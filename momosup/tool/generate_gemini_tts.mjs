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
const style = 'Bright, warm, and delightfully playful Korean storyteller for young children. Expressive, affectionate, and cheerful voice full of curiosity, clear natural Korean pronunciation, engaging musical cadence, no shouting, perfectly paced for preschoolers.';

async function loadEnvIfPresent() {
  if (process.env.GEMINI_API_KEY) return;
  const envPath = path.join(root, '.env');
  if (!existsSync(envPath)) return;
  const content = await readFile(envPath, 'utf8');
  for (const line of content.split('\n')) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eq = trimmed.indexOf('=');
    if (eq > 0) {
      const key = trimmed.slice(0, eq).trim();
      const val = trimmed.slice(eq + 1).trim();
      if (!process.env[key]) process.env[key] = val;
    }
  }
}

export function buildPayload(job, model = defaultModel, voice = defaultVoice) {
  if (job.kind !== 'speech' || typeof job.text !== 'string' || !job.text.trim()) {
    throw new Error('Only nonempty speech jobs can use TTS');
  }
  const content = [{ type: 'text', text: job.text }];
  if (model.includes('3.8')) {
    content[0].annotations = [{ type: 'speech_metadata', style }];
  }
  return {
    model,
    input: [{
      type: 'user_input',
      content,
    }],
    response_format: { type: 'audio' },
    generation_config: { speech_config: [{ voice }] },
  };
}

export function buildSongPayload(job, model = defaultModel, voice = defaultVoice) {
  if (typeof job.text !== 'string' || !job.text.trim()) {
    throw new Error('Only nonempty song jobs can use TTS');
  }
  const content = [{ type: 'text', text: job.text.replace(/\n/g, '. ') }];
  if (model.includes('3.8')) {
    const songStyle = 'Joyful, catchy, rhythmic singing tone for preschool nursery rhyme, bouncy 4/4 tempo, warm, playful, and cheerful vocal.';
    content[0].annotations = [{ type: 'speech_metadata', style: songStyle }];
  }
  return {
    model,
    input: [{
      type: 'user_input',
      content,
    }],
    response_format: { type: 'audio' },
    generation_config: { speech_config: [{ voice }] },
  };
}

function pcmToWav(pcm, sampleRate = 24000, channels = 1) {
  if (pcm.length >= 44 && pcm.toString('ascii', 0, 4) === 'RIFF' && pcm.toString('ascii', 8, 12) === 'WAVE') {
    return pcm;
  }
  const dataSize = pcm.length;
  const header = Buffer.alloc(44);
  header.write('RIFF', 0);
  header.writeUInt32LE(36 + dataSize, 4);
  header.write('WAVEfmt ', 8);
  header.writeUInt32LE(16, 16);
  header.writeUInt16LE(1, 20);
  header.writeUInt16LE(channels, 22);
  header.writeUInt32LE(sampleRate, 24);
  header.writeUInt32LE(sampleRate * channels * 2, 28);
  header.writeUInt16LE(channels * 2, 32);
  header.writeUInt16LE(16, 34);
  header.write('data', 36);
  header.writeUInt32LE(dataSize, 40);
  return Buffer.concat([header, pcm]);
}

export function extractWav(response) {
  const content = response?.steps
    ?.filter((step) => step.type === 'model_output')
    .flatMap((step) => step.content ?? [])
    .filter((item) => item.type === 'audio' && typeof item.data === 'string');
  if (!content?.length) throw new Error('Gemini response has no audio output');
  const raw = Buffer.from(content.at(-1).data, 'base64');
  const wav = pcmToWav(raw);
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
  for (let attempt = 0; attempt < 6; attempt++) {
    const response = await fetch(endpoint, {
      method: 'POST',
      headers: { 'content-type': 'application/json', 'x-goog-api-key': apiKey },
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(120_000),
    });
    if (response.ok) return extractWav(await response.json());
    const errText = await response.text().catch(() => '');
    if (![429, 500, 502, 503, 504].includes(response.status) || attempt === 5) {
      throw new Error(`Gemini API returned HTTP ${response.status}: ${errText.slice(0, 200)}`);
    }
    const delay = response.status === 429 ? 20_000 * (attempt + 1) : 2000 * (attempt + 1);
    process.stdout.write(`  [재시도 대기 ${delay / 1000}s (HTTP ${response.status})]\n`);
    await new Promise((resolve) => setTimeout(resolve, delay));
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
  if (!/^gemini-[a-z0-9.-]+-tts(-preview)?$/.test(options.model) || !/^[A-Za-z0-9_-]+$/.test(options.voice)) {
    throw new Error('Invalid model or voice name');
  }
  return options;
}

export async function run(args = process.argv.slice(2)) {
  await loadEnvIfPresent();
  const options = optionsFrom(args);
  const manifest = JSON.parse(await readFile(manifestPath, 'utf8'));
  const jobs = manifest.jobs.filter((job) =>
    (!options.activity || job.activityId === options.activity) &&
    job.status !== 'GENERATED_NEEDS_REVIEW' &&
    job.status !== 'APPROVED').slice(0, options.limit);
  if (options.dryRun) {
    process.stdout.write(`대상 작업 ${jobs.length}개\n`);
    for (const job of jobs) process.stdout.write(`${job.activityId}/${job.lineId} (${job.kind}): ${job.text.slice(0, 30)}...\n`);
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
    const payload = job.kind === 'original_song'
      ? buildSongPayload(job, options.model, options.voice)
      : buildPayload(job, options.model, options.voice);
    const wav = await synthesize(payload, apiKey);
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
    if (index + 1 < jobs.length) await new Promise((resolve) => setTimeout(resolve, 2000));
  }
  process.stdout.write(`생성 ${jobs.length}개 완료. 아이 모드 승인·권리 검증은 아직 필요합니다.\n`);
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  run().catch((error) => {
    process.stderr.write(`${error.message}\n`);
    process.exitCode = 1;
  });
}
