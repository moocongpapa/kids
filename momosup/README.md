# 모모숲 · Flutter 비공개 콘텐츠 시제품

이 프로젝트는 [PRD](../PRD.md)의 **비공개 검증판**을 위한 출발점이다. 2026-10-28과 월 ₩200,000은 사용자 확인에 따라 조정 가능한 계획 기준이다. 실기기는 아직 없고 Apple·Google Play·카카오 개발자 계정도 없다. 공개 MVP의 정확한 생년월일 서버 보관과 오프라인 안전 목록 24시간 만료 방향은 선택됐지만 이 시제품에는 실제 아동 정보를 서버로 보내는 기능이 없다. 공개 앱이 아니며 아이 혼자 사용하는 서비스로 배포하면 안 된다. 현재 10개 놀이 시나리오는 전부 미승인 초안이고 아이 모드에는 **0개**만 보인다. 보호자 PIN 뒤에서 10개를 조작 미리보기 할 수 있다.

## 구현한 것

- 하나의 Flutter 앱 안의 아이 화면과 보호자 전용 화면, 로컬 PIN 게이트
- 테스트용 만 3·4·5세 다자녀 프로필, 아바타·성별 선택·5문항 시작 단계 추천
- 프로필별 일일 이용시간·음악·차분한 움직임 설정과 로컬 놀이 기록
- 고유 놀이 초안 10개: 동물·감정·신체·탈것·자연 × 터치·색칠·동작
- 생성된 캐릭터 3개·표정 2개·숲 장면 5개(날씨 변형 2개 포함), 큰 터치 선택지, 단순 2D 반응
- 오프라인 한국어 글꼴 Noto Sans KR 포함 ([SIL OFL 라이선스](assets/fonts/OFL.txt))
- 그림 PNG 기기 저장, 네트워크 없이 번들된 이미지·텍스트 미리보기
- 명확한 종료·화면 밖 미션·자동 다음 재생 없음
- 승인·상업 이용권·필수 음성이 없으면 아이 화면에 표시하지 않는 게이트
- 승인 파일이 준비되면 활동별 사전 녹음 파일을 재생하는 코드

## 아직 구현되지 않은 것

카카오 로그인, 법정대리인 확인, 실제 생년월일 기반 자동 갱신, 24~35개월/6~7세 콘텐츠, **실제 생성된** AI 음성·노래·영상 파일, 창업자 전수 검수, 서버 연동, 가족 초대·다기기 동기화, 스토어 구독, 원격 콘텐츠 회수, 공식 개인정보·법률·앱스토어 검토. 로컬 PIN은 시제품 접근 장치일 뿐 법정대리인 인증이 아니다. 실명·정확한 생년월일은 시제품에 넣지 않는다.

## 실행과 검사

Flutter SDK 설치 후 프로젝트 폴더에서:

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

작업 환경에는 임시 Flutter 3.47.5 SDK가 `/private/tmp/kids_flutter_sdk`에 설치되어 있다. 임시 폴더는 장기 보존을 기대하면 안 된다. Xcode 27·iOS 27 시뮬레이터와 Android Studio·Android SDK·Android 17(API 37) ARM 에뮬레이터를 설치했다. iOS 시뮬레이터용 빌드, Android 디버그 APK 빌드, 양쪽 가상 기기의 첫 화면 실행을 확인했다. 현재 iOS 프로젝트는 Swift Package Manager로 빌드되지만 CocoaPods는 설치되어 있지 않아 Flutter 진단에 경고가 남는다. Android 관련 Flutter 진단에도 현재 앱에 쓰지 않는 SDK 부가 기능들의 미수락 라이선스 경고가 남는다. 실기기는 아직 없어 양 플랫폼의 실기기 빌드와 동작은 검증하지 못했다.

## 콘텐츠 제작 경로

- 원본 시나리오: [`assets/content/catalog.json`](assets/content/catalog.json)
- 2026-09-29 대본 수정 12건과 사람 확인 항목: [`production/SCRIPT_REVIEW_2026-09-29.md`](production/SCRIPT_REVIEW_2026-09-29.md)
- 놀이별 연출·검수 지침: [`CONTENT_PRODUCTION.md`](CONTENT_PRODUCTION.md)
- AI 음성/노래 작업 66개: [`assets/content/audio_manifest.json`](assets/content/audio_manifest.json)
- Gemini TTS 생성 도구: [`tool/generate_gemini_tts.mjs`](tool/generate_gemini_tts.mjs). `GEMINI_API_KEY`는 로컬 환경 변수로만 설정하고 채팅·저장소에 넣지 않는다. Google AI Pro 구독과 Gemini API 과금은 별개다.
- Flow Music 원곡 2개·영상 시안 프롬프트와 전수 검수표: [`production/FLOW_MUSIC_PRODUCTION.md`](production/FLOW_MUSIC_PRODUCTION.md)
- Google에 보낼 사용권 확인 문안: [`production/RIGHTS_INQUIRY.md`](production/RIGHTS_INQUIRY.md). 아직 발송하지 않았으며 명시적 답변 전에는 자산 생성·배포 게이트를 해제하지 않는다.
- 권리 확인이 지연될 때 쓸 직접 녹음 대본: [`production/VOICE_RECORDING_SCRIPT.md`](production/VOICE_RECORDING_SCRIPT.md). 노래 없는 8개 놀이의 안내 56줄을 먼저 녹음할 수 있다. 이 경로도 파일·그림·대본의 사람 검수를 거쳐야 한다.
- 카탈로그가 바뀌면 `dart run tool/export_audio_manifest.dart --write`로 음성 작업 목록을 다시 만든다. 동일한 대본의 생성·검수 메타데이터는 유지하고 대본이 달라진 작업은 초기화한다. **안전을 위해 실행 전 별도 백업과 변경 내용 비교를 권장**한다.
- `dart run tool/audit_content.dart`는 현재 미완료 작업을 나열하고, `dart run tool/audit_content.dart --release`는 남은 항목이 있으면 실패한다. 이 자동 검사는 사람의 눈·귀·조작 검수를 대체하지 않는다.

```sh
node tool/generate_gemini_tts.mjs --dry-run
node tool/generate_gemini_tts.mjs --activity animal_tracks --limit 2 --rights-evidence /local/private/google-clearance.pdf
```

두 번째 명령은 **Google의 서면 허용 또는 적절한 법률 검토 근거가 로컬 파일로 준비되고** API 키가 설정되어 있을 때만 호출한다. 도구가 확인 파일의 해시만 작업 목록에 기록하며 파일 내용은 저장소로 복사하지 않는다. 생성물은 앱에 번들되지 않는 `production/audio_pending/`에 `GENERATED_NEEDS_REVIEW` 상태로 저장된다. 창업자의 전수 청취·권리 확인 뒤 승인된 파일만 `assets/audio/`로 옮기고 카탈로그에 연결한다. 현재 프로젝트에는 키와 사용권 근거가 없어 실제 음성 파일은 생성하지 못했다. **Gemini API의 18세 미만 대상 앱 제한이 사전 제작 음성에도 적용되는지 해결되기 전에는 해당 API를 이 제품 자산 제작에 사용하지 않는다.** [약관](https://ai.google.dev/gemini-api/terms), [가격](https://ai.google.dev/gemini-api/docs/pricing) (2026-09-28 확인).

`ffmpeg`가 있으면 앱용 AAC/M4A를 만들고, 없으면 원본 PCM/WAV를 앱용으로 복사한다. 이 Mac의 `afconvert`에는 AAC 인코더가 없어 자동 사용하지 않는다. WAV는 용량이 크므로 공개 빌드 전 실제 iOS·Android 재생과 용량을 검사하고 필요하면 `ffmpeg`를 설치해 재생성한다.

`humanApprovedAt`, `rightsVerifiedAt`, `audioFiles`의 필수 줄별 자산 경로에 더해 **각 음성 작업의 `APPROVED` 상태·사람 검수일·상업 이용권 증빙·대본 일치·실제 파일 해시 일치**가 확인되기 전에는 놀이가 아이 모드에 나타나지 않는다. Render 카탈로그도 미승인 작업을 내보내지 않는다. 승인 표시만 임의로 바꾸지 말고 `CONTENT_PRODUCTION.md`의 사람 검수·권리 증빙을 먼저 마쳐야 한다.

가족 관찰을 시작하기 전 조건과 기록 양식은 [비공개 가족 관찰 준비표](production/PILOT_SESSION.md)에 정리했다. 현재 승인 놀이가 0개이므로 아이와의 시험은 아직 시작하지 않는다.

## 다음 사용자 준비 항목

1. iOS·Android 가상 기기의 빌드와 첫 화면 실행은 확인했다. Flutter SDK를 임시 폴더 밖에 영구 설치하고 실행 경로를 설정한다. 향후 CocoaPods를 쓰는 iOS 플러그인을 추가하면 별도 설치가 필요하다. 아이 관찰 전에 실제 Android/iPhone/iPad를 확보해 양 플랫폼에서 직접 실행한다.
2. 현재 쓰는 Render 서비스의 정확한 요금제·지역·Postgres 유무·백업 방식과 Codex·Google Pro 실제 청구액 확인. 신규 유료 스테이징 설정은 [backend/README.md](backend/README.md)와 [`render.yaml`](render.yaml)에 준비했다. 로그인 정보나 API 키를 채팅에 붙여넣지 말 것.
3. 아직 없는 카카오 개발자 앱·Apple·Google Play 개발자 계정 준비. 외부 서비스 키와 서명 설정 없이는 실제 로그인·스토어 배포·결제를 붙일 수 없다.
4. Gemini API와 Flow Music의 아동 대상 앱·오프라인 파일 재배포 권리를 각각 확인한다. 해결이 지연되면 [직접 녹음 대본](production/VOICE_RECORDING_SCRIPT.md)의 노래 없는 8개 놀이부터 제작·검수한다. 어느 경로든 권리와 사람 검수 전에는 아이 모드에 올리지 않는다.
5. 캐릭터·배경·대본·모든 음성의 시각·청각·조작 전수 검수. 마음에 걸리는 표현은 공개하지 말고 수정.

Render 연결용 로컬 [안전 API 시제품](backend/README.md)은 작성했지만 배포하거나 Flutter 앱에 연결하지 않았다. 기존 Render 계정의 상태를 모른 채 새 유료 리소스를 생성하거나 아동 데이터를 업로드하지 않는다. 오프라인 팩과 즉시 원격 회수는 동시에 절대 보장할 수 없다. 공개 MVP에서는 위험 콘텐츠의 온라인 차단과 오프라인 캐시 만료·재검증 정책을 별도로 설계하고 실기기에서 시험해야 한다.
