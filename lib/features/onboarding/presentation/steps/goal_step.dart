import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/enums.dart';
import 'step_scaffold.dart';

class GoalStep extends StatelessWidget {
  const GoalStep({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  final CycleGoal initial;
  final ValueChanged<CycleGoal> onChanged;

  static const _options = [
    (CycleGoal.trackCycle, '📅', 'Pantau siklus haid'),
    (CycleGoal.tryConceive, '🌷', 'Sedang berusaha hamil'),
    (CycleGoal.generalHealth, '💪', 'Pantau kesehatan umum'),
  ];

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      emoji: '🎯',
      title: 'Apa tujuanmu?',
      subtitle: 'Kami akan menyesuaikan insight & tips untukmu.',
      child: Column(
        children: [
          for (final (goal, emoji, label) in _options) ...[
            _OptionTile(
              emoji: emoji,
              label: label,
              selected: initial == goal,
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(goal);
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentSoft.withValues(alpha: 0.5)
              : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color:
                selected ? AppColors.accentPrimary : AppColors.separator,
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(
                label,
                style: AppTypography.headline.copyWith(
                  color: selected
                      ? AppColors.accentPressed
                      : AppColors.labelPrimary,
                ),
              ),
            ),
            if (selected)
              const Icon(
                CupertinoIcons.checkmark_alt_circle_fill,
                color: AppColors.accentPrimary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
