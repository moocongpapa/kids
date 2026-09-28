# 모모숲 직접 녹음용 대본

이 문서는 `assets/content/audio_manifest.json`에서 생성했습니다. 대본을 고치면 `node tool/export_recording_script.mjs`로 다시 만드세요. 현재 파일들은 아직 녹음·검수되지 않았습니다.

Gemini TTS 사용권이 해결되지 않을 때 사람의 직접 녹음으로 진행하는 대체 경로입니다. 녹음은 조용한 공간에서 자연스러운 성인 목소리로 하고, 줄마다 아이가 반응할 여유를 둡니다. 실제 아이의 목소리·이름·개인정보를 녹음하지 않습니다. 녹음자의 동의와 원본·앱용 파일의 권리를 기록합니다. 녹음만으로 놀이가 승인되는 것은 아니며 그림·대본·조작·음량도 별도로 검수합니다.

## 우선: 노래 없이 만들 수 있는 8개 놀이, 안내 56줄

각 줄을 별도 파일로 저장합니다. 목표 파일명은 나중에 `assets/audio/`에 둘 승인본의 이름입니다. 미검수 녹음은 `production/audio_pending/`에만 보관하세요.

| 놀이 ID | 줄 ID | 정확한 대본 | 승인본 목표 경로 |
|---|---|---|---|
| animal_tracks | intro | 모모숲 그림 속 길에 발자국이 남았어. 천천히 살펴볼까? | assets/audio/animal_tracks__intro.m4a |
| animal_tracks | prompt | 마음에 드는 발자국을 눌러 봐. | assets/audio/animal_tracks__prompt.m4a |
| animal_tracks | choice_0 | 동그란 발자국 | assets/audio/animal_tracks__choice_0.m4a |
| animal_tracks | reaction_0 | 동글동글! 곰 두리가 지나갔나 봐. | assets/audio/animal_tracks__reaction_0.m4a |
| animal_tracks | choice_1 | 작은 새 발자국 | assets/audio/animal_tracks__choice_1.m4a |
| animal_tracks | reaction_1 | 콩콩! 모모가 걸어간 길이야. | assets/audio/animal_tracks__reaction_1.m4a |
| animal_tracks | choice_2 | 길쭉한 발자국 | assets/audio/animal_tracks__choice_2.m4a |
| animal_tracks | reaction_2 | 사뿐사뿐! 숲 친구가 남긴 흔적이네. | assets/audio/animal_tracks__reaction_2.m4a |
| animal_tracks | outro | 발자국 구경은 여기까지. 모모가 손을 흔들어! | assets/audio/animal_tracks__outro.m4a |
| animal_tracks | offscreen | 식탁이나 바닥에서 동그란 모양 하나를 찾아봐. | assets/audio/animal_tracks__offscreen.m4a |
| feeling_cloud | intro | 누리 구름은 오늘 어떤 색일까? 정답은 없어. | assets/audio/feeling_cloud__intro.m4a |
| feeling_cloud | prompt | 마음에 드는 색으로 구름 주변을 칠해 봐. | assets/audio/feeling_cloud__prompt.m4a |
| feeling_cloud | outro | 네가 고른 색으로 구름이 달라졌어. 이제 그림을 쉬게 해 주자. | assets/audio/feeling_cloud__outro.m4a |
| feeling_cloud | offscreen | 가족에게 네가 고른 색 이야기를 해 봐. | assets/audio/feeling_cloud__offscreen.m4a |
| momo_faces | intro | 모모가 오늘 여러 표정을 지어. 하나씩 만나 볼까? | assets/audio/momo_faces__intro.m4a |
| momo_faces | prompt | 표정을 골라 모모의 이야기를 들어 봐. | assets/audio/momo_faces__prompt.m4a |
| momo_faces | choice_0 | 반가운 표정 | assets/audio/momo_faces__choice_0.m4a |
| momo_faces | reaction_0 | 친구를 만나서 반가운가 봐! | assets/audio/momo_faces__reaction_0.m4a |
| momo_faces | choice_1 | 조용한 표정 | assets/audio/momo_faces__choice_1.m4a |
| momo_faces | reaction_1 | 잠깐 쉬고 싶은 마음도 있어. | assets/audio/momo_faces__reaction_1.m4a |
| momo_faces | choice_2 | 속상한 표정 | assets/audio/momo_faces__choice_2.m4a |
| momo_faces | reaction_2 | 속상할 땐 가까운 어른에게 말할 수 있어. | assets/audio/momo_faces__reaction_2.m4a |
| momo_faces | outro | 여러 마음을 만나 봤어. 모모는 잠깐 쉬러 갈게. | assets/audio/momo_faces__outro.m4a |
| momo_faces | offscreen | 가족에게 지금 마음을 한마디로 말해 봐. | assets/audio/momo_faces__offscreen.m4a |
| hand_shapes | intro | 화면에 큰 손 모양이 있어. 네 마음대로 선을 더해 볼까? | assets/audio/hand_shapes__intro.m4a |
| hand_shapes | prompt | 화면에 손 모양이나 마음에 드는 선을 그려 봐. | assets/audio/hand_shapes__prompt.m4a |
| hand_shapes | outro | 네가 그은 선들이 남았어. 이제 손가락을 쉬게 하자. | assets/audio/hand_shapes__outro.m4a |
| hand_shapes | offscreen | 종이가 있으면 보호자와 함께 손바닥 모양을 살펴봐. | assets/audio/hand_shapes__offscreen.m4a |
| bus_stop | intro | 그림 속 모모숲 버스가 멈췄어. 친구들이 차례로 타려고 해. | assets/audio/bus_stop__intro.m4a |
| bus_stop | prompt | 그림 속 친구를 골라 빈 좌석에 앉혀 보자. | assets/audio/bus_stop__prompt.m4a |
| bus_stop | choice_0 | 모모 | assets/audio/bus_stop__choice_0.m4a |
| bus_stop | reaction_0 | 모모가 자리에 앉았어. 고마워! | assets/audio/bus_stop__reaction_0.m4a |
| bus_stop | choice_1 | 두리 | assets/audio/bus_stop__choice_1.m4a |
| bus_stop | reaction_1 | 두리가 조용히 자리에 앉았어. | assets/audio/bus_stop__reaction_1.m4a |
| bus_stop | choice_2 | 누리 | assets/audio/bus_stop__choice_2.m4a |
| bus_stop | reaction_2 | 누리가 창밖을 바라봐. 버스는 아직 멈춰 있어. | assets/audio/bus_stop__reaction_2.m4a |
| bus_stop | outro | 친구들이 다 앉았어. 버스 이야기는 여기서 마칠게. | assets/audio/bus_stop__outro.m4a |
| bus_stop | offscreen | 밖에서 버스를 보면 어른과 함께 색을 찾아봐. | assets/audio/bus_stop__offscreen.m4a |
| my_bus | intro | 모모숲 버스에 네가 좋아하는 색을 입혀 보자. | assets/audio/my_bus__intro.m4a |
| my_bus | prompt | 버스 안팎에 자유롭게 선을 그려 봐. | assets/audio/my_bus__prompt.m4a |
| my_bus | outro | 네가 그린 버스 이야기는 여기까지. 이제 손을 쉬게 하자. | assets/audio/my_bus__outro.m4a |
| my_bus | offscreen | 방금 그린 버스의 바퀴를 가족에게 이야기해 봐. | assets/audio/my_bus__offscreen.m4a |
| forest_weather | intro | 모모숲에는 여러 날씨가 있어. 누리가 보여 줄게. | assets/audio/forest_weather__intro.m4a |
| forest_weather | prompt | 하나를 골라 숲의 모습을 보자. | assets/audio/forest_weather__prompt.m4a |
| forest_weather | choice_0 | 맑은 하늘 | assets/audio/forest_weather__choice_0.m4a |
| forest_weather | reaction_0 | 햇살이 조용히 비춰. | assets/audio/forest_weather__reaction_0.m4a |
| forest_weather | choice_1 | 가벼운 비 | assets/audio/forest_weather__choice_1.m4a |
| forest_weather | reaction_1 | 빗방울이 톡톡. 숲이 촉촉해졌어. | assets/audio/forest_weather__reaction_1.m4a |
| forest_weather | choice_2 | 부드러운 바람 | assets/audio/forest_weather__choice_2.m4a |
| forest_weather | reaction_2 | 나뭇잎이 살랑살랑 움직여. | assets/audio/forest_weather__reaction_2.m4a |
| forest_weather | outro | 날씨 구경은 여기까지. 창밖을 어른과 함께 살펴볼까? | assets/audio/forest_weather__outro.m4a |
| forest_weather | offscreen | 창밖 날씨를 어른과 함께 살펴봐. | assets/audio/forest_weather__offscreen.m4a |
| after_rain_garden | intro | 비가 그친 정원은 어떤 색일까? 두리가 궁금해. | assets/audio/after_rain_garden__intro.m4a |
| after_rain_garden | prompt | 그림 속 잎과 꽃 주변을 마음대로 칠해 봐. | assets/audio/after_rain_garden__prompt.m4a |
| after_rain_garden | outro | 정원이 네 색으로 채워졌어. 그림을 쉬게 해 주자. | assets/audio/after_rain_garden__outro.m4a |
| after_rain_garden | offscreen | 집 안에서 식물이나 잎 모양을 찾아봐. | assets/audio/after_rain_garden__offscreen.m4a |

## 이후: 노래 놀이 2개

두 놀이의 안내 8줄은 아래와 같습니다. 노래 자체는 `production/FLOW_MUSIC_PRODUCTION.md`의 원곡 규격과 가사 검수를 별도로 따라야 합니다.

| 놀이 ID | 줄 ID | 정확한 대본 | 승인본 목표 경로 |
|---|---|---|---|
| animal_steps_song | intro | 두리와 앉아서 손으로 동물 움직임을 흉내 내자. | assets/audio/animal_steps_song__intro.m4a |
| animal_steps_song | prompt | 노래를 들으며 손을 움직여 봐. 안 해도 괜찮아. | assets/audio/animal_steps_song__prompt.m4a |
| animal_steps_song | outro | 동물 친구들이 쉬는 시간이야. 우리 손도 쉬자. | assets/audio/animal_steps_song__outro.m4a |
| animal_steps_song | offscreen | 가족에게 손으로 작은 새 인사를 해 봐. | assets/audio/animal_steps_song__offscreen.m4a |
| body_hello | intro | 누리와 편하게 앉아 손과 어깨로 인사해 보자. | assets/audio/body_hello__intro.m4a |
| body_hello | prompt | 할 수 있는 만큼만 따라 해 봐. | assets/audio/body_hello__prompt.m4a |
| body_hello | outro | 우리 몸의 인사는 여기까지. 편하게 쉬어도 좋아. | assets/audio/body_hello__outro.m4a |
| body_hello | offscreen | 가족에게 손을 흔들며 안녕 해 봐. | assets/audio/body_hello__offscreen.m4a |

## 승인 전 확인

1. 각 줄의 실제 발음과 대본 일치, 시작·끝 무음, 피크 음량을 사람이 끝까지 듣고 확인합니다.
2. 파일별 녹음자·녹음일·원본·권리 근거·SHA-256·검수일을 기록합니다.
3. 필요한 줄이 모두 승인되고 이미지·대본·조작도 승인되기 전에는 `audio_manifest.json`의 상태나 카탈로그 승인 날짜를 바꾸지 않습니다.
