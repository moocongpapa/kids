# 이야기숲 대표작 제작 기록 · 2026-09-30

## 현재 상태

**완성본 3편은 아직 제작되지 않았다.** Google API가 프로젝트 월간 지출 상한 초과를 반환해 추가 영상·음성·음악 생성이 중단됐다. 한도 해제 확인 전에는 추가 생성 요청을 하지 않는다.

- 전체 대본: 3편, 52장면. `../../tool/story_pilot_scripts.mjs`에 한국어 대사와 장면별 연출이 있다.
- 생성·장면별 자동 검수·인코딩 완료: 각 3장면, 총 9장면.
- 보호자 전용 첫 장면 미리보기: 각 약 47초, 총 약 2분 21초.
- 아이에게 공개한 완성 스토리: **0편**.
- 장면 연결을 다시 검토하면서 등장인물·낮밤·소품의 연속성 문제를 발견했다. 추가 수정 목록은 `visual_review.json`에 있으며, 자동 검수 통과만으로 완성본을 공개하지 않는다.
- 실제 부모·아이 관찰이나 사람이 전체를 청취했다는 기록은 만들지 않았다.

| 작품 | 대상 | 핵심 주제 하나 | 목표 길이 | 장면 |
|---|---|---|---|---|
| 구름아, 내 마음을 들어줘 | 24–35개월 | 내 마음을 말로 표현하기 | 약 3분 | 12 |
| 그네 하나, 친구 셋 | 만 3–5세 | 차례를 정하고 기다리기 | 약 5분 | 20 |
| 사라진 달빛을 찾아서 | 만 6–7세 미취학 | 생각한 것을 관찰로 확인하기 | 약 5분 | 20 |

월령과 길이는 제품 편집 기준이며 의료 권고나 검증된 발달 효과가 아니다. 24개월 미만은 기존 보호자용 화면 밖 놀이 정책을 적용한다. 대본은 감정을 즉시 없애는 마법이나 경쟁 점수 없이 사건과 행동으로 주제를 전달하도록 구성했다. 그네는 낮은 위치에서 한 친구만 앉고, 연못은 마른 길에서 관찰한다.

## 미디어 제작

- 영상: Gemini API `gemini-omni-1.1-flash`.
- 한국어 음성: `gemini-3.8-flash-tts`, Kore. 생성 후 별도 받아쓰기로 대사 일치를 검사했다.
- 계획된 음악: Lyria. **새 스토리 음악은 아직 생성되지 않았다.** 현재 미리보기에는 내레이션만 들어 있다.
- 스타일 이미지 `forest_reference.png`: built-in imagegen으로 기존 모모·두리·누리를 참고해 제작. 프롬프트는 원본 캐릭터를 유지한 따뜻한 수채화 숲, 낮은 나무 그네, 연못, 글자 없는 16:9 구성이다.
- 첫 생성에는 전체 숲 레퍼런스를 사용했다. 원하지 않는 친구가 나타나는 문제가 있어, 후속 코드는 장면에 필요한 캐릭터만 분리 참조하고 달빛 편의 밤 조명을 명시하도록 수정했다. 수정된 생성은 아직 실행하지 않았다.
- `*.preview.json`은 실제 생성한 9장면의 원본·음성·최종 영상 SHA-256과 자동 검수 기록이다. 큰 원본과 거절된 테이크는 Git에서 제외한 `../story_work/`에 보존한다. 키는 기존 로컬 환경에서만 읽는다.
- 미리보기는 1280×720 H.264/AAC로 앱에 번들해 오프라인 재생한다. 원격 저장소/CDN에는 배포하지 않았다.

## 앱 반영

- 홈 이야기 탭 → 숲속 작은 극장. 완성본은 월령에 맞는 편부터 표시하며 상위 연령 편을 어린 아이에게 노출하지 않는다.
- 보호자 공간 → **이야기숲 영상** → `제작 중 · 첫 장면 미리보기` 3편.
- 큰 재생·정지·닫기·음소거·가로 전체 화면 버튼, 제목/첫 장면 음성 듣기, 즐겨찾기.
- 실제 전경 재생 시간만 하루 이용시간에 합산. 정지·로딩·버퍼링은 제외한다. 앱 전환 후 명시적으로 재생해야 이어진다.
- 위치·즐겨찾기는 프로필별 로컬 보안 저장소에 저장하고 프로필 삭제 시 함께 삭제한다.
- 보호자 미리보기는 아이의 시청 시간·완주 기록을 변경하지 않는다. 다음 영상 자동재생은 없다.
- 내레이션과 별도 배경음악은 음성·음악 설정을 각각 따른다. 현재 미리보기에는 음악 트랙이 없다.

## 검증

- Flutter 정적 분석, 전체 회귀 테스트, 실제 이미지·한국어 글꼴을 사용한 세로·가로 렌더링.
- 연령 경계, 시간 소진, 앱 전환, 로딩 중 이탈, 버퍼링, 완주, 이어 보기·즐겨찾기 저장, 프로필 삭제, 부모 미리보기 기록 제외 테스트.
- MP4 3개와 M4A 3개의 전체 디코딩·해시 검사. MP4는 각 47.04초, 음성 피크 -4.2~-3.1dBFS로 디지털 클리핑 없음.
- iPhone Air/iOS 27 시뮬레이터 AVPlayer에서 3편 모두 1280×720 재생, 2.8초 이상 위치 진행, 정지 확인.
- 실제 휴대폰 청취, 전체 완성본 관람, 실제 가족 관찰은 미실시.

## 한도 해제 후 재개

Google AI Studio의 해당 프로젝트 월간 지출 상한을 조정한 뒤 실행한다. 구독 플랜 이름으로 API 한도 해제를 추정하지 않는다.

```sh
# momosup 디렉터리. FFmpeg가 PATH에 있어야 한다.
node tool/generate_story_pilot.mjs
node tool/generate_story_pilot.mjs --generate --episode=story_cloud --repair-scenes=story_cloud_01
node tool/generate_story_pilot.mjs --generate --episode=story_swing
node tool/generate_story_pilot.mjs --generate --episode=story_moon --repair-scenes=story_moon_00,story_moon_02
```

첫 명령은 비용 없는 계획 출력이다. `STORY_FFMPEG=/절대/경로/ffmpeg`도 지원한다. 이번에 쓴 임시 실행 파일은 `/private/tmp/kids-story-tools/imageio_ffmpeg/binaries/ffmpeg-macos-aarch64-v7.1`이다. 임시 경로를 영구 설치로 간주하지 않는다.

완성 영상 전체를 검토해 연속성 문제를 실제로 수정한 뒤 `visual_review.json`의 공개 차단을 해제한다. 이후 다음을 실행한다.

```sh
node tool/package_story_pilot.mjs --publish
node tool/audit_story_pilot.mjs
flutter analyze
flutter test
flutter run -t tool/story_native_smoke.dart -d <기기-ID>
```

`--publish`는 세 완성본·모든 장면 검수·제목/음악 검수·해시·연속성 수정 완료가 없으면 실패한다. 작업 완료 후 main 커밋·푸시한다.

공식 문서: [Gemini 영상](https://ai.google.dev/gemini-api/docs/omni), [API 가격](https://ai.google.dev/gemini-api/docs/pricing), [Flutter video_player](https://pub.dev/packages/video_player).
