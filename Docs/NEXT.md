# NEXT

## Current Focus

Get a **single hard-coded contact card rendering on the Rokid AR glasses**. Eyes-on validation before any parser or storage code.

## Why this focus

The original Day 1–7 milestone wrote files in isolation for a week before seeing anything render. That hides every layout, theme-token, and InkView quirk until late. Instead: shortest possible path to "I see a card on the device", then iterate.

## Next 3 Tasks (in strict order)

1. **Minimal viable shell that renders on device.**
   - Create `app.json`, `app.js`, `pages/contact-card/contact-card.ink`.
   - The `.ink` page renders ONE hard-coded contact object (王磊 example) — no input, no storage, no navigation, no parser.
   - Follow `SPEC.md` §5 (480px width, black background, card style, theme tokens) and `.agents/skills/aiui-dev/SKILL.md` §6.
   - Push to Rokid glasses. Confirm the card is readable and within the 120–380px height envelope.
   - Definition of done: a photo or screenshot of the card on the device.

2. **Capture page with inline-editable confirmation card.**
   - Create `pages/capture/capture.ink` and `services/parser.js`.
   - The parser is a stub: input string goes verbatim into `notes`, all structured fields are `"待补充"`. NO regex, NO date extraction. See `SPEC.md` §6.1.
   - The confirmation card is the inline editor — every field is a `<textarea>` or `<input>` the user can fill before saving.
   - Save into an in-memory array in `services/contact-store.js` (real persistence comes after).

3. **Home page + follow-up generation.**
   - Create `pages/index/index.ink` (recent contacts + follow-up count) and `pages/followups/followups.ink`.
   - When a confirmed contact has both `nextAction` and `followUpAt`, generate one follow-up. See `SPEC.md` §7.
   - Wire navigation between home → capture → contact-card → followups.

After these three: storage adapter (real `wx.storage`), voice integration, then LLM parser.

## Do Not Do Yet

- Do not integrate always-on recording.
- Do not use camera or face recognition.
- Do not build CRM-level relationship graphs.
- Do not write any regex-based parser (see `SPEC.md` §6.2).
- Do not add `priority` to the data model.
- Do not invest in a browser HTML mock — device is available.
- Do not commit yet; the user will decide when to commit after reviewing all amendments.

## Definition Of Done For The Current Focus

A still photo or short clip taken of the Rokid glasses showing the 王磊 contact card rendered from `pages/contact-card/contact-card.ink`, hardcoded data, fixed at 480px width, black background, AIUI theme tokens applied, on the actual device.

## Reminder

If any of the above starts to feel like "I should plan more first", that is the failure mode. The plan is already too long. Build the smallest visible thing on the device, then react to what you see.
