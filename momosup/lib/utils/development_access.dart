import 'package:flutter/foundation.dart';

/// Debug/profile builds allow local entry. Release builds need an explicit flag.
const developmentAccessEnabled = bool.fromEnvironment(
  'MOMOSUP_DEV_ACCESS',
  defaultValue: !kReleaseMode,
);
