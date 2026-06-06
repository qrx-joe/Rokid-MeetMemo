# MeetMemo AIUI

MeetMemo is an offline conversation memory Agent for Rokid AR glasses. The user speaks (or types) a short note about someone they just met; the Agent turns it into a structured relationship card, generates a follow-up task, and lets them recall recent contacts later through a glanceable HUD.

The current build prioritizes a working local preview loop. The Ink runtime is loaded as WebAssembly in the browser; the project files are served to it over an HTTP VFS. This means **the full UI is renderable on Windows / Linux / macOS without a Rokid device** — the device is only required for final voice / camera / on-glass validation.

> **Status:** Reset in progress. The 4-page touch-and-tap UI built in earlier rounds was wrong for an AR-glasses input model (no touchscreen, no keyboard). The next milestone is a **single HUD page** driven by `onKeyDown(Enter/Backspace)` and voice, modeled on the [`rokid-lens-coach`](./reference/) reference. See `Docs/NEXT.md`.

## Demo Flow (target, post-pivot)

```text
Open MeetMemo
-> HUD shows "Ready" + brand
-> Press Enter
-> Voice capture starts (speechRecognition)
-> User says "Wang Lei, education SaaS founder, send demo Tuesday"
-> HUD shows a parsed card draft
-> Press Enter to confirm save / Backspace to discard
-> Stored locally via wx.setStorageSync
-> Follow-up task is created from the next action and date
```

## Project Structure

```text
.
├── AGENTS.md                # AIUI agent identity, permissions, skills
├── app.js                   # AIUI app lifecycle (thin)
├── app.json                 # Page routing + window config
├── dev-server.js            # Local browser preview (Express + ink + ink-vfs-server)
├── public/
│   └── index.html           # Browser shell: <canvas> + Ink WASM bootstrap
├── pages/
│   ├── index/index.ink              # (current) home — TO BE REWRITTEN as HUD
│   ├── capture/capture.ink          # (current) text capture — TO BE REPLACED with voice
│   ├── contact-card/contact-card.ink # (current) detail view
│   └── followups/followups.ink      # (current) pending list — may be merged into HUD
├── services/
│   ├── contact-store.js     # in-memory adapter (wx.storage swap planned)
│   └── parser.js            # zero-parsing stub (LLM replacement planned)
├── Docs/                    # SPEC / TODO / NEXT / LOG / Plan
├── .agents/                 # Installed aiui-dev skill docs (LLM context)
├── reference/               # Read-only: scraped docs + lens-coach reference project
├── .aixignore               # Excluded from .aix packaging
├── .gitignore
└── package.json
```

## Prerequisites

- Node.js 18+ (tested with 24)
- npm 9+ (tested with 11)
- A modern browser (Chrome / Edge / Firefox) with WebAssembly support

Tested on Windows 11. No platform-specific binaries required.

## Local Development

### Install dependencies

```bash
npm install
```

This installs three dev dependencies:

- `@yodaos-pkg/ink` — Ink Web SDK (the actual runtime, as WebAssembly)
- `@yodaos-pkg/ink-vfs-server` — HTTP VFS for serving the project files to Ink
- `express` — HTTP host for the VFS middleware and the preview HTML

No runtime dependencies; the deployed `.aix` bundle contains only `pages/`, `services/`, `app.json`, `app.js`, and `AGENTS.md`.

### Run the browser preview

```bash
npm start
```

Then open `http://127.0.0.1:8081/` in a browser. You should see a 480×400 HUD canvas rendering the first page registered in `app.json`.

What this exercise validates:

- Page layout at 480×400 (the Rokid HUD safe zone)
- AIUI runtime acceptance of every `.ink` four-section file
- WXML directives (`ink:if`, `ink:for`) and bindings
- WXSS theme tokens (whether `var(--card-padding)` etc. exist at runtime)
- `bindtap` / `onKeyDown` event delivery
- `setData` shape (dotted paths, full-object replacement)
- `scroll-view` behavior

What it does NOT validate:

- `wx.media.*` (camera, recorder) — only exists on the device
- `wx.speech.startRecognition` — host-dependent
- `LanguageModel` — host-dependent
- On-glass visual contrast in real lighting

### Run tests

```bash
npm test
```

Currently empty; tests for `services/` will land alongside the HUD rewrite.

### Browser preview internals

```
[Browser]                              [Node process]
 ┌─────────────────────────────┐        ┌────────────────────────────────┐
 │ public/index.html           │        │ dev-server.js (Express)        │
 │  ↳ <canvas>                 │        │   ↳ static  /         → public │
 │  ↳ import @yodaos-pkg/ink   │ ◄──── │   ↳ static  /ink      → SDK    │
 │    createInkView()          │  HTTP  │   ↳ middleware /ink-vfs → VFS  │
 │    view.openFromVfs(...)    │        │      rootDir = .ink-build/     │
 └─────────────────────────────┘        └────────────────────────────────┘
```

Before each start, `dev-server.js` stages only the runtime files (`app.json`, `app.js`, `AGENTS.md`, `pages/`, `services/`, `assets/`) into `.ink-build/` so the VFS exposes a clean app bundle — node_modules, `.git`, `Docs`, `reference` never leak into the runtime view.

## Packaging To `.aix` And Pushing To Glasses (TODO)

The Ink Web SDK is npm-installable on every platform. The `.aix` packaging tool that the `rokid-lens-coach` reference uses (`aix-macos-universal`) is currently macOS-only and not on npm. Options for Windows users:

1. **Borrow a Mac (recommended for now)**: Install the tool once on macOS and run
   ```bash
   /path/to/aix-macos-universal pack --optimize -o dist/meetmemo.aix .
   ```
   Then upload `dist/meetmemo.aix` to the Rokid Lingzhu (灵珠) developer portal.

2. **Wait for Craft web workspace**: `https://js.rokid.com/craft` is announced as a browser-based workspace that imports projects and previews / packages them. As of 2026-06-06 the public site shows "coming soon" for full packaging.

3. **Hand-pack a zip**: If the deployment surface eventually accepts a zip instead of a signed `.aix`, this becomes a one-liner. Not confirmed yet.

For day-to-day iteration on Windows, the local browser preview (`npm start`) covers everything except hardware-specific APIs.

## Upload To Rokid Glasses (when `.aix` exists)

Use the Rokid Lingzhu (灵珠) online workflow:

1. Open Lingzhu → `Project Development`.
2. Create an AIUI agent.
3. Fill in name, version, category, description, icon.
4. Upload `dist/meetmemo.aix` as the agent package.
5. On the glasses, go to `Settings → Developer → AIUI Debug → Update Resources`.
6. Launch the agent on the glasses.

## Design Rules

- Display: 480 × 400 (Rokid HUD safe zone)
- Background: black `#000000`
- Accent: `#40FF5E` (currently — theme tokens deferred until verified on Ink)
- Border: 1.5–2 px on cards
- Radius: 12 px
- Type scale: 32/40 (title), 24/32 (primary), 20/26 (label), 18/24 (body), 16/22 (hint)
- No emoji in HUD copy
- No large solid color blocks
- Prefer one card per screen
- Drive interaction from `onKeyDown` (Enter / Backspace) and voice — **not** tap or text input

See `Docs/SPEC.md` for the full specification.

## Documentation

- `Docs/SPEC.md` — Source of truth for technical and product rules
- `Docs/TODO.md` — Executable task list
- `Docs/NEXT.md` — Immediate next 1–3 tasks
- `Docs/LOG.md` — Key decisions and AI/user collaboration notes
- `Docs/MeetMemo-AIUI-Development-Plan.md` — Original product plan (annotated with amendments)
- `Docs/AIUI-Cheatsheet.md` — Distilled aiui-dev skill cheatsheet (reference)

## Useful Links

- AIUI official: <https://github.com/jsar-project/AIUI>
- AIUI scaffolding CLI: `npx @yodaos-pkg/create-aiui-agent my-agent`
- Craft (web workspace): <https://js.rokid.com/craft>
- Ink Playground: <https://jsar-project.github.io/ink/playground.html>

## Troubleshooting

**`npm start` exits immediately** — port 8081 is already taken. On Windows:
```bash
netstat -ano | findstr :8081
taskkill /F /PID <pid>
```
Or set a different port: `PORT=8082 npm start`.

**Browser shows blank canvas** — open devtools console. The `#log` element on the page also surfaces the load error.

**`openFromVfs` 404** — verify `http://127.0.0.1:8081/ink-vfs/apps/meetmemo/manifest` lists the expected files. If `.git/` or `node_modules/` leak in, the staging step (`stageBundle`) did not run; delete `.ink-build/` and restart.

**WASM fails to instantiate** — confirm `http://127.0.0.1:8081/ink/pkg/ink_web_bg.wasm` returns 200 with `Content-Type: application/wasm`.
