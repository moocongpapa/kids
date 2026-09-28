import assert from 'node:assert/strict';
import { after, before, test } from 'node:test';
import { createServer } from 'node:http';
import { createHandler, isApproved } from './server.mjs';

const sample = {
  version: 'test',
  activities: [
    { id: 'draft', mode: 'color', humanApprovedAt: null,
      rightsVerifiedAt: null, audioFiles: {} },
    { id: 'approved', mode: 'color', humanApprovedAt: '2026-09-28',
      rightsVerifiedAt: '2026-09-28', audioFiles: {
        intro: 'assets/audio/intro.m4a', prompt: 'assets/audio/prompt.m4a',
        outro: 'assets/audio/outro.m4a', offscreen: 'assets/audio/offscreen.m4a',
      } },
  ],
};
const sampleAudioJobs = ['intro', 'prompt', 'outro', 'offscreen'].map((id) => ({
  activityId: 'approved', lineId: id, status: 'APPROVED',
  suggestedFile: `assets/audio/${id}.m4a`,
  humanReviewedAt: '2026-09-28', commercialRightsEvidence: 'test-only',
  sha256: 'test-only',
}));
const blocks = new Set();
const pool = {
  async query(query, values) {
    if (query.startsWith('SELECT content_id')) {
      return { rows: [...blocks].map((id) => ({ content_id: id })) };
    }
    if (query.startsWith('INSERT')) blocks.add(values[0]);
    return { rows: [] };
  },
};
const secret = 'a'.repeat(48);
let server;
let base;

before(async () => {
  server = createServer(createHandler({ pool, adminToken: secret,
    catalog: sample, audioJobs: sampleAudioJobs }));
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  base = `http://127.0.0.1:${server.address().port}`;
});
after(() => server.close());

test('미승인 콘텐츠는 목록에 없다', async () => {
  assert.equal(isApproved(sample.activities[0]), false);
  const response = await fetch(`${base}/v1/catalog`);
  assert.equal(response.status, 200);
  const body = await response.json();
  assert.deepEqual(body.approvedIds, ['approved']);
});

test('권한 없이는 콘텐츠를 차단하지 못한다', async () => {
  const response = await fetch(`${base}/v1/admin/content/approved/disable`, {
    method: 'POST', body: JSON.stringify({ reason: '안전 검수 중 일시 중단' }),
  });
  assert.equal(response.status, 401);
});

test('관리자 차단 뒤 승인 목록에서 제거된다', async () => {
  const response = await fetch(`${base}/v1/admin/content/approved/disable`, {
    method: 'POST',
    headers: { authorization: `Bearer ${secret}` },
    body: JSON.stringify({ reason: '안전 검수 중 일시 중단' }),
  });
  assert.equal(response.status, 200);
  const manifest = await (await fetch(`${base}/v1/catalog`)).json();
  assert.deepEqual(manifest.approvedIds, []);
  assert.deepEqual(manifest.blockedIds, ['approved']);
});
