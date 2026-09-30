// Extracts chronological contact sheets for assistant/manual visual inspection.
import fs from 'node:fs/promises';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const id=process.argv.find(a=>a.startsWith('--episode='))?.slice(10);
if(!['story_cloud','story_swing','story_moon'].includes(id))throw new Error('Choose a story episode');
const dir=path.join(root,'production/story_work',id);
const records=(await fs.readdir(dir)).filter(f=>new RegExp('^'+id+'_\\d{2}\\.json$').test(f)).sort();
for(let offset=0;offset<records.length;offset+=4){
 const group=await Promise.all(records.slice(offset,offset+4).map(async f=>JSON.parse(await fs.readFile(path.join(dir,f)))));
 const args=group.flatMap(s=>['-i',path.join(dir,s.id+'.mp4')]);
 const rows=group.map((s,i)=>`[${i}:v]fps=${3/s.seconds},scale=384:216,tile=3x1[row${i}]`);
 const filter=rows.join(';')+';'+group.map((_,i)=>`[row${i}]`).join('')+(group.length===1?'null[sheet]':`vstack=inputs=${group.length}[sheet]`);
 const output=path.join(dir,`contact_${Math.floor(offset/4)+1}.jpg`);
 const result=spawnSync(process.env.STORY_FFMPEG??'ffmpeg',['-hide_banner','-loglevel','error','-y',...args,'-filter_complex',filter,'-map','[sheet]','-frames:v','1','-q:v','2',output],{encoding:'utf8'});
 if(result.status!==0)throw new Error(result.stderr.slice(-1000));
 console.log(JSON.stringify({output,rows:group.map(s=>s.id),columns:'early, middle, late'}));
}
