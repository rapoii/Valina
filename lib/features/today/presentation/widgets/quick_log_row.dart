import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/day_log.dart';

/// Baris kartu ringkas yang menampilkan apakah user sudah log hari ini.
///
/// Kalau `onTap` null → mode read-only (untuk male yang lihat log pasangan):
/// chevron forward & icon "+" disembunyikan, hanya summary yang ditampilkan.
class QuickLogRow extends StatelessWidget {
  const QuickLogRow({super.key, required this.todayLog, required this.onTap});

  final DayLog todayLog;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasData = todayLog.hasAnyData;
    final summary = _summarize(todayLog);
    final readOnly = onTap == null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: readOnly
          ? null
          : () {
              HapticFeedback.lightImpact();
              onTap!();
            },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadow.subtle,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accentSoft.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              alignment: Alignment.center,
              child: Icon(
                readOnly ? CupertinoIcons.heart_fill : CupertinoIcons.plus,
                color: AppColors.accentPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasData ? 'Catatan hari ini' : 'Catat sesuatu hari ini',
                    style: AppTypography.headline,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasData ? summary : 'Mood, gejala, flow, dan lainnya',
                    style: AppTypography.subheadline.copyWith(
                      color: AppColors.labelSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!readOnly)
              const Icon(
                CupertinoIcons.chevron_forward,
                color: AppColors.labelTertiary,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  String _summarize(DayLog log) {
    final parts = <String>[];
    if (log.flowIntensity != null) {
      parts.add('Flow ${log.flowIntensity!.label}');
    }
    if (log.moods.isNotEmpty) parts.add('${log.moods.length} mood');
    if (log.symptoms.isNotEmpty) parts.add('${log.symptoms.length} gejala');
    if (log.notes != null && log.notes!.trim().isNotEmpty) parts.add('catatan');
    return parts.isEmpty ? 'Tap untuk mulai mencatat' : parts.join(' • ');
  }
}
