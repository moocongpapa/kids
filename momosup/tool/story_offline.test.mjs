import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import {createStoryRequester,summarizeStoryRequests} from './story_request_client.mjs';
import {hash,writeJson,sceneSpecHash,sameNarration} from './story_production_shared.mjs';
import {loadReviewedFilm,validateCatalog} from './story_release_checks.mjs';

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
