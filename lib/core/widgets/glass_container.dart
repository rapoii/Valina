import 'dart:ui';

import 'package:flutter/cupertino.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Container dengan efek frosted glass (translucency + backdrop blur).
///
/// Komponen ini meniru tampilan Apple Material di iOS — sangat cocok untuk
/// modal sheet, hero card, atau navigasi mengambang.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.blurSigma = 14,
    this.tint,
    this.border = true,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blurSigma;
  final Color? tint;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.lg);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tint ?? AppColors.glassCard,
            borderRadius: radius,
            border: border
                ? Border.all(color: AppColors.glassBorder, width: 0.5)
                : null,
          ),
          child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ),
      ),
    );
  }
}
