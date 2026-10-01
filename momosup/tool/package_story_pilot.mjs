import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {episodes} from './story_pilot_scripts.mjs';
import {loadReviewedFilm,validateCatalog} from './story_release_checks.mjs';
import {writeJson} from './story_production_shared.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const ffmpeg=process.env.STORY_FFMPEG ?? 'ffmpeg';
const hash=b=>createHash('sha256').update(b).digest('hex');
const args=process.argv.slice(2);
const preview=args.includes('--previews'), publish=args.includes('--publish');
const parentId=args.find(a=>a.startsWith('--reviewed-parent-preview='))?.split('=')[1];
if(Number(preview)+Number(publish)+Number(Boolean(parentId))!==1)throw new Error('Choose --previews, --publish, or --reviewed-parent-preview=<episode>. Child publication requires all three reviewed films.');
if(parentId&&!episodes.some(e=>e.id===parentId))throw new Error('Unknown parent preview episode');
const visualReview=publish||parentId?JSON.parse(await fs.readFile(path.join(root,'production/story_pilot/visual_review.json'))):null;
if(publish&&visualReview.publishBlocked!==false)throw new Error('Scene continuity corrections and final full-film inspection are still required.');
function ff(a){const r=spawnSync(ffmpeg,['-hide_banner','-loglevel','error','-y',...a],{encoding:'utf8'});if(r.status!==0)throw new Error(r.stderr.slice(-800));}
const packed=[];
for(const e of episodes.filter(e=>!parentId||e.id===parentId)){
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
   note:'Opening three scenes only. Full films remain in production. Available only in the parent preview.',
   videoModel:'gemini-omni-1.1-flash',voiceModel:'gemini-3.8-flash-tts'};
  await fs.writeFile(path.join(root,'production/story_pilot',e.id+'.preview.json'),JSON.stringify(item,null,2)+'\n');
 }else{
  item=await loadReviewedFilm(root,e,visualReview);
 }
 const {scenes,palette,musicPrompt,...metadata}=item;
 metadata.togetherActivity=e.togetherActivity;
 metadata.assetHashes={};
 for(const field of ['videoAsset','posterAsset','titleAudioAsset','musicAsset']){
  if(metadata[field])metadata.assetHashes[metadata[field]]=hash(await fs.readFile(path.join(root,metadata[field])));
 }
 if(parentId){
  metadata.status='PRODUCTION_PREVIEW';
  metadata.fullFilmPreview=true;
  metadata.note='Complete film, title voice and music reviewed; available in the parent preview while the three-film child release remains in production. Native playback and family observation are pending.';
 }
 packed.push(metadata);
 console.log(item.id,item.durationSeconds,'seconds',metadata.status);
}
let catalog;
if(parentId){
 catalog=JSON.parse(await fs.readFile(path.join(root,'assets/content/story_catalog.json')));
 if(!catalog.previews?.some(e=>e.id===parentId))throw new Error('Parent preview must already exist');
 catalog.previews=catalog.previews.map(e=>e.id===parentId?packed[0]:{...e,note:'Opening three scenes only. Remaining video production is waiting for the daily video quota; title voice and music are prepared. Available only in the parent preview.'});
 const progress=JSON.parse(await fs.readFile(path.join(root,'production/story_pilot/progress.json')));
 catalog.productionStatus=progress.status;
 catalog.version='story-pilot-'+new Date().toISOString().slice(0,10)+'-parent-review';
}else{
 catalog={version:'story-pilot-2026-09-30'+(publish?'-full':''),productionStatus:preview?'PRODUCTION_IN_PROGRESS':'COMPLETE',episodes:preview?[]:packed,previews:preview?packed:[]};
}
validateCatalog(catalog,episodes);
await writeJson(path.join(root,'assets/content/story_catalog.json'),catalog);
