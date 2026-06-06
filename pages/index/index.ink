<script def>
{
  "navigationBarTitleText": "MeetMemo",
  "description": "Home page. Primary entry to start a new quick note; lists the most recent contacts and the pending follow-up count. Refreshes on onShow so returning from capture/contact-card/followups always shows current data.",
  "schema": {
    "data": {
      "type": "object",
      "properties": {
        "recentContacts": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "id":         { "type": "string" },
              "name":       { "type": "string" },
              "role":       { "type": "string" },
              "followUpAt": { "type": "string" }
            },
            "required": ["id", "name"]
          }
        },
        "pendingCount": { "type": "number" },
        "loaded":       { "type": "boolean" }
      }
    }
  }
}
</script>

<script setup>
import wx from 'wx';
import { contactStore } from '../../services/contact-store.js';

// Cap on how many recent contacts the glance view shows.
// Anything more crowds the 480x380 envelope and forces scrolling within
// the home screen, which defeats "glance" use.
const RECENT_LIMIT = 5;

export default {
  data: {
    recentContacts: [],
    pendingCount: 0,
    loaded: false
  },

  async onLoad() {
    await this._refresh();
  },

  // onShow fires whenever the page becomes visible again, e.g. after
  // navigateBack from capture/contact-card. Re-pull so the list reflects
  // any save that happened while we were off-screen. If a future Ink
  // release omits onShow, the worst case is a stale list until the user
  // pulls down or relaunches — non-fatal.
  async onShow() {
    await this._refresh();
  },

  async _refresh() {
    const [contacts, followups] = await Promise.all([
      contactStore.listContacts(),
      contactStore.listFollowups()
    ]);

    // Pick a small projection per row — the home list does not need notes
    // or organization at glance level. Keep payload tiny so setData is cheap.
    const recent = contacts.slice(0, RECENT_LIMIT).map(c => ({
      id: c.id,
      name: c.name || '待补充',
      role: c.role || '',
      followUpAt: c.followUpAt || ''
    }));

    const pending = followups.filter(f => f.status === 'pending').length;

    this.setData({
      recentContacts: recent,
      pendingCount: pending,
      loaded: true
    });
  },

  handleStartCapture() {
    wx.navigateTo({ url: '/pages/capture/capture' });
  },

  // Same data-* pattern proven in capture handleField — keeps the
  // runtime assumption surface area constant across pages.
  handleOpenContact(e) {
    const id = e.currentTarget.dataset.id;
    if (!id) return;
    wx.navigateTo({
      url: `/pages/contact-card/contact-card?id=${encodeURIComponent(id)}`
    });
  },

  handleOpenFollowups() {
    wx.navigateTo({ url: '/pages/followups/followups' });
  }
};
</script>

<page>
  <view class="screen">
    <view class="card">
      <text class="title">MeetMemo</text>
      <text class="hint">记下你刚认识的人，下一次会面前一秒想起来。</text>

      <button class="btn-primary" bindtap="handleStartCapture">开始记录</button>

      <!-- Empty state: only the CTA, no recent list, no follow-up row. -->
      <view
        class="empty"
        ink:if="{{ loaded && recentContacts.length === 0 && pendingCount === 0 }}"
      >
        <text class="empty-text">还没有联系人。点上面"开始记录"，30 秒搞定第一条。</text>
      </view>

      <!-- Recent section: shown only when there is at least one contact. -->
      <view class="section" ink:if="{{ recentContacts.length > 0 }}">
        <text class="section-title">最近</text>
        <scroll-view class="recent-list" scroll-y="{{ true }}">
          <view
            class="recent-row"
            ink:for="{{ recentContacts }}"
            ink:key="id"
            data-id="{{ item.id }}"
            bindtap="handleOpenContact"
          >
            <view class="recent-main">
              <text class="recent-name">{{ item.name }}</text>
              <text class="recent-role" ink:if="{{ item.role }}">{{ item.role }}</text>
            </view>
            <text class="recent-date" ink:if="{{ item.followUpAt }}">{{ item.followUpAt }}</text>
          </view>
        </scroll-view>
      </view>

      <!-- Follow-up summary row: tap to drill into the list. -->
      <view
        class="followup-row"
        ink:if="{{ pendingCount > 0 }}"
        bindtap="handleOpenFollowups"
      >
        <text class="followup-label">待跟进</text>
        <text class="followup-count">{{ pendingCount }}</text>
      </view>
    </view>
  </view>
</page>

<style>
.screen {
  display: flex;
  width: 480px;
  background: var(--color-background);
  padding: var(--spacing-md);
  box-sizing: border-box;
}

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

.title {
  font-size: 24px;
  font-weight: 700;
  color: var(--color-text-primary);
}

.hint {
  font-size: 13px;
  color: var(--color-text-secondary);
  line-height: 1.4;
}

.btn-primary {
  padding: 12px 16px;
  background: var(--color-primary);
  color: var(--color-background);
  border: var(--border-width-default) solid var(--color-primary);
  border-radius: var(--radius-md);
  font-size: 16px;
  font-weight: 600;
}

.empty {
  padding: var(--spacing-md) 0;
}

.empty-text {
  font-size: 13px;
  color: var(--color-text-secondary);
  line-height: 1.4;
}

.section {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-sm);
}

.section-title {
  font-size: 12px;
  color: var(--color-text-secondary);
  text-transform: none;
}

/* Bounded so the home card stays within the 120–380px envelope even with
   many contacts. SPEC.md §5. */
.recent-list {
  max-height: 180px;
}

.recent-row {
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: space-between;
  padding: 8px 10px;
  border: var(--border-width-thin) solid var(--border-color-muted);
  border-radius: var(--radius-sm);
  margin-bottom: var(--spacing-sm);
}

.recent-main {
  display: flex;
  flex-direction: column;
  gap: 2px;
  flex: 1;
}

.recent-name {
  font-size: 15px;
  font-weight: 600;
  color: var(--color-text-primary);
  line-height: 1.2;
}

.recent-role {
  font-size: 12px;
  color: var(--color-text-secondary);
  line-height: 1.3;
}

.recent-date {
  font-size: 12px;
  color: var(--color-primary);
}

.followup-row {
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: space-between;
  padding: 10px 12px;
  border: var(--border-width-default) solid var(--border-color-accent);
  border-radius: var(--radius-md);
  margin-top: var(--spacing-sm);
}

.followup-label {
  font-size: 14px;
  color: var(--color-text-primary);
}

.followup-count {
  font-size: 16px;
  font-weight: 700;
  color: var(--color-primary);
}
</style>
