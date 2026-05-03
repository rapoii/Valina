import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/enums.dart';
import 'step_scaffold.dart';

/// Step pilih jenis kelamin. Menentukan alur selanjutnya:
/// - Perempuan → onboarding normal (DOB, siklus, dsb).
/// - Laki-laki → input kode pasangan (hanya view data pasangannya).
class GenderStep extends StatelessWidget {
  const GenderStep({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  final UserGender? initial;
  final ValueChanged<UserGender> onChanged;

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      emoji: '👋',
      title: 'Siapa kamu?',
      subtitle:
          'Pilih yang sesuai. Kalau kamu pasangan, kamu akan bisa memantau '
          'kalender siklus pasanganmu setelah memasukkan kode.',
      child: Column(
        children: [
          _OptionTile(
            emoji: '🌸',
            label: 'Perempuan',
            caption: 'Saya yang akan mencatat siklus',
            selected: initial == UserGender.female,
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(UserGender.female);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _OptionTile(
            emoji: '💙',
            label: 'Laki-laki',
            caption: 'Saya ingin memantau siklus pasangan',
            selected: initial == UserGender.male,
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(UserGender.male);
            },
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.emoji,
    required this.label,
    required this.caption,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final String caption;
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
            color: selected ? AppColors.accentPrimary : AppColors.separator,
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.headline.copyWith(
                      color: selected
                          ? AppColors.accentPressed
                          : AppColors.labelPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    caption,
                    style: AppTypography.footnote.copyWith(
                      color: AppColors.labelSecondary,
                    ),
                  ),
                ],
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
