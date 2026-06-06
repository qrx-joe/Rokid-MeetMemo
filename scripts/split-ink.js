/**
 * split-ink.js — Split .ink SFC files into traditional multi-file format
 *
 * .ink → .json (page config) + .js (logic) + .wxml (template) + .wxss (style)
 *
 * Run: node scripts/split-ink.js
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.join(__dirname, '..');
const PAGES_DIR = path.join(ROOT, 'pages');

function splitInkFile(inkPath) {
  const content = fs.readFileSync(inkPath, 'utf-8');
  const dir = path.dirname(inkPath);
  const base = path.basename(inkPath, '.ink');

  // Extract <script def> content
  const defMatch = content.match(/<script\s+def\s*>([\s\S]*?)<\/script\s*>/i);
  if (defMatch) {
    const jsonPath = path.join(dir, `${base}.json`);
    fs.writeFileSync(jsonPath, defMatch[1].trim() + '\n', 'utf-8');
    console.log(`  → ${path.relative(ROOT, jsonPath)}`);
  }

  // Extract <script setup> content
  const setupMatch = content.match(/<script\s+setup\s*>([\s\S]*?)<\/script\s*>/i);
  if (setupMatch) {
    const jsPath = path.join(dir, `${base}.js`);
    fs.writeFileSync(jsPath, setupMatch[1].trim() + '\n', 'utf-8');
    console.log(`  → ${path.relative(ROOT, jsPath)}`);
  }

  // Extract <page> content
  const pageMatch = content.match(/<page\s*>([\s\S]*?)<\/page\s*>/i);
  if (pageMatch) {
    const wxmlPath = path.join(dir, `${base}.wxml`);
    fs.writeFileSync(wxmlPath, pageMatch[1].trim() + '\n', 'utf-8');
    console.log(`  → ${path.relative(ROOT, wxmlPath)}`);
  }

  // Extract <style> content
  const styleMatch = content.match(/<style\s*>([\s\S]*?)<\/style\s*>/i);
  if (styleMatch) {
    const wxssPath = path.join(dir, `${base}.wxss`);
    fs.writeFileSync(wxssPath, styleMatch[1].trim() + '\n', 'utf-8');
    console.log(`  → ${path.relative(ROOT, wxssPath)}`);
  }
}

function main() {
  const entries = fs.readdirSync(PAGES_DIR, { withFileTypes: true });
  const pageDirs = entries.filter(e => e.isDirectory()).map(e => e.name);

  for (const pageDir of pageDirs) {
    const inkPath = path.join(PAGES_DIR, pageDir, `${pageDir}.ink`);
    if (!fs.existsSync(inkPath)) {
      console.warn(`Skip: ${inkPath} not found`);
      continue;
    }
    console.log(`Splitting: pages/${pageDir}/${pageDir}.ink`);
    splitInkFile(inkPath);
  }

  console.log('\nDone.');
}

main();
