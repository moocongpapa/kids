import 'package:flutter/material.dart';

class AvatarImage extends StatelessWidget {
  const AvatarImage({
    required this.avatar,
    this.size = 104,
    this.semanticLabel,
    super.key,
  });

  final String avatar;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel ?? '$avatar 캐릭터',
    child: Image.asset(
      'assets/images/$avatar.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    ),
  );
}
