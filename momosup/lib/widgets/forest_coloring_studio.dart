import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../utils/sound_effects.dart';
import 'forest_game_ui.dart';
import 'forest_landscape.dart';
import 'forest_play_stage.dart';
import 'game_particles.dart';

/// Represents a single colorable segment in a coloring template.
class ColoringSegment {
  ColoringSegment({
    required this.id,
    required this.name,
    required this.path,
    this.color,
    this.isBorderOnly = false,
  });

  final String id;
  final String name;
  final Path path;
  Color? color;
  final bool isBorderOnly;

  ColoringSegment copyWith({Color? color}) => ColoringSegment(
        id: id,
        name: name,
        path: path,
        color: color ?? this.color,
        isBorderOnly: isBorderOnly,
      );
}

/// A complete coloring template with multiple segments.
class ColoringTemplate {
  ColoringTemplate({
    required this.id,
    required this.title,
    required this.emoji,
    required this.createSegments,
  });

  final String id;
  final String title;
  final String emoji;
  final List<ColoringSegment> Function() createSegments;
}

/// 8 diverse and engaging templates for toddlers (Animals, Vehicles, Nature, Fantasy).
class ColoringCatalog {
  static List<ColoringTemplate> get all => [
        _rabbitTemplate,
        _bearTemplate,
        _catTemplate,
        _busTemplate,
        _flowerTemplate,
        _rocketTemplate,
        _fruitTemplate,
        _whaleTemplate,
      ];

  // 1. 🐰 포근 토끼 (Rabbit)
  static final _rabbitTemplate = ColoringTemplate(
    id: 'rabbit',
    title: '포근 토끼',
    emoji: '🐰',
    createSegments: () {
      final leftEar = Path()
        ..moveTo(95, 130)
        ..quadraticBezierTo(65, 30, 95, 10)
        ..quadraticBezierTo(125, 30, 115, 120)
        ..close();

      final rightEar = Path()
        ..moveTo(165, 120)
        ..quadraticBezierTo(155, 30, 185, 10)
        ..quadraticBezierTo(215, 30, 185, 130)
        ..close();

      final innerEarLeft = Path()
        ..moveTo(97, 115)
        ..quadraticBezierTo(80, 45, 95, 25)
        ..quadraticBezierTo(112, 45, 107, 110)
        ..close();

      final innerEarRight = Path()
        ..moveTo(173, 110)
        ..quadraticBezierTo(168, 45, 185, 25)
        ..quadraticBezierTo(200, 45, 183, 115)
        ..close();

      final body = Path()
        ..moveTo(95, 200)
        ..quadraticBezierTo(65, 240, 75, 280)
        ..lineTo(205, 280)
        ..quadraticBezierTo(215, 240, 185, 200)
        ..close();

      final head = Path()
        ..addOval(const Rect.fromLTWH(75, 90, 130, 120));

      final cheekLeft = Path()
        ..addOval(const Rect.fromLTWH(88, 160, 22, 16));

      final cheekRight = Path()
        ..addOval(const Rect.fromLTWH(170, 160, 22, 16));

      final snout = Path()
        ..addOval(const Rect.fromLTWH(122, 150, 36, 28));

      final ribbon = Path()
        ..moveTo(140, 200)
        ..lineTo(115, 190)
        ..lineTo(115, 215)
        ..close()
        ..moveTo(140, 200)
        ..lineTo(165, 190)
        ..lineTo(165, 215)
        ..close()
        ..addOval(const Rect.fromLTWH(133, 193, 14, 14));

      return [
        ColoringSegment(id: 'left_ear', name: '왼쪽 귀', path: leftEar),
        ColoringSegment(id: 'right_ear', name: '오른쪽 귀', path: rightEar),
        ColoringSegment(id: 'inner_ear_l', name: '왼쪽 귀 안쪽', path: innerEarLeft),
        ColoringSegment(id: 'inner_ear_r', name: '오른쪽 귀 안쪽', path: innerEarRight),
        ColoringSegment(id: 'body', name: '몸통', path: body),
        ColoringSegment(id: 'head', name: '얼굴', path: head),
        ColoringSegment(id: 'snout', name: '코와 주둥이', path: snout),
        ColoringSegment(id: 'cheek_l', name: '왼쪽 볼', path: cheekLeft),
        ColoringSegment(id: 'cheek_r', name: '오른쪽 볼', path: cheekRight),
        ColoringSegment(id: 'ribbon', name: '예쁜 리본', path: ribbon),
      ];
    },
  );

  // 2. 🐻 아기 곰 (Bear)
  static final _bearTemplate = ColoringTemplate(
    id: 'bear',
    title: '아기 곰',
    emoji: '🐻',
    createSegments: () {
      final leftEar = Path()..addOval(const Rect.fromLTWH(65, 60, 48, 48));
      final rightEar = Path()..addOval(const Rect.fromLTWH(167, 60, 48, 48));
      final innerEarLeft = Path()..addOval(const Rect.fromLTWH(75, 70, 28, 28));
      final innerEarRight = Path()..addOval(const Rect.fromLTWH(177, 70, 28, 28));
      final head = Path()..addOval(const Rect.fromLTWH(70, 80, 140, 130));
      final snout = Path()..addOval(const Rect.fromLTWH(110, 145, 60, 45));
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
        ColoringSegment(id: 'inner_ear_l', name: '왼쪽 귀 안쪽', path: innerEarLeft),
        ColoringSegment(id: 'inner_ear_r', name: '오른쪽 귀 안쪽', path: innerEarRight),
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

  // 3. 🐱 숲속 야옹이 (Cat)
  static final _catTemplate = ColoringTemplate(
    id: 'cat',
    title: '숲속 야옹이',
    emoji: '🐱',
    createSegments: () {
      final leftEar = Path()
        ..moveTo(80, 120)
        ..lineTo(70, 50)
        ..lineTo(120, 95)
        ..close();
      final rightEar = Path()
        ..moveTo(160, 95)
        ..lineTo(210, 50)
        ..lineTo(200, 120)
        ..close();
      final innerEarL = Path()
        ..moveTo(85, 110)
        ..lineTo(78, 65)
        ..lineTo(112, 95)
        ..close();
      final innerEarR = Path()
        ..moveTo(168, 95)
        ..lineTo(202, 65)
        ..lineTo(195, 110)
        ..close();
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
        ColoringSegment(id: 'inner_ear_l', name: '왼쪽 귀 안쪽', path: innerEarL),
        ColoringSegment(id: 'inner_ear_r', name: '오른쪽 귀 안쪽', path: innerEarR),
        ColoringSegment(id: 'body', name: '몸통', path: body),
        ColoringSegment(id: 'head', name: '얼굴', path: head),
        ColoringSegment(id: 'cheek_l', name: '왼쪽 볼', path: cheekL),
        ColoringSegment(id: 'cheek_r', name: '오른쪽 볼', path: cheekR),
        ColoringSegment(id: 'bell', name: '방울', path: bell),
      ];
    },
  );

  // 4. 🚌 붕붕 버스 (Bus)
  static final _busTemplate = ColoringTemplate(
    id: 'bus',
    title: '붕붕 버스',
    emoji: '🚌',
    createSegments: () {
      final roof = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(45, 65, 190, 24),
          const Radius.circular(10),
        ));
      final body = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(40, 85, 200, 120),
          const Radius.circular(24),
        ));
      final window1 = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(55, 100, 48, 45),
          const Radius.circular(10),
        ));
      final window2 = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(115, 100, 48, 45),
          const Radius.circular(10),
        ));
      final window3 = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(175, 100, 50, 45),
          const Radius.circular(10),
        ));
      final wheelL = Path()..addOval(const Rect.fromLTWH(65, 185, 46, 46));
      final wheelR = Path()..addOval(const Rect.fromLTWH(165, 185, 46, 46));
      final hubcapL = Path()..addOval(const Rect.fromLTWH(78, 198, 20, 20));
      final hubcapR = Path()..addOval(const Rect.fromLTWH(178, 198, 20, 20));
      final light = Path()..addOval(const Rect.fromLTWH(228, 155, 16, 20));
      final road = Path()
        ..addRect(const Rect.fromLTWH(20, 225, 240, 35));

      return [
        ColoringSegment(id: 'road', name: '길', path: road),
        ColoringSegment(id: 'body', name: '버스 몸체', path: body),
        ColoringSegment(id: 'roof', name: '지붕', path: roof),
        ColoringSegment(id: 'window_1', name: '앞 창문', path: window1),
        ColoringSegment(id: 'window_2', name: '가운데 창문', path: window2),
        ColoringSegment(id: 'window_3', name: '뒤 창문', path: window3),
        ColoringSegment(id: 'light', name: '전조등', path: light),
        ColoringSegment(id: 'wheel_l', name: '앞바퀴', path: wheelL),
        ColoringSegment(id: 'wheel_r', name: '뒷바퀴', path: wheelR),
        ColoringSegment(id: 'hubcap_l', name: '앞바퀴 휠', path: hubcapL),
        ColoringSegment(id: 'hubcap_r', name: '뒷바퀴 휠', path: hubcapR),
      ];
    },
  );

  // 5. 🌸 무지개 꽃밭 (Flower)
  static final _flowerTemplate = ColoringTemplate(
    id: 'flower',
    title: '무지개 꽃',
    emoji: '🌸',
    createSegments: () {
      final pot = Path()
        ..moveTo(100, 215)
        ..lineTo(180, 215)
        ..lineTo(170, 275)
        ..lineTo(110, 275)
        ..close();
      final stem = Path()
        ..addRect(const Rect.fromLTWH(134, 130, 12, 90));
      final leafL = Path()
        ..moveTo(134, 185)
        ..quadraticBezierTo(85, 175, 90, 150)
        ..quadraticBezierTo(120, 155, 134, 185)
        ..close();
      final leafR = Path()
        ..moveTo(146, 170)
        ..quadraticBezierTo(195, 160, 190, 135)
        ..quadraticBezierTo(160, 140, 146, 170)
        ..close();

      final center = const Offset(140, 85);
      final petals = <ColoringSegment>[];
      for (var i = 0; i < 6; i++) {
        final angle = i * math.pi / 3;
        final px = center.dx + math.cos(angle) * 38;
        final py = center.dy + math.sin(angle) * 38;
        final petal = Path()..addOval(Rect.fromCircle(center: Offset(px, py), radius: 24));
        petals.add(ColoringSegment(id: 'petal_$i', name: '꽃잎 ${i + 1}', path: petal));
      }
      final flowerCenter = Path()..addOval(Rect.fromCircle(center: center, radius: 25));

      return [
        ColoringSegment(id: 'stem', name: '줄기', path: stem),
        ColoringSegment(id: 'leaf_l', name: '왼쪽 잎', path: leafL),
        ColoringSegment(id: 'leaf_r', name: '오른쪽 잎', path: leafR),
        ColoringSegment(id: 'pot', name: '화분', path: pot),
        ...petals,
        ColoringSegment(id: 'center', name: '꽃술', path: flowerCenter),
      ];
    },
  );

  // 6. 🚀 우주 로켓 (Rocket)
  static final _rocketTemplate = ColoringTemplate(
    id: 'rocket',
    title: '우주 로켓',
    emoji: '🚀',
    createSegments: () {
      final nose = Path()
        ..moveTo(140, 25)
        ..quadraticBezierTo(115, 65, 115, 85)
        ..lineTo(165, 85)
        ..quadraticBezierTo(165, 65, 140, 25)
        ..close();
      final body = Path()
        ..moveTo(115, 85)
        ..lineTo(165, 85)
        ..lineTo(170, 195)
        ..lineTo(110, 195)
        ..close();
      final finL = Path()
        ..moveTo(110, 155)
        ..lineTo(70, 205)
        ..lineTo(110, 195)
        ..close();
      final finR = Path()
        ..moveTo(170, 155)
        ..lineTo(210, 205)
        ..lineTo(170, 195)
        ..close();
      final flame = Path()
        ..moveTo(125, 195)
        ..quadraticBezierTo(140, 250, 140, 270)
        ..quadraticBezierTo(140, 250, 155, 195)
        ..close();
      final window = Path()..addOval(const Rect.fromLTWH(125, 105, 30, 30));
      final star1 = Path()..addOval(const Rect.fromLTWH(50, 45, 18, 18));
      final star2 = Path()..addOval(const Rect.fromLTWH(215, 65, 22, 22));

      return [
        ColoringSegment(id: 'flame', name: '로켓 불꽃', path: flame),
        ColoringSegment(id: 'fin_l', name: '왼쪽 날개', path: finL),
        ColoringSegment(id: 'fin_r', name: '오른쪽 날개', path: finR),
        ColoringSegment(id: 'body', name: '로켓 몸통', path: body),
        ColoringSegment(id: 'nose', name: '로켓 머리', path: nose),
        ColoringSegment(id: 'window', name: '창문', path: window),
        ColoringSegment(id: 'star1', name: '작은 별', path: star1),
        ColoringSegment(id: 'star2', name: '큰 별', path: star2),
      ];
    },
  );

  // 7. 🍎 달콤 과일 (Fruits)
  static final _fruitTemplate = ColoringTemplate(
    id: 'fruit',
    title: '달콤 과일',
    emoji: '🍎',
    createSegments: () {
      final basket = Path()
        ..moveTo(65, 160)
        ..lineTo(215, 160)
        ..quadraticBezierTo(205, 255, 140, 260)
        ..quadraticBezierTo(75, 255, 65, 160)
        ..close();
      final basketRim = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(55, 150, 170, 18),
          const Radius.circular(8),
        ));
      final apple = Path()..addOval(const Rect.fromLTWH(75, 95, 58, 62));
      final appleLeaf = Path()
        ..moveTo(104, 95)
        ..quadraticBezierTo(90, 75, 110, 75)
        ..quadraticBezierTo(115, 88, 104, 95)
        ..close();
      final orange = Path()..addOval(const Rect.fromLTWH(145, 100, 56, 56));
      final grape1 = Path()..addOval(const Rect.fromLTWH(118, 90, 24, 24));
      final grape2 = Path()..addOval(const Rect.fromLTWH(135, 82, 22, 22));
      final grape3 = Path()..addOval(const Rect.fromLTWH(126, 110, 24, 24));

      return [
        ColoringSegment(id: 'basket', name: '과일 바구니', path: basket),
        ColoringSegment(id: 'basket_rim', name: '바구니 테두리', path: basketRim),
        ColoringSegment(id: 'apple', name: '사과', path: apple),
        ColoringSegment(id: 'apple_leaf', name: '사과 잎', path: appleLeaf),
        ColoringSegment(id: 'orange', name: '오렌지', path: orange),
        ColoringSegment(id: 'grape_1', name: '포도알 1', path: grape1),
        ColoringSegment(id: 'grape_2', name: '포도알 2', path: grape2),
        ColoringSegment(id: 'grape_3', name: '포도알 3', path: grape3),
      ];
    },
  );

  // 8. 🐳 바다 고래 (Whale)
  static final _whaleTemplate = ColoringTemplate(
    id: 'whale',
    title: '바다 고래',
    emoji: '🐳',
    createSegments: () {
      final whaleBody = Path()
        ..moveTo(60, 160)
        ..quadraticBezierTo(70, 90, 150, 95)
        ..quadraticBezierTo(210, 100, 240, 130)
        ..lineTo(260, 115)
        ..lineTo(255, 140)
        ..lineTo(265, 160)
        ..lineTo(235, 155)
        ..quadraticBezierTo(190, 185, 130, 195)
        ..quadraticBezierTo(70, 200, 60, 160)
        ..close();
      final belly = Path()
        ..moveTo(60, 160)
        ..quadraticBezierTo(100, 195, 150, 190)
        ..quadraticBezierTo(90, 200, 60, 160)
        ..close();
      final fin = Path()
        ..moveTo(125, 165)
        ..quadraticBezierTo(140, 195, 160, 185)
        ..quadraticBezierTo(145, 160, 125, 165)
        ..close();
      final waterSpout = Path()
        ..moveTo(135, 95)
        ..quadraticBezierTo(120, 50, 100, 55)
        ..quadraticBezierTo(125, 75, 135, 95)
        ..moveTo(137, 95)
        ..quadraticBezierTo(145, 45, 170, 48)
        ..quadraticBezierTo(150, 75, 137, 95)
        ..close();
      final wave1 = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(30, 215, 220, 20),
          const Radius.circular(10),
        ));
      final wave2 = Path()
        ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(50, 240, 180, 16),
          const Radius.circular(8),
        ));

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

/// The interactive Tap-to-Fill coloring studio widget.
class ForestColoringStudio extends StatefulWidget {
  const ForestColoringStudio({
    this.initialTemplateIndex = 0,
    this.quiet = false,
    this.onChanged,
    super.key,
  });

  final int initialTemplateIndex;
  final bool quiet;
  final VoidCallback? onChanged;

  @override
  State<ForestColoringStudio> createState() => _ForestColoringStudioState();
}

class _ForestColoringStudioState extends State<ForestColoringStudio> {
  // 12 warm forest-friendly paint colors
  static const palette = [
    Color(0xFFE25B5B), // 딸기 빨강
    Color(0xFFF48FB1), // 복숭아 핑크
    Color(0xFFFF9E40), // 살구 오렌지
    Color(0xFFF9D423), // 개나리 노랑
    Color(0xFF9CCC65), // 새싹 연두
    Color(0xFF4CAF50), // 깊은숲 초록
    Color(0xFF4FC3F7), // 하늘 파랑
    Color(0xFF2979FF), // 바다 파랑
    Color(0xFFAB47BC), // 포도 보라
    Color(0xFF8D6E63), // 초코 갈색
    Color(0xFFFFF9E9), // 포근 크림
    Color(0xFF424242), // 숲 먹색
  ];

  static const colorNames = [
    '딸기 빨강',
    '복숭아 핑크',
    '살구 오렌지',
    '개나리 노랑',
    '새싹 연두',
    '숲 초록',
    '하늘 파랑',
    '바다 파랑',
    '포도 보라',
    '초코 갈색',
    '포근 크림',
    '숲 먹색',
  ];

  late int selectedTemplateIndex;
  int selectedColorIndex = 0;
  late List<ColoringSegment> currentSegments;
  final List<List<Color?>> _history = [];
  final GlobalKey<GameParticlesState> _particlesKey = GlobalKey();
  int _lastTappedSegment = -1;
  int _wobble = 0;
  bool _celebrated = false;

  @override
  void initState() {
    super.initState();
    selectedTemplateIndex = widget.initialTemplateIndex.clamp(0, ColoringCatalog.all.length - 1);
    _loadTemplate(selectedTemplateIndex);
  }

  void _loadTemplate(int index) {
    selectedTemplateIndex = index;
    currentSegments = ColoringCatalog.all[index].createSegments();
    _history.clear();
    _saveHistory();
    _celebrated = false;
  }

  void _saveHistory() {
    _history.add(currentSegments.map((s) => s.color).toList());
    if (_history.length > 30) _history.removeAt(0);
  }

  void _undo() {
    if (_history.length <= 1) return;
    setState(() {
      _history.removeLast();
      final prev = _history.last;
      for (var i = 0; i < currentSegments.length; i++) {
        currentSegments[i].color = prev[i];
      }
    });
    SoundEffects.instance.pop();
    widget.onChanged?.call();
  }

  void _reset() {
    setState(() {
      _loadTemplate(selectedTemplateIndex);
    });
    SoundEffects.instance.whoosh();
    widget.onChanged?.call();
  }

  void _handleTap(Offset localPos, Size canvasSize) {
    // Canvas is normalized to 280 x 290 reference frame
    final scaleX = canvasSize.width / 280;
    final scaleY = canvasSize.height / 290;
    final normalizedPos = Offset(localPos.dx / scaleX, localPos.dy / scaleY);

    // Hit test segments from top to bottom (last drawn wins)
    int hitIndex = -1;
    for (var i = currentSegments.length - 1; i >= 0; i--) {
      if (currentSegments[i].path.contains(normalizedPos)) {
        hitIndex = i;
        break;
      }
    }

    if (hitIndex != -1) {
      final selectedColor = palette[selectedColorIndex];
      setState(() {
        currentSegments[hitIndex].color = selectedColor;
        _lastTappedSegment = hitIndex;
        _wobble++;
      });
      _saveHistory();
      SoundEffects.instance.pop();
      widget.onChanged?.call();

      // Check if all segments are colored
      final coloredCount = currentSegments.where((s) => s.color != null).length;
      if (coloredCount >= currentSegments.length && !_celebrated) {
        _celebrated = true;
        SoundEffects.instance.tada();
        if (!widget.quiet) {
          _particlesKey.currentState?.celebrate(Offset(canvasSize.width / 2, canvasSize.height / 2));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final template = ColoringCatalog.all[selectedTemplateIndex];
    final isWide = forestIsWide(context);

    // 1. Template Selector Chips
    final templateSelector = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          for (var i = 0; i < ColoringCatalog.all.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () {
                  if (selectedTemplateIndex != i) {
                    SoundEffects.instance.pop();
                    setState(() => _loadTemplate(i));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selectedTemplateIndex == i
                        ? const Color(0xFF5A7942)
                        : const Color(0xFFEAD2A0),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selectedTemplateIndex == i
                          ? const Color(0xFFF9E8BD)
                          : const Color(0xFFD4B57D),
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Color(0x33000000), offset: Offset(0, 2), blurRadius: 4),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(ColoringCatalog.all[i].emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(
                        ColoringCatalog.all[i].title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: selectedTemplateIndex == i ? Colors.white : forestInk,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    // 2. Title Row
    final titleRow = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(template.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(
            '${template.title} 색칠하기',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: forestInk,
            ),
          ),
        ],
      ),
    );

    // 3. Canvas Widget
    final canvasWidget = Center(
      child: SceneReaction(
        event: _wobble,
        quiet: widget.quiet,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFD4B57D),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFAF8C57), width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x447B744B),
                offset: Offset(0, 6),
                blurRadius: 10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: isWide ? 260 : 300,
              height: isWide ? 245 : 290,
              color: const Color(0xFFFFFDF5),
              child: Stack(
                children: [
                  LayoutBuilder(
                    builder: (ctx, box) => GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (d) => _handleTap(d.localPosition, box.biggest),
                      child: CustomPaint(
                        size: box.biggest,
                        painter: _ColoringCanvasPainter(
                          segments: currentSegments,
                          lastTapped: _lastTappedSegment,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: GameParticles(key: _particlesKey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // 4. Palette Widget
    final paletteWidget = Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < palette.length; i++)
          Semantics(
            label: '${colorNames[i]} 물감 선택',
            button: true,
            child: GestureDetector(
              onTap: () {
                SoundEffects.instance.pop();
                setState(() => selectedColorIndex = i);
              },
              child: AnimatedScale(
                scale: selectedColorIndex == i ? 1.18 : 1.0,
                duration: const Duration(milliseconds: 160),
                child: Container(
                  width: isWide ? 40 : 40,
                  height: isWide ? 40 : 40,
                  decoration: BoxDecoration(
                    color: palette[i],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selectedColorIndex == i
                          ? const Color(0xFF2C4A28)
                          : Colors.white,
                      width: selectedColorIndex == i ? 3.5 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(selectedColorIndex == i ? 70 : 35),
                        offset: const Offset(0, 3),
                        blurRadius: selectedColorIndex == i ? 6 : 3,
                      ),
                    ],
                  ),
                  child: selectedColorIndex == i
                      ? const Icon(
                          Icons.check_rounded,
                          size: 20,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
            ),
          ),
      ],
    );

    // 5. Action Buttons (Undo & Reset)
    final actionButtons = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ForestAction(
          label: '되돌리기',
          caption: '되돌리기',
          icon: Icons.undo_rounded,
          size: 58,
          quiet: widget.quiet,
          onPressed: _history.length > 1 ? _undo : null,
        ),
        const SizedBox(width: 16),
        ForestAction(
          label: '깨끗이 다시 칠하기',
          caption: '다시 시작',
          icon: Icons.refresh_rounded,
          size: 58,
          quiet: widget.quiet,
          onPressed: _reset,
        ),
      ],
    );

    if (isWide) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                titleRow,
                canvasWidget,
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 250,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                templateSelector,
                const SizedBox(height: 8),
                paletteWidget,
                const SizedBox(height: 10),
                actionButtons,
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        templateSelector,
        titleRow,
        canvasWidget,
        const SizedBox(height: 12),
        paletteWidget,
        const SizedBox(height: 12),
        actionButtons,
      ],
    );
  }
}

/// Custom painter for the coloring canvas.
class _ColoringCanvasPainter extends CustomPainter {
  _ColoringCanvasPainter({
    required this.segments,
    required this.lastTapped,
  });

  final List<ColoringSegment> segments;
  final int lastTapped;

  @override
  void paint(Canvas canvas, Size size) {
    // Reference canvas coordinate is 280 x 290
    final scaleX = size.width / 280;
    final scaleY = size.height / 290;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    // 1. Draw segment fills
    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = seg.color ?? const Color(0xFFFAF7EE);

      canvas.drawPath(seg.path, fillPaint);
    }

    // 2. Draw crisp dark borders over all segments
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF382E25);

    for (final seg in segments) {
      canvas.drawPath(seg.path, borderPaint);
    }

    // 3. Draw inner details (eyes, nose, mouth lines) for character expressions
    final detailPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF2B221B);

    final lineDetail = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF2B221B);

    // Eyes and cute features depending on segments present
    if (segments.any((s) => s.id == 'snout' || s.id == 'head')) {
      // Rabbit / Bear eye positions
      canvas.drawCircle(const Offset(112, 135), 4.5, detailPaint);
      canvas.drawCircle(const Offset(168, 135), 4.5, detailPaint);
      // Highlights
      canvas.drawCircle(const Offset(110.5, 133.5), 1.5, Paint()..color = Colors.white);
      canvas.drawCircle(const Offset(166.5, 133.5), 1.5, Paint()..color = Colors.white);
      // Small nose & mouth
      canvas.drawOval(const Rect.fromLTWH(136, 155, 8, 6), detailPaint);
      final mouth = Path()
        ..moveTo(140, 161)
        ..lineTo(140, 167)
        ..moveTo(134, 167)
        ..quadraticBezierTo(140, 172, 140, 167)
        ..quadraticBezierTo(140, 172, 146, 167);
      canvas.drawPath(mouth, lineDetail);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_ColoringCanvasPainter oldDelegate) => true;
}
