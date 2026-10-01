import 'package:flutter/material.dart';
import 'coloring_templates.dart';

/// 14 toddler-friendly vehicle coloring templates.
class ColoringVehicleCatalog {
  static List<ColoringTemplate> get all => [
        _busTemplate,
        _policeCarTemplate,
        _fireTruckTemplate,
        _ambulanceTemplate,
        _trainTemplate,
        _airplaneTemplate,
        _helicopterTemplate,
        _rocketTemplate,
        _sailboatTemplate,
        _submarineTemplate,
        _tractorTemplate,
        _bicycleTemplate,
        _hotAirBalloonTemplate,
        _ufoTemplate,
      ];

  // 1. 🚌 붕붕 버스
  static final _busTemplate = ColoringTemplate(
    id: 'bus',
    title: '붕붕 버스',
    emoji: '🚌',
    category: ColoringCategory.vehicle,
    createSegments: () {
      final roof = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(40, 50, 200, 20),
          const Radius.circular(10),
        ));
      final body = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(40, 65, 200, 130),
          const Radius.circular(16),
        ));
      final stripe = Path()
        ..addRect(const Rect.fromLTWH(40, 140, 200, 22));
      final windshield = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(50, 75, 45, 55),
          const Radius.circular(8),
        ));
      final window1 = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(105, 75, 38, 55),
          const Radius.circular(8),
        ));
      final window2 = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(150, 75, 38, 55),
          const Radius.circular(8),
        ));
      final window3 = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(195, 75, 38, 55),
          const Radius.circular(8),
        ));
      final bumper = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(30, 185, 220, 16),
          const Radius.circular(8),
        ));
      final wheelFront = Path()
        ..addOval(const Rect.fromLTWH(65, 175, 48, 48));
      final hubFront = Path()
        ..addOval(const Rect.fromLTWH(79, 189, 20, 20));
      final wheelBack = Path()
        ..addOval(const Rect.fromLTWH(165, 175, 48, 48));
      final hubBack = Path()
        ..addOval(const Rect.fromLTWH(179, 189, 20, 20));
      final headlight = Path()
        ..addOval(const Rect.fromLTWH(38, 150, 14, 22));

      return [
        ColoringSegment(id: 'body', name: '버스 몸체', path: body),
        ColoringSegment(id: 'roof', name: '버스 지붕', path: roof),
        ColoringSegment(id: 'stripe', name: '옆면 줄무늬', path: stripe),
        ColoringSegment(id: 'windshield', name: '앞 유리창', path: windshield),
        ColoringSegment(id: 'window_1', name: '첫 번째 창문', path: window1),
        ColoringSegment(id: 'window_2', name: '가운데 창문', path: window2),
        ColoringSegment(id: 'window_3', name: '뒤쪽 창문', path: window3),
        ColoringSegment(id: 'bumper', name: '앞뒤 범퍼', path: bumper),
        ColoringSegment(id: 'wheel_f', name: '앞바퀴', path: wheelFront),
        ColoringSegment(id: 'hub_f', name: '앞바퀴 휠', path: hubFront),
        ColoringSegment(id: 'wheel_b', name: '뒷바퀴', path: wheelBack),
        ColoringSegment(id: 'hub_b', name: '뒷바퀴 휠', path: hubBack),
        ColoringSegment(id: 'light', name: '헤드라이트', path: headlight),
      ];
    },
  );

  // 2. 🚓 삐뽀 경찰차
  static final _policeCarTemplate = ColoringTemplate(
    id: 'police_car',
    title: '삐뽀 경찰차',
    emoji: '🚓',
    category: ColoringCategory.vehicle,
    createSegments: () {
      final sirenL = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(115, 62, 22, 16),
          const Radius.circular(6),
        ));
      final sirenR = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(143, 62, 22, 16),
          const Radius.circular(6),
        ));
      final cabin = Path()
        ..moveTo(65, 130)
        ..lineTo(95, 76)
        ..lineTo(185, 76)
        ..lineTo(215, 130)
        ..close();
      final body = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(30, 125, 220, 68),
          const Radius.circular(16),
        ));
      final doorStripe = Path()
        ..addRect(const Rect.fromLTWH(30, 148, 220, 24));
      final starBadge = Path()
        ..addOval(const Rect.fromLTWH(125, 146, 30, 28));
      final frontWindow = Path()
        ..moveTo(75, 126)
        ..lineTo(100, 83)
        ..lineTo(135, 83)
        ..lineTo(135, 126)
        ..close();
      final backWindow = Path()
        ..moveTo(145, 126)
        ..lineTo(145, 83)
        ..lineTo(180, 83)
        ..lineTo(205, 126)
        ..close();
      final wheelF = Path()
        ..addOval(const Rect.fromLTWH(55, 170, 48, 48));
      final wheelB = Path()
        ..addOval(const Rect.fromLTWH(175, 170, 48, 48));
      final headlight = Path()
        ..addOval(const Rect.fromLTWH(28, 135, 14, 20));

      return [
        ColoringSegment(id: 'cabin', name: '지붕 탑승석', path: cabin),
        ColoringSegment(id: 'body', name: '경찰차 몸체', path: body),
        ColoringSegment(id: 'stripe', name: '경찰 줄무늬', path: doorStripe),
        ColoringSegment(id: 'badge', name: '경찰 마크', path: starBadge),
        ColoringSegment(id: 'siren_l', name: '빨간 사이렌', path: sirenL),
        ColoringSegment(id: 'siren_r', name: '파란 사이렌', path: sirenR),
        ColoringSegment(id: 'win_f', name: '앞 창문', path: frontWindow),
        ColoringSegment(id: 'win_b', name: '뒤 창문', path: backWindow),
        ColoringSegment(id: 'wheel_f', name: '앞바퀴', path: wheelF),
        ColoringSegment(id: 'wheel_b', name: '뒷바퀴', path: wheelB),
        ColoringSegment(id: 'headlight', name: '앞 라이트', path: headlight),
      ];
    },
  );

  // 3. 🚒 용감한 소방차
  static final _fireTruckTemplate = ColoringTemplate(
    id: 'fire_truck',
    title: '용감한 소방차',
    emoji: '🚒',
    category: ColoringCategory.vehicle,
    createSegments: () {
      final ladder = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(80, 45, 150, 18),
          const Radius.circular(6),
        ));
      final siren = Path()
        ..addOval(const Rect.fromLTWH(50, 60, 24, 20));
      final cabin = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(30, 80, 75, 110),
          const Radius.circular(14),
        ));
      final tank = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(105, 65, 145, 125),
          const Radius.circular(14),
        ));
      final cabinWindow = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(38, 90, 58, 48),
          const Radius.circular(8),
        ));
      final hoseCircle = Path()
        ..addOval(const Rect.fromLTWH(145, 95, 52, 52));
      final hoseCenter = Path()
        ..addOval(const Rect.fromLTWH(161, 111, 20, 20));
      final wheelF = Path()
        ..addOval(const Rect.fromLTWH(45, 172, 48, 48));
      final wheelB1 = Path()
        ..addOval(const Rect.fromLTWH(125, 172, 48, 48));
      final wheelB2 = Path()
        ..addOval(const Rect.fromLTWH(185, 172, 48, 48));
      final bumper = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(24, 180, 16, 16),
          const Radius.circular(4),
        ));

      return [
        ColoringSegment(id: 'tank', name: '소방 물탱크', path: tank),
        ColoringSegment(id: 'cabin', name: '소방차 운전석', path: cabin),
        ColoringSegment(id: 'window', name: '운전석 유리', path: cabinWindow),
        ColoringSegment(id: 'ladder', name: '구조 사다리', path: ladder),
        ColoringSegment(id: 'siren', name: '출동 경광등', path: siren),
        ColoringSegment(id: 'hose', name: '물호스 릴', path: hoseCircle),
        ColoringSegment(id: 'hose_c', name: '호스 중심축', path: hoseCenter),
        ColoringSegment(id: 'wheel_f', name: '앞바퀴', path: wheelF),
        ColoringSegment(id: 'wheel_b1', name: '중간바퀴', path: wheelB1),
        ColoringSegment(id: 'wheel_b2', name: '뒷바퀴', path: wheelB2),
        ColoringSegment(id: 'bumper', name: '앞 범퍼', path: bumper),
      ];
    },
  );

  // 4. 🚑 달리는 구급차
  static final _ambulanceTemplate = ColoringTemplate(
    id: 'ambulance',
    title: '달리는 구급차',
    emoji: '🚑',
    category: ColoringCategory.vehicle,
    createSegments: () {
      final siren = Path()
        ..addOval(const Rect.fromLTWH(80, 50, 28, 22));
      final cabin = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(30, 92, 70, 95),
          const Radius.circular(14),
        ));
      final body = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(95, 70, 155, 117),
          const Radius.circular(14),
        ));
      final windshield = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(38, 102, 54, 44),
          const Radius.circular(8),
        ));
      final backWindow = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(180, 85, 55, 45),
          const Radius.circular(8),
        ));
      final redCrossH = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(115, 110, 48, 18),
          const Radius.circular(4),
        ));
      final redCrossV = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(130, 95, 18, 48),
          const Radius.circular(4),
        ));
      final stripe = Path()
        ..addRect(const Rect.fromLTWH(30, 150, 220, 16));
      final wheelF = Path()
        ..addOval(const Rect.fromLTWH(48, 172, 48, 48));
      final wheelB = Path()
        ..addOval(const Rect.fromLTWH(175, 172, 48, 48));

      return [
        ColoringSegment(id: 'body', name: '구급차 몸체', path: body),
        ColoringSegment(id: 'cabin', name: '운전석', path: cabin),
        ColoringSegment(id: 'stripe', name: '초록 줄무늬', path: stripe),
        ColoringSegment(id: 'cross_h', name: '구급 마크 가로', path: redCrossH),
        ColoringSegment(id: 'cross_v', name: '구급 마크 세로', path: redCrossV),
        ColoringSegment(id: 'siren', name: '삐뽀 사이렌', path: siren),
        ColoringSegment(id: 'windshield', name: '앞 유리', path: windshield),
        ColoringSegment(id: 'back_win', name: '뒷 유리', path: backWindow),
        ColoringSegment(id: 'wheel_f', name: '앞바퀴', path: wheelF),
        ColoringSegment(id: 'wheel_b', name: '뒷바퀴', path: wheelB),
      ];
    },
  );

  // 5. 🚂 칙칙폭폭 기차
  static final _trainTemplate = ColoringTemplate(
    id: 'train',
    title: '칙칙폭폭 기차',
    emoji: '🚂',
    category: ColoringCategory.vehicle,
    createSegments: () {
      final cloud1 = Path()
        ..addOval(const Rect.fromLTWH(50, 20, 36, 36));
      final cloud2 = Path()
        ..addOval(const Rect.fromLTWH(75, 12, 44, 44));
      final chimney = Path()
        ..moveTo(72, 60)
        ..lineTo(60, 100)
        ..lineTo(98, 100)
        ..lineTo(86, 60)
        ..close();
      final boiler = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(45, 100, 120, 80),
          const Radius.circular(16),
        ));
      final cowcatcher = Path()
        ..moveTo(45, 180)
        ..lineTo(18, 205)
        ..lineTo(45, 205)
        ..close();
      final cabin = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(160, 75, 85, 110),
          const Radius.circular(12),
        ));
      final cabinRoof = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(150, 62, 105, 16),
          const Radius.circular(8),
        ));
      final cabinWindow = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(175, 90, 52, 48),
          const Radius.circular(8),
        ));
      final headlight = Path()
        ..addOval(const Rect.fromLTWH(36, 120, 18, 24));
      final bigWheel = Path()
        ..addOval(const Rect.fromLTWH(165, 168, 68, 68));
      final smallWheel1 = Path()
        ..addOval(const Rect.fromLTWH(50, 182, 48, 48));
      final smallWheel2 = Path()
        ..addOval(const Rect.fromLTWH(108, 182, 48, 48));

      return [
        ColoringSegment(id: 'cloud_1', name: '연기 구름 1', path: cloud1),
        ColoringSegment(id: 'cloud_2', name: '연기 구름 2', path: cloud2),
        ColoringSegment(id: 'chimney', name: '기차 굴뚝', path: chimney),
        ColoringSegment(id: 'boiler', name: '증기 보일러', path: boiler),
        ColoringSegment(id: 'cowcatcher', name: '앞 범퍼', path: cowcatcher),
        ColoringSegment(id: 'cabin', name: '조종실', path: cabin),
        ColoringSegment(id: 'roof', name: '조종실 지붕', path: cabinRoof),
        ColoringSegment(id: 'win', name: '조종실 창문', path: cabinWindow),
        ColoringSegment(id: 'light', name: '헤드라이트', path: headlight),
        ColoringSegment(id: 'wheel_big', name: '큰 바퀴', path: bigWheel),
        ColoringSegment(id: 'wheel_s1', name: '작은 바퀴 1', path: smallWheel1),
        ColoringSegment(id: 'wheel_s2', name: '작은 바퀴 2', path: smallWheel2),
      ];
    },
  );

  // 6. ✈️ 하늘 비행기
  static final _airplaneTemplate = ColoringTemplate(
    id: 'airplane',
    title: '하늘 비행기',
    emoji: '✈️',
    category: ColoringCategory.vehicle,
    createSegments: () {
      final fuselage = Path()
        ..moveTo(40, 140)
        ..quadraticBezierTo(50, 105, 120, 110)
        ..lineTo(230, 115)
        ..lineTo(245, 75)
        ..lineTo(260, 75)
        ..lineTo(252, 145)
        ..quadraticBezierTo(240, 165, 180, 165)
        ..lineTo(70, 165)
        ..quadraticBezierTo(40, 160, 40, 140)
        ..close();
      final cockpit = Path()
        ..addOval(const Rect.fromLTWH(55, 118, 30, 20));
      final wingMain = Path()
        ..moveTo(125, 140)
        ..lineTo(95, 230)
        ..lineTo(145, 230)
        ..lineTo(175, 140)
        ..close();
      final wingFar = Path()
        ..moveTo(140, 110)
        ..lineTo(165, 45)
        ..lineTo(195, 45)
        ..lineTo(180, 110)
        ..close();
      final engine = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(115, 180, 48, 22),
          const Radius.circular(8),
        ));
      final window1 = Path()
        ..addOval(const Rect.fromLTWH(100, 125, 14, 14));
      final window2 = Path()
        ..addOval(const Rect.fromLTWH(125, 125, 14, 14));
      final window3 = Path()
        ..addOval(const Rect.fromLTWH(150, 125, 14, 14));
      final cloud = Path()
        ..addOval(const Rect.fromLTWH(30, 210, 60, 32));

      return [
        ColoringSegment(id: 'wing_far', name: '위쪽 날개', path: wingFar),
        ColoringSegment(id: 'fuselage', name: '비행기 몸체', path: fuselage),
        ColoringSegment(id: 'cockpit', name: '조종석 창문', path: cockpit),
        ColoringSegment(id: 'wing_main', name: '아래쪽 날개', path: wingMain),
        ColoringSegment(id: 'engine', name: '제트 엔진', path: engine),
        ColoringSegment(id: 'win_1', name: '손님 창문 1', path: window1),
        ColoringSegment(id: 'win_2', name: '손님 창문 2', path: window2),
        ColoringSegment(id: 'win_3', name: '손님 창문 3', path: window3),
        ColoringSegment(id: 'cloud', name: '하늘 구름', path: cloud),
      ];
    },
  );

  // 7. 🚁 빙빙 헬리콥터
  static final _helicopterTemplate = ColoringTemplate(
    id: 'helicopter',
    title: '빙빙 헬리콥터',
    emoji: '🚁',
    category: ColoringCategory.vehicle,
    createSegments: () {
      final rotorBlade = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(30, 45, 220, 14),
          const Radius.circular(6),
        ));
      final rotorMast = Path()
        ..addRect(const Rect.fromLTWH(125, 59, 14, 25));
      final body = Path()
        ..addOval(const Rect.fromLTWH(60, 80, 135, 105));
      final cockpitGlass = Path()
        ..moveTo(65, 120)
        ..quadraticBezierTo(75, 88, 120, 88)
        ..lineTo(120, 148)
        ..quadraticBezierTo(80, 150, 65, 120)
        ..close();
      final tailBoom = Path()
        ..moveTo(180, 115)
        ..lineTo(250, 105)
        ..lineTo(250, 128)
        ..lineTo(180, 140)
        ..close();
      final tailFin = Path()
        ..moveTo(245, 85)
        ..lineTo(255, 85)
        ..lineTo(250, 145)
        ..close();
      final tailRotor = Path()
        ..addOval(const Rect.fromLTWH(242, 90, 16, 45));
      final skidLeg1 = Path()
        ..addRect(const Rect.fromLTWH(90, 185, 10, 25));
      final skidLeg2 = Path()
        ..addRect(const Rect.fromLTWH(145, 185, 10, 25));
      final skidBar = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(65, 205, 125, 14),
          const Radius.circular(6),
        ));

      return [
        ColoringSegment(id: 'tail_boom', name: '꼬리 기둥', path: tailBoom),
        ColoringSegment(id: 'tail_fin', name: '꼬리 날개', path: tailFin),
        ColoringSegment(id: 'tail_rotor', name: '꼬리 회전날개', path: tailRotor),
        ColoringSegment(id: 'body', name: '헬리콥터 몸체', path: body),
        ColoringSegment(id: 'glass', name: '투명 조종창', path: cockpitGlass),
        ColoringSegment(id: 'rotor_mast', name: '프로펠러 축', path: rotorMast),
        ColoringSegment(id: 'rotor_blade', name: '큰 회전날개', path: rotorBlade),
        ColoringSegment(id: 'skid_leg1', name: '착륙대 다리 1', path: skidLeg1),
        ColoringSegment(id: 'skid_leg2', name: '착륙대 다리 2', path: skidLeg2),
        ColoringSegment(id: 'skid_bar', name: '착륙 받침대', path: skidBar),
      ];
    },
  );

  // 8. 🚀 우주 로켓
  static final _rocketTemplate = ColoringTemplate(
    id: 'rocket',
    title: '우주 로켓',
    emoji: '🚀',
    category: ColoringCategory.vehicle,
    createSegments: () {
      final nose = Path()
        ..moveTo(140, 25)
        ..quadraticBezierTo(105, 75, 105, 95)
        ..lineTo(175, 95)
        ..quadraticBezierTo(175, 75, 140, 25)
        ..close();
      final body = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(105, 90, 70, 110),
          const Radius.circular(8),
        ));
      final finL = Path()
        ..moveTo(105, 160)
        ..lineTo(55, 215)
        ..lineTo(105, 200)
        ..close();
      final finR = Path()
        ..moveTo(175, 160)
        ..lineTo(225, 215)
        ..lineTo(175, 200)
        ..close();
      final flame = Path()
        ..moveTo(120, 200)
        ..lineTo(105, 255)
        ..lineTo(140, 235)
        ..lineTo(175, 255)
        ..lineTo(160, 200)
        ..close();
      final window = Path()
        ..addOval(const Rect.fromLTWH(122, 115, 36, 36));
      final star1 = Path()
        ..addOval(const Rect.fromLTWH(45, 60, 22, 22));
      final star2 = Path()
        ..addOval(const Rect.fromLTWH(215, 75, 24, 24));

      return [
        ColoringSegment(id: 'star_1', name: '작은 별', path: star1),
        ColoringSegment(id: 'star_2', name: '큰 별', path: star2),
        ColoringSegment(id: 'flame', name: '추진 불꽃', path: flame),
        ColoringSegment(id: 'fin_l', name: '왼쪽 날개', path: finL),
        ColoringSegment(id: 'fin_r', name: '오른쪽 날개', path: finR),
        ColoringSegment(id: 'nose', name: '로켓 머리', path: nose),
        ColoringSegment(id: 'body', name: '로켓 동체', path: body),
        ColoringSegment(id: 'window', name: '조종석 창문', path: window),
      ];
    },
  );

  // 9. ⛵ 하얀 돛단배
  static final _sailboatTemplate = ColoringTemplate(
    id: 'sailboat',
    title: '하얀 돛단배',
    emoji: '⛵',
    category: ColoringCategory.vehicle,
    createSegments: () {
      final mainSail = Path()
        ..moveTo(135, 45)
        ..lineTo(60, 165)
        ..lineTo(135, 165)
        ..close();
      final jibSail = Path()
        ..moveTo(145, 65)
        ..lineTo(215, 165)
        ..lineTo(145, 165)
        ..close();
      final flag = Path()
        ..moveTo(140, 25)
        ..lineTo(170, 35)
        ..lineTo(140, 45)
        ..close();
      final mast = Path()
        ..addRect(const Rect.fromLTWH(136, 25, 8, 150));
      final hull = Path()
        ..moveTo(45, 175)
        ..lineTo(75, 230)
        ..lineTo(215, 230)
        ..lineTo(245, 175)
        ..close();
      final deckStripe = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(40, 170, 210, 14),
          const Radius.circular(6),
        ));
      final wave1 = Path()
        ..moveTo(25, 235)
        ..quadraticBezierTo(70, 255, 115, 235)
        ..quadraticBezierTo(160, 215, 205, 235)
        ..lineTo(205, 260)
        ..lineTo(25, 260)
        ..close();
      final wave2 = Path()
        ..moveTo(85, 245)
        ..quadraticBezierTo(130, 265, 175, 245)
        ..quadraticBezierTo(220, 225, 265, 245)
        ..lineTo(265, 270)
        ..lineTo(85, 270)
        ..close();

      return [
        ColoringSegment(id: 'mast', name: '돛대 기둥', path: mast),
        ColoringSegment(id: 'flag', name: '꼭대기 깃발', path: flag),
        ColoringSegment(id: 'main_sail', name: '큰 돛', path: mainSail),
        ColoringSegment(id: 'jib_sail', name: '작은 돛', path: jibSail),
        ColoringSegment(id: 'hull', name: '배 몸체', path: hull),
        ColoringSegment(id: 'deck', name: '갑판 테두리', path: deckStripe),
        ColoringSegment(id: 'wave_1', name: '푸른 파도 1', path: wave1),
        ColoringSegment(id: 'wave_2', name: '푸른 파도 2', path: wave2),
      ];
    },
  );

  // 10. 🤿 신비한 잠수함
  static final _submarineTemplate = ColoringTemplate(
    id: 'submarine',
    title: '신비한 잠수함',
    emoji: '🤿',
    category: ColoringCategory.vehicle,
    createSegments: () {
      final periscope = Path()
        ..moveTo(125, 45)
        ..lineTo(145, 45)
        ..lineTo(145, 90)
        ..lineTo(135, 90)
        ..lineTo(135, 55)
        ..lineTo(125, 55)
        ..close();
      final tower = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(115, 80, 50, 45),
          const Radius.circular(10),
        ));
      final hull = Path()
        ..addOval(const Rect.fromLTWH(40, 110, 185, 95));
      final port1 = Path()
        ..addOval(const Rect.fromLTWH(75, 135, 34, 34));
      final port2 = Path()
        ..addOval(const Rect.fromLTWH(125, 135, 34, 34));
      final propBlade = Path()
        ..moveTo(225, 130)
        ..lineTo(250, 115)
        ..lineTo(245, 158)
        ..lineTo(250, 200)
        ..lineTo(225, 185)
        ..close();
      final bubble1 = Path()
        ..addOval(const Rect.fromLTWH(210, 80, 20, 20));
      final bubble2 = Path()
        ..addOval(const Rect.fromLTWH(235, 60, 26, 26));

      return [
        ColoringSegment(id: 'periscope', name: '잠망경', path: periscope),
        ColoringSegment(id: 'tower', name: '잠수함 타워', path: tower),
        ColoringSegment(id: 'hull', name: '노란 몸체', path: hull),
        ColoringSegment(id: 'port_1', name: '동그란 창문 1', path: port1),
        ColoringSegment(id: 'port_2', name: '동그란 창문 2', path: port2),
        ColoringSegment(id: 'prop', name: '스크루 프로펠러', path: propBlade),
        ColoringSegment(id: 'bubble_1', name: '물방울 1', path: bubble1),
        ColoringSegment(id: 'bubble_2', name: '물방울 2', path: bubble2),
      ];
    },
  );

  // 11. 🚜 숲속 트랙터
  static final _tractorTemplate = ColoringTemplate(
    id: 'tractor',
    title: '숲속 트랙터',
    emoji: '🚜',
    category: ColoringCategory.vehicle,
    createSegments: () {
      final chimney = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(65, 60, 12, 50),
          const Radius.circular(4),
        ));
      final hood = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(45, 105, 95, 65),
          const Radius.circular(12),
        ));
      final cabin = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(135, 75, 80, 95),
          const Radius.circular(12),
        ));
      final cabinRoof = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(125, 65, 100, 15),
          const Radius.circular(8),
        ));
      final cabinWin = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(145, 88, 60, 48),
          const Radius.circular(8),
        ));
      final headlight = Path()
        ..addOval(const Rect.fromLTWH(36, 115, 14, 22));
      final smallWheel = Path()
        ..addOval(const Rect.fromLTWH(50, 160, 52, 52));
      final smallRim = Path()
        ..addOval(const Rect.fromLTWH(64, 174, 24, 24));
      final bigWheel = Path()
        ..addOval(const Rect.fromLTWH(145, 140, 84, 84));
      final bigRim = Path()
        ..addOval(const Rect.fromLTWH(167, 162, 40, 40));

      return [
        ColoringSegment(id: 'chimney', name: '배기 굴뚝', path: chimney),
        ColoringSegment(id: 'hood', name: '엔진 보닛', path: hood),
        ColoringSegment(id: 'cabin', name: '운전석', path: cabin),
        ColoringSegment(id: 'roof', name: '지붕', path: cabinRoof),
        ColoringSegment(id: 'win', name: '유리창', path: cabinWin),
        ColoringSegment(id: 'light', name: '라이트', path: headlight),
        ColoringSegment(id: 'wheel_s', name: '앞쪽 작은 바퀴', path: smallWheel),
        ColoringSegment(id: 'rim_s', name: '앞바퀴 휠', path: smallRim),
        ColoringSegment(id: 'wheel_b', name: '뒤쪽 큰 바퀴', path: bigWheel),
        ColoringSegment(id: 'rim_b', name: '뒷바퀴 휠', path: bigRim),
      ];
    },
  );

  // 12. 🚲 씽씽 자전거
  static final _bicycleTemplate = ColoringTemplate(
    id: 'bicycle',
    title: '씽씽 자전거',
    emoji: '🚲',
    category: ColoringCategory.vehicle,
    createSegments: () {
      final wheelF = Path()
        ..addOval(const Rect.fromLTWH(35, 135, 78, 78));
      final wheelB = Path()
        ..addOval(const Rect.fromLTWH(165, 135, 78, 78));
      final hubF = Path()
        ..addOval(const Rect.fromLTWH(62, 162, 24, 24));
      final hubB = Path()
        ..addOval(const Rect.fromLTWH(192, 162, 24, 24));
      final frame = Path()
        ..moveTo(74, 174)
        ..lineTo(120, 105)
        ..lineTo(140, 174)
        ..lineTo(74, 174)
        ..moveTo(120, 105)
        ..lineTo(175, 105)
        ..lineTo(204, 174)
        ..lineTo(140, 174)
        ..close();
      final seat = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(160, 92, 40, 14),
          const Radius.circular(6),
        ));
      final handlebar = Path()
        ..moveTo(110, 85)
        ..lineTo(125, 85)
        ..lineTo(120, 105)
        ..close();
      final basket = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(85, 95, 30, 25),
          const Radius.circular(6),
        ));

      return [
        ColoringSegment(id: 'wheel_f', name: '앞바퀴', path: wheelF),
        ColoringSegment(id: 'hub_f', name: '앞바퀴 중심', path: hubF),
        ColoringSegment(id: 'wheel_b', name: '뒷바퀴', path: wheelB),
        ColoringSegment(id: 'hub_b', name: '뒷바퀴 중심', path: hubB),
        ColoringSegment(id: 'frame', name: '자전거 프레임', path: frame),
        ColoringSegment(id: 'seat', name: '푹신 안장', path: seat),
        ColoringSegment(id: 'handle', name: '손잡이 핸들', path: handlebar),
        ColoringSegment(id: 'basket', name: '앞 바구니', path: basket),
      ];
    },
  );

  // 13. 🎈 두둥실 열기구
  static final _hotAirBalloonTemplate = ColoringTemplate(
    id: 'hot_air_balloon',
    title: '두둥실 열기구',
    emoji: '🎈',
    category: ColoringCategory.vehicle,
    createSegments: () {
      final balloonLeft = Path()
        ..moveTo(140, 30)
        ..quadraticBezierTo(50, 45, 65, 120)
        ..quadraticBezierTo(75, 165, 125, 185)
        ..lineTo(140, 185)
        ..close();
      final balloonRight = Path()
        ..moveTo(140, 30)
        ..quadraticBezierTo(230, 45, 215, 120)
        ..quadraticBezierTo(205, 165, 155, 185)
        ..lineTo(140, 185)
        ..close();
      final balloonCenter = Path()
        ..moveTo(140, 30)
        ..quadraticBezierTo(105, 100, 125, 185)
        ..lineTo(155, 185)
        ..quadraticBezierTo(175, 100, 140, 30)
        ..close();
      final basket = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(115, 210, 50, 40),
          const Radius.circular(8),
        ));
      final ropeL = Path()
        ..moveTo(125, 185)
        ..lineTo(122, 210)
        ..lineTo(128, 210)
        ..lineTo(131, 185)
        ..close();
      final ropeR = Path()
        ..moveTo(155, 185)
        ..lineTo(158, 210)
        ..lineTo(152, 210)
        ..lineTo(149, 185)
        ..close();
      final cloud1 = Path()
        ..addOval(const Rect.fromLTWH(30, 180, 50, 30));
      final cloud2 = Path()
        ..addOval(const Rect.fromLTWH(200, 190, 55, 32));

      return [
        ColoringSegment(id: 'b_left', name: '왼쪽 풍선', path: balloonLeft),
        ColoringSegment(id: 'b_right', name: '오른쪽 풍선', path: balloonRight),
        ColoringSegment(id: 'b_center', name: '가운데 풍선', path: balloonCenter),
        ColoringSegment(id: 'rope_l', name: '왼쪽 줄', path: ropeL),
        ColoringSegment(id: 'rope_r', name: '오른쪽 줄', path: ropeR),
        ColoringSegment(id: 'basket', name: '탑승 바구니', path: basket),
        ColoringSegment(id: 'cloud_1', name: '하늘 구름 1', path: cloud1),
        ColoringSegment(id: 'cloud_2', name: '하늘 구름 2', path: cloud2),
      ];
    },
  );

  // 14. 🛸 윙윙 UFO
  static final _ufoTemplate = ColoringTemplate(
    id: 'ufo',
    title: '윙윙 UFO',
    emoji: '🛸',
    category: ColoringCategory.vehicle,
    createSegments: () {
      final dome = Path()
        ..moveTo(95, 110)
        ..quadraticBezierTo(95, 50, 140, 50)
        ..quadraticBezierTo(185, 50, 185, 110)
        ..close();
      final alienHead = Path()
        ..addOval(const Rect.fromLTWH(125, 68, 30, 32));
      final saucerTop = Path()
        ..addOval(const Rect.fromLTWH(45, 95, 190, 60));
      final saucerRim = Path()
        ..addOval(const Rect.fromLTWH(35, 115, 210, 48));
      final light1 = Path()
        ..addOval(const Rect.fromLTWH(70, 130, 22, 18));
      final light2 = Path()
        ..addOval(const Rect.fromLTWH(129, 134, 22, 18));
      final light3 = Path()
        ..addOval(const Rect.fromLTWH(188, 130, 22, 18));
      final beam = Path()
        ..moveTo(90, 155)
        ..lineTo(40, 255)
        ..lineTo(240, 255)
        ..lineTo(190, 155)
        ..close();

      return [
        ColoringSegment(id: 'beam', name: '반짝 광선', path: beam),
        ColoringSegment(id: 'dome', name: '우주 조종석', path: dome),
        ColoringSegment(id: 'alien', name: '외계인 친구', path: alienHead),
        ColoringSegment(id: 'saucer_top', name: '접시 윗면', path: saucerTop),
        ColoringSegment(id: 'saucer_rim', name: '비행접시 테두리', path: saucerRim),
        ColoringSegment(id: 'light_1', name: '신호등 1', path: light1),
        ColoringSegment(id: 'light_2', name: '신호등 2', path: light2),
        ColoringSegment(id: 'light_3', name: '신호등 3', path: light3),
      ];
    },
  );
}
