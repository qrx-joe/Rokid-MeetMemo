# Agent Manifest

## Identity

- **Name**: MeetMemo
- **Version**: 0.1.0
- **Description**: 离线对话记忆 Agent — 让佩戴 Rokid AR 眼镜的用户主动说出一段简短笔记，Agent 把它结构化成一张关系卡片，并自动生成一个跟进任务。聚焦活动、会议、面试、销售、商务社交场景，**不做后台监听，不做自动转录**。
- **Author**: MeetMemo Dev

## Capabilities

- **Permissions**:
  - microphone   # 语音快速记录入口（仅用户主动触发时启用）
  - audio        # 提示音 / TTS 回读确认卡片
  - network      # Phase 2 LLM 结构化解析需要联网

- **Skills**:
  - quick-note-capture        # 接收一段短文本/语音，落到结构化关系卡片草稿
  - contact-card-render       # 展示一张人物关系卡片
  - follow-up-extraction      # 从 nextAction + followUpAt 生成跟进任务

## Privacy Posture

详见 `Docs/SPEC.md` §8。关键承诺：

- 用户必须主动触发录入，无后台录音。
- 录音/输入界面必须可见地显示"正在记录"状态。
- 保存前必须出现确认卡片，由用户编辑/确认每个字段。
- 不保存原始音频；仅保存结构化笔记。
- 用户随时可删除已保存条目。
