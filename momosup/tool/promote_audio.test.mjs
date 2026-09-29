import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { copyFileSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

const script = fileURLToPath(new URL('./promote_audio.mjs', import.meta.url));

test('copies only reviewed audio with matching bytes and does not approve content', () => {
  const root = mkdtempSync(path.join(tmpdir(), 'momosup-audio-'));
  try {
    for (const folder of ['tool', 'production/audio_pending', 'assets/content']) {
      mkdirSync(path.join(root, folder), { recursive: true });
    }
    copyFileSync(script, path.join(root, 'tool/promote_audio.mjs'));

    const audioFiles = {};
    const jobs = [];
    for (const [lineId, status, recordedHash] of [
      ['intro', 'APPROVED', true],
      ['prompt', 'GENERATED_NEEDS_REVIEW', true],
      ['outro', 'APPROVED', false],
    ]) {
      const filename = `sample__${lineId}.wav`;
      const bytes = Buffer.from(`audio-${lineId}`);
      writeFileSync(path.join(root, 'production/audio_pending', filename), bytes);
      audioFiles[lineId] = `assets/audio/${filename}`;
      jobs.push({
        activityId: 'sample', lineId, status,
        humanReviewedAt: status === 'APPROVED' ? '2026-09-29' : null,
        commercialRightsEvidence: status === 'APPROVED' ? 'owner confirmation' : null,
        sha256: recordedHash ? createHash('sha256').update(bytes).digest('hex') : 'wrong',
        suggestedFile: audioFiles[lineId],
      });
    }
    const catalogPath = path.join(root, 'assets/content/catalog.json');
    const manifestPath = path.join(root, 'assets/content/audio_manifest.json');
    writeFileSync(catalogPath, JSON.stringify({ activities: [{ id: 'sample', audioFiles }] }));
    writeFileSync(manifestPath, JSON.stringify({ jobs }));
    const beforeCatalog = readFileSync(catalogPath, 'utf8');
    const beforeManifest = readFileSync(manifestPath, 'utf8');

    const output = execFileSync(process.execPath, [path.join(root, 'tool/promote_audio.mjs')], {
      encoding: 'utf8',
    });
    assert.match(output, /Copied 1 reviewed audio files; skipped 2/);
    assert.equal(existsSync(path.join(root, audioFiles.intro)), true);
    assert.equal(existsSync(path.join(root, audioFiles.prompt)), false);
    assert.equal(existsSync(path.join(root, audioFiles.outro)), false);
    assert.equal(readFileSync(catalogPath, 'utf8'), beforeCatalog);
    assert.equal(readFileSync(manifestPath, 'utf8'), beforeManifest);
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});
