import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/cycle_calculator.dart';
import '../../../core/utils/date_x.dart';
import '../../../core/utils/insights_helper.dart';
import '../../../core/utils/performance_monitor.dart';
import '../../../core/widgets/section_header.dart';
import '../../logging/presentation/log_sheet.dart';
import 'widgets/cycle_status_card.dart';
import 'widgets/insight_card.dart';
import 'widgets/quick_log_row.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PerformanceMonitor.trackBuildTime('TodayScreen', () {
      return _buildContent(context, ref);
    });
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final ownProfile = ref.watch(ownProfileProvider).value;
    // Untuk male, `profileProvider` returnable profile pasangan (cewek).
    // Untuk female, sama dengan ownProfile.
    final effectiveProfile = ref.watch(profileProvider).value;
    final forecast = ref.watch(todayForecastProvider);
    final todayLog = ref.watch(logForDateProvider(DateTime.now())).value;
    final insight = InsightsHelper.forForecast(forecast);
    final isReadOnly = ref.watch(isReadOnlyProvider);
    final canViewLogs = ref.watch(canViewLogsProvider);

    // Header: tampilkan nama OWN user (bukan partner), supaya male tetap
    // ngerasa ini app dia.
    final headerName = ownProfile == null
        ? 'Hari Ini'
        : 'Halo, ${ownProfile.name.split(' ').first}';

    return CupertinoPageScaffold(
      backgroundColor: AppColors.bgGrouped,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            backgroundColor: AppColors.glassNavBar,
            border: const Border(),
            largeTitle: Text(headerName),
            stretch: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, AppSpacing.lg),
                  child: Text(
                    DateFormatter.fullDay(DateTime.now()),
                    style: AppTypography.subheadline.copyWith(
                      color: AppColors.labelSecondary,
                    ),
                  ),
                ),
                if (isReadOnly)
                  _PartnerBanner(partnerName: effectiveProfile?.name),
                RepaintBoundary(child: CycleStatusCard(forecast: forecast)),
                const SizedBox(height: AppSpacing.xl),
                RepaintBoundary(child: InsightCard(insight: insight)),
                // Quick log hanya untuk female. Male: read-only, dan kalau
                // canViewLogs true bisa lihat log harian sebagai info.
                if (!isReadOnly) ...[
                  const SectionHeader(title: 'Catat hari ini'),
                  if (todayLog != null)
                    QuickLogRow(
                      todayLog: todayLog,
                      onTap: () => LogSheet.show(context, DateTime.now()),
                    ),
                ] else if (canViewLogs && todayLog != null) ...[
                  const SectionHeader(title: 'Catatan pasangan hari ini'),
                  QuickLogRow(todayLog: todayLog, onTap: null),
                ],
                const SizedBox(height: AppSpacing.xxl),
                RepaintBoundary(child: _ForecastTimeline(forecast: forecast)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner kecil di Today screen untuk male — kasih konteks "kamu lagi mantau
/// kalender [nama cewek]".
class _PartnerBanner extends StatelessWidget {
  const _PartnerBanner({required this.partnerName});

  final String? partnerName;

  @override
  Widget build(BuildContext context) {
    final name = partnerName ?? 'pasangan';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.lavender.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.lavender.withValues(alpha: 0.5),
            width: 0.6,
          ),
        ),
        child: Row(
          children: [
            const Icon(CupertinoIcons.eye, size: 18, color: AppColors.lavender),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Memantau kalender $name',
                style: AppTypography.subheadline.copyWith(
                  color: AppColors.labelPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForecastTimeline extends StatelessWidget {
  const _ForecastTimeline({required this.forecast});

  final CycleForecast forecast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadow.subtle,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prediksi minggu ini', style: AppTypography.headline),
            const SizedBox(height: AppSpacing.md),
            _TimelineRow(
              icon: CupertinoIcons.drop_fill,
              color: AppColors.phaseMenstrual,
              label: 'Haid berikutnya',
              date: forecast.nextPeriodStart,
            ),
            const SizedBox(height: AppSpacing.md),
            _TimelineRow(
              icon: CupertinoIcons.sparkles,
              color: AppColors.lavender,
              label: 'Ovulasi',
              date: forecast.ovulationDate,
            ),
            const SizedBox(height: AppSpacing.md),
            _TimelineRow(
              icon: CupertinoIcons.heart_fill,
              color: AppColors.peach,
              label: 'Fertile window',
              date: forecast.fertileWindowStart,
              endDate: forecast.fertileWindowEnd,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.date,
    this.endDate,
  });

  final IconData icon;
  final Color color;
  final String label;
  final DateTime date;
  final DateTime? endDate;

  @override
  Widget build(BuildContext context) {
    final dateLabel = endDate == null
        ? '${DateFormatter.dayMonth(date)} • ${DateFormatter.relativeDay(date)}'
        : '${DateFormatter.dayMonth(date)} – ${DateFormatter.dayMonth(endDate!)}';
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.subheadlineEmphasized),
              const SizedBox(height: 2),
              Text(
                dateLabel,
                style: AppTypography.footnote.copyWith(
                  color: AppColors.labelSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
