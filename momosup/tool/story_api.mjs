// Adult offline production. Never import this module into the app or backend.
import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {createStoryRequester,summarizeStoryRequests} from './story_request_client.mjs';
export const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const work=path.join(root,'production/story_work');
let key, client;
let maxVideoRequests=20;
export function configureStoryRequests({maxVideoRequests: maximum=20}={}){
 if(client)throw new Error('Configure request limits before starting production');
 if(!Number.isInteger(maximum)||maximum<1||maximum>20)throw new Error('Video request allowance must be 1–20 per run');
 maxVideoRequests=maximum;
}
async function getKey(){
 if(key)return key;
 key=process.env.GEMINI_API_KEY;
 if(!key){
  const env=await fs.readFile(path.join(root,'.env'),'utf8').catch(()=> '');
  key=env.match(/^\s*(?:export\s+)?GEMINI_API_KEY\s*=\s*(.*?)\s*$/m)?.[1].replace(/^(['"])(.*)\1$/,'$2');
 }
 return key;
}
export async function request(payload,context={}){
 if(!client&&process.env.STORY_API_DISABLED!=='1'){
  const rows=(await fs.readFile(path.join(work,'requests.jsonl'),'utf8').catch(error=>{if(error.code==='ENOENT')return '';throw error;})).trim().split('\n').filter(Boolean).map(row=>JSON.parse(row));
  if(summarizeStoryRequests(rows).unknown)throw new Error('STORY_PREVIOUS_OUTCOME_UNKNOWN: inspect the provider and resolve the local ledger before resuming.');
 }
 client??=createStoryRequester({getKey,fetchImpl:globalThis.fetch,
  warn:message=>console.warn(message),
  disabled:()=>process.env.STORY_API_DISABLED==='1',maxVideoRequests,
  sleep:ms=>new Promise(resolve=>setTimeout(resolve,ms)),
  writeEvent:async event=>{await fs.mkdir(work,{recursive:true});await fs.appendFile(path.join(work,'requests.jsonl'),JSON.stringify(event)+'\n');}
 });
 return client(payload,context);
}
export const content=r=>r.steps?.filter(s=>s.type==='model_output').flatMap(s=>s.content??[])??[];
if(process.argv.includes('--probe')){
 const image=await fs.readFile(path.join(root,'production/story_pilot/forest_reference.png'));
 const r=await request({model:'gemini-omni-1.1-flash',input:[{type:'image',data:image.toString('base64'),mime_type:'image/png'},{type:'text',text:'Create a 10 second animated storybook film. Use this image as a character and style reference. In one continuous shot the little green bird happily builds a tiny tower of three autumn leaves in this forest. Leaves gently flutter. The bird blinks and tilts its head curiously. Warm watercolor animation, full expressive character movement, calm camera, 16:9. No text, no speech, no music. Only soft forest ambience.'}],response_format:{type:'video',resolution:'720p',aspect_ratio:'16:9'},store:false});
 const video=content(r).find(c=>c.type==='video');
 if(!video?.data)throw new Error('No inline video returned');
 await fs.writeFile(path.join(root,'production/story_work/probe.mp4'),Buffer.from(video.data,'base64'));
 console.log(JSON.stringify({status:r.status,videoBytes:Buffer.from(video.data,'base64').length,model:r.model}));
}
