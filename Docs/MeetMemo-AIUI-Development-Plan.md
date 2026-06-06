# MeetMemo AIUI Development Plan

> **Amendments — 2026-06-06**
>
> This plan captures the original product thinking. Several sections have been **superseded** by `SPEC.md` after a design review. Treat `SPEC.md` as the source of truth; this file is kept as the product-direction reference.
>
> - §7 Data Model — `priority` field removed (see `SPEC.md` §7). `organization` default changed from `"未知"` to `"待补充"`.
> - §8 Parsing Strategy — Phase 1 regex-based pattern matching **rejected**. Use "zero parsing + good interaction": full input goes to `notes`, all structured fields default to `"待补充"`, the confirmation card is an inline editor. See `SPEC.md` §6.1.
> - §14 Development Milestones — Day 1–7 cadence is too slow given the `aiui-dev` skill cheatsheet already exists. Real MVP scope fits 1–2 working days. See `NEXT.md`.
> - Runtime / preview — Original plan did not specify how to run `.ink` files. Decision: push to Rokid AR glasses (developer hardware). See `SPEC.md` §3.1.
> - Repository layout — Vendor dumps moved into `reference/`; `git init` performed. See `SPEC.md` §3.2.

## 1. Product Positioning

MeetMemo is an offline conversation memory Agent for Rokid AIUI. It helps users actively record key information about people they meet during events, meetings, interviews, sales conversations, and business networking.

The MVP should not be positioned as passive recording or hidden meeting surveillance. That direction creates privacy, consent, noise, and trust problems too early. The first version should be an active quick-note Agent:

> The user deliberately speaks a short note, the Agent structures it into a relationship card, and the app generates follow-up reminders.

Example input:

```text
记一下，王磊，教育 SaaS 创始人，对 AIUI Demo 感兴趣，下周二发资料。
```

Example output:

```text
王磊
教育 SaaS 创始人

关注：
AIUI Demo

下一步：
下周二发送资料
```

## 2. Core Goals

- Capture key offline conversation details through voice or typed simulation input.
- Convert natural language notes into structured relationship cards.
- Display concise, wearable-friendly cards through Rokid AIUI.
- Generate follow-up tasks from captured conversation notes.
- Let users quickly review recent contacts and pending follow-ups.

## 3. Non-Goals For MVP

- Do not build always-on recording.
- Do not secretly transcribe conversations.
- Do not use face recognition.
- Do not attempt full CRM replacement.
- Do not depend on camera input in the first version.
- Do not overbuild complex multi-user relationship graphs.
- Do not claim automatic perfect extraction from noisy real-world conversations.

These are traps. If the MVP starts here, the project becomes fragile, legally risky, and technically bloated before it proves the basic interaction value.

## 4. Target Users

Primary users:

- Founders attending events.
- Sales and business development people.
- Recruiters.
- Consultants.
- Investors.
- Community organizers.
- Job seekers doing offline networking.

The first user profile should be narrow:

> A founder or BD person attending an offline AI event who needs to remember people, interests, and follow-up actions.

## 5. MVP User Flow

1. User opens MeetMemo on Rokid glasses.
2. Home page shows "Start Quick Note" and recent contacts.
3. User speaks or inputs a short note.
4. App parses the note into a structured contact draft.
5. Confirmation card displays extracted fields.
6. User confirms save.
7. Contact card is stored locally.
8. Follow-up task appears in the follow-up list.
9. User can review today's contacts or pending follow-ups.

## 6. AIUI Project Structure

Follow the `aiui-dev` skill conventions:

```text
AGENTS.md
app.json
app.js
pages/
  index/
    index.ink
  capture/
    capture.ink
  contact-card/
    contact-card.ink
  followups/
    followups.ink
assets/
  icons/
  images/
```

Recommended page responsibilities:

- `pages/index/index.ink`: Home, recent contacts, entry points.
- `pages/capture/capture.ink`: Voice/text capture, parse preview, confirmation.
- `pages/contact-card/contact-card.ink`: Structured relationship card display.
- `pages/followups/followups.ink`: Pending follow-up task list.

## 7. Data Model

Use a simple local model first:

```json
{
  "id": "contact_001",
  "name": "王磊",
  "role": "教育 SaaS 创始人",
  "organization": "未知",
  "context": "AI 创业活动",
  "interests": ["AIUI Demo", "企业培训场景"],
  "nextAction": "下周二发送 Demo 资料",
  "followUpAt": "2026-06-09",
  "priority": "medium",
  "notes": "对眼镜端低打扰交互感兴趣",
  "createdAt": "2026-06-06T10:00:00+08:00",
  "updatedAt": "2026-06-06T10:00:00+08:00"
}
```

Follow-up task model:

```json
{
  "id": "followup_001",
  "contactId": "contact_001",
  "title": "发送 Demo 资料",
  "dueAt": "2026-06-09",
  "status": "pending",
  "priority": "medium"
}
```

## 8. Parsing Strategy

Start with a mock parser before adding LLM calls.

Phase 1 parser:

- Extract name by fixed patterns such as "记一下，{name}".
- Extract role/company from phrase fragments.
- Extract next action from "下周", "明天", "发", "联系", "约", "跟进".
- Mark missing fields as "待补充".

Phase 2 parser:

- Use an LLM to transform notes into the contact schema.
- Add validation and fallback.
- Never invent missing facts. Unknown fields must stay unknown.

Bad smell to avoid:

> Building a magical all-purpose conversation understanding engine before the app can save and display one useful card.

## 9. UI Design Rules

Follow AIUI wearable constraints:

- Width: 480px.
- Recommended height: 120px to 380px.
- Use card-style layout.
- Default background: black.
- Prefer AIUI theme tokens.
- Prefer short labels and short lines.
- Use large readable text.
- Avoid dense tables.
- Avoid long paragraphs on the glasses display.
- Avoid emoji.
- Avoid large solid color blocks.

Recommended visual hierarchy:

- Primary line: name.
- Secondary line: role or organization.
- Body: interests and context.
- Footer: next action and follow-up date.

## 10. Page Specifications

### 10.1 Home Page

Purpose:

- Show entry point for quick note.
- Show recent contacts.
- Show pending follow-up count.

Main states:

- Empty state.
- Recent contacts available.
- Follow-up tasks pending.

Core actions:

- Start quick note.
- View follow-ups.
- Open recent contact.

### 10.2 Capture Page

Purpose:

- Collect a voice or simulated text note.
- Parse note into a draft card.
- Let user confirm before saving.

Main states:

- Idle.
- Listening or inputting.
- Parsed draft.
- Save success.
- Parse failed.

Important design point:

The confirmation step is required. Voice recognition and parsing will be imperfect, so saving directly is reckless.

### 10.3 Contact Card Page

Purpose:

- Display a person's structured memory card.

Fields:

- Name.
- Role.
- Organization.
- Context.
- Interests.
- Next action.
- Follow-up date.
- Notes.

The page should not display every field if the screen becomes crowded. Prioritize name, role, interest, and next action.

### 10.4 Follow-ups Page

Purpose:

- Show pending follow-up tasks.

Sections:

- Today.
- This week.
- Later.
- Completed.

MVP can start with only pending and completed.

## 11. Storage

MVP storage:

- Use local storage through AIUI-compatible `wx.*` storage APIs if available.
- If runtime support is not confirmed yet, implement a small storage adapter with mock data first.

Storage adapter interface:

```javascript
export const contactStore = {
  async listContacts() {},
  async getContact(id) {},
  async saveContact(contact) {},
  async listFollowups() {},
  async updateFollowupStatus(id, status) {}
};
```

Keep storage behind an adapter. Do not scatter direct storage calls across pages. Otherwise the app will become rigid as soon as persistence changes.

## 12. Voice Integration

Integrate voice only after the UI and data flow work with simulated input.

Voice commands:

- 新建记录
- 查看今天认识的人
- 查看待跟进
- 查一下王磊
- 保存
- 取消

Voice content example:

```text
记一下，李明，企业培训负责人，想看 AIUI Demo，下周一发介绍资料。
```

Required confirmation:

```text
已识别：
李明 / 企业培训负责人 / 下周一发资料

是否保存？
```

## 13. Privacy And Trust

The product must make privacy boundaries obvious:

- User must actively start a note.
- Do not imply background recording.
- Show a visible recording/listening state.
- Do not save raw audio in MVP.
- Save structured notes only.
- Let users edit or delete entries.

This is not optional polish. For offline social memory products, trust is the product.

## 14. Development Milestones

### Day 1: Project Skeleton

- Create `AGENTS.md`.
- Create `app.json`.
- Create `app.js`.
- Create page directories.
- Add mock data.

### Day 2: Home Page

- Implement home layout.
- Show recent contacts.
- Show follow-up count.
- Add navigation actions.

### Day 3: Capture Page

- Implement text-based note input.
- Add mock parser.
- Show parsed confirmation card.
- Save confirmed contact.

### Day 4: Contact Card Page

- Implement relationship card display.
- Handle missing fields.
- Add compact wearable layout.

### Day 5: Follow-up Page

- Implement pending follow-up list.
- Add completed state.
- Add simple status update.

### Day 6: Voice Entry

- Add voice command placeholder.
- Integrate AIUI voice API if confirmed.
- Keep text simulation fallback.

### Day 7: Demo Polish

- Polish typography, spacing, and card states.
- Add demo script.
- Test edge cases.
- Prepare short presentation flow.

## 15. Demo Script

Demo scenario:

1. User opens MeetMemo.
2. User starts quick note.
3. User says:

```text
记一下，王磊，教育 SaaS 创始人，对 AIUI Demo 感兴趣，下周二发资料。
```

4. App displays a confirmation card.
5. User confirms save.
6. App opens the relationship card.
7. Follow-up list shows "下周二发送 Demo 资料".
8. User checks today's new contacts.

## 16. Technical Risks

- AIUI voice API details may differ from generic browser speech APIs.
- Real-world voice recognition can be noisy.
- LLM parsing may hallucinate missing fields.
- Follow-up reminders may depend on unavailable system notification APIs.
- Wearable display space is limited; long CRM-like layouts will fail.

Mitigation:

- Start with text simulation.
- Use a parser adapter.
- Use a storage adapter.
- Keep cards compact.
- Confirm before saving.
- Treat unsupported APIs as optional enhancements.

## 17. Architecture Guardrails

- Keep parsing, storage, and UI separate.
- Do not put business logic directly inside every `.ink` page.
- Use adapters for storage, voice, and AI parsing.
- Avoid duplicated card rendering logic.
- Avoid circular imports between pages and services.
- Keep the MVP small enough to run before adding AI magic.

Suggested service structure:

```text
services/
  parser.js
  contact-store.js
  date-utils.js
  demo-data.js
```

## 18. Success Criteria

The MVP is successful if:

- A user can create a structured contact card in under 20 seconds.
- The generated card is readable on a 480px AIUI display.
- The follow-up action is visible without opening a long detail page.
- The app works with simulated input even before voice integration.
- Missing fields are handled gracefully.

## 19. Recommended Next Step

Start implementation with the project skeleton and mock data. Do not spend another week comparing ideas or hunting perfect APIs.

The first useful artifact should be:

> A working AIUI page that turns one short note into one relationship card and one follow-up task.

