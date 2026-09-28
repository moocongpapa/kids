import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { test } from 'node:test';
import { buildPayload, encodeM4a, extractWav, wavMetrics } from './generate_gemini_tts.mjs';

function tinyWav() {
  const sampleRate = 24000;
  const dataSize = sampleRate * 2;
  const wav = Buffer.alloc(44 + dataSize);
  wav.write('RIFF', 0);
  wav.writeUInt32LE(36 + dataSize, 4);
  wav.write('WAVEfmt ', 8);
  wav.writeUInt32LE(16, 16);
  wav.writeUInt16LE(1, 20);
  wav.writeUInt16LE(1, 22);
  wav.writeUInt32LE(sampleRate, 24);
  wav.writeUInt32LE(sampleRate * 2, 28);
  wav.writeUInt16LE(2, 32);
  wav.writeUInt16LE(16, 34);
  wav.write('data', 36);
  wav.writeUInt32LE(dataSize, 40);
  return wav;
}

test('TTS sends the exact approved script as text and a separate gentle style', () => {
  const payload = buildPayload({ kind: 'speech', text: '천천히 살펴볼까?' });
  assert.equal(payload.input[0].content[0].text, '천천히 살펴볼까?');
  assert.equal(payload.generation_config.speech_config[0].voice, 'Kore');
  assert.match(payload.input[0].content[0].annotations[0].style, /no shouting/);
  assert.throws(() => buildPayload({ kind: 'original_song', text: '노래' }));
});

test('REST audio response is decoded and checked', () => {
  const wav = tinyWav();
  const result = extractWav({ steps: [{ type: 'model_output', content: [
    { type: 'audio', data: wav.toString('base64') },
  ] }] });
  assert.deepEqual(result, wav);
  assert.equal(wavMetrics(result).durationSeconds, 1);
  assert.equal(wavMetrics(result).clippedSamples, 0);
  assert.throws(() => extractWav({ steps: [] }));
});

test('a generated WAV can become an app-playable M4A when ffmpeg is installed', async (t) => {
  if (spawnSync('which', ['ffmpeg']).status !== 0) {
    t.skip('ffmpeg is not installed; production falls back to WAV');
    return;
  }
  const dir = await mkdtemp(path.join(tmpdir(), 'momosup-tts-test-'));
  try {
    const wavPath = path.join(dir, 'test.wav');
    const m4aPath = path.join(dir, 'test.partial.m4a');
    await writeFile(wavPath, tinyWav());
    encodeM4a(wavPath, m4aPath);
    assert.ok(existsSync(m4aPath));
    const output = await readFile(m4aPath);
    assert.ok(output.length > 100);
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
});
