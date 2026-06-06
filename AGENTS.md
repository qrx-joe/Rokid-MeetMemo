# Agent Manifest

## Identity

- **Name**: MeetMemo
- **Version**: 3.0.0
- **Description**: MeetMemo 是 Rokid AIUI 联系人记忆智能体。用户可以主动说“记录一下今天见到的人”，保存联系人关系卡片、查看最近认识的人、回忆今天见了谁，并生成待跟进任务。MeetMemo is a Rokid AIUI contact memory agent for quick contact notes, recent contact recall, and follow-up tasks.
- **Author**: MeetMemo Dev

## Capabilities

- **Permissions**:
  - microphone
  - audio
  - network

- **Skills**:
  - quick-note-capture
  - contact-memory
  - recent-contact-recall
  - today-contact-review
  - query-contact-memory
  - contact-card-render
  - follow-up-extraction
  - follow-up-reminder
  - pending-follow-up-review
  - remember-person

## Example Utterances

- 记录一下今天见到的人
- 今天见了什么人
- 查看最近认识的人
- 查一下刚才认识的人
- 查看待跟进事项
- 帮我记一个联系人

## Privacy Posture

Key commitments:

- User-initiated capture only; no background recording.
- Visible listening state during capture.
- Confirm before saving.
- No raw audio is stored.
- Saved entries can be deleted.
