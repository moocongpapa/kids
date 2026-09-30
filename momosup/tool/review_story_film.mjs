// Reviews the assembled film in sequence; individual scene checks are separate.
import fs from 'node:fs/promises';
import path from 'node:path';
import {createHash} from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {request,content,root} from './story_api.mjs';

const id=process.argv.find(a=>a.startsWith('--episode='))?.slice(10);
if(!['story_cloud','story_swing','story_moon'].includes(id))throw new Error('Choose a story episode');
const manifest=JSON.parse(await fs.readFile(path.join(root,'production/story_pilot',id+'.json')));
const original=path.join(root,manifest.videoAsset);
const sha256=createHash('sha256').update(await fs.readFile(original)).digest('hex');
if(sha256!==manifest.sha256)throw new Error('Film does not match production manifest');
const reviewCopy=path.join(root,'production/story_work',id,'full_review.mp4');
const ffmpeg=process.env.STORY_FFMPEG??'ffmpeg';
const encoded=spawnSync(ffmpeg,['-hide_banner','-loglevel','error','-y','-i',original,'-vf','scale=640:360,fps=8','-c:v','libx264','-crf','32','-c:a','aac','-b:a','32k','-movflags','+faststart',reviewCopy],{encoding:'utf8'});
if(encoded.status!==0)throw new Error(encoded.stderr.slice(-800));
let at=0;
const timeline=manifest.scenes.map(s=>{const row={id:s.id,startSeconds:at,endSeconds:at+s.seconds,narration:s.text,action:s.visual};at+=s.seconds;return row;});
const prompt=`Watch this ENTIRE original Korean children's film in order, including all scene transitions and the ending. It is ${manifest.durationSeconds} seconds long. Target ${manifest.minAgeMonths}-${manifest.maxAgeMonths} months; exactly one theme: ${manifest.theme}.
Judge the actual video and audio, not just the expected script. Check that the child can follow the plot; the narrated action is visible; all spoken lines are intelligible and complete; no random added music or syllables in narration; the same three species remain recognizable; no inappropriate extra cast; time of day stays coherent; no frightening or unsafe modeled action; the ending is conclusive and invites a related real-world activity. Natural differences in camera angle, framing, or small watercolor details are not defects. Momo is a green bird, Duri a brown bear, Nuri a white cloud. In story_cloud, only Momo appears before scene03, then Momo and Nuri. In story_moon, only Momo and Duri appear before scene12, then Nuri joins; every shot must stay dusk/night. Only assess the episode supplied. No background score is present in this review copy; the app plays a separately reviewed score, so absence of underscore is not a defect.
Expected timeline: ${JSON.stringify(timeline)}
Return JSON only: {"watchedThroughSeconds":number,"plotCoherent":boolean,"narrationClear":boolean,"themeFocused":boolean,"endingComplete":boolean,"issues":[{"sceneIds":[string],"severity":"blocking"|"minor","observation":string,"correction":string}],"strengths":[string]}. Flag a blocking issue when actual footage contradicts the key action or story continuity, obscures the lesson, contains unsafe modeling, or the sound is unintelligible. Do not invent issues for unseen footage.`;
const result=await request({model:'gemini-3.8-flash',input:[{type:'text',text:prompt},{type:'video',mime_type:'video/mp4',data:(await fs.readFile(reviewCopy)).toString('base64')}],store:false});
const body=content(result).filter(c=>c.type==='text').map(c=>c.text).join('');
const review=JSON.parse(body.replace(/^```(?:json)?\s*/,'').replace(/\s*```$/,''));
const passed=review.watchedThroughSeconds>=manifest.durationSeconds-2&&review.plotCoherent===true&&review.narrationClear===true&&review.themeFocused===true&&review.endingComplete===true&&Array.isArray(review.issues)&&!review.issues.some(i=>i.severity==='blocking');
const record={episode:id,sha256,checkedAt:new Date().toISOString(),model:'gemini-3.8-flash',reviewCopy:'640x360 at 8fps; original narration retained',review,passed};
await fs.writeFile(path.join(root,'production/story_pilot',id+'.film_review.json'),JSON.stringify(record,null,2)+'\n');
console.log(JSON.stringify(record,null,2));
if(!passed)process.exitCode=1;
