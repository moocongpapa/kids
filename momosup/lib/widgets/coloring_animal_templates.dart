import 'package:flutter/material.dart';
import 'coloring_templates.dart';

/// 30 cute, toddler-friendly animal and creature templates.
class ColoringAnimalCatalog {
  static List<ColoringTemplate> get all => [
        _rabbitTemplate,
        _bearTemplate,
        _catTemplate,
        _puppyTemplate,
        _pigTemplate,
        _dinosaurTemplate,
        _butterflyTemplate,
        _penguinTemplate,
        _lionTemplate,
        _elephantTemplate,
        _giraffeTemplate,
        _monkeyTemplate,
        _frogTemplate,
        _duckTemplate,
        _pandaTemplate,
        _koalaTemplate,
        _tigerTemplate,
        _sheepTemplate,
        _chickTemplate,
        _turtleTemplate,
        _octopusTemplate,
        _crabTemplate,
        _beeTemplate,
        _ladybugTemplate,
        _owlTemplate,
        _squirrelTemplate,
        _hedgehogTemplate,
        _flamingoTemplate,
        _sealTemplate,
        _whaleTemplate,
      ];

  // 1. 🐰 포근 토끼
  static final _rabbitTemplate = ColoringTemplate(
    id: 'rabbit',
    title: '포근 토끼',
    emoji: '🐰',
    createSegments: () {
      final leftEar = Path()..addOval(const Rect.fromLTWH(80, 20, 36, 100));
      final rightEar = Path()..addOval(const Rect.fromLTWH(164, 20, 36, 100));
      final innerEarLeft = Path()..addOval(const Rect.fromLTWH(88, 35, 20, 70));
      final innerEarRight = Path()..addOval(const Rect.fromLTWH(172, 35, 20, 70));
      final head = Path()..addOval(const Rect.fromLTWH(70, 95, 140, 115));
      final snout = Path()..addOval(const Rect.fromLTWH(115, 150, 50, 35));
      final cheekLeft = Path()..addOval(const Rect.fromLTWH(82, 145, 22, 18));
      final cheekRight = Path()..addOval(const Rect.fromLTWH(176, 145, 22, 18));
      final body = Path()
        ..moveTo(90, 195)
        ..quadraticBezierTo(55, 240, 65, 280)
        ..lineTo(215, 280)
        ..quadraticBezierTo(225, 240, 190, 195)
        ..close();
      final ribbon = Path()
        ..moveTo(140, 200)
        ..lineTo(110, 188)
        ..lineTo(110, 212)
        ..close()
        ..moveTo(140, 200)
        ..lineTo(170, 188)
        ..lineTo(170, 212)
        ..close()
        ..addOval(const Rect.fromLTWH(132, 192, 16, 16));

      return [
        ColoringSegment(id: 'ear_l', name: '왼쪽 귀', path: leftEar),
        ColoringSegment(id: 'ear_r', name: '오른쪽 귀', path: rightEar),
        ColoringSegment(id: 'inner_ear_l', name: '왼쪽 귓속', path: innerEarLeft),
        ColoringSegment(id: 'inner_ear_r', name: '오른쪽 귓속', path: innerEarRight),
        ColoringSegment(id: 'body', name: '몸통', path: body),
        ColoringSegment(id: 'head', name: '얼굴', path: head),
        ColoringSegment(id: 'snout', name: '주둥이', path: snout),
        ColoringSegment(id: 'cheek_l', name: '왼쪽 볼', path: cheekLeft),
        ColoringSegment(id: 'cheek_r', name: '오른쪽 볼', path: cheekRight),
        ColoringSegment(id: 'ribbon', name: '리본', path: ribbon),
      ];
    },
  );

  // 2. 🐻 아기 곰
  static final _bearTemplate = ColoringTemplate(
    id: 'bear',
    title: '아기 곰',
    emoji: '🐻',
    createSegments: () {
      final leftEar = Path()..addOval(const Rect.fromLTWH(65, 55, 48, 48));
      final rightEar = Path()..addOval(const Rect.fromLTWH(167, 55, 48, 48));
      final innerEarLeft = Path()..addOval(const Rect.fromLTWH(75, 65, 28, 28));
      final innerEarRight = Path()..addOval(const Rect.fromLTWH(177, 65, 28, 28));
      final head = Path()..addOval(const Rect.fromLTWH(70, 80, 140, 120));
      final snout = Path()..addOval(const Rect.fromLTWH(110, 135, 60, 45));
      final cheekLeft = Path()..addOval(const Rect.fromLTWH(82, 145, 20, 16));
      final cheekRight = Path()..addOval(const Rect.fromLTWH(178, 145, 20, 16));
      final body = Path()
        ..moveTo(90, 195)
        ..quadraticBezierTo(55, 235, 65, 280)
        ..lineTo(215, 280)
        ..quadraticBezierTo(225, 235, 190, 195)
        ..close();
      final belly = Path()..addOval(const Rect.fromLTWH(100, 215, 80, 60));
      final bowTie = Path()
        ..moveTo(140, 200)
        ..lineTo(120, 192)
        ..lineTo(120, 212)
        ..close()
        ..moveTo(140, 200)
        ..lineTo(160, 192)
        ..lineTo(160, 212)
        ..close()
        ..addOval(const Rect.fromLTWH(135, 195, 10, 10));

      return [
        ColoringSegment(id: 'ear_l', name: '왼쪽 귀', path: leftEar),
        ColoringSegment(id: 'ear_r', name: '오른쪽 귀', path: rightEar),
        ColoringSegment(id: 'inner_ear_l', name: '왼쪽 귓속', path: innerEarLeft),
        ColoringSegment(id: 'inner_ear_r', name: '오른쪽 귓속', path: innerEarRight),
        ColoringSegment(id: 'body', name: '몸통', path: body),
        ColoringSegment(id: 'belly', name: '배', path: belly),
        ColoringSegment(id: 'head', name: '얼굴', path: head),
        ColoringSegment(id: 'snout', name: '주둥이', path: snout),
        ColoringSegment(id: 'cheek_l', name: '왼쪽 볼', path: cheekLeft),
        ColoringSegment(id: 'cheek_r', name: '오른쪽 볼', path: cheekRight),
        ColoringSegment(id: 'bowtie', name: '나비넥타이', path: bowTie),
      ];
    },
  );

  // 3. 🐱 숲속 야옹이
  static final _catTemplate = ColoringTemplate(
    id: 'cat',
    title: '숲속 야옹이',
    emoji: '🐱',
    createSegments: () {
      final leftEar = Path()..moveTo(80, 120)..lineTo(70, 50)..lineTo(120, 95)..close();
      final rightEar = Path()..moveTo(160, 95)..lineTo(210, 50)..lineTo(200, 120)..close();
      final innerEarL = Path()..moveTo(85, 110)..lineTo(78, 65)..lineTo(112, 95)..close();
      final innerEarR = Path()..moveTo(168, 95)..lineTo(202, 65)..lineTo(195, 110)..close();
      final head = Path()..addOval(const Rect.fromLTWH(75, 80, 130, 115));
      final cheekL = Path()..addOval(const Rect.fromLTWH(85, 140, 20, 16));
      final cheekR = Path()..addOval(const Rect.fromLTWH(175, 140, 20, 16));
      final body = Path()
        ..moveTo(95, 185)
        ..quadraticBezierTo(70, 225, 80, 280)
        ..lineTo(200, 280)
        ..quadraticBezierTo(210, 225, 185, 185)
        ..close();
      final tail = Path()
        ..moveTo(195, 260)
        ..quadraticBezierTo(250, 250, 240, 200)
        ..quadraticBezierTo(230, 190, 225, 205)
        ..quadraticBezierTo(230, 235, 190, 275)
        ..close();
      final bell = Path()..addOval(const Rect.fromLTWH(131, 183, 18, 18));

      return [
        ColoringSegment(id: 'tail', name: '꼬리', path: tail),
        ColoringSegment(id: 'ear_l', name: '왼쪽 귀', path: leftEar),
        ColoringSegment(id: 'ear_r', name: '오른쪽 귀', path: rightEar),
        ColoringSegment(id: 'inner_ear_l', name: '왼쪽 귓속', path: innerEarL),
        ColoringSegment(id: 'inner_ear_r', name: '오른쪽 귓속', path: innerEarR),
        ColoringSegment(id: 'body', name: '몸통', path: body),
        ColoringSegment(id: 'head', name: '얼굴', path: head),
        ColoringSegment(id: 'cheek_l', name: '왼쪽 볼', path: cheekL),
        ColoringSegment(id: 'cheek_r', name: '오른쪽 볼', path: cheekR),
        ColoringSegment(id: 'bell', name: '방울', path: bell),
      ];
    },
  );

  // 4. 🐶 멍멍 강아지
  static final _puppyTemplate = ColoringTemplate(
    id: 'puppy',
    title: '멍멍 강아지',
    emoji: '🐶',
    createSegments: () {
      final earL = Path()
        ..moveTo(85, 85)
        ..quadraticBezierTo(45, 120, 55, 175)
        ..quadraticBezierTo(75, 190, 95, 155)
        ..close();
      final earR = Path()
        ..moveTo(195, 85)
        ..quadraticBezierTo(235, 120, 225, 175)
        ..quadraticBezierTo(205, 190, 185, 155)
        ..close();
      final head = Path()..addOval(const Rect.fromLTWH(75, 70, 130, 120));
      final snout = Path()..addOval(const Rect.fromLTWH(105, 130, 70, 50));
      final nose = Path()..addOval(const Rect.fromLTWH(127, 138, 26, 20));
      final cheekL = Path()..addOval(const Rect.fromLTWH(85, 135, 20, 16));
      final cheekR = Path()..addOval(const Rect.fromLTWH(175, 135, 20, 16));
      final collar = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(95, 185, 90, 18),
          const Radius.circular(8),
        ));
      final body = Path()
        ..moveTo(95, 195)
        ..quadraticBezierTo(65, 235, 75, 280)
        ..lineTo(205, 280)
        ..quadraticBezierTo(215, 235, 185, 195)
        ..close();
      final tail = Path()
        ..moveTo(200, 250)
        ..quadraticBezierTo(250, 230, 245, 190)
        ..quadraticBezierTo(235, 195, 215, 235)
        ..close();

      return [
        ColoringSegment(id: 'tail', name: '꼬리', path: tail),
        ColoringSegment(id: 'ear_l', name: '왼쪽 귀', path: earL),
        ColoringSegment(id: 'ear_r', name: '오른쪽 귀', path: earR),
        ColoringSegment(id: 'body', name: '몸통', path: body),
        ColoringSegment(id: 'collar', name: '목줄', path: collar),
        ColoringSegment(id: 'head', name: '얼굴', path: head),
        ColoringSegment(id: 'snout', name: '주둥이', path: snout),
        ColoringSegment(id: 'nose', name: '코', path: nose),
        ColoringSegment(id: 'cheek_l', name: '왼쪽 볼', path: cheekL),
        ColoringSegment(id: 'cheek_r', name: '오른쪽 볼', path: cheekR),
      ];
    },
  );

  // 5. 🐷 꿀꿀 돼지
  static final _pigTemplate = ColoringTemplate(
    id: 'pig',
    title: '꿀꿀 돼지',
    emoji: '🐷',
    createSegments: () {
      final earL = Path()..moveTo(85, 100)..lineTo(60, 45)..lineTo(110, 75)..close();
      final earR = Path()..moveTo(195, 100)..lineTo(220, 45)..lineTo(170, 75)..close();
      final innerEarL = Path()..moveTo(88, 90)..lineTo(72, 58)..lineTo(105, 76)..close();
      final innerEarR = Path()..moveTo(192, 90)..lineTo(208, 58)..lineTo(175, 76)..close();
      final head = Path()..addOval(const Rect.fromLTWH(70, 70, 140, 130));
      final snout = Path()..addOval(const Rect.fromLTWH(110, 135, 60, 45));
      final nostrilL = Path()..addOval(const Rect.fromLTWH(123, 148, 12, 18));
      final nostrilR = Path()..addOval(const Rect.fromLTWH(145, 148, 12, 18));
      final cheekL = Path()..addOval(const Rect.fromLTWH(80, 140, 22, 18));
      final cheekR = Path()..addOval(const Rect.fromLTWH(178, 140, 22, 18));
      final body = Path()
        ..moveTo(90, 195)
        ..quadraticBezierTo(55, 235, 70, 280)
        ..lineTo(210, 280)
        ..quadraticBezierTo(225, 235, 190, 195)
        ..close();
      final tail = Path()
        ..moveTo(205, 240)
        ..quadraticBezierTo(245, 245, 240, 220)
        ..quadraticBezierTo(225, 215, 230, 235)
        ..close();

      return [
        ColoringSegment(id: 'tail', name: '꼬리', path: tail),
        ColoringSegment(id: 'ear_l', name: '왼쪽 귀', path: earL),
        ColoringSegment(id: 'ear_r', name: '오른쪽 귀', path: earR),
        ColoringSegment(id: 'inner_ear_l', name: '왼쪽 귓속', path: innerEarL),
        ColoringSegment(id: 'inner_ear_r', name: '오른쪽 귓속', path: innerEarR),
        ColoringSegment(id: 'body', name: '몸통', path: body),
        ColoringSegment(id: 'head', name: '얼굴', path: head),
        ColoringSegment(id: 'snout', name: '돼지 코', path: snout),
        ColoringSegment(id: 'nostril_l', name: '왼쪽 콧구멍', path: nostrilL),
        ColoringSegment(id: 'nostril_r', name: '오른쪽 콧구멍', path: nostrilR),
        ColoringSegment(id: 'cheek_l', name: '왼쪽 볼', path: cheekL),
        ColoringSegment(id: 'cheek_r', name: '오른쪽 볼', path: cheekR),
      ];
    },
  );

  // 6. 🦖 아기 공룡
  static final _dinosaurTemplate = ColoringTemplate(
    id: 'dinosaur',
    title: '아기 공룡',
    emoji: '🦖',
    createSegments: () {
      final spike1 = Path()..moveTo(85, 75)..lineTo(65, 45)..lineTo(100, 65)..close();
      final spike2 = Path()..moveTo(70, 115)..lineTo(45, 95)..lineTo(75, 125)..close();
      final spike3 = Path()..moveTo(60, 160)..lineTo(35, 145)..lineTo(68, 175)..close();
      final head = Path()
        ..moveTo(90, 85)
        ..quadraticBezierTo(110, 45, 165, 55)
        ..quadraticBezierTo(205, 65, 200, 115)
        ..quadraticBezierTo(175, 140, 140, 130)
        ..quadraticBezierTo(110, 135, 95, 115)
        ..close();
      final cheek = Path()..addOval(const Rect.fromLTWH(145, 105, 22, 18));
      final body = Path()
        ..moveTo(105, 125)
        ..quadraticBezierTo(60, 170, 70, 250)
        ..lineTo(190, 250)
        ..quadraticBezierTo(200, 180, 145, 125)
        ..close();
      final belly = Path()..addOval(const Rect.fromLTWH(115, 155, 65, 80));
      final tail = Path()
        ..moveTo(75, 230)
        ..quadraticBezierTo(25, 250, 15, 220)
        ..quadraticBezierTo(40, 210, 75, 210)
        ..close();
      final legL = Path()..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(90, 240, 32, 40), const Radius.circular(12)));
      final legR = Path()..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(150, 240, 32, 40), const Radius.circular(12)));

      return [
        ColoringSegment(id: 'tail', name: '꼬리', path: tail),
        ColoringSegment(id: 'spike_1', name: '머리 뿔', path: spike1),
        ColoringSegment(id: 'spike_2', name: '등 뿔 1', path: spike2),
        ColoringSegment(id: 'spike_3', name: '등 뿔 2', path: spike3),
        ColoringSegment(id: 'leg_l', name: '왼쪽 다리', path: legL),
        ColoringSegment(id: 'leg_r', name: '오른쪽 다리', path: legR),
        ColoringSegment(id: 'body', name: '몸통', path: body),
        ColoringSegment(id: 'belly', name: '배', path: belly),
        ColoringSegment(id: 'head', name: '공룡 머리', path: head),
        ColoringSegment(id: 'cheek', name: '볼', path: cheek),
      ];
    },
  );

  // 7. 🦋 알록 나비
  static final _butterflyTemplate = ColoringTemplate(
    id: 'butterfly',
    title: '알록 나비',
    emoji: '🦋',
    createSegments: () {
      final wingTL = Path()
        ..moveTo(135, 110)
        ..quadraticBezierTo(65, 30, 30, 70)
        ..quadraticBezierTo(25, 135, 130, 145)
        ..close();
      final wingTR = Path()
        ..moveTo(145, 110)
        ..quadraticBezierTo(215, 30, 250, 70)
        ..quadraticBezierTo(255, 135, 150, 145)
        ..close();
      final wingBL = Path()
        ..moveTo(132, 150)
        ..quadraticBezierTo(50, 160, 55, 225)
        ..quadraticBezierTo(95, 255, 135, 190)
        ..close();
      final wingBR = Path()
        ..moveTo(148, 150)
        ..quadraticBezierTo(230, 160, 225, 225)
        ..quadraticBezierTo(185, 255, 145, 190)
        ..close();
      final spotTL = Path()..addOval(const Rect.fromLTWH(60, 75, 32, 32));
      final spotTR = Path()..addOval(const Rect.fromLTWH(188, 75, 32, 32));
      final spotBL = Path()..addOval(const Rect.fromLTWH(80, 190, 24, 24));
      final spotBR = Path()..addOval(const Rect.fromLTWH(176, 190, 24, 24));
      final body = Path()..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(130, 100, 20, 110), const Radius.circular(10)));
      final head = Path()..addOval(const Rect.fromLTWH(126, 75, 28, 28));
      final antL = Path()..addOval(const Rect.fromLTWH(115, 48, 14, 14));
      final antR = Path()..addOval(const Rect.fromLTWH(151, 48, 14, 14));

      return [
        ColoringSegment(id: 'wing_tl', name: '왼쪽 윗날개', path: wingTL),
        ColoringSegment(id: 'wing_tr', name: '오른쪽 윗날개', path: wingTR),
        ColoringSegment(id: 'wing_bl', name: '왼쪽 아랫날개', path: wingBL),
        ColoringSegment(id: 'wing_br', name: '오른쪽 아랫날개', path: wingBR),
        ColoringSegment(id: 'spot_tl', name: '왼쪽 큰 무늬', path: spotTL),
        ColoringSegment(id: 'spot_tr', name: '오른쪽 큰 무늬', path: spotTR),
        ColoringSegment(id: 'spot_bl', name: '왼쪽 작은 무늬', path: spotBL),
        ColoringSegment(id: 'spot_br', name: '오른쪽 작은 무늬', path: spotBR),
        ColoringSegment(id: 'body', name: '몸통', path: body),
        ColoringSegment(id: 'head', name: '머리', path: head),
        ColoringSegment(id: 'ant_l', name: '왼쪽 더듬이', path: antL),
        ColoringSegment(id: 'ant_r', name: '오른쪽 더듬이', path: antR),
      ];
    },
  );

  // 8. 🐧 뒤뚱 펭귄
  static final _penguinTemplate = ColoringTemplate(
    id: 'penguin',
    title: '뒤뚱 펭귄',
    emoji: '🐧',
    createSegments: () {
      final body = Path()
        ..moveTo(140, 50)
        ..quadraticBezierTo(75, 60, 75, 170)
        ..quadraticBezierTo(70, 260, 140, 260)
        ..quadraticBezierTo(210, 260, 205, 170)
        ..quadraticBezierTo(205, 60, 140, 50)
        ..close();
      final belly = Path()..addOval(const Rect.fromLTWH(95, 110, 90, 135));
      final wingL = Path()
        ..moveTo(76, 130)
        ..quadraticBezierTo(40, 170, 55, 215)
        ..quadraticBezierTo(75, 210, 80, 160)
        ..close();
      final wingR = Path()
        ..moveTo(204, 130)
        ..quadraticBezierTo(240, 170, 225, 215)
        ..quadraticBezierTo(205, 210, 200, 160)
        ..close();
      final cheekL = Path()..addOval(const Rect.fromLTWH(92, 105, 20, 16));
      final cheekR = Path()..addOval(const Rect.fromLTWH(168, 105, 20, 16));
      final beak = Path()..moveTo(125, 95)..lineTo(140, 115)..lineTo(155, 95)..close();
      final footL = Path()..addOval(const Rect.fromLTWH(95, 250, 40, 22));
      final footR = Path()..addOval(const Rect.fromLTWH(145, 250, 40, 22));

      return [
        ColoringSegment(id: 'foot_l', name: '왼쪽 발', path: footL),
        ColoringSegment(id: 'foot_r', name: '오른쪽 발', path: footR),
        ColoringSegment(id: 'wing_l', name: '왼쪽 날개', path: wingL),
        ColoringSegment(id: 'wing_r', name: '오른쪽 날개', path: wingR),
        ColoringSegment(id: 'body', name: '검은 몸통', path: body),
        ColoringSegment(id: 'belly', name: '하얀 배', path: belly),
        ColoringSegment(id: 'cheek_l', name: '왼쪽 볼', path: cheekL),
        ColoringSegment(id: 'cheek_r', name: '오른쪽 볼', path: cheekR),
        ColoringSegment(id: 'beak', name: '부리', path: beak),
      ];
    },
  );

  // 9. 🦁 멋쟁이 사자
  static final _lionTemplate = ColoringTemplate(
    id: 'lion',
    title: '멋쟁이 사자',
    emoji: '🦁',
    createSegments: () {
      final mane = Path()..addOval(const Rect.fromLTWH(55, 45, 170, 165));
      final earL = Path()..addOval(const Rect.fromLTWH(75, 60, 36, 36));
      final earR = Path()..addOval(const Rect.fromLTWH(169, 60, 36, 36));
      final head = Path()..addOval(const Rect.fromLTWH(80, 75, 120, 105));
      final snout = Path()..addOval(const Rect.fromLTWH(115, 125, 50, 36));
      final nose = Path()..moveTo(130, 132)..lineTo(150, 132)..lineTo(140, 144)..close();
      final cheekL = Path()..addOval(const Rect.fromLTWH(90, 130, 18, 14));
      final cheekR = Path()..addOval(const Rect.fromLTWH(172, 130, 18, 14));
      final body = Path()
        ..moveTo(95, 195)
        ..quadraticBezierTo(70, 235, 75, 280)
        ..lineTo(205, 280)
        ..quadraticBezierTo(210, 235, 185, 195)
        ..close();
      final tail = Path()
        ..moveTo(195, 260)
        ..quadraticBezierTo(245, 250, 240, 205)
        ..quadraticBezierTo(230, 215, 210, 260)
        ..close()
        ..addOval(const Rect.fromLTWH(230, 195, 20, 20));

      return [
        ColoringSegment(id: 'tail', name: '꼬리', path: tail),
        ColoringSegment(id: 'mane', name: '사자 갈기', path: mane),
        ColoringSegment(id: 'ear_l', name: '왼쪽 귀', path: earL),
        ColoringSegment(id: 'ear_r', name: '오른쪽 귀', path: earR),
        ColoringSegment(id: 'body', name: '몸통', path: body),
        ColoringSegment(id: 'head', name: '얼굴', path: head),
        ColoringSegment(id: 'snout', name: '주둥이', path: snout),
        ColoringSegment(id: 'nose', name: '코', path: nose),
        ColoringSegment(id: 'cheek_l', name: '왼쪽 볼', path: cheekL),
        ColoringSegment(id: 'cheek_r', name: '오른쪽 볼', path: cheekR),
      ];
    },
  );

  // 10. 🐘 숲속 코끼리
  static final _elephantTemplate = ColoringTemplate(
    id: 'elephant',
    title: '숲속 코끼리',
    emoji: '🐘',
    createSegments: () {
      final earL = Path()..addOval(const Rect.fromLTWH(35, 80, 65, 85));
      final earR = Path()..addOval(const Rect.fromLTWH(180, 80, 65, 85));
      final innerEarL = Path()..addOval(const Rect.fromLTWH(48, 95, 40, 55));
      final innerEarR = Path()..addOval(const Rect.fromLTWH(192, 95, 40, 55));
      final head = Path()..addOval(const Rect.fromLTWH(80, 75, 120, 110));
      final trunk = Path()
        ..moveTo(125, 145)
        ..quadraticBezierTo(120, 215, 150, 215)
        ..quadraticBezierTo(165, 205, 155, 190)
        ..quadraticBezierTo(140, 190, 145, 145)
        ..close();
      final tuskL = Path()..moveTo(115, 155)..lineTo(105, 180)..lineTo(125, 165)..close();
      final tuskR = Path()..moveTo(165, 155)..lineTo(175, 180)..lineTo(155, 165)..close();
      final body = Path()
        ..moveTo(90, 185)
        ..quadraticBezierTo(60, 225, 70, 280)
        ..lineTo(210, 280)
        ..quadraticBezierTo(220, 225, 190, 185)
        ..close();

      return [
        ColoringSegment(id: 'ear_l', name: '왼쪽 큰 귀', path: earL),
        ColoringSegment(id: 'ear_r', name: '오른쪽 큰 귀', path: earR),
        ColoringSegment(id: 'inner_ear_l', name: '왼쪽 귓속', path: innerEarL),
        ColoringSegment(id: 'inner_ear_r', name: '오른쪽 귓속', path: innerEarR),
        ColoringSegment(id: 'body', name: '몸통', path: body),
        ColoringSegment(id: 'head', name: '얼굴', path: head),
        ColoringSegment(id: 'trunk', name: '긴 코', path: trunk),
        ColoringSegment(id: 'tusk_l', name: '왼쪽 상아', path: tuskL),
        ColoringSegment(id: 'tusk_r', name: '오른쪽 상아', path: tuskR),
      ];
    },
  );

  // 11. 🦒 키다리 기린
  static final _giraffeTemplate = ColoringTemplate(
    id: 'giraffe',
    title: '키다리 기린',
    emoji: '🦒',
    createSegments: () {
      final hornL = Path()..addOval(const Rect.fromLTWH(105, 30, 14, 25));
      final hornR = Path()..addOval(const Rect.fromLTWH(161, 30, 14, 25));
      final earL = Path()..addOval(const Rect.fromLTWH(80, 55, 30, 20));
      final earR = Path()..addOval(const Rect.fromLTWH(170, 55, 30, 20));
      final head = Path()..addOval(const Rect.fromLTWH(100, 50, 80, 75));
      final snout = Path()..addOval(const Rect.fromLTWH(110, 85, 60, 42));
      final neck = Path()
        ..moveTo(118, 120)
        ..lineTo(110, 220)
        ..lineTo(170, 220)
        ..lineTo(162, 120)
        ..close();
      final spot1 = Path()..addOval(const Rect.fromLTWH(125, 135, 26, 22));
      final spot2 = Path()..addOval(const Rect.fromLTWH(135, 170, 24, 20));
      final body = Path()
        ..moveTo(95, 220)
        ..quadraticBezierTo(70, 240, 80, 280)
        ..lineTo(200, 280)
        ..quadraticBezierTo(210, 240, 185, 220)
        ..close();

      return [
        ColoringSegment(id: 'horn_l', name: '왼쪽 뿔', path: hornL),
        ColoringSegment(id: 'horn_r', name: '오른쪽 뿔', path: hornR),
        ColoringSegment(id: 'ear_l', name: '왼쪽 귀', path: earL),
        ColoringSegment(id: 'ear_r', name: '오른쪽 귀', path: earR),
        ColoringSegment(id: 'body', name: '몸통', path: body),
        ColoringSegment(id: 'neck', name: '긴 목', path: neck),
        ColoringSegment(id: 'spot_1', name: '기린 얼룩 1', path: spot1),
        ColoringSegment(id: 'spot_2', name: '기린 얼룩 2', path: spot2),
        ColoringSegment(id: 'head', name: '얼굴', path: head),
        ColoringSegment(id: 'snout', name: '주둥이', path: snout),
      ];
    },
  );

  // 12. 🐵 장난꾸러기 원숭이
  static final _monkeyTemplate = ColoringTemplate(
    id: 'monkey',
    title: '원숭이',
    emoji: '🐵',
    createSegments: () {
      final earL = Path()..addOval(const Rect.fromLTWH(55, 80, 42, 42));
      final earR = Path()..addOval(const Rect.fromLTWH(183, 80, 42, 42));
      final head = Path()..addOval(const Rect.fromLTWH(75, 65, 130, 115));
      final faceMask = Path()
        ..addOval(const Rect.fromLTWH(90, 85, 50, 45))
        ..addOval(const Rect.fromLTWH(140, 85, 50, 45))
        ..addOval(const Rect.fromLTWH(105, 110, 70, 55));
      final body = Path()
        ..moveTo(95, 180)
        ..quadraticBezierTo(70, 225, 80, 275)
        ..lineTo(200, 275)
        ..quadraticBezierTo(210, 225, 185, 180)
        ..close();
      final belly = Path()..addOval(const Rect.fromLTWH(108, 195, 64, 60));
      final banana = Path()
        ..moveTo(180, 220)
        ..quadraticBezierTo(230, 230, 235, 270)
        ..quadraticBezierTo(215, 265, 180, 240)
        ..close();

      return [
        ColoringSegment(id: 'banana', name: '바나나', path: banana),
        ColoringSegment(id: 'ear_l', name: '왼쪽 큰 귀', path: earL),
        ColoringSegment(id: 'ear_r', name: '오른쪽 큰 귀', path: earR),
        ColoringSegment(id: 'body', name: '몸통', path: body),
        ColoringSegment(id: 'belly', name: '배', path: belly),
        ColoringSegment(id: 'head', name: '원숭이 머리', path: head),
        ColoringSegment(id: 'face_mask', name: '얼굴 하트', path: faceMask),
      ];
    },
  );

  // 13. 🐸 개굴 개구리
  static final _frogTemplate = ColoringTemplate(
    id: 'frog',
    title: '개굴 개구리',
    emoji: '🐸',
    createSegments: () {
      final eyeL = Path()..addOval(const Rect.fromLTWH(75, 60, 48, 48));
      final eyeR = Path()..addOval(const Rect.fromLTWH(157, 60, 48, 48));
      final pupilL = Path()..addOval(const Rect.fromLTWH(88, 72, 22, 24));
      final pupilR = Path()..addOval(const Rect.fromLTWH(170, 72, 22, 24));
      final head = Path()..addOval(const Rect.fromLTWH(65, 85, 150, 95));
      final cheekL = Path()..addOval(const Rect.fromLTWH(80, 130, 22, 16));
      final cheekR = Path()..addOval(const Rect.fromLTWH(178, 130, 22, 16));
      final body = Path()..addOval(const Rect.fromLTWH(85, 160, 110, 100));
      final belly = Path()..addOval(const Rect.fromLTWH(102, 175, 76, 75));
      final legL = Path()..addOval(const Rect.fromLTWH(55, 230, 50, 40));
      final legR = Path()..addOval(const Rect.fromLTWH(175, 230, 50, 40));

      return [
        ColoringSegment(id: 'leg_l', name: '왼쪽 뒷다리', path: legL),
        ColoringSegment(id: 'leg_r', name: '오른쪽 뒷다리', path: legR),
        ColoringSegment(id: 'eye_l', name: '왼쪽 왕눈', path: eyeL),
        ColoringSegment(id: 'eye_r', name: '오른쪽 왕눈', path: eyeR),
        ColoringSegment(id: 'pupil_l', name: '왼쪽 눈동자', path: pupilL),
        ColoringSegment(id: 'pupil_r', name: '오른쪽 눈동자', path: pupilR),
        ColoringSegment(id: 'body', name: '몸통', path: body),
        ColoringSegment(id: 'belly', name: '배', path: belly),
        ColoringSegment(id: 'head', name: '얼굴', path: head),
        ColoringSegment(id: 'cheek_l', name: '왼쪽 볼', path: cheekL),
        ColoringSegment(id: 'cheek_r', name: '오른쪽 볼', path: cheekR),
      ];
    },
  );

  // 14. 🦆 꽥꽥 오리
  static final _duckTemplate = ColoringTemplate(
    id: 'duck',
    title: '꽥꽥 오리',
    emoji: '🦆',
    createSegments: () {
      final ripple = Path()
        ..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(40, 235, 200, 22), const Radius.circular(11)));
      final body = Path()
        ..moveTo(95, 160)
        ..quadraticBezierTo(60, 185, 70, 240)
        ..lineTo(215, 240)
        ..quadraticBezierTo(235, 195, 175, 170)
        ..close();
      final wing = Path()..addOval(const Rect.fromLTWH(110, 175, 75, 45));
      final head = Path()..addOval(const Rect.fromLTWH(75, 80, 85, 80));
      final cheek = Path()..addOval(const Rect.fromLTWH(90, 120, 18, 14));
      final beak = Path()
        ..moveTo(80, 115)
        ..quadraticBezierTo(35, 120, 40, 135)
        ..quadraticBezierTo(75, 145, 90, 135)
        ..close();

      return [
        ColoringSegment(id: 'ripple', name: '물결', path: ripple),
        ColoringSegment(id: 'body', name: '오리 몸통', path: body),
        ColoringSegment(id: 'wing', name: '날개', path: wing),
        ColoringSegment(id: 'head', name: '머리', path: head),
        ColoringSegment(id: 'cheek', name: '볼', path: cheek),
        ColoringSegment(id: 'beak', name: '오리 부리', path: beak),
      ];
    },
  );

  // 15. 🐼 아기 판다
  static final _pandaTemplate = ColoringTemplate(
    id: 'panda',
    title: '아기 판다',
    emoji: '🐼',
    createSegments: () {
      final earL = Path()..addOval(const Rect.fromLTWH(65, 55, 45, 45));
      final earR = Path()..addOval(const Rect.fromLTWH(170, 55, 45, 45));
      final head = Path()..addOval(const Rect.fromLTWH(70, 75, 140, 120));
      final patchL = Path()..addOval(const Rect.fromLTWH(90, 105, 34, 42));
      final patchR = Path()..addOval(const Rect.fromLTWH(156, 105, 34, 42));
      final snout = Path()..addOval(const Rect.fromLTWH(115, 140, 50, 36));
      final body = Path()
        ..moveTo(90, 195)
        ..quadraticBezierTo(55, 235, 65, 280)
        ..lineTo(215, 280)
        ..quadraticBezierTo(225, 235, 190, 195)
        ..close();
      final belly = Path()..addOval(const Rect.fromLTWH(100, 215, 80, 60));

      return [
        ColoringSegment(id: 'ear_l', name: '왼쪽 검은 귀', path: earL),
        ColoringSegment(id: 'ear_r', name: '오른쪽 검은 귀', path: earR),
        ColoringSegment(id: 'body', name: '몸통', path: body),
        ColoringSegment(id: 'belly', name: '하얀 배', path: belly),
        ColoringSegment(id: 'head', name: '얼굴', path: head),
        ColoringSegment(id: 'patch_l', name: '왼쪽 눈패치', path: patchL),
        ColoringSegment(id: 'patch_r', name: '오른쪽 눈패치', path: patchR),
        ColoringSegment(id: 'snout', name: '주둥이', path: snout),
      ];
    },
  );

  // 16. 🐨 포근 코알라
  static final _koalaTemplate = ColoringTemplate(
    id: 'koala',
    title: '코알라',
    emoji: '🐨',
    createSegments: () {
      final earL = Path()..addOval(const Rect.fromLTWH(45, 65, 60, 60));
      final earR = Path()..addOval(const Rect.fromLTWH(175, 65, 60, 60));
      final innerL = Path()..addOval(const Rect.fromLTWH(60, 80, 32, 32));
      final innerR = Path()..addOval(const Rect.fromLTWH(188, 80, 32, 32));
      final head = Path()..addOval(const Rect.fromLTWH(75, 80, 130, 115));
      final nose = Path()..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(122, 115, 36, 50), const Radius.circular(16)));
      final cheekL = Path()..addOval(const Rect.fromLTWH(85, 140, 20, 16));
      final cheekR = Path()..addOval(const Rect.fromLTWH(175, 140, 20, 16));
      final body = Path()
        ..moveTo(95, 195)
        ..quadraticBezierTo(70, 235, 75, 275)
        ..lineTo(205, 275)
        ..quadraticBezierTo(210, 235, 185, 195)
        ..close();

      return [
        ColoringSegment(id: 'ear_l', name: '왼쪽 털귀', path: earL),
        ColoringSegment(id: 'ear_r', name: '오른쪽 털귀', path: earR),
        ColoringSegment(id: 'inner_l', name: '왼쪽 귓속', path: innerL),
        ColoringSegment(id: 'inner_r', name: '오른쪽 귓속', path: innerR),
        ColoringSegment(id: 'body', name: '몸통', path: body),
        ColoringSegment(id: 'head', name: '얼굴', path: head),
        ColoringSegment(id: 'nose', name: '큰 코', path: nose),
        ColoringSegment(id: 'cheek_l', name: '왼쪽 볼', path: cheekL),
        ColoringSegment(id: 'cheek_r', name: '오른쪽 볼', path: cheekR),
      ];
    },
  );

  // 17. 🐯 어흥 호랑이
  static final _tigerTemplate = ColoringTemplate(
    id: 'tiger',
    title: '어흥 호랑이',
    emoji: '🐯',
    createSegments: () {
      final earL = Path()..addOval(const Rect.fromLTWH(70, 60, 44, 44));
      final earR = Path()..addOval(const Rect.fromLTWH(166, 60, 44, 44));
      final innerL = Path()..addOval(const Rect.fromLTWH(80, 70, 24, 24));
      final innerR = Path()..addOval(const Rect.fromLTWH(176, 70, 24, 24));
      final head = Path()..addOval(const Rect.fromLTWH(70, 80, 140, 120));
      final stripe1 = Path()..moveTo(133, 85)..lineTo(140, 105)..lineTo(147, 85)..close();
      final stripe2 = Path()..moveTo(85, 115)..lineTo(105, 122)..lineTo(85, 128)..close();
      final stripe3 = Path()..moveTo(195, 115)..lineTo(175, 122)..lineTo(195, 128)..close();
      final snout = Path()..addOval(const Rect.fromLTWH(110, 135, 60, 45));
      final body = Path()
        ..moveTo(90, 195)
        ..quadraticBezierTo(55, 235, 65, 280)
        ..lineTo(215, 280)
        ..quadraticBezierTo(225, 235, 190, 195)
        ..close();

      return [
        ColoringSegment(id: 'ear_l', name: '왼쪽 귀', path: earL),
        ColoringSegment(id: 'ear_r', name: '오른쪽 귀', path: earR),
        ColoringSegment(id: 'inner_l', name: '왼쪽 귓속', path: innerL),
        ColoringSegment(id: 'inner_r', name: '오른쪽 귓속', path: innerR),
        ColoringSegment(id: 'body', name: '호랑이 몸통', path: body),
        ColoringSegment(id: 'head', name: '얼굴', path: head),
        ColoringSegment(id: 'stripe_1', name: '이마 줄무늬', path: stripe1),
        ColoringSegment(id: 'stripe_2', name: '왼쪽 줄무늬', path: stripe2),
        ColoringSegment(id: 'stripe_3', name: '오른쪽 줄무늬', path: stripe3),
        ColoringSegment(id: 'snout', name: '주둥이', path: snout),
      ];
    },
  );

  // 18. 🐑 몽실 양
  static final _sheepTemplate = ColoringTemplate(
    id: 'sheep',
    title: '몽실 양',
    emoji: '🐑',
    createSegments: () {
      final woolBody = Path()..addOval(const Rect.fromLTWH(60, 100, 160, 140));
      final woolTop = Path()..addOval(const Rect.fromLTWH(95, 55, 90, 60));
      final earL = Path()..addOval(const Rect.fromLTWH(65, 105, 34, 20));
      final earR = Path()..addOval(const Rect.fromLTWH(181, 105, 34, 20));
      final head = Path()..addOval(const Rect.fromLTWH(95, 90, 90, 95));
      final cheekL = Path()..addOval(const Rect.fromLTWH(105, 140, 18, 14));
      final cheekR = Path()..addOval(const Rect.fromLTWH(157, 140, 18, 14));
      final legL = Path()..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(95, 230, 24, 45), const Radius.circular(10)));
      final legR = Path()..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(161, 230, 24, 45), const Radius.circular(10)));

      return [
        ColoringSegment(id: 'leg_l', name: '왼쪽 다리', path: legL),
        ColoringSegment(id: 'leg_r', name: '오른쪽 다리', path: legR),
        ColoringSegment(id: 'wool_body', name: '몽실 몸통', path: woolBody),
        ColoringSegment(id: 'wool_top', name: '머리 양털', path: woolTop),
        ColoringSegment(id: 'ear_l', name: '왼쪽 귀', path: earL),
        ColoringSegment(id: 'ear_r', name: '오른쪽 귀', path: earR),
        ColoringSegment(id: 'head', name: '얼굴', path: head),
        ColoringSegment(id: 'cheek_l', name: '왼쪽 볼', path: cheekL),
        ColoringSegment(id: 'cheek_r', name: '오른쪽 볼', path: cheekR),
      ];
    },
  );

  // 19. 🐥 삐약 병아리
  static final _chickTemplate = ColoringTemplate(
    id: 'chick',
    title: '삐약 병아리',
    emoji: '🐥',
    createSegments: () {
      final eggShell = Path()
        ..moveTo(70, 200)
        ..lineTo(95, 175)
        ..lineTo(120, 205)
        ..lineTo(145, 175)
        ..lineTo(170, 205)
        ..lineTo(195, 175)
        ..lineTo(215, 205)
        ..quadraticBezierTo(220, 270, 140, 270)
        ..quadraticBezierTo(65, 270, 70, 200)
        ..close();
      final body = Path()..addOval(const Rect.fromLTWH(80, 75, 120, 130));
      final wingL = Path()
        ..moveTo(82, 135)
        ..quadraticBezierTo(50, 160, 65, 185)
        ..quadraticBezierTo(85, 175, 88, 150)
        ..close();
      final wingR = Path()
        ..moveTo(198, 135)
        ..quadraticBezierTo(230, 160, 215, 185)
        ..quadraticBezierTo(195, 175, 192, 150)
        ..close();
      final beak = Path()..moveTo(130, 120)..lineTo(140, 138)..lineTo(150, 120)..close();
      final cheekL = Path()..addOval(const Rect.fromLTWH(95, 125, 18, 14));
      final cheekR = Path()..addOval(const Rect.fromLTWH(167, 125, 18, 14));
      final crest = Path()..addOval(const Rect.fromLTWH(132, 55, 16, 25));

      return [
        ColoringSegment(id: 'crest', name: '벼슬', path: crest),
        ColoringSegment(id: 'wing_l', name: '왼쪽 날개', path: wingL),
        ColoringSegment(id: 'wing_r', name: '오른쪽 날개', path: wingR),
        ColoringSegment(id: 'body', name: '병아리 몸통', path: body),
        ColoringSegment(id: 'egg_shell', name: '알 껍질', path: eggShell),
        ColoringSegment(id: 'beak', name: '부리', path: beak),
        ColoringSegment(id: 'cheek_l', name: '왼쪽 볼', path: cheekL),
        ColoringSegment(id: 'cheek_r', name: '오른쪽 볼', path: cheekR),
      ];
    },
  );

  // 20. 🐢 엉금 거북이
  static final _turtleTemplate = ColoringTemplate(
    id: 'turtle',
    title: '엉금 거북이',
    emoji: '🐢',
    createSegments: () {
      final legFL = Path()..addOval(const Rect.fromLTWH(65, 85, 35, 45));
      final legFR = Path()..addOval(const Rect.fromLTWH(180, 85, 35, 45));
      final legBL = Path()..addOval(const Rect.fromLTWH(65, 190, 35, 45));
      final legBR = Path()..addOval(const Rect.fromLTWH(180, 190, 35, 45));
      final tail = Path()..moveTo(132, 230)..lineTo(140, 260)..lineTo(148, 230)..close();
      final head = Path()..addOval(const Rect.fromLTWH(115, 45, 50, 55));
      final cheek = Path()..addOval(const Rect.fromLTWH(132, 75, 16, 12));
      final shell = Path()..addOval(const Rect.fromLTWH(75, 90, 130, 145));
      final plateCenter = Path()..addOval(const Rect.fromLTWH(112, 135, 56, 55));
      final plateTop = Path()..addOval(const Rect.fromLTWH(118, 105, 44, 25));

      return [
        ColoringSegment(id: 'tail', name: '꼬리', path: tail),
        ColoringSegment(id: 'leg_fl', name: '앞 왼발', path: legFL),
        ColoringSegment(id: 'leg_fr', name: '앞 오른발', path: legFR),
        ColoringSegment(id: 'leg_bl', name: '뒤 왼발', path: legBL),
        ColoringSegment(id: 'leg_br', name: '뒤 오른발', path: legBR),
        ColoringSegment(id: 'head', name: '거북이 머리', path: head),
        ColoringSegment(id: 'cheek', name: '볼', path: cheek),
        ColoringSegment(id: 'shell', name: '등딱지', path: shell),
        ColoringSegment(id: 'plate_center', name: '가운데 무늬', path: plateCenter),
        ColoringSegment(id: 'plate_top', name: '위쪽 무늬', path: plateTop),
      ];
    },
  );

  // 21. 🐙 바다 문어
  static final _octopusTemplate = ColoringTemplate(
    id: 'octopus',
    title: '바다 문어',
    emoji: '🐙',
    createSegments: () {
      final head = Path()..addOval(const Rect.fromLTWH(75, 55, 130, 125));
      final cheekL = Path()..addOval(const Rect.fromLTWH(88, 130, 20, 16));
      final cheekR = Path()..addOval(const Rect.fromLTWH(172, 130, 20, 16));
      final t1 = Path()
        ..moveTo(85, 170)
        ..quadraticBezierTo(40, 210, 55, 250)
        ..quadraticBezierTo(75, 245, 95, 185)
        ..close();
      final t2 = Path()
        ..moveTo(105, 175)
        ..quadraticBezierTo(85, 230, 105, 260)
        ..quadraticBezierTo(125, 245, 120, 180)
        ..close();
      final t3 = Path()
        ..moveTo(160, 180)
        ..quadraticBezierTo(155, 245, 175, 260)
        ..quadraticBezierTo(195, 230, 175, 175)
        ..close();
      final t4 = Path()
        ..moveTo(185, 185)
        ..quadraticBezierTo(205, 245, 225, 250)
        ..quadraticBezierTo(240, 210, 195, 170)
        ..close();
      final bubble1 = Path()..addOval(const Rect.fromLTWH(60, 45, 18, 18));
      final bubble2 = Path()..addOval(const Rect.fromLTWH(205, 40, 22, 22));

      return [
        ColoringSegment(id: 'bubble_1', name: '작은 방울', path: bubble1),
        ColoringSegment(id: 'bubble_2', name: '큰 방울', path: bubble2),
        ColoringSegment(id: 't_1', name: '왼쪽 다리 1', path: t1),
        ColoringSegment(id: 't_2', name: '왼쪽 다리 2', path: t2),
        ColoringSegment(id: 't_3', name: '오른쪽 다리 1', path: t3),
        ColoringSegment(id: 't_4', name: '오른쪽 다리 2', path: t4),
        ColoringSegment(id: 'head', name: '문어 머리', path: head),
        ColoringSegment(id: 'cheek_l', name: '왼쪽 볼', path: cheekL),
        ColoringSegment(id: 'cheek_r', name: '오른쪽 볼', path: cheekR),
      ];
    },
  );

  // 22. 🦀 찰칵 꽃게
  static final _crabTemplate = ColoringTemplate(
    id: 'crab',
    title: '찰칵 꽃게',
    emoji: '🦀',
    createSegments: () {
      final clawL = Path()
        ..moveTo(70, 75)
        ..quadraticBezierTo(30, 45, 35, 95)
        ..quadraticBezierTo(50, 115, 80, 100)
        ..close();
      final clawR = Path()
        ..moveTo(210, 75)
        ..quadraticBezierTo(250, 45, 245, 95)
        ..quadraticBezierTo(230, 115, 200, 100)
        ..close();
      final armL = Path()..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(70, 95, 25, 45), const Radius.circular(10)));
      final armR = Path()..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(185, 95, 25, 45), const Radius.circular(10)));
      final body = Path()..addOval(const Rect.fromLTWH(65, 125, 150, 100));
      final eyeL = Path()..addOval(const Rect.fromLTWH(105, 95, 24, 28));
      final eyeR = Path()..addOval(const Rect.fromLTWH(151, 95, 24, 28));
      final legL1 = Path()..addOval(const Rect.fromLTWH(45, 170, 30, 18));
      final legL2 = Path()..addOval(const Rect.fromLTWH(40, 195, 30, 18));
      final legR1 = Path()..addOval(const Rect.fromLTWH(205, 170, 30, 18));
      final legR2 = Path()..addOval(const Rect.fromLTWH(210, 195, 30, 18));

      return [
        ColoringSegment(id: 'leg_l1', name: '왼쪽 다리 1', path: legL1),
        ColoringSegment(id: 'leg_l2', name: '왼쪽 다리 2', path: legL2),
        ColoringSegment(id: 'leg_r1', name: '오른쪽 다리 1', path: legR1),
        ColoringSegment(id: 'leg_r2', name: '오른쪽 다리 2', path: legR2),
        ColoringSegment(id: 'claw_l', name: '왼쪽 집게발', path: clawL),
        ColoringSegment(id: 'claw_r', name: '오른쪽 집게발', path: clawR),
        ColoringSegment(id: 'arm_l', name: '왼쪽 팔', path: armL),
        ColoringSegment(id: 'arm_r', name: '오른쪽 팔', path: armR),
        ColoringSegment(id: 'body', name: '꽃게 등딱지', path: body),
        ColoringSegment(id: 'eye_l', name: '왼쪽 눈', path: eyeL),
        ColoringSegment(id: 'eye_r', name: '오른쪽 눈', path: eyeR),
      ];
    },
  );

  // 23. 🐝 붕붕 꿀벌
  static final _beeTemplate = ColoringTemplate(
    id: 'bee',
    title: '붕붕 꿀벌',
    emoji: '🐝',
    createSegments: () {
      final wingL = Path()
        ..moveTo(125, 95)
        ..quadraticBezierTo(70, 30, 60, 75)
        ..quadraticBezierTo(75, 115, 125, 115)
        ..close();
      final wingR = Path()
        ..moveTo(155, 95)
        ..quadraticBezierTo(210, 30, 220, 75)
        ..quadraticBezierTo(205, 115, 155, 115)
        ..close();
      final head = Path()..addOval(const Rect.fromLTWH(100, 70, 80, 65));
      final cheekL = Path()..addOval(const Rect.fromLTWH(108, 105, 16, 12));
      final cheekR = Path()..addOval(const Rect.fromLTWH(156, 105, 16, 12));
      final body = Path()..addOval(const Rect.fromLTWH(90, 125, 100, 120));
      final stripe1 = Path()..addRect(const Rect.fromLTWH(90, 155, 100, 22));
      final stripe2 = Path()..addRect(const Rect.fromLTWH(95, 195, 90, 22));
      final stinger = Path()..moveTo(132, 242)..lineTo(140, 265)..lineTo(148, 242)..close();

      return [
        ColoringSegment(id: 'stinger', name: '침', path: stinger),
        ColoringSegment(id: 'wing_l', name: '왼쪽 투명날개', path: wingL),
        ColoringSegment(id: 'wing_r', name: '오른쪽 투명날개', path: wingR),
        ColoringSegment(id: 'body', name: '노란 꿀벌 몸통', path: body),
        ColoringSegment(id: 'stripe_1', name: '검은 줄무늬 1', path: stripe1),
        ColoringSegment(id: 'stripe_2', name: '검은 줄무늬 2', path: stripe2),
        ColoringSegment(id: 'head', name: '머리', path: head),
        ColoringSegment(id: 'cheek_l', name: '왼쪽 볼', path: cheekL),
        ColoringSegment(id: 'cheek_r', name: '오른쪽 볼', path: cheekR),
      ];
    },
  );

  // 24. 🐞 빨간 무당벌레
  static final _ladybugTemplate = ColoringTemplate(
    id: 'ladybug',
    title: '무당벌레',
    emoji: '🐞',
    createSegments: () {
      final head = Path()..addOval(const Rect.fromLTWH(105, 55, 70, 60));
      final antL = Path()..addOval(const Rect.fromLTWH(95, 38, 12, 18));
      final antR = Path()..addOval(const Rect.fromLTWH(173, 38, 12, 18));
      final wingL = Path()
        ..moveTo(138, 95)
        ..quadraticBezierTo(55, 105, 55, 195)
        ..quadraticBezierTo(70, 255, 138, 255)
        ..close();
      final wingR = Path()
        ..moveTo(142, 95)
        ..quadraticBezierTo(225, 105, 225, 195)
        ..quadraticBezierTo(210, 255, 142, 255)
        ..close();
      final spot1 = Path()..addOval(const Rect.fromLTWH(80, 130, 24, 24));
      final spot2 = Path()..addOval(const Rect.fromLTWH(90, 185, 26, 26));
      final spot3 = Path()..addOval(const Rect.fromLTWH(176, 130, 24, 24));
      final spot4 = Path()..addOval(const Rect.fromLTWH(164, 185, 26, 26));

      return [
        ColoringSegment(id: 'ant_l', name: '왼쪽 더듬이', path: antL),
        ColoringSegment(id: 'ant_r', name: '오른쪽 더듬이', path: antR),
        ColoringSegment(id: 'head', name: '검은 머리', path: head),
        ColoringSegment(id: 'wing_l', name: '왼쪽 빨간 날개', path: wingL),
        ColoringSegment(id: 'wing_r', name: '오른쪽 빨간 날개', path: wingR),
        ColoringSegment(id: 'spot_1', name: '점 무늬 1', path: spot1),
        ColoringSegment(id: 'spot_2', name: '점 무늬 2', path: spot2),
        ColoringSegment(id: 'spot_3', name: '점 무늬 3', path: spot3),
        ColoringSegment(id: 'spot_4', name: '점 무늬 4', path: spot4),
      ];
    },
  );

  // 25. 🦉 밤 부엉이
  static final _owlTemplate = ColoringTemplate(
    id: 'owl',
    title: '밤 부엉이',
    emoji: '🦉',
    createSegments: () {
      final branch = Path()
        ..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(30, 245, 220, 20), const Radius.circular(10)));
      final earTuftL = Path()..moveTo(95, 75)..lineTo(75, 40)..lineTo(115, 65)..close();
      final earTuftR = Path()..moveTo(185, 75)..lineTo(205, 40)..lineTo(165, 65)..close();
      final body = Path()..addOval(const Rect.fromLTWH(75, 65, 130, 175));
      final wingL = Path()
        ..moveTo(80, 115)
        ..quadraticBezierTo(50, 160, 65, 205)
        ..quadraticBezierTo(85, 195, 90, 150)
        ..close();
      final wingR = Path()
        ..moveTo(200, 115)
        ..quadraticBezierTo(230, 160, 215, 205)
        ..quadraticBezierTo(195, 195, 190, 150)
        ..close();
      final eyeRingL = Path()..addOval(const Rect.fromLTWH(85, 90, 48, 48));
      final eyeRingR = Path()..addOval(const Rect.fromLTWH(147, 90, 48, 48));
      final beak = Path()..moveTo(133, 125)..lineTo(140, 142)..lineTo(147, 125)..close();
      final bellyFeathers = Path()..addOval(const Rect.fromLTWH(105, 160, 70, 65));

      return [
        ColoringSegment(id: 'branch', name: '나뭇가지', path: branch),
        ColoringSegment(id: 'ear_l', name: '왼쪽 깃털 귀', path: earTuftL),
        ColoringSegment(id: 'ear_r', name: '오른쪽 깃털 귀', path: earTuftR),
        ColoringSegment(id: 'wing_l', name: '왼쪽 날개', path: wingL),
        ColoringSegment(id: 'wing_r', name: '오른쪽 날개', path: wingR),
        ColoringSegment(id: 'body', name: '부엉이 몸', path: body),
        ColoringSegment(id: 'belly', name: '배 깃털', path: bellyFeathers),
        ColoringSegment(id: 'eye_ring_l', name: '왼쪽 눈테', path: eyeRingL),
        ColoringSegment(id: 'eye_ring_r', name: '오른쪽 눈테', path: eyeRingR),
        ColoringSegment(id: 'beak', name: '부리', path: beak),
      ];
    },
  );

  // 26. 🐿️ 도토리 다람쥐
  static final _squirrelTemplate = ColoringTemplate(
    id: 'squirrel',
    title: '도토리 다람쥐',
    emoji: '🐿️',
    createSegments: () {
      final bigTail = Path()
        ..moveTo(100, 240)
        ..quadraticBezierTo(20, 220, 30, 110)
        ..quadraticBezierTo(50, 40, 100, 50)
        ..quadraticBezierTo(120, 80, 80, 130)
        ..quadraticBezierTo(65, 190, 110, 230)
        ..close();
      final earL = Path()..addOval(const Rect.fromLTWH(135, 65, 24, 30));
      final earR = Path()..addOval(const Rect.fromLTWH(185, 65, 24, 30));
      final head = Path()..addOval(const Rect.fromLTWH(130, 80, 85, 80));
      final snout = Path()..addOval(const Rect.fromLTWH(155, 115, 45, 34));
      final cheek = Path()..addOval(const Rect.fromLTWH(140, 125, 18, 14));
      final body = Path()
        ..moveTo(125, 155)
        ..quadraticBezierTo(105, 200, 115, 260)
        ..lineTo(205, 260)
        ..quadraticBezierTo(215, 200, 180, 155)
        ..close();
      final acorn = Path()..addOval(const Rect.fromLTWH(175, 185, 35, 42));

      return [
        ColoringSegment(id: 'tail', name: '풍성한 꼬리', path: bigTail),
        ColoringSegment(id: 'ear_l', name: '왼쪽 귀', path: earL),
        ColoringSegment(id: 'ear_r', name: '오른쪽 귀', path: earR),
        ColoringSegment(id: 'body', name: '몸통', path: body),
        ColoringSegment(id: 'acorn', name: '도토리', path: acorn),
        ColoringSegment(id: 'head', name: '얼굴', path: head),
        ColoringSegment(id: 'snout', name: '주둥이', path: snout),
        ColoringSegment(id: 'cheek', name: '통통 볼', path: cheek),
      ];
    },
  );

  // 27. 🦔 밤송이 고슴도치
  static final _hedgehogTemplate = ColoringTemplate(
    id: 'hedgehog',
    title: '고슴도치',
    emoji: '🦔',
    createSegments: () {
      final quills = Path()
        ..moveTo(130, 85)
        ..quadraticBezierTo(40, 95, 45, 230)
        ..lineTo(235, 230)
        ..quadraticBezierTo(245, 110, 130, 85)
        ..close();
      final apple = Path()..addOval(const Rect.fromLTWH(110, 50, 48, 48));
      final face = Path()
        ..moveTo(175, 150)
        ..quadraticBezierTo(250, 175, 240, 215)
        ..lineTo(170, 225)
        ..close();
      final nose = Path()..addOval(const Rect.fromLTWH(236, 182, 16, 16));
      final cheek = Path()..addOval(const Rect.fromLTWH(195, 185, 18, 14));
      final legL = Path()..addOval(const Rect.fromLTWH(80, 220, 35, 25));
      final legR = Path()..addOval(const Rect.fromLTWH(170, 220, 35, 25));

      return [
        ColoringSegment(id: 'leg_l', name: '왼쪽 발', path: legL),
        ColoringSegment(id: 'leg_r', name: '오른쪽 발', path: legR),
        ColoringSegment(id: 'quills', name: '뾰족 가시', path: quills),
        ColoringSegment(id: 'apple', name: '등 위 사과', path: apple),
        ColoringSegment(id: 'face', name: '뾰족 얼굴', path: face),
        ColoringSegment(id: 'nose', name: '코', path: nose),
        ColoringSegment(id: 'cheek', name: '볼', path: cheek),
      ];
    },
  );

  // 28. 🦩 분홍 플라밍고
  static final _flamingoTemplate = ColoringTemplate(
    id: 'flamingo',
    title: '플라밍고',
    emoji: '🦩',
    createSegments: () {
      final water = Path()
        ..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(40, 255, 200, 20), const Radius.circular(10)));
      final leg = Path()..addRect(const Rect.fromLTWH(135, 190, 8, 70));
      final body = Path()..addOval(const Rect.fromLTWH(90, 125, 95, 75));
      final wing = Path()..addOval(const Rect.fromLTWH(95, 135, 75, 55));
      final neck = Path()
        ..moveTo(165, 145)
        ..quadraticBezierTo(215, 110, 185, 60)
        ..quadraticBezierTo(165, 45, 160, 75)
        ..quadraticBezierTo(185, 105, 150, 155)
        ..close();
      final head = Path()..addOval(const Rect.fromLTWH(145, 50, 38, 32));
      final beak = Path()..moveTo(148, 62)..lineTo(125, 78)..lineTo(152, 75)..close();

      return [
        ColoringSegment(id: 'water', name: '호숫물', path: water),
        ColoringSegment(id: 'leg', name: '긴 다리', path: leg),
        ColoringSegment(id: 'body', name: '분홍 몸통', path: body),
        ColoringSegment(id: 'wing', name: '깃털 날개', path: wing),
        ColoringSegment(id: 'neck', name: '곡선 목', path: neck),
        ColoringSegment(id: 'head', name: '머리', path: head),
        ColoringSegment(id: 'beak', name: '굽은 부리', path: beak),
      ];
    },
  );

  // 29. 🦭 귀여운 물개
  static final _sealTemplate = ColoringTemplate(
    id: 'seal',
    title: '아기 물개',
    emoji: '🦭',
    createSegments: () {
      final ball = Path()..addOval(const Rect.fromLTWH(155, 30, 48, 48));
      final body = Path()
        ..moveTo(105, 100)
        ..quadraticBezierTo(75, 150, 65, 245)
        ..quadraticBezierTo(135, 260, 205, 235)
        ..quadraticBezierTo(195, 160, 155, 100)
        ..close();
      final belly = Path()..addOval(const Rect.fromLTWH(85, 140, 75, 95));
      final flipperL = Path()..addOval(const Rect.fromLTWH(55, 215, 45, 25));
      final flipperR = Path()..addOval(const Rect.fromLTWH(180, 215, 45, 25));
      final head = Path()..addOval(const Rect.fromLTWH(100, 75, 80, 75));
      final snout = Path()..addOval(const Rect.fromLTWH(115, 105, 50, 36));
      final cheekL = Path()..addOval(const Rect.fromLTWH(105, 112, 16, 12));
      final cheekR = Path()..addOval(const Rect.fromLTWH(158, 112, 16, 12));

      return [
        ColoringSegment(id: 'ball', name: '비치볼', path: ball),
        ColoringSegment(id: 'flipper_l', name: '왼쪽 지느러미', path: flipperL),
        ColoringSegment(id: 'flipper_r', name: '오른쪽 지느러미', path: flipperR),
        ColoringSegment(id: 'body', name: '통통 몸통', path: body),
        ColoringSegment(id: 'belly', name: '하얀 배', path: belly),
        ColoringSegment(id: 'head', name: '얼굴', path: head),
        ColoringSegment(id: 'snout', name: '주둥이', path: snout),
        ColoringSegment(id: 'cheek_l', name: '왼쪽 볼', path: cheekL),
        ColoringSegment(id: 'cheek_r', name: '오른쪽 볼', path: cheekR),
      ];
    },
  );

  // 30. 🐳 바다 고래
  static final _whaleTemplate = ColoringTemplate(
    id: 'whale',
    title: '바다 고래',
    emoji: '🐳',
    createSegments: () {
      final whaleBody = Path()
        ..moveTo(55, 165)
        ..quadraticBezierTo(70, 95, 145, 95)
        ..quadraticBezierTo(225, 95, 235, 155)
        ..quadraticBezierTo(265, 135, 260, 185)
        ..quadraticBezierTo(225, 175, 205, 195)
        ..quadraticBezierTo(145, 215, 55, 165)
        ..close();
      final belly = Path()
        ..moveTo(65, 168)
        ..quadraticBezierTo(135, 212, 195, 192)
        ..quadraticBezierTo(135, 178, 65, 168)
        ..close();
      final fin = Path()
        ..moveTo(125, 170)
        ..quadraticBezierTo(135, 200, 110, 205)
        ..quadraticBezierTo(115, 185, 125, 170)
        ..close();
      final waterSpout = Path()
        ..moveTo(135, 95)
        ..quadraticBezierTo(120, 50, 95, 55)
        ..quadraticBezierTo(125, 75, 133, 95)
        ..close()
        ..moveTo(137, 95)
        ..quadraticBezierTo(145, 40, 175, 45)
        ..quadraticBezierTo(150, 75, 137, 95)
        ..close();
      final wave1 = Path()
        ..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(30, 215, 220, 20), const Radius.circular(10)));
      final wave2 = Path()
        ..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(50, 240, 180, 16), const Radius.circular(8)));

      return [
        ColoringSegment(id: 'wave2', name: '작은 파도', path: wave2),
        ColoringSegment(id: 'wave1', name: '큰 파도', path: wave1),
        ColoringSegment(id: 'spout', name: '뿜는 물줄기', path: waterSpout),
        ColoringSegment(id: 'body', name: '고래 몸통', path: whaleBody),
        ColoringSegment(id: 'belly', name: '고래 배', path: belly),
        ColoringSegment(id: 'fin', name: '지느러미', path: fin),
      ];
    },
  );
}
