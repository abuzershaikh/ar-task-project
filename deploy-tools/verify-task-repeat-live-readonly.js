// Reads production history through the compiled filters. Synthetic new-order
// objects remain in memory; no order, assignment, review, or push is created.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');

async function main() {
  const backend = process.env.BACKEND_ROOT || '/opt/task-engine';
  const build = process.env.BACKEND_BUILD_DIR || path.join(backend, 'dist');
  require(path.join(backend, 'node_modules/dotenv')).config({ path: path.join(backend, '.env'), quiet: true });
  const typeorm = require(path.join(backend, 'node_modules/typeorm'));
  for (const file of fs.readdirSync(path.join(build, 'shared/database/entities')).filter((file) => file.endsWith('.entity.js'))) {
    require(path.join(build, 'shared/database/entities', file));
  }
  const ds = new typeorm.DataSource({ type: 'mysql', host: process.env.DB_HOST || 'localhost',
    username: process.env.DB_USERNAME || 'taskapp', password: process.env.DB_PASSWORD,
    database: process.env.DB_DATABASE || 'task_platform',
    entities: [...new Set(typeorm.getMetadataArgsStorage().tables.map((table) => table.target))],
    synchronize: false, migrationsRun: false, logging: false, extra: { connectionLimit: 1 } });
  await ds.initialize();
  try {
    await ds.query('SET SESSION TRANSACTION READ ONLY');
    const make = (file, name, entityFile, entityName) => new (require(path.join(build, 'shared/database/repositories', file))[name])(
      ds.getRepository(require(path.join(build, 'shared/database/entities', entityFile))[entityName]));
    const taskRepo = make('task.repository', 'TaskRepository', 'task.entity', 'Task');
    const query = new (require(path.join(build, 'task-engine/queries/task-query.service')).TaskQueryService)(taskRepo,
      make('campaign-worker-participation.repository', 'CampaignWorkerParticipationRepository', 'campaign-worker-participation.entity', 'CampaignWorkerParticipation'),
      make('submission.repository', 'SubmissionRepository', 'submission.entity', 'TaskSubmission'),
      make('task-assignment.repository', 'TaskAssignmentRepository', 'task-assignment.entity', 'TaskAssignment'),
      make('user.repository', 'UserRepository', 'user.entity', 'User'));
    const { extractTaskIdentity, resolvedUrlCache } = require(path.join(build, 'shared/common/utils/task-identity.util'));
    const { eligibleTaskPushTokens } = require(path.join(build, 'shared/common/utils/task-push-tokens.util'));
    const command = Object.create(require(path.join(build, 'task-engine/handlers/task-command.service')).TaskCommandService.prototype);
    command.logger = { warn() {}, error() {} };
    const template = await taskRepo.findById('02054fec-d54b-4a4b-ae3d-ff7ae7600f22');
    assert.ok(template, 'Historical business fixture exists');
    const originalAvailable = taskRepo.findAvailableForAssignment.bind(taskRepo);
    for (const uid of ['om619a893wc1l6lVnDJSEroCUOC3', 'ad6936a1-0255-4c9c-9407-4b01abbdedee']) {
      resolvedUrlCache.clear();
      const rows = await ds.query('SELECT u.id,u.email,w.id worker_id FROM users u LEFT JOIN workers w ON w.user_id=u.id WHERE u.id=?', [uid]);
      assert.equal(rows.length, 1, 'Regression worker exists');
      const user = rows[0];
      const next = { ...template, id: 'diagnostic-task-not-persisted', orderId: 'diagnostic-buyer-order-not-persisted',
        campaignId: 'diagnostic-buyer-order-not-persisted', orderUnitId: 'diagnostic-new-unit', assignedTo: null, status: 'ACTIVE' };
      taskRepo.findAvailableForAssignment = async () => [next];
      let offered;
      try { offered = await query.getAvailableTasks(user.id, user.email); }
      finally { taskRepo.findAvailableForAssignment = originalAvailable; }
      assert.equal(offered.length, 0, 'Same business from a new buyer must not be offered');
      const identity = extractTaskIdentity(next);
      const aliases = [user.id, user.email, user.worker_id].filter(Boolean);
      await assert.rejects(command.verifyNoDuplicateAppOrUrlTransactional(ds.manager, next, aliases, identity), /already completed/);
      const excluded = new Set(await taskRepo.findWorkerIdsWithPackageOrUrl(identity.packageId, identity.normalizedUrl, identity.businessNameKey, identity.entityKeys));
      assert.ok(aliases.some((alias) => excluded.has(alias.toLowerCase())));
      console.log(JSON.stringify({ regressionWorker: uid, coldCache: true, offered: false, duplicateAcceptanceBlocked: true, pushExcluded: true }));
    }
    const users = await ds.query("SELECT id,email,metadata FROM users WHERE role='WORKER'");
    const tokensOf = (user) => {
      const metadata = typeof user.metadata === 'string' ? JSON.parse(user.metadata) : user.metadata || {};
      return [...new Set([metadata.fcmToken, metadata.deviceToken])].filter((token) => typeof token === 'string' && token.length > 20);
    };
    const grouped = new Map();
    for (const user of users) for (const token of tokensOf(user)) {
      if (!grouped.has(token)) grouped.set(token, []);
      grouped.get(token).push(user);
    }
    const available = await originalAvailable();
    const distinct = new Map();
    for (const task of available) {
      if (/play|business|maps|gmb|install/i.test([task.taskType, task.requirements?.platform].join(' '))) distinct.set(task.orderId, task);
    }
    let mixedDevicesBlocked = 0;
    for (const task of [...distinct.values()].slice(0, 5)) {
      const identity = extractTaskIdentity(task);
      const excluded = new Set(await taskRepo.findWorkerIdsWithPackageOrUrl(identity.packageId, identity.normalizedUrl, identity.businessNameKey, identity.entityKeys));
      const recipients = eligibleTaskPushTokens(users, excluded);
      assert.equal(recipients.length, new Set(recipients).size);
      const selected = new Set(recipients);
      for (const [token, owners] of grouped) {
        const blocked = owners.some((user) => excluded.has(user.id.toLowerCase()) || excluded.has(user.email.toLowerCase()));
        const eligible = owners.some((user) => !excluded.has(user.id.toLowerCase()) && !excluded.has(user.email.toLowerCase()));
        if (blocked && eligible) { assert.equal(selected.has(token), false); mixedDevicesBlocked++; }
      }
      console.log(JSON.stringify({ orderId: task.orderId, uniqueRecipients: recipients.length, tokenLeak: false }));
    }
    console.log(JSON.stringify({ verification: 'PASS', mixedDevicesBlocked, newOrdersCreated: 0, pushesSent: 0 }));
  } finally {
    await ds.destroy();
  }
}
main().catch((error) => { console.error(error.message); process.exitCode = 1; });
