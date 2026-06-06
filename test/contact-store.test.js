import assert from 'node:assert/strict';
import test from 'node:test';

import { contactStore, __internal } from '../services/contact-store.js';

function installStorageMock(initial = {}) {
  const storage = new Map(Object.entries(initial));
  globalThis.wx = {
    getStorageSync(key) {
      return storage.get(key);
    },
    setStorageSync(key, data) {
      storage.set(key, data);
    }
  };
  return storage;
}

test('contactStore persists contacts and generated followups through wx storage', async () => {
  const storage = installStorageMock();
  await __internal.resetForTest();

  const saved = await contactStore.saveContact({
    name: '李明',
    role: 'BD',
    organization: 'Acme',
    context: 'AI 活动',
    interests: ['AIUI'],
    nextAction: '发送资料',
    followUpAt: '2026-06-09',
    notes: '想看眼镜端 Demo'
  });

  const persisted = storage.get(__internal.STORAGE_KEY);
  assert.equal(persisted.contacts.some(contact => contact.id === saved.id), true);
  assert.equal(persisted.followups.some(followup => followup.contactId === saved.id), true);

  await __internal.resetForTest();
  const reloaded = await contactStore.getContact(saved.id);
  const followups = await contactStore.listFollowups();

  assert.equal(reloaded.name, '李明');
  assert.equal(followups.some(followup => followup.contactId === saved.id), true);
});

test('contactStore persists followup status updates', async () => {
  installStorageMock();
  await __internal.resetForTest();

  const saved = await contactStore.saveContact({
    name: '赵敏',
    nextAction: '约演示',
    followUpAt: '2026-06-10'
  });

  const created = (await contactStore.listFollowups())
    .find(followup => followup.contactId === saved.id);

  assert.equal(created.status, 'pending');

  await contactStore.updateFollowupStatus(created.id, 'done');
  await __internal.resetForTest();

  const updated = (await contactStore.listFollowups())
    .find(followup => followup.contactId === saved.id);

  assert.equal(updated.status, 'done');
});

test('contactStore deletes a contact and its derived followups', async () => {
  installStorageMock();
  await __internal.resetForTest();

  const saved = await contactStore.saveContact({
    name: '周宁',
    nextAction: '发报价',
    followUpAt: '2026-06-11'
  });

  assert.equal(await contactStore.deleteContact(saved.id), true);
  assert.equal(await contactStore.getContact(saved.id), null);
  assert.equal(
    (await contactStore.listFollowups()).some(followup => followup.contactId === saved.id),
    false
  );
});

test('contactStore deletes a followup without deleting its contact', async () => {
  installStorageMock();
  await __internal.resetForTest();

  const saved = await contactStore.saveContact({
    name: '陈晨',
    nextAction: '约复盘',
    followUpAt: '2026-06-12'
  });
  const followup = (await contactStore.listFollowups())
    .find(item => item.contactId === saved.id);

  assert.equal(await contactStore.deleteFollowup(followup.id), true);
  assert.equal(await contactStore.getContact(saved.id).then(contact => contact.name), '陈晨');
  assert.equal(
    (await contactStore.listFollowups()).some(item => item.id === followup.id),
    false
  );
});
