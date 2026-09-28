# 숲의 날씨 장면 변형 기록

상태: 2026-09-29 **AI 생성 초안**. 기존 `assets/images/forest_weather.png`를 편집 대상으로 사용했다. 앱의 보호자 미리보기에서 선택에 따라 장면이 바뀌지만, 사람의 시각·안전·권리 검수 전에는 콘텐츠를 승인하지 않는다. 제작 방식은 내장 이미지 생성 도구다.

| 선택 | 파일 | SHA-256 | 확인할 점 |
|---|---|---|---|
| 가벼운 비 | `assets/images/forest_weather_rain.png` | `2111f5f205113efab854dad1fbebecf8fd645bf97182ff40139b9ea8e12cdd63` | 비가 무섭거나 어둡지 않은지, 갑작스러운 시각 변화가 없는지 |
| 부드러운 바람 | `assets/images/forest_weather_wind.png` | `5a5d5ff3f3be0be3d7d0673e0de526261720131de61a831848b1920de37bce22` | 날리는 잎이 위험한 물체처럼 보이지 않는지, 바람 표현이 과하지 않은지 |

## 비 장면 최종 프롬프트

> Use case: lighting-weather edit. Asset type: 16:9 2D preschool interaction scene variant for a low-stimulation Korean picture-book app. Input image: the provided forest_weather.png is the edit target. Preserve the exact camera framing, geography, mountain and stream shapes, tree positions, foreground stones, flower placements, hand-painted cut-paper and watercolor texture, and sage/cream/coral/sky palette. Change only the weather to a very gentle light rain: slightly overcast pale sky, a few small soft raindrops visible against the sky and stream, slightly damp leaves and stones. Keep the scene bright, calm, inviting, and legible. No thunder, lightning, storm, dark shadows, strong motion, characters, people, text, logos, or watermark. Output a full landscape image matching the input aspect ratio.

## 바람 장면 최종 프롬프트

> Use case: lighting-weather edit. Asset type: 16:9 2D preschool interaction scene variant for a low-stimulation Korean picture-book app. Input image: the provided forest_weather.png is the edit target. Preserve the same camera framing, geography, mountains, stream, tree trunks, foreground stones, flowers, hand-painted cut-paper and watercolor texture, and sage/cream/coral/sky palette. Change only the weather to a soft pleasant breeze: a few leaves on the existing trees lean gently in the same direction, a handful of tiny leaves drift slowly through the sky, and the stream has delicate ripples. Keep blue sky and bright calm daylight; make the wind visibly different from the original without depicting a storm. No rain, dark clouds, strong gusts, unsafe flying objects, characters, people, text, logos, or watermark. Output a full landscape image matching the input aspect ratio.

생성물은 두 파일 모두 1672×941 PNG다. 기존 햇살 배경도 그대로 남겨 세 가지 날씨를 비교할 수 있다. 생성물의 상업 이용권과 기존 작품 유사성, 실제 기기에서의 밝기·자극·화면 전환은 별도 확인이 필요하다.
