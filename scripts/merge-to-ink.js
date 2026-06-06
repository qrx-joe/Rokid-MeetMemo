/**
 * merge-to-ink.js — Merge split files (.json + .js + .wxml + .wxss) back into .ink SFC
 *
 * Run: node scripts/merge-to-ink.js
 */

import fs from 'node:fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.join(__dirname, '..');
const PAGES_DIR = path.join(ROOT, 'pages');

function mergePage(pageDir) {
  const pageName = path.basename(pageDir);
  const jsonPath = path.join(pageDir, `${pageName}.json`);
  const jsPath = path.join(pageDir, `${pageName}.js`);
  const wxmlPath = path.join(pageDir, `${pageName}.wxml`);
  const wxssPath = path.join(pageDir, `${pageName}.wxss`);
  const inkPath = path.join(pageDir, `${pageName}.ink`);

  if (!fs.existsSync(jsonPath) || !fs.existsSync(jsPath)) {
    console.warn(`Skip ${pageName}: missing json or js`);
    return;
  }

  const jsonContent = fs.readFileSync(jsonPath, 'utf-8').trim();
  const jsContent = fs.readFileSync(jsPath, 'utf-8').trim();
  let wxmlContent = '';
  let wxssContent = '';

  if (fs.existsSync(wxmlPath)) {
    wxmlContent = fs.readFileSync(wxmlPath, 'utf-8').trim();
  }
  if (fs.existsSync(wxssPath)) {
    wxssContent = fs.readFileSync(wxssPath, 'utf-8').trim();
  }

  // Convert wx: directives back to ink: for AIUI native support
  // (AIUI supports both, but ink: is the native prefix)
  if (wxmlContent) {
    wxmlContent = wxmlContent.replace(/wx:/g, 'ink:');
  }

  const parts = [];
  parts.push(`<script def>`);
  parts.push(jsonContent);
  parts.push(`</script>`);
  parts.push('');
  parts.push(`<script setup>`);
  parts.push(jsContent);
  parts.push(`</script>`);
  parts.push('');
  if (wxmlContent) {
    parts.push(`<page>`);
    parts.push(wxmlContent);
    parts.push(`</page>`);
    parts.push('');
  }
  if (wxssContent) {
    parts.push(`<style>`);
    parts.push(wxssContent);
    parts.push(`</style>`);
  }

  fs.writeFileSync(inkPath, parts.join('\n') + '\n', 'utf-8');
  console.log(`  → pages/${pageName}/${pageName}.ink`);
}

function main() {
  const entries = fs.readdirSync(PAGES_DIR, { withFileTypes: true });
  const pageDirs = entries
    .filter(e => e.isDirectory())
    .map(e => path.join(PAGES_DIR, e.name));

  for (const pageDir of pageDirs) {
    const pageName = path.basename(pageDir);
    console.log(`Merging: ${pageName}`);
    mergePage(pageDir);
  }

  console.log('\nDone.');
}

main();
