# TODO

> Updated 2026-06-06 (evening). See `LOG.md` for what changed and why.

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

- [x] Create `app.json` (capture as homepage, contact-card registered).
- [x] Create `app.js`.
- [ ] Create `pages/index/index.ink`. (Task #3 next round.)
- [x] Create `pages/capture/capture.ink`.
- [x] Create `pages/contact-card/contact-card.ink`.
- [ ] Create `pages/followups/followups.ink`. (Task #3 next round.)
- [x] Create `services/parser.js` (zero-parsing stub per SPEC.md §6.1).
- [x] Create `services/contact-store.js` (in-memory adapter, async API stable for wx.storage swap).
- [ ] Create `services/demo-data.js`. (Deferred — seeded demo currently lives inside contact-store; extract when 3+ surfaces share it.)

## Device Verification

- [ ] **Push current build to Rokid AR glasses.**
- [ ] **Confirm contact-card.ink renders the 王磊 card** (standalone open, no nav params).
- [ ] **Confirm capture.ink flow: type → 下一步 → edit → 保存 → land on contact-card with the just-saved person.**
- [ ] Capture a photo/clip for the milestone record.

## Core Flow

- [ ] Build home page with recent contacts and follow-up count.
- [x] Build text-based quick note input before voice integration.
- [x] Build "zero parsing" capture: full input → notes, all structured fields default to `"待补充"`. See `SPEC.md` §6.1.
- [x] Build inline-editable confirmation card (NOT a read-only preview).
- [x] Save confirmed contact to local store adapter.
- [x] Generate follow-up task from `nextAction` and `followUpAt` (handled inside `contactStore.saveContact`).
- [x] Display contact detail card. (Reads `?id=` from nav query, store-backed, demo fallback when opened standalone.)
- [ ] Display follow-up task list.

## Voice And Device

- [ ] Read `aiui-dev` voice-related API references before implementation.
- [ ] Identify supported AIUI voice or `wx.*` APIs on the actual Rokid device.
- [ ] Add voice command adapter.
- [ ] Keep text simulation fallback. (Already the default in capture mode='input'.)

## Persistence (next milestone)

- [ ] Swap `contactStore` Map backend for `wx.setStorage`/`wx.getStorage`. Interface MUST stay identical.
- [ ] Decide JSON envelope format and storage key namespacing.
- [ ] Handle storage-not-supported fallback (per SKILL.md §6: `wx.media.*` returns undefined on missing capability — confirm storage parity).

## Quality

- [x] Keep UI width at 480px. (Enforced in `pages/contact-card/contact-card.ink` and `pages/capture/capture.ink`.)
- [x] Keep main page height between 120px and 380px where possible. (Capture confirm mode wrapped in `scroll-view` with `max-height: 360px`.)
- [x] Use card-style layout.
- [x] Use AIUI theme tokens before hardcoded colors. (No hex literals in pages.)
- [x] Add comments for non-obvious parsing and storage behavior. (Banner comments in services and pages reference SPEC sections.)
- [ ] Avoid duplicated card rendering logic. (Capture edit form vs contact-card display are different shapes — no extraction needed yet. Re-check when home/followups land.)
