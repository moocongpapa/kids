import { createServer } from 'node:http';
import { createHash, timingSafeEqual } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import pg from 'pg';

const directory = path.dirname(fileURLToPath(import.meta.url));
const catalogPath = path.resolve(directory, '../assets/content/catalog.json');
const audioManifestPath = path.resolve(directory, '../assets/content/audio_manifest.json');

function expectedAudioIds(item) {
  const result = ['intro', 'prompt', 'outro', 'offscreen'];
  if (item.mode === 'touch') {
    for (let i = 0; i < item.choices.length; i++) {
      result.push(`choice_${i}`, `reaction_${i}`);
    }
  }
  if (item.mode === 'move') result.push('song');
  return result;
}

export function isApproved(item, audioJobs = []) {
  return Boolean(
    item.humanApprovedAt &&
    item.rightsVerifiedAt &&
    expectedAudioIds(item).every((id) => {
      const filePath = item.audioFiles?.[id];
      const matches = audioJobs.filter((job) =>
        job.activityId === item.id && job.lineId === id);
      if (matches.length !== 1) return false;
      const job = matches[0];
      return typeof filePath === 'string' &&
        filePath.startsWith('assets/audio/') &&
        !filePath.includes('..') &&
        job.status === 'APPROVED' &&
        Boolean(job.humanReviewedAt) &&
        Boolean(job.commercialRightsEvidence) &&
        Boolean(job.sha256) &&
        job.suggestedFile === filePath;
    }),
  );
}

function authorized(header, adminToken) {
  if (!adminToken || adminToken.length < 32 || !header?.startsWith('Bearer ')) {
    return false;
  }
  const supplied = Buffer.from(header.slice(7));
  const expected = Buffer.from(adminToken);
  return supplied.length === expected.length &&
    timingSafeEqual(supplied, expected);
}

function send(response, status, payload) {
  response.writeHead(status, {
    'content-type': 'application/json; charset=utf-8',
    'cache-control': 'no-store',
    'x-content-type-options': 'nosniff',
  });
  response.end(JSON.stringify(payload));
}

async function readSmallJson(request) {
  let data = '';
  for await (const chunk of request) {
    data += chunk;
    if (data.length > 4096) throw new Error('BODY_TOO_LARGE');
  }
  return JSON.parse(data);
}

export function createHandler({ pool, adminToken, catalog, audioJobs = [] }) {
  const byId = new Map(catalog.activities.map((item) => [item.id, item]));
  return async function handler(request, response) {
    try {
      const url = new URL(request.url, 'http://localhost');
      if (request.method === 'GET' && url.pathname === '/health') {
        await pool.query('SELECT 1');
        return send(response, 200, { ok: true });
      }
      if (request.method === 'GET' && url.pathname === '/v1/catalog') {
        const blocked = await pool.query('SELECT content_id FROM content_blocks');
        const blockedIds = new Set(blocked.rows.map((row) => row.content_id));
        const approvedIds = catalog.activities
          .filter((item) => isApproved(item, audioJobs) && !blockedIds.has(item.id))
          .map((item) => item.id);
        const payload = {
          version: catalog.version,
          checkedAt: new Date().toISOString(),
          approvedIds,
          blockedIds: [...blockedIds],
          offlineMaxAgeHours: 24,
        };
        payload.digest = createHash('sha256')
          .update(JSON.stringify(payload)).digest('hex');
        return send(response, 200, payload);
      }
      const disable = /^\/v1\/admin\/content\/([a-z0-9_]+)\/disable$/.exec(url.pathname);
      if (request.method === 'POST' && disable) {
        if (!authorized(request.headers.authorization, adminToken)) {
          return send(response, 401, { error: 'unauthorized' });
        }
        const id = disable[1];
        if (!byId.has(id)) return send(response, 404, { error: 'unknown_content' });
        const body = await readSmallJson(request);
        const reason = typeof body.reason === 'string' ? body.reason.trim() : '';
        if (reason.length < 10 || reason.length > 500) {
          return send(response, 400, { error: 'reason_length_10_to_500' });
        }
        await pool.query(
          `INSERT INTO content_blocks(content_id, reason, disabled_at)
           VALUES ($1, $2, NOW())
           ON CONFLICT (content_id) DO UPDATE
           SET reason = EXCLUDED.reason, disabled_at = NOW()`,
          [id, reason],
        );
        return send(response, 200, { id, disabled: true });
      }
      return send(response, 404, { error: 'not_found' });
    } catch (error) {
      if (error.message === 'BODY_TOO_LARGE') {
        return send(response, 413, { error: 'body_too_large' });
      }
      if (error instanceof SyntaxError) {
        return send(response, 400, { error: 'invalid_json' });
      }
      // Fail closed: never return an unblocked catalog if Postgres is down.
      return send(response, 503, { error: 'temporarily_unavailable' });
    }
  };
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  if (!process.env.DATABASE_URL || !process.env.ADMIN_TOKEN ||
      process.env.ADMIN_TOKEN.length < 32) {
    throw new Error('DATABASE_URL and ADMIN_TOKEN (32+ characters) are required');
  }
  const catalog = JSON.parse(await readFile(catalogPath, 'utf8'));
  const audioManifest = JSON.parse(await readFile(audioManifestPath, 'utf8'));
  const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL,
    max: 3, connectionTimeoutMillis: 5000 });
  const server = createServer(createHandler({
    pool, adminToken: process.env.ADMIN_TOKEN, catalog,
    audioJobs: audioManifest.jobs,
  }));
  const port = Number(process.env.PORT ?? 10000);
  server.listen(port, '0.0.0.0', () => {
    process.stdout.write(`momosup safety API listening on ${port}\n`);
  });
}
