import fs from 'node:fs/promises';
import {existsSync} from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {episodes} from './story_pilot_scripts.mjs';
import {request,content,root} from './story_api.mjs';
import {buildPayload,extractWav} from './generate_gemini_tts.mjs';
const args=process.argv.slice(2), only=args.find(x=>x.startsWith('--episode='))?.slice(10);
const repairIds=new Set((args.find(x=>x.startsWith('--repair-scenes='))?.slice(16)??'').split(',').filter(Boolean));
const recheckIds=new Set((args.find(x=>x.startsWith('--recheck-scenes='))?.slice(17)??'').split(',').filter(Boolean));
if(!args.includes('--generate')){console.log(JSON.stringify(episodes.map(e=>({id:e.id,scenes:e.scenes.length,seconds:e.scenes.length*15,theme:e.theme}))));process.exit(0);}
const ffmpeg=process.env.STORY_FFMPEG ?? 'ffmpeg';
const work=path.join(root,'production/story_work');
const out=path.join(root,'assets/stories');
await fs.mkdir(work,{recursive:true});await fs.mkdir(out,{recursive:true});
const hash=b=>createHash('sha256').update(b).digest('hex');
function ff(a){const r=spawnSync(ffmpeg,['-hide_banner','-loglevel','error','-y',...a],{encoding:'utf8',maxBuffer:4e6});if(r.status!==0)throw new Error('FFmpeg: '+r.stderr.slice(-1200));}
function duration(file){const p=spawnSync(ffmpeg,['-hide_banner','-i',file],{encoding:'utf8'});const m=p.stderr.match(/Duration: (\d+):(\d+):([\d.]+)/);if(!m)throw new Error('No duration '+file);return Number(m[1])*3600+Number(m[2])*60+Number(m[3]);}
const characterRefs=Object.fromEntries(await Promise.all(['momo','duri','nuri'].map(async name=>[name,await fs.readFile(path.join(root,'assets/images',name+'.png'))])));
const visualStyle='Original Momosup hand-painted watercolor storybook animation. Match these exact reference characters throughout: Momo olive-green round leaf-feathered bird with cream face, belly and orange beak; Duri small warm brown bear with cream muzzle and belly; Nuri white cloud creature with curled top, small arms and feet. Keep species, colors and anatomy consistent, no clothes or accessories unless scene specifies. Large readable expressions, expressive full character animation, subtle layered forest movement, calm camera, no flashing. Use reference as character/style guide, not a literal starting frame. A continuous 10 second animated shot, with a beginning action and gentle settling. No text, subtitles, symbols, speech or music. ';
const normalize=s=>s.normalize('NFC').replace(/[^\p{L}\p{N}]/gu,'');
// TTS/ASR can render the same surprised "앗" as "아/어" or a soft "응" as "음".
// Only these standalone interjections vary; names, actions and instructions must match.
const normalizeInterjections=s=>normalize(s.replace(/(^|[\s.!?])(?:앗|아|어)(?=[\s.!?,])/gu,'$1앗').replace(/(^|[\s.!?])(?:응|음)(?=[\s.!?,])/gu,'$1응'));
const sameNarration=(a,b)=>normalizeInterjections(a)===normalizeInterjections(b);
const sceneCast=(e,i)=>e.id==='story_cloud'?(i<3?['momo']:['momo','nuri']):e.id==='story_moon'?(i===2?[]:i<12?['momo','duri']:['momo','duri','nuri']):['momo','duri','nuri'];
function sceneContinuity(e,i){
 if(e.id==='story_cloud')return 'Continuity: '+(i>=2&&i<=8?'On one low flat mossy stone lie THREE LOOSE FLAT LEAVES, scattered horizontally. This is what remains after the previous collapse. Keep these separate leaves flat; no upright leaf structure or house exists yet. ':'The leaf house is a tiny handmade pile/tent of three loose broad leaves on one low flat mossy stone. It is not an architectural cottage: no doors, windows, walls or wooden frame. ')+(i>=2&&i<=6?'Momo is disappointed: drooping wings, downcast eyes, small downturned mouth. Momo must NOT smile, laugh, dance or look delighted yet. Nuri is gentle and concerned. ':'');
 if(e.id==='story_moon')return 'Continuity: indigo night throughout. A single full moon and its reflected light, no extra moons. '+(i===2?'POND INSERT SHOT ONLY: do not show any character, creature, animal, face, or portrait. The ONLY action is wind rippling the moon reflection. ':'')+'Any friends shown stay back on the broad dry path, never in water or leaning over the edge. ';
 return 'Continuity: only one low wooden swing with two ropes, in a warm forest clearing. Only one seated rider at a time, holding ropes, with waiting friends outside its arc. ';
}
function json(r){const s=content(r).filter(c=>c.type==='text').map(c=>c.text).join('');return JSON.parse(s.replace(/^```(?:json)?\s*/,'').replace(/\s*```$/,''));}
function speechPayload(text){
 const payload=buildPayload({kind:'speech',text});
 payload.input[0].content[0].annotations[0].style='Dry studio spoken voice only, absolutely no background music or sound effects. Warm expressive Korean adult storyteller. Natural clear Korean for young children, gentle character inflections, conversational pace with short breaths. Read exactly this text. No added words, no humming, no singing. Silence behind the voice.';
 return payload;
}
async function prepareEpisodeAudio(e,dir){
 // Spoken title for the large, text-optional story selection screen.
 const titleRaw=path.join(dir,'title.wav');
 if(!existsSync(titleRaw))await fs.writeFile(titleRaw,extractWav(await request(speechPayload(e.title))));
 ff(['-i',titleRaw,'-af','loudnorm=I=-20:TP=-3:LRA=7','-c:a','aac','-b:a','64k','-ar','24000',path.join(out,e.id+'_title.m4a')]);
 const musicRaw=path.join(dir,'music.mp3');
 const musicPrompt=`Instrumental only, absolutely no voice, singing or humming. Gentle warm watercolor woodland animation underscore, about 30 seconds. ${e.id==='story_moon'?'Wonder and quiet curiosity, soft celesta and warm strings, no suspense, no ominous sounds.':e.id==='story_swing'?'Playful acoustic guitar and soft marimba, lightly bouncing but never busy.':'Tender soft acoustic guitar and warm felt piano, reassuring with a little gentle humor.'} No sharp impacts or sudden changes, sparse arrangement with plenty of room for Korean narration, soft ending.`;
 if(!existsSync(musicRaw)){const r=await request({model:'lyria-3-clip-preview',input:musicPrompt});const a=content(r).find(c=>c.type==='audio');if(!a?.data)throw new Error('No music');await fs.writeFile(musicRaw,Buffer.from(a.data,'base64'));}
 ff(['-i',musicRaw,'-af',`loudnorm=I=-25:TP=-5:LRA=6,afade=t=in:d=1,afade=t=out:st=${Math.max(0,duration(musicRaw)-2)}:d=2`,'-c:a','aac','-b:a','64k','-ar','24000',path.join(out,e.id+'_music.m4a')]);
 const titleBytes=await fs.readFile(path.join(out,e.id+'_title.m4a'));
 const musicBytes=await fs.readFile(path.join(out,e.id+'_music.m4a'));
 const titleReview=json(await request({model:'gemini-3.8-flash',input:[{type:'text',text:'Transcribe exactly the audible Korean words. JSON only: {"transcript":string,"abruptNoise":boolean,"music":boolean}.'},{type:'audio',mime_type:'audio/mp4',data:titleBytes.toString('base64')}]}));
 const musicReview=json(await request({model:'gemini-3.8-flash',input:[{type:'text',text:'Listen to the full clip. JSON only: {"voice":boolean,"abruptNoise":boolean,"notes":string}. Voice includes speech, singing and humming. Abrupt noise includes startling impacts, screams or glitches.'},{type:'audio',mime_type:'audio/mp4',data:musicBytes.toString('base64')}]}));
 const finalAudioReview={titleReview,musicReview,model:'gemini-3.8-flash',passed:normalize(titleReview.transcript??'')===normalize(e.title)&&!titleReview.abruptNoise&&!titleReview.music&&!musicReview.voice&&!musicReview.abruptNoise,checkedAt:new Date().toISOString()};
 const result={episode:e.id,title:e.title,finalAudioReview,musicPrompt,
  titleAudioAsset:`assets/stories/${e.id}_title.m4a`,musicAsset:`assets/stories/${e.id}_music.m4a`,
  assetHashes:{title:hash(titleBytes),music:hash(musicBytes)},
  voiceModel:'gemini-3.8-flash-tts',musicModel:'lyria-3-clip-preview',
  createdAt:new Date().toISOString(),status:finalAudioReview.passed?'AUTOMATED_AUDIO_REVIEW_PASSED':'REVIEW_REQUIRED'};
 await fs.writeFile(path.join(root,'production/story_pilot',e.id+'.audio.json'),JSON.stringify(result,null,2)+'\n');
 return result;
}
async function runEpisode(e){
 const dir=path.join(work,e.id);await fs.mkdir(dir,{recursive:true});
 if(args.includes('--audio-only')){
  const audio=await prepareEpisodeAudio(e,dir);
  console.log('AUDIO_COMPLETE',e.id,audio.status);
  if(!audio.finalAudioReview.passed)throw new Error('Audio review required '+e.id);
  return;
 }
 const records=[];
 for(let i=0;i<e.scenes.length;i++){
  const s=e.scenes[i], id=`${e.id}_${String(i).padStart(2,'0')}`, stem=path.join(dir,id), specHash=hash(JSON.stringify(s)+visualStyle);
  const attemptFile=stem+'_attempt.json';
  let attempt=existsSync(attemptFile)?JSON.parse(await fs.readFile(attemptFile)).attempt:1;
  const recordPath=stem+'.json';
  if(recheckIds.delete(id)){
   for(const suffix of ['.json','_review.json','_attempt.json']){
    if(existsSync(stem+suffix))await fs.rename(stem+suffix,stem+'.before-recheck-'+Date.now()+suffix);
   }
   attempt=1;
  }
  if(repairIds.delete(id)){
   for(const suffix of ['.json','_raw.mp4','_review.json','_attempt.json']){
    if(existsSync(stem+suffix))await fs.rename(stem+suffix,stem+'.before-repair-'+Date.now()+suffix);
   }
   attempt=1;
  }
  if(existsSync(recordPath)){
   const old=JSON.parse(await fs.readFile(recordPath));
   if(old.specSha256===specHash&&old.review?.passed&&existsSync(stem+'.mp4')&&hash(await fs.readFile(stem+'.mp4'))===old.sha256){records.push(old);console.log('Reuse',id);continue;}
  }
  console.log('Producing',id);
  let speech,video;
  // One paid attempt at a time, persisted immediately to allow safe resumes.
  if(existsSync(stem+'.wav')) speech=await fs.readFile(stem+'.wav');
  else{
   const payload=speechPayload(s.text);
   speech=extractWav(await request(payload));await fs.writeFile(stem+'.wav',speech);
  }
  if(existsSync(stem+'_raw.mp4')) video=await fs.readFile(stem+'_raw.mp4');
  else{
   const cast=sceneCast(e,i);
   const references=cast.map(name=>({type:'image',data:characterRefs[name].toString('base64'),mime_type:'image/png'}));
   const previous=records.at(-1);
   let continuityReference=null;
   if(i>0&&cast.length&&previous?.id===`${e.id}_${String(i-1).padStart(2,'0')}`){
    const frame=path.join(dir,id+'_continuity.jpg');
    ff(['-sseof','-0.4','-i',path.join(dir,previous.id+'.mp4'),'-frames:v','1','-vf','scale=640:360','-q:v','3',frame]);
    const bytes=await fs.readFile(frame);
    references.unshift({type:'image',data:bytes.toString('base64'),mime_type:'image/jpeg'});
    continuityReference={previousScene:previous.id,sha256:hash(bytes)};
   }
   const prompt=visualStyle+'Palette: '+e.palette+'. Only include these characters when the scene requires them: '+(cast.join(', ')||'NONE')+'. '+(continuityReference?'The FIRST image is the ending of the previous shot. Continue the same location, lighting, actor appearance and prop states. You may choose a new camera angle to show the current action. The remaining images are isolated character design references. ':'The supplied images are isolated CHARACTER REFERENCES, not starting frames. ')+'Do not recreate a group portrait or a white studio background. Place the action in the same lush mossy woodland with broad tree roots and softly layered trees. Create the specified setting and action. '+sceneContinuity(e,i)+'Scene: '+s.visual;
   const r=await request({model:'gemini-omni-1.1-flash',input:[...references,{type:'text',text:prompt}],response_format:{type:'video',resolution:'720p',aspect_ratio:'16:9'},store:false});
   await fs.writeFile(stem+'_video_prompt.json',JSON.stringify({prompt,continuityReference,referenceAssets:cast.map(name=>'assets/images/'+name+'.png'),referenceSha256:cast.map(name=>hash(characterRefs[name]))},null,2));
   const v=content(r).find(c=>c.type==='video');if(!v?.data)throw new Error('No inline video '+id);
   video=Buffer.from(v.data,'base64');await fs.writeFile(stem+'_raw.mp4',video);
  }
  const reviewPath=stem+'_review.json';let review;
  if(existsSync(reviewPath))review=JSON.parse(await fs.readFile(reviewPath));
  else{
   const transcript=json(await request({model:'gemini-3.8-flash',input:[{type:'text',text:'Listen carefully to the entire Korean narration. Transcribe exactly what is audibly said without correcting or inventing words. Music means separate audible instrumental accompaniment or actual singing/humming. Expressive speech with melodic intonation alone is NOT music. Abrupt noise means startling unwanted impacts, glitches or screams, not clear spoken exclamations. JSON only: {"transcript":string,"abruptNoise":boolean,"music":boolean,"soundNotes":string}.'},{type:'audio',mime_type:'audio/wav',data:speech.toString('base64')}]}));
   const visual=json(await request({model:'gemini-3.8-flash',input:[{type:'text',text:'Review this original preschool animation. Expected scene: '+s.visual+' Allowed cast: '+(sceneCast(e,i).join(', ')||'NONE: water close-up without characters')+'. Momo is an olive-green bird, Duri a brown bear, Nuri a white cloud creature. No other character should appear. Lighting: '+e.palette+'. '+sceneContinuity(e,i)+'Return JSON only: {"animated":boolean,"unsafeOrFrightening":boolean,"majorCharacterDeformation":boolean,"sceneMatches":boolean,"notes":string}. Set sceneMatches false for an extra character, wrong time of day, wrong emotion/prop state that contradicts the plot, a static reference portrait instead of the described action, or a missing key action. Minor artistic differences are acceptable. A quiet scene can have subtle movement. Judge only visible content.'},{type:'video',mime_type:'video/mp4',data:video.toString('base64')}]}));
   review={transcript,visual,narrationMatch:normalize(transcript.transcript??'')===normalize(s.text)?'exact':sameNarration(transcript.transcript??'',s.text)?'expressiveInterjectionOnly':'mismatch',passed:sameNarration(transcript.transcript??'',s.text)&&!transcript.abruptNoise&&!transcript.music&&visual.animated&&!visual.unsafeOrFrightening&&!visual.majorCharacterDeformation&&visual.sceneMatches,model:'gemini-3.8-flash',checkedAt:new Date().toISOString()};
   await fs.writeFile(reviewPath,JSON.stringify(review,null,2));
  }
  if(!review.passed){
   console.log('REVIEW_REQUIRED',id,JSON.stringify(review));
   if(attempt>=3){console.log('SCENE_BLOCKED',id);continue;}
   const speechGood=sameNarration(review.transcript.transcript??'',s.text)&&!review.transcript.abruptNoise&&!review.transcript.music;
   const videoGood=review.visual.animated&&!review.visual.unsafeOrFrightening&&!review.visual.majorCharacterDeformation&&review.visual.sceneMatches;
   if(!speechGood)await fs.rename(stem+'.wav',stem+`.rejected${attempt}.wav`);
   if(!videoGood)await fs.rename(stem+'_raw.mp4',stem+`.rejected${attempt}.mp4`);
   await fs.rename(reviewPath,stem+`.rejected${attempt}.json`);
   await fs.writeFile(attemptFile,JSON.stringify({attempt:attempt+1}));
   i--;continue;
  }
  const voiceSeconds=duration(stem+'.wav'),rawSeconds=duration(stem+'_raw.mp4');
  const seconds=Math.max(s.targetSeconds,Math.ceil(voiceSeconds+1.8));
  if(seconds/rawSeconds>2.25)throw new Error('Scene needs another animated shot '+id);
  ff(['-i',stem+'_raw.mp4','-i',stem+'.wav','-filter_complex',`[0:v]setpts=${seconds/rawSeconds}*PTS,scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2,fps=24,setsar=1[v];[1:a]loudnorm=I=-20:TP=-3:LRA=7,adelay=350:all=1,apad[a]`,'-map','[v]','-map','[a]','-t',String(seconds),'-c:v','libx264','-preset','fast','-crf','25','-pix_fmt','yuv420p','-c:a','aac','-b:a','80k','-ar','24000','-movflags','+faststart',stem+'.mp4']);
  const record={id,...s,seconds,voiceSeconds,sourceVideoSeconds:rawSeconds,specSha256:specHash,sourceVideoSha256:hash(video),sourceSpeechSha256:hash(speech),sha256:hash(await fs.readFile(stem+'.mp4')),review};
  await fs.writeFile(recordPath,JSON.stringify(record,null,2));records.push(record);console.log('Ready',id,seconds+'s');
 }
 if(records.length!==e.scenes.length)throw new Error('Some scenes require correction: '+e.id);
 const concat=path.join(dir,'concat.txt');await fs.writeFile(concat,records.map(r=>`file '${path.join(dir,r.id+'.mp4')}'`).join('\n'));
 const final=path.join(out,e.id+'.mp4');ff(['-f','concat','-safe','0','-i',concat,'-c','copy','-movflags','+faststart',final]);
  ff(['-ss','7','-i',final,'-frames:v','1','-vf','scale=960:540','-q:v','3',path.join(out,e.id+'.jpg')]);
 const {finalAudioReview,musicPrompt}=await prepareEpisodeAudio(e,dir);
 const bytes=await fs.readFile(final);
 const result={...e,scenes:records,finalAudioReview,durationSeconds:duration(final),videoAsset:`assets/stories/${e.id}.mp4`,posterAsset:`assets/stories/${e.id}.jpg`,titleAudioAsset:`assets/stories/${e.id}_title.m4a`,musicAsset:`assets/stories/${e.id}_music.m4a`,bytes:bytes.length,sha256:hash(bytes),videoModel:'gemini-omni-1.1-flash',voiceModel:'gemini-3.8-flash-tts',musicModel:'lyria-3-clip-preview',musicPrompt,voice:'Kore',createdAt:new Date().toISOString(),humanReviewedAt:null,applicationAuthorization:'Owner explicitly requested production and app integration of three age-targeted story films on 2026-09-30.',status:finalAudioReview.passed?'APPLIED_ON_OWNER_REQUEST':'REVIEW_REQUIRED'};
 await fs.writeFile(path.join(root,'production/story_pilot',e.id+'.json'),JSON.stringify(result,null,2)+'\n');
 console.log('EPISODE_COMPLETE',e.id,result.durationSeconds,bytes.length);
}
for(const e of episodes.filter(e=>!only||e.id===only))await runEpisode(e);
