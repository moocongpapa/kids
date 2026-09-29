import fs from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { createHash } from 'node:crypto';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const jobs=[
 {id:'age_06_06_song',activityId:'age_06_06',title:'우리 둘의 인사 노래',lyrics:'안녕 안녕 반가워\n네 소리를 기다려\n안녕 안녕 반가워\n우리 잠깐 쉬어요',prompt:'Create an original 30 second Korean caregiver demonstration song. Warm natural adult female voice, sparse soft acoustic plucks, gentle 70 BPM, clear Korean words, comfortable low dynamics, no children voices, no sound effects, no sudden changes. Allow pauses after each short line. Sing only these lyrics: 안녕 안녕 반가워. 네 소리를 기다려. 안녕 안녕 반가워. 우리 잠깐 쉬어요. End with a gentle fade, no loop.'},
 {id:'age_15_05_song',activityId:'age_15_05',title:'손 인사 행진곡',lyrics:'손을 살랑 안녕\n잠깐 쉬고 안녕\n앉아서도 안녕\n우리 이제 쉬어요',prompt:'Create an original 30 second Korean caregiver gesture-song demonstration, gentle 80 BPM. Warm natural adult female singing voice, light wooden percussion and soft marimba, no loud drums, no child voices, no abrupt changes. Pauses between lines for seated hand gestures. Only these Korean lyrics: 손을 살랑 안녕. 잠깐 쉬고 안녕. 앉아서도 안녕. 우리 이제 쉬어요. Finish naturally, not a loop.'},
];
if(!process.argv.includes('--adult-preview')){console.log(JSON.stringify({mode:'dry-run',jobs:jobs.length}));process.exit(0);}
const env=await fs.readFile(path.join(root,'.env'),'utf8');
const key=process.env.GEMINI_API_KEY||env.match(/^\s*(?:export\s+)?GEMINI_API_KEY\s*=\s*(.*?)\s*$/m)?.[1].replace(/^(['"])(.*)\1$/,'$2');
if(!key)throw new Error('Local GEMINI_API_KEY is missing');
const file=path.join(root,'assets/content/age_music_manifest.json');
const manifest=existsSync(file)?JSON.parse(await fs.readFile(file)):{status:'NEEDS_HUMAN_REVIEW',notice:'Adult preview only. Lyrics, sound level and child-app rights need review.',jobs:[]};
for(const job of jobs){
 if(manifest.jobs.some(j=>j.id===job.id))continue;
 console.log('Generating',job.id);
 const r=await fetch('https://generativelanguage.googleapis.com/v1beta/interactions',{method:'POST',headers:{'content-type':'application/json','x-goog-api-key':key},body:JSON.stringify({model:'lyria-3-clip-preview',input:job.prompt}),signal:AbortSignal.timeout(180000)});
 if(!r.ok)throw new Error(`Lyria HTTP ${r.status}`);
 const data=await r.json();const audio=data.steps?.filter(s=>s.type==='model_output').flatMap(s=>s.content??[]).find(c=>c.type==='audio'&&c.data);
 if(!audio)throw new Error('Lyria did not return audio');
 const mime=audio.mime_type??audio.mimeType??'audio/mpeg';
 if(!['audio/mpeg','audio/mp3'].includes(mime))throw new Error(`Unexpected audio type ${mime}`);
 const bytes=Buffer.from(audio.data,'base64');if(bytes.length<1000)throw new Error('Audio too short');
 const target=`assets/audio/age_pack/${job.id}.mp3`;
 await fs.writeFile(path.join(root,target),bytes,{flag:'wx'});
 manifest.jobs.push({...job,file:target,sha256:createHash('sha256').update(bytes).digest('hex'),model:'lyria-3-clip-preview',generatedAt:new Date().toISOString(),status:'NEEDS_HUMAN_REVIEW',humanReviewedAt:null,rightsEvidence:null});
 await fs.writeFile(file,JSON.stringify(manifest,null,2)+'\n');console.log('Saved',job.id,bytes.length);
}
