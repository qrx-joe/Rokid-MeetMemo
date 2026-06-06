<script def>
{
  "navigationBarTitleText": "待跟进",
  "description": "Follow-up list page. Two sections: Pending (default focus) and Completed. Each row shows title, contact name, and due date; tap to jump to the contact card; the inline button toggles status. Resolves contact names via contactStore.getContact lazily so this page does not duplicate Contact storage.",
  "schema": {
    "data": {
      "type": "object",
      "properties": {
        "pending": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "id":          { "type": "string" },
              "contactId":   { "type": "string" },
              "contactName": { "type": "string" },
              "title":       { "type": "string" },
              "dueAt":       { "type": "string" },
              "status":      { "type": "string" }
            },
            "required": ["id", "title", "status"]
          }
        },
        "completed": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "id":          { "type": "string" },
              "contactId":   { "type": "string" },
              "contactName": { "type": "string" },
              "title":       { "type": "string" },
              "dueAt":       { "type": "string" },
              "status":      { "type": "string" }
            },
            "required": ["id", "title", "status"]
          }
        },
        "loaded": { "type": "boolean" }
      }
    }
  }
}
</script>

<script setup>
import wx from 'wx';
import { contactStore } from '../../services/contact-store.js';

export default {
  data: {
    pending: [],
    completed: [],
    loaded: false
  },

  async onLoad() {
    await this._refresh();
  },

  // Same onShow pattern as index — keeps the list in sync after the user
  // navigates back from a contact card. If onShow is not honored by Ink,
  // the inline status toggle still refreshes via the explicit call.
  async onShow() {
    await this._refresh();
  },

  async _refresh() {
    const followups = await contactStore.listFollowups();

    // Resolve contact names lazily; this keeps Followup records in the
    // store free of duplicated contact fields. Promise.all is acceptable
    // because MVP lists stay short.
    const enriched = await Promise.all(followups.map(async f => {
      const c = await contactStore.getContact(f.contactId);
      return {
        id: f.id,
        contactId: f.contactId,
        contactName: c ? (c.name || '待补充') : '未知',
        title: f.title,
        dueAt: f.dueAt || '',
        status: f.status
      };
    }));

    this.setData({
      pending: enriched.filter(f => f.status === 'pending'),
      completed: enriched.filter(f => f.status !== 'pending'),
      loaded: true
    });
  },

  // Tap on the row body opens the source contact. dataset access pattern
  // is identical to capture.handleField / index.handleOpenContact — one
  // assumption to verify on device, not three.
  handleOpenContact(e) {
    const contactId = e.currentTarget.dataset.contactId;
    if (!contactId) return;
    wx.navigateTo({
      url: `/pages/contact-card/contact-card?id=${encodeURIComponent(contactId)}`
    });
  },

  // catchtap on the button prevents the row's bindtap from also firing.
  async handleToggleStatus(e) {
    const id = e.currentTarget.dataset.id;
    const current = e.currentTarget.dataset.status;
    const next = current === 'pending' ? 'done' : 'pending';
    await contactStore.updateFollowupStatus(id, next);
    await this._refresh();
  }
};
</script>

<page>
  <view class="screen">
    <view class="card">
      <text class="title">待跟进</text>

      <!-- Empty state: no follow-ups in any bucket. -->
      <view
        class="empty"
        ink:if="{{ loaded && pending.length === 0 && completed.length === 0 }}"
      >
        <text class="empty-text">没有待跟进的事项。新建联系人时填上"下一步"与"跟进日期"会自动出现在这里。</text>
      </view>

      <!-- Pending section. -->
      <view class="section" ink:if="{{ pending.length > 0 }}">
        <text class="section-title">进行中</text>
        <scroll-view class="list" scroll-y="{{ true }}">
          <view
            class="row"
            ink:for="{{ pending }}"
            ink:key="id"
            data-contact-id="{{ item.contactId }}"
            bindtap="handleOpenContact"
          >
            <view class="row-main">
              <text class="row-title">{{ item.title }}</text>
              <view class="row-meta">
                <text class="row-contact">{{ item.contactName }}</text>
                <text class="row-sep" ink:if="{{ item.dueAt }}"> · </text>
                <text class="row-date" ink:if="{{ item.dueAt }}">{{ item.dueAt }}</text>
              </view>
            </view>
            <button
              class="row-btn"
              data-id="{{ item.id }}"
              data-status="{{ item.status }}"
              catchtap="handleToggleStatus"
            >完成</button>
          </view>
        </scroll-view>
      </view>

      <!-- Completed section. -->
      <view class="section" ink:if="{{ completed.length > 0 }}">
        <text class="section-title">已完成</text>
        <scroll-view class="list" scroll-y="{{ true }}">
          <view
            class="row row-done"
            ink:for="{{ completed }}"
            ink:key="id"
            data-contact-id="{{ item.contactId }}"
            bindtap="handleOpenContact"
          >
            <view class="row-main">
              <text class="row-title row-title-done">{{ item.title }}</text>
              <view class="row-meta">
                <text class="row-contact">{{ item.contactName }}</text>
                <text class="row-sep" ink:if="{{ item.dueAt }}"> · </text>
                <text class="row-date" ink:if="{{ item.dueAt }}">{{ item.dueAt }}</text>
              </view>
            </view>
            <button
              class="row-btn-secondary"
              data-id="{{ item.id }}"
              data-status="{{ item.status }}"
              catchtap="handleToggleStatus"
            >撤销</button>
          </view>
        </scroll-view>
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
  font-size: 22px;
  font-weight: 700;
  color: var(--color-text-primary);
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
}

/* Per SPEC §5: keep page within 380px tall — even two long lists fit. */
.list {
  max-height: 140px;
}

.row {
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: space-between;
  padding: 8px 10px;
  border: var(--border-width-thin) solid var(--border-color-muted);
  border-radius: var(--radius-sm);
  margin-bottom: var(--spacing-sm);
  gap: var(--spacing-sm);
}

.row-done {
  opacity: 0.6;
}

.row-main {
  display: flex;
  flex-direction: column;
  gap: 2px;
  flex: 1;
}

.row-title {
  font-size: 14px;
  font-weight: 600;
  color: var(--color-text-primary);
  line-height: 1.2;
}

.row-title-done {
  text-decoration: line-through;
}

.row-meta {
  display: flex;
  flex-direction: row;
  align-items: center;
  font-size: 12px;
  color: var(--color-text-secondary);
}

.row-contact,
.row-sep,
.row-date {
  font-size: 12px;
  color: var(--color-text-secondary);
}

.row-date {
  color: var(--color-primary);
}

.row-btn {
  padding: 6px 12px;
  background: var(--color-primary);
  color: var(--color-background);
  border: var(--border-width-default) solid var(--color-primary);
  border-radius: var(--radius-sm);
  font-size: 12px;
}

.row-btn-secondary {
  padding: 6px 12px;
  background: var(--color-surface);
  color: var(--color-text-primary);
  border: var(--border-width-default) solid var(--border-color-muted);
  border-radius: var(--radius-sm);
  font-size: 12px;
}
</style>
