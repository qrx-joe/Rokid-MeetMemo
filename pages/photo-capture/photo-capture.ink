<script def>
{
  "navigationBarTitleText": "拍照记录",
  "description": "Camera capture for Rokid glasses. Enter takes a photo, Backspace cancels or retakes. Confirmed photo is handed off to the capture flow for structured note entry.",
  "schema": {
    "data": {
      "type": "object",
      "properties": {
        "mode": { "type": "string" },
        "statusText": { "type": "string" },
        "primaryText": { "type": "string" },
        "hintText": { "type": "string" },
        "photoData": { "type": "string" },
        "hasPhoto": { "type": "boolean" },
        "isPreview": { "type": "boolean" },
        "isReview": { "type": "boolean" },
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
        }
      },
      "required": ["mode", "statusText", "primaryText", "hintText", "photoData", "hasPhoto", "isPreview", "isReview", "selectedAction", "actionRows"]
    }
  }
}
</script>

<script setup>
import wx from 'wx';
import { contactStore } from '../../services/contact-store.js';

function actionRow(id, label, selectedId) {
  return {
    id,
    label,
    className: id === selectedId ? 'card-action card-action-active' : 'card-action'
  };
}

function createView(state) {
  const isPreview = state.mode === 'preview';
  const isReview = state.mode === 'review';
  const hasPhoto = Boolean(state.photoData);

  let primaryText = '按 Enter 拍照';
  let hintText = '对准人物后按 Enter 拍摄。';
  let statusText = 'Camera';

  if (isReview) {
    primaryText = '照片已拍摄';
    hintText = 'Enter 保存并继续，Backspace 重拍。';
    statusText = 'Review';
  }

  return {
    mode: state.mode,
    photoData: state.photoData,
    hasPhoto,
    isPreview,
    isReview,
    selectedAction: state.selectedAction,
    primaryText,
    hintText,
    statusText,
    actionRows: [
      actionRow('continue', '保存并继续', state.selectedAction),
      actionRow('retake', '重拍', state.selectedAction)
    ]
  };
}

function initialView() {
  return createView({
    mode: 'preview',
    photoData: '',
    selectedAction: 'continue'
  });
}

function arrayBufferToBase64(buffer) {
  if (!buffer || !(buffer instanceof ArrayBuffer)) return '';
  const bytes = new Uint8Array(buffer);
  let binary = '';
  for (let i = 0; i < bytes.byteLength; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return 'data:image/jpeg;base64,' + btoa(binary);
}

export default {
  data: initialView(),

  onLoad() {
    this.speak('拍照模式。按 Enter 拍摄。');
  },

  onKeyDown(event) {
    const code = event && event.code;
    if (code === 'Backspace') {
      if (this.data.isReview) {
        this.setData(initialView());
        this.speak('重拍');
        return;
      }
      wx.navigateBack();
      return;
    }
    if (code === 'ArrowDown' || code === 'ArrowRight') {
      this.setData(createView({
        mode: this.data.mode,
        photoData: this.data.photoData,
        selectedAction: 'retake'
      }));
      return;
    }
    if (code === 'ArrowUp' || code === 'ArrowLeft') {
      this.setData(createView({
        mode: this.data.mode,
        photoData: this.data.photoData,
        selectedAction: 'continue'
      }));
      return;
    }
    if (code === 'Enter') {
      this.handleEnter();
    }
  },

  async handleEnter() {
    if (this.data.isPreview) {
      await this.takePhoto();
      return;
    }
    if (this.data.isReview) {
      if (this.data.selectedAction === 'retake') {
        this.setData(initialView());
        this.speak('重拍');
        return;
      }
      // Save photo to temporary store and navigate to capture flow
      const photoKey = contactStore.savePhoto(this.data.photoData);
      wx.navigateTo({
        url: `/pages/capture/capture?photoKey=${encodeURIComponent(photoKey)}`
      });
    }
  },

  async takePhoto() {
    this.speak('正在拍摄');

    try {
      const camera = wx.media && wx.media.createCameraContext
        ? wx.media.createCameraContext()
        : null;

      if (!camera) {
        console.warn('[MeetMemo] camera not available');
        this.useFallbackPhoto();
        return;
      }

      const result = await camera.takePhoto({ quality: 'high' });
      if (!result || !result.data) {
        throw new Error('empty photo data');
      }

      const base64 = arrayBufferToBase64(result.data);
      if (!base64) {
        throw new Error('base64 conversion failed');
      }

      this.setData(createView({
        mode: 'review',
        photoData: base64,
        selectedAction: 'continue'
      }));
      this.speak('拍摄完成，请确认');
    } catch (error) {
      console.error('[MeetMemo] take photo failed', error);
      this.useFallbackPhoto();
    }
  },

  useFallbackPhoto() {
    // Fallback: generate a placeholder so the UI still works in preview
    this.setData(createView({
      mode: 'review',
      photoData: '',
      selectedAction: 'continue'
    }));
    this.speak('相机不可用，请重试');
  },

  speak(text) {
    try {
      if (wx.speech && typeof wx.speech.playTTS === 'function') {
        wx.speech.playTTS(text);
        return;
      }
      if (typeof SpeechSynthesisUtterance !== 'undefined' && typeof speechSynthesis !== 'undefined') {
        const utterance = new SpeechSynthesisUtterance(text);
        utterance.lang = 'zh-CN';
        speechSynthesis.speak(utterance);
      }
    } catch (e) {
      // ignore
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
        <text class="kicker">拍照记录</text>
        <text class="title">{{ primaryText }}</text>
        <text class="hint">{{ hintText }}</text>
      </view>

      <!-- Camera preview or photo review -->
      <view class="camera-area">
        <camera class="camera-preview" ink:if="{{ isPreview }}" device-position="back" flash="auto" />
        <image class="photo-review" ink:if="{{ isReview && hasPhoto }}" src="{{ photoData }}" mode="aspectFit" />
        <view class="photo-placeholder" ink:if="{{ isReview && !hasPhoto }}">
          <text class="placeholder-text">照片预览不可用</text>
        </view>
      </view>

      <!-- Review actions -->
      <view class="card-actions" ink:if="{{ isReview }}">
        <view class="{{ item.className }}" ink:for="{{ actionRows }}" ink:key="id">
          <text class="card-action-text">{{ item.label }}</text>
        </view>
      </view>

      <view class="bottom-row">
        <text class="key-hint">Enter {{ isPreview ? '拍照' : '执行' }}</text>
        <text class="key-hint">Back {{ isReview ? '重拍' : '返回' }}</text>
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

.hero {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.kicker {
  font-size: 18px;
  line-height: 24px;
  color: rgba(64, 255, 94, 0.85);
}

.title {
  font-size: 28px;
  line-height: 36px;
  color: #f5f7fa;
  font-family: HarmonyOS_SansSC_Medium;
}

.hint {
  font-size: 18px;
  line-height: 24px;
  color: rgba(245, 247, 250, 0.68);
}

.camera-area {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 8px 0;
  border: 1.5px solid rgba(64, 255, 94, 0.32);
  border-radius: 12px;
  overflow: hidden;
  background: #0a0a0a;
}

.camera-preview {
  width: 100%;
  height: 100%;
}

.photo-review {
  width: 100%;
  height: 100%;
}

.photo-placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
}

.placeholder-text {
  font-size: 18px;
  color: rgba(245, 247, 250, 0.5);
}

.card-actions {
  display: flex;
  flex-direction: column;
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
