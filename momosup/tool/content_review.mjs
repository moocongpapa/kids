import { createHash } from 'node:crypto';

// Keep the canonical representation aligned with lib/models/content_review.dart.
const reviewFields = new Set([
  'status', 'reviewStatus', 'humanReviewedAt', 'rightsEvidence',
  'approvedContentSha256', 'validatedAudioHashes', 'musicLyrics', 'musicPrompt',
]);
function canonical(value) {
  if (Array.isArray(value)) return value.map(canonical);
  if (value !== null && typeof value === 'object') {
    return Object.fromEntries(Object.keys(value).sort().map(k => [k, canonical(value[k])]));
  }
  return value;
}
export function contentReviewDigest(data) {
  const content = Object.fromEntries(Object.entries(data).filter(([key]) => !reviewFields.has(key)));
  return createHash('sha256').update(JSON.stringify(canonical(content))).digest('hex');
}
export function hasApprovedReview(data, statusField = 'status') {
  return data[statusField] === 'APPROVED' &&
    typeof data.humanReviewedAt === 'string' && Number.isFinite(Date.parse(data.humanReviewedAt)) &&
    typeof data.rightsEvidence === 'string' && data.rightsEvidence.trim().length > 0 &&
    data.approvedContentSha256 === contentReviewDigest(data);
}
