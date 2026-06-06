# SPEC

## 1. Project Name

MeetMemo AIUI

## 2. Product Type

Offline conversation memory Agent for Rokid AIUI.

## 3. Technical Stack

Primary runtime:

- Rokid AIUI on Rokid AR glasses (developer device).

Primary page format:

- `.ink` Single File Component.

Expected AIUI file structure:

```text
AGENTS.md
app.json
app.js
pages/
assets/
services/
```

## 3.1 Runtime And Local Development Reality

This section exists because the original development plan did not describe how the project actually runs. As of 2026-06-06:

- **Craft** (Rokid's official workspace with live preview) is announced but **not released** ("敬请期待").
- **Ink** runtime GitHub repository is announced but **not open-sourced** ("Coming Soon").
- **JSAR** (the open-source runtime at jsar.rokid.com) targets HTML5/CSS3/TS and **does not run `.ink` SFCs**.
- **Ink Playground** (`https://jsar-project.github.io/ink/playground.html`) is the only public web-based preview surface, but is single-file oriented.

For this project:

- **Primary verification: Rokid AR glasses (developer hardware).** Code is pushed to the device and validated there. This is the only environment that exercises real `wx.*` APIs, voice integration, and the 480px display.
- **Auxiliary debugging:** Ink Playground may be used to sanity-check isolated `.ink` snippets (component styling, single-page rendering) when iterating on visual details without redeploying to the device.
- **Do not assume any browser-based mock represents real runtime behavior** — `wx.*` storage, `LanguageModel`, `wx.media.*`, and InkView interaction lifecycle only exist on the device.

If the project ever needs to onboard a contributor without device access, add a fallback browser mock then; do not invest in it preemptively.

## 3.2 Repository Layout

The project root must stay free of vendor dumps and reference material. Enforced layout:

```text
/
├── AGENTS.md            # MeetMemo agent manifest
├── app.json             # AIUI app config
├── app.js               # AIUI app entry
├── pages/               # AIUI pages (.ink SFCs)
├── services/            # Parser, storage adapter, demo data, date utils
├── assets/              # Icons, fonts, images
├── Docs/                # Project management docs (SPEC, TODO, NEXT, LOG, plans)
├── .agents/             # Installed Claude/agent skill library (aiui-dev, ...)
├── reference/           # READ-ONLY vendor artifacts (scraped docs, bundle.js)
│                        # See reference/README.md
├── .gitignore
└── .git/
```

Rules:

- Do not put project source files under `reference/`.
- Do not import code from anything inside `reference/`.
- Large vendor bundles in `reference/` are git-ignored by default (see `.gitignore`).

Recommended page structure:

```html
<script def>
{}
</script>

<script setup>
export default {}
</script>

<page>
</page>

<style>
</style>
```

## 4. AIUI Development Rules

Use the installed `aiui-dev` skill as the source of truth for AIUI structure, components, APIs, and design limits.

Key references:

- `.agents/skills/aiui-dev/SKILL.md`
- `.agents/skills/aiui-dev/components.md`
- `.agents/skills/aiui-dev/apis.md`
- `.agents/skills/aiui-dev/apis-wx.md`
- `.agents/skills/aiui-dev/apis-device.md`
- `.agents/skills/aiui-dev/apis-ai.md`

Before using an AIUI or `wx.*` API, check the relevant reference file first. Do not assume browser or WeChat Mini Program behavior without confirmation.

## 5. Wearable UI Rules

- Standard width: 480px.
- Recommended height: 120px to 380px.
- Use card-style UI.
- Default background should be black or token-based dark surface.
- Prefer AIUI theme tokens such as `var(--color-primary)`, `var(--color-background)`, `var(--color-surface)`, `var(--color-text-primary)`, `var(--spacing-md)`, and `var(--radius-md)`.
- Avoid long paragraphs.
- Avoid dense tables.
- Avoid emoji in UI copy unless explicitly requested.
- Avoid large solid color blocks.
- Prioritize glanceable text and clear hierarchy.

## 6. Architecture Rules

Separate responsibilities:

- UI pages render state and handle user interaction.
- `services/parser.js` parses quick notes into structured data.
- `services/contact-store.js` owns persistence behavior.
- `services/demo-data.js` owns sample data.

Do not scatter storage calls across pages. Use a storage adapter.

Do not mix parsing logic directly into page templates. Use a parser service.

Do not add abstractions before they remove real duplication or protect an unstable boundary.

## 6.1 Parser Strategy

The MeetMemo development plan §8 originally proposed regex-based fixed-pattern parsing in Phase 1. **This is rejected.** Pattern matching ("记一下，{name}", "下周二") is fragile (breaks on "帮我记一下哈"), produces invented fields when patterns partially match, and the entire regex codebase becomes garbage the day an LLM is wired in.

Phase 1 — Zero parsing, good interaction:

- The full input string is stored unchanged in `notes`.
- All structured fields (`name`, `role`, `organization`, `context`, `interests`, `nextAction`, `followUpAt`) default to `"待补充"` or empty.
- The confirmation card is an **inline editor**, not a read-only preview. The user fills in (or corrects) each field with one tap before saving.
- The parser service still exists, returning `{ notes, status: 'needs-input' }`. It exists as a stable seam, not as logic to maintain.

Phase 2 — LLM extraction:

- Replace the parser body with a single LLM call that returns the structured schema.
- Apply schema validation. Unknown fields stay `"待补充"`. Never let the LLM invent missing facts (no hallucinated `organization` because the model "felt" it should exist).
- Keep the confirmation editor intact. LLM output is a suggestion, not a save.

Why this matters:

- Phase 1 ships in hours, not days.
- The throwaway code in Phase 1 is roughly 10 lines, not a regex engine.
- The interaction (always-editable confirmation card) is correct for both phases — no UX regression when LLM lands.

## 6.2 Parser Anti-patterns

Do not:

- Apply Chinese-language regex heuristics to extract people, dates, or actions.
- Auto-default `priority` to `"medium"` from voice input.
- Auto-default `organization` to a guess derived from `role`.
- Build a "smart" date parser ("下周二") before the LLM stage — let the user type or pick the date.

## 7. Data Model

Contact:

```json
{
  "id": "contact_001",
  "name": "王磊",
  "role": "教育 SaaS 创始人",
  "organization": "待补充",
  "context": "AI 创业活动",
  "interests": ["AIUI Demo"],
  "nextAction": "下周二发送 Demo 资料",
  "followUpAt": "2026-06-09",
  "notes": "对眼镜端低打扰交互感兴趣",
  "createdAt": "2026-06-06T10:00:00+08:00",
  "updatedAt": "2026-06-06T10:00:00+08:00"
}
```

Field rules:

- All string fields except `id`, `createdAt`, `updatedAt` may be `"待补充"` or empty.
- `interests` may be an empty array.
- `followUpAt` is optional. When absent, no follow-up task is generated.
- **`priority` is intentionally NOT in MVP.** Priority is a follow-up *management* concern, not a capture-time concern. Adding it now slows the 20-second capture target. Reintroduce only if real users sort by it.

Follow-up:

```json
{
  "id": "followup_001",
  "contactId": "contact_001",
  "title": "发送 Demo 资料",
  "dueAt": "2026-06-09",
  "status": "pending"
}
```

Follow-up field rules:

- A follow-up is created **only when** a contact has both `nextAction` and `followUpAt`.
- `status` is `"pending"` or `"done"` in MVP. No richer state machine.
- `priority` is also NOT in MVP follow-ups (same reason as Contact).

## 8. Privacy Rules

- User must actively start note capture.
- Always show a visible capture/listening state.
- Always confirm extracted fields before saving.
- Do not save raw audio in MVP.
- Support delete or discard.
- Do not imply hidden recording.

## 9. Commenting Rules

Write comments where intent is not obvious.

Comments are required for:

- Parsing heuristics.
- Date extraction rules.
- Storage fallback behavior.
- AIUI API compatibility assumptions.
- Privacy-sensitive behavior.

Avoid comments that merely repeat the code.

Bad comment:

```javascript
// Set name.
contact.name = name;
```

Good comment:

```javascript
// Keep missing fields explicit so the UI can ask for confirmation instead of inventing facts.
contact.organization = organization || '待补充';
```

## 10. Similar Product Reference Principles

Reference categories:

- CRM contact notes.
- AI meeting note tools.
- Personal memory assistants.
- Voice memo tools.
- Lightweight task managers.

Do not copy broad product scope. Borrow only proven interaction patterns:

- Fast capture.
- Structured summaries.
- Confirmation before save.
- Follow-up task extraction.
- Search and recall.

The product should not become a full CRM, meeting transcript app, or generic AI assistant.

## 11. Maintainability Requirements

- Keep MVP pages small.
- Keep service files focused.
- Avoid duplicated schemas.
- Keep demo data separate from production data handling.
- Use stable IDs for contacts and follow-ups.
- Add validation when parsing external or AI-generated data.
- Prefer simple state transitions over clever hidden flows.

## 12. First MVP Definition

The first MVP is complete when:

- A user can input one quick note.
- The app parses it into a contact draft.
- The app shows a confirmation card.
- The app saves a contact.
- The app generates one follow-up task.
- The home page can display the saved contact and pending follow-up count.

