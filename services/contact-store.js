// services/contact-store.js
//
// MeetMemo storage adapter. Pages must use this module instead of touching
// wx storage directly; that keeps persistence swappable and testable.

const STORAGE_KEY = 'meetmemo.v1.store';
const UNKNOWN = '待补充';

const contacts = new Map();
const followups = new Map();

// Temporary in-memory photo storage.
// Photos are stored as base64 data URLs between photo-capture and capture pages.
// They are merged into the contact record on save and cleared afterward.
const photoData = new Map();

const DEMO_CONTACT_ID = 'contact_demo_wanglei';
const DEMO_FOLLOWUP_ID = 'followup_demo_wanglei';

let loaded = false;
let wxModule = null;
let wxResolved = false;

function demoContact() {
  return {
    id: DEMO_CONTACT_ID,
    name: '王磊',
    role: '教育 SaaS 创始人',
    organization: UNKNOWN,
    context: 'AI 创业活动',
    interests: ['AIUI Demo'],
    nextAction: '下周二发送 Demo 资料',
    followUpAt: '2026-06-09',
    notes: '对眼镜端低打扰交互感兴趣',
    createdAt: '2026-06-06T10:00:00+08:00',
    updatedAt: '2026-06-06T10:00:00+08:00'
  };
}

function demoFollowup() {
  return {
    id: DEMO_FOLLOWUP_ID,
    contactId: DEMO_CONTACT_ID,
    title: '发送 Demo 资料',
    dueAt: '2026-06-09',
    status: 'pending'
  };
}

function seedDemoData() {
  if (!contacts.has(DEMO_CONTACT_ID)) {
    contacts.set(DEMO_CONTACT_ID, demoContact());
  }
  if (!followups.has(DEMO_FOLLOWUP_ID)) {
    followups.set(DEMO_FOLLOWUP_ID, demoFollowup());
  }
}

async function getWx() {
  if (wxResolved) return wxModule;
  wxResolved = true;

  if (globalThis.wx) {
    wxModule = globalThis.wx;
    return wxModule;
  }

  try {
    const mod = await import('wx');
    wxModule = mod.default;
  } catch (error) {
    wxModule = null;
  }
  return wxModule;
}

function normalizeContact(draft, existing, now, id) {
  return {
    id,
    name: draft.name || '',
    role: draft.role || '',
    organization: draft.organization || UNKNOWN,
    context: draft.context || '',
    interests: Array.isArray(draft.interests) ? [...draft.interests] : [],
    nextAction: draft.nextAction || '',
    followUpAt: draft.followUpAt || '',
    notes: draft.notes || '',
    photo: draft.photo || '',
    createdAt: existing ? existing.createdAt : now,
    updatedAt: now
  };
}

function snapshot() {
  return {
    contacts: Array.from(contacts.values()),
    followups: Array.from(followups.values())
  };
}

function applySnapshot(data) {
  contacts.clear();
  followups.clear();

  if (data && Array.isArray(data.contacts)) {
    for (const contact of data.contacts) {
      if (contact && contact.id) {
        contacts.set(contact.id, {
          ...contact,
          interests: Array.isArray(contact.interests) ? [...contact.interests] : []
        });
      }
    }
  }

  if (data && Array.isArray(data.followups)) {
    for (const followup of data.followups) {
      if (followup && followup.id) {
        followups.set(followup.id, { ...followup });
      }
    }
  }
}

async function loadState() {
  if (loaded) return;
  loaded = true;

  const wx = await getWx();
  if (wx && typeof wx.getStorageSync === 'function') {
    try {
      const stored = wx.getStorageSync(STORAGE_KEY);
      if (stored) {
        applySnapshot(stored);
      }
    } catch (error) {
      console.log('[MeetMemo] storage read failed, using memory fallback', error);
    }
  }

  seedDemoData();
}

async function saveState() {
  const wx = await getWx();
  if (!wx || typeof wx.setStorageSync !== 'function') {
    return;
  }

  try {
    wx.setStorageSync(STORAGE_KEY, snapshot());
  } catch (error) {
    // Persistence failure must not crash capture. The in-memory copy still
    // keeps the current session usable; device testing should surface logs.
    console.log('[MeetMemo] storage write failed, using memory fallback', error);
  }
}

function nowIso() {
  return new Date().toISOString();
}

function newId(prefix) {
  if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
    return `${prefix}_${crypto.randomUUID()}`;
  }
  return `${prefix}_${Date.now()}_${Math.floor(Math.random() * 1e6)}`;
}

function syncFollowupForContact(contact) {
  const hasAction = Boolean(contact.nextAction && contact.nextAction.trim());
  const hasDate = Boolean(contact.followUpAt && contact.followUpAt.trim());
  if (!hasAction || !hasDate) {
    return null;
  }

  let existing = null;
  for (const followup of followups.values()) {
    if (followup.contactId === contact.id) {
      existing = followup;
      break;
    }
  }

  if (existing) {
    existing.title = contact.nextAction;
    existing.dueAt = contact.followUpAt;
    return existing;
  }

  const created = {
    id: newId('followup'),
    contactId: contact.id,
    title: contact.nextAction,
    dueAt: contact.followUpAt,
    status: 'pending'
  };
  followups.set(created.id, created);
  return created;
}

export const contactStore = {
  async listContacts() {
    await loadState();
    return Array.from(contacts.values()).sort((a, b) => {
      return (b.updatedAt || '').localeCompare(a.updatedAt || '');
    });
  },

  async getContact(id) {
    await loadState();
    if (!id) return null;
    return contacts.get(id) || null;
  },

  async saveContact(draft) {
    await loadState();

    const now = nowIso();
    const id = draft.id || newId('contact');
    const existing = contacts.get(id);
    const stored = normalizeContact(draft, existing, now, id);

    contacts.set(id, stored);
    syncFollowupForContact(stored);
    await saveState();
    return stored;
  },

  async listFollowups() {
    await loadState();
    return Array.from(followups.values()).sort((a, b) => {
      if (a.status !== b.status) {
        return a.status === 'pending' ? -1 : 1;
      }
      return (a.dueAt || '').localeCompare(b.dueAt || '');
    });
  },

  async updateFollowupStatus(id, status) {
    await loadState();
    const followup = followups.get(id);
    if (!followup) return null;
    followup.status = status;
    await saveState();
    return followup;
  },

  async deleteContact(id) {
    await loadState();
    if (!id || !contacts.has(id)) return false;

    contacts.delete(id);
    for (const followup of Array.from(followups.values())) {
      if (followup.contactId === id) {
        followups.delete(followup.id);
      }
    }
    await saveState();
    return true;
  },

  async deleteFollowup(id) {
    await loadState();
    if (!id || !followups.has(id)) return false;

    followups.delete(id);
    await saveState();
    return true;
  },

  // ---------- Photo storage (in-memory, page-to-page handoff) ----------
  savePhoto(base64Data) {
    const key = newId('photo');
    photoData.set(key, base64Data);
    return key;
  },

  getPhoto(key) {
    return photoData.get(key) || '';
  },

  deletePhoto(key) {
    photoData.delete(key);
  }
};

// Test-only hooks. Pages should not use these except for DEMO_CONTACT_ID,
// which keeps contact-card renderable when opened directly.
export const __internal = {
  STORAGE_KEY,
  contacts,
  followups,
  DEMO_CONTACT_ID,
  async resetForTest() {
    loaded = false;
    wxModule = null;
    wxResolved = false;
    contacts.clear();
    followups.clear();
  }
};
