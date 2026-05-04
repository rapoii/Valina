import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';

/// Grid chip 4-kolom dengan emoji + label.
class ChipGrid<T> extends StatelessWidget {
  const ChipGrid({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.emojiOf,
    required this.onToggle,
  });

  final List<T> options;
  final Set<T> selected;
  final String Function(T) labelOf;
  final String Function(T) emojiOf;
  final ValueChanged<T> onToggle;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: options.length,
      itemBuilder: (context, i) {
        final opt = options[i];
        final isSelected = selected.contains(opt);
        return _ChipItem(
          emoji: emojiOf(opt),
          label: labelOf(opt),
          selected: isSelected,
          onTap: () => onToggle(opt),
        );
      },
    );
  }
}

class _ChipItem extends StatelessWidget {
  const _ChipItem({
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
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentSoft.withValues(alpha: 0.55)
              : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.accentPrimary : AppColors.separator,
            width: selected ? 1.2 : 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption2.copyWith(
                color: selected
                    ? AppColors.accentPressed
                    : AppColors.labelPrimary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
