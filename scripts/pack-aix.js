import fs from 'fs';
import path from 'path';
import { ZipArchive } from 'archiver';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.join(__dirname, '..');

const output = fs.createWriteStream(path.join(ROOT, 'dist/meetmemo.aix'));
const archive = new ZipArchive({ zlib: { level: 9 } });

archive.on('error', err => { throw err; });
archive.pipe(output);

const baseDir = path.join(ROOT, 'dist/_verify_aix');
function addFiles(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    const relPath = path.relative(baseDir, fullPath).replace(/\\/g, '/');
    if (entry.isDirectory()) {
      addFiles(fullPath);
    } else {
      archive.file(fullPath, { name: relPath });
    }
  }
}

addFiles(baseDir);
archive.finalize();
output.on('close', () => {
  console.log('Created meetmemo.aix, size:', archive.pointer());
});
