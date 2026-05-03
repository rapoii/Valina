import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/cycle_calculator.dart';
import '../../../../core/utils/date_x.dart';
import '../../../../core/utils/insights_helper.dart';
import '../../../../core/widgets/cycle_ring.dart';

class CycleStatusCard extends StatelessWidget {
  const CycleStatusCard({super.key, required this.forecast});

  final CycleForecast forecast;

  @override
  Widget build(BuildContext context) {
    final phaseColor = AppColors.phaseColor(
      InsightsHelper.phaseColorEnum(forecast.phase),
    );
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            phaseColor.withValues(alpha: 0.10),
            phaseColor.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: phaseColor.withValues(alpha: 0.18),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Center(
            child: CycleRing(
              progress: forecast.cycleProgress,
              cycleDay: forecast.cycleDay,
              cycleLength: forecast.cycleLength,
              phaseColor: phaseColor,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: phaseColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              InsightsHelper.phaseColorLabel(forecast.phase),
              style: AppTypography.footnoteEmphasized.copyWith(
                color: phaseColor,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            InsightsHelper.headlineForForecast(forecast),
            style: AppTypography.title2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Prediksi haid: ${DateFormatter.dayMonth(forecast.nextPeriodStart)} • '
            'Ovulasi: ${DateFormatter.dayMonth(forecast.ovulationDate)}',
            style: AppTypography.footnote,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
