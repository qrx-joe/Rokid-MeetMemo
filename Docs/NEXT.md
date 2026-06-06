# NEXT

## Current Focus

Wire the navigation backbone: `pages/index/index.ink` as the home page, and `pages/followups/followups.ink` for pending follow-ups. Then voice integration as a separate milestone.

## Why this focus

Capture → contact-card flow now exists end-to-end (text → store → display). The next leverage point is **return visits**: a user who saved someone two days ago needs a way to find them and check their pending follow-ups. That requires `index` (recent contacts + follow-up count) and `followups` (list view). Without these two, the app forgets everything after the first save from a user's point of view.

## Next 3 Tasks (in strict order)

1. **`pages/index/index.ink` — home page.**
   - Sections: "Recent" (latest 3–5 contacts from `contactStore.listContacts()`) + "Follow-ups" badge (count from `contactStore.listFollowups()`).
   - Primary CTA: "Start quick note" → `wx.navigateTo` to capture.
   - Tap on a recent contact → navigate to contact-card with `?id=`.
   - Empty state: short copy + only the "Start quick note" button.
   - Make this the new homepage in `app.json`; capture becomes a sub-route (navigated to from index).

2. **`pages/followups/followups.ink` — pending follow-ups list.**
   - Sections per `SPEC.md` §10.4: Pending + Completed (MVP scope).
   - Each row: title, due date, source contact name (resolved via `contactStore.getContact(contactId)`).
   - Tap row to open the source contact card; long-press / dedicated button to mark done.
   - Empty state: short copy, link back to index.

3. **`services/demo-data.js` extraction (only if needed).**
   - If the home page wants more than the one seeded contact to look populated, move the demo seed out of `contactStore` into `services/demo-data.js` and have `contactStore` load it conditionally.
   - **Skip this task entirely** if one demo contact is enough to validate the UI on device.

## Do Not Do Yet

- Do not integrate always-on recording.
- Do not use camera or face recognition.
- Do not build CRM-level relationship graphs.
- Do not write any regex-based parser (see `SPEC.md` §6.2).
- Do not add `priority` to the data model.
- Do not swap `contactStore` to `wx.storage` until the navigation backbone is verified on device — keeping it in-memory makes iteration faster and an iteration crash won't corrupt state.
- Do not add LLM parsing until index + followups feel right on device.

## Definition Of Done For The Current Focus

User can:
1. Open the app and land on `pages/index/index.ink`.
2. See recent contacts and a pending follow-up count.
3. Tap "Start quick note" → capture → save → bounce back to index with the new contact visible.
4. Tap a recent contact → see the relationship card.
5. Tap the follow-up count → see the pending list.

Verified on the Rokid AR glasses with a screenshot or short clip.

## Pending Device Verification (carried over)

Before starting the next 3 tasks above, please run the verification listed in `TODO.md` → Device Verification. If the current capture → contact-card flow has rendering or runtime issues on device, fixing them is higher priority than building more pages.
