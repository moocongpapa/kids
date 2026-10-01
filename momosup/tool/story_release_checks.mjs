import path from 'node:path';
import {hash, normalize, narrationPassed, visualPassed, sceneSpecHash, readJson, verifyAsset} from './story_production_shared.mjs';

export async function reviewedAudio(root, episode) {
  const audio = await readJson(path.join(root, 'production/story_pilot', episode.id + '.audio.json'));
  const review = audio?.finalAudioReview;
  if (audio?.episode !== episode.id || audio.title !== episode.title || review?.passed !== true ||
      normalize(review.titleReview?.transcript ?? '') !== normalize(episode.title) ||
      review.titleReview.music !== false || review.titleReview.abruptNoise !== false ||
      review.musicReview?.voice !== false || review.musicReview.abruptNoise !== false) throw new Error('Unreviewed title/music: ' + episode.id);
  await verifyAsset(root, audio.titleAudioAsset, audio.assetHashes?.title);
  await verifyAsset(root, audio.musicAsset, audio.assetHashes?.music);
  return audio;
}

export async function loadReviewedFilm(root, episode, visualReview, {applyEditing = true} = {}) {
  const item = await readJson(path.join(root, 'production/story_pilot', episode.id + '.json'));
  if (item?.id !== episode.id || item.title !== episode.title || item.minAgeMonths !== episode.minAgeMonths ||
      item.maxAgeMonths !== episode.maxAgeMonths || item.theme !== episode.theme ||
      item.status !== 'APPLIED_ON_OWNER_REQUEST' || item.scenes?.length !== episode.scenes.length) throw new Error('Incomplete film: ' + episode.id);
  for (let i = 0; i < episode.scenes.length; i++) {
    const s = item.scenes[i], expected = episode.scenes[i];
    if (s.id !== episode.id + '_' + String(i).padStart(2, '0') || s.specSha256 !== sceneSpecHash(expected) ||
        s.text !== expected.text || s.visual !== expected.visual || s.review?.passed !== true ||
        !narrationPassed(s.review.transcript, expected.text) || !visualPassed(s.review.visual)) throw new Error('Stale/unreviewed scene: ' + s.id);
  }
  const duration = item.scenes.reduce((n, s) => n + s.seconds, 0);
  if (!Number.isFinite(item.durationSeconds) || item.durationSeconds <= 0 || item.durationSeconds > 420 || Math.abs(duration - item.durationSeconds) > 1) throw new Error('Invalid film duration');
  await verifyAsset(root, item.videoAsset, item.sha256);
  await verifyAsset(root, item.posterAsset, item.posterSha256);
  const filmReview = await readJson(path.join(root, 'production/story_pilot', episode.id + '.film_review.json'));
  const r = filmReview?.review;
  if (filmReview?.passed !== true || filmReview.sha256 !== item.sha256 || !Number.isFinite(r?.watchedThroughSeconds) || r.watchedThroughSeconds < item.durationSeconds - 2 ||
      !['plotCoherent', 'narrationClear', 'themeFocused', 'endingComplete'].every(k => r?.[k] === true) ||
      !Array.isArray(r.issues) || r.issues.some(i => i.severity === 'blocking')) throw new Error('Full-film review required: ' + episode.id);
  if (!visualReview?.reviewedFilms?.some(f => f.id === episode.id && f.sha256 === item.sha256) ||
      visualReview.requiredCorrections?.some(c => c.id.startsWith(episode.id + '_'))) throw new Error('Visual correction/inspection required: ' + episode.id);
  const audio = await reviewedAudio(root, episode);
  if (item.titleAudioAsset !== audio.titleAudioAsset || item.musicAsset !== audio.musicAsset ||
      hash(JSON.stringify(item.finalAudioReview)) !== hash(JSON.stringify(audio.finalAudioReview))) throw new Error('Film audio review changed: ' + episode.id);
  const result = {...item, automatedReviewPassed: true};
  if (applyEditing) {
    const edit = await readJson(path.join(root, 'production/story_pilot', episode.id + '.editing.json'));
    if (edit) {
      if (edit.episode !== episode.id || edit.sourceVideoSha256 !== item.sha256 || edit.sourceMusicSha256 !== audio.assetHashes.music ||
          edit.transform?.kind !== 'loop-crossfade-v1' || edit.technicalReview?.passed !== true ||
          edit.technicalReview.loopDecoded !== true || !Number.isFinite(edit.technicalReview.loopPeakDb) || edit.technicalReview.loopPeakDb >= -.5) throw new Error('Stale/unverified sound edit: ' + episode.id);
      await verifyAsset(root, edit.loopAsset, edit.loopSha256);
      result.musicAsset = edit.loopAsset;
      result.localAudioEdit = {sourceMusicAsset: audio.musicAsset, sourceMusicSha256: audio.assetHashes.music, kind: edit.transform.kind};
    }
  }
  return result;
}

export function validateCatalog(catalog, episodes) {
  if (!Array.isArray(catalog.episodes) || !Array.isArray(catalog.previews)) throw new Error('Invalid catalog lists');
  if (catalog.episodes.length && (catalog.productionStatus !== 'COMPLETE' || catalog.episodes.length !== episodes.length)) throw new Error('Partial child publication');
  const seen = new Set();
  for (const [items, preview] of [[catalog.episodes, false], [catalog.previews, true]]) {
    for (const item of items) {
      const expected = episodes.find(e => e.id === item.id);
      if (!expected || seen.has(item.id)) throw new Error('Duplicate/unknown film');
      seen.add(item.id);
      if (item.status !== (preview ? 'PRODUCTION_PREVIEW' : 'APPLIED_ON_OWNER_REQUEST') || item.automatedReviewPassed !== true ||
          item.minAgeMonths !== expected.minAgeMonths || item.maxAgeMonths !== expected.maxAgeMonths ||
          !Number.isFinite(item.durationSeconds) || item.durationSeconds <= 0 || item.durationSeconds > 420) throw new Error('Invalid published metadata');
      for (const field of ['videoAsset', 'posterAsset', 'titleAudioAsset', 'musicAsset']) {
        if (field === 'musicAsset' && item[field] === '' && preview && !item.fullFilmPreview) continue;
        const extension = field === 'videoAsset' ? '.mp4' : field === 'posterAsset' ? '.jpg' : '.m4a';
        if (!/^assets\/stories\/[a-z0-9_]+\.(mp4|m4a|jpg)$/.test(item[field] ?? '') || !item[field].endsWith(extension) || !/^[a-f0-9]{64}$/.test(item.assetHashes?.[item[field]] ?? '')) throw new Error('Missing asset/hash: ' + field);
      }
    }
  }
}
