import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import 'step_scaffold.dart';

class PeriodLengthStep extends StatelessWidget {
  const PeriodLengthStep({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  final int initial;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      emoji: '🩸',
      title: 'Berapa lama haidmu biasanya?',
      subtitle: 'Durasi rata-rata haid (3–7 hari adalah normal).',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.separator, width: 0.5),
        ),
        clipBehavior: Clip.hardEdge,
        height: 240,
        child: Stack(
          children: [
            CupertinoPicker(
              itemExtent: 44,
              scrollController:
                  FixedExtentScrollController(initialItem: initial - 2),
              onSelectedItemChanged: (i) => onChanged(2 + i),
              children: List.generate(
                10,
                (i) => Center(
                  child: Text(
                    '${2 + i} hari',
                    style: AppTypography.title2,
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: Center(
                child: Container(
                  height: 44,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      horizontal: BorderSide(
                        color: AppColors.accentSoft.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
