# iOS 플러그인 호환성 수정

2026-10-01 기준 배포된 최신 버전의 네이티브 경고를 제한적으로 처리한다. `pubspec.yaml`의 `dependency_overrides`가 이 디렉터리를 참조하므로 `flutter pub get`, 새 체크아웃, CI에서도 수정이 유지된다. 사용자의 `.pub-cache`는 수정하지 않는다.

| 패키지 | 원본 버전 | 변경 |
| --- | --- | --- |
| `kakao_flutter_sdk_auth` | 2.0.1 | 인증 창을 `UIApplication.windows` 대신 전경 `UIWindowScene`의 key window에서 선택 |
| `kakao_flutter_sdk_common` | 2.0.1 | 같은 방식으로 웹 인증 창 선택 |
| `audio_session` | 0.2.4 | iOS 16+에서는 더 이상 전달되지 않는 `wasSuspended` 값을 `null`로 유지. iOS 14.5–15는 interruption reason에서 판별 |
| `video_player_avfoundation` | 2.12.0 | Objective-C 프로토콜의 `AVKeyValueStatus` 선언 한 곳에만 호환성 경고 예외 적용 |

영상의 예외는 재생 구현을 Swift 비동기 API로 전면 재작성하는 변경을 피하기 위한 것이다. `AVAsyncProperty.Status`는 Swift API이며 기존 Objective-C 프로토콜에 그대로 대입할 수 없다. 기존 재생 동작과 iOS 15 지원은 유지한다. 앱 전체나 플러그인 전체의 경고를 끄지 않는다. 오디오의 iOS 16 미만 분기에도 이전 OS 전용 API 사용 부분에만 진단 범위를 제한한다.

원본은 pub.dev의 동일 버전 패키지다. 런타임 소스·플랫폼 구현·기존 테스트·LICENSE·AUTHORS(존재하는 경우)·버전 기록을 보관한다. 예제 앱과 코드 생성 입력은 런타임에 필요하지 않아 포함하지 않았다. 카카오 패키지의 원본 `resolution: workspace`는 이 앱에서 독립 path dependency로 사용하기 위해 제거했다. Dart API와 Android 구현은 원본과 동일하다.

Xcode 27의 권장 설정을 실제 대화상자에서 검토했다. 최소 iOS 버전을 자동으로 올리는 두 제안은 iOS 15 지원을 유지하기 위해 적용하지 않았다. `Quoted Include In Framework Header` 옵션은 적용 후 Flutter 3.47.5의 배포된 프레임워크 헤더 자체에 경고를 발생시키는 것을 확인해 명시적으로 `NO`로 유지했다. 나머지 앱 경고는 활성 상태다. Xcode가 프로젝트·스킴의 검토 버전을 갱신했다.

원본과의 변경 차이는 [`ios_compatibility.patch`](ios_compatibility.patch)에 함께 보관한다.

## 향후 업데이트

상위 패키지에 수정이 배포되면 네이티브 변경을 비교하고 해당 override와 복사본을 함께 제거한다. `flutter pub get` 후 iOS 시뮬레이터 빌드 로그와 홈·음성·영상 회귀 검사를 확인한다. 카카오 로그인 창은 실제 계정/기기에서 별도로 확인해야 한다.

## 검증 기록

2026-10-01: 최종 iOS 시뮬레이터 디버그 빌드(arm64/x86_64)는 19.4초에 성공했고 전체 상세 로그의 컴파일 경고는 0개였다. Xcode에서도 다시 Build를 실행해 `Build Succeeded`와 필터 없는 빈 Issue Navigator를 확인했다. 앱과 통합 테스트의 정적 분석, 홈·놀이·영상 재생 정책·온보딩 회귀 검사 26개도 통과했다. 각 LICENSE와 수정 대상 외의 Dart/Android 소스가 원본과 같은 것을 비교했다. 실제 카카오 계정 로그인과 전체 네이티브 재생 검사는 이 기록에 포함하지 않는다.

참고: [Flutter 영상 패키지](https://pub.dev/packages/video_player_avfoundation/changelog), [audio_session](https://pub.dev/packages/audio_session/changelog), [카카오 변경 이력](https://developers.kakao.com/docs/ko/flutter/download), [Apple의 중단 키 문서](https://developer.apple.com/documentation/avfaudio/avaudiosessioninterruptionwassuspendedkey), [중단 사유의 지원 종료](https://developer.apple.com/documentation/avfaudio/avaudiosession/interruptionreason/appwassuspended), [AVAsyncProperty](https://developer.apple.com/documentation/avfoundation/avasyncproperty).
