import 'package:flutter/material.dart';

import 'coloring_animal_templates.dart';
import 'coloring_object_templates.dart';
import 'coloring_vehicle_templates.dart';

export 'coloring_animal_templates.dart';
export 'coloring_object_templates.dart';
export 'coloring_vehicle_templates.dart';

/// Categories for coloring templates.
enum ColoringCategory {
  all('전체', '🌟'),
  animal('동물', '🐾'),
  vehicle('탈것', '🚗'),
  object('사물', '🎈');

  const ColoringCategory(this.label, this.emoji);
  final String label;
  final String emoji;
}

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
    this.category = ColoringCategory.animal,
    required this.createSegments,
  });

  final String id;
  final String title;
  final String emoji;
  final ColoringCategory category;
  final List<ColoringSegment> Function() createSegments;
}

/// Rich catalog of 64 coloring templates: 30 animals, 14 vehicles, and 20 objects.
class ColoringCatalog {
  /// 30 cute animal & creature templates.
  static List<ColoringTemplate> get animals => ColoringAnimalCatalog.all;

  /// 14 vehicle templates (cars, trains, airplanes, rockets, etc.).
  static List<ColoringTemplate> get vehicles => ColoringVehicleCatalog.all;

  /// 20 object, food, nature, and toy templates.
  static List<ColoringTemplate> get objects => ColoringObjectCatalog.all;

  /// Complete list of all 64 coloring templates.
  static List<ColoringTemplate> get all => [
        ...animals,
        ...vehicles,
        ...objects,
      ];

  /// Filter templates by category.
  static List<ColoringTemplate> byCategory(ColoringCategory category) {
    switch (category) {
      case ColoringCategory.all:
        return all;
      case ColoringCategory.animal:
        return animals;
      case ColoringCategory.vehicle:
        return vehicles;
      case ColoringCategory.object:
        return objects;
    }
  }
}
