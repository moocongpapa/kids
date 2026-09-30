import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {episodes} from './story_pilot_scripts.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const ffmpeg=process.env.STORY_FFMPEG ?? 'ffmpeg';
const hash=b=>createHash('sha256').update(b).digest('hex');
const args=process.argv.slice(2);
const preview=args.includes('--previews'), publish=args.includes('--publish');
if(preview===publish)throw new Error('Choose --previews or --publish. Publishing requires all three complete, reviewed episodes.');
if(publish){
 const review=JSON.parse(await fs.readFile(path.join(root,'production/story_pilot/visual_review.json')));
 if(review.publishBlocked)throw new Error('Scene continuity corrections and final full-film inspection are still required.');
}
function ff(a){const r=spawnSync(ffmpeg,['-hide_banner','-loglevel','error','-y',...a],{encoding:'utf8'});if(r.status!==0)throw new Error(r.stderr.slice(-800));}
const packed=[];
for(const e of episodes){
 let item;
 if(preview){
  const dir=path.join(root,'production/story_work',e.id);
  const records=[];
  for(let i=0;i<3;i++){
   const id=`${e.id}_${String(i).padStart(2,'0')}`;
   const record=JSON.parse(await fs.readFile(path.join(dir,id+'.json')));
   const bytes=await fs.readFile(path.join(dir,id+'.mp4'));
   if(!record.review?.passed||hash(bytes)!==record.sha256)throw new Error('Unverified scene '+id);
   records.push(record);
  }
  const concat=path.join(dir,'preview.txt');
  await fs.writeFile(concat,records.map(r=>`file '${path.join(dir,r.id+'.mp4')}'`).join('\n'));
  const videoAsset=`assets/stories/${e.id}_preview.mp4`, titleAudioAsset=`assets/stories/${e.id}_preview_intro.m4a`;
  ff(['-f','concat','-safe','0','-i',concat,'-c','copy','-movflags','+faststart',path.join(root,videoAsset)]);
  ff(['-i',path.join(dir,records[0].id+'.mp4'),'-vn','-c:a','copy',path.join(root,titleAudioAsset)]);
  item={...e,scenes:records,durationSeconds:records.reduce((n,r)=>n+r.seconds,0),
   videoAsset,titleAudioAsset,posterAsset:`assets/stories/${e.id}.jpg`,musicAsset:'',
   status:'PRODUCTION_PREVIEW',automatedReviewPassed:true,humanReviewedAt:null,
   note:'Opening three scenes only. The complete film and new score are pending the Google project monthly spend cap. Available only in the parent preview.',
   videoModel:'gemini-omni-1.1-flash',voiceModel:'gemini-3.8-flash-tts'};
  await fs.writeFile(path.join(root,'production/story_pilot',e.id+'.preview.json'),JSON.stringify(item,null,2)+'\n');
 }else{
  item=JSON.parse(await fs.readFile(path.join(root,'production/story_pilot',e.id+'.json')));
  if(item.scenes.length!==e.scenes.length||item.scenes.some(s=>!s.review?.passed)||!item.finalAudioReview?.passed)
   throw new Error('Incomplete production/review '+e.id);
  const bytes=await fs.readFile(path.join(root,item.videoAsset));
  if(hash(bytes)!==item.sha256)throw new Error('Changed video '+e.id);
  item.automatedReviewPassed=true;
 }
 const {scenes,palette,musicPrompt,...metadata}=item;
 metadata.assetHashes={};
 for(const field of ['videoAsset','posterAsset','titleAudioAsset','musicAsset']){
  if(metadata[field])metadata.assetHashes[metadata[field]]=hash(await fs.readFile(path.join(root,metadata[field])));
 }
 packed.push(metadata);
 console.log(item.id,item.durationSeconds,'seconds',item.status);
}
const catalog={version:'story-pilot-2026-09-30',productionStatus:preview?'AWAITING_GEMINI_PROJECT_SPEND_CAP':'COMPLETE',episodes:preview?[]:packed,previews:preview?packed:[]};
await fs.writeFile(path.join(root,'assets/content/story_catalog.json'),JSON.stringify(catalog,null,2)+'\n');
