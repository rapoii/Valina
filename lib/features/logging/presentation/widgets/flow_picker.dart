import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/enums.dart';

/// Pilih intensitas flow + tombol "tidak ada".
class FlowPicker extends StatelessWidget {
  const FlowPicker({super.key, required this.value, required this.onChanged});

  final FlowIntensity? value;
  final ValueChanged<FlowIntensity?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (final f in FlowIntensity.values) ...[
            Expanded(
              child: _FlowItem(
                label: f.label,
                dotCount: _dotsFor(f),
                selected: value == f,
                onTap: () => onChanged(value == f ? null : f),
              ),
            ),
            if (f != FlowIntensity.heavy) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  int _dotsFor(FlowIntensity f) => switch (f) {
        FlowIntensity.spotting => 1,
        FlowIntensity.light => 2,
        FlowIntensity.medium => 3,
        FlowIntensity.heavy => 4,
      };
}

class _FlowItem extends StatelessWidget {
  const _FlowItem({
    required this.label,
    required this.dotCount,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int dotCount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentPrimary.withValues(alpha: 0.10)
              : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color:
                selected ? AppColors.accentPrimary : AppColors.separator,
            width: selected ? 1.2 : 0.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i < dotCount
                          ? AppColors.accentPrimary
                          : AppColors.fillSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.caption1.copyWith(
                color: selected
                    ? AppColors.accentPressed
                    : AppColors.labelPrimary,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
