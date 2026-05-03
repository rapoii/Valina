import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

enum AppButtonStyle { filled, tinted, plain }

enum AppButtonSize { regular, large }

/// Tombol utama bergaya iOS dengan dukungan haptic feedback.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.style = AppButtonStyle.filled,
    this.size = AppButtonSize.large,
    this.icon,
    this.expanded = true,
    this.color,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final AppButtonSize size;
  final IconData? icon;
  final bool expanded;
  final Color? color;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final isLarge = size == AppButtonSize.large;
    final accent = color ?? AppColors.accentPrimary;

    final (Color bg, Color fg) = switch (style) {
      AppButtonStyle.filled => (accent, CupertinoColors.white),
      AppButtonStyle.tinted => (accent.withValues(alpha: 0.16), accent),
      AppButtonStyle.plain => (const Color(0x00000000), accent),
    };

    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (loading)
          CupertinoActivityIndicator(color: fg, radius: 9)
        else ...[
          if (icon != null) ...[
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(label, style: AppTypography.headline.copyWith(color: fg)),
        ],
      ],
    );

    return CupertinoButton(
      padding: EdgeInsets.symmetric(
        vertical: isLarge ? 16 : 12,
        horizontal: isLarge ? 24 : 16,
      ),
      borderRadius: BorderRadius.circular(AppRadius.md),
      color: style == AppButtonStyle.plain ? null : bg,
      onPressed: (onPressed == null || loading)
          ? null
          : () {
              HapticFeedback.lightImpact();
              onPressed!();
            },
      minimumSize: Size(0, isLarge ? 52 : 44),
      child: child,
    );
  }
}
