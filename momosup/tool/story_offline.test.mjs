import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {createStoryRequester,summarizeStoryRequests} from './story_request_client.mjs';
import {hash,writeJson,sceneSpecHash,sameNarration,rawVideoSpec} from './story_production_shared.mjs';
import {loadReviewedFilm,validateCatalog,replaceParentPreview} from './story_release_checks.mjs';
import {inspectProduction} from './story_preflight.mjs';

const video={model:'test-video',input:'private prompt',response_format:{type:'video'}};
function client(responses,extra={}){
  const events=[],waits=[];let calls=0;
  const request=createStoryRequester({getKey:async()=> 'private-key',fetchImpl:async()=>{
    calls++;const r=responses.shift();if(r instanceof Error)throw r;
    return {status:r.status,ok:r.status===200,json:async()=>r.body};
  },writeEvent:async e=>events.push(e),sleep:async ms=>waits.push(ms),...extra});
  return {request,events,waits,get calls(){return calls;}};
}
test('offline mode blocks key lookup, ledger and HTTP before any request',async()=>{
  const c=client([],{disabled:()=>true,getKey:async()=>{throw new Error('must not load secret');}});
  await assert.rejects(c.request(video),/STORY_API_DISABLED/);assert.equal(c.calls,0);assert.deepEqual(c.events,[]);
});
test('daily/spend caps stop immediately; only retry timing is recorded',async()=>{
  for(const [message,category] of [['daily quota: 20 requests per day; retry in 23h52m37s private-key','daily-quota'],['monthly spending cap private-key','project-spend-cap']]){
    const c=client([{status:429,body:{error:{message}}}]);
    await assert.rejects(c.request(video,{episode:'story_cloud',scene:'story_cloud_11',purpose:'video',private:'private-key'}));
    assert.equal(c.calls,1);assert.equal(c.events.at(-1).category,category);assert.deepEqual(c.waits,[]);
    assert.ok(!JSON.stringify(c.events).includes('private'));assert.ok(!JSON.stringify(c.events).includes('prompt'));
  }
});
test('HTTP 402 stops once with a payment category and no provider-message leak',async()=>{
  const providerMessage='Payment required: private-key private account billing details';
  const c=client([{status:402,body:{error:{message:providerMessage}}},{status:200,body:{steps:[]}}]);
  await assert.rejects(c.request({model:'test-review',input:'private prompt'},{episode:'story_swing',scene:'story_swing_11',purpose:'visual-review'}),error=>{
    assert.equal(error.message,'PROJECT_PAYMENT_REQUIRED: Gemini HTTP 402; check project billing before resuming.');
    assert.ok(!error.message.includes('private'));
    return true;
  });
  assert.equal(c.calls,1);
  assert.deepEqual(c.waits,[]);
  assert.equal(c.events.at(-1).category,'payment-required');
  assert.equal(c.events.at(-1).httpStatus,402);
  assert.ok(!JSON.stringify(c.events).includes('private'));
  assert.equal(summarizeStoryRequests(c.events).unknown,0);
});
test('transient retries count against the per-run video budget',async()=>{
  const c=client([{status:503,body:{}},{status:200,body:{steps:[]}}],{maxVideoRequests:1});
  await assert.rejects(c.request(video),/RUN_VIDEO_REQUEST_LIMIT/);assert.equal(c.calls,1);
});
test('success/retry counters retain numeric usage without provider content',async()=>{
  const c=client([{status:503,body:{}},{status:200,body:{steps:[{content:'private speech'}],usage:{total_tokens:12,secret:'private-key'}}}]);
  await c.request(video);assert.equal(c.calls,2);assert.equal(c.events.filter(e=>e.event==='started').length,2);
  assert.deepEqual(c.events.at(-1).usage,{total_tokens:12});assert.equal(c.events[0].requestId,c.events[2].requestId);
  assert.ok(!JSON.stringify(c.events).includes('private'));
});
test('ambiguous network failure is not automatically resubmitted',async()=>{
  const c=client([new Error('private-key')]);await assert.rejects(c.request(video),/OUTCOME_UNKNOWN/);
  assert.equal(c.calls,1);assert.equal(c.events.at(-1).category,'network-unknown');assert.ok(!JSON.stringify(c.events).includes('private-key'));
  assert.equal(summarizeStoryRequests(c.events).unknown,1);
});
test('an unreadable successful response remains unknown at the next preflight',async()=>{
  const c=client([{status:200,body:null}]);
  await assert.rejects(c.request(video),/STORY_RESPONSE_UNKNOWN/);
  assert.equal(c.calls,1);assert.equal(summarizeStoryRequests(c.events).unknown,1);
});
test('ledger failure blocks a billable call',async()=>{
  const c=client([],{writeEvent:async()=>{throw new Error('disk unavailable');}});
  await assert.rejects(c.request(video),/disk unavailable/);assert.equal(c.calls,0);
});
test('a successful response survives ledger failure and blocks further requests',async()=>{
  let rows=0;const warnings=[];
  const c=client([{status:200,body:{steps:[{media:'private media'}]}}],{writeEvent:async()=>{if(++rows>1)throw new Error('disk full');},warn:v=>warnings.push(v)});
  assert.equal((await c.request(video)).steps[0].media,'private media');
  await assert.rejects(c.request(video),/STORY_LEDGER_FAILED/);assert.equal(c.calls,1);
  assert.equal(warnings.length,1);assert.ok(!warnings[0].includes('private'));
});
test('speech matching preserves names, instructions and turn ownership',()=>{
  assert.ok(sameNarration('연못에 달이 없어졌어.','연못의 달이 없어졌어.'));
  for(const [a,b] of [['누리야, 내 차례야.','누리야, 네 차례야.'],['두리가 왔어요.','누리가 왔어요.'],['얼음과 함께.','어른과 함께.'],['연못의 별.','연못의 달.']])assert.equal(sameNarration(a,b),false);
});
test('legacy raw provenance requires the exact reviewed source and completed scene',()=>{
  const scene={text:'누리가 왔어요.',visual:'Nuri arrives.',targetSeconds:15};
  const raw=Buffer.from('old provider take'),encoded=Buffer.from('reviewed encoded scene');
  const record={...scene,specSha256:sceneSpecHash(scene),sourceVideoSha256:hash(raw),sha256:hash(encoded),review:{passed:true,transcript:{transcript:scene.text,music:false,abruptNoise:false},visual:{animated:true,unsafeOrFrightening:false,majorCharacterDeformation:false,sceneMatches:true}}};
  const input={scene,raw,encoded,record};
  assert.equal(rawVideoSpec(input),record.specSha256,'older reviews need no newer prompt or nested hash fields');
  assert.equal(rawVideoSpec({...input,record:null}),null);
  assert.equal(rawVideoSpec({...input,raw:Buffer.from('unknown replacement')}),null);
  assert.equal(rawVideoSpec({...input,encoded:Buffer.from('changed final')}),null);
  assert.equal(rawVideoSpec({...input,record:{...record,review:{...record.review,passed:false}}}),null);
  assert.equal(rawVideoSpec({...input,scene:{...scene,text:'두리가 왔어요.'}}),null);
  assert.equal(rawVideoSpec({scene,raw,prompt:{specSha256:sceneSpecHash(scene)}}),record.specSha256);
});
test('generator preserves unknown raw before any request and retains historical provenance during recheck',async t=>{
  const root=await fs.mkdtemp(path.join(os.tmpdir(),'kids-provenance-test-'));
  t.after(()=>fs.rm(root,{recursive:true,force:true}));
  const tool=path.join(root,'tool');await fs.mkdir(tool);
  for(const file of ['generate_story_pilot.mjs','story_production_shared.mjs'])await fs.copyFile(new URL(file,import.meta.url),path.join(tool,file));
  const scene={text:'누리가 왔어요.',visual:'Nuri arrives.',targetSeconds:15},id='story_fixture_00';
  await fs.writeFile(path.join(tool,'story_pilot_scripts.mjs'),'export const episodes='+JSON.stringify([{id:'story_fixture',scenes:[scene]}])+';');
  // No real requester, key lookup, network or media process exists in this fixture.
  await fs.writeFile(path.join(tool,'story_api.mjs'),`import fs from 'node:fs/promises'; export const root=${JSON.stringify(root)}; export const configureStoryRequests=()=>{}; export const content=()=>[]; export async function request(){await fs.writeFile(root+'/request-attempted','yes');throw new Error('FIXTURE_REQUEST_BLOCKED');}`);
  await fs.writeFile(path.join(tool,'generate_gemini_tts.mjs'),'export const buildPayload=()=>({input:[{content:[{annotations:[{}]}]}]}); export const extractWav=()=>null;');
  const images=path.join(root,'assets/images');await fs.mkdir(images,{recursive:true});
  for(const name of ['momo','duri','nuri'])await fs.writeFile(path.join(images,name+'.png'),'fixture');
  const dir=path.join(root,'production/story_work/story_fixture');await fs.mkdir(dir,{recursive:true});
  const stem=path.join(dir,id),raw=Buffer.from('preserved legacy raw');await fs.writeFile(stem+'_raw.mp4',raw);
  const run=(extra=[])=>spawnSync(process.execPath,[path.join(tool,'generate_story_pilot.mjs'),'--generate','--episode=story_fixture','--stop-on-scene-rejection',...extra],{encoding:'utf8',env:{STORY_API_DISABLED:'1',PATH:'/usr/bin:/bin'}});
  const blocked=run();
  assert.equal(blocked.status,1);assert.match(blocked.stderr,/STORY_RAW_PROVENANCE_UNKNOWN/);
  assert.match(blocked.stderr,/--repair-scenes=story_fixture_00/);
  assert.deepEqual(await fs.readFile(stem+'_raw.mp4'),raw);
  await assert.rejects(fs.access(path.join(root,'request-attempted')),{code:'ENOENT'});
  await assert.rejects(fs.access(stem+'_video_prompt.json'),{code:'ENOENT'});
  const encoded=Buffer.from('reviewed encoded scene');await fs.writeFile(stem+'.mp4',encoded);
  await writeJson(stem+'.json',{...scene,id,specSha256:sceneSpecHash(scene),sourceVideoSha256:hash(raw),sha256:hash(encoded),review:{passed:true,transcript:{transcript:scene.text,music:false,abruptNoise:false},visual:{animated:true,unsafeOrFrightening:false,majorCharacterDeformation:false,sceneMatches:true}}});
  const recheck=run(['--recheck-scenes='+id]);
  assert.equal(recheck.status,1);assert.match(recheck.stderr,/FIXTURE_REQUEST_BLOCKED/);
  assert.doesNotMatch(recheck.stderr,/STORY_RAW_PROVENANCE_UNKNOWN/);
  assert.deepEqual(await fs.readFile(stem+'_raw.mp4'),raw);
  assert.ok((await fs.readdir(dir)).some(name=>name.startsWith(id+'.before-recheck-')&&name.endsWith('.json')));
});

async function fixture(t){
  const root=await fs.mkdtemp(path.join(os.tmpdir(),'kids-release-test-'));t.after(()=>fs.rm(root,{recursive:true,force:true}));
  const e={id:'story_fixture',title:'숲 이야기',minAgeMonths:24,maxAgeMonths:35,theme:'마음',scenes:[{text:'누리가 왔어요.',visual:'Nuri arrives.',targetSeconds:15}]};
  const asset=async(ext,body)=>{const file='assets/stories/story_fixture'+ext;await fs.mkdir(path.join(root,'assets/stories'),{recursive:true});await fs.writeFile(path.join(root,file),body);return [file,hash(body)];};
  const [videoAsset,sha256]=await asset('.mp4','video'),[posterAsset,posterSha256]=await asset('.jpg','poster');
  const [titleAudioAsset,title]=await asset('_title.m4a','voice'),[musicAsset,music]=await asset('_music.m4a','music');
  const finalAudioReview={passed:true,titleReview:{transcript:e.title,music:false,abruptNoise:false},musicReview:{voice:false,abruptNoise:false}};
  const item={...e,status:'APPLIED_ON_OWNER_REQUEST',durationSeconds:15,videoAsset,posterAsset,posterSha256,titleAudioAsset,musicAsset,sha256,finalAudioReview,scenes:[{...e.scenes[0],id:e.id+'_00',seconds:15,specSha256:sceneSpecHash(e.scenes[0]),review:{passed:true,transcript:{transcript:e.scenes[0].text,music:false,abruptNoise:false},visual:{animated:true,unsafeOrFrightening:false,majorCharacterDeformation:false,sceneMatches:true}}}]};
  const dir=path.join(root,'production/story_pilot');
  await writeJson(path.join(dir,e.id+'.json'),item);
  await writeJson(path.join(dir,e.id+'.audio.json'),{episode:e.id,title:e.title,titleAudioAsset,musicAsset,assetHashes:{title,music},finalAudioReview});
  await writeJson(path.join(dir,e.id+'.film_review.json'),{passed:true,sha256,review:{watchedThroughSeconds:15,plotCoherent:true,narrationClear:true,themeFocused:true,endingComplete:true,issues:[]}});
  return {root,e,item,visual:{publishBlocked:true,reviewedFilms:[{id:e.id,sha256}],requiredCorrections:[]},dir};
}
test('reviewed full film can be parent-only while other films are blocked',async t=>{
  const f=await fixture(t);assert.equal((await loadReviewedFilm(f.root,f.e,f.visual)).sha256,f.item.sha256);
});
test('replacing music after review is blocked even with passed flags',async t=>{
  const f=await fixture(t);await fs.writeFile(path.join(f.root,f.item.musicAsset),'different score');
  await assert.rejects(loadReviewedFilm(f.root,f.e,f.visual),/Changed reviewed asset/);
});
test('poster and derived music must match their reviewed bytes',async t=>{
  const f=await fixture(t);
  await fs.writeFile(path.join(f.root,f.item.posterAsset),'new poster');
  await assert.rejects(loadReviewedFilm(f.root,f.e,f.visual),/Changed reviewed asset/);
  await fs.writeFile(path.join(f.root,f.item.posterAsset),'poster');
  const loopAsset='assets/stories/story_fixture_loop.m4a';
  await fs.writeFile(path.join(f.root,loopAsset),'loop');
  await writeJson(path.join(f.dir,f.e.id+'.editing.json'),{episode:f.e.id,sourceVideoSha256:f.item.sha256,sourceMusicSha256:hash('music'),transform:{kind:'loop-crossfade-v1'},technicalReview:{passed:true,loopDecoded:true,loopPeakDb:-13},loopAsset,loopSha256:hash('loop')});
  assert.equal((await loadReviewedFilm(f.root,f.e,f.visual)).musicAsset,loopAsset);
  await fs.writeFile(path.join(f.root,loopAsset),'changed loop');
  await assert.rejects(loadReviewedFilm(f.root,f.e,f.visual),/Changed reviewed asset/);
});
test('changing script cannot reuse previous scene/full-film approval',async t=>{
  const f=await fixture(t);f.e.scenes[0].text='두리가 왔어요.';
  await assert.rejects(loadReviewedFilm(f.root,f.e,f.visual),/Stale\/unreviewed scene/);
});
test('a false passed flag or unresolved visual correction cannot publish',async t=>{
  const f=await fixture(t);f.visual.requiredCorrections=[{id:f.e.id+'_00'}];
  await assert.rejects(loadReviewedFilm(f.root,f.e,f.visual),/Visual correction/);
  f.visual.requiredCorrections=[];
  await writeJson(path.join(f.dir,f.e.id+'.film_review.json'),{passed:true,sha256:f.item.sha256,review:{plotCoherent:true,narrationClear:true,themeFocused:true,endingComplete:true,issues:[]}});
  await assert.rejects(loadReviewedFilm(f.root,f.e,f.visual),/Full-film review/);
});
test('partial child release and missing asset hashes are rejected',async()=>{
  assert.throws(()=>validateCatalog({productionStatus:'COMPLETE',episodes:[{}],previews:[]},[{id:'one'},{id:'two'},{id:'three'}]),/Partial child/);
  assert.throws(()=>validateCatalog({episodes:[],previews:[{id:'one',status:'PRODUCTION_PREVIEW',automatedReviewPassed:true,minAgeMonths:24,maxAgeMonths:35,durationSeconds:15,videoAsset:'assets/stories/a.mp4'}]},[{id:'one',minAgeMonths:24,maxAgeMonths:35}]),/Missing asset\/hash/);
});

test('successive parent preview upgrades preserve completed siblings and do not publish or invent human review',()=>{
  const cloud={id:'story_cloud',durationSeconds:183.04,status:'PRODUCTION_PREVIEW',fullFilmPreview:true,videoAsset:'assets/stories/story_cloud.mp4',musicAsset:'assets/stories/story_cloud_loop.m4a',humanReviewedAt:null,note:'Entire cloud film; human and native review pending.',assetHashes:{'assets/stories/story_cloud.mp4':'reviewed-cloud-hash'},localAudioEdit:{kind:'loop-crossfade-v1'}};
  const swing={id:'story_swing',durationSeconds:47,status:'PRODUCTION_PREVIEW',humanReviewedAt:null,note:'Opening swing scenes only.'};
  const moon={id:'story_moon',durationSeconds:47,status:'PRODUCTION_PREVIEW',humanReviewedAt:null,note:'Opening moon scenes only.'};
  const original={version:'existing',productionStatus:'IN_PROGRESS',episodes:[],previews:[cloud,swing,moon]};
  const snapshot=structuredClone(original);
  const fullSwing={...swing,durationSeconds:301,fullFilmPreview:true,note:'Entire swing film; human and native review pending.'};
  const first=replaceParentPreview(original,'story_swing',fullSwing);
  assert.deepEqual(first.previews,[cloud,fullSwing,moon]);
  assert.deepEqual(original,snapshot,'packaging must not mutate the source catalog');
  const fullMoon={...moon,durationSeconds:303,fullFilmPreview:true,note:'Entire moon film; human and native review pending.'};
  const second=replaceParentPreview(first,'story_moon',fullMoon);
  assert.deepEqual(second.previews,[cloud,fullSwing,fullMoon]);
  assert.deepEqual(second.episodes,[],'adult integration must not publish child episodes');
  assert.ok(second.previews.every(item=>item.status==='PRODUCTION_PREVIEW'&&item.humanReviewedAt===null));
  assert.equal(second.productionStatus,'IN_PROGRESS');
});

test('preflight preserves a pending edited take and blocks payment until a later successful request',async t=>{
  const f=await fixture(t),id=f.e.id+'_00';
  await fs.rm(path.join(f.dir,f.e.id+'.json'));
  const dir=path.join(f.root,'production/story_work',f.e.id),stem=path.join(dir,id);
  await fs.mkdir(dir,{recursive:true});
  await fs.writeFile(stem+'_raw.mp4','edited-provider-take');
  await fs.writeFile(stem+'.wav','reviewed-narration');
  await writeJson(stem+'_video_prompt.json',{specSha256:sceneSpecHash(f.e.scenes[0])});
  await writeJson(stem+'_clip_edit.json',{outputSha256:hash('edited-provider-take'),humanReviewedAt:null});
  await writeJson(stem+'_narration_review.json',{sha256:hash('reviewed-narration'),review:{transcript:f.e.scenes[0].text,music:false,abruptNoise:false}});
  await writeJson(path.join(f.dir,'visual_review.json'),{publishBlocked:true,requiredCorrections:[]});
  await writeJson(path.join(f.root,'assets/content/story_catalog.json'),{episodes:[],previews:[]});
  const ledger=path.join(f.root,'production/story_work/requests.jsonl');
  const events=[{requestId:'review-1',attempt:1,event:'started',model:'test-review'},{requestId:'review-1',attempt:1,event:'failed',model:'test-review',httpStatus:402,category:'http-error',time:'2026-10-06T13:23:55Z'}];
  await fs.writeFile(ledger,events.map(e=>JSON.stringify(e)).join('\n')+'\n');
  const blocked=await inspectProduction(f.root,[f.e]);
  assert.equal(blocked.apiRequests,0);
  assert.equal(blocked.filesReadyToResume,true);
  assert.equal(blocked.readyToResume,false);
  assert.equal(blocked.apiBlockers[0].category,'payment-required');
  assert.equal(blocked.scenes[0].state,'PENDING_REVIEW');
  assert.equal(blocked.scenes[0].edited,true);
  assert.equal(blocked.summary.pendingReviewVideos,1);
  assert.equal(blocked.summary.missingVideos,0);
  assert.ok(blocked.nextCommands.every(c=>c.includes('--stop-on-scene-rejection')));
  assert.ok(blocked.nextCommands.every(c=>!c.includes('--repair-scenes=')));
  await fs.appendFile(ledger,JSON.stringify({requestId:'review-2',attempt:1,event:'failed',model:'test-review',httpStatus:503})+'\n');
  assert.equal((await inspectProduction(f.root,[f.e])).readyToResume,false);
  await fs.appendFile(ledger,JSON.stringify({requestId:'review-3',attempt:1,event:'succeeded',model:'test-review',httpStatus:200})+'\n');
  const resumed=await inspectProduction(f.root,[f.e]);
  assert.equal(resumed.readyToResume,true);
  assert.deepEqual(resumed.apiBlockers,[]);
  await fs.writeFile(stem+'_raw.mp4','changed-unverified-edit');
  const stale=await inspectProduction(f.root,[f.e]);
  assert.equal(stale.filesReadyToResume,false);
  assert.equal(stale.scenes[0].state,'RAW_INVALID');
  assert.equal(stale.summary.pendingReviewVideos,0);
  assert.equal(stale.summary.invalidRawVideos,1);
  await fs.writeFile(stem+'_raw.mp4','edited-provider-take');
  await fs.rm(stem+'_video_prompt.json');
  const unverified=await inspectProduction(f.root,[f.e]);
  assert.equal(unverified.filesReadyToResume,false);
  assert.equal(unverified.scenes[0].state,'RAW_UNVERIFIED');
  assert.equal(unverified.summary.unverifiedRawVideos,1);
  assert.equal(unverified.summary.missingVideos,0);
});
