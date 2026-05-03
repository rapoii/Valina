import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/cycle_calculator.dart';
import '../../../core/utils/date_x.dart';
import '../../../core/utils/insights_helper.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/models/day_log.dart';
import '../../logging/presentation/log_sheet.dart';
import 'widgets/cycle_month_view.dart';

/// Provider untuk pre-compute semua forecast dalam satu bulan.
/// Mengurangi rebuild dan menghindari multiple provider instances.
final _monthForecastsProvider =
    Provider.family<Map<DateTime, CycleForecast>, DateTime>((ref, month) {
      final cycles = ref.watch(cyclesProvider).value ?? const [];
      final profile = ref.watch(profileProvider).value;
      final lastOfMonth = DateTime(month.year, month.month + 1, 0);

      final forecasts = <DateTime, CycleForecast>{};
      for (var day = 1; day <= lastOfMonth.day; day++) {
        final date = DateTime(month.year, month.month, day).dateOnly;
        forecasts[date] = CycleCalculator.compute(
          cycles: cycles,
          fallbackCycleLength: profile?.avgCycleLength ?? 28,
          fallbackPeriodLength: profile?.avgPeriodLength ?? 5,
          today: date,
        );
      }
      return forecasts;
    });

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _displayedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );
  DateTime _selectedDate = DateTime.now().dateOnly;

  void _shiftMonth(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + delta,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cycles = ref.watch(cyclesProvider).value ?? const [];
    final logs = ref.watch(allLogsProvider).value ?? const [];
    // Pre-compute semua forecast untuk bulan ini dalam satu provider
    final forecasts = ref.watch(_monthForecastsProvider(_displayedMonth));

    return CupertinoPageScaffold(
      backgroundColor: AppColors.bgGrouped,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            backgroundColor: AppColors.glassNavBar,
            largeTitle: const Text('Kalender'),
            border: const Border(),
            stretch: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _MonthHeader(
                  month: _displayedMonth,
                  onPrev: () => _shiftMonth(-1),
                  onNext: () => _shiftMonth(1),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: AppShadow.subtle,
                  ),
                  child: CycleMonthView(
                    month: _displayedMonth,
                    selectedDate: _selectedDate,
                    onSelectDate: (DateTime d) =>
                        setState(() => _selectedDate = d),
                    cycles: cycles,
                    logs: logs,
                    forecasts: forecasts,
                  ),
                ),
                const CalendarLegend(),
                const SectionHeader(title: 'Detail tanggal'),
                _DayDetail(date: _selectedDate),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          Text(DateFormatter.monthYear(month), style: AppTypography.title2),
          const Spacer(),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(36, 36),
            onPressed: onPrev,
            child: const Icon(
              CupertinoIcons.chevron_back,
              size: 20,
              color: AppColors.accentPrimary,
            ),
          ),
          const SizedBox(width: 4),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(36, 36),
            onPressed: onNext,
            child: const Icon(
              CupertinoIcons.chevron_forward,
              size: 20,
              color: AppColors.accentPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayDetail extends ConsumerWidget {
  const _DayDetail({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(logForDateProvider(date)).value;
    final forecast = ref.watch(forecastForDateProvider(date));
    final phaseLabel = InsightsHelper.phaseColorLabel(forecast.phase);
    final phaseColor = AppColors.phaseColor(
      InsightsHelper.phaseColorEnum(forecast.phase),
    );
    final isReadOnly = ref.watch(isReadOnlyProvider);
    final canViewLogs = ref.watch(canViewLogsProvider);
    final canViewNotes = ref.watch(canViewNotesProvider);
    // Untuk male: hanya tampilkan log bila female membagikan log,
    // dan hanya hide notes kalau shareNotes=false.
    final showLogContent = !isReadOnly || canViewLogs;
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: phaseColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    phaseLabel,
                    style: AppTypography.caption1.copyWith(
                      color: phaseColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormatter.relativeDay(date),
                  style: AppTypography.footnote,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(DateFormatter.fullDay(date), style: AppTypography.title3),
            const SizedBox(height: AppSpacing.md),
            if (!showLogContent)
              Text(
                'Pasangan tidak membagikan log harian.',
                style: AppTypography.subheadline.copyWith(
                  color: AppColors.labelSecondary,
                ),
              )
            else if (log == null || !log.hasAnyData)
              _EmptyDayDetail(date: date)
            else
              _PopulatedDayDetail(log: log, hideNotes: !canViewNotes),
            // Tombol edit hanya muncul kalau user write-capable (female).
            if (!isReadOnly) ...[
              const SizedBox(height: AppSpacing.md),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => LogSheet.show(context, date),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.pencil,
                      color: AppColors.accentPrimary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      log == null || !log.hasAnyData
                          ? 'Tambah catatan'
                          : 'Edit catatan',
                      style: AppTypography.subheadlineEmphasized.copyWith(
                        color: AppColors.accentPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyDayDetail extends StatelessWidget {
  const _EmptyDayDetail({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Belum ada catatan untuk hari ini.',
      style: AppTypography.subheadline.copyWith(
        color: AppColors.labelSecondary,
      ),
    );
  }
}

class _PopulatedDayDetail extends StatelessWidget {
  const _PopulatedDayDetail({required this.log, this.hideNotes = false});

  final DayLog log;
  final bool hideNotes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (log.flowIntensity != null)
          _Row(
            label: 'Flow',
            value: log.flowIntensity!.label,
            color: AppColors.phaseMenstrual,
          ),
        if (log.moods.isNotEmpty)
          _Row(
            label: 'Mood',
            value: log.moods.map((m) => m.label).join(', '),
            color: AppColors.lavender,
          ),
        if (log.symptoms.isNotEmpty)
          _Row(
            label: 'Gejala',
            value: log.symptoms.map((s) => s.label).join(', '),
            color: AppColors.peach,
          ),
        if (log.discharge != null)
          _Row(
            label: 'Discharge',
            value: log.discharge!.label,
            color: AppColors.mint,
          ),
        if (!hideNotes && log.notes != null && log.notes!.trim().isNotEmpty)
          _Row(
            label: 'Catatan',
            value: log.notes!,
            color: AppColors.labelSecondary,
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTypography.subheadline.copyWith(
                color: AppColors.labelSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: AppTypography.subheadlineEmphasized),
          ),
        ],
      ),
    );
  }
}
