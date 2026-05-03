import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tipografi mengikuti SF Pro Display/Text di iOS dan Inter di Android.
///
/// SF Pro adalah font sistem default iOS (otomatis dipakai bila `fontFamily`
/// dibiarkan null pada `CupertinoApp`). Untuk Android, kita pakai Inter
/// sebagai pengganti yang sangat mirip — license-nya open source.
abstract final class AppTypography {
  /// Apakah aplikasi berjalan di iOS (gunakan SF Pro default sistem).
  static bool get _useSystemFont {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isMacOS;
  }

  /// Mengembalikan TextStyle dengan font yang sesuai platform.
  static TextStyle _font({
    required double fontSize,
    required FontWeight fontWeight,
    double? letterSpacing,
    double? height,
    Color color = AppColors.labelPrimary,
  }) {
    final base = TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
      color: color,
    );
    if (_useSystemFont) {
      // iOS akan otomatis pakai SF Pro karena fontFamily dibiarkan null.
      return base;
    }
    return GoogleFonts.inter(textStyle: base);
  }

  // ============================================================
  // Display & Title (mengikuti Apple typography scale)
  // ============================================================
  static TextStyle largeTitle = _font(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.37,
    height: 1.12,
  );

  static TextStyle title1 = _font(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.36,
    height: 1.14,
  );

  static TextStyle title2 = _font(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.35,
    height: 1.18,
  );

  static TextStyle title3 = _font(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.38,
    height: 1.20,
  );

  // ============================================================
  // Body & Label
  // ============================================================
  static TextStyle headline = _font(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.41,
    height: 1.29,
  );

  static TextStyle body = _font(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.41,
    height: 1.29,
  );

  static TextStyle callout = _font(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.32,
    height: 1.31,
  );

  static TextStyle subheadline = _font(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.24,
    height: 1.33,
  );

  static TextStyle footnote = _font(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.08,
    height: 1.38,
    color: AppColors.labelSecondary,
  );

  static TextStyle caption1 = _font(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.33,
    color: AppColors.labelSecondary,
  );

  static TextStyle caption2 = _font(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.07,
    height: 1.27,
    color: AppColors.labelTertiary,
  );

  // ============================================================
  // Variants emphasized
  // ============================================================
  static TextStyle bodyEmphasized = body.copyWith(fontWeight: FontWeight.w600);

  static TextStyle calloutEmphasized =
      callout.copyWith(fontWeight: FontWeight.w600);

  static TextStyle subheadlineEmphasized =
      subheadline.copyWith(fontWeight: FontWeight.w600);

  static TextStyle footnoteEmphasized =
      footnote.copyWith(fontWeight: FontWeight.w600);
}
