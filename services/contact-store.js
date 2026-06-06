// services/contact-store.js
//
// MeetMemo storage adapter. Per SPEC.md §6 and §11, persistence MUST live
// behind one adapter — pages never touch storage primitives directly.
//
// MVP implementation: module-scoped in-memory Maps. Persistence across app
// launches is intentionally NOT in scope yet. When wx.storage proves stable
// on the target Rokid device, swap the Map ops for wx.getStorage /
// wx.setStorage calls; the exported interface MUST stay identical so
// pages/capture and pages/contact-card do not change.
//
// All methods are async (return Promises) on purpose. The current Map
// implementation could be sync, but exposing async now makes the wx.storage
// migration a no-op for callers.

// --- internal state ------------------------------------------------------

const contacts = new Map();   // id -> Contact
const followups = new Map();  // id -> Followup

// Seed one demo contact so pages/contact-card stays renderable when opened
// directly (e.g. from a hard-coded link or first-launch demo).
// The seed is intentionally the same 王磊 sample SPEC.md §7 illustrates.
const DEMO_CONTACT_ID = 'contact_demo_wanglei';
contacts.set(DEMO_CONTACT_ID, {
  id: DEMO_CONTACT_ID,
  name: '王磊',
  role: '教育 SaaS 创始人',
  organization: '待补充',
  context: 'AI 创业活动',
  interests: ['AIUI Demo'],
  nextAction: '下周二发送 Demo 资料',
  followUpAt: '2026-06-09',
  notes: '对眼镜端低打扰交互感兴趣',
  createdAt: '2026-06-06T10:00:00+08:00',
  updatedAt: '2026-06-06T10:00:00+08:00'
});
followups.set('followup_demo_wanglei', {
  id: 'followup_demo_wanglei',
  contactId: DEMO_CONTACT_ID,
  title: '发送 Demo 资料',
  dueAt: '2026-06-09',
  status: 'pending'
});

// --- helpers -------------------------------------------------------------

function nowIso() {
  // Plain ISO 8601 with local-ish offset is fine for MVP; we don't sort by
  // sub-second precision and there is no cross-device sync to worry about.
  return new Date().toISOString();
}

function newId(prefix) {
  // crypto.randomUUID is listed as supported in aiui-dev SKILL.md §8.
  // Fallback path is defensive only — if randomUUID is missing we still
  // produce a unique-enough id rather than crashing the save flow.
  if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
    return `${prefix}_${crypto.randomUUID()}`;
  }
  return `${prefix}_${Date.now()}_${Math.floor(Math.random() * 1e6)}`;
}

// Follow-ups are derived from contacts; whenever a contact is saved with
// both nextAction and followUpAt, ensure a matching follow-up exists.
// Returning the followup lets callers reference it if needed.
function syncFollowupForContact(contact) {
  const hasAction = Boolean(contact.nextAction && contact.nextAction.trim());
  const hasDate = Boolean(contact.followUpAt && contact.followUpAt.trim());
  if (!hasAction || !hasDate) {
    return null;
  }

  // One contact -> at most one MVP follow-up. Find existing by contactId,
  // refresh its title/dueAt; otherwise create.
  let existing = null;
  for (const f of followups.values()) {
    if (f.contactId === contact.id) {
      existing = f;
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

// --- public API ----------------------------------------------------------

export const contactStore = {
  async listContacts() {
    // Newest first — capture flow expects "recent contacts" ordering.
    return Array.from(contacts.values()).sort((a, b) => {
      return (b.updatedAt || '').localeCompare(a.updatedAt || '');
    });
  },

  async getContact(id) {
    if (!id) return null;
    return contacts.get(id) || null;
  },

  async saveContact(draft) {
    // Defensive copy so the caller can keep mutating their object without
    // accidentally writing back through the Map reference.
    const now = nowIso();
    const id = draft.id || newId('contact');
    const existing = contacts.get(id);
    const stored = {
      id,
      name: draft.name || '',
      role: draft.role || '',
      // Keep '待补充' explicit per SPEC.md §7 — never invent values silently.
      organization: draft.organization || '待补充',
      context: draft.context || '',
      interests: Array.isArray(draft.interests) ? [...draft.interests] : [],
      nextAction: draft.nextAction || '',
      followUpAt: draft.followUpAt || '',
      notes: draft.notes || '',
      createdAt: existing ? existing.createdAt : now,
      updatedAt: now
    };
    contacts.set(id, stored);
    syncFollowupForContact(stored);
    return stored;
  },

  async listFollowups() {
    // Pending first, then by dueAt ascending. MVP — no week-grouping yet.
    return Array.from(followups.values()).sort((a, b) => {
      if (a.status !== b.status) {
        return a.status === 'pending' ? -1 : 1;
      }
      return (a.dueAt || '').localeCompare(b.dueAt || '');
    });
  },

  async updateFollowupStatus(id, status) {
    const f = followups.get(id);
    if (!f) return null;
    f.status = status;
    return f;
  }
};

// Exported for tests / direct seeding inspection only. Not part of the
// stable adapter contract — do not call from pages.
export const __internal = { contacts, followups, DEMO_CONTACT_ID };
