# TODO

> Updated 2026-06-06 (late). See `LOG.md` for what changed and why.

## Product

- [x] Confirm MVP name: MeetMemo AIUI.
- [x] Confirm first target user: founder or BD person attending offline AI events.
- [ ] Define 3 demo scenarios.
- [x] Define privacy copy for active recording and manual confirmation. (See `AGENTS.md` Privacy Posture and `SPEC.md` §8.)

## Project Hygiene

- [x] Move scraped Rokid docs into `reference/` and isolate from project code.
- [x] Add `.gitignore` (untrack vendor bundles, IDE files, .venv).
- [x] `git init` on `main`, initial commit recorded.
- [x] Fix misplaced root `AGENTS.md` (was AIUI cheatsheet, moved to `Docs/AIUI-Cheatsheet.md`).
- [x] Rewrite root `AGENTS.md` as a real AIUI manifest (Identity / Capabilities / Privacy).

## AIUI App Skeleton

- [x] Create `app.json` (4 pages registered, index as homepage).
- [x] Create `app.js`.
- [x] Create `pages/index/index.ink`.
- [x] Create `pages/capture/capture.ink`.
- [x] Create `pages/contact-card/contact-card.ink`.
- [x] Create `pages/followups/followups.ink`.
- [x] Create `services/parser.js` (zero-parsing stub per SPEC.md §6.1).
- [x] Create `services/contact-store.js` (in-memory adapter, async API stable for wx.storage swap).
- [ ] Create `services/demo-data.js`. (Deferred — seeded demo lives inside `contact-store`; extract only when 3+ surfaces share it. Current seed is fine.)

## Device Verification

- [ ] **Push current build to Rokid AR glasses.**
- [ ] **Confirm index renders: title, "开始记录" button, "最近" list with 王磊 seed, "待跟进 1" row.**
- [ ] **Confirm capture flow: index → 开始记录 → input → 下一步 → confirm → 保存 → land on contact-card.**
- [ ] **Confirm follow-ups: index → 待跟进 1 → list shows "发送 Demo 资料" row; 完成 button toggles to 已完成 section.**
- [ ] **Confirm contact-card standalone (no `?id=`) falls back to 王磊 demo.**
- [ ] **Confirm onShow refresh: from contact-card use navigation back → index shows new contact added during this session.**
- [ ] Capture a photo/clip for the milestone record.

## Core Flow

- [x] Build home page with recent contacts and follow-up count.
- [x] Build text-based quick note input before voice integration.
- [x] Build "zero parsing" capture: full input → notes, all structured fields default to `"待补充"`. See `SPEC.md` §6.1.
- [x] Build inline-editable confirmation card (NOT a read-only preview).
- [x] Save confirmed contact to local store adapter.
- [x] Generate follow-up task from `nextAction` and `followUpAt` (handled inside `contactStore.saveContact`).
- [x] Display contact detail card. (Reads `?id=` from nav query, store-backed, demo fallback when opened standalone.)
- [x] Display follow-up task list.

## Voice And Device (next milestone)

- [ ] Read `aiui-dev` voice-related API references (`apis-wx.md` §wx.speech, `apis-ai.md` §SpeechRecognition).
- [ ] Identify supported AIUI voice or `wx.*` APIs on the actual Rokid device.
- [ ] Add voice command adapter (mic button in capture input mode → `wx.speech.startRecognition()`).
- [x] Keep text simulation fallback. (Already the default in capture mode='input'.)

## Persistence (next milestone)

- [ ] Swap `contactStore` Map backend for `wx.setStorage`/`wx.getStorage`. Interface MUST stay identical.
- [ ] Decide JSON envelope format and storage key namespacing (`meetmemo:contacts:v1`, `meetmemo:followups:v1`).
- [ ] Handle storage-not-supported fallback (per SKILL.md §6: `wx.media.*` returns undefined on missing capability — confirm storage parity).

## LLM Parser (Phase 2, after device verification)

- [ ] Wire `LanguageModel.availability()` check on capture page load.
- [ ] Replace `parser.parse()` body with LLM call returning the Contact schema.
- [ ] Apply schema validation; unknown fields STILL stay blank/'待补充'.
- [ ] Keep the editable confirmation card intact — LLM output is a suggestion.

## Quality

- [x] Keep UI width at 480px. (Enforced in all 4 pages.)
- [x] Keep main page height between 120px and 380px where possible. (scroll-view bounded in capture/index/followups.)
- [x] Use card-style layout.
- [x] Use AIUI theme tokens before hardcoded colors. (Zero hex literals in pages.)
- [x] Add comments for non-obvious parsing and storage behavior. (Banner comments in services and pages reference SPEC sections.)
- [ ] Avoid duplicated card rendering logic. (Recent-row vs followup-row vs contact-card use different shapes; extraction not warranted yet. Re-check if a 5th row type appears.)
