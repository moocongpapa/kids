import { copyFileSync, existsSync, mkdirSync, readFileSync, readdirSync } from 'node:fs';
import { createHash } from 'node:crypto';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const pendingDir = path.join(root, 'production/audio_pending');
const audioDir = path.join(root, 'assets/audio');
const catalog = JSON.parse(readFileSync(path.join(root, 'assets/content/catalog.json'), 'utf8'));
const manifest = JSON.parse(readFileSync(path.join(root, 'assets/content/audio_manifest.json'), 'utf8'));

if (!existsSync(audioDir)) mkdirSync(audioDir, { recursive: true });

let copied = 0;
let skipped = 0;
for (const file of existsSync(pendingDir) ? readdirSync(pendingDir) : []) {
  const match = /^([a-z0-9_]+)__([a-z0-9_]+)\.(wav|m4a)$/.exec(file);
  if (!match) continue;

  const [, activityId, lineId] = match;
  const src = path.join(pendingDir, file);
  const relativeDest = `assets/audio/${file}`;
  const hash = createHash('sha256').update(readFileSync(src)).digest('hex');

  const job = manifest.jobs.find((j) => j.activityId === activityId && j.lineId === lineId);
  const act = catalog.activities.find((a) => a.id === activityId);
  // A copied file is not evidence of human review or commercial-use rights.
  if (job?.status !== 'APPROVED' || !job.humanReviewedAt ||
      !job.commercialRightsEvidence || job.sha256 !== hash ||
      job.suggestedFile !== relativeDest ||
      act?.audioFiles?.[lineId] !== relativeDest) {
    skipped++;
    continue;
  }

  copyFileSync(src, path.join(audioDir, file));
  copied++;
}

console.log(`Copied ${copied} reviewed audio files; skipped ${skipped} without matching approval and hash.`);
