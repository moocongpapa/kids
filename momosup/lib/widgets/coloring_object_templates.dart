import 'package:flutter/material.dart';
import 'coloring_templates.dart';

/// 20 toddler-friendly object, food, nature, and toy coloring templates.
class ColoringObjectCatalog {
  static List<ColoringTemplate> get all => [
        _flowerTemplate,
        _fruitTemplate,
        _cakeTemplate,
        _iceCreamTemplate,
        _pizzaTemplate,
        _burgerTemplate,
        _donutTemplate,
        _lollipopTemplate,
        _giftTemplate,
        _crownTemplate,
        _guitarTemplate,
        _soccerTemplate,
        _teddyToyTemplate,
        _castleTemplate,
        _rainbowTemplate,
        _sunTemplate,
        _moonTemplate,
        _treeTemplate,
        _mushroomTemplate,
        _juiceTemplate,
      ];

  // 1. 🌸 무지개 꽃
  static final _flowerTemplate = ColoringTemplate(
    id: 'flower',
    title: '무지개 꽃',
    emoji: '🌸',
    category: ColoringCategory.object,
    createSegments: () {
      final pot = Path()
        ..moveTo(90, 185)
        ..lineTo(105, 260)
        ..lineTo(175, 260)
        ..lineTo(190, 185)
        ..close();
      final stem = Path()
        ..addRect(const Rect.fromLTWH(135, 125, 10, 65));
      final leafL = Path()
        ..addOval(const Rect.fromLTWH(80, 145, 55, 25));
      final leafR = Path()
        ..addOval(const Rect.fromLTWH(145, 135, 55, 25));
      final petal1 = Path()
        ..addOval(const Rect.fromLTWH(115, 20, 50, 50));
      final petal2 = Path()
        ..addOval(const Rect.fromLTWH(155, 45, 50, 50));
      final petal3 = Path()
        ..addOval(const Rect.fromLTWH(155, 95, 50, 50));
      final petal4 = Path()
        ..addOval(const Rect.fromLTWH(115, 120, 50, 50));
      final petal5 = Path()
        ..addOval(const Rect.fromLTWH(75, 95, 50, 50));
      final petal6 = Path()
        ..addOval(const Rect.fromLTWH(75, 45, 50, 50));
      final center = Path()
        ..addOval(const Rect.fromLTWH(115, 65, 50, 50));

      return [
        ColoringSegment(id: 'pot', name: '화분', path: pot),
        ColoringSegment(id: 'stem', name: '줄기', path: stem),
        ColoringSegment(id: 'leaf_l', name: '왼쪽 잎', path: leafL),
        ColoringSegment(id: 'leaf_r', name: '오른쪽 잎', path: leafR),
        ColoringSegment(id: 'petal_1', name: '꽃잎 1', path: petal1),
        ColoringSegment(id: 'petal_2', name: '꽃잎 2', path: petal2),
        ColoringSegment(id: 'petal_3', name: '꽃잎 3', path: petal3),
        ColoringSegment(id: 'petal_4', name: '꽃잎 4', path: petal4),
        ColoringSegment(id: 'petal_5', name: '꽃잎 5', path: petal5),
        ColoringSegment(id: 'petal_6', name: '꽃잎 6', path: petal6),
        ColoringSegment(id: 'center', name: '꽃 중심', path: center),
      ];
    },
  );

  // 2. 🍎 달콤 과일
  static final _fruitTemplate = ColoringTemplate(
    id: 'fruit',
    title: '달콤 과일',
    emoji: '🍎',
    category: ColoringCategory.object,
    createSegments: () {
      final basket = Path()
        ..moveTo(60, 165)
        ..lineTo(80, 260)
        ..lineTo(200, 260)
        ..lineTo(220, 165)
        ..close();
      final rim = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(50, 155, 180, 18),
          const Radius.circular(8),
        ));
      final apple = Path()
        ..addOval(const Rect.fromLTWH(75, 95, 65, 65));
      final appleLeaf = Path()
        ..addOval(const Rect.fromLTWH(100, 80, 22, 16));
      final orange = Path()
        ..addOval(const Rect.fromLTWH(140, 100, 65, 65));
      final grape1 = Path()
        ..addOval(const Rect.fromLTWH(125, 80, 26, 26));
      final grape2 = Path()
        ..addOval(const Rect.fromLTWH(115, 60, 24, 24));
      final grape3 = Path()
        ..addOval(const Rect.fromLTWH(135, 60, 24, 24));

      return [
        ColoringSegment(id: 'basket', name: '과일 바구니', path: basket),
        ColoringSegment(id: 'rim', name: '바구니 테두리', path: rim),
        ColoringSegment(id: 'apple', name: '빨간 사과', path: apple),
        ColoringSegment(id: 'leaf', name: '사과 잎', path: appleLeaf),
        ColoringSegment(id: 'orange', name: '주황 오렌지', path: orange),
        ColoringSegment(id: 'grape_1', name: '포도알 1', path: grape1),
        ColoringSegment(id: 'grape_2', name: '포도알 2', path: grape2),
        ColoringSegment(id: 'grape_3', name: '포도알 3', path: grape3),
      ];
    },
  );

  // 3. 🎂 생일 케이크
  static final _cakeTemplate = ColoringTemplate(
    id: 'cake',
    title: '생일 케이크',
    emoji: '🎂',
    category: ColoringCategory.object,
    createSegments: () {
      final bottomPlate = Path()
        ..addOval(const Rect.fromLTWH(30, 230, 220, 40));
      final bottomTier = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(50, 170, 180, 75),
          const Radius.circular(12),
        ));
      final bottomCream = Path()
        ..addOval(const Rect.fromLTWH(50, 160, 180, 24));
      final topTier = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(80, 105, 120, 65),
          const Radius.circular(12),
        ));
      final topCream = Path()
        ..addOval(const Rect.fromLTWH(80, 95, 120, 22));
      final candle = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(133, 45, 14, 52),
          const Radius.circular(4),
        ));
      final flame = Path()
        ..addOval(const Rect.fromLTWH(132, 20, 16, 26));
      final cherry1 = Path()
        ..addOval(const Rect.fromLTWH(90, 85, 20, 20));
      final cherry2 = Path()
        ..addOval(const Rect.fromLTWH(170, 85, 20, 20));

      return [
        ColoringSegment(id: 'plate', name: '케이크 받침 접시', path: bottomPlate),
        ColoringSegment(id: 'tier_1', name: '아래쪽 빵', path: bottomTier),
        ColoringSegment(id: 'cream_1', name: '아래쪽 생크림', path: bottomCream),
        ColoringSegment(id: 'tier_2', name: '위쪽 빵', path: topTier),
        ColoringSegment(id: 'cream_2', name: '위쪽 생크림', path: topCream),
        ColoringSegment(id: 'candle', name: '생일 촛대', path: candle),
        ColoringSegment(id: 'flame', name: '따뜻한 촛불', path: flame),
        ColoringSegment(id: 'cherry_1', name: '왼쪽 딸기', path: cherry1),
        ColoringSegment(id: 'cherry_2', name: '오른쪽 딸기', path: cherry2),
      ];
    },
  );

  // 4. 🍦 달콤 아이스크림
  static final _iceCreamTemplate = ColoringTemplate(
    id: 'ice_cream',
    title: '달콤 아이스크림',
    emoji: '🍦',
    category: ColoringCategory.object,
    createSegments: () {
      final cone = Path()
        ..moveTo(85, 155)
        ..lineTo(140, 275)
        ..lineTo(195, 155)
        ..close();
      final coneRibbon = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(80, 148, 120, 16),
          const Radius.circular(8),
        ));
      final scoopBottom = Path()
        ..addOval(const Rect.fromLTWH(70, 100, 140, 60));
      final scoopTop = Path()
        ..addOval(const Rect.fromLTWH(85, 50, 110, 65));
      final cherry = Path()
        ..addOval(const Rect.fromLTWH(126, 25, 28, 28));
      final sprinkle1 = Path()
        ..addOval(const Rect.fromLTWH(105, 75, 12, 18));
      final sprinkle2 = Path()
        ..addOval(const Rect.fromLTWH(155, 70, 12, 18));
      final sprinkle3 = Path()
        ..addOval(const Rect.fromLTWH(135, 120, 16, 12));

      return [
        ColoringSegment(id: 'cone', name: '바삭 콘 과자', path: cone),
        ColoringSegment(id: 'ribbon', name: '콘 테두리', path: coneRibbon),
        ColoringSegment(id: 'scoop_1', name: '초코 아이스크림', path: scoopBottom),
        ColoringSegment(id: 'scoop_2', name: '딸기 아이스크림', path: scoopTop),
        ColoringSegment(id: 'cherry', name: '꼭대기 체리', path: cherry),
        ColoringSegment(id: 'sp_1', name: '알록 토핑 1', path: sprinkle1),
        ColoringSegment(id: 'sp_2', name: '알록 토핑 2', path: sprinkle2),
        ColoringSegment(id: 'sp_3', name: '알록 토핑 3', path: sprinkle3),
      ];
    },
  );

  // 5. 🍕 맛있는 피자
  static final _pizzaTemplate = ColoringTemplate(
    id: 'pizza',
    title: '맛있는 피자',
    emoji: '🍕',
    category: ColoringCategory.object,
    createSegments: () {
      final crust = Path()
        ..moveTo(40, 60)
        ..quadraticBezierTo(140, 30, 240, 60)
        ..lineTo(225, 80)
        ..quadraticBezierTo(140, 50, 55, 80)
        ..close();
      final cheese = Path()
        ..moveTo(55, 78)
        ..quadraticBezierTo(140, 50, 225, 78)
        ..lineTo(140, 265)
        ..close();
      final pep1 = Path()
        ..addOval(const Rect.fromLTWH(100, 100, 34, 34));
      final pep2 = Path()
        ..addOval(const Rect.fromLTWH(150, 115, 34, 34));
      final pep3 = Path()
        ..addOval(const Rect.fromLTWH(125, 165, 32, 32));
      final mushroom1 = Path()
        ..addOval(const Rect.fromLTWH(75, 130, 24, 20));
      final mushroom2 = Path()
        ..addOval(const Rect.fromLTWH(175, 155, 24, 20));
      final olive = Path()
        ..addOval(const Rect.fromLTWH(115, 205, 18, 18));

      return [
        ColoringSegment(id: 'crust', name: '도우 크러스트', path: crust),
        ColoringSegment(id: 'cheese', name: '쭉쭉 치즈', path: cheese),
        ColoringSegment(id: 'pep_1', name: '페퍼로니 1', path: pep1),
        ColoringSegment(id: 'pep_2', name: '페퍼로니 2', path: pep2),
        ColoringSegment(id: 'pep_3', name: '페퍼로니 3', path: pep3),
        ColoringSegment(id: 'mush_1', name: '버섯 토핑 1', path: mushroom1),
        ColoringSegment(id: 'mush_2', name: '버섯 토핑 2', path: mushroom2),
        ColoringSegment(id: 'olive', name: '올리브', path: olive),
      ];
    },
  );

  // 6. 🍔 냠냠 햄버거
  static final _burgerTemplate = ColoringTemplate(
    id: 'burger',
    title: '냠냠 햄버거',
    emoji: '🍔',
    category: ColoringCategory.object,
    createSegments: () {
      final bunTop = Path()
        ..moveTo(45, 110)
        ..quadraticBezierTo(140, 25, 235, 110)
        ..close();
      final sesame1 = Path()
        ..addOval(const Rect.fromLTWH(95, 65, 12, 8));
      final sesame2 = Path()
        ..addOval(const Rect.fromLTWH(140, 55, 12, 8));
      final sesame3 = Path()
        ..addOval(const Rect.fromLTWH(175, 75, 12, 8));
      final lettuce = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(35, 110, 210, 20),
          const Radius.circular(10),
        ));
      final tomato = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(45, 130, 190, 18),
          const Radius.circular(6),
        ));
      final cheese = Path()
        ..moveTo(45, 148)
        ..lineTo(235, 148)
        ..lineTo(215, 172)
        ..lineTo(170, 155)
        ..lineTo(140, 175)
        ..lineTo(105, 155)
        ..lineTo(65, 172)
        ..close();
      final patty = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(40, 165, 200, 32),
          const Radius.circular(12),
        ));
      final bunBottom = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(48, 197, 184, 40),
          const Radius.circular(14),
        ));

      return [
        ColoringSegment(id: 'bun_top', name: '위쪽 빵', path: bunTop),
        ColoringSegment(id: 'sesame_1', name: '참깨 1', path: sesame1),
        ColoringSegment(id: 'sesame_2', name: '참깨 2', path: sesame2),
        ColoringSegment(id: 'sesame_3', name: '참깨 3', path: sesame3),
        ColoringSegment(id: 'lettuce', name: '아삭 양상추', path: lettuce),
        ColoringSegment(id: 'tomato', name: '빨간 토마토', path: tomato),
        ColoringSegment(id: 'cheese', name: '고소한 치즈', path: cheese),
        ColoringSegment(id: 'patty', name: '두툼한 패티', path: patty),
        ColoringSegment(id: 'bun_bottom', name: '아래쪽 빵', path: bunBottom),
      ];
    },
  );

  // 7. 🍩 달콤 도넛
  static final _donutTemplate = ColoringTemplate(
    id: 'donut',
    title: '달콤 도넛',
    emoji: '🍩',
    category: ColoringCategory.object,
    createSegments: () {
      final base = Path()
        ..addOval(const Rect.fromLTWH(40, 45, 200, 200));
      final icing = Path()
        ..addOval(const Rect.fromLTWH(50, 55, 180, 180));
      final centerHole = Path()
        ..addOval(const Rect.fromLTWH(110, 115, 60, 60));
      final spr1 = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(75, 95, 24, 10),
          const Radius.circular(5),
        ));
      final spr2 = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(165, 85, 10, 24),
          const Radius.circular(5),
        ));
      final spr3 = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(175, 160, 24, 10),
          const Radius.circular(5),
        ));
      final spr4 = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(95, 185, 24, 10),
          const Radius.circular(5),
        ));

      return [
        ColoringSegment(id: 'base', name: '고소한 도넛 빵', path: base),
        ColoringSegment(id: 'icing', name: '달콤 딸기 아이싱', path: icing),
        ColoringSegment(id: 'hole', name: '가운데 구멍', path: centerHole),
        ColoringSegment(id: 'sp_1', name: '토핑 스프링클 1', path: spr1),
        ColoringSegment(id: 'sp_2', name: '토핑 스프링클 2', path: spr2),
        ColoringSegment(id: 'sp_3', name: '토핑 스프링클 3', path: spr3),
        ColoringSegment(id: 'sp_4', name: '토핑 스프링클 4', path: spr4),
      ];
    },
  );

  // 8. 🍭 뱅글 사탕
  static final _lollipopTemplate = ColoringTemplate(
    id: 'lollipop',
    title: '뱅글 사탕',
    emoji: '🍭',
    category: ColoringCategory.object,
    createSegments: () {
      final stick = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(134, 160, 12, 110),
          const Radius.circular(6),
        ));
      final outerRing = Path()
        ..addOval(const Rect.fromLTWH(60, 30, 160, 160));
      final midRing = Path()
        ..addOval(const Rect.fromLTWH(80, 50, 120, 120));
      final innerRing = Path()
        ..addOval(const Rect.fromLTWH(105, 75, 70, 70));
      final centerDot = Path()
        ..addOval(const Rect.fromLTWH(125, 95, 30, 30));
      final bowL = Path()
        ..moveTo(140, 170)
        ..lineTo(110, 155)
        ..lineTo(110, 185)
        ..close();
      final bowR = Path()
        ..moveTo(140, 170)
        ..lineTo(170, 155)
        ..lineTo(170, 185)
        ..close();

      return [
        ColoringSegment(id: 'stick', name: '사탕 막대', path: stick),
        ColoringSegment(id: 'ring_out', name: '바깥쪽 사탕', path: outerRing),
        ColoringSegment(id: 'ring_mid', name: '중간 소용돌이', path: midRing),
        ColoringSegment(id: 'ring_in', name: '안쪽 소용돌이', path: innerRing),
        ColoringSegment(id: 'center', name: '가운데 꼭지', path: centerDot),
        ColoringSegment(id: 'bow_l', name: '왼쪽 리본', path: bowL),
        ColoringSegment(id: 'bow_r', name: '오른쪽 리본', path: bowR),
      ];
    },
  );

  // 9. 🎁 선물 상자
  static final _giftTemplate = ColoringTemplate(
    id: 'gift',
    title: '선물 상자',
    emoji: '🎁',
    category: ColoringCategory.object,
    createSegments: () {
      final box = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(55, 115, 170, 135),
          const Radius.circular(10),
        ));
      final lid = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(45, 95, 190, 30),
          const Radius.circular(8),
        ));
      final ribbonV = Path()
        ..addRect(const Rect.fromLTWH(126, 95, 28, 155));
      final ribbonH = Path()
        ..addRect(const Rect.fromLTWH(55, 165, 170, 26));
      final bowL = Path()
        ..moveTo(140, 95)
        ..quadraticBezierTo(70, 35, 110, 65)
        ..close();
      final bowR = Path()
        ..moveTo(140, 95)
        ..quadraticBezierTo(210, 35, 170, 65)
        ..close();
      final bowCenter = Path()
        ..addOval(const Rect.fromLTWH(128, 80, 24, 24));

      return [
        ColoringSegment(id: 'box', name: '선물 상자', path: box),
        ColoringSegment(id: 'lid', name: '상자 뚜껑', path: lid),
        ColoringSegment(id: 'ribbon_v', name: '세로 리본', path: ribbonV),
        ColoringSegment(id: 'ribbon_h', name: '가로 리본', path: ribbonH),
        ColoringSegment(id: 'bow_l', name: '왼쪽 리본 매듭', path: bowL),
        ColoringSegment(id: 'bow_r', name: '오른쪽 리본 매듭', path: bowR),
        ColoringSegment(id: 'bow_c', name: '리본 방울', path: bowCenter),
      ];
    },
  );

  // 10. 👑 반짝 왕관
  static final _crownTemplate = ColoringTemplate(
    id: 'crown',
    title: '반짝 왕관',
    emoji: '👑',
    category: ColoringCategory.object,
    createSegments: () {
      final baseBand = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(40, 200, 200, 35),
          const Radius.circular(10),
        ));
      final peaks = Path()
        ..moveTo(45, 200)
        ..lineTo(40, 95)
        ..lineTo(90, 150)
        ..lineTo(140, 70)
        ..lineTo(190, 150)
        ..lineTo(240, 95)
        ..lineTo(235, 200)
        ..close();
      final gemCenter = Path()
        ..addOval(const Rect.fromLTWH(126, 120, 28, 35));
      final gemL = Path()
        ..addOval(const Rect.fromLTWH(75, 150, 22, 28));
      final gemR = Path()
        ..addOval(const Rect.fromLTWH(183, 150, 22, 28));
      final star1 = Path()
        ..addOval(const Rect.fromLTWH(30, 75, 22, 22));
      final star2 = Path()
        ..addOval(const Rect.fromLTWH(130, 48, 22, 22));
      final star3 = Path()
        ..addOval(const Rect.fromLTWH(230, 75, 22, 22));

      return [
        ColoringSegment(id: 'peaks', name: '황금 왕관 날개', path: peaks),
        ColoringSegment(id: 'band', name: '왕관 띠', path: baseBand),
        ColoringSegment(id: 'gem_c', name: '가운데 보석', path: gemCenter),
        ColoringSegment(id: 'gem_l', name: '왼쪽 보석', path: gemL),
        ColoringSegment(id: 'gem_r', name: '오른쪽 보석', path: gemR),
        ColoringSegment(id: 'star_1', name: '반짝 별 1', path: star1),
        ColoringSegment(id: 'star_2', name: '반짝 별 2', path: star2),
        ColoringSegment(id: 'star_3', name: '반짝 별 3', path: star3),
      ];
    },
  );

  // 11. 🎸 신나는 기타
  static final _guitarTemplate = ColoringTemplate(
    id: 'guitar',
    title: '신나는 기타',
    emoji: '🎸',
    category: ColoringCategory.object,
    createSegments: () {
      final body = Path()
        ..moveTo(95, 125)
        ..quadraticBezierTo(70, 150, 80, 195)
        ..quadraticBezierTo(75, 255, 140, 260)
        ..quadraticBezierTo(205, 255, 200, 195)
        ..quadraticBezierTo(210, 150, 185, 125)
        ..quadraticBezierTo(140, 135, 95, 125)
        ..close();
      final soundHole = Path()
        ..addOval(const Rect.fromLTWH(120, 175, 40, 40));
      final pickguard = Path()
        ..addOval(const Rect.fromLTWH(145, 185, 30, 45));
      final neck = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(128, 55, 24, 75),
          const Radius.circular(4),
        ));
      final headstock = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(122, 25, 36, 35),
          const Radius.circular(8),
        ));
      final pegL = Path()
        ..addOval(const Rect.fromLTWH(110, 32, 14, 18));
      final pegR = Path()
        ..addOval(const Rect.fromLTWH(156, 32, 14, 18));
      final note = Path()
        ..addOval(const Rect.fromLTWH(50, 60, 26, 26));

      return [
        ColoringSegment(id: 'body', name: '기타 울림통', path: body),
        ColoringSegment(id: 'guard', name: '픽가드', path: pickguard),
        ColoringSegment(id: 'hole', name: '사운드 홀', path: soundHole),
        ColoringSegment(id: 'neck', name: '기타 넥', path: neck),
        ColoringSegment(id: 'head', name: '헤드스톡', path: headstock),
        ColoringSegment(id: 'peg_l', name: '왼쪽 조율 손잡이', path: pegL),
        ColoringSegment(id: 'peg_r', name: '오른쪽 조율 손잡이', path: pegR),
        ColoringSegment(id: 'note', name: '멜로디 음표', path: note),
      ];
    },
  );

  // 12. ⚽ 데굴 축구공
  static final _soccerTemplate = ColoringTemplate(
    id: 'soccer',
    title: '데굴 축구공',
    emoji: '⚽',
    category: ColoringCategory.object,
    createSegments: () {
      final ball = Path()
        ..addOval(const Rect.fromLTWH(45, 50, 190, 190));
      final pentagonC = Path()
        ..moveTo(140, 120)
        ..lineTo(165, 138)
        ..lineTo(155, 168)
        ..lineTo(125, 168)
        ..lineTo(115, 138)
        ..close();
      final patchTop = Path()
        ..moveTo(140, 52)
        ..lineTo(120, 85)
        ..lineTo(160, 85)
        ..close();
      final patchTL = Path()
        ..moveTo(55, 105)
        ..lineTo(85, 105)
        ..lineTo(70, 135)
        ..close();
      final patchTR = Path()
        ..moveTo(225, 105)
        ..lineTo(195, 105)
        ..lineTo(210, 135)
        ..close();
      final patchBL = Path()
        ..moveTo(70, 185)
        ..lineTo(100, 205)
        ..lineTo(85, 230)
        ..close();
      final patchBR = Path()
        ..moveTo(210, 185)
        ..lineTo(180, 205)
        ..lineTo(195, 230)
        ..close();

      return [
        ColoringSegment(id: 'ball', name: '둥근 공 바탕', path: ball),
        ColoringSegment(id: 'patch_c', name: '가운데 오각형', path: pentagonC),
        ColoringSegment(id: 'p_top', name: '위쪽 조각', path: patchTop),
        ColoringSegment(id: 'p_tl', name: '왼쪽 위 조각', path: patchTL),
        ColoringSegment(id: 'p_tr', name: '오른쪽 위 조각', path: patchTR),
        ColoringSegment(id: 'p_bl', name: '왼쪽 아래 조각', path: patchBL),
        ColoringSegment(id: 'p_br', name: '오른쪽 아래 조각', path: patchBR),
      ];
    },
  );

  // 13. 🧸 포근 곰인형
  static final _teddyToyTemplate = ColoringTemplate(
    id: 'teddy_toy',
    title: '포근 곰인형',
    emoji: '🧸',
    category: ColoringCategory.object,
    createSegments: () {
      final earL = Path()
        ..addOval(const Rect.fromLTWH(65, 30, 42, 42));
      final earR = Path()
        ..addOval(const Rect.fromLTWH(173, 30, 42, 42));
      final head = Path()
        ..addOval(const Rect.fromLTWH(75, 50, 130, 110));
      final snout = Path()
        ..addOval(const Rect.fromLTWH(115, 100, 50, 38));
      final body = Path()
        ..addOval(const Rect.fromLTWH(70, 135, 140, 115));
      final belly = Path()
        ..addOval(const Rect.fromLTWH(95, 150, 90, 85));
      final armL = Path()
        ..addOval(const Rect.fromLTWH(42, 145, 42, 60));
      final armR = Path()
        ..addOval(const Rect.fromLTWH(196, 145, 42, 60));
      final footL = Path()
        ..addOval(const Rect.fromLTWH(65, 225, 52, 42));
      final footR = Path()
        ..addOval(const Rect.fromLTWH(163, 225, 52, 42));
      final bow = Path()
        ..addOval(const Rect.fromLTWH(125, 135, 30, 20));

      return [
        ColoringSegment(id: 'ear_l', name: '왼쪽 귀', path: earL),
        ColoringSegment(id: 'ear_r', name: '오른쪽 귀', path: earR),
        ColoringSegment(id: 'arm_l', name: '왼쪽 팔', path: armL),
        ColoringSegment(id: 'arm_r', name: '오른쪽 팔', path: armR),
        ColoringSegment(id: 'foot_l', name: '왼쪽 발', path: footL),
        ColoringSegment(id: 'foot_r', name: '오른쪽 발', path: footR),
        ColoringSegment(id: 'body', name: '통통 몸통', path: body),
        ColoringSegment(id: 'belly', name: '배 패치', path: belly),
        ColoringSegment(id: 'head', name: '곰 얼굴', path: head),
        ColoringSegment(id: 'snout', name: '곰 코 주둥이', path: snout),
        ColoringSegment(id: 'bow', name: '나비 넥타이', path: bow),
      ];
    },
  );

  // 14. 🏰 동화 속 성
  static final _castleTemplate = ColoringTemplate(
    id: 'castle',
    title: '동화 속 성',
    emoji: '🏰',
    category: ColoringCategory.object,
    createSegments: () {
      final wall = Path()
        ..addRect(const Rect.fromLTWH(70, 140, 140, 115));
      final gate = Path()
        ..moveTo(115, 255)
        ..lineTo(115, 195)
        ..quadraticBezierTo(140, 175, 165, 195)
        ..lineTo(165, 255)
        ..close();
      final towerL = Path()
        ..addRect(const Rect.fromLTWH(45, 95, 45, 160));
      final towerR = Path()
        ..addRect(const Rect.fromLTWH(190, 95, 45, 160));
      final roofL = Path()
        ..moveTo(40, 95)
        ..lineTo(67, 35)
        ..lineTo(95, 95)
        ..close();
      final roofR = Path()
        ..moveTo(185, 95)
        ..lineTo(212, 35)
        ..lineTo(240, 95)
        ..close();
      final roofCenter = Path()
        ..moveTo(115, 140)
        ..lineTo(140, 85)
        ..lineTo(165, 140)
        ..close();
      final flagL = Path()
        ..moveTo(67, 35)
        ..lineTo(85, 42)
        ..lineTo(67, 50)
        ..close();
      final flagR = Path()
        ..moveTo(212, 35)
        ..lineTo(230, 42)
        ..lineTo(212, 50)
        ..close();

      return [
        ColoringSegment(id: 'wall', name: '성벽', path: wall),
        ColoringSegment(id: 'gate', name: '성문', path: gate),
        ColoringSegment(id: 'tower_l', name: '왼쪽 탑', path: towerL),
        ColoringSegment(id: 'tower_r', name: '오른쪽 탑', path: towerR),
        ColoringSegment(id: 'roof_l', name: '왼쪽 탑 지붕', path: roofL),
        ColoringSegment(id: 'roof_r', name: '오른쪽 탑 지붕', path: roofR),
        ColoringSegment(id: 'roof_c', name: '가운데 지붕', path: roofCenter),
        ColoringSegment(id: 'flag_l', name: '왼쪽 깃발', path: flagL),
        ColoringSegment(id: 'flag_r', name: '오른쪽 깃발', path: flagR),
      ];
    },
  );

  // 15. 🌈 일곱빛깔 무지개
  static final _rainbowTemplate = ColoringTemplate(
    id: 'rainbow',
    title: '일곱빛깔 무지개',
    emoji: '🌈',
    category: ColoringCategory.object,
    createSegments: () {
      final arc1 = Path()
        ..moveTo(40, 190)
        ..quadraticBezierTo(140, 50, 240, 190)
        ..quadraticBezierTo(140, 75, 55, 190)
        ..close();
      final arc2 = Path()
        ..moveTo(55, 190)
        ..quadraticBezierTo(140, 75, 225, 190)
        ..quadraticBezierTo(140, 100, 70, 190)
        ..close();
      final arc3 = Path()
        ..moveTo(70, 190)
        ..quadraticBezierTo(140, 100, 210, 190)
        ..quadraticBezierTo(140, 125, 85, 190)
        ..close();
      final arc4 = Path()
        ..moveTo(85, 190)
        ..quadraticBezierTo(140, 125, 195, 190)
        ..quadraticBezierTo(140, 150, 100, 190)
        ..close();
      final cloudL = Path()
        ..addOval(const Rect.fromLTWH(25, 165, 80, 50));
      final cloudR = Path()
        ..addOval(const Rect.fromLTWH(175, 165, 80, 50));
      final star = Path()
        ..addOval(const Rect.fromLTWH(125, 30, 30, 30));

      return [
        ColoringSegment(id: 'arc_1', name: '빨간 띠', path: arc1),
        ColoringSegment(id: 'arc_2', name: '노란 띠', path: arc2),
        ColoringSegment(id: 'arc_3', name: '초록 띠', path: arc3),
        ColoringSegment(id: 'arc_4', name: '파란 띠', path: arc4),
        ColoringSegment(id: 'cloud_l', name: '왼쪽 뭉게구름', path: cloudL),
        ColoringSegment(id: 'cloud_r', name: '오른쪽 뭉게구름', path: cloudR),
        ColoringSegment(id: 'star', name: '꼭대기 별', path: star),
      ];
    },
  );

  // 16. ☀️ 방긋 해님
  static final _sunTemplate = ColoringTemplate(
    id: 'sun',
    title: '방긋 해님',
    emoji: '☀️',
    category: ColoringCategory.object,
    createSegments: () {
      final sunFace = Path()
        ..addOval(const Rect.fromLTWH(75, 80, 130, 130));
      final cheekL = Path()
        ..addOval(const Rect.fromLTWH(88, 155, 22, 18));
      final cheekR = Path()
        ..addOval(const Rect.fromLTWH(170, 155, 22, 18));
      final rayTop = Path()
        ..moveTo(140, 25)
        ..lineTo(125, 68)
        ..lineTo(155, 68)
        ..close();
      final rayBottom = Path()
        ..moveTo(140, 265)
        ..lineTo(125, 222)
        ..lineTo(155, 222)
        ..close();
      final rayLeft = Path()
        ..moveTo(25, 145)
        ..lineTo(65, 130)
        ..lineTo(65, 160)
        ..close();
      final rayRight = Path()
        ..moveTo(255, 145)
        ..lineTo(215, 130)
        ..lineTo(215, 160)
        ..close();
      final rayTL = Path()
        ..moveTo(55, 60)
        ..lineTo(85, 75)
        ..lineTo(70, 95)
        ..close();
      final rayTR = Path()
        ..moveTo(225, 60)
        ..lineTo(195, 75)
        ..lineTo(210, 95)
        ..close();

      return [
        ColoringSegment(id: 'sun_face', name: '동그란 해님 얼굴', path: sunFace),
        ColoringSegment(id: 'cheek_l', name: '왼쪽 볼', path: cheekL),
        ColoringSegment(id: 'cheek_r', name: '오른쪽 볼', path: cheekR),
        ColoringSegment(id: 'ray_t', name: '위쪽 햇살', path: rayTop),
        ColoringSegment(id: 'ray_b', name: '아래쪽 햇살', path: rayBottom),
        ColoringSegment(id: 'ray_l', name: '왼쪽 햇살', path: rayLeft),
        ColoringSegment(id: 'ray_r', name: '오른쪽 햇살', path: rayRight),
        ColoringSegment(id: 'ray_tl', name: '왼쪽 위 햇살', path: rayTL),
        ColoringSegment(id: 'ray_tr', name: '오른쪽 위 햇살', path: rayTR),
      ];
    },
  );

  // 17. 🌙 새근 달님
  static final _moonTemplate = ColoringTemplate(
    id: 'moon',
    title: '새근 달님',
    emoji: '🌙',
    category: ColoringCategory.object,
    createSegments: () {
      final crescent = Path()
        ..moveTo(140, 40)
        ..quadraticBezierTo(50, 90, 80, 195)
        ..quadraticBezierTo(120, 260, 205, 235)
        ..quadraticBezierTo(115, 230, 95, 165)
        ..quadraticBezierTo(90, 85, 140, 40)
        ..close();
      final nightcap = Path()
        ..moveTo(130, 48)
        ..lineTo(165, 30)
        ..lineTo(195, 55)
        ..lineTo(155, 75)
        ..close();
      final capPom = Path()
        ..addOval(const Rect.fromLTWH(190, 45, 22, 22));
      final cheek = Path()
        ..addOval(const Rect.fromLTWH(85, 155, 20, 16));
      final cloud = Path()
        ..addOval(const Rect.fromLTWH(135, 190, 100, 45));
      final star1 = Path()
        ..addOval(const Rect.fromLTWH(185, 100, 28, 28));
      final star2 = Path()
        ..addOval(const Rect.fromLTWH(220, 145, 22, 22));

      return [
        ColoringSegment(id: 'crescent', name: '초승달 몸체', path: crescent),
        ColoringSegment(id: 'cap', name: '수면 모자', path: nightcap),
        ColoringSegment(id: 'pom', name: '모자 방울', path: capPom),
        ColoringSegment(id: 'cheek', name: '발그레 볼', path: cheek),
        ColoringSegment(id: 'cloud', name: '포근 밤구름', path: cloud),
        ColoringSegment(id: 'star_1', name: '빛나는 별 1', path: star1),
        ColoringSegment(id: 'star_2', name: '빛나는 별 2', path: star2),
      ];
    },
  );

  // 18. 🌳 초록 나무
  static final _treeTemplate = ColoringTemplate(
    id: 'tree',
    title: '초록 나무',
    emoji: '🌳',
    category: ColoringCategory.object,
    createSegments: () {
      final trunk = Path()
        ..moveTo(125, 150)
        ..lineTo(115, 260)
        ..lineTo(165, 260)
        ..lineTo(155, 150)
        ..close();
      final leavesB = Path()
        ..addOval(const Rect.fromLTWH(65, 120, 150, 85));
      final leavesM = Path()
        ..addOval(const Rect.fromLTWH(75, 75, 130, 80));
      final leavesT = Path()
        ..addOval(const Rect.fromLTWH(95, 35, 90, 70));
      final apple1 = Path()
        ..addOval(const Rect.fromLTWH(95, 115, 24, 24));
      final apple2 = Path()
        ..addOval(const Rect.fromLTWH(165, 105, 24, 24));
      final bird = Path()
        ..addOval(const Rect.fromLTWH(130, 45, 22, 18));

      return [
        ColoringSegment(id: 'trunk', name: '튼튼한 나무 기둥', path: trunk),
        ColoringSegment(id: 'leaves_b', name: '아래쪽 잎더미', path: leavesB),
        ColoringSegment(id: 'leaves_m', name: '중간 잎더미', path: leavesM),
        ColoringSegment(id: 'leaves_t', name: '꼭대기 잎더미', path: leavesT),
        ColoringSegment(id: 'apple_1', name: '빨간 열매 1', path: apple1),
        ColoringSegment(id: 'apple_2', name: '빨간 열매 2', path: apple2),
        ColoringSegment(id: 'bird', name: '나무 위 작은 새', path: bird),
      ];
    },
  );

  // 19. 🍄 숲속 버섯
  static final _mushroomTemplate = ColoringTemplate(
    id: 'mushroom',
    title: '숲속 버섯',
    emoji: '🍄',
    category: ColoringCategory.object,
    createSegments: () {
      final cap = Path()
        ..moveTo(50, 150)
        ..quadraticBezierTo(140, 30, 230, 150)
        ..close();
      final stem = Path()
        ..moveTo(105, 150)
        ..lineTo(95, 245)
        ..lineTo(185, 245)
        ..lineTo(175, 150)
        ..close();
      final spot1 = Path()
        ..addOval(const Rect.fromLTWH(85, 90, 32, 32));
      final spot2 = Path()
        ..addOval(const Rect.fromLTWH(135, 65, 30, 30));
      final spot3 = Path()
        ..addOval(const Rect.fromLTWH(165, 105, 28, 28));
      final grassL = Path()
        ..moveTo(70, 245)
        ..lineTo(85, 215)
        ..lineTo(100, 245)
        ..close();
      final grassR = Path()
        ..moveTo(180, 245)
        ..lineTo(195, 215)
        ..lineTo(210, 245)
        ..close();

      return [
        ColoringSegment(id: 'stem', name: '버섯 기둥', path: stem),
        ColoringSegment(id: 'cap', name: '빨간 버섯 갓', path: cap),
        ColoringSegment(id: 'spot_1', name: '땡땡이 무늬 1', path: spot1),
        ColoringSegment(id: 'spot_2', name: '땡땡이 무늬 2', path: spot2),
        ColoringSegment(id: 'spot_3', name: '땡땡이 무늬 3', path: spot3),
        ColoringSegment(id: 'grass_l', name: '왼쪽 풀잎', path: grassL),
        ColoringSegment(id: 'grass_r', name: '오른쪽 풀잎', path: grassR),
      ];
    },
  );

  // 20. 🧃 새콤달콤 주스
  static final _juiceTemplate = ColoringTemplate(
    id: 'juice',
    title: '새콤달콤 주스',
    emoji: '🧃',
    category: ColoringCategory.object,
    createSegments: () {
      final straw = Path()
        ..moveTo(160, 35)
        ..lineTo(178, 48)
        ..lineTo(152, 90)
        ..lineTo(142, 85)
        ..close();
      final box = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(70, 85, 140, 170),
          const Radius.circular(16),
        ));
      final boxTop = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(70, 85, 140, 30),
          const Radius.circular(12),
        ));
      final orangeSlice = Path()
        ..addOval(const Rect.fromLTWH(95, 145, 65, 65));
      final orangeInner = Path()
        ..addOval(const Rect.fromLTWH(105, 155, 45, 45));
      final leaf = Path()
        ..addOval(const Rect.fromLTWH(145, 135, 28, 18));
      final droplet = Path()
        ..addOval(const Rect.fromLTWH(165, 190, 16, 24));

      return [
        ColoringSegment(id: 'straw', name: '빨대', path: straw),
        ColoringSegment(id: 'box', name: '주스 팩 몸체', path: box),
        ColoringSegment(id: 'top', name: '팩 윗면 테두리', path: boxTop),
        ColoringSegment(id: 'orange', name: '오렌지 껍질', path: orangeSlice),
        ColoringSegment(id: 'orange_in', name: '과즙 알맹이', path: orangeInner),
        ColoringSegment(id: 'leaf', name: '풋풋한 나뭇잎', path: leaf),
        ColoringSegment(id: 'droplet', name: '달콤 주스 방울', path: droplet),
      ];
    },
  );
}
