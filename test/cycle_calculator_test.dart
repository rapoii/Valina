import 'package:flo_track/core/utils/cycle_calculator.dart';
import 'package:flo_track/data/models/cycle.dart';
import 'package:flo_track/data/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CycleCalculator.compute', () {
    test('belum ada data — fase menstrual hari pertama, pakai fallback',
        () {
      final today = DateTime(2026, 5, 15);
      final forecast = CycleCalculator.compute(
        cycles: const [],
        fallbackCycleLength: 28,
        fallbackPeriodLength: 5,
        today: today,
      );

      expect(forecast.cycleLength, 28);
      expect(forecast.periodLength, 5);
      expect(forecast.usingHistoricalAverage, isFalse);
      expect(forecast.phase, CyclePhase.menstrual);
      expect(forecast.cycleDay, 2);
    });

    test('1 siklus — pakai fallback length tapi posisi siklus dari startDate',
        () {
      final today = DateTime(2026, 5, 15);
      final start = DateTime(2026, 5);
      final cycles = [Cycle(id: 'a', startDate: start, endDate: DateTime(2026, 5, 5))];

      final forecast = CycleCalculator.compute(
        cycles: cycles,
        fallbackCycleLength: 28,
        fallbackPeriodLength: 5,
        today: today,
      );

      expect(forecast.cycleStartDate, start);
      expect(forecast.cycleDay, 15);
      // Hari ke-15 di siklus 28 hari, ovulasi hari ke-15 → fase ovulasi.
      expect(forecast.phase, CyclePhase.ovulation);
      expect(forecast.usingHistoricalAverage, isFalse);
    });

    test('3 siklus reguler 28 hari — pakai rata-rata historis', () {
      final cycles = [
        Cycle(id: '1', startDate: DateTime(2026), endDate: DateTime(2026, 1, 5)),
        Cycle(id: '2', startDate: DateTime(2026, 1, 29), endDate: DateTime(2026, 2, 2)),
        Cycle(id: '3', startDate: DateTime(2026, 2, 26), endDate: DateTime(2026, 3, 2)),
        Cycle(id: '4', startDate: DateTime(2026, 3, 26), endDate: DateTime(2026, 3, 30)),
      ];
      final today = DateTime(2026, 4, 5);

      final forecast = CycleCalculator.compute(
        cycles: cycles,
        fallbackCycleLength: 30,
        fallbackPeriodLength: 7,
        today: today,
      );

      expect(forecast.cycleLength, 28);
      expect(forecast.periodLength, 5);
      expect(forecast.usingHistoricalAverage, isTrue);
      expect(forecast.regularityScore, 1.0);
    });

    test('siklus tidak teratur menghasilkan regularityScore < 1', () {
      final cycles = [
        Cycle(id: '1', startDate: DateTime(2026)),
        Cycle(id: '2', startDate: DateTime(2026, 1, 25)),  // 24 hari
        Cycle(id: '3', startDate: DateTime(2026, 2, 28)),  // 34 hari
        Cycle(id: '4', startDate: DateTime(2026, 3, 22)),  // 22 hari
      ];

      final forecast = CycleCalculator.compute(
        cycles: cycles,
        fallbackCycleLength: 28,
        fallbackPeriodLength: 5,
        today: DateTime(2026, 4),
      );

      expect(forecast.usingHistoricalAverage, isTrue);
      expect(forecast.regularityScore, lessThan(1.0));
    });

    test('fertile window dihitung relatif terhadap ovulasi', () {
      final cycles = [
        Cycle(id: '1', startDate: DateTime(2026, 5), endDate: DateTime(2026, 5, 5)),
      ];

      final forecast = CycleCalculator.compute(
        cycles: cycles,
        fallbackCycleLength: 28,
        fallbackPeriodLength: 5,
        today: DateTime(2026, 5, 10),
      );

      // Next period = 1 May + 28 = 29 May
      expect(forecast.nextPeriodStart, DateTime(2026, 5, 29));
      // Ovulation = 29 May - 14 = 15 May
      expect(forecast.ovulationDate, DateTime(2026, 5, 15));
      // Fertile window = [10 May, 16 May]
      expect(forecast.fertileWindowStart, DateTime(2026, 5, 10));
      expect(forecast.fertileWindowEnd, DateTime(2026, 5, 16));
      expect(forecast.isInFertileWindow, isTrue);
    });

    test('siklus baru otomatis disimulasi bila gap > cycleLength', () {
      // Last recorded cycle 60 hari lalu, cycleLength 28.
      // Calculator harus geser cycleStartDate ke siklus berikutnya.
      final cycles = [
        Cycle(id: '1', startDate: DateTime(2026), endDate: DateTime(2026, 1, 5)),
        Cycle(id: '2', startDate: DateTime(2026, 1, 29), endDate: DateTime(2026, 2, 2)),
        Cycle(id: '3', startDate: DateTime(2026, 2, 26), endDate: DateTime(2026, 3, 2)),
      ];

      final today = DateTime(2026, 4); // 34 hari setelah 26 Feb
      final forecast = CycleCalculator.compute(
        cycles: cycles,
        fallbackCycleLength: 28,
        fallbackPeriodLength: 5,
        today: today,
      );

      // CycleStart harus geser ke 26 Feb + 28 = 26 Mar
      expect(forecast.cycleStartDate, DateTime(2026, 3, 26));
      expect(forecast.cycleDay, 7);
    });

    test('hari ke-3 dari haid tergolong fase menstrual', () {
      final cycles = [
        Cycle(id: '1', startDate: DateTime(2026, 5), endDate: DateTime(2026, 5, 5)),
      ];

      final forecast = CycleCalculator.compute(
        cycles: cycles,
        fallbackCycleLength: 28,
        fallbackPeriodLength: 5,
        today: DateTime(2026, 5, 3),
      );

      expect(forecast.phase, CyclePhase.menstrual);
      expect(forecast.cycleDay, 3);
      expect(forecast.isInPeriod, isTrue);
    });

    test('hari ke-22 dari siklus 28 hari tergolong fase luteal', () {
      final cycles = [
        Cycle(id: '1', startDate: DateTime(2026, 5), endDate: DateTime(2026, 5, 5)),
      ];

      final forecast = CycleCalculator.compute(
        cycles: cycles,
        fallbackCycleLength: 28,
        fallbackPeriodLength: 5,
        today: DateTime(2026, 5, 22),
      );

      expect(forecast.cycleDay, 22);
      expect(forecast.phase, CyclePhase.luteal);
    });
  });
}
