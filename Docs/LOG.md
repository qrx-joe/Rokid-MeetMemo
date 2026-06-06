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


