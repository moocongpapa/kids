#!/usr/bin/env python3
"""Read-only macOS audit of bundled audio; afconvert decodes AAC in temp files.
Usage: python3 tool/audit_audio.py [--output /tmp/audio-audit.json]
RMS/peaks describe digital signals, not device loudness or listening quality.
"""
import argparse, array, concurrent.futures, hashlib, json, math, pathlib, subprocess, tempfile, wave
root=pathlib.Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output', type=pathlib.Path)
args=parser.parse_args()
expected={}
for name in ['audio_manifest','age_audio_manifest','age_music_manifest']:
 for j in json.loads((root/'assets/content'/f'{name}.json').read_text())['jobs']:
  expected[j.get('file',j.get('suggestedFile'))]=j

def inspect(p):
 rel=str(p.relative_to(root));j=expected.get(rel,{})
 with tempfile.TemporaryDirectory(prefix='kids-audio-') as temp:
  decoded=p
  if p.suffix=='.m4a':
   decoded=pathlib.Path(temp)/'decoded.wav'
   subprocess.run(['/usr/bin/afconvert','-f','WAVE','-d','LEI16@24000','-c','1',str(p),str(decoded)],check=True,capture_output=True)
  with wave.open(str(decoded)) as w:
   frames=w.getnframes(); rate=w.getframerate(); channels=w.getnchannels()
   assert w.getsampwidth()==2
   samples=array.array('h',w.readframes(frames))
  peak=max(map(abs,samples));rms=math.sqrt(sum(x*x for x in samples)/len(samples));active=[i for i,v in enumerate(samples) if abs(v)>184]
  return {'file':rel,'duration':round(frames/rate,3),'peakDbfs':round(20*math.log10(max(peak,1)/32768),2),'rmsDbfs':round(20*math.log10(max(rms,1)/32768),2),'clippedSamples':sum(abs(v)>=32767 for v in samples),'leadingSilence':round(active[0]/rate/channels,3) if active else frames/rate,'trailingSilence':round((len(samples)-1-active[-1])/rate/channels,3) if active else frames/rate,'hashMatches':hashlib.sha256(p.read_bytes()).hexdigest()==j['sha256'] if j else None,'text':j.get('text',j.get('lyrics'))}
files=sorted(p for p in (root/'assets/audio').rglob('*') if p.suffix in ['.wav','.m4a'])
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool: rows=list(pool.map(inspect,files))
if args.output:
 args.output.write_text(json.dumps(rows,ensure_ascii=False,indent=2))
missing=sorted(set(expected)-{r['file'] for r in rows})
print('Missing manifest assets:',missing)
for kind,subset in [('classic',[r for r in rows if '__' in r['file']]),('age',[r for r in rows if '/age_pack/' in r['file']]),('effects',[r for r in rows if '/sfx_' in r['file']])]:
 print(kind,len(subset),'rmsRange',min(r['rmsDbfs'] for r in subset),max(r['rmsDbfs'] for r in subset),'durationRange',min(r['duration'] for r in subset),max(r['duration'] for r in subset))
print('TOTAL',len(rows),'hashFailures',sum(r['hashMatches']==False for r in rows),'clippedFiles',sum(r['clippedSamples']>0 for r in rows))
print('leading > .5s',[(r['file'],r['leadingSilence']) for r in rows if r['leadingSilence']>.5])
print('trailing > 1s',[(r['file'],r['trailingSilence']) for r in rows if r['trailingSilence']>1])

if missing or any(r['hashMatches'] is False or r['clippedSamples'] > 0 for r in rows):
 raise SystemExit(1)
