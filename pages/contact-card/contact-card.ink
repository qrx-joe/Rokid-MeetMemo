<script def>
{
  "navigationBarTitleText": "联系人卡片",
  "description": "Display a structured relationship card. Reads ?id= from navigation query and pulls from services/contact-store. When no id is provided (e.g. opened standalone for demo), falls back to the seeded demo contact so the page is always renderable.",
  "schema": {
    "data": {
      "type": "object",
      "properties": {
        "contact": {
          "type": "object",
          "properties": {
            "id":           { "type": "string" },
            "name":         { "type": "string" },
            "role":         { "type": "string" },
            "organization": { "type": "string" },
            "context":      { "type": "string" },
            "interests":    { "type": "array", "items": { "type": "string" } },
            "nextAction":   { "type": "string" },
            "followUpAt":   { "type": "string" },
            "notes":        { "type": "string" }
          },
          "required": ["id", "name"]
        }
      },
      "required": ["contact"]
    }
  }
}
</script>

<script setup>
import { contactStore, __internal } from '../../services/contact-store.js';

// Start with a safe empty shape so the template never dereferences null
// before onLoad finishes (mini-program data binding evaluates immediately).
const EMPTY_CONTACT = {
  id: '',
  name: '加载中...',
  role: '',
  organization: '待补充',
  context: '',
  interests: [],
  nextAction: '',
  followUpAt: '',
  notes: ''
};

export default {
  data: {
    contact: EMPTY_CONTACT
  },

  async onLoad(query) {
    const requestedId = (query && query.id) ? query.id : null;
    let contact = null;

    if (requestedId) {
      contact = await contactStore.getContact(requestedId);
      if (!contact) {
        console.warn('[MeetMemo] contact id not found, falling back to demo', requestedId);
      }
    }

    // Fallback: no id (standalone open) OR id lookup failed.
    // Per SPEC.md §6.1, do not invent data — but the seeded demo is
    // explicitly intended to keep this page renderable in isolation.
    if (!contact) {
      contact = await contactStore.getContact(__internal.DEMO_CONTACT_ID);
    }

    if (contact) {
      this.setData({ contact });
    }
  }
};
</script>

<page>
  <view class="screen">
    <view class="card">
      <!-- Header: name is the primary glanceable line. -->
      <view class="header">
        <text class="name">{{ contact.name }}</text>
        <text class="role" ink:if="{{ contact.role }}">{{ contact.role }}</text>
      </view>

      <!-- Secondary line: organization + context. Hidden when both placeholder/empty. -->
      <view class="meta" ink:if="{{ (contact.organization && contact.organization !== '待补充') || contact.context }}">
        <text class="meta-org" ink:if="{{ contact.organization && contact.organization !== '待补充' }}">{{ contact.organization }}</text>
        <text class="meta-sep" ink:if="{{ contact.organization && contact.organization !== '待补充' && contact.context }}"> · </text>
        <text class="meta-ctx" ink:if="{{ contact.context }}">{{ contact.context }}</text>
      </view>

      <!-- Interests: chip-like inline list. Nested ink:for is unsupported, so this stays flat.
           Use ink:key="index" for string arrays (100% supported); skip the WeChat-style "*this"
           shortcut which is not confirmed for Ink. -->
      <view class="interests" ink:if="{{ contact.interests.length > 0 }}">
        <view class="chip" ink:for="{{ contact.interests }}" ink:key="index">
          <text class="chip-text">{{ item }}</text>
        </view>
      </view>

      <!-- Footer: next action + follow-up date — the action the user came here to remember. -->
      <view class="footer" ink:if="{{ contact.nextAction }}">
        <text class="footer-label">下一步</text>
        <text class="footer-action">{{ contact.nextAction }}</text>
        <text class="footer-date" ink:if="{{ contact.followUpAt }}">{{ contact.followUpAt }}</text>
      </view>
    </view>
  </view>
</page>

<style>
/* Width is enforced to AIUI's standard 480px; the runtime owns viewport. */
.screen {
  display: flex;
  width: 480px;
  background: var(--color-background);
  padding: var(--spacing-md);
  box-sizing: border-box;
}

/* One-card-per-screen layout per SPEC.md §5. Keep height inside 120–380px. */
.card {
  display: flex;
  flex-direction: column;
  width: 100%;
  padding: var(--card-padding);
  background: var(--color-surface);
  border: var(--card-border-width) solid var(--card-border-color);
  border-radius: var(--radius-md);
  gap: var(--spacing-md);
}

.header {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-sm);
}

.name {
  font-size: 28px;
  font-weight: 700;
  color: var(--color-text-primary);
  line-height: 1.2;
}

.role {
  font-size: 16px;
  color: var(--color-text-secondary);
  line-height: 1.3;
}

.meta {
  display: flex;
  flex-direction: row;
  align-items: center;
  font-size: 13px;
  color: var(--color-text-secondary);
}

.meta-org,
.meta-sep,
.meta-ctx {
  font-size: 13px;
  color: var(--color-text-secondary);
}

.interests {
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
  gap: var(--spacing-sm);
}

.chip {
  display: flex;
  padding: 4px 10px;
  border: var(--border-width-thin) solid var(--border-color-accent);
  border-radius: var(--radius-sm);
}

.chip-text {
  font-size: 13px;
  color: var(--color-primary);
}

.footer {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding-top: var(--card-footer-padding-y);
  margin-top: var(--card-footer-margin-top);
  border-top: var(--card-divider-width) solid var(--card-divider-color);
}

.footer-label {
  font-size: var(--card-footer-font-size);
  color: var(--color-text-secondary);
  text-transform: none;
}

.footer-action {
  font-size: 15px;
  color: var(--color-text-primary);
  line-height: 1.3;
}

.footer-date {
  font-size: 13px;
  color: var(--color-primary);
}
</style>
