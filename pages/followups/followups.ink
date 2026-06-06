<script def>
{
  "navigationBarTitleText": "待跟进",
  "description": "Hardware-key follow-up HUD. Arrow keys select one task, Enter toggles pending/done, ArrowRight opens the related contact, Backspace returns.",
  "schema": {
    "data": {
      "type": "object",
      "properties": {
        "items": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "id": { "type": "string" },
              "contactId": { "type": "string" },
              "contactName": { "type": "string" },
              "title": { "type": "string" },
              "dueAt": { "type": "string" },
              "status": { "type": "string" },
              "className": { "type": "string" },
              "statusText": { "type": "string" },
              "actionText": { "type": "string" },
              "metaText": { "type": "string" }
            },
            "required": ["id", "contactId", "contactName", "title", "status", "className"]
          }
        },
        "selectedTitle": { "type": "string" },
        "selectedMeta": { "type": "string" },
        "selectedAction": { "type": "string" },
        "secondaryAction": { "type": "string" },
        "selectedId": { "type": "string" },
        "hasItems": { "type": "boolean" },
        "isEmpty": { "type": "boolean" },
        "isDeleteConfirm": { "type": "boolean" },
        "statusText": { "type": "string" }
      },
      "required": ["items", "selectedTitle", "selectedMeta", "selectedAction", "secondaryAction", "selectedId", "hasItems", "isEmpty", "isDeleteConfirm", "statusText"]
    }
  }
}
</script>

<script setup>
import wx from 'wx';
import { contactStore } from '../../services/contact-store.js';

function createItemView(item, selectedId) {
  const isSelected = item.id === selectedId;
  const isDone = item.status !== 'pending';
  const className = isSelected
    ? 'task-row task-row-active'
    : isDone
      ? 'task-row task-row-done'
      : 'task-row';

  return {
    ...item,
    className,
    statusText: isDone ? '已完成' : '待处理',
    actionText: isDone ? 'Enter 撤销' : 'Enter 完成',
    metaText: item.dueAt ? `${item.contactName} · ${item.dueAt}` : item.contactName
  };
}

function createView(state) {
  const selected = state.items.find(item => item.id === state.selectedId) || state.items[0] || null;
  const selectedId = selected ? selected.id : '';
  const rows = state.items.map(item => createItemView(item, selectedId));
  const selectedView = selected ? createItemView(selected, selectedId) : null;
  const isDeleteConfirm = Boolean(state.isDeleteConfirm && selectedView);

  return {
    items: rows,
    selectedId,
    selectedTitle: isDeleteConfirm
      ? '确认删除任务'
      : selectedView
        ? selectedView.title
        : '没有待跟进',
    selectedMeta: isDeleteConfirm
      ? selectedView.title
      : selectedView
        ? selectedView.metaText
        : '保存联系人时填写下一步和日期，会出现在这里。',
    selectedAction: isDeleteConfirm
      ? 'Enter 删除'
      : selectedView
        ? selectedView.actionText
        : 'Back 返回',
    hasItems: rows.length > 0,
    isEmpty: rows.length === 0,
    isDeleteConfirm,
    secondaryAction: isDeleteConfirm ? 'Back 取消' : 'Left 删除 · Right 联系人',
    statusText: isDeleteConfirm ? 'Confirm' : rows.length ? `${rows.length} Tasks` : 'Empty'
  };
}

function emptyView() {
  return createView({
    items: [],
    selectedId: ''
  });
}

export default {
  data: emptyView(),

  async onLoad() {
    await this.refresh();
  },

  async onShow() {
    await this.refresh();
  },

  onKeyDown(event) {
    const code = event && event.code;
    if (code === 'Backspace') {
      if (this.data.isDeleteConfirm) {
        this.setData(createView({
          items: this.data.items,
          selectedId: this.data.selectedId,
          isDeleteConfirm: false
        }));
        return;
      }
      wx.navigateBack();
      return;
    }
    if (this.data.isDeleteConfirm && code === 'Enter') {
      this.deleteSelectedFollowup();
      return;
    }
    if (this.data.isDeleteConfirm) {
      return;
    }
    if (code === 'ArrowDown') {
      this.moveSelection(1);
      return;
    }
    if (code === 'ArrowUp') {
      this.moveSelection(-1);
      return;
    }
    if (code === 'ArrowRight') {
      this.openSelectedContact();
      return;
    }
    if (code === 'ArrowLeft') {
      this.confirmDeleteSelected();
      return;
    }
    if (code === 'Enter') {
      this.toggleSelectedStatus();
    }
  },

  async refresh(preferredId) {
    const followups = await contactStore.listFollowups();
    const items = await Promise.all(followups.map(async followup => {
      const contact = await contactStore.getContact(followup.contactId);
      return {
        id: followup.id,
        contactId: followup.contactId,
        contactName: contact ? (contact.name || '待补充') : '未知联系人',
        title: followup.title,
        dueAt: followup.dueAt || '',
        status: followup.status
      };
    }));

    const selectedId = preferredId && items.some(item => item.id === preferredId)
      ? preferredId
      : items[0]
        ? items[0].id
        : '';

    this.setData(createView({ items, selectedId, isDeleteConfirm: false }));
  },

  moveSelection(delta) {
    if (!this.data.items.length) return;
    const ids = this.data.items.map(item => item.id);
    const currentIndex = ids.indexOf(this.data.selectedId);
    const nextIndex = (currentIndex + delta + ids.length) % ids.length;
    this.setData(createView({
      items: this.data.items,
      selectedId: ids[nextIndex],
      isDeleteConfirm: false
    }));
  },

  confirmDeleteSelected() {
    if (!this.data.selectedId) return;
    this.setData(createView({
      items: this.data.items,
      selectedId: this.data.selectedId,
      isDeleteConfirm: true
    }));
  },

  async deleteSelectedFollowup() {
    if (!this.data.selectedId) return;
    const deletedId = this.data.selectedId;
    await contactStore.deleteFollowup(deletedId);
    await this.refresh();
  },

  async toggleSelectedStatus() {
    if (!this.data.selectedId) return;
    const item = this.data.items.find(row => row.id === this.data.selectedId);
    if (!item) return;
    const next = item.status === 'pending' ? 'done' : 'pending';
    await contactStore.updateFollowupStatus(item.id, next);
    await this.refresh(item.id);
  },

  openSelectedContact() {
    const item = this.data.items.find(row => row.id === this.data.selectedId);
    if (!item || !item.contactId) return;
    wx.navigateTo({
      url: `/pages/contact-card/contact-card?id=${encodeURIComponent(item.contactId)}`
    });
  }
};
</script>

<page>
<view class="page">
    <view class="safe-zone">
      <view class="top-row">
        <view class="brand-mark">
          <text class="brand-dot"></text>
          <text class="brand-name">MeetMemo</text>
        </view>
        <text class="status">{{ statusText }}</text>
      </view>

      <view class="hero">
        <text class="kicker">待跟进</text>
        <text class="title">{{ selectedTitle }}</text>
        <text class="hint">{{ selectedMeta }}</text>
      </view>

      <view class="task-list" ink:if="{{ hasItems }}">
        <view class="{{ item.className }}" ink:for="{{ items }}" ink:key="id">
          <view class="task-main">
            <text class="task-title">{{ item.title }}</text>
            <text class="task-meta">{{ item.metaText }}</text>
          </view>
          <text class="task-status">{{ item.statusText }}</text>
        </view>
      </view>

      <view class="empty-card" ink:if="{{ isEmpty }}">
        <text class="empty-text">暂无任务</text>
        <text class="empty-hint">保存联系人时补上下一步和日期。</text>
      </view>

      <view class="bottom-row">
        <text class="key-hint">{{ selectedAction }}</text>
        <text class="key-hint">{{ secondaryAction }}</text>
      </view>
    </view>
  </view>
</page>

<style>
.page {
  width: 100%;
  min-height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  box-sizing: border-box;
  background: #000000;
  color: #f5f7fa;
  font-family: HarmonyOS_SansSC_Regular;
}

.safe-zone {
  width: 480px;
  height: 400px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  box-sizing: border-box;
  padding: 18px 22px;
  border: 1.5px solid rgba(64, 255, 94, 0.4);
  border-radius: 12px;
  background: #000000;
}

.top-row,
.bottom-row,
.brand-mark,
.task-row {
  display: flex;
  flex-direction: row;
  align-items: center;
}

.top-row,
.bottom-row,
.task-row {
  justify-content: space-between;
}

.brand-dot {
  width: 12px;
  height: 12px;
  margin-right: 8px;
  border-radius: 12px;
  border: 1.5px solid #40ff5e;
  box-sizing: border-box;
}

.brand-name,
.status,
.key-hint {
  font-size: 16px;
  line-height: 22px;
}

.brand-name {
  color: #40ff5e;
  font-family: HarmonyOS_SansSC_Medium;
}

.status,
.key-hint {
  color: rgba(64, 255, 94, 0.8);
}

.hero,
.task-list,
.task-main,
.empty-card {
  display: flex;
  flex-direction: column;
}

.hero {
  gap: 6px;
}

.kicker {
  font-size: 18px;
  line-height: 24px;
  color: rgba(64, 255, 94, 0.85);
}

.title {
  font-size: 30px;
  line-height: 38px;
  color: #f5f7fa;
  font-family: HarmonyOS_SansSC_Medium;
}

.hint {
  font-size: 18px;
  line-height: 24px;
  color: rgba(245, 247, 250, 0.68);
}

.task-list {
  gap: 8px;
}

.task-row {
  min-height: 44px;
  padding: 6px 12px;
  border: 1.5px solid rgba(64, 255, 94, 0.32);
  border-radius: 12px;
  box-sizing: border-box;
}

.task-row-active {
  border-color: #40ff5e;
}

.task-row-done {
  opacity: 0.58;
}

.task-main {
  gap: 2px;
  flex: 1;
}

.task-title {
  font-size: 18px;
  line-height: 24px;
  color: #f5f7fa;
}

.task-meta,
.task-status,
.empty-hint {
  font-size: 16px;
  line-height: 22px;
  color: rgba(245, 247, 250, 0.62);
}

.task-status {
  color: rgba(64, 255, 94, 0.82);
}

.empty-card {
  gap: 6px;
  padding: 14px 16px;
  border: 1.5px solid rgba(245, 247, 250, 0.18);
  border-radius: 12px;
  box-sizing: border-box;
}

.empty-text {
  font-size: 22px;
  line-height: 30px;
  color: #f5f7fa;
}

.key-hint {
  max-width: 320px;
}
</style>
