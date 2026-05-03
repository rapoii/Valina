import 'package:flutter/cupertino.dart';

import 'app_colors.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  /// CupertinoThemeData utama (light mode untuk MVP).
  static CupertinoThemeData light = CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.accentPrimary,
    primaryContrastingColor: CupertinoColors.white,
    scaffoldBackgroundColor: AppColors.bgGrouped,
    barBackgroundColor: AppColors.glassNavBar,
    textTheme: CupertinoTextThemeData(
      primaryColor: AppColors.accentPrimary,
      textStyle: AppTypography.body,
      actionTextStyle:
          AppTypography.body.copyWith(color: AppColors.accentPrimary),
      tabLabelTextStyle: AppTypography.caption2,
      navTitleTextStyle: AppTypography.headline,
      navLargeTitleTextStyle: AppTypography.largeTitle,
      navActionTextStyle:
          AppTypography.body.copyWith(color: AppColors.accentPrimary),
      pickerTextStyle: AppTypography.body,
      dateTimePickerTextStyle: AppTypography.body,
    ),
    applyThemeToAll: true,
  );
}

/// Konstanta radius & spacing yang konsisten dengan rasa Apple HIG.
abstract final class AppRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

/// Shadow yang lembut, bukan dramatis.
abstract final class AppShadow {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> raised = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 30,
      offset: Offset(0, 10),
    ),
  ];

  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
}
