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
├── reference/           # READ-ONLY vendor artifacts (scraped docs, bundle.js,
│                        # lens-coach reference project). See reference/README.md
├── public/              # Browser preview shell (index.html for dev-server)
├── dev-server.js        # Local browser preview entry (Express + ink + VFS)
├── package.json         # Node tooling (test, start, deps)
├── .aixignore           # Files excluded from .aix package
├── .gitignore
└── .git/
```

Rules:

- Do not put project source files under `reference/`.
- Do not import code from anything inside `reference/`.
- Large vendor bundles in `reference/` are git-ignored by default (see `.gitignore`).
- `.ink-build/` is the staging dir produced by `dev-server.js`; git-ignored, regenerated on every `npm start`.

## 3.3 Local Browser Preview Toolchain

This project ships a **Windows-friendly local preview** that does not depend on macOS-only Rokid binaries.

Stack:

- `@yodaos-pkg/ink` — Ink Web SDK (WASM runtime in the browser)
- `@yodaos-pkg/ink-vfs-server` — HTTP VFS exposing project files to the runtime
- `express` — host process for the VFS middleware + static preview shell

Entry: `npm start` → `node dev-server.js` → open `http://127.0.0.1:8081`.

Before serving, `dev-server.js` stages only runtime files (`app.json`, `app.js`, `AGENTS.md`, `pages/`, `services/`, `assets/`) into `.ink-build/`. `node_modules`, `.git`, `Docs`, `reference` never leak into the VFS manifest.

What the preview validates:

- Page layout at 480 × 400
- WXML directives (`ink:if`, `ink:for`) and bindings
- WXSS theme tokens vs hex literals (whether `var(--card-padding)` exists at runtime)
- `bindtap`, `onKeyDown` event delivery, `setData` shape, `scroll-view` behavior

What the preview does NOT validate (only the device exercises these):

- `wx.media.*` (camera, recorder)
- `wx.speech.startRecognition`
- `LanguageModel`
- Real-glasses lighting, focus, and key hardware behavior

The browser preview is the primary day-to-day iteration loop; the device is the verification loop before each demo.

## 3.4 `.ink` SFC Conventions (alignment notes)

Cross-checked against the `rokid-lens-coach` reference project and `@yodaos-pkg/create-aiui-agent` scaffold:

- `<script def>` must include `type="application/json"`. The bare `<script def>` form may parse on some Ink builds but is not the documented form. Example:

  ```html
  <script type="application/json" def>
  { "navigationBarTitleText": "..." }
  </script>
  ```

- `<script setup>` exports the page object directly via `export default { ... }`. Do not wrap with `defineComponent` or any other framework helper.

- `<page>` uses WXML-style syntax; directives use the `ink:` prefix (`ink:if`, `ink:elif`, `ink:else`, `ink:for`, `ink:key`).

- `<style>` is WXSS, layout-compatible with CSS but with the runtime constraints in §5.

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
- Recommended height: **400px** (fixed safe zone per `rokid-lens-coach` reference; supersedes the earlier 120–380px range).
- Use card-style UI.
- Default background should be **black `#000000`** (hex literal, not `var(--color-background)` — see §5.7).
- Accent color: `#40FF5E` (Rokid green). Use hex literal directly; see §5.7.
- Border width: 1.5px on cards.
- Border radius: 12px.
- Type scale: `32/40` (title), `24/32` (primary), `20/26` (label), `18/24` (body), `16/22` (hint).
- Avoid long paragraphs.
- Avoid dense tables.
- Avoid emoji in UI copy unless explicitly requested.
- Avoid large solid color blocks.
- Prioritize glanceable text and clear hierarchy.

## 5.7 CSS Token Reality (overrides SKILL.md guidance)

`SKILL.md` recommends preferring `var(--color-primary)`, `var(--card-padding)`, etc. **This was the source-of-truth document, not the runtime truth.** The `rokid-lens-coach` reference project and the official `@yodaos-pkg/create-aiui-agent` scaffold **both use hex literals exclusively** (`#40FF5E`, `#000000`, `rgba(64, 255, 94, 0.4)`). No `var(--token)` calls anywhere.

Rule:

- **Default to hex literals for color, spacing, border, and radius values.** Match the values in §5.
- Use a `var(--*)` token only when verified to render correctly on the target Ink build.
- If a token name appears in `SKILL.md` but is unknown to the runtime, the style silently falls back to the default — often a transparent/white default that makes cards unreadable.

This is a runtime-vs-spec gap; until the Ink runtime publishes a confirmed token registry, hex literals are the safer surface.

## 5.8 Template Expression Constraints

The `rokid-lens-coach` reference explicitly states:

> Uses **precomputed template fields** instead of complex inline template expressions for **better AIUI compatibility**.

Rule:

- Templates evaluate **simple references** (`{{ greeting }}`) and **single boolean refs** in directives (`ink:if="{{ isStepOneActive }}"`).
- Compound expressions, string comparisons, ternaries, and `&&`/`||` chains inside `ink:if` are **discouraged**. Precompute the boolean in `<script setup>` and bind the precomputed flag.

Bad:

```html
<view ink:if="{{ (contact.organization && contact.organization !== '待补充') || contact.context }}">
```

Good:

```javascript
// In <script setup>:
function deriveView(data) {
  return {
    ...data,
    hasMeta: Boolean(
      (data.organization && data.organization !== '待补充') || data.context
    ),
  };
}
```

```html
<view ink:if="{{ hasMeta }}">
```

This keeps the template parser on its proven happy path and makes the boolean intent obvious in JS where it can be tested.

## 6. Architecture Rules

Separate responsibilities:

- UI pages render state and handle user interaction.
- `services/parser.js` parses quick notes into structured data.
- `services/contact-store.js` owns persistence behavior.
- `services/demo-data.js` owns sample data.

Do not scatter storage calls across pages. Use a storage adapter.

Do not mix parsing logic directly into page templates. Use a parser service.

Do not add abstractions before they remove real duplication or protect an unstable boundary.

> **Note on directory naming**: the `rokid-lens-coach` reference uses `lib/` instead of `services/`. MeetMemo will migrate `services/` → `lib/` during the HUD rewrite (see `Docs/NEXT.md`), aligning with the community convention. The interface contract stays the same.

## 6.3 Interaction Model (AR glasses)

**Rokid AR glasses have no touchscreen and no keyboard.** Inputs available to an Ink app are:

- Hardware key events (Enter, Backspace, possibly side keys) via `onKeyDown(event)`
- Voice via `SpeechRecognition` (when host capability is present)
- Camera frames via `wx.media.createCameraContext()` (when permitted)

UI patterns from web / mini-program / handheld phones **do not apply**:

| Pattern | Status on glasses | Why |
| --- | --- | --- |
| `bindtap` on a button | **Avoid** (works in browser preview only) | No touch surface on the device |
| `<textarea>`, `<input>` | **Avoid** | No keyboard; user cannot type |
| Multi-page navigation via `wx.navigateTo` | **Avoid for primary flows** | No back button gesture; pile-up of stacks confuses |
| `bindchange` on `<switch>` | **Avoid** | No selection focus mechanism |
| List of tap targets | **Avoid** | User cannot point at one |

Patterns that **do** apply:

- One-screen-at-a-time HUD with state-driven content
- `onKeyDown` for Enter (advance / confirm) and Backspace (back / exit)
- Voice prompts to gather structured input ("Now say their role")
- TTS feedback via `speechSynthesis.speak(new SpeechSynthesisUtterance(text))`
- Storage via `wx.setStorageSync(key, json)` and `wx.getStorageSync(key)`

Rule:

- New pages MUST default to a HUD + `onKeyDown` model.
- A `bindtap` or `<input>` is allowed only when explicitly justified for the browser-preview environment (e.g. debugging probes), and must not gate the primary user flow.

## 6.4 Parser Strategy

The MeetMemo development plan §8 originally proposed regex-based fixed-pattern parsing in Phase 1. **This is rejected.** Pattern matching ("记一下，{name}", "下周二") is fragile (breaks on "帮我记一下哈"), produces invented fields when patterns partially match, and the entire regex codebase becomes garbage the day an LLM is wired in.

Phase 1 — Zero parsing, voice-prompted authoring:

- The raw input string is stored unchanged in `notes`.
- All structured fields (`name`, `role`, `organization`, `context`, `interests`, `nextAction`, `followUpAt`) default to `""` or `"待补充"`.
- The HUD walks the user through each missing field via voice prompts (e.g. "What is their role?" → `SpeechRecognition` answer → set the field).
- The parser service still exists, returning `{ notes, status: 'needs-input' }`. It exists as a stable seam, not as logic to maintain.

Phase 2 — LLM extraction:

- Replace the parser body with a single LLM call that returns the structured schema.
- Apply schema validation. Unknown fields stay `"待补充"`. Never let the LLM invent missing facts.
- The voice-prompted authoring HUD still exists, but skips fields the LLM filled with confidence.

## 6.5 Parser Anti-patterns

Do not:

- Apply Chinese-language regex heuristics to extract people, dates, or actions.
- Auto-default `priority` to `"medium"` from voice input.
- Auto-default `organization` to a guess derived from `role`.
- Build a "smart" date parser ("下周二") before the LLM stage — let the user speak the date or the HUD pick today + 7.

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

