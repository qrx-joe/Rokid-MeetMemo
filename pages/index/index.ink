<script def>
{
  "navigationBarTitleText": "MeetMemo",
  "description": "Home HUD for Rokid glasses. Hardware keys select quick note, follow-up review, or recent contact entry without touch input.",
  "schema": {
    "data": {
      "type": "object",
      "properties": {
        "statusText": { "type": "string" },
        "primaryText": { "type": "string" },
        "hintText": { "type": "string" },
        "actionRows": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "id": { "type": "string" },
              "label": { "type": "string" },
              "detail": { "type": "string" },
              "className": { "type": "string" },
              "enabled": { "type": "boolean" }
            },
            "required": ["id", "label", "detail", "className"]
          }
        },
        "recentRows": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "id": { "type": "string" },
              "name": { "type": "string" },
              "detail": { "type": "string" }
            },
            "required": ["id", "name", "detail"]
          }
        },
        "hasRecent": { "type": "boolean" },
        "pendingText": { "type": "string" },
        "recentText": { "type": "string" },
        "pendingCount": { "type": "number" },
        "selectedAction": { "type": "string" }
      },
      "required": ["statusText", "primaryText", "hintText", "actionRows", "recentRows", "hasRecent", "pendingText", "recentText", "pendingCount", "selectedAction"]
    }
  }
}
</script>

<script setup>
import wx from 'wx';
import { contactStore } from '../../services/contact-store.js';

const RECENT_LIMIT = 3;

function actionRow(id, label, detail, selectedId, enabled = true) {
  return {
    id,
    label,
    detail,
    className: id === selectedId ? 'action-row action-row-active' : 'action-row',
    enabled
  };
}

function createView(state) {
  const actions = [
    actionRow('capture', '快速记录', '说一段会面笔记', state.selectedAction, true),
    actionRow('photo', '拍照记录', '拍摄对方照片', state.selectedAction, true),
    actionRow('followups', '待跟进', state.pendingText, state.selectedAction, state.pendingCount > 0),
    actionRow('recent', '最近联系人', state.recentText, state.selectedAction, state.recentRows.length > 0)
  ];

  return {
    selectedAction: state.selectedAction,
    recentRows: state.recentRows,
    pendingCount: state.pendingCount,
    pendingText: state.pendingText,
    recentText: state.recentText,
    statusText: state.loaded ? 'Ready' : 'Loading',
    primaryText: state.primaryText,
    hintText: 'Enter 执行，方向键切换，Backspace 退出',
    actionRows: actions,
    hasRecent: state.recentRows.length > 0
  };
}

function initialView() {
  return createView({
    selectedAction: 'capture',
    recentRows: [],
    pendingCount: 0,
    pendingText: '暂无待跟进',
    recentText: '暂无联系人',
    primaryText: '记录刚认识的人',
    loaded: false
  });
}

// ========== 语音与头部姿态控制 ==========

const VOICE_COMMANDS = {
  '下一个': 1,
  '往下': 1,
  '下一个按钮': 1,
  '上一个': -1,
  '往上': -1,
  '上一个按钮': -1,
  '确认': 'confirm',
  '执行': 'confirm',
  '打开': 'confirm',
  '快速记录': 'capture',
  '记一个人': 'capture',
  '记一下': 'capture',
  '待跟进': 'followups',
  '跟进': 'followups',
  '最近联系人': 'recent',
  '返回': 'exit',
  '退出': 'exit',
  '回去': 'exit'
};

async function recognizeOnce() {
  if (wx.speech && typeof wx.speech.startRecognition === 'function') {
    const text = wx.speech.startRecognition();
    if (text) return text.trim();
  }
  if (typeof SpeechRecognition !== 'undefined') {
    return new Promise((resolve, reject) => {
      const recognition = new SpeechRecognition();
      recognition.lang = 'zh-CN';
      recognition.continuous = false;
      recognition.interimResults = false;
      recognition.maxAlternatives = 1;
      recognition.onresult = event => {
        const result = event.results[0] && event.results[0][0];
        resolve(result ? result.transcript.trim() : '');
      };
      recognition.onerror = () => reject(new Error('recognition failed'));
      recognition.onnomatch = () => reject(new Error('no match'));
      recognition.start();
    });
  }
  throw new Error('voice unavailable');
}

function speak(text) {
  try {
    if (wx.speech && typeof wx.speech.playTTS === 'function') {
      wx.speech.playTTS(text);
    }
  } catch (e) {
    // TTS 不可用则静默
  }
}

export default {
  data: initialView(),
  _accel: null,
  _lastAccelY: 0,
  _gestureCooldown: false,
  _voiceListening: false,

  async onLoad() {
    await this.refresh();
    this.initHeadControl();
  },

  onUnload() {
    this.stopHeadControl();
  },

  async onShow() {
    await this.refresh();
  },

  // ========== 语音唤醒（系统级）==========
  onVoiceWakeup(event) {
    this.listenForVoiceCommand();
  },

  // ========== 语音指令 ==========
  async listenForVoiceCommand() {
    if (this._voiceListening) return;
    this._voiceListening = true;

    speak('请说出指令');

    try {
      const text = await recognizeOnce();
      this.executeVoiceCommand(text);
    } catch (e) {
      speak('没听清，请再说一次');
    } finally {
      this._voiceListening = false;
    }
  },

  executeVoiceCommand(text) {
    if (!text) {
      speak('未识别');
      return;
    }

    for (const [keyword, action] of Object.entries(VOICE_COMMANDS)) {
      if (text.includes(keyword)) {
        if (action === 'confirm') {
          speak('确认');
          this.runSelectedAction();
        } else if (action === 'exit') {
          speak('退出');
          wx.exitMiniProgram();
        } else if (action === 'capture') {
          speak('快速记录');
          wx.navigateTo({ url: '/pages/capture/capture' });
        } else if (action === 'followups') {
          speak('待跟进');
          wx.navigateTo({ url: '/pages/followups/followups' });
        } else if (action === 'recent') {
          const first = this.data.recentRows[0];
          if (first) {
            speak('最近联系人');
            wx.navigateTo({
              url: `/pages/contact-card/contact-card?id=${encodeURIComponent(first.id)}`
            });
          } else {
            speak('暂无最近联系人');
          }
        } else if (typeof action === 'number') {
          const direction = action > 0 ? '下一个' : '上一个';
          speak(direction);
          this.moveSelection(action);
        }
        return;
      }
    }

    speak('未识别指令：' + text);
  },

  // ========== 头部姿态控制 ==========
  initHeadControl() {
    if (typeof Accelerometer === 'undefined') {
      console.log('[MeetMemo] Accelerometer not available');
      return;
    }

    this._accel = new Accelerometer({ frequency: 10 });
    this._lastAccelY = 0;
    this._gestureCooldown = false;

    this._accel.addEventListener('reading', () => {
      if (this._gestureCooldown || !this._accel) return;

      const y = this._accel.y || 0;
      const deltaY = y - this._lastAccelY;
      this._lastAccelY = y;

      const THRESHOLD = 0.25;
      const CONFIRM_THRESHOLD = 0.7;

      // 快速点头 = 确认
      if (deltaY > CONFIRM_THRESHOLD) {
        this._gestureCooldown = true;
        speak('确认');
        this.runSelectedAction();
        setTimeout(() => { this._gestureCooldown = false; }, 1000);
        return;
      }

      // 轻微低头 = 下一个
      if (deltaY > THRESHOLD) {
        this._gestureCooldown = true;
        this.moveSelection(1);
        setTimeout(() => { this._gestureCooldown = false; }, 600);
        return;
      }

      // 轻微抬头 = 上一个
      if (deltaY < -THRESHOLD) {
        this._gestureCooldown = true;
        this.moveSelection(-1);
        setTimeout(() => { this._gestureCooldown = false; }, 600);
        return;
      }
    });

    this._accel.start();
    console.log('[MeetMemo] head control initialized');
  },

  stopHeadControl() {
    if (this._accel) {
      this._accel.stop();
      this._accel = null;
    }
  },

  onKeyDown(event) {
    const code = event && event.code;
    if (code === 'Backspace') {
      wx.exitMiniProgram();
      return;
    }
    if (code === 'ArrowDown' || code === 'ArrowRight') {
      this.moveSelection(1);
      return;
    }
    if (code === 'ArrowUp' || code === 'ArrowLeft') {
      this.moveSelection(-1);
      return;
    }
    if (code === 'Enter') {
      this.runSelectedAction();
    }
  },

  async refresh() {
    const [contacts, followups] = await Promise.all([
      contactStore.listContacts(),
      contactStore.listFollowups()
    ]);

    const recentRows = contacts.slice(0, RECENT_LIMIT).map(contact => ({
      id: contact.id,
      name: contact.name || '待补充',
      detail: contact.role || contact.context || contact.followUpAt || '无补充信息'
    }));
    const pendingCount = followups.filter(followup => followup.status === 'pending').length;
    const selectedAction = this.getUsableAction(this.data.selectedAction || 'capture', recentRows, pendingCount);

    this.setData(createView({
      selectedAction,
      recentRows,
      pendingCount,
      pendingText: pendingCount ? `${pendingCount} 项待处理` : '暂无待跟进',
      recentText: recentRows.length ? `${recentRows.length} 位最近联系人` : '暂无联系人',
      primaryText: recentRows.length ? recentRows[0].name : '记录刚认识的人',
      loaded: true
    }));
  },

  getUsableAction(action, recentRows, pendingCount) {
    if (action === 'followups' && pendingCount === 0) return 'capture';
    if (action === 'recent' && recentRows.length === 0) return 'capture';
    return action;
  },

  moveSelection(delta) {
    const order = ['capture', 'photo', 'followups', 'recent'];
    const enabled = {
      capture: true,
      followups: this.data.pendingCount > 0,
      recent: this.data.recentRows.length > 0
    };
    let index = order.indexOf(this.data.selectedAction);
    for (let i = 0; i < order.length; i += 1) {
      index = (index + delta + order.length) % order.length;
      if (enabled[order[index]]) {
        const selectedAction = order[index];
        this.setData(createView({
          selectedAction,
          recentRows: this.data.recentRows,
          pendingCount: this.data.pendingCount,
          pendingText: this.data.pendingText,
          recentText: this.data.recentText,
          primaryText: selectedAction === 'recent' && this.data.recentRows[0]
            ? this.data.recentRows[0].name
            : '记录刚认识的人',
          loaded: true
        }));
        return;
      }
    }
  },

  runSelectedAction() {
    if (this.data.selectedAction === 'photo') {
      wx.navigateTo({ url: '/pages/photo-capture/photo-capture' });
      return;
    }

    if (this.data.selectedAction === 'followups' && this.data.pendingCount > 0) {
      wx.navigateTo({ url: '/pages/followups/followups' });
      return;
    }

    if (this.data.selectedAction === 'recent' && this.data.recentRows[0]) {
      wx.navigateTo({
        url: `/pages/contact-card/contact-card?id=${encodeURIComponent(this.data.recentRows[0].id)}`
      });
      return;
    }

    wx.navigateTo({ url: '/pages/capture/capture' });
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
        <text class="kicker">离线会面记忆</text>
        <text class="title">{{ primaryText }}</text>
        <text class="hint">主动记录，不后台录音；保存前逐项确认。</text>
      </view>

      <view class="action-list">
        <view class="{{ item.className }}" ink:for="{{ actionRows }}" ink:key="id">
          <text class="action-label">{{ item.label }}</text>
          <text class="action-detail">{{ item.detail }}</text>
        </view>
      </view>

      <view class="recent" ink:if="{{ hasRecent }}">
        <view class="recent-row" ink:for="{{ recentRows }}" ink:key="id">
          <text class="recent-name">{{ item.name }}</text>
          <text class="recent-detail">{{ item.detail }}</text>
        </view>
      </view>

      <view class="bottom-row">
        <text class="key-hint">Enter 执行</text>
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
.action-row,
.recent-row {
  display: flex;
  flex-direction: row;
  align-items: center;
}

.top-row,
.bottom-row,
.action-row,
.recent-row {
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
.action-list,
.recent {
  display: flex;
  flex-direction: column;
}

.hero {
  gap: 6px;
}

.kicker {
  font-size: 18px;
  line-height: 24px;
  color: rgba(245, 247, 250, 0.72);
}

.title {
  font-size: 32px;
  line-height: 40px;
  color: #f5f7fa;
  font-family: HarmonyOS_SansSC_Medium;
}

.hint {
  font-size: 18px;
  line-height: 24px;
  color: rgba(245, 247, 250, 0.68);
}

.action-list {
  gap: 8px;
}

.action-row {
  height: 40px;
  padding: 0 12px;
  border: 1.5px solid rgba(64, 255, 94, 0.32);
  border-radius: 12px;
  box-sizing: border-box;
}

.action-row-active {
  border-color: #40ff5e;
}

.action-label {
  font-size: 20px;
  line-height: 26px;
  color: #f5f7fa;
}

.action-detail {
  font-size: 16px;
  line-height: 22px;
  color: rgba(64, 255, 94, 0.82);
}

.recent {
  gap: 4px;
}

.recent-row {
  height: 28px;
}

.recent-name,
.recent-detail {
  font-size: 16px;
  line-height: 22px;
}

.recent-name {
  color: #f5f7fa;
}

.recent-detail {
  color: rgba(245, 247, 250, 0.58);
}

.key-hint {
  max-width: 320px;
}
</style>
