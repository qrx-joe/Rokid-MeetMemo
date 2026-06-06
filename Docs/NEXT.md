# NEXT

## Current Focus

**Stop writing new code. Verify on device.**

Four pages and two services are in tree, all using the same minimal set of runtime assumptions. If those assumptions hold, the MVP UI loop is complete; if any one of them fails, the fix lands in roughly the same place across every page. Either way, the verification answer is short.

## Why this focus

Three rounds of code without device verification is the carry. Continuing to stack more code (persistence, voice, LLM) before testing what is already written multiplies the rollback cost. The leverage is now on the device, not in the editor.

## Verification Plan (single device session)

Run through `TODO.md` → Device Verification top to bottom. If any step fails, paste the InkView/devtools error and the failing page name; the fix lives in one of these known places:

| Symptom | Suspected assumption | Fix location |
| --- | --- | --- |
| `currentTarget.dataset` undefined | Ink doesn't forward dataset | All pages — expand dataset reads into per-element handlers |
| `setData` ignores dotted path | Ink doesn't honor `'a.b': v` form | `capture.handleField`, `index._refresh`, `followups._refresh` — rewrite as full object replacements |
| `wx.navigateTo` rejects leading `/` | Ink uses relative paths only | Drop the `/` in all `navigateTo` calls (3 sites) |
| `async onLoad`/`onShow` not awaited | Ink calls but ignores Promise | Convert to `.then()` chains — visible behavior identical |
| `scroll-view max-height` ignored | Ink wants fixed `height` | Change `max-height: Npx` → `height: Npx` in capture/index/followups |
| `var(--card-padding)` etc unknown | Token name differs in current Ink | Cross-check `.agents/skills/aiui-dev/SKILL.md` §5.4 — swap to nearest supported token |
| `catchtap` does not stop propagation on `<button>` inside `<view bindtap>` | Ink button event model differs | Switch row body to `<view>` instead of `<view bindtap>`; move tap target to an inner `<text>` |
| `onShow` never fires after navigateBack | Lifecycle gap | Add an explicit refresh trigger (custom event) or accept stale list until manual reload |

## Next 3 Tasks (after verification passes)

1. **Persistence: swap `contactStore` to `wx.storage`.**
   - Use keys `meetmemo:contacts:v1` and `meetmemo:followups:v1`.
   - Read-on-init, write-on-mutate. No in-memory cache invalidation logic in MVP — the store is the only writer.
   - Keep the in-memory seeded demo as fallback ONLY when storage is empty (first launch).
   - **The public adapter API must not change.** If a single page change is needed, the swap is wrong.

2. **Voice input in capture (input mode).**
   - Read `.agents/skills/aiui-dev/apis-wx.md` for `wx.speech.startRecognition` first.
   - Add a mic button next to the textarea; press to start, press again to stop; transcript appended to the textarea value.
   - Visible recording state (per `SPEC.md` §8). No auto-listen.
   - Text input remains the primary path.

3. **LLM parser (Phase 2).**
   - Replace `parser.parse()` body with `LanguageModel.create() + session.prompt()` per SKILL.md §10.1.
   - Output must conform to the Contact schema. Validation rejects unknown shapes.
   - Confirmation card stays editable — LLM output is suggestion, not save.

## Do Not Do Yet

- Do not begin any of the Next 3 Tasks until at least the capture → save → contact-card round trip is verified on device.
- Do not add `priority` to the data model.
- Do not write any regex-based parser (`SPEC.md` §6.2).
- Do not over-engineer the storage swap — `wx.setStorage`/`wx.getStorage` is enough; no encryption, no migration tooling in MVP.
- Do not enable always-on recording or background listening.

## Definition Of Done For The Current Focus

A short clip taken on the Rokid AR glasses showing:
1. App opens to `index` with 王磊 seed visible and "待跟进 1" badge.
2. Tap "开始记录" → type a note → 下一步 → fill in name → 保存.
3. App lands on `contact-card` showing the just-saved person.
4. Navigate back to `index` → the new person appears at top of the recent list.
5. Tap "待跟进" → followups list shows both 王磊's and the new person's pending follow-up (if a date was entered).
6. Tap 完成 on one → moves to 已完成 section.

If any step fails, the page where it fails plus the error message is enough to unblock the fix.
