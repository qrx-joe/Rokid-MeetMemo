# LOG

## 2026-06-06

### Project Direction

Selected the offline conversation memory Agent as the first-priority idea.

Reasoning:

- It fits Rokid glasses better than generic web-style tools.
- It uses voice and glanceable display naturally.
- It avoids direct competition with broad official features such as general AI assistant, translation, navigation, and meeting transcription.
- It has clearer business value for founders, sales, BD, recruiters, consultants, and event-heavy users.

### MVP Boundary

The MVP is active quick-note capture, not passive recording.

Important boundary:

- User must actively start a note.
- App should show a confirmation card before saving.
- Raw audio should not be saved in MVP.
- Missing fields must stay unknown instead of being invented.

### Documentation Decision

Created four project management documents:

- `TODO.md`: full executable task list.
- `NEXT.md`: immediate 1-3 next tasks.
- `LOG.md`: key decisions and AI/user collaboration notes.
- `SPEC.md`: technical and product development standards.

Rejected a separate `ADVICE.md` for now because advice should become decisions or tasks, not a pile of vague notes.

### Existing Reference

Main development plan:

- `Docs/MeetMemo-AIUI-Development-Plan.md`

Installed AIUI skill context:

- `.agents/skills/aiui-dev/SKILL.md`
- `.agents/skills/aiui-dev/components.md`
- `.agents/skills/aiui-dev/apis.md`

## 2026-06-06 (afternoon revision)

### Pre-Implementation Review

Before writing the first line of code, ran a critical review of the existing plan. Surfaced and resolved the following blockers:

#### Runtime environment was undefined

The original plan and SPEC did not specify how a `.ink` file actually runs. Investigation results:

- Craft (official workspace) and Ink GitHub repo are both "coming soon".
- JSAR is open-sourced but targets HTML5/CSS3/TS, not `.ink` SFCs.
- Ink Playground exists but is single-file oriented.
- **User has a Rokid AR glasses developer device.** This is now the primary verification target.

Recorded in `SPEC.md` §3.1.

#### Repository layout was polluted

Root contained 8 MB of scraped Rokid documentation HTML/JS mixed with project intent files. Moved all `rokid_*.{js,html}` into `reference/` with an explanatory `reference/README.md`. Added `.gitignore` (vendor bundles untracked by default). Initialized git on `main`. Recorded in `SPEC.md` §3.2.

#### Parser strategy was fragile

Plan §8 proposed regex-based fixed-pattern extraction ("记一下，{name}"). Rejected:

- Breaks on natural variation ("帮我记一下哈").
- Generates throwaway code that gets deleted when LLM lands in Phase 2.
- Risks inventing fields the user did not provide.

New strategy ("zero parsing + good interaction"): full input into `notes`, all structured fields default to `"待补充"`, confirmation card is an inline editor. Recorded in `SPEC.md` §6.1.

#### Data model carried premature complexity

`priority: "medium"` removed from both Contact and Follow-up models. Priority is a follow-up *management* concern, not a capture-time concern; adding it at capture time slows the 20-second target. Recorded in `SPEC.md` §7.

#### Milestone cadence was inflated

Day 1–7 schedule allocated a full day to file scaffolding that the `aiui-dev` skill cheatsheet makes a 20-minute task. Plan amendment banner added at top of `MeetMemo-AIUI-Development-Plan.md` flagging the cadence as too slow. Realistic MVP: 1–2 working days. `NEXT.md` rewritten accordingly.

### Decisions Index

| Decision | Recorded in |
| --- | --- |
| Run on Rokid AR glasses; Playground is auxiliary only | `SPEC.md` §3.1 |
| `reference/` holds vendor artifacts, not project code | `SPEC.md` §3.2 |
| Phase 1 parser does no extraction; confirmation card is editable | `SPEC.md` §6.1 |
| `priority` field removed from MVP data model | `SPEC.md` §7 |
| Original plan §8 and §14 are deprecated; SPEC is source of truth | Banner in `MeetMemo-AIUI-Development-Plan.md` |

## 2026-06-06 (evening — capture flow)

### Built

End-to-end capture → store → display flow, all from text input. Two services and two pages now compose:

- `services/contact-store.js`: in-memory `Map`-backed adapter exposing `listContacts / getContact / saveContact / listFollowups / updateFollowupStatus`. Async signatures throughout so the future `wx.storage` swap costs zero changes at call sites. Seeded with the 王磊 demo contact + a matching follow-up so any page opened in isolation still renders.
- `services/parser.js`: zero-parsing stub per SPEC §6.1. `parse(text)` returns `{ contact, status: 'needs-input' }` with `notes` filled verbatim and every other field blank. Phase 2 will replace the body with an LLM call; the return shape is the stable seam.
- `pages/capture/capture.ink`: two-mode state machine (`input` → `confirm`). Confirm view is a `scroll-view` of 8 editable fields using a single `handleField` handler driven by `data-field="..."` dataset, so the per-field input handlers fan out to one method.
- `pages/contact-card/contact-card.ink`: now reads `?id=` from `onLoad(query)`, pulls from the store, and falls back to the seeded demo when no/unknown id is provided. This keeps standalone open working while the capture flow can pass real saved ids.
- `app.json`: pages array now `['pages/capture/capture', 'pages/contact-card/contact-card']` — capture is the MVP entry point.

### Decisions made this round

| Decision | Why | Risk if wrong |
| --- | --- | --- |
| Single generic `handleField` on capture via `data-field` dataset | Reduces 8 per-field handlers to 1; idiomatic WeChat-style pattern | If Ink does not forward `currentTarget.dataset`, expand to per-field handlers (mechanical change) |
| Async API on `contactStore` even though impl is sync | Lets the wx.storage swap not touch any caller | None — adds a Promise wrapper at most |
| Save triggers `wx.navigateTo` to contact-card with `encodeURIComponent(id)` | Standard mini-program nav; the saved card is the natural success page | If `navigateTo` differs in Ink, the save still succeeds in the store — only the redirect breaks |
| Interests edited as comma-joined string, re-split on save | Avoids building an array-editor UI in MVP; tolerant of both `,` and `，` | User confusion if they paste a list with semicolons. Add `/[,，;；]/` if it bites |
| `crypto.randomUUID()` for ids with a `Date.now()+Math.random()` fallback | SKILL.md §8 confirms support; fallback keeps save flow from crashing on older runtimes | Worst case: ids include a timestamp — still unique |
| Capture page does NOT pre-fill name from `notes` | Phase 1 must not guess; user authors `name` from scratch | None — this is the SPEC §6.1 commitment |
| `scroll-view` `max-height: 360px` on capture confirm | Keeps the page inside SPEC §5 (120–380px) without truncating tall edit forms | If Ink ignores `max-height` on `scroll-view`, content may exceed; switch to fixed `height` |

### Deferred deliberately

- Persistence (`wx.storage`) — until navigation backbone (`index`, `followups`) is verified on device.
- `services/demo-data.js` extraction — seed lives inside `contactStore` for now; extract only if 3+ surfaces share it.
- LLM parser — Phase 2.
- Voice integration — Phase 3.
- Date picker for `followUpAt` — string input + `YYYY-MM-DD` regex validation is enough for MVP.

### Carried risk

The previous round's contact-card was committed without device verification, and this round was built on top of it. If contact-card has a token or `ink:if` issue on the real Rokid runtime, capture's save-then-navigate will land on a broken page. Mitigation: validate both pages in a single device session next.

## 2026-06-06 (late — navigation backbone)

### Built

Navigation now closes: index → capture → contact-card → followups → contact-card. Four pages, one store, one parser.

- `pages/index/index.ink`: home with "开始记录" CTA, `scroll-view`-bounded recent contacts list (5 max), and a "待跟进 N" row. `onLoad` + `onShow` both call `_refresh()` so returning from any sub-page picks up new state.
- `pages/followups/followups.ink`: pending / completed sections. Each row resolves the contact name lazily via `contactStore.getContact()` rather than duplicating contact fields in the followup record. Row body navigates to the contact card; an inline `catchtap` button toggles `pending` ↔ `done`.
- `app.json`: pages array now `['pages/index/index', 'pages/capture/capture', 'pages/contact-card/contact-card', 'pages/followups/followups']` — index is the new homepage; capture/contact-card/followups become sub-routes with the default navigation back button.

### The single design principle this round

**Do not introduce a new runtime assumption.** Index and followups reuse exactly the patterns capture proved on paper:

- `async onLoad` (and the new `async onShow`) returning a Promise the runtime can ignore.
- `wx.navigateTo({ url: '/pages/...?key=value' })` with leading slash and `encodeURIComponent` on dynamic ids.
- `e.currentTarget.dataset.<camelCase>` for dispatching handlers — same as capture's `handleField`.
- `catchtap` to stop propagation when an inline button sits inside a `bindtap` row.
- `var(--token)` exclusively; no hex literals.
- `scroll-view` with `max-height: Npx` to keep cards inside the SPEC §5 height envelope.

The payoff: if device verification surfaces a runtime gap, the fix lands in the same shape across all four pages. One investigation, one mechanical refactor.

### Decisions made this round

| Decision | Why | Risk if wrong |
| --- | --- | --- |
| `onShow` re-pulls store on every visibility | Captures changes made from sub-pages without an event bus | If `onShow` never fires, the list goes stale until app relaunch — graceful degrade |
| Followup rows resolve contact name via `getContact` per row | Followup records stay normalized; no duplicated contact name to update on rename | Slight Promise.all cost; trivial at MVP list sizes |
| `index.recentContacts` is a 4-field projection, not full Contact objects | Smaller setData payload, cleaner template binding | None — the contact card pulls the full object on tap |
| Empty states render only when `loaded` is true | Prevents "no contacts" flashing before the async pull resolves | None — purely a UX nicety |
| `followups` page uses `catchtap` on action buttons | Standard mini-program propagation control | If `catchtap` is unsupported, the row tap fires too — both actions land on the same followup; functionally noisy but not destructive |
| `scroll-view max-height` on three pages | Honors SPEC §5 height envelope without truncating long lists | If Ink ignores `max-height`, switch to `height` in 3 places |

### The carried risk reached its third round

This is now the third stacked commit without device verification. NEXT.md is explicit: stop, validate, then continue. If a runtime gap exists, fixing 4 pages in one pass is acceptable; fixing 7 pages after persistence and voice land would not be.

### Deferred deliberately (unchanged)

- Persistence (`wx.storage`)
- LLM parser (Phase 2)
- Voice integration (Phase 3)
- `services/demo-data.js` extraction
- Date picker for `followUpAt`

## 2026-06-06 (late evening — pivot to reference-aligned project)

### The trigger

User dropped `reference/rokid-lens-coach/` — a complete AIUI demo project — and asked: *"对照看看你按要求实现了吗?"*. The honest answer was **no**, and the differences were structural, not cosmetic.

### Four categories of gap identified

1. **Fatal — interaction model**

   The reference project's `pages/index/index.ink` is driven entirely by `onKeyDown(Enter | Backspace)` plus `speechSynthesis` for TTS. Rokid AR glasses have **no touchscreen and no keyboard**. Every `bindtap`, `<textarea>`, `<input>`, and `wx.navigateTo`-based navigation MeetMemo built across 4 pages is unusable on the actual device.

2. **Major — missing toolchain**

   Reference has `package.json` (scripts.test), `.aixignore`, `lib/` (instead of `services/`), `test/` with Node's built-in test runner, and a documented `.aix` packaging step. MeetMemo had none of these.

3. **Substantive — SKILL.md vs runtime mismatch**

   `SKILL.md` recommends `var(--token)` everywhere. The reference project uses **hex literals exclusively** (`#40FF5E`, `rgba(64, 255, 94, 0.4)`). The official `@yodaos-pkg/create-aiui-agent` scaffold does the same. Tokens are likely unsupported by the current Ink build.

   Reference also explicitly avoids complex inline `ink:if` expressions: *"Uses precomputed template fields instead of complex inline template expressions for better AIUI compatibility."* MeetMemo's `ink:if="{{ (a && a !== '待补充') || b }}"` form may fail to parse on real Ink.

4. **Configuration — `<script def>` and `app.json`**

   Reference uses `<script type="application/json" def>` (with explicit MIME type). MeetMemo used the bare `<script def>`. Reference `app.json` is minimal (no `navigationBarBackgroundColor`, no `backgroundColor`, no `navigationBarTextStyle`) — those extra fields probably ignored by Ink.

### Windows toolchain investigation result

The reference project's `aiui-open` / `aiui-aix` are macOS binaries (no Windows release on GitHub — `releases` API returns `[]`). However, the npm scope `@yodaos-pkg/` ships **cross-platform** packages:

| Package | Role |
| --- | --- |
| `@yodaos-pkg/ink` 0.12.3 | Ink Web SDK (WASM in browser) |
| `@yodaos-pkg/ink-vfs-server` 0.1.0 | HTTP VFS exposing app files |
| `@yodaos-pkg/aix` 0.6.0 | AIX **Reader** (not packager) |
| `@yodaos-pkg/create-aiui-agent` 2.1.2 | Project scaffold |

This means **Windows users get a full local browser preview via npm**, no platform binaries required. The only step still macOS-bound is the final `.aix` packaging for Lingzhu upload.

### What this round shipped

- `package.json` rewritten with `scripts.start`, `scripts.test`, dev dependencies.
- `.aixignore` modeled on the reference project's exclusion list.
- `dev-server.js` — Express host that mounts the Ink SDK at `/ink`, mounts the VFS middleware at `/ink-vfs`, and serves the preview shell from `public/`.
- `public/index.html` — canvas + Ink WASM bootstrap; the user opens this in a browser to see the real Ink runtime render the project.
- Pre-serve staging: `dev-server.js` copies only `app.json`, `app.js`, `AGENTS.md`, `pages/`, `services/`, `assets/` into `.ink-build/` and points the VFS at that subdir. `node_modules`, `.git`, `Docs`, `reference` never reach the runtime.
- Verified: `npm start` works on Windows; manifest contains 9 expected files; `app.json` reachable through VFS; Ink WASM downloads with the correct `Content-Type`.
- `README.md` rewritten in the lens-coach style: Demo Flow, Project Structure, Prerequisites, Local Development, Packaging, Upload, Design Rules, Troubleshooting.
- `SPEC.md` extended with §3.3 local toolchain, §3.4 `.ink` conventions alignment, §5.7 CSS token reality, §5.8 template expression constraints, §6.3 interaction model for AR glasses, plus a note on `services/` → `lib/` migration.

### What this round deliberately did NOT do

- The four existing pages (capture/contact-card/followups/index) are **not yet rewritten**. They still use `bindtap` / `<input>` / `<textarea>` and likely contain `var(--token)` calls. The next milestone is the HUD rewrite, and trying to "patch" the wrong UI before then would waste effort.
- `services/` → `lib/` rename deferred to the HUD rewrite (the new HUD will declare what `lib/` modules it needs; rename now would create churn for code that may be deleted).
- `.aix` packaging path remains open. Decision: continue on browser preview; arrange a Mac session once the HUD is renderable end-to-end.

### Decisions index (updated)

| Decision | Recorded in |
| --- | --- |
| Drop touchscreen UI assumptions; default to HUD + onKeyDown + voice | `SPEC.md` §6.3 |
| Use hex literals, not `var(--token)`, until tokens are runtime-confirmed | `SPEC.md` §5.7 |
| Precompute booleans for `ink:if`; avoid compound expressions in templates | `SPEC.md` §5.8 |
| `<script type="application/json" def>` is the documented form | `SPEC.md` §3.4 |
| Local preview via `@yodaos-pkg/ink` + `ink-vfs-server` + express (Windows-friendly) | `SPEC.md` §3.3 |
| `services/` → `lib/` migration deferred to HUD rewrite | `SPEC.md` §6 note |
| HUD: 480 × 400 fixed safe zone (supersedes earlier 120–380 height range) | `SPEC.md` §5 |





