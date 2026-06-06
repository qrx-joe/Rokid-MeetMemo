# TODO

## Product

- [ ] Confirm MVP name: MeetMemo AIUI.
- [ ] Confirm first target user: founder or BD person attending offline AI events.
- [ ] Define 3 demo scenarios.
- [ ] Define privacy copy for active recording and manual confirmation.

## AIUI App Skeleton

- [ ] Create `app.json`.
- [ ] Create `app.js`.
- [ ] Create `pages/index/index.ink`.
- [ ] Create `pages/capture/capture.ink`.
- [ ] Create `pages/contact-card/contact-card.ink`.
- [ ] Create `pages/followups/followups.ink`.
- [ ] Create `services/parser.js`.
- [ ] Create `services/contact-store.js`.
- [ ] Create `services/demo-data.js`.

## Core Flow

- [ ] Build home page with recent contacts and follow-up count.
- [ ] Build text-based quick note input before voice integration.
- [ ] Build mock parser for structured contact extraction.
- [ ] Build confirmation card before saving.
- [ ] Save confirmed contact to local store adapter.
- [ ] Generate follow-up task from `nextAction` and `followUpAt`.
- [ ] Display contact detail card.
- [ ] Display follow-up task list.

## Voice And Device

- [ ] Read `aiui-dev` voice-related API references before implementation.
- [ ] Identify supported AIUI voice or `wx.*` APIs.
- [ ] Add voice command adapter.
- [ ] Keep text simulation fallback.

## Quality

- [ ] Keep UI width at 480px.
- [ ] Keep main page height between 120px and 380px where possible.
- [ ] Use card-style layout.
- [ ] Use AIUI theme tokens before hardcoded colors.
- [ ] Add comments for non-obvious parsing and storage behavior.
- [ ] Avoid duplicated card rendering logic.

