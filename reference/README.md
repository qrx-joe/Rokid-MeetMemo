# reference/

This folder holds **read-only vendor artifacts**, not project code.

## What is in here

- `rokid_aiui_bundle.js` (~6.8 MB) — Vue3 + Vite SSR bundle scraped from Rokid's developer docs site (`JS for Rokid Developers`). NOT a runtime.
- `rokid_aiui_*.html` — Pre-rendered documentation pages from the same site.
- `rokid_arplatform_*.{js,html}` — Same source, AR Platform docs section.

## Why these exist

Captured 2026-06-06 so the AIUI documentation could be browsed offline while the official Ink GitHub repo and Craft workspace are still in "coming soon" status.

## Do not

- Do not import code from these files.
- Do not edit them.
- Do not assume they represent the current Rokid API — when in doubt, check `.agents/skills/aiui-dev/` (which is the source of truth) or the live docs at https://jsar-project.github.io/ink/

## When to delete

Delete this folder once Ink is open-sourced on GitHub and Craft ships, or when the captured docs are stale enough to mislead.
