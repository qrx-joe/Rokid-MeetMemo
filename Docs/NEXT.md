# NEXT

## Current Focus

**Open `http://127.0.0.1:8081` in a browser.** The local preview now renders the project through the real Ink WASM runtime. The next concrete decisions depend on what you actually see.

```bash
npm start
# then open http://127.0.0.1:8081
```

Take one of three actions based on what the page shows:

1. **Pages render (even ugly)** — proceed to the HUD rewrite (Task #1 below). What's on screen now uses the wrong interaction model anyway; we are about to throw it out. The preview just confirmed the toolchain works.
2. **Blank canvas + console error** — paste the `#log` element contents back. Most likely fixes are listed in the symptom table below.
3. **Server fails to start** — port collision; either `taskkill /F /PID <pid>` on the 8081 holder or `PORT=8082 npm start`.

## Next 3 Tasks (after toolchain validation)

1. **HUD rewrite — `pages/index/index.ink` as a single Lens-Coach-style HUD.**

   Hard delete `pages/capture/`, `pages/contact-card/`, `pages/followups/`. Hard delete `services/` and replace with `lib/coach.js` style. The new HUD state machine:

   ```
   READY  → press Enter → LISTENING (voice capture) → THINKING (parse) → CONFIRMING (show card, Enter saves, Backspace discards) → SAVED → READY
   ```

   - Driven by `onKeyDown(Enter | Backspace)` only.
   - `speechSynthesis` for spoken prompts at each state transition.
   - `SpeechRecognition` for the LISTENING capture (with text-input fallback only when running in the browser preview).
   - 480 × 400 layout, hex literals (no `var(--token)`), precomputed boolean fields for `ink:if`.
   - Persist via `wx.setStorageSync('meetmemo:last-session', snapshot)` directly inside `lib/coach.js`.

2. **`lib/coach.js` — deterministic state + mock parser.**

   Mirror `reference/rokid-lens-coach/lib/coach.js`:

   ```js
   export function createInitialState() { ... }    // READY
   export async function captureNote(raw) { ... }  // raw transcript → ContactDraft (mock for now)
   export function confirmDraft(state) { ... }     // CONFIRMING → SAVED
   export function nextPrompt(state) { ... }       // walk through missing fields one at a time
   export function toStorageSnapshot(state) { ... }
   ```

   With Node test runner coverage in `test/coach.test.js`.

3. **Borrow a Mac and pack the first `.aix`.**

   Even before voice + LLM land, packaging the current HUD into `.aix` and uploading to Lingzhu validates the deployment surface. One Mac session, three commands:

   ```bash
   /path/to/aix-macos-universal pack --optimize -o dist/meetmemo.aix .
   /path/to/aix-macos-universal list dist/meetmemo.aix
   # then upload via Lingzhu Project Development
   ```

## Symptom → Fix Lookup (browser preview)

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `openFromVfs` fails 404 on `manifest` | VFS basePath mismatch | Confirm `curl http://127.0.0.1:8081/ink-vfs/apps/meetmemo/manifest` is 200; if not, `.ink-build/` empty → check `stageBundle()` |
| WASM fails to instantiate | Wrong `Content-Type` | `curl -I http://127.0.0.1:8081/ink/pkg/ink_web_bg.wasm` should return `application/wasm` |
| Canvas blank, no error | Page render path missing | Open devtools, check whether the page's `<script setup>` evaluated; common cause is a syntax error in `.ink` swallowed by the runtime |
| Style looks broken (no border / wrong color) | `var(--token)` not recognized | Replace tokens with hex literals in the failing file (see `SPEC.md` §5.7) |
| `ink:if` not gating content | Compound expression unsupported | Precompute boolean in `<script setup>` and bind the flag (see `SPEC.md` §5.8) |
| `currentTarget.dataset` undefined | Dataset not forwarded by Ink | Convert dataset-dispatched handlers to per-element handlers |
| `setData` dotted path no-op | Path syntax unsupported | Rewrite as `this.setData({ draft: { ...this.data.draft, [field]: value } })` |

## Do Not Do Yet

- Do not patch the four legacy pages — they are scheduled for deletion in the HUD rewrite.
- Do not add `priority`, regex parsing, or `services/demo-data.js`.
- Do not chase `.aix` packaging on Windows; arrange Mac access when needed.
- Do not enable always-on recording or background listening.

## Definition Of Done For The Current Focus

A screenshot of `http://127.0.0.1:8081` showing either:

- The current MeetMemo `index` page rendered on the 480 × 400 canvas (even if styled wrong), confirming the toolchain works end-to-end. Then HUD rewrite begins.
- A clearly readable error in the `#log` element. Then we fix that error first.

Either way: **one browser session, one screenshot, decision unblocked**.
