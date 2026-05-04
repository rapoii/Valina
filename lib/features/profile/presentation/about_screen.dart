import 'package:flutter/cupertino.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.bgGrouped,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.glassNavBar,
        border: const Border(
          bottom: BorderSide(color: AppColors.separator, width: 0.3),
        ),
        middle: const Text('Tentang'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 60),
          children: [
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentPrimary.withValues(alpha: 0.25),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    'assets/images/logo-valina.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(child: Text('Valina', style: AppTypography.title1)),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Versi 1.0.0',
                style: AppTypography.subheadline.copyWith(
                  color: AppColors.labelSecondary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            Text('Tentang aplikasi', style: AppTypography.headline),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Valina adalah aplikasi pelacak siklus menstruasi & kesehatan '
              'reproduksi yang dirancang dengan estetika Apple HIG. Datamu '
              'tersinkron aman di cloud dan terikat ke akunmu — privasi tetap '
              'terjaga.',
              style: AppTypography.body.copyWith(
                color: AppColors.labelSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text('Kredit', style: AppTypography.headline),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Dibuat oleh Rafi Permana dengan ❤ menggunakan Flutter, Riverpod, dan Firebase.\n'
              'Tipografi: SF Pro (iOS) / Inter (Android).\n'
              'Ikon: SF Symbols / CupertinoIcons.',
              style: AppTypography.subheadline.copyWith(
                color: AppColors.labelSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
