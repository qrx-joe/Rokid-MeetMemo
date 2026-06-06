// dev-server.js — MeetMemo local browser preview.
//
// What this does:
// - stages only runtime files (app.json, app.js, AGENTS.md, pages/, services/,
//   assets/) into .ink-build/ so the VFS exposes a clean app bundle (no
//   node_modules, no .git, no Docs leaking into the runtime view)
// - serves node_modules/@yodaos-pkg/ink at /ink so the browser can import the
//   ESM SDK and load the WASM runtime directly
// - mounts ink-vfs-server's Express middleware at /ink-vfs, exposing the
//   staged app bundle as the AIUI app the runtime will fetch
// - serves public/ as static (index.html, anything else we add later)
//
// Open http://localhost:8081 in a browser to see the MeetMemo .ink pages
// rendered by the real Ink WASM runtime. This is the best signal we can get
// without pushing to actual Rokid glasses.
//
// Caveats:
// - Some Ink runtime capabilities (e.g. wx.media camera, on-device TTS) only
//   work on real hardware. Browser preview is for visual + structural
//   validation, not full functional parity.

import express from 'express';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { cp, mkdir, rm, stat } from 'node:fs/promises';
import { createExpressMiddleware } from '@yodaos-pkg/ink-vfs-server';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PORT = Number(process.env.PORT) || 8081;
const HOST = process.env.HOST || '127.0.0.1';
const APP_ID = 'meetmemo';
const BUILD_DIR = path.join(__dirname, '.ink-build');

// Whitelist of runtime files/dirs the AIUI app actually needs. Everything else
// (node_modules, .git, Docs, reference, test, .agents, public, dev-server.js)
// stays out of the VFS bundle.
const RUNTIME_ENTRIES = [
  'app.json',
  'app.js',
  'AGENTS.md',
  'pages',
  'services',
  'assets',
];

async function exists(p) {
  try {
    await stat(p);
    return true;
  } catch {
    return false;
  }
}

async function stageBundle() {
  await rm(BUILD_DIR, { recursive: true, force: true });
  await mkdir(BUILD_DIR, { recursive: true });
  for (const entry of RUNTIME_ENTRIES) {
    const src = path.join(__dirname, entry);
    if (!(await exists(src))) {
      // Some entries (assets/) may not exist yet; skip silently.
      continue;
    }
    const dst = path.join(BUILD_DIR, entry);
    await cp(src, dst, { recursive: true });
  }
  console.log(`[MeetMemo] staged runtime bundle to .ink-build/`);
}

await stageBundle();

const app = express();

// 1. Static-serve our own preview shell (public/index.html) FIRST.
//    express.static falls through on miss, so /ink and /ink-vfs requests are
//    unaffected. This makes GET / return the canvas shell, not 405 from VFS.
app.use(express.static(path.join(__dirname, 'public')));

// 2. Static-serve the Ink Web SDK so the browser can `import` it as ESM.
//    Path inside node_modules contains ink_web_bg.wasm that the SDK fetches
//    relative to its own JS, so this single static mount handles both.
app.use(
  '/ink',
  express.static(path.join(__dirname, 'node_modules/@yodaos-pkg/ink'), {
    fallthrough: false,
    setHeaders: (res, filePath) => {
      if (filePath.endsWith('.wasm')) {
        res.setHeader('Content-Type', 'application/wasm');
      }
    },
  })
);

// 3. Mount the VFS middleware. Default basePath is /ink-vfs; routes become
//    GET /ink-vfs/apps/:appId/manifest and /ink-vfs/apps/:appId/files/:path.
//    rootDir points at the staged bundle so the runtime sees a clean app.
app.use(
  createExpressMiddleware({
    appId: APP_ID,
    rootDir: BUILD_DIR,
    basePath: '/ink-vfs',
    allowOrigin: '*',
  })
);

app.listen(PORT, HOST, () => {
  console.log(`[MeetMemo] dev server running`);
  console.log(`  Preview:  http://${HOST}:${PORT}`);
  console.log(`  Manifest: http://${HOST}:${PORT}/ink-vfs/apps/${APP_ID}/manifest`);
  console.log(`  Stop with Ctrl+C`);
});
