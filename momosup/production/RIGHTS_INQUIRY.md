# Google에 확인할 자산 사용권 문의 초안

아래 문안은 **발송하지 않은 초안**이다. 계정의 실제 제품명·요금제와 연락처를 넣고 Google 지원 채널로 직접 문의한다. 답변 원본과 날짜를 로컬에 보관한다. 일반적인 “상업 이용 가능” 답변만으로 아래의 구체적 사용 범위가 해결된 것으로 간주하지 않는다.

## Gemini API / 사전 생성 음성

Subject: Written clarification on pre-generated Gemini TTS audio in an under-18-directed offline app

> We are developing a Korean preschool app for children aged 0–7. Children will never access Gemini API, AI Studio, or live AI features. A parent-controlled developer account would generate Korean narration offline, and the resulting reviewed audio files would be packaged into the iOS/Android app for offline playback. The app is directed at children under 18. The Gemini API Additional Terms state that the Services must not be used as part of an application directed towards or likely accessed by minors. Does this restriction also prohibit generating fixed audio files during development and distributing those audio files in this child-directed app? If permitted, please confirm the permitted API product, paid tier, app bundling/offline redistribution rights, territory, and any required disclosure or attribution in writing. We will not submit child personal data to the API.

명시적인 허용 답변을 받기 전에는 `tool/generate_gemini_tts.mjs`의 실제 API 생성 기능을 쓰지 않는다. [Gemini API 약관](https://ai.google.dev/gemini-api/terms).

## Google Flow Music / 원곡과 영상 파일

Subject: Clarification on bundling Google Flow Music Plus outputs in a paid preschool mobile app

> We have a Google AI Pro subscription with Google Flow Music Plus benefits. We plan to generate original Korean songs and short music videos from our own scripts, download the resulting files, review them, and bundle them in a paid, ad-free, offline-capable iOS/Android preschool app. Children will not access Flow Music or generation tools. Do the Plus plan's commercial use rights specifically permit distributing the downloaded audio/video files inside the app package and offline content packs to subscribers? May subscribers continue using already downloaded assets if the creator's Flow Music Plus subscription ends? Are there any territory, attribution, watermark, editing, re-encoding, or retention restrictions? Please provide the applicable terms or a written answer.

영상의 보이는 워터마크를 임의로 제거하지 않는다. 답변 전에는 음악·영상 시안이 생기더라도 `production/`에서만 보관하고 아이 모드에 넣지 않는다. [Google AI Pro 혜택](https://support.google.com/googleone/answer/14534406?hl=en), [Flow Music 영상](https://support.google.com/flow/answer/17084421?hl=en).
