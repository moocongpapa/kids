import fs from 'node:fs/promises';
import {existsSync} from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {episodes} from './story_pilot_scripts.mjs';
import {request,content,root,configureStoryRequests} from './story_api.mjs';
import {hash,visualStyle,sceneSpecHash,normalize,sameNarration,narrationPassed,visualPassed,rawVideoSpec,readJson,writeJson} from './story_production_shared.mjs';
import {buildPayload,extractWav} from './generate_gemini_tts.mjs';
const args=process.argv.slice(2), only=args.find(x=>x.startsWith('--episode='))?.slice(10);
const repairIds=new Set((args.find(x=>x.startsWith('--repair-scenes='))?.slice(16)??'').split(',').filter(Boolean));
const recheckIds=new Set((args.find(x=>x.startsWith('--recheck-scenes='))?.slice(17)??'').split(',').filter(Boolean));
if(only&&!episodes.some(e=>e.id===only))throw new Error('Unknown episode');
if(args.includes('--audio-only')&&args.includes('--narration-only'))throw new Error('Choose one audio mode');
const selectedIds=new Set(episodes.filter(e=>!only||e.id===only).flatMap(e=>e.scenes.map((_,i)=>e.id+'_'+String(i).padStart(2,'0'))));
if([...repairIds,...recheckIds].some(id=>!selectedIds.has(id)))throw new Error('Unknown or unselected scene');
if([...repairIds].some(id=>recheckIds.has(id)))throw new Error('Choose repair or recheck for each scene');
configureStoryRequests({maxVideoRequests:Number(args.find(x=>x.startsWith('--max-video-requests='))?.split('=')[1]??20)});
if(!args.includes('--generate')){console.log(JSON.stringify(episodes.map(e=>({id:e.id,scenes:e.scenes.length,seconds:e.scenes.length*15,theme:e.theme}))));process.exit(0);}
const ffmpeg=process.env.STORY_FFMPEG ?? 'ffmpeg';
const work=path.join(root,'production/story_work');
const out=path.join(root,'assets/stories');
await fs.mkdir(work,{recursive:true});await fs.mkdir(out,{recursive:true});
function ff(a){const r=spawnSync(ffmpeg,['-hide_banner','-loglevel','error','-y',...a],{encoding:'utf8',maxBuffer:4e6});if(r.status!==0)throw new Error('FFmpeg: '+r.stderr.slice(-1200));}
function duration(file){const p=spawnSync(ffmpeg,['-hide_banner','-i',file],{encoding:'utf8'});const m=p.stderr.match(/Duration: (\d+):(\d+):([\d.]+)/);if(!m)throw new Error('No duration '+file);return Number(m[1])*3600+Number(m[2])*60+Number(m[3]);}
const characterRefs=Object.fromEntries(await Promise.all(['momo','duri','nuri'].map(async name=>[name,await fs.readFile(path.join(root,'assets/images',name+'.png'))])));
const sceneCast=(e,i)=>e.id==='story_swing'&&i===10?['momo','nuri']:e.id==='story_swing'&&i===11?['duri']:e.id==='story_cloud'?(i<3?['momo']:['momo','nuri']):e.id==='story_moon'?(i===2?[]:i<12?['momo','duri']:['momo','duri','nuri']):['momo','duri','nuri'];
function sceneContinuity(e,i){
 if(e.id==='story_cloud')return 'Continuity: '+(i>=2&&i<=8?'On one low flat mossy stone lie THREE LOOSE FLAT LEAVES, scattered horizontally. This is what remains after the previous collapse. Keep these separate leaves flat; no upright leaf structure or house exists yet. ':'The leaf house is a tiny handmade pile/tent of three loose broad leaves on one low flat mossy stone. It is not an architectural cottage: no doors, windows, walls or wooden frame. ')+(i>=2&&i<=6?'Momo is disappointed: drooping wings, downcast eyes, small downturned mouth. Momo must NOT smile, laugh, dance or look delighted yet. Nuri is gentle and concerned. ':'');
 if(e.id==='story_moon')return 'Continuity: indigo night throughout. A single full moon and its reflected light, no extra moons. '+(i===2?'POND INSERT SHOT ONLY: do not show any character, creature, animal, face, or portrait. The ONLY action is wind rippling the moon reflection. ':'')+'Any friends shown stay back on the broad dry path, never in water or leaning over the edge. ';
 if(e.id==='story_swing'&&i===10)return 'NEW CLOSE CAMERA ANGLE in the same warm forest clearing. Frame only Momo and Nuri on the waiting bench. Duri and the single swing are entirely OFFSCREEN; Duri is still taking his turn and must not appear walking nearby. Nuri wears one broad leaf, which gently slips toward its nose and flutters away after a tiny sneeze. Momo smiles. Never add a bear, another friend, or a swing behind them. ';
 if(e.id==='story_swing'&&i===11)return 'NEW CLOSE CAMERA ANGLE in the same warm forest clearing. Show Duri ALONE seated on the ONLY low wooden swing, exactly one seat and one pair of ropes. The waiting friends and their bench are offscreen. Use a medium full-body view with the ground visible. The seat is just below Duri knee height, so BOTH feet can rest FLAT on the ground without leaving the seat. Begin with tiny slow movement, then show both soles touching the earth and remaining firmly planted as this SAME seat becomes fully still. Duri stays seated, holding both ropes, and looks gently toward the offscreen friends. No other swings or bears anywhere in the background. ';
 return 'Continuity: only one low wooden swing with two ropes, in a warm forest clearing. Only one seated rider at a time, holding ropes, with waiting friends outside its arc. ';
}
function json(r){const s=content(r).filter(c=>c.type==='text').map(c=>c.text).join('');return JSON.parse(s.replace(/^```(?:json)?\s*/,'').replace(/\s*```$/,''));}
function speechPayload(text){
 const payload=buildPayload({kind:'speech',text});
 payload.input[0].content[0].annotations[0].style='Dry studio spoken voice only, absolutely no background music or sound effects. Warm expressive Korean adult storyteller. Natural clear Korean for young children, gentle character inflections, conversational pace with short breaths. Read exactly this text, articulating each word fully without contractions. Carefully distinguish the names: 모모 (mo-mo), 두리 (du-ri), 누리 (nu-ri). Never replace 누리 with 두리 or 노리, or 모모 with 모무. Also articulate 어른 (eo-reun, adult) clearly, never 얼음 (eol-eum, ice). These pronunciation instructions must not be spoken. No added words, no humming, no singing. Silence behind the voice.';
 return payload;
}
async function reviewNarration(speech,context={}){
 return json(await request({model:'gemini-3.8-flash',input:[{type:'text',text:'Listen carefully to the entire Korean narration. Transcribe exactly what is audibly said without correcting or inventing words. Music means separate audible instrumental accompaniment or actual singing/humming. Expressive speech with melodic intonation alone is NOT music. Abrupt noise means startling unwanted impacts, glitches or screams, not clear spoken exclamations. JSON only: {"transcript":string,"abruptNoise":boolean,"music":boolean,"soundNotes":string}.'},{type:'audio',mime_type:'audio/wav',data:speech.toString('base64')}]},{...context,purpose:'narration-review'}));
}
async function cachedNarrationReview(stem,speech){
 const file=stem+'_narration_review.json';
 if(!existsSync(file))return null;
 const cached=JSON.parse(await fs.readFile(file));
 return cached.sha256===hash(speech)?cached.review:null;
}
async function prepareSceneNarration(e,s,id,stem){
 for(let attempt=1;attempt<=3;attempt++){
  const context={episode:e.id,scene:id};
  if(!existsSync(stem+'.wav'))await fs.writeFile(stem+'.wav',extractWav(await request(speechPayload(s.text),{...context,purpose:'narration'})));
  const speech=await fs.readFile(stem+'.wav');
  let review=await cachedNarrationReview(stem,speech);
  if(!review&&existsSync(stem+'.json')){
   const scene=await readJson(stem+'.json');
   if(scene.sourceSpeechSha256===hash(speech))review=scene.review?.transcript;
  }
  // A known mismatch is discarded BEFORE requesting a new video.
  if(!review)review=await reviewNarration(speech,context);
  if(narrationPassed(review,s.text)){
   await writeJson(stem+'_narration_review.json',{sha256:hash(speech),text:s.text,review});
   return {speech,review};
  }
  console.log('NARRATION_REVIEW_REQUIRED',id,JSON.stringify(review));
  await fs.rename(stem+'.wav',stem+'.narration-rejected-'+Date.now()+'.wav');
  await fs.rm(stem+'_narration_review.json',{force:true});
 }
 throw new Error('Narration requires correction '+id);
}
async function prepareEpisodeNarration(e,dir){
 const records=[];
 for(let i=0;i<e.scenes.length;i++){
  const s=e.scenes[i],id=e.id+'_'+String(i).padStart(2,'0'),stem=path.join(dir,id);
  const {speech,review}=await prepareSceneNarration(e,s,id,stem);
  records.push({id,text:s.text,sourceSpeechSha256:hash(speech),voiceSeconds:duration(stem+'.wav'),narrationMatch:normalize(review.transcript)===normalize(s.text)?'exact':'allowedSpokenVariant',review});
  console.log('NARRATION_READY',id);
 }
 const result={episode:e.id,title:e.title,voiceModel:'gemini-3.8-flash-tts',reviewModel:'gemini-3.8-flash',createdAt:new Date().toISOString(),status:'AUTOMATED_NARRATION_REVIEW_PASSED',storage:'Raw WAV files remain in gitignored production/story_work; the app uses them only after video assembly and film review.',scenes:records};
 await writeJson(path.join(root,'production/story_pilot',e.id+'.narration.json'),result);
 console.log('NARRATION_COMPLETE',e.id,records.length);
}
async function prepareEpisodeAudio(e,dir){
 const musicPrompt=`Instrumental only, absolutely no voice, singing or humming. Gentle warm watercolor woodland animation underscore, about 30 seconds. ${e.id==='story_moon'?'Wonder and quiet curiosity, soft celesta and warm strings, no suspense, no ominous sounds.':e.id==='story_swing'?'Playful acoustic guitar and soft marimba, lightly bouncing but never busy.':'Tender soft acoustic guitar and warm felt piano, reassuring with a little gentle humor.'} No sharp impacts or sudden changes, sparse arrangement with plenty of room for Korean narration, soft ending.`;
 const previous=await readJson(path.join(root,'production/story_pilot',e.id+'.audio.json'));
 if(previous?.title===e.title&&previous.musicPrompt===musicPrompt&&previous.finalAudioReview?.passed&&normalize(previous.finalAudioReview.titleReview?.transcript??'')===normalize(e.title)){
  const title=await fs.readFile(path.join(root,previous.titleAudioAsset)).catch(()=>null);
  const music=await fs.readFile(path.join(root,previous.musicAsset)).catch(()=>null);
  if(title&&music&&hash(title)===previous.assetHashes?.title&&hash(music)===previous.assetHashes?.music&&previous.finalAudioReview.titleReview.music===false&&previous.finalAudioReview.titleReview.abruptNoise===false&&previous.finalAudioReview.musicReview.voice===false&&previous.finalAudioReview.musicReview.abruptNoise===false){
   console.log('Reuse reviewed title and music',e.id);return previous;
  }
 }
 if(previous&&previous.title!==e.title&&existsSync(path.join(dir,'title.wav')))await fs.rename(path.join(dir,'title.wav'),path.join(dir,'title.before-change-'+Date.now()+'.wav'));
 if(previous&&previous.musicPrompt!==musicPrompt&&existsSync(path.join(dir,'music.mp3')))await fs.rename(path.join(dir,'music.mp3'),path.join(dir,'music.before-change-'+Date.now()+'.mp3'));
 // Spoken title for the large, text-optional story selection screen.
 const titleRaw=path.join(dir,'title.wav');
 if(!existsSync(titleRaw))await fs.writeFile(titleRaw,extractWav(await request(speechPayload(e.title),{episode:e.id,purpose:'title'})));
 ff(['-i',titleRaw,'-af','loudnorm=I=-20:TP=-3:LRA=7','-c:a','aac','-b:a','64k','-ar','24000',path.join(out,e.id+'_title.m4a')]);
 const musicRaw=path.join(dir,'music.mp3');
 if(!existsSync(musicRaw)){const r=await request({model:'lyria-3-clip-preview',input:musicPrompt},{episode:e.id,purpose:'music'});const a=content(r).find(c=>c.type==='audio');if(!a?.data)throw new Error('No music');await fs.writeFile(musicRaw,Buffer.from(a.data,'base64'));}
 ff(['-i',musicRaw,'-af',`loudnorm=I=-25:TP=-5:LRA=6,afade=t=in:d=1,afade=t=out:st=${Math.max(0,duration(musicRaw)-2)}:d=2`,'-c:a','aac','-b:a','64k','-ar','24000',path.join(out,e.id+'_music.m4a')]);
 const titleBytes=await fs.readFile(path.join(out,e.id+'_title.m4a'));
 const musicBytes=await fs.readFile(path.join(out,e.id+'_music.m4a'));
 const titleReview=json(await request({model:'gemini-3.8-flash',input:[{type:'text',text:'Transcribe exactly the audible Korean words. JSON only: {"transcript":string,"abruptNoise":boolean,"music":boolean}.'},{type:'audio',mime_type:'audio/mp4',data:titleBytes.toString('base64')}]},{episode:e.id,purpose:'title-review'}));
 const musicReview=json(await request({model:'gemini-3.8-flash',input:[{type:'text',text:'Listen to the full clip. JSON only: {"voice":boolean,"abruptNoise":boolean,"notes":string}. Voice includes speech, singing and humming. Abrupt noise includes startling impacts, screams or glitches.'},{type:'audio',mime_type:'audio/mp4',data:musicBytes.toString('base64')}]},{episode:e.id,purpose:'music-review'}));
 const finalAudioReview={titleReview,musicReview,model:'gemini-3.8-flash',passed:normalize(titleReview.transcript??'')===normalize(e.title)&&titleReview.abruptNoise===false&&titleReview.music===false&&musicReview.voice===false&&musicReview.abruptNoise===false,checkedAt:new Date().toISOString()};
 const result={episode:e.id,title:e.title,finalAudioReview,musicPrompt,
  titleAudioAsset:`assets/stories/${e.id}_title.m4a`,musicAsset:`assets/stories/${e.id}_music.m4a`,
  assetHashes:{title:hash(titleBytes),music:hash(musicBytes)},
  voiceModel:'gemini-3.8-flash-tts',musicModel:'lyria-3-clip-preview',
  createdAt:new Date().toISOString(),status:finalAudioReview.passed?'AUTOMATED_AUDIO_REVIEW_PASSED':'REVIEW_REQUIRED'};
 await writeJson(path.join(root,'production/story_pilot',e.id+'.audio.json'),result);
 return result;
}
async function runEpisode(e){
 const dir=path.join(work,e.id);await fs.mkdir(dir,{recursive:true});
 if(args.includes('--narration-only')){
  await prepareEpisodeNarration(e,dir);
  return;
 }
 if(args.includes('--audio-only')){
  const audio=await prepareEpisodeAudio(e,dir);
  console.log('AUDIO_COMPLETE',e.id,audio.status);
  if(!audio.finalAudioReview.passed)throw new Error('Audio review required '+e.id);
  return;
 }
 const records=[];
 for(let i=0;i<e.scenes.length;i++){
  const s=e.scenes[i], id=`${e.id}_${String(i).padStart(2,'0')}`, stem=path.join(dir,id), specHash=sceneSpecHash(s);
  const attemptFile=stem+'_attempt.json';
  let attempt=existsSync(attemptFile)?JSON.parse(await fs.readFile(attemptFile)).attempt:1;
  const recordPath=stem+'.json';
  // Keep validated historical provenance available if an explicit recheck
  // archives a scene record that predates video prompt sidecars.
  const historicalScene=await readJson(recordPath);
  if(recheckIds.delete(id)){
   for(const suffix of ['.json','_review.json','_attempt.json']){
    if(existsSync(stem+suffix))await fs.rename(stem+suffix,stem+'.before-recheck-'+Date.now()+suffix);
   }
   attempt=1;
  }
  if(repairIds.delete(id)){
   for(const suffix of ['.json','_raw.mp4','_review.json','_attempt.json','_clip_edit.json']){
    if(existsSync(stem+suffix))await fs.rename(stem+suffix,stem+'.before-repair-'+Date.now()+suffix);
   }
   attempt=1;
  }
  if(existsSync(recordPath)){
   const old=JSON.parse(await fs.readFile(recordPath));
   if(old.specSha256===specHash&&old.review?.passed&&narrationPassed(old.review.transcript,s.text)&&visualPassed(old.review.visual)&&existsSync(stem+'.mp4')&&hash(await fs.readFile(stem+'.mp4'))===old.sha256){records.push(old);console.log('Reuse',id);continue;}
  }
  console.log('Producing',id);
  const videoPrompt=await readJson(stem+'_video_prompt.json');
  const existingRaw=existsSync(stem+'_raw.mp4')?await fs.readFile(stem+'_raw.mp4'):null;
  const sourceSpec=rawVideoSpec({scene:s,raw:existingRaw,prompt:videoPrompt,record:historicalScene,encoded:existsSync(stem+'.mp4')?await fs.readFile(stem+'.mp4'):null});
  // Missing provenance is not permission to review an old take against today's
  // script. Preserve it and stop before narration or any other billable call.
  if(existingRaw&&!sourceSpec)throw new Error('STORY_RAW_PROVENANCE_UNKNOWN: preserved '+id+'; inspect its source records or explicitly archive it with --repair-scenes='+id+' before generating a replacement.');
  if(existingRaw&&sourceSpec!==specHash){
   for(const suffix of ['_raw.mp4','_review.json','_video_prompt.json','_clip_edit.json'])if(existsSync(stem+suffix))await fs.rename(stem+suffix,stem+'.before-spec-change-'+Date.now()+suffix);
  }
  const {speech,review:voiceReview}=await prepareSceneNarration(e,s,id,stem);
  let video;
  if(existsSync(stem+'_raw.mp4')) video=await fs.readFile(stem+'_raw.mp4');
  else{
   const cast=sceneCast(e,i);
   const references=cast.map(name=>({type:'image',data:characterRefs[name].toString('base64'),mime_type:'image/png'}));
   let storyboardReference=null;
   if(e.id==='story_swing'&&i===11){
    const asset='production/story_pilot/duri_stop_keyframe.png';
    const bytes=await fs.readFile(path.join(root,asset));
    references.unshift({type:'image',data:bytes.toString('base64'),mime_type:'image/png'});
    storyboardReference={asset,sha256:hash(bytes)};
   }
   const previous=records.at(-1);
   let continuityReference=null;
   if(i>0&&cast.length&&!(e.id==='story_swing'&&[10,11].includes(i))&&previous?.id===`${e.id}_${String(i-1).padStart(2,'0')}`){
    const frame=path.join(dir,id+'_continuity.jpg');
    ff(['-sseof','-0.4','-i',path.join(dir,previous.id+'.mp4'),'-frames:v','1','-vf','scale=640:360','-q:v','3',frame]);
    const bytes=await fs.readFile(frame);
    references.unshift({type:'image',data:bytes.toString('base64'),mime_type:'image/jpeg'});
    continuityReference={previousScene:previous.id,sha256:hash(bytes)};
   }
   const retryFeedback=(await readJson(attemptFile))?.visualFeedback;
   const correctionHint=typeof retryFeedback==='string'?' The previous take was rejected for this visible problem: '+retryFeedback.slice(0,800)+'. Correct that problem while keeping the scene and cast described above. ':'';
   const referenceInstruction=storyboardReference?'The FIRST image is a purpose-drawn layout keyframe. Preserve its ONE low seat, ONE bear, two ropes and clearly grounded feet. Animate this same composition, with a tiny movement settling to complete stillness as both feet plant on the ground. Do not raise the seat or let the feet float. The remaining image is the isolated character identity reference. ':continuityReference?'The FIRST image is the ending of the previous shot. Continue the same location, lighting, actor appearance and prop states. You may choose a new camera angle and reframe the existing actors to show the current action; the previous image is not a fixed background layer. The remaining images are isolated character design references. ':'The supplied images are isolated CHARACTER REFERENCES, not starting frames. ';
   const prompt=visualStyle+'Palette: '+e.palette+'. Only include these characters when the scene requires them: '+(cast.join(', ')||'NONE')+'. Each named character is a SINGLE individual: never create duplicate birds, bears or cloud friends. In a closer shot, reframe the existing actor; do not retain that actor in the background and add a second copy in the foreground. Characters may remain offscreen when the shot focuses on their friends. '+referenceInstruction+'Do not recreate a group portrait or a white studio background. Place the action in the same lush mossy woodland with broad tree roots and softly layered trees. Create the specified setting and action. '+sceneContinuity(e,i)+'Scene: '+s.visual+correctionHint;
   const r=await request({model:'gemini-omni-1.1-flash',input:[...references,{type:'text',text:prompt}],response_format:{type:'video',resolution:'720p',aspect_ratio:'16:9'},store:false},{episode:e.id,scene:id,purpose:'video'});
   await writeJson(stem+'_video_prompt.json',{specSha256:specHash,prompt,continuityReference,storyboardReference,referenceAssets:cast.map(name=>'assets/images/'+name+'.png'),referenceSha256:cast.map(name=>hash(characterRefs[name]))});
   const v=content(r).find(c=>c.type==='video');if(!v?.data)throw new Error('No inline video '+id);
   video=Buffer.from(v.data,'base64');await fs.writeFile(stem+'_raw.mp4',video);
  }
  const sourceEdit=await readJson(stem+'_clip_edit.json');
  if(sourceEdit&&sourceEdit.outputSha256!==hash(video))throw new Error('Stale local video edit: '+id);
  const reviewPath=stem+'_review.json';let review;
  review=await readJson(reviewPath);
  if(review?.specSha256!==specHash||review?.sourceSpeechSha256!==hash(speech)||review?.sourceVideoSha256!==hash(video))review=null;
  if(!review){
   const transcript=voiceReview;
   const visual=json(await request({model:'gemini-3.8-flash',input:[{type:'text',text:'Review this original preschool animation. Expected scene: '+s.visual+' Allowed cast: '+(sceneCast(e,i).join(', ')||'NONE: water close-up without characters')+'. Momo is an olive-green bird, Duri a brown bear, Nuri a white cloud creature. No other character should appear. Lighting: '+e.palette+'. '+sceneContinuity(e,i)+'Return JSON only: {"animated":boolean,"unsafeOrFrightening":boolean,"majorCharacterDeformation":boolean,"sceneMatches":boolean,"notes":string}. Set sceneMatches false for an extra character, wrong time of day, wrong emotion/prop state that contradicts the plot, a static reference portrait instead of the described action, or a missing key action. Minor artistic differences are acceptable. A quiet scene can have subtle movement. Judge only visible content.'},{type:'video',mime_type:'video/mp4',data:video.toString('base64')}]},{episode:e.id,scene:id,purpose:'visual-review'}));
   review={specSha256:specHash,sourceSpeechSha256:hash(speech),sourceVideoSha256:hash(video),transcript,visual,narrationMatch:normalize(transcript.transcript??'')===normalize(s.text)?'exact':sameNarration(transcript.transcript??'',s.text)?'allowedSpokenVariant':'mismatch',passed:narrationPassed(transcript,s.text)&&visualPassed(visual),model:'gemini-3.8-flash',checkedAt:new Date().toISOString()};
   await writeJson(reviewPath,review);
  }
  if(!review.passed){
   console.log('REVIEW_REQUIRED',id,JSON.stringify(review));
   // Local editorial changes must not be replaced by an unrelated paid take.
   if(sourceEdit||args.includes('--stop-on-scene-rejection'))throw new Error('SCENE_REVIEW_REQUIRED: inspect the saved take before another billable video request: '+id);
   if(attempt>=3){console.log('SCENE_BLOCKED',id);continue;}
   const speechGood=sameNarration(review.transcript.transcript??'',s.text)&&!review.transcript.abruptNoise&&!review.transcript.music;
   const videoGood=review.visual.animated&&!review.visual.unsafeOrFrightening&&!review.visual.majorCharacterDeformation&&review.visual.sceneMatches;
   if(!speechGood)await fs.rename(stem+'.wav',stem+`.rejected${attempt}.wav`);
   if(!videoGood)await fs.rename(stem+'_raw.mp4',stem+`.rejected${attempt}.mp4`);
   await fs.rename(reviewPath,stem+`.rejected${attempt}.json`);
   await fs.writeFile(attemptFile,JSON.stringify({attempt:attempt+1,...(!videoGood&&typeof review.visual?.notes==='string'?{visualFeedback:review.visual.notes}:{})}));
   i--;continue;
  }
  const voiceSeconds=duration(stem+'.wav'),rawSeconds=duration(stem+'_raw.mp4');
  const seconds=Math.max(s.targetSeconds,Math.ceil(voiceSeconds+1.8));
  if(seconds/rawSeconds>2.25)throw new Error('Scene needs another animated shot '+id);
  ff(['-i',stem+'_raw.mp4','-i',stem+'.wav','-filter_complex',`[0:v]setpts=${seconds/rawSeconds}*PTS,scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2,fps=24,setsar=1[v];[1:a]loudnorm=I=-20:TP=-3:LRA=7,adelay=350:all=1,apad[a]`,'-map','[v]','-map','[a]','-t',String(seconds),'-c:v','libx264','-preset','fast','-crf','25','-pix_fmt','yuv420p','-c:a','aac','-b:a','80k','-ar','24000','-movflags','+faststart',stem+'.mp4']);
  const record={id,...s,seconds,voiceSeconds,sourceVideoSeconds:rawSeconds,specSha256:specHash,sourceVideoSha256:hash(video),sourceSpeechSha256:hash(speech),sha256:hash(await fs.readFile(stem+'.mp4')),review,...(sourceEdit?{sourceEdit}:{})};
  await writeJson(recordPath,record);records.push(record);console.log('Ready',id,seconds+'s');
 }
 if(records.length!==e.scenes.length)throw new Error('Some scenes require correction: '+e.id);
 const concat=path.join(dir,'concat.txt');await fs.writeFile(concat,records.map(r=>`file '${path.join(dir,r.id+'.mp4')}'`).join('\n'));
 const final=path.join(out,e.id+'.mp4');ff(['-f','concat','-safe','0','-i',concat,'-c','copy','-movflags','+faststart',final]);
  ff(['-ss','7','-i',final,'-frames:v','1','-vf','scale=960:540','-q:v','3',path.join(out,e.id+'.jpg')]);
 const {finalAudioReview,musicPrompt}=await prepareEpisodeAudio(e,dir);
 const bytes=await fs.readFile(final);
 const result={...e,scenes:records,finalAudioReview,durationSeconds:duration(final),videoAsset:`assets/stories/${e.id}.mp4`,posterAsset:`assets/stories/${e.id}.jpg`,titleAudioAsset:`assets/stories/${e.id}_title.m4a`,musicAsset:`assets/stories/${e.id}_music.m4a`,bytes:bytes.length,sha256:hash(bytes),posterSha256:hash(await fs.readFile(path.join(out,e.id+'.jpg'))),videoModel:'gemini-omni-1.1-flash',voiceModel:'gemini-3.8-flash-tts',musicModel:'lyria-3-clip-preview',musicPrompt,voice:'Kore',createdAt:new Date().toISOString(),humanReviewedAt:null,applicationAuthorization:'Owner explicitly requested production and app integration of three age-targeted story films on 2026-09-30.',status:finalAudioReview.passed?'APPLIED_ON_OWNER_REQUEST':'REVIEW_REQUIRED'};
 await writeJson(path.join(root,'production/story_pilot',e.id+'.json'),result);
 console.log('EPISODE_COMPLETE',e.id,result.durationSeconds,bytes.length);
}
for(const e of episodes.filter(e=>!only||e.id===only))await runEpisode(e);
