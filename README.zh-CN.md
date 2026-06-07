# MeetMemo AIUI — 遇见备忘录

> 一句话：一款为 Rokid AR 眼镜打造的**离线人脉速记 Agent**。你说一句话，它自动生成结构化的人脉卡片和待办跟进。

## 它是做什么的？

在展会、沙龙、饭局上刚认识一个人？

**戴上眼镜 → 按确认键 → 说一段话** → 完成。

MeetMemo 会把你的语音自动转换成一张结构化的人脉卡片（姓名、身份、关键信息），并提取出下一步行动（"周二发 demo"），生成待办提醒。之后随时可以在眼镜上快速浏览最近见过的人。

```text
打开 MeetMemo
→ HUD 显示 "就绪" + 品牌标识
→ 按下确认键 (Enter)
→ 开始语音采集
→ 你说："王磊，教育 SaaS 创始人，周二发 demo"
→ HUD 显示解析后的人脉卡片草稿
→ 按确认保存 / 按返回丢弃
→ 数据本地存储 (wx.setStorageSync)
→ 自动创建跟进待办
```

## 为什么需要它？

- **场景真实**：AR 眼镜没有触摸屏、没有键盘，传统 App 的交互方式完全失效
- **输入极简**：仅靠 `Enter` / `Backspace` 两个按键 + 语音驱动全部交互
- **完全离线**：不依赖网络，数据本地存储，隐私安全
- **跨平台开发**：无需真机即可在 Windows / macOS / Linux 上完整预览 UI

## 技术栈

| 层级 | 技术 |
|------|------|
| 运行时 | Ink WebAssembly（Rokid AIUI 框架） |
| 开发服务器 | Express + `ink-vfs-server` HTTP 虚拟文件系统 |
| 预览方式 | 浏览器 Canvas 渲染 480×400 HUD 界面 |
| 打包格式 | `.aix`（AIUI Agent 包） |
| 部署平台 | Rokid 灵珠开发者平台 |

## 项目结构

```text
.
├── AGENTS.md                # AIUI Agent 身份、权限、技能定义
├── app.js                   # AIUI 应用生命周期（薄层）
├── app.json                 # 页面路由 + 窗口配置
├── dev-server.js            # 本地浏览器预览服务器
├── public/
│   └── index.html           # 浏览器外壳：<canvas> + Ink WASM 引导
├── pages/
│   ├── index/index.ink              # 首页 HUD
│   ├── photo-capture/photo-capture.ink   # 拍照采集
│   ├── capture/capture.ink          # 文本/语音采集
│   ├── contact-card/contact-card.ink # 人脉卡片详情
│   └── followups/followups.ink      # 待办跟进列表
├── services/
│   ├── contact-store.js     # 数据存储适配器
│   └── parser.js            # 语音解析（占位，后续接入 LLM）
├── Docs/                    # 技术规范 / 任务清单 / 决策日志
├── reference/               # 参考资料（rokid-lens-coach 参考项目等）
├── scripts/                 # 构建/打包脚本
└── test/                    # 测试目录
```

## 快速开始

### 环境要求

- Node.js 18+（测试通过 24）
- npm 9+（测试通过 11）
- 现代浏览器（Chrome / Edge / Firefox），支持 WebAssembly

> 已在 Windows 11 上测试通过。无需平台专属二进制文件。

### 安装依赖

```bash
npm install
```

安装三个开发依赖：

- `@yodaos-pkg/ink` — Ink Web SDK（WASM 运行时）
- `@yodaos-pkg/ink-vfs-server` — HTTP 虚拟文件系统，将项目文件提供给 Ink
- `express` — VFS 中间件和预览 HTML 的 HTTP 服务

**无运行时依赖**；部署时的 `.aix` 包仅包含 `pages/`、`services/`、`app.json`、`app.js`、`AGENTS.md`。

### 启动本地预览

```bash
npm start
```

然后浏览器打开 `http://127.0.0.1:8081/`。你会看到一个 480×400 的 HUD 画布，渲染 `app.json` 中注册的第一个页面。

**本地预览能验证的：**

- ✅ 480×400 页面布局（Rokid HUD 安全区）
- ✅ AIUI 运行时对 `.ink` 四段式文件的兼容性
- ✅ WXML 指令（`ink:if`、`ink:for`）和数据绑定
- ✅ WXSS 主题变量（`var(--card-padding)` 等）
- ✅ `bindtap` / `onKeyDown` 事件传递
- ✅ `setData` 数据更新（点路径、全对象替换）
- ✅ `scroll-view` 滚动行为

**本地预览无法验证的（需要真机）：**

- ❌ `wx.media.*`（相机、录音）— 仅设备端可用
- ❌ `wx.speech.startRecognition` — 依赖宿主环境
- ❌ `LanguageModel` — 依赖宿主环境
- ❌ 真实光照下的 HUD 视觉对比度

### 运行测试

```bash
npm test
```

> 当前为空；`services/` 的测试将在 HUD 重构完成后补充。

### 本地预览原理

```
[浏览器]                              [Node 进程]
 ┌─────────────────────────────┐        ┌────────────────────────────────┐
 │ public/index.html           │        │ dev-server.js (Express)        │
 │  ↳ <canvas>                 │        │   ↳ static  /         → public │
 │  ↳ import @yodaos-pkg/ink   │ ◄────  │   ↳ static  /ink      → SDK    │
 │    createInkView()          │  HTTP  │   ↳ middleware /ink-vfs → VFS  │
 │    view.openFromVfs(...)    │        │      rootDir = .ink-build/     │
 └─────────────────────────────┘        └────────────────────────────────┘
```

每次启动前，`dev-server.js` 会将运行时所需文件（`app.json`、`app.js`、`AGENTS.md`、`pages/`、`services/`、`assets/`）暂存到 `.ink-build/`，确保 VFS 暴露的是一个干净的应用包 —— `node_modules`、`.git`、`Docs`、`reference` 永远不会泄漏到运行时视图中。

## 打包为 `.aix` 并部署到眼镜

Ink Web SDK 可以跨平台 npm 安装。但 `.aix` 打包工具（`aix-macos-universal`）目前仅支持 macOS，且未上架 npm。Windows 用户的选择：

### 方案一：借一台 Mac（目前推荐）

在 macOS 上安装工具后执行：

```bash
/path/to/aix-macos-universal pack --optimize -o dist/meetmemo.aix .
```

然后将 `dist/meetmemo.aix` 上传到 Rokid 灵珠开发者平台。

### 方案二：等待 Craft 在线工作区

`https://js.rokid.com/craft` 已公布为浏览器版工作区，可导入项目并预览/打包。截至 2026-06-06，官网显示完整打包功能"即将推出"。

### 方案三：手动打 zip 包

如果部署端最终接受 zip 而非签名的 `.aix`，这将变成一行命令。目前尚未确认。

> **日常开发**：本地浏览器预览（`npm start`）已覆盖除硬件专属 API 外的全部功能。

## 上传到 Rokid 眼镜（获得 `.aix` 后）

通过 Rokid 灵珠在线工作流部署：

1. 打开灵珠 → `项目开发`
2. 创建一个 AIUI Agent
3. 填写名称、版本、分类、描述、图标
4. 上传 `dist/meetmemo.aix` 作为 Agent 包
5. 在眼镜端进入 `设置 → 开发者 → AIUI 调试 → 更新资源`
6. 在眼镜上启动 Agent

## 设计规范

- **显示区域**：480 × 400（Rokid HUD 安全区）
- **背景色**：纯黑 `#000000`
- **强调色**：`#40FF5E`（当前 — 主题变量待 Ink 验证后调整）
- **边框**：卡片 1.5–2 px
- **圆角**：12 px
- **字号层级**：32/40（标题）、24/32（主文本）、20/26（标签）、18/24（正文）、16/22（提示）
- **HUD 文案**：不使用 emoji
- **避免**：大面积纯色块
- **原则**：一屏一卡片
- **交互方式**：`onKeyDown`（Enter / Backspace）+ 语音 —— **不支持点击和文本输入**

完整规范见 `Docs/SPEC.md`。

## 文档索引

| 文件 | 内容 |
|------|------|
| `Docs/SPEC.md` | 技术和产品规范的唯一事实来源 |
| `Docs/TODO.md` | 可执行的任务清单 |
| `Docs/NEXT.md` | 接下来 1–3 个优先任务 |
| `Docs/LOG.md` | 关键决策和 AI/用户协作记录 |
| `Docs/MeetMemo-AIUI-Development-Plan.md` | 原始产品计划（含修订标注） |
| `Docs/AIUI-Cheatsheet.md` | aiui-dev skill 速查手册 |

## 相关链接

- AIUI 官方仓库：<https://github.com/jsar-project/AIUI>
- AIUI 脚手架 CLI：`npx @yodaos-pkg/create-aiui-agent my-agent`
- Craft 在线工作区：<https://js.rokid.com/craft>
- Ink Playground：<https://jsar-project.github.io/ink/playground.html>

## 常见问题排查

### `npm start` 立即退出

端口 8081 被占用。Windows 下：

```bash
netstat -ano | findstr :8081
taskkill /F /PID <pid>
```

或更换端口：`PORT=8082 npm start`

### 浏览器显示空白画布

打开开发者工具控制台。页面上的 `#log` 元素也会显示加载错误信息。

### `openFromVfs` 报 404

访问 `http://127.0.0.1:8081/ink-vfs/apps/meetmemo/manifest` 确认列出的文件是否正确。如果 `.git/` 或 `node_modules/` 泄漏其中，说明 staging 步骤（`stageBundle`）未执行；删除 `.ink-build/` 后重启即可。

### WASM 初始化失败

确认 `http://127.0.0.1:8081/ink/pkg/ink_web_bg.wasm` 返回 200，且 `Content-Type` 为 `application/wasm`。

---

> **项目状态**：正在重构中。早期构建的 4 页触屏+点击 UI 对 AR 眼镜输入模型（无触摸屏、无键盘）是错误的。下一个里程碑是**单页 HUD**，由 `onKeyDown(Enter/Backspace)` 和语音驱动，参考 [`rokid-lens-coach`](./reference/) 项目。详见 `Docs/NEXT.md`。
