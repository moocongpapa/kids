import 'package:flutter/material.dart';

enum ForestPlace { house, garden, music, art }

/// One transparent illustration atlas; each quadrant is drawn at its own size.
class ForestPlaceArt extends StatelessWidget {
  const ForestPlaceArt(this.place, {required this.size, super.key});
  final ForestPlace place;
  final double size;
  static const asset = 'assets/images/forest_places_v2.png';

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: size * 2,
          maxWidth: size * 2,
          minHeight: size * 2,
          maxHeight: size * 2,
          child: FractionalTranslation(
            translation: Offset(
              -(place.index % 2) / 2,
              -(place.index ~/ 2) / 2,
            ),
            child: Image.asset(
              asset,
              width: size * 2,
              height: size * 2,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ),
    ),
  );
}
