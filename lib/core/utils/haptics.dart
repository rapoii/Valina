import 'package:flutter/services.dart';

/// Wrapper haptic feedback yang sering dipakai untuk konsistensi feel iOS.
abstract final class Haptics {
  static Future<void> selection() => HapticFeedback.selectionClick();
  static Future<void> light() => HapticFeedback.lightImpact();
  static Future<void> medium() => HapticFeedback.mediumImpact();
  static Future<void> heavy() => HapticFeedback.heavyImpact();
  static Future<void> success() => HapticFeedback.lightImpact();
}
