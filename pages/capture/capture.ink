<script def>
{
  "navigationBarTitleText": "快速记录",
  "description": "Capture page: user types/dictates a short free-text note, hits 'parse', then edits each structured field in an inline confirmation card before saving. Phase 1 parser does ZERO extraction (see SPEC.md §6.1) — the confirm view exists to let the user author the structured fields directly, not to correct an inference.",
  "schema": {
    "data": {
      "type": "object",
      "properties": {
        "mode":           { "type": "string", "enum": ["input", "confirm"] },
        "rawInput":       { "type": "string" },
        "interestsInput": { "type": "string" },
        "errorMsg":       { "type": "string" }
      }
    }
  }
}
</script>

<script setup>
import wx from 'wx';
import { parser } from '../../services/parser.js';
import { contactStore } from '../../services/contact-store.js';

// Convert the comma-separated UI string into a clean string[].
// Accepts both Chinese full-width comma '，' and ASCII ','.
function splitInterests(input) {
  if (!input) return [];
  return input
    .split(/[,，]/)
    .map(s => s.trim())
    .filter(Boolean);
}

export default {
  data: {
    mode: 'input',
    rawInput: '',
    // draft mirrors the Contact schema (SPEC.md §7) except `interests`
    // which is edited as a single comma-joined string in the UI and
    // re-split on save.
    draft: {
      id: null,
      name: '',
      role: '',
      organization: '待补充',
      context: '',
      interests: [],
      nextAction: '',
      followUpAt: '',
      notes: ''
    },
    interestsInput: '',
    errorMsg: ''
  },

  onLoad() {
    console.log('[MeetMemo] capture loaded');
  },

  // --- input mode --------------------------------------------------------

  handleRawInput(e) {
    this.setData({ rawInput: e.detail.value, errorMsg: '' });
  },

  handleParse() {
    const result = parser.parse(this.data.rawInput);
    if (!this.data.rawInput.trim()) {
      this.setData({ errorMsg: '请先说一段话或输入一行文字。' });
      return;
    }
    this.setData({
      mode: 'confirm',
      draft: result.contact,
      interestsInput: '',
      errorMsg: ''
    });
  },

  // --- confirm mode ------------------------------------------------------

  // Generic field handler. Pages bind every input/textarea to this with
  // data-field="<key>"; AIUI exposes dataset on currentTarget identically
  // to WeChat. If a future Ink version drops dataset support, expand into
  // per-field handlers — until then, one handler beats nine.
  handleField(e) {
    const field = e.currentTarget.dataset.field;
    if (!field) return;
    const value = e.detail.value;
    // setData supports dotted paths in WeChat-style mini programs; AIUI
    // mirrors that. Falling back to a full setData(draft) reassignment
    // is also safe if needed.
    this.setData({ [`draft.${field}`]: value, errorMsg: '' });
  },

  handleInterestsInput(e) {
    this.setData({ interestsInput: e.detail.value, errorMsg: '' });
  },

  handleCancel() {
    this.setData({
      mode: 'input',
      draft: {
        id: null,
        name: '',
        role: '',
        organization: '待补充',
        context: '',
        interests: [],
        nextAction: '',
        followUpAt: '',
        notes: ''
      },
      interestsInput: '',
      errorMsg: ''
    });
  },

  async handleSave() {
    const draft = { ...this.data.draft };
    draft.interests = splitInterests(this.data.interestsInput);

    // SPEC.md §7: name is the one structured field we insist on having
    // before saving. Everything else can stay '待补充' or empty.
    if (!draft.name || !draft.name.trim()) {
      this.setData({ errorMsg: '姓名不能为空，至少给这个人一个标签。' });
      return;
    }

    // Lightweight ISO-date sanity check for followUpAt. We don't try to
    // be smart — just refuse obviously broken strings so the follow-up
    // list won't choke later.
    if (draft.followUpAt && !/^\d{4}-\d{2}-\d{2}$/.test(draft.followUpAt.trim())) {
      this.setData({ errorMsg: '跟进日期请用 YYYY-MM-DD 格式（例：2026-06-09）。' });
      return;
    }
    if (draft.followUpAt) draft.followUpAt = draft.followUpAt.trim();

    try {
      const saved = await contactStore.saveContact(draft);
      console.log('[MeetMemo] saved contact', saved.id);
      // Navigate to the detail card. contact-card.ink reads ?id= in
      // its onLoad query and pulls from the store.
      wx.navigateTo({
        url: `/pages/contact-card/contact-card?id=${encodeURIComponent(saved.id)}`
      });
    } catch (err) {
      console.error('[MeetMemo] save failed', err);
      this.setData({ errorMsg: '保存失败，请重试。' });
    }
  }
};
</script>

<page>
  <view class="screen">
    <!-- INPUT MODE: textarea + parse button. -->
    <view class="card" ink:if="{{ mode === 'input' }}">
      <text class="title">快速记录</text>
      <text class="hint">说一段话，下一步逐项确认。系统不会替你猜内容。</text>

      <textarea
        class="raw-input"
        placeholder="例如：王磊，教育 SaaS 创始人，对 AIUI Demo 感兴趣，下周二发资料。"
        value="{{ rawInput }}"
        bindinput="handleRawInput"
        maxlength="500"
      />

      <text class="error" ink:if="{{ errorMsg }}">{{ errorMsg }}</text>

      <view class="actions">
        <button class="btn-primary" bindtap="handleParse">下一步</button>
      </view>
    </view>

    <!-- CONFIRM MODE: scroll-view wraps editable fields + save/cancel. -->
    <scroll-view
      class="card-scroll"
      ink:if="{{ mode === 'confirm' }}"
      scroll-y="{{ true }}"
    >
      <view class="card-inner">
        <text class="title">确认信息</text>
        <text class="hint">每个字段都可以改。不知道的留空或写「待补充」。</text>

        <view class="field">
          <text class="field-label">姓名（必填）</text>
          <input
            class="field-input"
            data-field="name"
            value="{{ draft.name }}"
            placeholder="例：王磊"
            bindinput="handleField"
            maxlength="40"
          />
        </view>

        <view class="field">
          <text class="field-label">身份 / 角色</text>
          <input
            class="field-input"
            data-field="role"
            value="{{ draft.role }}"
            placeholder="例：教育 SaaS 创始人"
            bindinput="handleField"
            maxlength="60"
          />
        </view>

        <view class="field">
          <text class="field-label">机构</text>
          <input
            class="field-input"
            data-field="organization"
            value="{{ draft.organization }}"
            placeholder="待补充"
            bindinput="handleField"
            maxlength="60"
          />
        </view>

        <view class="field">
          <text class="field-label">场合</text>
          <input
            class="field-input"
            data-field="context"
            value="{{ draft.context }}"
            placeholder="例：AI 创业活动"
            bindinput="handleField"
            maxlength="60"
          />
        </view>

        <view class="field">
          <text class="field-label">关注点（逗号分隔）</text>
          <input
            class="field-input"
            value="{{ interestsInput }}"
            placeholder="例：AIUI Demo, 企业培训"
            bindinput="handleInterestsInput"
            maxlength="120"
          />
        </view>

        <view class="field">
          <text class="field-label">下一步</text>
          <input
            class="field-input"
            data-field="nextAction"
            value="{{ draft.nextAction }}"
            placeholder="例：下周二发送 Demo 资料"
            bindinput="handleField"
            maxlength="80"
          />
        </view>

        <view class="field">
          <text class="field-label">跟进日期</text>
          <input
            class="field-input"
            data-field="followUpAt"
            value="{{ draft.followUpAt }}"
            placeholder="YYYY-MM-DD"
            bindinput="handleField"
            maxlength="10"
          />
        </view>

        <view class="field">
          <text class="field-label">原话 / 备注</text>
          <textarea
            class="field-textarea"
            data-field="notes"
            value="{{ draft.notes }}"
            placeholder="原文已保留在这里，可补充。"
            bindinput="handleField"
            maxlength="500"
          />
        </view>

        <text class="error" ink:if="{{ errorMsg }}">{{ errorMsg }}</text>

        <view class="actions">
          <button class="btn-secondary" bindtap="handleCancel">重写</button>
          <button class="btn-primary" bindtap="handleSave">保存</button>
        </view>
      </view>
    </scroll-view>
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

.card,
.card-scroll {
  display: flex;
  flex-direction: column;
  width: 100%;
  background: var(--color-surface);
  border: var(--card-border-width) solid var(--card-border-color);
  border-radius: var(--radius-md);
  padding: var(--card-padding);
  gap: var(--spacing-md);
}

/* scroll-view needs a bounded height to actually scroll on InkView. */
.card-scroll {
  max-height: 360px;
}

.card-inner {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-md);
}

.title {
  font-size: 22px;
  font-weight: 700;
  color: var(--color-text-primary);
}

.hint {
  font-size: 13px;
  color: var(--color-text-secondary);
  line-height: 1.4;
}

.raw-input {
  width: 100%;
  min-height: 96px;
  padding: var(--input-padding-y) var(--input-padding-x);
  background: var(--input-background-color);
  border: var(--input-border-width) solid var(--input-border-color);
  border-radius: var(--input-radius);
  color: var(--color-text-primary);
  font-size: 14px;
  line-height: 1.4;
  box-sizing: border-box;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.field-label {
  font-size: 12px;
  color: var(--color-text-secondary);
}

.field-input {
  width: 100%;
  padding: var(--input-padding-y) var(--input-padding-x);
  background: var(--input-background-color);
  border: var(--input-border-width) solid var(--input-border-color);
  border-radius: var(--input-radius);
  color: var(--color-text-primary);
  font-size: 14px;
  box-sizing: border-box;
}

.field-textarea {
  width: 100%;
  min-height: 70px;
  padding: var(--input-padding-y) var(--input-padding-x);
  background: var(--input-background-color);
  border: var(--input-border-width) solid var(--input-border-color);
  border-radius: var(--input-radius);
  color: var(--color-text-primary);
  font-size: 14px;
  line-height: 1.4;
  box-sizing: border-box;
}

.error {
  font-size: 13px;
  color: var(--border-color-danger);
}

.actions {
  display: flex;
  flex-direction: row;
  gap: var(--spacing-sm);
  margin-top: var(--spacing-sm);
}

.btn-primary {
  flex: 1;
  padding: 10px 16px;
  background: var(--color-primary);
  color: var(--color-background);
  border: var(--border-width-default) solid var(--color-primary);
  border-radius: var(--radius-md);
  font-size: 15px;
  font-weight: 600;
}

.btn-secondary {
  flex: 1;
  padding: 10px 16px;
  background: var(--color-surface);
  color: var(--color-text-primary);
  border: var(--border-width-default) solid var(--border-color-muted);
  border-radius: var(--radius-md);
  font-size: 15px;
}
</style>
