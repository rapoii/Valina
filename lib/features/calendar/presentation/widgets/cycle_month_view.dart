import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/cycle_calculator.dart';
import '../../../../core/utils/date_x.dart';
import '../../../../data/models/cycle.dart';
import '../../../../data/models/day_log.dart';
import '../../../../data/models/enums.dart';

/// Tampilan satu bulan kalender dengan dot warna sesuai fase.
/// Optimized untuk 60fps dengan RepaintBoundary dan memoized forecasts.
class CycleMonthView extends StatelessWidget {
  const CycleMonthView({
    super.key,
    required this.month,
    required this.selectedDate,
    required this.onSelectDate,
    required this.cycles,
    required this.logs,
    required this.forecasts,
    this.showPhaseForecast = true,
  });

  final DateTime month;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;
  final List<Cycle> cycles;
  final List<DayLog> logs;
  final Map<DateTime, CycleForecast> forecasts;
  final bool showPhaseForecast;

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(month.year, month.month);
    final lastOfMonth = DateTime(month.year, month.month + 1, 0);
    // Senin = 1, Minggu = 7. Ikuti weekday lokal Indonesia (Senin pertama).
    final leadingEmpty = (firstOfMonth.weekday - 1) % 7;
    final totalDays = lastOfMonth.day;
    final cells = leadingEmpty + totalDays;
    final rows = (cells / 7).ceil();

    // Cache DateTime.now() sekali per build — hindari 35+ call di _DayCell.
    final today = DateTime.now().dateOnly;

    // Precompute Sets untuk O(1) lookup — hindari O(n²) linear scan per cell.
    final periodDates = _computePeriodDates(cycles);
    final activityDates = _computeActivityDates(logs);

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, AppSpacing.md, 20, AppSpacing.sm),
            child: Row(
              children: [
                _DayLabel('Sen'),
                _DayLabel('Sel'),
                _DayLabel('Rab'),
                _DayLabel('Kam'),
                _DayLabel('Jum'),
                _DayLabel('Sab'),
                _DayLabel('Min'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: List.generate(rows, (r) {
                return Row(
                  children: List.generate(7, (c) {
                    final cellIndex = r * 7 + c;
                    final dayNum = cellIndex - leadingEmpty + 1;
                    if (dayNum < 1 || dayNum > totalDays) {
                      return const Expanded(child: SizedBox(height: 56));
                    }
                    final date = DateTime(month.year, month.month, dayNum);
                    final dateOnly = date.dateOnly;
                    return Expanded(
                      child: RepaintBoundary(
                        child: _DayCell(
                          date: date,
                          today: today,
                          selected: dateOnly.isSameDate(selectedDate),
                          isInActualPeriod: periodDates.contains(dateOnly),
                          hasSexualActivity: activityDates.contains(dateOnly),
                          forecast:
                              forecasts[dateOnly] ?? _defaultForecast(dateOnly),
                          showPhaseForecast: showPhaseForecast,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onSelectDate(date);
                          },
                        ),
                      ),
                    );
                  }),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  CycleForecast _defaultForecast(DateTime date) => CycleForecast(
    referenceDate: date,
    cycleStartDate: date.subtract(const Duration(days: 1)),
    cycleDay: 1,
    cycleLength: 28,
    periodLength: 5,
    phase: CyclePhase.follicular,
    nextPeriodStart: date.add(const Duration(days: 27)),
    ovulationDate: date.add(const Duration(days: 13)),
    fertileWindowStart: date.add(const Duration(days: 8)),
    fertileWindowEnd: date.add(const Duration(days: 14)),
    regularityScore: 0.5,
    usingHistoricalAverage: false,
    pregnancyChance: 0.01,
  );

  /// Precompute `Set<DateTime>` untuk O(1) lookup — hindari O(n²) scan per cell.
  static Set<DateTime> _computePeriodDates(List<Cycle> cycles) {
    final result = <DateTime>{};
    for (final c in cycles) {
      final start = c.startDate.dateOnly;
      final end = (c.endDate ?? c.startDate).dateOnly;
      var current = start;
      while (!current.isAfter(end)) {
        result.add(current);
        current = current.add(const Duration(days: 1));
      }
    }
    return result;
  }

  static Set<DateTime> _computeActivityDates(List<DayLog> logs) {
    final result = <DateTime>{};
    for (final l in logs) {
      if (l.sexualActivities.any((s) => s != SexualActivity.none)) {
        result.add(l.date.dateOnly);
      }
    }
    return result;
  }
}

class _DayLabel extends StatelessWidget {
  const _DayLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: AppTypography.caption2.copyWith(
            color: AppColors.labelSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.today,
    required this.selected,
    required this.isInActualPeriod,
    required this.hasSexualActivity,
    required this.forecast,
    required this.showPhaseForecast,
    required this.onTap,
  });

  final DateTime date;
  final DateTime today;
  final bool selected;
  final bool isInActualPeriod;
  final bool hasSexualActivity;
  final CycleForecast forecast;
  final bool showPhaseForecast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isToday = date.isSameDate(today);
    final isFuture = date.isAfter(today);
    final phase = forecast.phase;

    final isPredictedPeriod =
        isFuture && phase == CyclePhase.menstrual && !isInActualPeriod;
    final isOvulation = forecast.isPeakOvulation && !isInActualPeriod;
    final isFertileOnly =
        forecast.isInFertileWindow && !isInActualPeriod && !isOvulation;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (showPhaseForecast) ...[
              if (isFertileOnly && !isPredictedPeriod)
                _buildFertileBackground(),
              if (isOvulation && !isPredictedPeriod)
                _buildOvulationBackground(),
              if (isInActualPeriod)
                _buildPeriodBackground()
              else if (isPredictedPeriod)
                _buildPredictedBackground(),
            ],
            if (selected) _buildSelectedBorder(),
            _buildContent(isToday, isInActualPeriod),
          ],
        ),
      ),
    );
  }

  Widget _buildFertileBackground() => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: AppColors.lavender.withValues(alpha: 0.18),
      shape: BoxShape.circle,
    ),
  );

  Widget _buildOvulationBackground() => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: AppColors.lavender.withValues(alpha: 0.55),
      shape: BoxShape.circle,
    ),
  );

  Widget _buildPeriodBackground() => Container(
    width: 40,
    height: 40,
    decoration: const BoxDecoration(
      color: AppColors.phaseMenstrual,
      shape: BoxShape.circle,
    ),
  );

  Widget _buildPredictedBackground() => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: AppColors.phaseMenstrual.withValues(alpha: 0.6),
        width: 1.4,
      ),
    ),
  );

  Widget _buildSelectedBorder() => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.accentPrimary, width: 2),
    ),
  );

  Widget _buildContent(bool isToday, bool isInActualPeriod) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${date.day}',
          style: AppTypography.subheadline.copyWith(
            color: showPhaseForecast && isInActualPeriod
                ? CupertinoColors.white
                : isToday
                ? AppColors.accentPrimary
                : AppColors.labelPrimary,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        _LoveIndicator(visible: hasSexualActivity),
      ],
    );
  }
}

class _LoveIndicator extends StatelessWidget {
  const _LoveIndicator({required this.visible});
  final bool visible;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 8,
      child: visible
          ? const Text('❤', style: TextStyle(fontSize: 7, height: 1))
          : const SizedBox.shrink(),
    );
  }
}

/// Penjelasan warna kalender (legenda kecil di bawah).
class CalendarLegend extends StatelessWidget {
  const CalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Wrap(
        spacing: 14,
        runSpacing: 8,
        children: [
          const _LegendItem(color: AppColors.phaseMenstrual, label: 'Haid'),
          _LegendItem(
            color: AppColors.phaseMenstrual.withValues(alpha: 0.6),
            label: 'Prediksi',
            outlined: true,
          ),
          _LegendItem(
            color: AppColors.lavender.withValues(alpha: 0.55),
            label: 'Ovulasi',
          ),
          _LegendItem(
            color: AppColors.lavender.withValues(alpha: 0.18),
            label: 'Masa subur',
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    this.outlined = false,
  });

  final Color color;
  final String label;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: outlined ? null : color,
            shape: BoxShape.circle,
            border: outlined ? Border.all(color: color, width: 1.4) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.caption1.copyWith(
            color: AppColors.labelSecondary,
          ),
        ),
      ],
    );
  }
}
