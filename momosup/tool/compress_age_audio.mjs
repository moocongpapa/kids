import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { wavMetrics } from './generate_gemini_tts.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const ffmpeg=process.argv.find(a=>a.startsWith('--ffmpeg='))?.slice('--ffmpeg='.length);
if(!ffmpeg)throw new Error('Pass --ffmpeg=/path/to/ffmpeg');
if(fs.existsSync(path.join(root,'production/age_audio_generation.lock')))throw new Error('Wait for generation to finish before encoding.');
const digest=b=>createHash('sha256').update(b).digest('hex');
const archive=path.join(root,'production/audio_wav/age_pack');fs.mkdirSync(archive,{recursive:true});
for(const name of ['age_audio_manifest.json','age_music_manifest.json']){
 const manifestPath=path.join(root,'assets/content',name);const manifest=JSON.parse(fs.readFileSync(manifestPath));
 for(const job of manifest.jobs){
  const encoded=job.file.endsWith('.m4a');
  if(encoded && !(process.argv.includes('--headroom') && job.metrics.peakDbfs > -3))continue;
  const source=path.join(root,encoded?job.processing.sourceArchive:job.file);const bytes=fs.readFileSync(source);if(digest(bytes)!==(encoded?job.sourceSha256:job.sha256))throw new Error(`Source hash changed: ${job.id}`);
  const relative=job.file.replace(/\.(wav|mp3)$/,'.m4a');const target=path.join(root,relative);const temporary=target+'.partial.m4a';
  const run=spawnSync(ffmpeg,['-hide_banner','-loglevel','error','-y','-i',source,'-af','loudnorm=I=-20:TP=-3:LRA=7,volume=-3dB','-ac','1','-ar','24000','-c:a','aac','-b:a','64k',temporary],{encoding:'utf8'});
  if(run.status!==0)throw new Error(`Encoding failed: ${job.id}: ${run.stderr}`);
  const decoded=path.join(archive,`${job.id}_verification.wav`);
  const check=spawnSync(ffmpeg,['-hide_banner','-loglevel','error','-y','-i',temporary,'-ac','1','-ar','24000',decoded],{encoding:'utf8'});
  if(check.status!==0)throw new Error(`Decode failed: ${job.id}`);
  const metrics=wavMetrics(fs.readFileSync(decoded));fs.unlinkSync(decoded);
  if(metrics.clippedSamples||metrics.peakDbfs===null||metrics.peakDbfs < -50)throw new Error(`Decoded quality check failed: ${job.id}`);
  fs.renameSync(temporary,target);
  const archived=path.join(archive,path.basename(source));if(source!==archived)fs.copyFileSync(source,archived);
  job.sourceSha256=digest(bytes);job.sourceMetrics=job.sourceMetrics??job.metrics;job.metrics=metrics;job.sha256=digest(fs.readFileSync(target));job.file=relative;job.processing={format:'AAC 64 kbps mono 24 kHz',loudnessTargetLufs:-20,truePeakTargetDb:-3,additionalHeadroomDb:-3,sourceArchive:path.relative(root,archived)};
  fs.writeFileSync(manifestPath+'.partial',JSON.stringify(manifest,null,2)+'\n');fs.renameSync(manifestPath+'.partial',manifestPath);if(source!==archived)fs.unlinkSync(source);
 }
 console.log(name,manifest.jobs.length,'encoded and decoded successfully');
}
