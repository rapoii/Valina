import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';

/// Bar chart sederhana untuk panjang siklus 6 terakhir (dalam hari).
class CycleLengthChart extends StatelessWidget {
  const CycleLengthChart({super.key, required this.lengths});

  /// Diurutkan dari yang terlama (kiri) ke yang terbaru (kanan).
  final List<int> lengths;

  @override
  Widget build(BuildContext context) {
    if (lengths.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        alignment: Alignment.center,
        child: Text(
          'Belum cukup data — catat 2 siklus untuk melihat grafik.',
          style: AppTypography.subheadline.copyWith(
            color: AppColors.labelSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    // Bar chart selalu mulai dari 0 (hindari overflow rendering saat minY > 0).
    // maxY menyesuaikan data tertinggi + margin, tanpa batas atas yang bisa
    // bikin bar melampaui container kalau user punya siklus panjang.
    final maxValue = lengths.reduce((a, b) => a > b ? a : b);
    final maxY = ((maxValue + 5) / 5).ceil() * 5.0;
    final interval = (maxY / 6).ceilToDouble().clamp(5.0, double.infinity);

    return SizedBox(
      height: 180,
      // ClipRect jaga-jaga supaya bar tidak pernah overflow keluar container.
      child: RepaintBoundary(
        child: ClipRect(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              minY: 0,
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: interval,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: AppColors.separator, strokeWidth: 0.5),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: interval,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: AppTypography.caption2,
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'S${lengths.length - value.toInt()}',
                        style: AppTypography.caption2,
                      ),
                    ),
                  ),
                ),
                rightTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                for (var i = 0; i < lengths.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: lengths[i].toDouble(),
                        width: 22,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppRadius.xs),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppColors.accentPrimary.withValues(alpha: 0.7),
                            AppColors.accentPrimary,
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
