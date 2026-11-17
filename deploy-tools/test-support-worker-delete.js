const test = require('node:test');
const assert = require('node:assert/strict');
const vm = require('node:vm');
const fs = require('node:fs');
const path = require('node:path');

function serviceWith(query) {
  const sandbox = {
    module: { exports: {} }, console,
    require: (name) => {
      if (name === '../config/db') return { pool: { query } };
      if (name === 'uuid') return { v4: () => 'test-message' };
      if (name === './fcm.service') return {};
      if (name === '../config/firebase') return {};
      if (name === 'crypto') return require('node:crypto');
      throw new Error(`Unexpected dependency: ${name}`);
    },
  };
  vm.runInNewContext(fs.readFileSync(path.join(__dirname, '../support-chat-engine/src/services/chat.service.js'), 'utf8'), sandbox);
  return sandbox.module.exports;
}

test('deleted worker cannot recreate a support conversation', async () => {
  const calls = [];
  const service = serviceWith(async (sql) => { calls.push(sql); return [[{ identity_hash: 'deleted' }]]; });
  await assert.rejects(service.getOrCreateConversation('deleted-worker'), /permanently deleted/);
  assert.equal(calls.length, 1);
  assert.ok(calls[0].includes('deleted_worker_accounts'));
});

test('deleted worker cannot add messages to an existing conversation', async () => {
  const calls = [];
  const service = serviceWith(async (sql) => {
    calls.push(sql);
    if (sql.includes('FROM support_conversations')) return [[{ worker_id: 'deleted-worker', worker_email: 'deleted@example.test' }]];
    return [[{ identity_hash: 'deleted' }]];
  });
  await assert.rejects(service.createMessage({ conversationId: 'old-conversation', workerId: 'deleted-worker', senderType: 'WORKER' }), /permanently deleted/);
  assert.ok(calls.every((sql) => !sql.includes('INSERT')));
});

test('old conversation IDs cannot create orphaned messages after cleanup', async () => {
  const service = serviceWith(async () => [[]]);
  await assert.rejects(service.createMessage({ conversationId: 'deleted-conversation', workerId: 'deleted-worker', senderType: 'WORKER' }), /no longer exists/);
});

test('deletion arriving after prechecks still blocks conversation insertion', async () => {
  const service = serviceWith(async (sql) => sql.includes('INSERT INTO') ? [{ affectedRows: 0 }] : [[]]);
  await assert.rejects(service.getOrCreateConversation('worker', { name: 'Test', email: 'worker@example.test' }), /permanently deleted/);
});

test('deletion arriving after message prechecks still blocks message insertion', async () => {
  const service = serviceWith(async (sql) => {
    if (sql.startsWith('SELECT worker_id')) return [[{ worker_id: 'worker', worker_email: 'worker@example.test' }]];
    return sql.includes('INSERT INTO') ? [{ affectedRows: 0 }] : [[]];
  });
  await assert.rejects(service.createMessage({ conversationId: 'conversation', workerId: 'worker', senderType: 'WORKER' }), /has been deleted/);
});
