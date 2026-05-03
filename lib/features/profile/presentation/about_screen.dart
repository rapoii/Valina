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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.accentSoft,
                      AppColors.accentPrimary.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentPrimary.withValues(alpha: 0.25),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🌸', style: TextStyle(fontSize: 48)),
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.peach.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    CupertinoIcons.exclamationmark_triangle,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Disclaimer kesehatan',
                          style: AppTypography.subheadlineEmphasized,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Aplikasi ini bukan alat diagnosis medis dan tidak dapat '
                          'diandalkan sebagai metode kontrasepsi. Konsultasikan '
                          'masalah kesehatan kamu kepada tenaga medis profesional.',
                          style: AppTypography.footnote.copyWith(
                            color: AppColors.labelPrimary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text('Kredit', style: AppTypography.headline),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Dibuat dengan ❤ menggunakan Flutter, Riverpod, dan Firebase.\n'
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
