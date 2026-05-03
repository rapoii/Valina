import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import 'step_scaffold.dart';

class CycleLengthStep extends StatelessWidget {
  const CycleLengthStep({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  final int initial;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      emoji: '🔄',
      title: 'Berapa panjang siklusmu?',
      subtitle:
          'Hari pertama haid hingga hari pertama haid berikutnya. Rata-rata 28 hari.',
      child: _NumberPicker(
        min: 18,
        max: 45,
        initial: initial,
        unit: 'hari',
        onChanged: onChanged,
      ),
    );
  }
}

class _NumberPicker extends StatelessWidget {
  const _NumberPicker({
    required this.min,
    required this.max,
    required this.initial,
    required this.unit,
    required this.onChanged,
  });

  final int min;
  final int max;
  final int initial;
  final String unit;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                FixedExtentScrollController(initialItem: initial - min),
            onSelectedItemChanged: (i) => onChanged(min + i),
            children: List.generate(
              max - min + 1,
              (i) => Center(
                child: Text(
                  '${min + i} $unit',
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
    );
  }
}
