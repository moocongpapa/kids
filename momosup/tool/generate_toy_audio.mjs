// Offline adult production only. No credentials or child data enter the app.
// APIs: https://ai.google.dev/gemini-api/docs/speech-generation
// https://ai.google.dev/gemini-api/docs/music-generation
import fs from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildPayload, extractWav } from './generate_gemini_tts.mjs';
import { jobs } from './toy_audio_jobs.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const sha=b=>createHash('sha256').update(b).digest('hex');
const target=path.join(root,'assets/content/toy_audio_manifest.json');
const args=process.argv.slice(2);
const python=args.find(a=>a.startsWith('--python='))?.slice(9) ?? 'python3';
if(!args.includes('--generate')) { console.log(JSON.stringify({mode:'dry-run',speech:jobs.filter(j=>j.kind==='speech').length,music:jobs.filter(j=>j.kind==='music').length}));process.exit(0); }
let key=process.env.GEMINI_API_KEY;
if(!key && existsSync(path.join(root,'.env'))) {
 const env=await fs.readFile(path.join(root,'.env'),'utf8');
 key=env.match(/^\s*(?:export\s+)?GEMINI_API_KEY\s*=\s*(.*?)\s*$/m)?.[1].replace(/^(['"])(.*)\1$/,'$2');
}
if(!key)throw new Error('Local GEMINI_API_KEY is missing');
const manifest=existsSync(target)?JSON.parse(await fs.readFile(target)):{version:'toy-audio-2026-09-30',applicationAuthorization:'Owner explicitly requested Gemini/Flow audio production and application in this task on 2026-09-30.',humanReviewedAt:null,notice:'Applied on the owner production/integration request after automated audio and transcript checks. No human listening or provider legal clearance is asserted.',jobs:[]};
await fs.mkdir(path.join(root,'production/audio_pending/toy_pack'),{recursive:true});
await fs.mkdir(path.join(root,'assets/audio/toy_pack'),{recursive:true});
async function save(){await fs.writeFile(target+'.partial',JSON.stringify(manifest,null,2)+'\n');await fs.rename(target+'.partial',target);}
async function request(payload){
 for(let attempt=0;attempt<4;attempt++){
  const r=await fetch('https://generativelanguage.googleapis.com/v1beta/interactions',{method:'POST',headers:{'content-type':'application/json','x-goog-api-key':key},body:JSON.stringify(payload),signal:AbortSignal.timeout(180000)});
  if(r.ok)return r.json();
  // Error bodies and headers can contain credentials; log only status/model.
  console.log(JSON.stringify({http:r.status,model:payload.model,attempt:attempt+1}));
  if(![429,500,502,503,504].includes(r.status)||attempt===3)throw new Error(`Generation HTTP ${r.status}`);
  await new Promise(r=>setTimeout(r,Math.min(30000,(attempt+1)*8000)));
 }
}
const content=d=>d.steps?.filter(s=>s.type==='model_output').flatMap(s=>s.content??[])??[];
function normalize(s){return s.normalize('NFC').replace(/[^\p{L}\p{N}]/gu,'');}
async function review(job, bytes, mime){
 const prompt=job.kind==='speech'
  ? 'Listen to this short Korean recording. Transcribe only words actually audible, without inventing or correcting anything. Return JSON only: {"transcript":string,"hasMusic":boolean,"hasAbruptNoise":boolean,"notes":string}. Do not put sound descriptions in transcript.'
  : 'Listen to this full music clip. Return JSON only: {"hasVoice":boolean,"hasAbruptNoise":boolean,"notes":string}. hasVoice includes any speech, singing, humming or vocal sounds. hasAbruptNoise means startling impacts, screams, sirens or glitches, not gentle instruments. Briefly describe the instruments and mood in notes.';
 const r=await request({model:'gemini-3.8-flash',input:[{type:'text',text:prompt},{type:'audio',data:bytes.toString('base64'),mime_type:mime}]});
 const text=content(r).filter(c=>c.type==='text').map(c=>c.text).join('');
 const result=JSON.parse(text.replace(/^```(?:json)?\s*/,'').replace(/\s*```$/,''));
 const passed=job.kind==='speech'?normalize(result.transcript??'')===normalize(job.text)&&result.hasMusic===false&&result.hasAbruptNoise===false:result.hasVoice===false&&result.hasAbruptNoise===false;
 return {...result,passed,model:'gemini-3.8-flash',checkedAt:new Date().toISOString()};
}
for(const job of jobs){
 const fingerprint=sha(JSON.stringify(job));
 let entry=manifest.jobs.find(j=>j.id===job.id);
 if(entry?.specSha256===fingerprint && entry.automatedReview?.passed && existsSync(path.join(root,entry.file)) && sha(await fs.readFile(path.join(root,entry.file)))===entry.sha256){console.log('Reusing',job.id);continue;}
 let success=false;
 for(let take=1;take<=2&&!success;take++){
  console.log('Generating',job.id,'take',take);
  const model=job.kind==='speech'?'gemini-3.8-flash-tts':'lyria-3-clip-preview';
  const payload=job.kind==='speech'?buildPayload(job,model):{model,input:job.prompt};
  if(job.kind==='speech')payload.input[0].content[0].annotations[0].style='Warm, gently playful adult Korean storyteller speaking naturally to a preschool child. Clear Korean, short conversational pacing, friendly curiosity, soft dynamics. No shouting, no singing, no music, no sound effects. Say exactly the provided words, no additions.';
  const response=await request(payload);
  const raw=job.kind==='speech'?extractWav(response):Buffer.from(content(response).find(c=>c.type==='audio')?.data??'','base64');
  if(raw.length<1000)throw new Error('Missing generated audio');
  const source=`production/audio_pending/toy_pack/${job.id}_${fingerprint.slice(0,8)}_${take}.${job.kind==='speech'?'wav':'mp3'}`;
  await fs.writeFile(path.join(root,source),raw);
  const file=`assets/audio/toy_pack/${job.id}.m4a`;
  const partial=path.join(root,'production/audio_pending/toy_pack',job.id+'.m4a');
  await fs.rm(partial,{force:true});
  const p=spawnSync(python,[path.join(root,'tool/prepare_toy_audio.py'),path.join(root,source),partial,job.kind],{encoding:'utf8'});
  if(p.status!==0) {console.log('Processing failed',job.id, p.stderr.slice(-600));if(take===2)throw new Error('Audio processing failed');continue;}
  const metrics=JSON.parse(p.stdout);
  // Review the final encoded asset, not just the generation prompt.
  const finalBytes=await fs.readFile(partial);
  const automatedReview=await review(job,finalBytes,'audio/mp4');
  entry={...job,specSha256:fingerprint,file,sha256:sha(finalBytes),source,sourceSha256:sha(raw),model,voice:job.kind==='speech'?'Kore':null,generatedAt:new Date().toISOString(),metrics,automatedReview,humanReviewedAt:null,status:automatedReview.passed?'APPLIED_ON_OWNER_REQUEST':'RETRY_REQUIRED'};
  manifest.jobs=manifest.jobs.filter(j=>j.id!==job.id);manifest.jobs.push(entry);await save();
  console.log(JSON.stringify({id:job.id,seconds:metrics.durationSeconds,review:automatedReview.passed,transcript:automatedReview.transcript,notes:automatedReview.notes}));
  if(automatedReview.passed){await fs.copyFile(partial,path.join(root,file));success=true;}
  await new Promise(r=>setTimeout(r,2500));
 }
 if(!success)throw new Error(`Automated review did not pass: ${job.id}`);
}
console.log('Completed',manifest.jobs.length,'assets. Human listening review remains explicitly unset.');
