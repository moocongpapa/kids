// Adult offline production. Never import this module into the app or backend.
import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
export const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
let key=process.env.GEMINI_API_KEY;
if(!key){
 const env=await fs.readFile(path.join(root,'.env'),'utf8').catch(()=> '');
 key=env.match(/^\s*(?:export\s+)?GEMINI_API_KEY\s*=\s*(.*?)\s*$/m)?.[1].replace(/^(['"])(.*)\1$/,'$2');
}
export async function request(payload){
 if(!key)throw new Error('Local GEMINI_API_KEY is missing');
 for(let attempt=0;attempt<8;attempt++){
  const r=await fetch('https://generativelanguage.googleapis.com/v1beta/interactions',{method:'POST',headers:{'content-type':'application/json','x-goog-api-key':key},body:JSON.stringify(payload),signal:AbortSignal.timeout(360000)});
  if(r.ok)return r.json();
  let spendRateLimited=false;
  if(r.status===429){
   const error=await r.json().catch(()=>({}));
   const details=error.error?.details??[];
   console.log('Quota message',String(error.error?.message??'').replaceAll(key,'[redacted]').replace(/https?:\/\/\S+/g,'[service-url]').slice(0,300));
   if(/monthly spending cap|spend(ing)? (cap|limit)/i.test(error.error?.message??'')) {
    throw new Error('PROJECT_SPEND_CAP_REACHED: resume only after the owner raises the project cap.');
   }
   if(/requests per day|daily (?:request )?(?:limit|quota)/i.test(error.error?.message??'')){
    throw new Error(`DAILY_REQUEST_QUOTA_REACHED (${payload.model}): resume only after reset or an approved quota increase.`);
   }
   spendRateLimited=/spend-based rate|spending rate/i.test(error.error?.message??'');
   console.log('Quota',JSON.stringify(details.flatMap(d=>(d.violations??[]).map(v=>({quotaId:v.quotaId,quotaValue:v.quotaValue,quotaMetric:v.quotaMetric})))));
  }
  if(![429,500,502,503,504].includes(r.status)||attempt===7)throw new Error(`Gemini HTTP ${r.status} (${payload.model})`);
  console.log('Transient API status',r.status,payload.model,'retry',attempt+1);
  // Spend rate quotas use a rolling window. Wait without changing project/model.
  const delay=spendRateLimited?120000:Math.min(60000,15000*(attempt+1));
  console.log('Next API retry after',delay/1000,'seconds');
  for(let remaining=delay;remaining>0;remaining-=60000){
   await new Promise(resolve=>setTimeout(resolve,Math.min(60000,remaining)));
  }
 }
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
