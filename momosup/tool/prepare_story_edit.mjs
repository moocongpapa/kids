// Local edit of existing, reviewed media. Never imports or calls the API.
import fs from 'node:fs/promises';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {episodes} from './story_pilot_scripts.mjs';
import {hash,readJson,writeJson} from './story_production_shared.mjs';
import {loadReviewedFilm,reviewedAudio} from './story_release_checks.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const id=process.argv.find(a=>a.startsWith('--episode='))?.split('=')[1];
const episode=episodes.find(e=>e.id===id);
if(!episode)throw new Error('Choose a complete episode');
const visual=await readJson(path.join(root,'production/story_pilot/visual_review.json'));
const film=await loadReviewedFilm(root,episode,visual,{applyEditing:false});
const audio=await reviewedAudio(root,episode);
const ffmpeg=process.env.STORY_FFMPEG??'ffmpeg';
function ff(args){const r=spawnSync(ffmpeg,['-hide_banner','-nostdin','-y',...args],{encoding:'utf8',maxBuffer:4e6});if(r.status!==0)throw new Error(r.stderr.slice(-1000));return r.stderr;}
function metrics(file){
  const log=ff(['-i',file,'-af','volumedetect','-f','null','-']);
  const d=log.match(/Duration: (\d+):(\d+):([\d.]+)/);
  return {duration:d?Number(d[1])*3600+Number(d[2])*60+Number(d[3]):null,peak:Number(log.match(/max_volume: (-?[\d.]+)/)?.[1]),mean:Number(log.match(/mean_volume: (-?[\d.]+)/)?.[1]),decoded:true};
}
const source=path.join(root,audio.musicAsset),sourceMetrics=metrics(source);
const trimHead=1.1,trimTail=2.2,crossfade=1.2,clipLength=sourceMetrics.duration-trimHead-trimTail;
if(clipLength<crossfade*3)throw new Error('Music too short for a smooth loop');
const loopAsset='assets/stories/'+id+'_loop.m4a',loopFile=path.join(root,loopAsset),pending=loopFile+'.pending.m4a';
// Rotate the edited clip around an overlapping tail→head bridge. The bridge ends
// at the same head position where the body begins on the next loop.
const filter=`[0:a]atrim=start=${trimHead}:end=${sourceMetrics.duration-trimTail},asetpts=PTS-STARTPTS,asplit=3[a][b][c];[a]atrim=start=${crossfade}:end=${clipLength-crossfade},asetpts=PTS-STARTPTS[body];[b]atrim=start=${clipLength-crossfade}:end=${clipLength},asetpts=PTS-STARTPTS[tail];[c]atrim=start=0:end=${crossfade},asetpts=PTS-STARTPTS[head];[tail]afade=t=out:st=0:d=${crossfade}[tailFade];[head]afade=t=in:st=0:d=${crossfade}[headFade];[tailFade][headFade]amix=inputs=2:duration=longest:normalize=0[bridge];[body][bridge]concat=n=2:v=0:a=1[loop]`;
ff(['-i',source,'-filter_complex',filter,'-map','[loop]','-c:a','aac','-b:a','64k','-ar','24000',pending]);
const loop=metrics(pending);
if(!Number.isFinite(loop.peak)||loop.peak>=-.5||Math.abs(loop.duration-(clipLength-crossfade))>.2)throw new Error('Invalid loop edit');
await fs.rename(pending,loopFile);
const dir=path.join(root,'production/story_work',id);
await fs.mkdir(dir,{recursive:true});
const mixFile=path.join(dir,id+'_review_mix.mp4'),mixPending=mixFile+'.pending.mp4';
const seconds=film.durationSeconds;
ff(['-i',path.join(root,film.videoAsset),'-stream_loop','-1','-i',loopFile,'-filter_complex',`[0:a]anull[voice];[1:a]atrim=duration=${seconds},asetpts=PTS-STARTPTS,volume=0.22,afade=t=in:d=1.5,afade=t=out:st=${seconds-3}:d=3[music];[voice][music]amix=inputs=2:duration=first:normalize=0[mix]`,'-map','0:v','-map','[mix]','-c:v','copy','-c:a','aac','-b:a','96k','-ar','24000','-t',String(seconds),'-movflags','+faststart',mixPending]);
const mix=metrics(mixPending);
if(!Number.isFinite(mix.peak)||mix.peak>=-.5||Math.abs(mix.duration-seconds)>.2)throw new Error('Invalid narration/music mix');
await fs.rename(mixPending,mixFile);
const silenceLog=ff(['-i',path.join(root,film.videoAsset),'-af','silencedetect=noise=-36dB:d=0.2','-f','null','-']);
const lastStart=[...silenceLog.matchAll(/silence_start: ([\d.]+)/g)].at(-1)?.[1];
const lastEnd=[...silenceLog.matchAll(/silence_end: ([\d.]+)/g)].at(-1)?.[1];
const endingGap=lastStart&&lastEnd&&Number(lastEnd)>seconds-.2?Number((seconds-Number(lastStart)).toFixed(2)):0;
const cuts=[];let at=0;for(const s of film.scenes){cuts.push({id:s.id,startSeconds:at,endSeconds:at+s.seconds});at+=s.seconds;}
const record={episode:id,checkedAt:new Date().toISOString(),sourceVideoSha256:film.sha256,sourceMusicSha256:audio.assetHashes.music,loopAsset,loopSha256:hash(await fs.readFile(loopFile)),transform:{kind:'loop-crossfade-v1',trimHeadSeconds:trimHead,trimTailSeconds:trimTail,crossfadeSeconds:crossfade,curve:'linear',note:'Existing instrumental source only; no new notes, voices or generated imagery.'},technicalReview:{passed:endingGap>=1.5,loopDecoded:true,loopSeconds:loop.duration,loopPeakDb:loop.peak,mixDecoded:true,mixSeconds:mix.duration,mixPeakDb:mix.peak,mixMeanDb:mix.mean,musicGain:.22,fadeInSeconds:1.5,fadeOutSeconds:3,endingVoiceGapSeconds:endingGap,videoFramesUnchanged:true},sceneTimeline:cuts,localPreview:{file:path.relative(root,mixFile),sha256:hash(await fs.readFile(mixFile))},humanReviewedAt:null,nativePlaybackVerified:false};
await writeJson(path.join(root,'production/story_pilot',id+'.editing.json'),record);
console.log(JSON.stringify({loopAsset,mixFile,...record.technicalReview},null,2));
if(!record.technicalReview.passed)process.exitCode=1;
