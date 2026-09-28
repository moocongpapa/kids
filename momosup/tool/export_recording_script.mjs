import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const manifest = JSON.parse(await readFile(path.join(root, 'assets/content/audio_manifest.json'), 'utf8'));
const jobs = manifest.jobs;
const rows = (items) => items.map((job) =>
  `| ${job.activityId} | ${job.lineId} | ${job.text.replaceAll('\n', ' / ').replaceAll('|', '\\|')} | ${job.suggestedFile} |`,
).join('\n');
const isSongActivity = (job) => ['animal_steps_song', 'body_hello'].includes(job.activityId);

const content = `# 모모숲 직접 녹음용 대본

이 문서는 \`assets/content/audio_manifest.json\`에서 생성했습니다. 대본을 고치면 \`node tool/export_recording_script.mjs\`로 다시 만드세요. 현재 파일들은 아직 녹음·검수되지 않았습니다.

Gemini TTS 사용권이 해결되지 않을 때 사람의 직접 녹음으로 진행하는 대체 경로입니다. 녹음은 조용한 공간에서 자연스러운 성인 목소리로 하고, 줄마다 아이가 반응할 여유를 둡니다. 실제 아이의 목소리·이름·개인정보를 녹음하지 않습니다. 녹음자의 동의와 원본·앱용 파일의 권리를 기록합니다. 녹음만으로 놀이가 승인되는 것은 아니며 그림·대본·조작·음량도 별도로 검수합니다.

## 우선: 노래 없이 만들 수 있는 8개 놀이, 안내 56줄

각 줄을 별도 파일로 저장합니다. 목표 파일명은 나중에 \`assets/audio/\`에 둘 승인본의 이름입니다. 미검수 녹음은 \`production/audio_pending/\`에만 보관하세요.

| 놀이 ID | 줄 ID | 정확한 대본 | 승인본 목표 경로 |
|---|---|---|---|
${rows(jobs.filter((job) => job.kind === 'speech' && !isSongActivity(job)))}

## 이후: 노래 놀이 2개

두 놀이의 안내 8줄은 아래와 같습니다. 노래 자체는 \`production/FLOW_MUSIC_PRODUCTION.md\`의 원곡 규격과 가사 검수를 별도로 따라야 합니다.

| 놀이 ID | 줄 ID | 정확한 대본 | 승인본 목표 경로 |
|---|---|---|---|
${rows(jobs.filter((job) => job.kind === 'speech' && isSongActivity(job)))}

## 승인 전 확인

1. 각 줄의 실제 발음과 대본 일치, 시작·끝 무음, 피크 음량을 사람이 끝까지 듣고 확인합니다.
2. 파일별 녹음자·녹음일·원본·권리 근거·SHA-256·검수일을 기록합니다.
3. 필요한 줄이 모두 승인되고 이미지·대본·조작도 승인되기 전에는 \`audio_manifest.json\`의 상태나 카탈로그 승인 날짜를 바꾸지 않습니다.
`;

await writeFile(path.join(root, 'production/VOICE_RECORDING_SCRIPT.md'), content);
console.log(`Wrote ${jobs.filter((job) => job.kind === 'speech').length} spoken lines.`);
