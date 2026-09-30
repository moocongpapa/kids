const lines = {
  feeding: {
    intro: '열매를 톡 눌러, 모모에게 나눠 줄까?',
    complete: '모모가 배불러졌네. 나눠 줘서 고마워.',
    outro: '이제 손을 쉬어요. 가족과 물 한 잔 마시러 가요.',
  },
  sorting: {
    intro: '큰 도토리는 큰 바구니에, 작은 건 작은 바구니에.',
    complete: '도토리가 제자리를 찾았네.',
    outro: '이제 손을 쉬어요. 장난감도 바구니에 담아 볼까?',
  },
  peekaboo: {
    intro: '풀숲을 톡 눌러 볼까? 어떤 친구가 있을까?',
    complete: '까꿍! 숲속 친구들을 만났네.',
    outro: '잠깐 쉬자. 가족과 까꿍 놀이를 해 볼까?',
  },
  xylophone: {
    intro: '나무 건반을 톡. 네 소리를 들려줘.',
    follow: '반짝이는 건반을 차례로 눌러 볼까?',
    complete: '네가 고른 소리가 노래가 됐네.',
    outro: '이제 손을 쉬어요. 가족과 손뼉을 쳐 볼까?',
  },
  puzzle: {
    intro: '친구 조각을 골라, 같은 그림자에 놓아 줘.',
    complete: '친구들이 제자리에 모였네.',
    outro: '이제 손을 쉬어요. 두 팔을 쭉 펴고 쉬어 볼까?',
  },
};
export const speechJobs = Object.entries(lines).flatMap(([toy, cues]) =>
  Object.entries(cues).map(([cue, text]) => ({ id: `toy_${toy}_${cue}`, toy, cue, kind: 'speech', text })));
export const musicJobs = [
  { id: 'toy_music_picnic', kind: 'music', toys: ['feeding', 'peekaboo'], prompt: 'Compose a cheerful but quiet 30-second original forest play instrumental. Use ONLY nylon-string acoustic guitar and warm felt piano, simple major-key harmony, 72 BPM. A tiny happy curious woodland melody with generous rests, like a friendly picnic in sunshine. Keep the arrangement sparse and soft. No sadness, no melancholy, no dramatic tension. No flute, no bowed strings, no percussion, no bells, no vocals, no singing, no humming, no lyrics, no animal calls, no sound effects. A gentle beginning and natural soft ending. Do not imitate an existing melody or artist. Background level, leaving space for spoken Korean game instructions.' },
  { id: 'toy_music_clearing', kind: 'music', toys: ['sorting', 'puzzle'], prompt: 'Compose an original 30-second instrumental background for sorting acorns and matching friendly silhouettes in a cozy forest clearing. Soft felt piano with sparse pizzicato strings, relaxed 68 BPM, simple warm harmony, patient and gently curious. Very soft even dynamics, frequent rests. No percussion, no bells, no rhythmic ticking, no dramatic changes, no voices, no singing, no humming, no lyrics, no sound effects. Gentle beginning and natural soft ending. Do not imitate any existing melody or artist. Keep plenty of space for child interaction sounds and spoken instructions.' },
];
export const jobs = [...speechJobs, ...musicJobs];
