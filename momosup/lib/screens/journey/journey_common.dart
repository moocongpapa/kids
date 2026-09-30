import '../../widgets/forest_game_ui.dart';

ForestObject journeyProp(String value) => ForestObject.values.firstWhere(
  (o) => o.name == value,
  orElse: () => ForestObject.leaf,
);

String propLabel(String value) =>
    const {
      'berry': '열매',
      'raspberry': '빨간 열매',
      'blueberry': '파란 열매',
      'basket': '바구니',
      'bush': '풀숲',
      'music': '소리',
      'paw': '손 인사',
      'sun': '해',
      'bus': '버스',
      'flower': '꽃',
      'cloud': '구름',
      'leaf': '나뭇잎',
      'home': '숲집',
      'acorn': '도토리',
      'heart': '친구 마음',
    }[value] ??
    value;
