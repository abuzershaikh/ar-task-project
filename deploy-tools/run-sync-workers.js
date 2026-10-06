const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function main() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  const syncScript = `
const { pool } = require('./src/config/db');
const admin = require('./src/config/firebase');

async function syncWorkerNames() {
  console.log('[Sync] Finding nameless worker conversations...');
  const [rows] = await pool.query(
    "SELECT id, worker_id, worker_name, worker_email FROM support_conversations WHERE worker_name IS NULL OR worker_name='' OR worker_name='Worker' OR worker_email IS NULL OR worker_email=''"
  );
  console.log(\`[Sync] Found \${rows.length} conversations to inspect.\`);

  let updatedCount = 0;
  for (const row of rows) {
    let resolvedName = '';
    let resolvedEmail = '';
    let resolvedAvatar = '';
    let resolvedPhone = '';

    // 1. Try Firebase Auth
    try {
      const fbUser = await admin.auth().getUser(row.worker_id);
      if (fbUser) {
        resolvedEmail = fbUser.email || '';
        resolvedName = fbUser.displayName || '';
        resolvedAvatar = fbUser.photoURL || '';
        resolvedPhone = fbUser.phoneNumber || '';
      }
    } catch (e) {
      // not a firebase uid or not found
    }

    // 2. Try users table by id or email
    try {
      const [uRows] = await pool.query(
        "SELECT full_name, email, avatar_url, phone FROM users WHERE id = ? OR (email != '' AND email = ?) LIMIT 1",
        [row.worker_id, resolvedEmail]
      );
      if (uRows.length > 0) {
        if (!resolvedName || resolvedName === 'Worker') resolvedName = uRows[0].full_name;
        if (!resolvedEmail) resolvedEmail = uRows[0].email;
        if (!resolvedAvatar) resolvedAvatar = uRows[0].avatar_url;
        if (!resolvedPhone) resolvedPhone = uRows[0].phone;
      }
    } catch (e) {}

    // Fallback if still empty
    if (!resolvedName || resolvedName === 'Worker') {
      if (resolvedEmail) {
        resolvedName = resolvedEmail.split('@')[0];
      }
    }

    if (resolvedName && resolvedName !== 'Worker') {
      await pool.query(
        "UPDATE support_conversations SET worker_name = ?, worker_email = COALESCE(NULLIF(?, ''), worker_email), worker_avatar_url = COALESCE(NULLIF(?, ''), worker_avatar_url), worker_phone = COALESCE(NULLIF(?, ''), worker_phone) WHERE id = ?",
        [resolvedName, resolvedEmail, resolvedAvatar, resolvedPhone, row.id]
      );
      console.log(\`[Sync] Updated \${row.worker_id} => Name: "\${resolvedName}", Email: "\${resolvedEmail}"\`);
      updatedCount++;
    } else {
      console.log(\`[Sync] Could not resolve \${row.worker_id}\`);
    }
  }

  console.log(\`[Sync] Done! Successfully updated \${updatedCount} of \${rows.length} conversations.\`);
  process.exit(0);
}

syncWorkerNames().catch(e => {
  console.error('[Sync] Fatal error:', e);
  process.exit(1);
});
`;

  await ssh.execCommand(`cat << 'EOF' > /opt/support-chat-engine/sync_worker_names.js\n${syncScript}\nEOF`);
  console.log('Running sync script on VPS...');
  const res = await ssh.execCommand('node sync_worker_names.js', { cwd: '/opt/support-chat-engine' });
  console.log(res.stdout);
  console.log(res.stderr);

  ssh.dispose();
}

main().catch(console.error);
