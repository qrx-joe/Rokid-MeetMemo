<script def>
{
  "navigationBarTitleText": "联系人卡片",
  "description": "Structured relationship card rendered as a compact Rokid HUD. Template conditions use precomputed booleans for Ink compatibility.",
  "schema": {
    "data": {
      "type": "object",
      "properties": {
        "name": { "type": "string" },
        "role": { "type": "string" },
        "metaText": { "type": "string" },
        "interestRows": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "value": { "type": "string" }
            },
            "required": ["value"]
          }
        },
        "nextAction": { "type": "string" },
        "followUpAt": { "type": "string" },
        "notes": { "type": "string" },
        "contactId": { "type": "string" },
        "hasRole": { "type": "boolean" },
        "hasMeta": { "type": "boolean" },
        "hasInterests": { "type": "boolean" },
        "hasNextAction": { "type": "boolean" },
        "hasFollowUpAt": { "type": "boolean" },
        "hasNotes": { "type": "boolean" },
        "hasPhoto": { "type": "boolean" },
        "photoData": { "type": "string" },
        "canDelete": { "type": "boolean" },
        "isDeleteConfirm": { "type": "boolean" },
        "selectedAction": { "type": "string" },
        "actionRows": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "id": { "type": "string" },
              "label": { "type": "string" },
              "className": { "type": "string" }
            },
            "required": ["id", "label", "className"]
          }
        },
        "primaryKeyHint": { "type": "string" },
        "secondaryKeyHint": { "type": "string" },
        "statusText": { "type": "string" },
        "hasPhoto": { "type": "boolean" },
        "photoData": { "type": "string" },
        "contact": {
          "type": "object",
          "properties": {
            "id": { "type": "string" },
            "name": { "type": "string" },
            "role": { "type": "string" },
            "organization": { "type": "string" },
            "context": { "type": "string" },
            "interests": {
              "type": "array",
              "items": { "type": "string" }
            },
            "nextAction": { "type": "string" },
            "followUpAt": { "type": "string" },
            "notes": { "type": "string" }
          },
          "required": ["id", "name", "role", "organization", "context", "interests", "nextAction", "followUpAt", "notes"]
        }
      },
      "required": ["name", "role", "metaText", "interestRows", "nextAction", "followUpAt", "notes", "contactId", "hasRole", "hasMeta", "hasInterests", "hasNextAction", "hasFollowUpAt", "hasNotes", "hasPhoto", "photoData", "canDelete", "isDeleteConfirm", "selectedAction", "actionRows", "primaryKeyHint", "secondaryKeyHint", "statusText", "contact"]
    }
  }
}
</script>

<script setup>
import wx from 'wx';
import { contactStore, __internal } from '../../services/contact-store.js';

const UNKNOWN = '待补充';

function actionRow(id, label, selectedAction) {
  return {
    id,
    label,
    className: id === selectedAction ? 'card-action card-action-active' : 'card-action'
  };
}

function createCardView(contact, ui = {}) {
  const selectedAction = ui.selectedAction || 'return';
  const isDeleteConfirm = Boolean(ui.isDeleteConfirm);
  const organization = contact.organization && contact.organization !== UNKNOWN
    ? contact.organization
    : '';
  const context = contact.context || '';
  const metaParts = [organization, context].filter(Boolean);
  const interests = Array.isArray(contact.interests) ? contact.interests : [];

  return {
    contactId: contact.id || '',
    name: contact.name || UNKNOWN,
    role: contact.role || '',
    metaText: metaParts.join(' · '),
    interestRows: interests.map(value => ({ value })),
    nextAction: contact.nextAction || '',
    followUpAt: contact.followUpAt || '',
    notes: contact.notes || '',
    contact,
    hasRole: Boolean(contact.role),
    hasMeta: metaParts.length > 0,
    hasInterests: interests.length > 0,
    hasNextAction: Boolean(contact.nextAction),
    hasFollowUpAt: Boolean(contact.followUpAt),
    hasNotes: Boolean(contact.notes),
    hasPhoto: Boolean(contact.photo),
    photoData: contact.photo || '',
    canDelete: Boolean(contact.id && contact.id !== __internal.DEMO_CONTACT_ID),
    selectedAction,
    isDeleteConfirm,
    actionRows: [
      actionRow('return', '返回', selectedAction),
      actionRow('delete', isDeleteConfirm ? '确认删除' : '删除联系人', selectedAction)
    ],
    primaryKeyHint: isDeleteConfirm ? 'Enter 确认删除' : 'Enter 执行',
    secondaryKeyHint: isDeleteConfirm ? 'Back 取消' : '方向键选择 · Back 返回',
    statusText: isDeleteConfirm ? 'Confirm' : 'Card'
  };
}

function emptyView() {
  return createCardView({
    id: '',
    name: '加载中',
    role: '',
    organization: UNKNOWN,
    context: '',
    interests: [],
    nextAction: '',
    followUpAt: '',
    notes: ''
  });
}

export default {
  data: emptyView(),

  async onLoad(query) {
    const requestedId = query && query.id ? query.id : null;
    let contact = null;

    if (requestedId) {
      contact = await contactStore.getContact(requestedId);
      if (!contact) {
        console.warn('[MeetMemo] contact id not found, falling back to demo', requestedId);
      }
    }

    if (!contact) {
      contact = await contactStore.getContact(__internal.DEMO_CONTACT_ID);
    }

    if (contact) {
      this.setData(createCardView(contact));
    }
  },

  onKeyDown(event) {
    const code = event && event.code;
    if (code === 'Backspace') {
      if (this.data.isDeleteConfirm) {
        this.setData(createCardView(this.data.contact, { selectedAction: 'delete' }));
        return;
      }
      wx.navigateBack();
      return;
    }

    if ((code === 'ArrowDown' || code === 'ArrowRight') && this.data.canDelete) {
      this.setData(createCardView(this.data.contact, { selectedAction: 'delete' }));
      return;
    }

    if ((code === 'ArrowUp' || code === 'ArrowLeft') && this.data.canDelete) {
      this.setData(createCardView(this.data.contact, { selectedAction: 'return' }));
      return;
    }

    if (code === 'Enter') {
      this.runSelectedAction();
    }
  },

  async runSelectedAction() {
    if (this.data.selectedAction !== 'delete' || !this.data.canDelete) {
      wx.navigateBack();
      return;
    }

    if (!this.data.isDeleteConfirm) {
      this.setData(createCardView(this.data.contact, {
        selectedAction: 'delete',
        isDeleteConfirm: true
      }));
      return;
    }

    await contactStore.deleteContact(this.data.contactId);
    wx.navigateBack();
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

      <view class="header">
        <text class="name">{{ name }}</text>
        <text class="role" ink:if="{{ hasRole }}">{{ role }}</text>
        <text class="meta" ink:if="{{ hasMeta }}">{{ metaText }}</text>
      </view>

      <view class="photo-thumb-wrap" ink:if="{{ hasPhoto }}">
        <image class="photo-thumb" src="{{ photoData }}" mode="aspectFit" />
      </view>

      <view class="interests" ink:if="{{ hasInterests }}">
        <view class="chip" ink:for="{{ interestRows }}" ink:key="value">
          <text class="chip-text">{{ item.value }}</text>
        </view>
      </view>

      <view class="action-card" ink:if="{{ hasNextAction }}">
        <text class="action-label">下一步</text>
        <text class="action-text">{{ nextAction }}</text>
        <text class="action-date" ink:if="{{ hasFollowUpAt }}">{{ followUpAt }}</text>
      </view>

      <view class="note-card" ink:if="{{ hasNotes }}">
        <text class="note-label">原文</text>
        <text class="note-text">{{ notes }}</text>
      </view>

      <view class="card-actions" ink:if="{{ canDelete }}">
        <view class="{{ item.className }}" ink:for="{{ actionRows }}" ink:key="id">
          <text class="card-action-text">{{ item.label }}</text>
        </view>
      </view>

      <view class="bottom-row">
        <text class="key-hint">{{ primaryKeyHint }}</text>
        <text class="key-hint">{{ secondaryKeyHint }}</text>
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
.brand-mark {
  display: flex;
  flex-direction: row;
  align-items: center;
}

.top-row,
.bottom-row {
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

.header,
.action-card,
.note-card,
.card-actions {
  display: flex;
  flex-direction: column;
}

.header {
  gap: 6px;
}

.name {
  font-size: 32px;
  line-height: 40px;
  color: #f5f7fa;
  font-family: HarmonyOS_SansSC_Medium;
}

.role {
  font-size: 24px;
  line-height: 32px;
  color: rgba(245, 247, 250, 0.82);
}

.meta {
  font-size: 18px;
  line-height: 24px;
  color: rgba(245, 247, 250, 0.62);
}

.photo-thumb-wrap {
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 6px 0;
}

.photo-thumb {
  width: 120px;
  height: 80px;
  object-fit: cover;
  border-radius: 8px;
  border: 1.5px solid rgba(64, 255, 94, 0.4);
}

.interests {
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
  gap: 8px;
}

.chip {
  display: flex;
  padding: 4px 10px;
  border: 1.5px solid rgba(64, 255, 94, 0.7);
  border-radius: 12px;
  box-sizing: border-box;
}

.chip-text {
  font-size: 16px;
  line-height: 22px;
  color: #40ff5e;
}

.action-card,
.note-card {
  gap: 4px;
  padding: 12px 14px;
  border: 1.5px solid rgba(64, 255, 94, 0.55);
  border-radius: 12px;
  box-sizing: border-box;
}

.action-label,
.note-label {
  font-size: 16px;
  line-height: 22px;
  color: rgba(64, 255, 94, 0.85);
}

.action-text {
  font-size: 22px;
  line-height: 30px;
  color: #f5f7fa;
}

.action-date,
.note-text {
  font-size: 16px;
  line-height: 22px;
  color: rgba(245, 247, 250, 0.68);
}

.card-actions {
  gap: 8px;
}

.card-action {
  display: flex;
  height: 34px;
  align-items: center;
  padding: 0 12px;
  border: 1.5px solid rgba(64, 255, 94, 0.32);
  border-radius: 12px;
  box-sizing: border-box;
}

.card-action-active {
  border-color: #40ff5e;
}

.card-action-text {
  font-size: 16px;
  line-height: 22px;
  color: #f5f7fa;
}

.key-hint {
  max-width: 320px;
}
</style>
