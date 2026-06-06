<script def>
{
  "navigationBarTitleText": "快速记录",
  "description": "Rokid glasses HUD capture flow. Enter starts voice capture for the current step, Backspace goes back or exits. The page gathers one raw note, prompts for missing structured fields, shows a review card, and saves only after explicit confirmation.",
  "schema": {
    "data": {
      "type": "object",
      "properties": {
        "mode": { "type": "string" },
        "statusText": { "type": "string" },
        "promptText": { "type": "string" },
        "primaryText": { "type": "string" },
        "hintText": { "type": "string" },
        "progressText": { "type": "string" },
        "summaryRows": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "label": { "type": "string" },
              "value": { "type": "string" }
            },
            "required": ["label", "value"]
          }
        },
        "hasError": { "type": "boolean" },
        "isReview": { "type": "boolean" },
        "isSaved": { "type": "boolean" },
        "stepIndex": { "type": "number" },
        "savedId": { "type": "string" },
        "errorMsg": { "type": "string" },
        "draft": {
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
        },
        "isCapturing": { "type": "boolean" },
        "showSummary": { "type": "boolean" },
        "showNote": { "type": "boolean" },
        "photoData": { "type": "string" },
        "hasPhoto": { "type": "boolean" }
      },
      "required": ["mode", "statusText", "promptText", "primaryText", "hintText", "progressText", "summaryRows", "hasError", "isReview", "isSaved", "stepIndex", "savedId", "errorMsg", "draft", "isCapturing", "showSummary", "showNote", "photoData", "hasPhoto"]
    }
  }
}
</script>

<script setup>
import wx from 'wx';
import { parser } from '../../services/parser.js';
import { contactStore } from '../../services/contact-store.js';

const UNKNOWN = '待补充';

const STEPS = [
  {
    key: 'notes',
    label: '原始记录',
    prompt: '请说一句你想记下的会面信息。',
    hint: '例：王磊，教育 SaaS 创始人，对 AIUI Demo 感兴趣，下周二发资料。'
  },
  {
    key: 'name',
    label: '姓名',
    prompt: '请说这个人的姓名。',
    hint: '姓名是保存前唯一必填字段。'
  },
  {
    key: 'role',
    label: '身份',
    prompt: '请说他的身份或角色。',
    hint: '不知道可以说待补充。'
  },
  {
    key: 'organization',
    label: '机构',
    prompt: '请说他的机构。',
    hint: '不知道可以说待补充。'
  },
  {
    key: 'context',
    label: '场合',
    prompt: '请说你们在哪里认识。',
    hint: '例：AI 创业活动、客户拜访、面试现场。'
  },
  {
    key: 'interests',
    label: '关注点',
    prompt: '请说他的关注点。',
    hint: '多个关注点可以连续说出来。'
  },
  {
    key: 'nextAction',
    label: '下一步',
    prompt: '请说下一步要做什么。',
    hint: '没有跟进动作可以说跳过。'
  },
  {
    key: 'followUpAt',
    label: '跟进日期',
    prompt: '请说跟进日期，最好是 YYYY-MM-DD。',
    hint: '没有日期可以说跳过。'
  }
];

const DEMO_ANSWERS = {
  notes: '王磊，教育 SaaS 创始人，对 AIUI Demo 感兴趣，下周二发送 Demo 资料。',
  name: '王磊',
  role: '教育 SaaS 创始人',
  organization: UNKNOWN,
  context: 'AI 创业活动',
  interests: 'AIUI Demo',
  nextAction: '发送 Demo 资料',
  followUpAt: '2026-06-09'
};

function createDraft() {
  return {
    id: '',
    name: '',
    role: '',
    organization: UNKNOWN,
    context: '',
    interests: [],
    nextAction: '',
    followUpAt: '',
    notes: '',
    photo: ''
  };
}

function cleanText(value) {
  return typeof value === 'string' ? value.trim() : '';
}

function splitInterests(input) {
  return cleanText(input)
    .split(/[,，、]/)
    .map(item => item.trim())
    .filter(Boolean);
}

function isSkipText(text) {
  const value = cleanText(text);
  return value === '跳过' || value === '不用' || value === '没有' || value === '无';
}

function extractSpeechText(event) {
  const resultIndex = event && typeof event.resultIndex === 'number' ? event.resultIndex : 0;
  const results = event && event.results;
  const candidate = results && results[resultIndex] && results[resultIndex][0];
  return cleanText(candidate && candidate.transcript);
}

function getStepValue(draft, key) {
  if (key === 'interests') {
    return draft.interests.length ? draft.interests.join('、') : '';
  }
  return draft[key] || '';
}

function createRows(draft) {
  return [
    { label: '姓名', value: draft.name || UNKNOWN },
    { label: '身份', value: draft.role || UNKNOWN },
    { label: '机构', value: draft.organization || UNKNOWN },
    { label: '场合', value: draft.context || UNKNOWN },
    { label: '关注', value: draft.interests.length ? draft.interests.join('、') : UNKNOWN },
    { label: '下一步', value: draft.nextAction || UNKNOWN },
    { label: '日期', value: draft.followUpAt || UNKNOWN }
  ];
}

function createView(state) {
  const step = STEPS[state.stepIndex] || null;
  const hasStep = Boolean(step);
  const isReview = state.mode === 'review';
  const isSaved = state.mode === 'saved';
  const draft = state.draft;
  const stepValue = step ? getStepValue(draft, step.key) : '';

  let primaryText = '按 Enter 开始记录';
  let promptText = '主动说一段简短笔记，MeetMemo 会逐项确认。';
  let hintText = 'Enter 开始，Backspace 退出。';
  let progressText = 'Ready';

  if (hasStep) {
    primaryText = stepValue || '等待语音输入';
    promptText = step.prompt;
    hintText = stepValue ? 'Enter 继续下一项，Backspace 重录上一项。' : step.hint;
    progressText = `${state.stepIndex + 1}/${STEPS.length}`;
  }

  if (state.mode === 'listening') {
    primaryText = '正在听...';
    hintText = '请直接说话，识别完成后按 Enter 继续。';
  }

  if (isReview) {
    primaryText = draft.name || UNKNOWN;
    promptText = '请确认这张关系卡片。';
    hintText = 'Enter 保存，Backspace 返回修改。';
    progressText = '确认';
  }

  if (isSaved) {
    primaryText = draft.name || '已保存';
    promptText = '已保存关系卡片。';
    hintText = draft.nextAction && draft.followUpAt
      ? '已生成跟进任务。Backspace 返回。'
      : '没有完整跟进动作和日期，未生成任务。Backspace 返回。';
    progressText = '完成';
  }

  if (state.errorMsg) {
    hintText = state.errorMsg;
  }

  return {
    mode: state.mode,
    stepIndex: state.stepIndex,
    draft,
    savedId: state.savedId,
    errorMsg: state.errorMsg,
    statusText: state.statusText,
    promptText,
    primaryText,
    hintText,
    progressText,
    summaryRows: createRows(draft),
    hasError: Boolean(state.errorMsg),
    isReview,
    isSaved,
    isCapturing: hasStep && !isReview && !isSaved,
    showSummary: isReview || isSaved,
    showNote: Boolean(draft.notes) && !isReview && !isSaved,
    photoData: draft.photo || '',
    hasPhoto: Boolean(draft.photo)
  };
}

function createInitialState() {
  return createView({
    mode: 'ready',
    stepIndex: -1,
    draft: createDraft(),
    savedId: '',
    errorMsg: '',
    statusText: 'Ready'
  });
}

export default {
  data: createInitialState(),

  onLoad(query) {
    const photoKey = query && query.photoKey ? query.photoKey : '';
    let photoData = '';
    if (photoKey) {
      photoData = contactStore.getPhoto(photoKey);
      contactStore.deletePhoto(photoKey);
    }

    const draft = createDraft();
    draft.photo = photoData;

    this.setData(createView({
      mode: 'ready',
      stepIndex: -1,
      draft,
      savedId: '',
      errorMsg: '',
      statusText: 'Ready'
    }));

    this.speak(photoData ? '照片已加载，按 Enter 开始补充信息。' : 'MeetMemo ready. Press Enter to start.');
  },

  onKeyDown(event) {
    const code = event && event.code;
    if (code === 'Backspace') {
      this.handleBack();
      return;
    }
    if (code !== 'Enter' || this.data.mode === 'listening') {
      return;
    }
    this.handleEnter();
  },

  async handleEnter() {
    if (this.data.mode === 'ready') {
      this.setCaptureState(0, createDraft(), '', 'Prompt');
      return;
    }

    if (this.data.mode === 'review') {
      await this.saveDraft();
      return;
    }

    if (this.data.mode === 'saved') {
      wx.navigateBack();
      return;
    }

    await this.advanceOrListen();
  },

  handleBack() {
    if (this.data.mode === 'ready') {
      wx.navigateBack();
      return;
    }

    if (this.data.mode === 'saved') {
      wx.navigateBack();
      return;
    }

    if (this.data.mode === 'review') {
      const targetStep = this.data.stepIndex >= 0 ? this.data.stepIndex : STEPS.length - 1;
      this.setCaptureState(targetStep, this.data.draft, '', 'Editing');
      return;
    }

    const previous = this.data.stepIndex - 1;
    if (previous < 0) {
      this.setData(createInitialState());
      this.speak('Capture cancelled.');
      return;
    }
    this.setCaptureState(previous, this.data.draft, '', 'Editing');
  },

  async advanceOrListen() {
    const step = STEPS[this.data.stepIndex];
    if (this.data.statusText === 'Editing' || this.data.statusText === 'Check date' || this.data.errorMsg) {
      await this.listenForCurrentStep();
      return;
    }
    const value = step ? getStepValue(this.data.draft, step.key) : '';
    if (!value && this.data.statusText !== 'Captured') {
      await this.listenForCurrentStep();
      return;
    }

    const nextIndex = this.data.stepIndex + 1;
    if (nextIndex >= STEPS.length) {
      this.showReview();
      return;
    }
    this.setCaptureState(nextIndex, this.data.draft, '', 'Prompt');
  },

  setCaptureState(stepIndex, draft, errorMsg, statusText) {
    this.setData(createView({
      mode: 'capturing',
      stepIndex,
      draft,
      savedId: this.data.savedId || '',
      errorMsg,
      statusText
    }));
    const step = STEPS[stepIndex];
    if (step) {
      this.speak(step.prompt);
    }
  },

  async listenForCurrentStep() {
    const step = STEPS[this.data.stepIndex];
    if (!step) return;

    this.setData(createView({
      mode: 'listening',
      stepIndex: this.data.stepIndex,
      draft: this.data.draft,
      savedId: this.data.savedId || '',
      errorMsg: '',
      statusText: 'Listening'
    }));

    try {
      const text = await this.recognizeSpeech(step.key);
      this.applyStepText(step, text);
    } catch (error) {
      console.log('[MeetMemo] voice unavailable, using demo fallback', error);
      this.applyStepText(step, DEMO_ANSWERS[step.key] || '');
    }
  },

  recognizeSpeech(key) {
    if (typeof SpeechRecognition !== 'undefined') {
      return new Promise((resolve, reject) => {
        const recognition = new SpeechRecognition();
        recognition.lang = 'zh-CN';
        recognition.continuous = false;
        recognition.interimResults = false;
        recognition.maxAlternatives = 1;
        recognition.onresult = event => {
          const text = extractSpeechText(event);
          if (text) resolve(text);
          else reject(new Error('empty speech result'));
        };
        recognition.onerror = event => {
          reject(new Error((event && event.message) || 'speech recognition error'));
        };
        recognition.onnomatch = () => reject(new Error('speech no match'));
        recognition.start();
      });
    }

    if (wx.speech && typeof wx.speech.startRecognition === 'function') {
      const text = cleanText(wx.speech.startRecognition());
      if (text) return Promise.resolve(text);
    }

    return Promise.reject(new Error(`speech unavailable for ${key}`));
  },

  applyStepText(step, rawText) {
    const text = cleanText(rawText);
    const draft = { ...this.data.draft };

    if (!text) {
      this.setCaptureState(this.data.stepIndex, draft, '没有听到内容，请按 Enter 重试。', 'Retry');
      return;
    }

    if (step.key === 'notes') {
      const result = parser.parse(text);
      Object.assign(draft, result.contact);
      draft.id = draft.id || '';
      draft.notes = text;
    } else if (step.key === 'interests') {
      draft.interests = isSkipText(text) ? [] : splitInterests(text);
    } else if (step.key === 'followUpAt') {
      draft.followUpAt = isSkipText(text) ? '' : text;
    } else if (step.key === 'organization') {
      draft.organization = isSkipText(text) ? UNKNOWN : text;
    } else {
      draft[step.key] = isSkipText(text) ? '' : text;
    }

    if (step.key === 'followUpAt' && draft.followUpAt && !/^\d{4}-\d{2}-\d{2}$/.test(draft.followUpAt)) {
      this.setData(createView({
        mode: 'capturing',
        stepIndex: this.data.stepIndex,
        draft,
        savedId: this.data.savedId || '',
        errorMsg: '日期请用 YYYY-MM-DD。按 Enter 重录，或 Backspace 返回。',
        statusText: 'Check date'
      }));
      this.speak('Please use year month day format.');
      return;
    }

    this.setData(createView({
      mode: 'capturing',
      stepIndex: this.data.stepIndex,
      draft,
      savedId: this.data.savedId || '',
      errorMsg: '',
      statusText: 'Captured'
    }));
    this.speak('Recorded. Press Enter to continue.');
  },

  showReview() {
    this.setData(createView({
      mode: 'review',
      stepIndex: this.data.stepIndex,
      draft: this.data.draft,
      savedId: this.data.savedId || '',
      errorMsg: '',
      statusText: 'Review'
    }));
    this.speak('Please confirm the card. Press Enter to save.');
  },

  async saveDraft() {
    const draft = { ...this.data.draft };
    draft.name = cleanText(draft.name);
    draft.followUpAt = cleanText(draft.followUpAt);

    if (!draft.name) {
      this.setData(createView({
        mode: 'review',
        stepIndex: 1,
        draft,
        savedId: '',
        errorMsg: '姓名不能为空。Backspace 返回姓名步骤，或按 Enter 重试保存。',
        statusText: 'Need name'
      }));
      this.speak('Name is required.');
      return;
    }

    if (draft.followUpAt && !/^\d{4}-\d{2}-\d{2}$/.test(draft.followUpAt)) {
      this.setData(createView({
        mode: 'review',
        stepIndex: STEPS.length - 1,
        draft,
        savedId: '',
        errorMsg: '跟进日期请用 YYYY-MM-DD。',
        statusText: 'Check date'
      }));
      this.speak('Follow up date format is invalid.');
      return;
    }

    try {
      const saved = await contactStore.saveContact(draft);
      this.setData(createView({
        mode: 'saved',
        stepIndex: this.data.stepIndex,
        draft: saved,
        savedId: saved.id,
        errorMsg: '',
        statusText: 'Saved'
      }));
      this.speak('Saved.');
    } catch (error) {
      console.error('[MeetMemo] save failed', error);
      this.setData(createView({
        mode: 'review',
        stepIndex: this.data.stepIndex,
        draft,
        savedId: '',
        errorMsg: '保存失败，请按 Enter 重试。',
        statusText: 'Save failed'
      }));
    }
  },

  speak(text) {
    try {
      if (wx.speech && typeof wx.speech.playTTS === 'function') {
        wx.speech.playTTS(text);
        return;
      }
      if (typeof SpeechSynthesisUtterance === 'undefined' || typeof speechSynthesis === 'undefined') {
        return;
      }
      const utterance = new SpeechSynthesisUtterance(text);
      utterance.lang = 'zh-CN';
      utterance.rate = 1;
      speechSynthesis.speak(utterance);
    } catch (error) {
      console.log('[MeetMemo] speech skipped', error);
    }
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
        <text class="kicker">{{ progressText }}</text>
        <text class="title">{{ promptText }}</text>
        <text class="primary">{{ primaryText }}</text>
      </view>

      <view class="summary" ink:if="{{ showSummary }}">
        <view class="summary-row" ink:for="{{ summaryRows }}" ink:key="label">
          <text class="summary-label">{{ item.label }}</text>
          <text class="summary-value">{{ item.value }}</text>
        </view>
      </view>

      <view class="note-card" ink:if="{{ showNote }}">
        <text class="note-label">原文</text>
        <text class="note-text">{{ draft.notes }}</text>
      </view>

      <view class="photo-card" ink:if="{{ hasPhoto }}">
        <text class="photo-label">照片</text>
        <image class="photo-thumb" src="{{ photoData }}" mode="aspectFit" />
      </view>

      <view class="bottom-row">
        <text class="key-hint">Enter 下一步</text>
        <text class="key-hint">{{ hintText }}</text>
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
.summary-row {
  display: flex;
  flex-direction: row;
  align-items: center;
}

.top-row,
.bottom-row,
.summary-row {
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
.key-hint,
.note-text {
  font-size: 16px;
  line-height: 22px;
}

.brand-name {
  color: #40ff5e;
  font-family: HarmonyOS_SansSC_Medium;
}

.status {
  color: rgba(64, 255, 94, 0.8);
}

.hero {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.kicker {
  font-size: 18px;
  line-height: 24px;
  color: rgba(64, 255, 94, 0.85);
}

.title {
  max-width: 420px;
  font-size: 28px;
  line-height: 36px;
  color: #f5f7fa;
  font-family: HarmonyOS_SansSC_Medium;
}

.primary {
  max-width: 420px;
  font-size: 20px;
  line-height: 26px;
  color: rgba(245, 247, 250, 0.76);
}

.summary {
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding: 10px 12px;
  border: 1.5px solid rgba(64, 255, 94, 0.55);
  border-radius: 12px;
  box-sizing: border-box;
}

.summary-label {
  width: 64px;
  font-size: 16px;
  line-height: 22px;
  color: rgba(245, 247, 250, 0.64);
}

.summary-value {
  flex: 1;
  font-size: 18px;
  line-height: 24px;
  color: #f5f7fa;
  text-align: right;
}

.note-card {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 10px 12px;
  border: 1.5px solid rgba(245, 247, 250, 0.18);
  border-radius: 12px;
  box-sizing: border-box;
}

.note-label {
  font-size: 16px;
  line-height: 22px;
  color: rgba(64, 255, 94, 0.85);
}

.note-text {
  color: rgba(245, 247, 250, 0.72);
}

.photo-card {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 10px 12px;
  border: 1.5px solid rgba(245, 247, 250, 0.18);
  border-radius: 12px;
  box-sizing: border-box;
}

.photo-label {
  font-size: 16px;
  line-height: 22px;
  color: rgba(64, 255, 94, 0.85);
}

.photo-thumb {
  width: 100%;
  height: 80px;
  object-fit: cover;
  border-radius: 8px;
}

.key-hint {
  max-width: 320px;
  color: rgba(64, 255, 94, 0.8);
}
</style>
