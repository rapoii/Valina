import '../../data/models/cycle.dart';
import '../../data/models/enums.dart';
import 'date_x.dart';

/// Forecast/proyeksi siklus untuk tanggal tertentu.
class CycleForecast {
  const CycleForecast({
    required this.referenceDate,
    required this.cycleStartDate,
    required this.cycleDay,
    required this.cycleLength,
    required this.periodLength,
    required this.phase,
    required this.nextPeriodStart,
    required this.ovulationDate,
    required this.fertileWindowStart,
    required this.fertileWindowEnd,
    required this.regularityScore,
    required this.usingHistoricalAverage,
  });

  /// Tanggal referensi (hari ini atau hari yang dipilih).
  final DateTime referenceDate;

  /// Tanggal mulai siklus saat ini (haid terakhir).
  final DateTime cycleStartDate;

  /// Hari ke-N dalam siklus saat ini (1-based).
  final int cycleDay;

  final int cycleLength;
  final int periodLength;
  final CyclePhase phase;

  final DateTime nextPeriodStart;
  final DateTime ovulationDate;
  final DateTime fertileWindowStart;
  final DateTime fertileWindowEnd;

  /// 0..1 — semakin tinggi semakin teratur. < 0.6 = tidak teratur.
  final double regularityScore;

  /// True bila prediksi memakai rata-rata historis (>=3 siklus).
  final bool usingHistoricalAverage;

  bool get isInPeriod => phase == CyclePhase.menstrual;
  bool get isInFertileWindow =>
      !referenceDate.isBefore(fertileWindowStart) &&
      !referenceDate.isAfter(fertileWindowEnd);

  int get daysUntilNextPeriod => referenceDate.daysBetween(nextPeriodStart);
  int get daysUntilOvulation => referenceDate.daysBetween(ovulationDate);

  double get cycleProgress {
    if (cycleLength <= 0) return 0;
    return (cycleDay / cycleLength).clamp(0.0, 1.0);
  }
}

/// Algoritma prediksi siklus.
///
/// Murni Dart, tanpa side-effect — mudah di-test.
abstract final class CycleCalculator {
  /// Minimal siklus historis untuk gunakan rata-rata bergerak.
  static const int minHistoricalCycles = 3;

  /// Maks siklus terakhir yang dipakai untuk rata-rata.
  static const int maxHistoricalWindow = 6;

  /// Hitung forecast.
  ///
  /// [cycles] = list siklus historis (harus sudah selesai untuk dihitung
  /// length-nya — siklus yang masih ongoing dilewati untuk averaging).
  /// [fallbackCycleLength] dan [fallbackPeriodLength] dipakai bila
  /// historical data tidak cukup.
  /// [today] biasanya `DateTime.now()`, tapi parameter agar bisa di-test.
  static CycleForecast compute({
    required List<Cycle> cycles,
    required int fallbackCycleLength,
    required int fallbackPeriodLength,
    required DateTime today,
  }) {
    final ref = today.dateOnly;

    final sorted = [...cycles]
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    // Hitung rata-rata cycle/period length dari riwayat lengkap.
    final lengths = _historicalCycleLengths(sorted);
    final periodLengths = _historicalPeriodLengths(sorted);

    final useHistorical = lengths.length >= minHistoricalCycles;

    final cycleLength = useHistorical
        ? _avg(lengths.take(maxHistoricalWindow).toList())
        : fallbackCycleLength;
    final periodLength = periodLengths.isNotEmpty
        ? _avg(periodLengths.take(maxHistoricalWindow).toList())
        : fallbackPeriodLength;

    // Tentukan cycleStartDate: siklus paling baru yang dimulai <= ref.
    DateTime cycleStartDate;
    if (sorted.isEmpty) {
      // Belum ada data: asumsikan haid mulai 1 hari lalu.
      cycleStartDate = ref.subtract(const Duration(days: 1));
    } else {
      final last = sorted.last;
      if (!last.startDate.dateOnly.isAfter(ref)) {
        cycleStartDate = last.startDate.dateOnly;
        // Bila ref sudah jauh lebih dari panjang siklus dari startDate
        // berarti siklus baru sudah mulai (belum tercatat). Geser maju.
        final gap = cycleStartDate.daysBetween(ref);
        if (gap >= cycleLength) {
          final extraCycles = gap ~/ cycleLength;
          cycleStartDate =
              cycleStartDate.add(Duration(days: extraCycles * cycleLength));
        }
      } else {
        // Siklus paling baru di masa depan (edge case onboarding).
        cycleStartDate = last.startDate.dateOnly;
      }
    }

    final cycleDay = cycleStartDate.daysBetween(ref) + 1;

    final nextPeriodStart = cycleStartDate.add(Duration(days: cycleLength));
    final ovulationDate =
        nextPeriodStart.subtract(const Duration(days: 14));
    final fertileStart = ovulationDate.subtract(const Duration(days: 5));
    final fertileEnd = ovulationDate.add(const Duration(days: 1));

    final phase = _phaseForDay(
      cycleDay: cycleDay,
      cycleLength: cycleLength,
      periodLength: periodLength,
      ovulationDay:
          cycleStartDate.daysBetween(ovulationDate) + 1, // 1-based
    );

    final regularity = _regularityScore(lengths);

    return CycleForecast(
      referenceDate: ref,
      cycleStartDate: cycleStartDate,
      cycleDay: cycleDay,
      cycleLength: cycleLength,
      periodLength: periodLength,
      phase: phase,
      nextPeriodStart: nextPeriodStart,
      ovulationDate: ovulationDate,
      fertileWindowStart: fertileStart,
      fertileWindowEnd: fertileEnd,
      regularityScore: regularity,
      usingHistoricalAverage: useHistorical,
    );
  }

  // ================================================================
  // Helpers
  // ================================================================

  /// Panjang setiap siklus historis (jarak antar startDate).
  /// Hanya menggunakan siklus yang sudah punya siklus berikutnya.
  static List<int> _historicalCycleLengths(List<Cycle> sortedAsc) {
    final result = <int>[];
    for (var i = 0; i < sortedAsc.length - 1; i++) {
      final length = sortedAsc[i]
          .startDate
          .daysBetween(sortedAsc[i + 1].startDate);
      if (length > 0 && length <= 60) {
        result.add(length);
      }
    }
    return result.reversed.toList(); // newest first
  }

  static List<int> _historicalPeriodLengths(List<Cycle> sortedAsc) {
    final result = <int>[];
    for (final c in sortedAsc.reversed) {
      if (c.endDate != null) {
        final p = c.periodLength;
        if (p > 0 && p <= 14) result.add(p);
      }
    }
    return result;
  }

  static int _avg(List<int> values) {
    if (values.isEmpty) return 0;
    final sum = values.fold<int>(0, (a, b) => a + b);
    return (sum / values.length).round();
  }

  static CyclePhase _phaseForDay({
    required int cycleDay,
    required int cycleLength,
    required int periodLength,
    required int ovulationDay,
  }) {
    if (cycleDay <= 0) return CyclePhase.menstrual; // edge case
    if (cycleDay <= periodLength) return CyclePhase.menstrual;
    // Window ovulasi ±1 hari
    if (cycleDay >= ovulationDay - 1 && cycleDay <= ovulationDay + 1) {
      return CyclePhase.ovulation;
    }
    if (cycleDay < ovulationDay - 1) return CyclePhase.follicular;
    return CyclePhase.luteal;
  }

  /// Skor keteraturan: 1.0 bila variasi <=2 hari, 0.0 bila variasi >=10 hari.
  static double _regularityScore(List<int> lengths) {
    if (lengths.length < 2) return 0.5;
    final avg = _avg(lengths).toDouble();
    final variance = lengths
            .map((l) => (l - avg).abs())
            .fold<double>(0, (a, b) => a + b) /
        lengths.length;
    if (variance <= 2) return 1.0;
    if (variance >= 10) return 0.0;
    return (10 - variance) / 8;
  }
}
