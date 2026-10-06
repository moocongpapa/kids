// Offline only: no API import, key lookup or generation. Safe before every resume.
import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {episodes} from './story_pilot_scripts.mjs';
import {hash,readJson,writeJson,sceneSpecHash,narrationPassed,visualPassed,rawVideoSpec,verifyAsset} from './story_production_shared.mjs';
import {reviewedAudio,loadReviewedFilm,validateCatalog} from './story_release_checks.mjs';
import {summarizeStoryRequests} from './story_request_client.mjs';

export async function inspectProduction(root, episodeList = episodes) {
  const visual = await readJson(path.join(root,'production/story_pilot/visual_review.json'));
  const report={checkedAt:new Date().toISOString(),apiRequests:0,scenes:[],films:[],errors:[],apiBlockers:[],requests:{started:0,succeeded:0,failed:0,unknown:0,byModel:{}},nextCommands:[]};
  for(const e of episodeList){
    const dir=path.join(root,'production/story_work',e.id);
    const film={id:e.id,expectedScenes:e.scenes.length,reusableScenes:0,preparedNarration:0,audioReady:false,fullFilmReady:false};
    try{await reviewedAudio(root,e);film.audioReady=true;}catch(error){report.errors.push(error.message);}
    for(let i=0;i<e.scenes.length;i++){
      const s=e.scenes[i],id=e.id+'_'+String(i).padStart(2,'0'),stem=path.join(dir,id);
      const record=await readJson(stem+'.json');
      const encoded=await fs.readFile(stem+'.mp4').catch(()=>null);
      const speech=await fs.readFile(stem+'.wav').catch(()=>null);
      const review=await readJson(stem+'_narration_review.json');
      const voiceReview=review?.sha256===(speech&&hash(speech))?review.review:record?.sourceSpeechSha256===(speech&&hash(speech))?record.review?.transcript:null;
      const narrationReady=Boolean(speech&&narrationPassed(voiceReview,s.text));
      const correction=visual?.requiredCorrections?.find(c=>c.id===id);
      const reusable=Boolean(record&&encoded&&record.specSha256===sceneSpecHash(s)&&record.sha256===hash(encoded)&&record.review?.passed&&narrationPassed(record.review.transcript,s.text)&&visualPassed(record.review.visual)&&!correction);
      const raw=await fs.readFile(stem+'_raw.mp4').catch(error=>{if(error.code==='ENOENT')return null;throw error;});
      const prompt=await readJson(stem+'_video_prompt.json');
      const edit=await readJson(stem+'_clip_edit.json');
      const rawSpec=rawVideoSpec({scene:s,raw,prompt,record,encoded});
      const rawMatches=Boolean(raw?.length&&rawSpec===sceneSpecHash(s)&&narrationReady&&(!edit||edit.outputSha256===hash(raw)));
      const state=reusable?'REUSE':correction?'REPAIR_REQUIRED':rawMatches?'PENDING_REVIEW':raw?(prompt?.specSha256||record?.specSha256?'RAW_INVALID':'RAW_UNVERIFIED'):record?'REPAIR_REQUIRED':'MISSING_VIDEO';
      if(state==='RAW_INVALID')report.errors.push('Existing raw take needs inspection before reuse: '+id);
      if(state==='RAW_UNVERIFIED')report.errors.push('Existing raw take has no matching scene provenance: '+id);
      film.reusableScenes+=Number(reusable);film.preparedNarration+=Number(narrationReady);
      report.scenes.push({id,state,narrationReady,...(state==='PENDING_REVIEW'?{rawVideoSha256:hash(raw),edited:Boolean(edit),note:'Existing take preserved; visual review and encoding remain. No new video is required to review this take.'}:{}),...(correction?{reason:correction.reason}:{})});
      if(!narrationReady)report.errors.push('Narration needs preparation: '+id);
    }
    if(await readJson(path.join(root,'production/story_pilot',e.id+'.json'))){
      try{await loadReviewedFilm(root,e,visual);film.fullFilmReady=true;}catch(error){report.errors.push(error.message);}
    }
    const repairs=report.scenes.filter(s=>s.id.startsWith(e.id+'_')&&s.state==='REPAIR_REQUIRED').map(s=>s.id);
    if(film.reusableScenes<film.expectedScenes)report.nextCommands.push('node tool/generate_story_pilot.mjs --generate --episode='+e.id+' --max-video-requests=5 --stop-on-scene-rejection'+(repairs.length?' --repair-scenes='+repairs.join(','):''));
    report.films.push(film);
  }
  const catalog=await readJson(path.join(root,'assets/content/story_catalog.json'));
  try{
    validateCatalog(catalog,episodeList);
    for(const item of [...catalog.episodes,...catalog.previews])for(const field of ['videoAsset','posterAsset','titleAudioAsset','musicAsset'])if(item[field])await verifyAsset(root,item[field],item.assetHashes[item[field]]);
  }catch(error){report.errors.push(error.message);}
  const lines=(await fs.readFile(path.join(root,'production/story_work/requests.jsonl'),'utf8').catch(()=>'' )).trim().split('\n').filter(Boolean);
  const events=[];
  for(const line of lines){
    let r;try{r=JSON.parse(line);}catch{report.errors.push('Incomplete request ledger row');continue;}
    events.push(r);
  }
  report.requests=summarizeStoryRequests(events);
  if(report.requests.unknown)report.apiBlockers.push({category:'outcome-unknown',message:'Requests with unknown result require provider inspection before retrying.'});
  // A later failure does not erase an unpaid response. Only a subsequent successful
  // request is evidence that the provider accepted requests again; no probe is sent here.
  let payment=null;
  for(const event of events){
    if(event.event==='failed'&&(event.category==='payment-required'||event.httpStatus===402))payment=event;
    else if(event.event==='succeeded')payment=null;
  }
  if(payment)report.apiBlockers.push({category:'payment-required',httpStatus:402,model:payment.model,time:payment.time,message:'The latest payment-required response has no later successful request. Check project billing before manually resuming.'});
  report.summary={totalScenes:report.scenes.length,reusableScenes:report.scenes.filter(s=>s.state==='REUSE').length,missingVideos:report.scenes.filter(s=>s.state==='MISSING_VIDEO').length,pendingReviewVideos:report.scenes.filter(s=>s.state==='PENDING_REVIEW').length,invalidRawVideos:report.scenes.filter(s=>s.state==='RAW_INVALID').length,unverifiedRawVideos:report.scenes.filter(s=>s.state==='RAW_UNVERIFIED').length,repairs:report.scenes.filter(s=>s.state==='REPAIR_REQUIRED').length,preparedNarration:report.scenes.filter(s=>s.narrationReady).length,completeFilms:report.films.filter(f=>f.fullFilmReady).length};
  report.filesReadyToResume=report.errors.length===0;
  report.readyToResume=report.filesReadyToResume&&report.apiBlockers.length===0;
  report.requestLedgerNote='Records start with this tool update. Historical provider requests and account-wide daily usage cannot be reconstructed from this local ledger.';
  return report;
}

if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)){
  const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
  const report=await inspectProduction(root);
  if(process.argv.includes('--save'))await writeJson(path.join(root,'production/story_pilot/preflight.json'),report);
  console.log(JSON.stringify(process.argv.includes('--json')?report:{...report.summary,filesReadyToResume:report.filesReadyToResume,readyToResume:report.readyToResume,apiBlockers:report.apiBlockers,errors:report.errors,nextCommands:report.nextCommands,requests:report.requests},null,2));
  if(!report.readyToResume)process.exitCode=1;
}
