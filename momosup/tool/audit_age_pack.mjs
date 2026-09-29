import fs from 'node:fs';
import path from 'node:path';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { jobsFor } from './generate_age_audio.mjs';
import { hasApprovedReview } from './content_review.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const read=p=>JSON.parse(fs.readFileSync(path.join(root,p)));
const pack=read('assets/content/age_journeys.json');const speech=read('assets/content/age_audio_manifest.json');const music=read('assets/content/age_music_manifest.json');
const issues=[];const expected=jobsFor(pack);
if(pack.activities.length!==72)issues.push('Expected 72 activities');
if(new Set(pack.activities.map(a=>a.id)).size!==72)issues.push('Duplicate IDs');
for(let age=6;age<=95;age++){
 const choices=pack.activities.filter(a=>a.minAgeMonths<=age&&a.maxAgeMonths>=age);
 if(choices.length!==6)issues.push(`Age ${age}: expected six activities`);
 if(age<24&&choices.some(a=>a.mechanic!=='caregiver'))issues.push(`Digital infant activity at ${age}`);
}
for(const a of pack.activities){
 if(a.steps.length!==3||a.variants.length!==3||a.steps.some(s=>!s.trim())||a.variants.some(s=>!s.trim()))issues.push(`Incomplete writing ${a.id}`);
 if(!a.materials||!a.offscreen||!a.safety.length)issues.push(`Missing caregiver context ${a.id}`);
}
for(const job of expected){
 const found=speech.jobs.filter(j=>j.id===job.id&&j.text===job.text);
 if(found.length!==1){issues.push(`Missing or stale speech ${job.id}`);continue;}
}
for(const job of [...speech.jobs,...music.jobs]){
 if(!/^assets\/audio\/age_pack\/[a-z0-9_]+\.(wav|m4a|mp3)$/.test(job.file)){issues.push(`Invalid path ${job.id}`);continue;}
 const file=path.join(root,job.file);if(!fs.existsSync(file)){issues.push(`Missing file ${job.id}`);continue;}
 const hash=createHash('sha256').update(fs.readFileSync(file)).digest('hex');if(hash!==job.sha256)issues.push(`Changed file ${job.id}`);
 if(!job.metrics||job.metrics.clippedSamples>0||job.metrics.peakDbfs==null||job.metrics.peakDbfs< -50)issues.push(`Invalid audio metrics ${job.id}`);
}
const pendingActivities=pack.activities.filter(a=>!hasApprovedReview(a,'reviewStatus')).length;
const pending=[...speech.jobs,...music.jobs].filter(j=>!hasApprovedReview(j)).length;
console.log(JSON.stringify({activities:pack.activities.length,caregiver:pack.activities.filter(a=>a.mechanic==='caregiver').length,digital:pack.activities.filter(a=>a.mechanic!=='caregiver').length,speech:speech.jobs.length,expectedSpeech:expected.length,music:music.jobs.length,pendingHumanActivityReview:pendingActivities,pendingHumanMediaReview:pending,issues},null,2));
if(issues.length||process.argv.includes('--release')&&(pending+pendingActivities))process.exitCode=1;
