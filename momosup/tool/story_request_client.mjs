import {randomUUID} from 'node:crypto';

// Dependencies are injected so quota, retries and privacy can be tested offline.
export function createStoryRequester({getKey, fetchImpl, writeEvent, sleep, warn = () => {}, now = () => Date.now(), disabled = () => false, maxVideoRequests = 20}) {
  if (!Number.isInteger(maxVideoRequests) || maxVideoRequests < 1 || maxVideoRequests > 20) throw new Error('Invalid per-run video request allowance');
  const runId = randomUUID();
  let videoRequests = 0;
  let ledgerHealthy = true;
  const safeContext = c => Object.fromEntries(['episode', 'scene', 'purpose'].filter(k => /^[a-z0-9_-]{1,64}$/.test(c[k] ?? '')).map(k => [k, c[k]]));
  const usage = value => Object.fromEntries(Object.entries(value ?? {}).filter(([k, v]) => /token|count|duration|second/i.test(k) && typeof v === 'number' && Number.isFinite(v) && v >= 0));
  return async function request(payload, context = {}) {
    if (disabled()) throw new Error('STORY_API_DISABLED: offline work cannot send any generation or review request.');
    if (!ledgerHealthy) throw new Error('STORY_LEDGER_FAILED: save the previous response and repair the ledger before further requests.');
    const key = await getKey();
    if (!key) throw new Error('Local GEMINI_API_KEY is missing');
    const model = payload.model;
    if (!/^[a-z0-9.-]+$/.test(model ?? '')) throw new Error('Invalid model');
    const requestId = randomUUID(), fields = {runId, requestId, model, ...safeContext(context)};
    const isVideo = payload.response_format?.type === 'video';
    for (let attempt = 1; attempt <= 8; attempt++) {
      if (isVideo && videoRequests >= maxVideoRequests) throw new Error('RUN_VIDEO_REQUEST_LIMIT: resume explicitly with a new request allowance.');
      const start = now();
      if (isVideo) videoRequests++;
      // Failure to persist the start event stops before any billable request.
      await writeEvent({...fields, attempt, event: 'started', time: new Date(start).toISOString(), videoRequests});
      let response;
      try {
        response = await fetchImpl('https://generativelanguage.googleapis.com/v1beta/interactions', {
          method: 'POST', headers: {'content-type': 'application/json', 'x-goog-api-key': key},
          body: JSON.stringify(payload), signal: AbortSignal.timeout(360000),
        });
      } catch {
        await writeEvent({...fields, attempt, event: 'failed', time: new Date(now()).toISOString(), category: 'network-unknown', elapsedMs: now() - start});
        // An ambiguous timeout may already be billed; do not silently resubmit it.
        throw new Error('STORY_NETWORK_OUTCOME_UNKNOWN: inspect the provider before repeating this request.');
      }
      const result = await response.json().catch(() => null);
      if (response.ok && result) {
        try {
          await writeEvent({...fields, attempt, event: 'succeeded', time: new Date(now()).toISOString(), httpStatus: response.status, elapsedMs: now() - start, usage: usage(result.usage ?? result.usageMetadata)});
        } catch {
          ledgerHealthy = false;
          // Keep a successful media response so the caller can save it, but stop the next request.
          warn('STORY_LEDGER_FAILED: response preserved; repair the ledger before further requests.');
        }
        return result;
      }
      const message = String(result?.error?.message ?? '');
      const category = response.ok && !result ? 'response-unknown'
        : /monthly spending cap|spend(ing)? (cap|limit)/i.test(message) ? 'project-spend-cap'
        : /requests per day|daily (?:request )?(?:limit|quota)/i.test(message) ? 'daily-quota'
        : /spend-based rate|spending rate/i.test(message) ? 'spending-rate' : 'http-error';
      // Never record the provider message, payload, key, prompts or base64 media.
      const retryAfter = message.match(/retry in ([0-9dhms ]+)/i)?.[1]?.trim();
      await writeEvent({...fields, attempt, event: 'failed', time: new Date(now()).toISOString(), httpStatus: response.status, elapsedMs: now() - start, category, ...(retryAfter ? {retryAfter} : {})});
      if (category === 'project-spend-cap') throw new Error('PROJECT_SPEND_CAP_REACHED: resume after the owner raises the project cap.');
      if (category === 'daily-quota') throw new Error(`DAILY_REQUEST_QUOTA_REACHED (${model})${retryAfter ? '; retry after ' + retryAfter : ''}`);
      if (!result && response.ok) throw new Error('STORY_RESPONSE_UNKNOWN: inspect the provider before repeating this request.');
      if (![429, 500, 502, 503, 504].includes(response.status) || attempt === 8) throw new Error(`Gemini HTTP ${response.status} (${model})`);
      const delay = category === 'spending-rate' ? 120000 : Math.min(60000, 15000 * attempt);
      for (let remaining = delay; remaining > 0; remaining -= 60000) await sleep(Math.min(60000, remaining));
    }
  };
}

export function summarizeStoryRequests(events) {
  const counts = {started: 0, succeeded: 0, failed: 0, unknown: 0, byModel: {}};
  const started = new Set(), finished = new Set();
  for (const r of events) {
    const key = r.requestId + ':' + r.attempt;
    if (!['started', 'succeeded', 'failed'].includes(r.event)) continue;
    counts[r.event]++;
    const model = counts.byModel[r.model] ??= {started: 0, succeeded: 0, failed: 0};
    model[r.event]++;
    if (r.event === 'started') started.add(key);
    else if (!['network-unknown', 'response-unknown'].includes(r.category)) finished.add(key);
  }
  counts.unknown = [...started].filter(k => !finished.has(k)).length;
  return counts;
}
