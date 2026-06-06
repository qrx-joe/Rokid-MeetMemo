# Rokid AIUI Development Cheatsheet

> 单文件速查表，覆盖 AIUI 项目结构、`.ink` SFC、组件、API、设计约束、易踩坑点。
>
> 详细规范见 `.agents/skills/aiui-dev/` 下 8 份原始文档；本表是"够用就行"的提炼。

---

## 1. 项目骨架

```
project/
├── AGENTS.md          # 智能体清单（身份 / 权限 / 技能）
├── app.json           # 全局配置（页面路由、窗口、字体）
├── app.js             # ES module default 导出（onLaunch、globalData）
├── pages/
│   └── <page>/
│       ├── <page>.ink     # 推荐：单文件组件（4 段式）
│       ├── page.json      # 可选：页面级配置
│       └── (page.js/wxml/wxss  按需)
└── assets/            # 图片、字体、音频
```

**最小 `app.json`**：
```json
{
  "pages": ["pages/index/index"],
  "window": {
    "navigationBarTitleText": "My Agent",
    "viewport": { "width": "device-width" }
  }
}
```

**最小 `app.js`**：
```javascript
export default {
  onLaunch() { console.log('App Launch'); },
  globalData: {}
};
```

**AGENTS.md 关键字段**：`Identity`（Name/Version/Description/Author）+ `Capabilities`（Permissions: camera/microphone/network/audio；Skills: 业务能力名）。

---

## 2. 设计硬约束（违反会很难看）

| 项 | 值 | 备注 |
|---|---|---|
| 宽度 | **480px** 固定 | 不要做"自适应" |
| 高度 | **120 ~ 380px** | 超过 380 = 滚动灾难 |
| 背景 | **黑色** 默认 | `#000` 或主题 token |
| 边框 | **2px**（卡片、关键交互元素） | 用 `--border-width-default` |
| 圆角 | **12px** | 卡片/按钮/图片统一 |
| 布局 | **卡片式** 优先 | 一屏一卡 |
| **emoji** | **禁止**默认使用 | 除非产品明确要求 |
| **大色块** | **禁止**大面积纯色 | 颜色仅用于强调 |

**配色原则**：先 `var(--color-primary)`、`var(--color-text-primary)`、`var(--color-spacing-md)`，再考虑硬编码。绿色主题 token 才是公开 API。

---

## 3. `.ink` 单文件组件

四段式，**缺一不可**（顺序固定）：

```html
<script def>
{
  "navigationBarTitleText": "Home",
  "description": "主页：欢迎 + 状态卡",
  "schema": {
    "data": {
      "type": "object",
      "properties": { "city": { "type": "string" } },
      "required": ["city"]
    }
  }
}
</script>

<script setup>
import wx from 'wx';

export default {
  data: { greeting: 'Hello' },
  onLoad() { console.log('loaded'); },
  handleTap() { this.setData({ greeting: 'Hi' }); }
};
</script>

<page>
  <view class="card">
    <text>{{ greeting }}</text>
    <button bindtap="handleTap">Click</button>
  </view>
</page>

<style>
.card { display: flex; padding: 16px; border: 2px solid var(--color-primary); border-radius: 12px; }
</style>
```

要点：
- `<script def>`：JSON 配置块（`description` + `schema` 是 **MCP UI 契约**）
- `<script setup>`：**`export default { ... }` 必须是直接导出**，不要包成 `defineComponent`
- `<page>`：WXML 模板
- `<style>`：WXSS（高度兼容 CSS，但用 `var(--token)` 优先）

---

## 4. WXML 指令

| 用途 | 语法 | 注意 |
|---|---|---|
| 数据绑定 | `{{ expr }}` | 支持三元、算术、属性插值 |
| 条件 | `<view ink:if="{{a===1}}">` / `ink:elif` / `ink:else` | **前缀是 `ink:`，不是 `wx:`** |
| 列表 | `<view ink:for="{{items}}" ink:key="id">` | **不支持嵌套 `ink:for`**——多层级数据要先在 JS 里 flatten |
| 事件 | `bindtap` / `catchtap` / `bindinput` / `bindchange` | `bind`=冒泡, `catch`=阻止冒泡 |
| 键盘 | 页面上 `onKeyDown(e)` / `onKeyUp(e)` | 写在 page 对象上，**不是 WXML 属性** |

---

## 5. 内置组件速查

### 5.1 真组件（用这些就够）

| 组件 | 关键属性 | 关键事件 | 用途 |
|---|---|---|---|
| `view` | id/class/style | bindtap/catchtap | 基础容器 |
| `text` | id/class/style | bindtap | 文字 |
| `image` | `src`、`mode="widthFix\|heightFix\|scaleToFill"` | — | 图片 |
| `button` | id/class/style | bindtap/catchtap | 按钮（**不是表单提交语义**） |
| `canvas` | `width`、`height` | — | 配合 `wx.createCanvasContext('id')` |
| `scroll-view` | `scroll-x`、`scroll-y`、`scroll-into-view`、`auto-scroll`、`scroll-speed`、`scroll-direction` | — | **可滚动**（AR 眼镜的"长内容"方案） |
| `chart` | `type`(line/area/pie/radar)、`series`、`data`、`x-axis`、`y-axis`、`animate` | — | 数据可视化 |
| `input` | `value`、`placeholder`、`disabled`、`maxLength` | **`bindinput`** | 单行输入 |
| `textarea` | `value`、`placeholder`、`disabled`、`maxLength` | **`bindinput`** | 多行输入 |
| `switch` | `checked`、`type="checkbox"`、`color` | `bindchange` | 开关（`event.detail.value` 是布尔） |
| `lottie-view` | `src`、`auto-play`（**不是 autoplay**）、`loop`、`speed`、`progress` | — | Lottie 动画 |

### 5.2 AI 专用组件（差异化点）

| 组件 | 用途 |
|---|---|
| `<streamdown content="{{replyText}}" streaming="{{isStreaming}}">` | 流式 markdown 渲染 + 光标动画 |
| `<a2ui commands="{{json}}" id="...">` | 接收 A2UI 协议命令流，让 agent 动态生成 UI |
| `<error-state icon="..." text="...">` | 错误状态行（icon + text） |

### 5.3 空壳组件（**不要用**）

| 组件 | 实际行为 |
|---|---|
| `swiper` / `swiper-item` / `fragment` | 底层都是 `view`，**没有轮播图能力** |
| `icon` | 底层是 `text`，**没有内建 icon 字体** |

如果需要轮播，自己用 `scroll-view` 配 `ink:for` 实现。

---

## 6. `wx.*` 桥 API 速查

```javascript
import wx from 'wx';  // 唯一导入方式：只导出 default
```

| 类别 | API | 关键注意 |
|---|---|---|
| 工具 | `arrayBufferToBase64(buf)` | detached buffer 会抛错 |
| 系统 | `exitMiniProgram(opts?)` | 调 `success`/`complete` |
| UI | `setBackgroundColor({ backgroundColor, backgroundColorTop, backgroundColorBottom })` | **顶/底可分设** |
| 路由 | `navigateTo` / `redirectTo` / `navigateBack(delta=1)` | url 必填 |
| 存储 | `setStorage/getStorage/removeStorage/clearStorage`（async + sync） | **JSON 序列化**——二进制会丢 |
| 网络 | `request(opts)` | **默认 `responseType: 'arraybuffer'`**（文本要显式声明）<br>默认 GET，默认超时 60s |
| 网络 | `createSocket` / `connectSocket` / `createEventSource` | 返回 Task，**支持分块流、SSE** |
| 语音 | `wx.speech.playTTS(text)` / `wx.speech.startRecognition()` | 都要**用户交互触发** |
| 媒体 | `wx.media.getRecorderManager()` / `wx.media.createCameraContext()` | **返回 `undefined` 而非抛错**——能力缺失时静默 |

Task 流式能力：
- `RequestTask`: `onHeadersReceived`, `onChunkReceived(buffer)`
- `SocketTask`: `onMessage` 收 `string | ArrayBuffer | Uint8Array`
- `EventSourceTask`: SSE 协议，消息格式 `{ data, event, id }`
- `RecorderManager`: `onHeader(format, buffer)`（**2 个位置参数**）, `onFrameRecorded({ frameBuffer })`

---

## 7. AI / 领域 API

### 7.1 AI（`LanguageModel`）

```javascript
const status = await LanguageModel.availability();  // 'available' | 'unavailable'
const session = await LanguageModel.create({
  model: 'gpt-4o-mini',  // 可选，回退到 host defaultModel
  initialPrompts: [{ role: 'system', content: '...' }],  // system 必须是第一条
  tools: [{ type: 'function', function: { name, description, parameters } }]
});

const text = await session.prompt('hello');  // Promise<string>，完整响应
const stream = session.promptStreaming('hello');  // 返回 LanguageModelTextStream
// 轮询: while ({ done, value } = await stream.read()) { ... }
stream.cancel();
session.destroy();
```

**关键约束**：
- `LanguageModel` 是 **singleton**，不可构造
- `availability()` **不返回 provider 元数据**（不知道有哪些模型）
- `prompt(input)` 接受 `string | Array<{role, content}>`，**不能传 system**（system 只能在 initialPrompts）
- **同时只允许一个活跃请求**——并发会 reject
- `LanguageModelTextStream` **不是 WHATWG ReadableStream**——没有 `pipeTo`、`for await`，只能 `read()` 轮询
- **结构化 tool-call 还没在 JS 侧暴露**（声明了 tools，agent 能不能用要看 host）

### 7.2 Canvas（2D）

```javascript
const ctx = wx.createCanvasContext('chartCanvas');  // 查 <canvas id="...">，找不到返回 null
// 或
const canvas = new Canvas(300, 150);
const ctx = canvas.getContext('2d');  // 只接受 '2d'，否则返回 null
```

**限制**：
- **颜色解析很有限**：仅 `#rrggbb` / `#rgb` / `rgb()` / `rgba()` / 9 个命名色（black/white/red/green/blue/yellow/transparent）
- `createPattern(image, repetition)` **基本是坏的**——忽略 image，从 1x1 内部 surface 创建
- `drawImage` **只接受 `Canvas` 实例**——不能直接传 HTMLImageElement
- 标脏方法（这些会自动触发重绘）：`fillRect/strokeRect/clearRect/arc/rect/ellipse/arcTo/bezierCurveTo/quadraticCurveTo/fill/stroke/fillText/strokeText/flush/drawImage/putImageData`

### 7.3 条码（`BarcodeDetector`）

```javascript
const detector = new BarcodeDetector();
const formats = await BarcodeDetector.getSupportedFormats();
const results = await detector.detect({ width, height, data: imageDataArrayBuffer });
// results: [{ format, rawValue }]
```

### 7.4 蓝牙（`navigator.bluetooth`）

```javascript
const device = await navigator.bluetooth.requestDevice({
  acceptAllDevices: false,  // 默认 false
  optionalServices: ['...'],
  filters: [{ name: 'MyDevice' }, { services: ['...'] }]  // 只支持 name 和 services
});
const server = await device.gatt.connect();
const service = await server.getPrimaryService('uuid');
const char = await service.getCharacteristic('uuid');
await char.startNotifications();
char.addEventListener('characteristicvaluechanged', e => { ... });
```

**陷阱**：
- `filters` **不支持 `manufacturerData` 等 Web Bluetooth 完整过滤**——别假设
- `requestDevice / scanDevices / gatt.connect / startNotifications` **全部需要 InkView 保持交互**——非交互状态会失败
- `getPrimaryService(uuid)` **同步抛错**（不是 Promise reject），其他 GATT API 都是 async
- `readValue()` 返回 `Promise<number[]>`（**不是 DataView 也不是 ArrayBuffer**）

### 7.5 传感器

```javascript
const accel = new Accelerometer({ frequency: 60 });  // frequency 是 best-effort 提示
accel.addEventListener('reading', e => console.log(e.x, e.y, e.z));
accel.addEventListener('error', e => console.error(e.error, e.message));
accel.start();
```

- 三个：`Accelerometer` / `AbsoluteOrientationSensor` / `Gyroscope`
- 事件：`activate`、`reading`、`error`
- `AbsoluteOrientationSensor` 的 `quaternion` 是 `[x, y, z, w]` 顺序
- `stop()` 是 no-op 如果已经 idle

### 7.6 媒体（`Sound`）

```javascript
const click = new Sound('./assets/click.wav');
click.volume = 0.5;
click.play();  // 总是从开头重放（不支持 pause/resume）
click.destroy();  // 之后任何调用都会抛错
```

**严重局限**：只支持本地文件（拒绝 `http://`）、不支持 seek/streaming/事件回调。**只能做音效**。

### 7.7 Web Speech

- `speechSynthesis.speak(utterance)`——**只有这一个方法**（没有 `cancel/pause/resume/getVoices`）
- `SpeechRecognition` 完整支持：`start/stop/abort` + 11 种事件（`result` 暴露 `resultIndex/results/sessionId`）
- `start()` 在 InkView 非交互时抛 `InvalidStateError`

---

## 8. 主题 Token 精选（完整表见 SKILL.md §5.4）

```css
/* 颜色 */
color: var(--color-primary);                    /* 主色 */
color: var(--color-text-primary);               /* 主文字 */
color: var(--color-text-secondary);             /* 次文字 */
background: var(--color-background);            /* 背景 */
background: var(--color-surface);               /* 卡片表面 */
background: var(--color-surface-highlight);     /* 高亮表面 */

/* 间距 / 圆角 / 边框 */
padding: var(--spacing-md);
gap: var(--spacing-md);
border-radius: var(--radius-md);                /* 默认 12 */
border: var(--border-width-default) solid var(--border-color-default);

/* 卡片专用 */
.card {
  padding: var(--card-padding);
  border: var(--card-border-width) solid var(--card-border-color);
  border-radius: var(--radius-md);
  background: var(--color-surface);
}
```

**绿色主题硬编码值**（如果非用不可）：`#40FF5E` / `rgba(64, 255, 94, 0.6)` / `rgba(64, 255, 94, 0.4)`——但**优先用 token**。

---

## 9. 字体

```json
// app.json
{
  "fonts": [
    { "family": "Bundled Serif", "src": "assets/fonts/NotoSerif-Regular.ttf", "weight": 400, "style": "normal" }
  ]
}
```

```xml
<text style="font-family: 'Bundled Serif', serif; font-size: 20px;">Hello</text>
```

```javascript
const ctx = wx.createCanvasContext('c');
ctx.font = '20px "Bundled Serif", serif';
ctx.fillText('Hello', 12, 40);
```

规则：`font-family` 字符串、Canvas `font` 字符串、`<text style>` 三处**必须同名**。不假设 web `@font-face` 远程加载。

---

## 10. AI Agent 模式

AIUI 是为 AI agent 设计的，三个核心模式：

### 10.1 流式回复（最常用）

```html
<streamdown content="{{replyText}}" streaming="{{isStreaming}}" class="reply" />
```

```javascript
import { LanguageModel } from 'language-model';
// 或全局: const session = await LanguageModel.create({...});
const stream = session.promptStreaming(userInput);
let acc = '';
while (true) {
  const { done, value } = await stream.read();
  if (done) break;
  if (value) {
    acc += value;
    this.setData({ replyText: acc, isStreaming: true });
  }
}
this.setData({ isStreaming: false });
```

### 10.2 动态 UI（A2UI）

```html
<a2ui id="agent-view" commands="{{ initialJson }}" class="agent-surface" />
```

```javascript
import a2ui from 'a2ui';  // 实际可能叫别的名
const ctx = a2ui.createA2UIContext('agent-view');
ctx.write(JSON.stringify([{ type: 'createSurface', surfaceId: 'main' }]));
// 支持的操作: full write / stream open / stream chunk / stream close / clear
```

### 10.3 多模态输入（相机+ASR+LLM）

```javascript
// 拍照 → BarcodeDetector / 视觉模型
const cam = wx.media.createCameraContext();
const { data: photoBuf } = await cam.takePhoto({ quality: 'high' });
const detector = new BarcodeDetector();
const codes = await detector.detect({ width, height, data: photoBuf });

// 录音 → 实时帧
const rec = wx.media.getRecorderManager();
rec.onFrameRecorded(({ frameBuffer }) => { /* 推给 LLM */ });
await rec.start({ ... });

// 语音识别
const recognition = new SpeechRecognition();
recognition.onresult = e => console.log(e.results[0][0].transcript);
recognition.start();
```

---

## 11. 常见陷阱清单

| 陷阱 | 后果 | 正确做法 |
|---|---|---|
| 用 `swiper` 做轮播 | 实际是 view，不滚动 | 用 `scroll-view` 配 `ink:for` |
| 用 `<icon>` 当图标 | 实际是 text | 用 `text` + 字体图标字符 |
| 假设 `wx.request` 默认返回 text | 拿到的是 ArrayBuffer | 显式 `responseType: 'text'` |
| 假设 `Storage` 能存二进制 | 数据被 JSON 序列化丢失 | 转 base64 字符串或存文件 |
| 在非交互回调里调蓝牙/相机/录音 | 抛 InvalidStateError | 绑在 `bindtap` 里 |
| 用 `navigator.bluetooth.filters` 配 manufacturerData | 字段被忽略 | 改用 `name` 或 `services` |
| 把 `LanguageModelTextStream` 当 ReadableStream | `.pipeTo` 不存在 | 用 `read()` 轮询 |
| `LanguageModel.availability()` 等于"模型清单" | 只返回 available/unavailable | 自己 hardcode 模型名 |
| 假设 `sound.play()` 是流式 | 它总是从 0 开始 | 别用 Sound 做音乐 |
| 假设 `speechSynthesis.cancel()` 存在 | 该方法没暴露 | 没招，要么不取消 |
| 假设 `tools` 声明后能拿到结构化 tool-call | 文档说还没暴露 | 走 text-based tool use 兜底 |
| 用 `canvas.createPattern(image, ...)` | 实际是 1x1 surface | 改用 `CanvasGradient` |
| `getPrimaryService` 没连就调 | **同步抛错**（不是 reject） | 先 `gatt.connect()`，try/catch |
| `wx.media.*` 不判空 | 拿到 undefined 调方法炸 | 先 `if (rec)` 判空 |
| 给 Lottie 写 `autoplay` | 属性不识别 | 写 `auto-play` |
| 用 `bindchange` 监听 input | 收不到 | input/textarea 用 `bindinput` |
| 嵌套 `ink:for` | 不支持 | 在 JS 里 flatten |

---

## 12. 详档索引

- `.agents/skills/aiui-dev/SKILL.md` —— 总览（项目结构、.ink、组件列表、API 索引、设计指南、主题 token 全表）
- `.agents/skills/aiui-dev/apis.md` —— API 总索引（确认支持的运行时 API 列表）
- `.agents/skills/aiui-dev/components.md` —— 全部内置组件的参数表
- `.agents/skills/aiui-dev/apis-wx.md` —— `wx.*` 全部方法签名与错误行为
- `.agents/skills/aiui-dev/apis-ai.md` —— `LanguageModel` / Speech
- `.agents/skills/aiui-dev/apis-canvas.md` —— Canvas 2D / Barcode
- `.agents/skills/aiui-dev/apis-device.md` —— Bluetooth / Sensors
- `.agents/skills/aiui-dev/apis-media.md` —— `Sound`
