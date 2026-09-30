import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {createHash} from 'node:crypto';
import {spawnSync} from 'node:child_process';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const catalog=JSON.parse(await fs.readFile(path.join(root,'assets/content/story_catalog.json')));
const ffmpeg=process.env.STORY_FFMPEG ?? 'ffmpeg';
const hash=b=>createHash('sha256').update(b).digest('hex');
const report={productionStatus:catalog.productionStatus,published:catalog.episodes.length,previews:(catalog.previews??[]).length,assets:[],errors:[]};
for(const item of [...catalog.episodes,...catalog.previews??[]]){
 for(const [relative,expected] of Object.entries(item.assetHashes)){
  if(!/^assets\/stories\/[a-z0-9_]+\.(mp4|m4a|jpg)$/.test(relative))throw new Error('Unsafe asset');
  const file=path.join(root,relative), bytes=await fs.readFile(file);
  if(hash(bytes)!==expected)report.errors.push('hash:'+relative);
  if(relative.endsWith('.jpg'))continue;
  const decode=spawnSync(ffmpeg,['-hide_banner','-i',file,'-af','volumedetect','-f','null','-'],{encoding:'utf8'});
  const m=decode.stderr.match(/Duration: (\d+):(\d+):([\d.]+)/);
  const seconds=m?Number(m[1])*3600+Number(m[2])*60+Number(m[3]):null;
  const peak=Number(decode.stderr.match(/max_volume: (-?[\d.]+)/)?.[1]);
  const mean=Number(decode.stderr.match(/mean_volume: (-?[\d.]+)/)?.[1]);
  const record={file:relative,bytes:bytes.length,seconds,peakDb:peak,meanDb:mean,decoded:decode.status===0};
  if(!record.decoded||seconds===null||seconds<=0||!Number.isFinite(peak)||peak>=-.5||peak< -60)report.errors.push('media:'+relative);
  if(relative.endsWith('.mp4')&&(!/Video: h264/.test(decode.stderr)||!/1280x720/.test(decode.stderr)||!/Audio: aac/.test(decode.stderr)))report.errors.push('format:'+relative);
  if(relative.endsWith('.mp4')&&Math.abs(seconds-item.durationSeconds)>1)report.errors.push('duration:'+relative);
  report.assets.push(record);
 }
}
console.log(JSON.stringify(report,null,2));
if(report.errors.length)process.exitCode=1;
