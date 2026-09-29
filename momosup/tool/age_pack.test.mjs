import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { jobsFor } from './generate_age_audio.mjs';
const pack=JSON.parse(fs.readFileSync(new URL('../assets/content/age_journeys.json',import.meta.url)));
test('72 authored activities export 30 parent guides and 126 scene recordings',()=>{
 const jobs=jobsFor(pack);assert.equal(jobs.length,156);assert.equal(new Set(jobs.map(j=>j.id)).size,156);assert.equal(jobs.filter(j=>j.audience==='caregiver').length,30);assert.equal(jobs.filter(j=>j.audience==='child').length,126);
 for(const job of jobs){assert.match(job.id,/^age_\d\d_\d\d_(guide|step_[012])$/);assert.ok(job.text.trim());const a=pack.activities.find(a=>a.id===job.activityId);if(a.minAgeMonths<24)assert.equal(job.audience,'caregiver');}
});
test('all 12 month bands are contiguous, have six different activities, and three variations',()=>{
 let next=6;for(const band of pack.bands){assert.equal(band.min,next);next=band.max+1;const rows=pack.activities.filter(a=>a.minAgeMonths===band.min&&a.maxAgeMonths===band.max);assert.equal(rows.length,6);for(const a of rows){assert.equal(new Set(a.steps).size,3);assert.equal(new Set(a.variants).size,3);}}
 assert.equal(next,96);
});
