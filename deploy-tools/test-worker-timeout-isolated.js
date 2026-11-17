// Uses connection-local temporary tables: no production task or worker is modified.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const { randomUUID } = require('node:crypto');

async function main() {
  const backend = process.env.BACKEND_ROOT || '/opt/task-engine';
  const build = process.env.BACKEND_BUILD_DIR || path.join(backend, 'dist');
  require(path.join(backend, 'node_modules/dotenv')).config({ path: path.join(backend, '.env'), quiet: true });
  const orm = require(path.join(backend, 'node_modules/typeorm'));
  for (const file of fs.readdirSync(path.join(build, 'shared/database/entities')).filter(f => f.endsWith('.entity.js'))) {
    require(path.join(build, 'shared/database/entities', file));
  }
  const ds = new orm.DataSource({ type: 'mysql', host: process.env.DB_HOST || 'localhost',
    username: process.env.DB_USERNAME || 'taskapp', password: process.env.DB_PASSWORD,
    database: process.env.DB_DATABASE || 'task_platform',
    entities: [...new Set(orm.getMetadataArgsStorage().tables.map(t => t.target))],
    synchronize: false, migrationsRun: false, logging: false, timezone: '+00:00', extra: { connectionLimit: 1 } });
  await ds.initialize();
  const load = (file, name) => require(path.join(build, file))[name];
  const entity = (file, name) => load('shared/database/entities/' + file, name);
  const Task = entity('task.entity', 'Task');
  const Assignment = entity('task-assignment.entity', 'TaskAssignment');
  const Participation = entity('campaign-worker-participation.entity', 'CampaignWorkerParticipation');
  try {
    for (const table of ['tasks', 'task_assignments', 'campaign_worker_participation', 'worker_completed_identities']) {
      const [schema] = await ds.query(`SHOW CREATE TABLE \`${table}\``);
      const ddl = schema['Create Table'].replace('CREATE TABLE', 'CREATE TEMPORARY TABLE')
        .replace(/^\s*CONSTRAINT .*FOREIGN KEY.*\n?/gm, '')
        .replace(/,\s*\)/g, '\n)');
      await ds.query(ddl);
    }
    const taskRepo = new (load('shared/database/repositories/task.repository', 'TaskRepository'))(ds.getRepository(Task));
    const events = [];
    const release = new (load('shared/engines/reallocation-engine/services/task-release.service', 'TaskReleaseService'))(
      null, null, null, { emit: (...args) => events.push(args) }, ds);
    const machine = new (load('task-engine/state-machine/task-state-machine', 'TaskStateMachine'))();
    const validation = new (load('task-engine/task-validation.service', 'TaskValidationService'))(machine);
    const command = new (load('task-engine/handlers/task-command.service', 'TaskCommandService'))(
      ds, taskRepo, null, null, validation, machine);
    const monitor = new (load('shared/engines/reallocation-engine/services/deadline-monitor.service', 'DeadlineMonitorService'))(
      taskRepo, null, null, release, { reassignTaskToNewWorker() { throw Error('Expired accepted work must return to pool'); } });
    const oldWorker = 'timeout-old@example.invalid', newWorker = 'timeout-new@example.invalid';
    const task = await ds.getRepository(Task).save({ id: randomUUID(), campaignId: randomUUID(), orderId: randomUUID(),
      orderUnitId: randomUUID(), taskType: 'generic', status: 'in_progress', assignedTo: oldWorker,
      acceptedAt: new Date(Date.now() - 31 * 60000), assignedAt: new Date(Date.now() - 31 * 60000),
      startedAt: new Date(Date.now() - 30 * 60000), deadline: new Date(Date.now() + 89 * 60000),
      rewardAmount: 1, attemptCount: 1, requirements: {}, metadata: {} });
    await ds.getRepository(Assignment).save({ taskId: task.id, campaignId: task.campaignId, orderId: task.orderId,
      orderUnitId: task.orderUnitId, workerId: oldWorker, attemptNumber: 1, status: 'STARTED' });
    await ds.getRepository(Participation).save({ campaignId: task.campaignId, workerId: oldWorker, status: 'ASSIGNED' });
    await assert.rejects(command.submitTask({ taskId: task.id, workerId: oldWorker, data: {} }), /30-minute/);
    const result = await monitor.processFullTimeouts();
    assert.equal(result.expiredCount, 1);
    assert.equal(events.length, 1);
    assert.ok((await taskRepo.findAvailableForAssignment()).some(t => t.id === task.id));
    assert.equal((await ds.getRepository(Assignment).findOneBy({ taskId: task.id })).status, 'EXPIRED');
    await assert.rejects(command.acceptTask({ taskId: task.id, workerId: oldWorker }), /already participated/);
    const accepted = await command.acceptTask({ taskId: task.id, workerId: newWorker });
    assert.equal(accepted.id, task.id);
    assert.equal(accepted.orderUnitId, task.orderUnitId);
    assert.equal(accepted.assignedTo, newWorker);
    assert.equal(accepted.attemptCount, 2);
    assert.equal(accepted.deadline.getTime() - accepted.acceptedAt.getTime(), 30 * 60000);
    await assert.rejects(command.submitTask({ taskId: task.id, workerId: oldWorker, data: {} }), /another worker/);
    // A submitted proof wins against a stale monitor snapshot.
    await ds.getRepository(Task).update(task.id, { status: 'under_review', submittedAt: new Date() });
    assert.equal(await release.releaseWorkerFromTask({ taskId: task.id, workerId: newWorker,
      campaignId: task.campaignId, reason: 'WORKER_TIMEOUT', expectedDeadline: new Date(0) }), false);
    assert.equal(events.length, 1);
    console.log(JSON.stringify({ temporaryTablesOnly: true, expiredTaskReturnedToPool: true,
      oldWorkerExcluded: true, secondWorkerAcceptedSameUnit: true, freshThirtyMinuteWindow: true,
      lateProofRejected: true, submittedProofProtected: true }));
  } finally {
    await ds.destroy();
  }
}
main().catch(error => { console.error(error.stack || error.message); process.exitCode = 1; });
