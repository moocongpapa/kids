#!/usr/bin/env python3
"""Normalize generated audio into a compact app asset using macOS Core Audio."""
import array, json, math, pathlib, subprocess, sys, tempfile, wave
from audio_pcm import read_pcm
source, target, kind = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2]), sys.argv[3]
with tempfile.TemporaryDirectory(prefix='toy-audio-') as temp:
    decoded = pathlib.Path(temp) / 'decoded.wav'
    subprocess.run(['/usr/bin/afconvert', '-f', 'WAVE', '-d', 'LEI16@24000', '-c', '1', str(source), str(decoded)], check=True, capture_output=True)
    rate, channels, data = read_pcm(decoded)
    if channels != 1: raise ValueError('Expected mono audio')
    if not data: raise ValueError('Empty audio')
    if kind == 'speech':
        active = [i for i, value in enumerate(data) if abs(value) > 184]
        if not active: raise ValueError('Silent speech')
        data = data[max(0, active[0] - int(.12*rate)):min(len(data), active[-1]+int(.22*rate))]
    peak = max(map(abs, data)); rms = math.sqrt(sum(x*x for x in data)/len(data))
    if rms < 10: raise ValueError('Near silent audio')
    target_rms = 32768 * 10 ** ((-22 if kind == 'speech' else -25)/20)
    gain = min(target_rms/rms, (32768*10**(-4/20))/peak)
    fade_in = int(rate*(.012 if kind == 'speech' else 1.0))
    fade_out = int(rate*(.06 if kind == 'speech' else 1.8))
    pcm = array.array('h', (round(v*gain*min(1, i/max(1,fade_in), (len(data)-1-i)/max(1,fade_out))) for i,v in enumerate(data)))
    normalized = pathlib.Path(temp)/'normalized.wav'
    with wave.open(str(normalized),'wb') as w:
        w.setnchannels(1);w.setsampwidth(2);w.setframerate(rate);w.writeframes(pcm.tobytes())
    subprocess.run(['/usr/bin/afconvert','-f','m4af','-d','aac','-b','64000','-q','127',str(normalized),str(target)],check=True,capture_output=True)
    checked = pathlib.Path(temp)/'checked.wav'
    subprocess.run(['/usr/bin/afconvert','-f','WAVE','-d','LEI16@24000','-c','1',str(target),str(checked)],check=True,capture_output=True)
    _, _, samples = read_pcm(checked)
    metrics={'durationSeconds':round(len(samples)/rate,3),'sampleRate':rate,'peakDbfs':round(20*math.log10(max(map(abs,samples))/32768),2),'rmsDbfs':round(20*math.log10(math.sqrt(sum(v*v for v in samples)/len(samples))/32768),2),'clippedSamples':sum(abs(v)>=32767 for v in samples)}
    if metrics['clippedSamples'] or not (.7 <= metrics['durationSeconds'] <= (9 if kind=='speech' else 35)): raise ValueError('Audio outside duration/peak limits')
    print(json.dumps(metrics))
