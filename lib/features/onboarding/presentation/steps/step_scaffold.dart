import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';

/// Layout standar untuk satu pertanyaan onboarding.
class StepScaffold extends StatelessWidget {
  const StepScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.emoji,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (emoji != null) ...[
            Text(emoji!, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(title, style: AppTypography.title1),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: AppTypography.callout.copyWith(
              color: AppColors.labelSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          child,
        ],
      ),
    );
  }
}
