import { readFile, writeFile, mkdir, rename, open } from 'node:fs/promises';
import { existsSync, unlinkSync } from 'node:fs';
import { createHash } from 'node:crypto';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildPayload, extractWav, wavMetrics } from './generate_gemini_tts.mjs';

// Adult-operated production tool. Its outputs stay pending until an adult reviews
// the exact scripts/audio and confirms usage rights. No child data is submitted.
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const manifestPath = path.join(root, 'assets/content/age_audio_manifest.json');
const sha = value => createHash('sha256').update(value).digest('hex');
export function jobsFor(pack) {
  return pack.activities.flatMap(a => a.mechanic === 'caregiver'
    ? [{ id: `${a.id}_guide`, activityId: a.id, text: a.narration, kind: 'speech', audience: 'caregiver' }]
    : a.steps.map((text, i) => ({ id: `${a.id}_step_${i}`, activityId: a.id, text, kind: 'speech', audience: 'child' })));
}
export async function run(args = process.argv.slice(2)) {
  const pack = JSON.parse(await readFile(path.join(root, 'assets/content/age_journeys.json')));
  const jobs = jobsFor(pack);
  if (!args.includes('--adult-preview')) {
    console.log(JSON.stringify({ jobs: jobs.length, mode: 'dry-run', notice: 'Use --adult-preview to generate review copies. This does not assert child-app redistribution rights.' }));
    return;
  }
  const lockPath=path.join(root,'production/age_audio_generation.lock');
  const lock=await open(lockPath,'wx').catch(()=>{throw new Error('Another age audio generator may be running. Inspect production/age_audio_generation.lock before retrying.');});
  await lock.writeFile(String(process.pid)); await lock.close();
  process.once('exit',()=>{try{unlinkSync(lockPath);}catch{}});
  process.once('SIGTERM',()=>process.exit(143));
  process.once('SIGINT',()=>process.exit(130));
  if (!process.env.GEMINI_API_KEY && existsSync(path.join(root, '.env'))) {
    const env = await readFile(path.join(root, '.env'), 'utf8');
    const match = env.match(/^\s*(?:export\s+)?GEMINI_API_KEY\s*=\s*(.*?)\s*$/m);
    if (match) process.env.GEMINI_API_KEY = match[1].replace(/^(['"])(.*)\1$/, '$2');
  }
  if (!process.env.GEMINI_API_KEY) throw new Error('Local GEMINI_API_KEY is missing');
  const manifest = existsSync(manifestPath) ? JSON.parse(await readFile(manifestPath)) : {
    version: pack.version, status: 'NEEDS_HUMAN_REVIEW', jobs: [],
    generationAuthorization: 'Owner requested Gemini media production in this Codex task, 2026-09-29.',
    rightsNotice: 'Generation authorization is not provider clearance. Confirm redistribution terms before child release.',
  };
  const limitArg = args.find(a => a.startsWith('--limit='));
  const limit = limitArg ? Number(limitArg.split('=')[1]) : args.includes('--all') ? jobs.length : 1;
  if (!Number.isInteger(limit) || limit < 1 || limit > jobs.length) throw new Error('Invalid limit');
  const todo = [];
  for (const job of jobs) {
    const saved = manifest.jobs.find(j => j.id === job.id && j.text === job.text);
    if (saved?.file && existsSync(path.join(root, saved.file)) && sha(await readFile(path.join(root, saved.file))) === saved.sha256) continue;
    todo.push(job);
  }
  const queue = todo.slice(0, limit);
  await mkdir(path.join(root, 'assets/audio/age_pack'), { recursive: true });
  let cursor = 0, finished = 0;
  const models = ['gemini-3.8-flash-lite-tts', 'gemini-3.1-flash-tts-preview'];
  let modelIndex = 0;
  let nextRequestAt = 0;
  async function requestSlot() { const now=Date.now(); const at=Math.max(now,nextRequestAt); nextRequestAt=at+6500; if(at>now) await new Promise(r=>setTimeout(r,at-now)); }
  let saveQueue = Promise.resolve();
  async function worker() {
    while (cursor < queue.length) {
      const job = queue[cursor++];
      let payload = buildPayload(job, models[modelIndex]);
      if (job.audience === 'caregiver' && payload.input[0].content[0].annotations) payload.input[0].content[0].annotations[0].style = 'Calm warm adult Korean guide. Clear conversational Korean, gentle moderate pace, no singing, no sound effects, no added words.';
      let wav;
      for (let attempt = 0; attempt < 4; attempt++) {
        await requestSlot();
        const response = await fetch('https://generativelanguage.googleapis.com/v1beta/interactions', {
          method: 'POST', headers: { 'content-type': 'application/json', 'x-goog-api-key': process.env.GEMINI_API_KEY },
          body: JSON.stringify(payload), signal: AbortSignal.timeout(120000),
        });
        if (response.ok) { wav = extractWav(await response.json()); break; }
        // Only print structured quota fields; never response text or credentials.
        const err = await response.json().catch(() => ({}));
        console.log(JSON.stringify({http:response.status,reason:String(err.error?.message ?? err.message ?? 'rate limited').replaceAll(process.env.GEMINI_API_KEY,'[REDACTED]').slice(0,500)}));
        for (const detail of err.error?.details ?? []) {
          for (const violation of detail.violations ?? []) console.log(JSON.stringify({quotaId:violation.quotaId,quotaValue:violation.quotaValue}));
          if (detail.retryDelay) console.log(JSON.stringify({retryDelay:detail.retryDelay}));
        }
        if (response.status === 429 && /per day/i.test(err.error?.message ?? err.message ?? '')) { if(payload.model !== models[modelIndex]) {payload=buildPayload(job,models[modelIndex]);continue;} if(modelIndex + 1 < models.length) {modelIndex++;payload=buildPayload(job,models[modelIndex]);continue;} }
        if (![429, 500, 502, 503, 504].includes(response.status) || attempt === 3) throw new Error(`Gemini HTTP ${response.status} (${job.id})`);
        const advertised = String(err.error?.message ?? err.message ?? '').match(/retry in (\d+)s/i);
        const delay = advertised ? Math.min(60000, Number(advertised[1])*1000+1000) : Math.min(20000,3000*(attempt+1));
        nextRequestAt = Math.max(nextRequestAt,Date.now()+delay);
        await new Promise(r => setTimeout(r,delay));
      }
      if (!wav) throw new Error(`No audio after retries: ${job.id}`);
      const metrics = wavMetrics(wav);
      if (metrics.peakDbfs === null || metrics.peakDbfs < -50 || metrics.clippedSamples || metrics.durationSeconds > 90) throw new Error(`Audio quality check failed: ${job.id}`);
      const file = `assets/audio/age_pack/${job.id}.wav`;
      await writeFile(path.join(root, `${file}.partial`), wav);
      await rename(path.join(root, `${file}.partial`), path.join(root, file));
      const entry = { ...job, file, sha256: sha(wav), model: payload.model, voice: 'Kore', generatedAt: new Date().toISOString(), metrics, status: 'NEEDS_HUMAN_REVIEW', humanReviewedAt: null, rightsEvidence: null };
      const at = manifest.jobs.findIndex(j => j.id === job.id);
      if (at < 0) manifest.jobs.push(entry); else manifest.jobs[at] = entry;
      // Serialize writes from workers and atomically replace to make resumes safe.
      saveQueue = saveQueue.then(async () => {
        manifest.jobs.sort((a,b) => a.id.localeCompare(b.id));
        await writeFile(`${manifestPath}.partial`, `${JSON.stringify(manifest, null, 2)}\n`);
        await rename(`${manifestPath}.partial`, manifestPath);
      });
      await saveQueue;
      console.log(`${++finished}/${queue.length} ${job.id} ${metrics.durationSeconds}s`);
      if (cursor < queue.length) await new Promise(r => setTimeout(r, 2000));
    }
  }
  const workers = await Promise.allSettled([worker(),worker(),worker()]);
  await saveQueue;
  const failed = workers.filter(r => r.status === 'rejected');
  if (failed.length) throw new Error(failed.map(r => r.reason.message).join('; '));
  console.log(`Generated ${finished}; pending human listening and rights review.`);
}
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) run().catch(e => { console.error(e.message); process.exitCode = 1; });
