import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';

class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentPrimary.withValues(alpha: 0.25),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: Image.asset(
                'assets/images/logo-valina.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Text(
            'Selamat datang',
            style: AppTypography.largeTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Pelacak siklus & kesehatan reproduksimu — '
            'dirancang lembut, privat, dan mudah dipahami.',
            style: AppTypography.body.copyWith(
              color: AppColors.labelSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxxl),
          const _FeatureBullet(
            icon: CupertinoIcons.calendar,
            text: 'Prediksi haid & ovulasi yang akurat',
          ),
          const SizedBox(height: AppSpacing.lg),
          const _FeatureBullet(
            icon: CupertinoIcons.heart,
            text: 'Catat gejala, mood, dan kebiasaan harian',
          ),
          const SizedBox(height: AppSpacing.lg),
          const _FeatureBullet(
            icon: CupertinoIcons.lock_shield,
            text: 'Privasi penuh — semua data hanya di perangkatmu',
          ),
          const Spacer(),
          PrimaryButton(label: 'Mulai', onPressed: onNext),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  const _FeatureBullet({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.accentSoft.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: AppColors.accentPrimary, size: 18),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(text, style: AppTypography.callout)),
      ],
    );
  }
}
