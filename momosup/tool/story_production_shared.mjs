import fs from 'node:fs/promises';
import path from 'node:path';
import {createHash, randomUUID} from 'node:crypto';

export const hash = bytes => createHash('sha256').update(bytes).digest('hex');
export const visualStyle = 'Original Momosup hand-painted watercolor storybook animation. Match these exact reference characters throughout: Momo olive-green round leaf-feathered bird with cream face, belly and orange beak; Duri small warm brown bear with cream muzzle and belly; Nuri white cloud creature with curled top, small arms and feet. Keep species, colors and anatomy consistent, no clothes or accessories unless scene specifies. Large readable expressions, expressive full character animation, subtle layered forest movement, calm camera, no flashing. Use reference as character/style guide, not a literal starting frame. A continuous 10 second animated shot, with a beginning action and gentle settling. No text, subtitles, symbols, speech or music. ';
export const sceneSpecHash = scene => hash(JSON.stringify(scene) + visualStyle);
export const normalize = s => s.normalize('NFC').replace(/[^\p{L}\p{N}]/gu, '');
// Limited spoken variants. Never merge names, actions, turn ownership or all particles.
// Possessive 의: https://m.korean.go.kr/front/page/pageView.do?mn_id=95&page_id=P000098
const spoken = s => normalize(s.replace(/(^|[\s.!?])(?:앗|아|어)(?=[\s.!?,])/gu, '$1앗')
  .replace(/(^|[\s.!?])(?:응|음)(?=[\s.!?,])/gu, '$1응').replace(/연못[의에](?=\s*달)/gu, '연못의'));
export const sameNarration = (a, b) => typeof a === 'string' && typeof b === 'string' && spoken(a) === spoken(b);
export const narrationPassed = (review, text) => sameNarration(review?.transcript, text) && review.abruptNoise === false && review.music === false;
export const visualPassed = r => r?.animated === true && r.unsafeOrFrightening === false && r.majorCharacterDeformation === false && r.sceneMatches === true;
// Older completed scenes predate prompt sidecars. Their exact raw and encoded
// bytes plus passing scene review can establish provenance without inventing one.
export function rawVideoSpec({scene, raw, prompt, record, encoded}) {
  if (!raw?.length) return null;
  if (/^[a-f0-9]{64}$/.test(prompt?.specSha256 ?? '')) return prompt.specSha256;
  if (record?.specSha256 === sceneSpecHash(scene) && encoded?.length
    && record.sourceVideoSha256 === hash(raw) && record.sha256 === hash(encoded)
    && record.review?.passed === true && narrationPassed(record.review.transcript, scene.text)
    && visualPassed(record.review.visual)
    && (!record.review.specSha256 || record.review.specSha256 === record.specSha256)
    && (!record.review.sourceVideoSha256 || record.review.sourceVideoSha256 === record.sourceVideoSha256)) return record.specSha256;
  return null;
}
export async function readJson(file) {
  try { return JSON.parse(await fs.readFile(file, 'utf8')); }
  catch (error) { if (error.code === 'ENOENT') return null; throw error; }
}
export async function writeJson(file, value) {
  await fs.mkdir(path.dirname(file), {recursive: true});
  const temp = file + '.pending-' + randomUUID();
  try { await fs.writeFile(temp, JSON.stringify(value, null, 2) + '\n'); await fs.rename(temp, file); }
  finally { await fs.rm(temp, {force: true}); }
}
export function storyAsset(root, relative) {
  if (!/^assets\/stories\/[a-z0-9_]+\.(mp4|m4a|jpg)$/.test(relative ?? '')) throw new Error('Invalid story asset path');
  return path.join(root, relative);
}
export async function verifyAsset(root, relative, expected) {
  if (!/^[a-f0-9]{64}$/.test(expected ?? '')) throw new Error('Missing reviewed hash: ' + relative);
  const actual = hash(await fs.readFile(storyAsset(root, relative)));
  if (actual !== expected) throw new Error('Changed reviewed asset: ' + relative);
  return actual;
}
