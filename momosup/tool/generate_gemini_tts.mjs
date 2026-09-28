import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync } from 'node:fs';
import { mkdir, readFile, rename, unlink, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const manifestPath = path.join(root, 'assets/content/audio_manifest.json');
const endpoint = 'https://generativelanguage.googleapis.com/v1beta/interactions';
const defaultModel = 'gemini-3.8-flash-tts';
const defaultVoice = 'Kore';
const style = 'Warm, calm Korean adult storyteller. Clear natural Korean pronunciation, gentle consistent volume, slightly unhurried, no shouting, no exaggerated baby talk.';

export function buildPayload(job, model = defaultModel, voice = defaultVoice) {
  if (job.kind !== 'speech' || typeof job.text !== 'string' || !job.text.trim()) {
    throw new Error('Only nonempty speech jobs can use TTS');
  }
  return {
    model,
    input: [{
      type: 'user_input',
      content: [{
        type: 'text',
        text: job.text,
        annotations: [{ type: 'speech_metadata', style }],
      }],
    }],
    response_format: { type: 'audio' },
    generation_config: { speech_config: [{ voice }] },
  };
}

export function extractWav(response) {
  const content = response?.steps
    ?.filter((step) => step.type === 'model_output')
    .flatMap((step) => step.content ?? [])
    .filter((item) => item.type === 'audio' && typeof item.data === 'string');
  if (!content?.length) throw new Error('Gemini response has no audio output');
  const wav = Buffer.from(content.at(-1).data, 'base64');
  if (wav.length < 45 || wav.toString('ascii', 0, 4) !== 'RIFF' ||
      wav.toString('ascii', 8, 12) !== 'WAVE') {
    throw new Error('Gemini response is not a complete WAV file');
  }
  return wav;
}

export function wavMetrics(wav) {
  const sampleRate = wav.readUInt32LE(24);
  const channels = wav.readUInt16LE(22);
  const bitsPerSample = wav.readUInt16LE(34);
  if (channels !== 1 || bitsPerSample !== 16 || sampleRate < 8000) {
    throw new Error('Unexpected WAV audio format');
  }
  let offset = 12;
  while (offset + 8 <= wav.length) {
    const name = wav.toString('ascii', offset, offset + 4);
    const size = wav.readUInt32LE(offset + 4);
    if (name === 'data') {
      if (offset + 8 + size > wav.length || size < sampleRate / 2) {
        throw new Error('WAV audio is truncated or too short');
      }
      let peak = 0;
      let clipped = 0;
      for (let i = offset + 8; i + 1 < offset + 8 + size; i += 2) {
        const amplitude = Math.abs(wav.readInt16LE(i));
        peak = Math.max(peak, amplitude);
        if (amplitude >= 32760) clipped++;
      }
      return {
        durationSeconds: Number((size / (sampleRate * 2)).toFixed(2)),
        sampleRate,
        peakDbfs: peak ? Number((20 * Math.log10(peak / 32768)).toFixed(1)) : null,
        clippedSamples: clipped,
      };
    }
    offset += 8 + size + (size % 2);
  }
  throw new Error('WAV has no data chunk');
}

function commandExists(command) {
  return spawnSync('which', [command], { stdio: 'ignore' }).status === 0;
}

export function encodeM4a(wavPath, outputPath) {
  if (!commandExists('ffmpeg')) throw new Error('ffmpeg is required to encode M4A');
  const result = spawnSync('ffmpeg', ['-hide_banner', '-loglevel', 'error', '-y', '-i', wavPath, '-c:a', 'aac', '-b:a', '96k', outputPath], { encoding: 'utf8' });
  if (result.status !== 0) throw new Error(`M4A encoding failed: ${result.stderr?.trim() || result.status}`);
}

async function synthesize(payload, apiKey) {
  for (let attempt = 0; attempt < 3; attempt++) {
    const response = await fetch(endpoint, {
      method: 'POST',
      headers: { 'content-type': 'application/json', 'x-goog-api-key': apiKey },
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(120_000),
    });
    if (response.ok) return extractWav(await response.json());
    if (![429, 500, 502, 503, 504].includes(response.status) || attempt === 2) {
      throw new Error(`Gemini API returned HTTP ${response.status}`);
    }
    await new Promise((resolve) => setTimeout(resolve, 1500 * (attempt + 1)));
  }
  throw new Error('Gemini API retries exhausted');
}

function optionsFrom(args) {
  const options = { dryRun: false, activity: null, limit: Infinity, model: defaultModel, voice: defaultVoice, rightsEvidence: null };
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (arg === '--dry-run') options.dryRun = true;
    else if (arg === '--activity') options.activity = args[++i];
    else if (arg === '--limit') options.limit = Number(args[++i]);
    else if (arg === '--model') options.model = args[++i];
    else if (arg === '--voice') options.voice = args[++i];
    else if (arg === '--rights-evidence') options.rightsEvidence = args[++i];
    else throw new Error(`Unknown argument: ${arg}`);
  }
  if (!Number.isInteger(options.limit) && options.limit !== Infinity || options.limit < 1) {
    throw new Error('--limit must be a positive integer');
  }
  if (!/^gemini-[a-z0-9.-]+-tts$/.test(options.model) || !/^[A-Za-z0-9_-]+$/.test(options.voice)) {
    throw new Error('Invalid model or voice name');
  }
  return options;
}

export async function run(args = process.argv.slice(2)) {
  const options = optionsFrom(args);
  const manifest = JSON.parse(await readFile(manifestPath, 'utf8'));
  const jobs = manifest.jobs.filter((job) => job.kind === 'speech' &&
    (!options.activity || job.activityId === options.activity) &&
    job.status !== 'GENERATED_NEEDS_REVIEW').slice(0, options.limit);
  if (options.dryRun) {
    process.stdout.write(`대상 안내 음성 ${jobs.length}개 (노래 제외)\n`);
    for (const job of jobs) process.stdout.write(`${job.activityId}/${job.lineId}: ${job.text}\n`);
    return;
  }
  if (!options.rightsEvidence || !existsSync(options.rightsEvidence)) {
    throw new Error('Gemini API under-18 app rights are unresolved. Obtain written provider/legal clearance, save it locally, then pass --rights-evidence /path/to/evidence');
  }
  const evidenceBytes = await readFile(options.rightsEvidence);
  if (evidenceBytes.length < 20) throw new Error('Rights evidence file is empty or incomplete');
  const evidenceSha256 = createHash('sha256').update(evidenceBytes).digest('hex');
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) throw new Error('Set GEMINI_API_KEY in your local environment; do not paste it into chat or code');
  await mkdir(path.join(root, 'production/audio_wav'), { recursive: true });
  await mkdir(path.join(root, 'production/audio_pending'), { recursive: true });
  const useM4a = commandExists('ffmpeg');
  for (const [index, job] of jobs.entries()) {
    const filename = `${job.activityId}__${job.lineId}`;
    if (!/^[a-z0-9_]+$/.test(filename)) throw new Error(`Unsafe audio ID: ${filename}`);
    const wavPath = path.join(root, 'production/audio_wav', `${filename}.wav`);
    const pendingPath = path.join(root, 'production/audio_pending', `${filename}.${useM4a ? 'm4a' : 'wav'}`);
    if (existsSync(wavPath) || existsSync(pendingPath)) {
      throw new Error(`Output already exists for ${filename}; inspect it before retrying`);
    }
    process.stdout.write(`[${index + 1}/${jobs.length}] ${filename}\n`);
    const wav = await synthesize(buildPayload(job, options.model, options.voice), apiKey);
    const metrics = wavMetrics(wav);
    if (metrics.peakDbfs === null || metrics.peakDbfs < -50) {
      throw new Error(`${filename} is silent or barely audible; do not publish it`);
    }
    if (metrics.clippedSamples > 0) throw new Error(`${filename} is clipped; do not publish it`);
    const wavTemp = `${wavPath}.partial`;
    const pendingTemp = `${pendingPath}.partial.${useM4a ? 'm4a' : 'wav'}`;
    try {
      await writeFile(wavTemp, wav, { flag: 'wx' });
      if (useM4a) encodeM4a(wavTemp, pendingTemp);
      else await writeFile(pendingTemp, wav, { flag: 'wx' });
      await rename(wavTemp, wavPath);
      await rename(pendingTemp, pendingPath);
    } catch (error) {
      await unlink(wavTemp).catch(() => {});
      await unlink(pendingTemp).catch(() => {});
      throw error;
    }
    job.generationModel = options.model;
    job.generationVoice = options.voice;
    job.generationDate = new Date().toISOString();
    job.childAppTermsEvidenceSha256 = evidenceSha256;
    job.sourceWav = path.relative(root, wavPath);
    job.generatedFile = path.relative(root, pendingPath);
    job.suggestedFile = `assets/audio/${filename}.${useM4a ? 'm4a' : 'wav'}`;
    job.sha256 = createHash('sha256').update(await readFile(pendingPath)).digest('hex');
    job.audioFormat = useM4a ? 'aac/m4a' : 'pcm/wav';
    job.audioMetrics = metrics;
    job.status = 'GENERATED_NEEDS_REVIEW';
    // Rights evidence and the founder's listening/approval remain deliberately unset.
    await writeFile(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`);
  }
  process.stdout.write(`생성 ${jobs.length}개 완료. 아이 모드 승인·권리 검증은 아직 필요합니다.\n`);
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  run().catch((error) => {
    process.stderr.write(`${error.message}\n`);
    process.exitCode = 1;
  });
}
