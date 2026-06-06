# TODO

> Updated 2026-06-06 (afternoon). See `LOG.md` for what changed and why.

## Product

- [x] Confirm MVP name: MeetMemo AIUI.
- [x] Confirm first target user: founder or BD person attending offline AI events.
- [ ] Define 3 demo scenarios.
- [x] Define privacy copy for active recording and manual confirmation. (See `AGENTS.md` Privacy Posture and `SPEC.md` §8.)

## Project Hygiene (new)

- [x] Move scraped Rokid docs into `reference/` and isolate from project code.
- [x] Add `.gitignore` (untrack vendor bundles, IDE files, .venv).
- [x] `git init` on `main`, initial commit recorded.
- [x] Fix misplaced root `AGENTS.md` (was AIUI cheatsheet, moved to `Docs/AIUI-Cheatsheet.md`).
- [x] Rewrite root `AGENTS.md` as a real AIUI manifest (Identity / Capabilities / Privacy).

## AIUI App Skeleton

- [x] Create `app.json`.
- [x] Create `app.js`.
- [ ] Create `pages/index/index.ink`.
- [ ] Create `pages/capture/capture.ink`.
- [x] Create `pages/contact-card/contact-card.ink`.
- [ ] Create `pages/followups/followups.ink`.
- [ ] Create `services/parser.js`. (Deferred until capture flow lands. See `SPEC.md` §6.1.)
- [ ] Create `services/contact-store.js`. (Deferred until capture flow lands.)
- [ ] Create `services/demo-data.js`. (Deferred until 2+ pages share the mock.)

## Device Verification (new)

- [ ] **Push current skeleton to Rokid AR glasses.**
- [ ] **Confirm contact-card.ink renders the 王磊 card.**
- [ ] Capture a photo/clip for the milestone record.

## Core Flow

- [ ] Build home page with recent contacts and follow-up count.
- [ ] Build text-based quick note input before voice integration.
- [ ] Build "zero parsing" capture: full input → notes, all structured fields default to `"待补充"`. See `SPEC.md` §6.1.
- [ ] Build inline-editable confirmation card (NOT a read-only preview).
- [ ] Save confirmed contact to local store adapter.
- [ ] Generate follow-up task from `nextAction` and `followUpAt`.
- [x] Display contact detail card (hard-coded for now; will accept navigation params later).
- [ ] Display follow-up task list.

## Voice And Device

- [ ] Read `aiui-dev` voice-related API references before implementation.
- [ ] Identify supported AIUI voice or `wx.*` APIs on the actual Rokid device.
- [ ] Add voice command adapter.
- [ ] Keep text simulation fallback.

## Quality

- [x] Keep UI width at 480px. (Enforced in `pages/contact-card/contact-card.ink`.)
- [x] Keep main page height between 120px and 380px where possible. (Card layout sized for it.)
- [x] Use card-style layout.
- [x] Use AIUI theme tokens before hardcoded colors. (No hex literals in contact-card.ink.)
- [x] Add comments for non-obvious parsing and storage behavior. (Banner comments in `.ink` files reference SPEC sections.)
- [ ] Avoid duplicated card rendering logic. (Re-check when index/capture/followups land — extract a shared card component if duplication appears.)
