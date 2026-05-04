import '../../data/models/cycle.dart';
import '../../data/models/day_log.dart';
import '../../data/models/enums.dart';
import 'date_x.dart';

/// Metode yang digunakan untuk prediksi — semakin banyak sinyal,
/// semakin tinggi confidence.
enum PredictionMethod {
  /// Hanya calendar method (fallback).
  calendar,

  /// Discharge pattern + calendar.
  dischargeEnhanced,

  /// BBT shift terdeteksi (konfirmasi ovulasi sudah terjadi).
  bbtConfirmed,

  /// Multi-signal: BBT + discharge + symptoms semua konvergen.
  multiSignal,
}

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
    required this.pregnancyChance,
    this.confidence = 0.5,
    this.predictionMethod = PredictionMethod.calendar,
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

  /// Perkiraan tingkat kehamilan untuk tanggal ini (0..1).
  /// Berdasarkan jarak dari ovulationDate: puncak di hari ovulasi (0.33),
  /// tinggi di H-1 (0.28), H-2 s/d H-5 (0.15–0.1), sangat rendah diluar.
  final double pregnancyChance;

  /// Confidence score 0..1 — semakin tinggi semakin banyak sinyal
  /// biologis yang mendukung prediksi (BBT, discharge, symptoms).
  final double confidence;

  /// Metode prediksi yang digunakan untuk forecast ini.
  final PredictionMethod predictionMethod;

  bool get isInPeriod => phase == CyclePhase.menstrual;
  bool get isPeakOvulation => phase == CyclePhase.ovulation;
  bool get isInFertileWindow =>
      !referenceDate.isBefore(fertileWindowStart) &&
      !referenceDate.isAfter(fertileWindowEnd);

  int get daysUntilNextPeriod => referenceDate.daysBetween(nextPeriodStart);
  int get daysUntilOvulation => referenceDate.daysBetween(ovulationDate);

  double get cycleProgress {
    if (cycleLength <= 0) return 0;
    return (cycleDay / cycleLength).clamp(0.0, 1.0);
  }

  /// Label teks tingkat kehamilan.
  String get pregnancyChanceLabel {
    if (pregnancyChance >= 0.30) return 'Sangat Tinggi';
    if (pregnancyChance >= 0.20) return 'Tinggi';
    if (pregnancyChance >= 0.10) return 'Sedang';
    if (pregnancyChance >= 0.03) return 'Rendah';
    return 'Sangat Rendah';
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
    List<DayLog> logs = const [],
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
      cycleStartDate = ref.subtract(const Duration(days: 1));
    } else {
      final last = sorted.last;
      if (!last.startDate.dateOnly.isAfter(ref)) {
        cycleStartDate = last.startDate.dateOnly;
        final gap = cycleStartDate.daysBetween(ref);
        if (gap >= cycleLength) {
          final extraCycles = gap ~/ cycleLength;
          cycleStartDate = cycleStartDate.add(
            Duration(days: extraCycles * cycleLength),
          );
        }
      } else {
        cycleStartDate = last.startDate.dateOnly;
      }
    }

    // Override cycleStartDate kalau logs menunjukkan period aktual mulai
    // di tanggal berbeda dari cycle yang tercatat di Firestore.
    final actualStartFromLogs = _detectActualCycleStartFromLogs(
      logs,
      sorted,
      cycleStartDate,
      ref,
    );
    if (actualStartFromLogs != null) {
      cycleStartDate = actualStartFromLogs;
    }

    // === ADAPTIVE PERIOD LENGTH: deteksi haid selesai lebih awal ===
    final adjustedPeriodLength = _adjustPeriodLengthFromLogs(
      logs,
      cycleStartDate,
      ref,
      periodLength,
    );

    // === ENHANCED PREDICTION: Gunakan semua sinyal biologis ===
    final nextPeriodStart = cycleStartDate.add(Duration(days: cycleLength));

    // 1. Deteksi ovulasi yang sudah terjadi dari BBT shift (siklus berjalan).
    final bbtConfirmedOvulation = _detectBBTOvulationInCycle(
      logs,
      cycleStartDate,
      ref,
    );

    // 2. Belajar luteal phase dari siklus historis yang punya BBT data.
    final learnedLutealPhase = _learnLutealPhaseFromBBT(sorted, logs);

    // 3. Deteksi fertile window dari discharge pattern (siklus berjalan).
    final dischargeOvulation = _detectOvulationFromDischarge(
      logs,
      cycleStartDate,
      ref,
    );

    // 4. Analisa symptom pattern untuk prediksi ovulasi.
    final symptomOvulationDay = _predictOvulationFromSymptoms(
      logs,
      sorted,
      cycleStartDate,
      ref,
    );

    // === Kombinasi semua sinyal ===
    var confidence = 0.5;
    var method = PredictionMethod.calendar;
    DateTime predictedOvulation;

    if (bbtConfirmedOvulation != null) {
      // BBT shift terdeteksi — ovulasi SUDAH terjadi (paling akurat).
      predictedOvulation = bbtConfirmedOvulation;
      confidence = 0.92;
      method = PredictionMethod.bbtConfirmed;
    } else if (learnedLutealPhase != null) {
      // Gunakan luteal phase yang dipelajari dari historis BBT.
      predictedOvulation = nextPeriodStart.subtract(
        Duration(days: learnedLutealPhase),
      );
      confidence = 0.75;
      method = PredictionMethod.bbtConfirmed;
    } else {
      // Fallback calendar method (luteal phase fixed 14 hari).
      predictedOvulation = nextPeriodStart.subtract(const Duration(days: 14));
    }

    // Cross-validate dengan discharge.
    if (dischargeOvulation != null) {
      final diff = predictedOvulation
          .difference(dischargeOvulation)
          .inDays
          .abs();
      if (diff <= 2) {
        // Discharge & BBT/calendar converge → confidence tinggi.
        confidence = confidence.clamp(0.0, 1.0);
        if (confidence < 0.88) confidence = 0.88;
        if (method != PredictionMethod.bbtConfirmed) {
          method = PredictionMethod.dischargeEnhanced;
        }
      } else if (diff <= 4) {
        // Partial agreement → moderate confidence boost.
        confidence = (confidence + 0.1).clamp(0.0, 0.85);
        if (method == PredictionMethod.calendar) {
          method = PredictionMethod.dischargeEnhanced;
        }
      }
      // Kalau diff > 4, trust BBT/calendar lebih (discharge bisa subjective).
    }

    // Cross-validate dengan symptom patterns.
    if (symptomOvulationDay != null) {
      final symptomOvulation = cycleStartDate.add(
        Duration(days: symptomOvulationDay - 1),
      );
      final diff = predictedOvulation.difference(symptomOvulation).inDays.abs();
      if (diff <= 2) {
        confidence = (confidence + 0.05).clamp(0.0, 0.95);
        if (method == PredictionMethod.bbtConfirmed ||
            method == PredictionMethod.dischargeEnhanced) {
          method = PredictionMethod.multiSignal;
        }
      }
    }

    final ovulationDate = predictedOvulation;
    final fertileStart = ovulationDate.subtract(const Duration(days: 5));
    final fertileEnd = ovulationDate.add(const Duration(days: 1));

    final cycleDay = cycleStartDate.daysBetween(ref) + 1;

    final phase = _phaseForDay(
      cycleDay: cycleDay,
      cycleLength: cycleLength,
      periodLength: adjustedPeriodLength,
      ovulationDay: cycleStartDate.daysBetween(ovulationDate) + 1,
    );

    final regularity = _regularityScore(lengths);

    final pregnancyChance = _pregnancyChance(
      referenceDate: ref,
      ovulationDate: ovulationDate,
      fertileWindowStart: fertileStart,
      fertileWindowEnd: fertileEnd,
    );

    return CycleForecast(
      referenceDate: ref,
      cycleStartDate: cycleStartDate,
      cycleDay: cycleDay,
      cycleLength: cycleLength,
      periodLength: adjustedPeriodLength,
      phase: phase,
      nextPeriodStart: nextPeriodStart,
      ovulationDate: ovulationDate,
      fertileWindowStart: fertileStart,
      fertileWindowEnd: fertileEnd,
      regularityScore: regularity,
      usingHistoricalAverage: useHistorical,
      pregnancyChance: pregnancyChance,
      confidence: confidence,
      predictionMethod: method,
    );
  }

  /// Hitung forecast untuk semua hari dalam satu bulan — optimasi untuk
  /// kalender. Hindari sort 28-31x dengan pre-sort sekali dan reuse.
  static Map<DateTime, CycleForecast> computeForMonth({
    required List<Cycle> cycles,
    required int fallbackCycleLength,
    required int fallbackPeriodLength,
    required DateTime month,
    List<DayLog> logs = const [],
  }) {
    final lastOfMonth = DateTime(month.year, month.month + 1, 0);

    // Pre-sort & pre-compute averages sekali.
    final sorted = [...cycles]
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final lengths = _historicalCycleLengths(sorted);
    final periodLengths = _historicalPeriodLengths(sorted);
    final useHistorical = lengths.length >= minHistoricalCycles;
    final cycleLength = useHistorical
        ? _avg(lengths.take(maxHistoricalWindow).toList())
        : fallbackCycleLength;
    final periodLength = periodLengths.isNotEmpty
        ? _avg(periodLengths.take(maxHistoricalWindow).toList())
        : fallbackPeriodLength;
    final regularity = _regularityScore(lengths);

    // Pre-compute enhanced ovulation & adjusted period length per cycleStart.
    final cycleOvulationCache = <DateTime, _CycleOvulation>{};
    final cyclePeriodLengthCache = <DateTime, int>{};

    DateTime rawCycleStart(DateTime ref) {
      if (sorted.isEmpty) return ref.subtract(const Duration(days: 1));
      final last = sorted.last;
      if (!last.startDate.dateOnly.isAfter(ref)) {
        var start = last.startDate.dateOnly;
        final gap = start.daysBetween(ref);
        if (gap >= cycleLength) {
          final extraCycles = gap ~/ cycleLength;
          start = start.add(Duration(days: extraCycles * cycleLength));
        }
        return start;
      }
      return last.startDate.dateOnly;
    }

    // Override cycle start untuk siklus berjalan dari logs.
    final actualStartFromLogs = _detectActualCycleStartFromLogs(
      logs,
      sorted,
      rawCycleStart(lastOfMonth),
      lastOfMonth,
    );

    // Collect semua cycleStartDate unik di bulan ini.
    final uniqueStarts = <DateTime>{};
    for (var day = 1; day <= lastOfMonth.day; day++) {
      final ref = DateTime(month.year, month.month, day).dateOnly;
      final raw = rawCycleStart(ref);
      // Kalau raw adalah last Firestore cycle dan logs tunjukkan start beda,
      // pakai actual start. Kalau sudah projected ke siklus berikutnya,
      // atau ini cycle lama, pakai raw.
      final last = sorted.isNotEmpty ? sorted.last.startDate.dateOnly : null;
      if (actualStartFromLogs != null &&
          last != null &&
          raw.isAtSameMomentAs(last)) {
        uniqueStarts.add(actualStartFromLogs);
      } else {
        uniqueStarts.add(raw);
      }
    }

    // Pre-compute enhanced ovulation untuk masing-masing cycleStart.
    for (final start in uniqueStarts) {
      final nextPeriodStart = start.add(Duration(days: cycleLength));

      // BBT shift detection untuk siklus ini (kalau ada data).
      final bbtConfirmed = _detectBBTOvulationInCycle(logs, start, lastOfMonth);

      // Learned luteal phase dari historis BBT.
      final learnedLuteal = _learnLutealPhaseFromBBT(sorted, logs);

      // Discharge detection.
      final dischargeOv = _detectOvulationFromDischarge(
        logs,
        start,
        lastOfMonth,
      );

      // Symptom prediction.
      final symptomOvDay = _predictOvulationFromSymptoms(
        logs,
        sorted,
        start,
        lastOfMonth,
      );

      DateTime predictedOv;
      var confidence = 0.5;
      var method = PredictionMethod.calendar;

      if (bbtConfirmed != null) {
        predictedOv = bbtConfirmed;
        confidence = 0.92;
        method = PredictionMethod.bbtConfirmed;
      } else if (learnedLuteal != null) {
        predictedOv = nextPeriodStart.subtract(Duration(days: learnedLuteal));
        confidence = 0.75;
        method = PredictionMethod.bbtConfirmed;
      } else {
        predictedOv = nextPeriodStart.subtract(const Duration(days: 14));
      }

      // Cross-validate dengan discharge.
      if (dischargeOv != null) {
        final diff = predictedOv.difference(dischargeOv).inDays.abs();
        if (diff <= 2) {
          confidence = confidence.clamp(0.0, 1.0);
          if (confidence < 0.88) confidence = 0.88;
          if (method != PredictionMethod.bbtConfirmed) {
            method = PredictionMethod.dischargeEnhanced;
          }
        } else if (diff <= 4) {
          confidence = (confidence + 0.1).clamp(0.0, 0.85);
          if (method == PredictionMethod.calendar) {
            method = PredictionMethod.dischargeEnhanced;
          }
        }
      }

      // Cross-validate dengan symptoms.
      if (symptomOvDay != null) {
        final symptomOv = start.add(Duration(days: symptomOvDay - 1));
        final diff = predictedOv.difference(symptomOv).inDays.abs();
        if (diff <= 2) {
          confidence = (confidence + 0.05).clamp(0.0, 0.95);
          if (method == PredictionMethod.bbtConfirmed ||
              method == PredictionMethod.dischargeEnhanced) {
            method = PredictionMethod.multiSignal;
          }
        }
      }

      cycleOvulationCache[start] = _CycleOvulation(
        ovulationDate: predictedOv,
        fertileStart: predictedOv.subtract(const Duration(days: 5)),
        fertileEnd: predictedOv.add(const Duration(days: 1)),
        confidence: confidence,
        method: method,
      );

      // Adaptive period length dari logs aktual untuk cycle ini.
      cyclePeriodLengthCache[start] = _adjustPeriodLengthFromLogs(
        logs,
        start,
        lastOfMonth,
        periodLength,
      );
    }

    final forecasts = <DateTime, CycleForecast>{};
    DateTime? lastCycleStart;

    for (var day = 1; day <= lastOfMonth.day; day++) {
      final ref = DateTime(month.year, month.month, day).dateOnly;
      final raw = rawCycleStart(ref);
      final lastCycle = sorted.isNotEmpty
          ? sorted.last.startDate.dateOnly
          : null;
      final cycleStartDate =
          (actualStartFromLogs != null &&
              lastCycle != null &&
              raw.isAtSameMomentAs(lastCycle))
          ? actualStartFromLogs
          : raw;

      // Skip recompute kalau masih dalam siklus yang sama.
      if (lastCycleStart != null &&
          cycleStartDate.isAtSameMomentAs(lastCycleStart)) {
        final prev = forecasts.values.last;
        forecasts[ref] = CycleForecast(
          referenceDate: ref,
          cycleStartDate: prev.cycleStartDate,
          cycleDay: prev.cycleDay + 1,
          cycleLength: prev.cycleLength,
          periodLength: prev.periodLength,
          phase: _phaseForDay(
            cycleDay: prev.cycleDay + 1,
            cycleLength: prev.cycleLength,
            periodLength: prev.periodLength,
            ovulationDay:
                prev.cycleStartDate.daysBetween(prev.ovulationDate) + 1,
          ),
          nextPeriodStart: prev.nextPeriodStart,
          ovulationDate: prev.ovulationDate,
          fertileWindowStart: prev.fertileWindowStart,
          fertileWindowEnd: prev.fertileWindowEnd,
          regularityScore: prev.regularityScore,
          usingHistoricalAverage: prev.usingHistoricalAverage,
          pregnancyChance: _pregnancyChance(
            referenceDate: ref,
            ovulationDate: prev.ovulationDate,
            fertileWindowStart: prev.fertileWindowStart,
            fertileWindowEnd: prev.fertileWindowEnd,
          ),
          confidence: prev.confidence,
          predictionMethod: prev.predictionMethod,
        );
        lastCycleStart = cycleStartDate;
        continue;
      }

      lastCycleStart = cycleStartDate;
      final cycleDay = cycleStartDate.daysBetween(ref) + 1;
      final nextPeriodStart = cycleStartDate.add(Duration(days: cycleLength));

      final cached = cycleOvulationCache[cycleStartDate]!;

      final adjustedPeriodLength = cyclePeriodLengthCache[cycleStartDate]!;

      final phase = _phaseForDay(
        cycleDay: cycleDay,
        cycleLength: cycleLength,
        periodLength: adjustedPeriodLength,
        ovulationDay: cycleStartDate.daysBetween(cached.ovulationDate) + 1,
      );

      forecasts[ref] = CycleForecast(
        referenceDate: ref,
        cycleStartDate: cycleStartDate,
        cycleDay: cycleDay,
        cycleLength: cycleLength,
        periodLength: adjustedPeriodLength,
        phase: phase,
        nextPeriodStart: nextPeriodStart,
        ovulationDate: cached.ovulationDate,
        fertileWindowStart: cached.fertileStart,
        fertileWindowEnd: cached.fertileEnd,
        regularityScore: regularity,
        usingHistoricalAverage: useHistorical,
        pregnancyChance: _pregnancyChance(
          referenceDate: ref,
          ovulationDate: cached.ovulationDate,
          fertileWindowStart: cached.fertileStart,
          fertileWindowEnd: cached.fertileEnd,
        ),
        confidence: cached.confidence,
        predictionMethod: cached.method,
      );
    }

    return forecasts;
  }

  // ================================================================
  // Helpers
  // ================================================================

  /// Panjang setiap siklus historis (jarak antar startDate).
  /// Hanya menggunakan siklus yang sudah punya siklus berikutnya.
  static List<int> _historicalCycleLengths(List<Cycle> sortedAsc) {
    final result = <int>[];
    for (var i = 0; i < sortedAsc.length - 1; i++) {
      final length = sortedAsc[i].startDate.daysBetween(
        sortedAsc[i + 1].startDate,
      );
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

  /// Perkiraan chance kehamilan berdasarkan jarak dari ovulationDate.
  /// Angka berbasis studi fertilitas standar (Wilcox et al.).
  static double _pregnancyChance({
    required DateTime referenceDate,
    required DateTime ovulationDate,
    required DateTime fertileWindowStart,
    required DateTime fertileWindowEnd,
  }) {
    final diff = ovulationDate.difference(referenceDate).inDays;
    // diff positif = sebelum ovulasi, diff negatif = setelah ovulasi
    return switch (diff) {
      0 => 0.33, // hari ovulasi
      1 => 0.28, // H-1 sebelum ovulasi
      2 => 0.20, // H-2
      3 => 0.15, // H-3
      4 => 0.12, // H-4
      5 => 0.10, // H-5 (awal fertile window)
      -1 => 0.08, // H+1 setelah ovulasi
      _ => 0.01, // di luar fertile window
    };
  }

  /// Skor keteraturan: 1.0 bila variasi <=2 hari, 0.0 bila variasi >=10 hari.
  static double _regularityScore(List<int> lengths) {
    if (lengths.length < 2) return 0.5;
    final avg = _avg(lengths).toDouble();
    final variance =
        lengths.map((l) => (l - avg).abs()).fold<double>(0, (a, b) => a + b) /
        lengths.length;
    if (variance <= 2) return 1.0;
    if (variance >= 10) return 0.0;
    return (10 - variance) / 8;
  }

  // ================================================================
  // Enhanced Prediction Helpers
  // ================================================================

  /// Deteksi ovulasi yang SUDAH TERJADI dari BBT shift di siklus berjalan.
  /// Algoritma NFP/FAM: 3 hari berturut-turut naik >= 0.2°C dari baseline
  /// 6 hari pre-ovulatory menandakan ovulasi terjadi 1 hari sebelum hari naik.
  /// Return null kalau data BBT tidak cukup atau shift tidak terdeteksi.
  static DateTime? _detectBBTOvulationInCycle(
    List<DayLog> logs,
    DateTime cycleStart,
    DateTime upToDate,
  ) {
    final cycleLogs = _logsInRange(logs, cycleStart, upToDate)
      ..sort((a, b) => a.date.compareTo(b.date));

    final bbtLogs = cycleLogs.where((l) => l.bbt != null).toList();
    if (bbtLogs.length < 9) return null; // Butuh 6 pre-shift + 3 post-shift

    // Cari 6 suhu terendah berturut-turut untuk baseline
    // (window sliding: ambil 6 hari berturut-turut terendah)
    var bestBaseline = double.infinity;
    var bestBaselineEnd = -1;

    for (var i = 0; i <= bbtLogs.length - 6; i++) {
      final window = bbtLogs.sublist(i, i + 6);
      final temps = window.map((l) => l.bbt!).toList();
      final maxInWindow = temps.reduce((a, b) => a > b ? a : b);
      if (maxInWindow < bestBaseline) {
        bestBaseline = maxInWindow;
        bestBaselineEnd = i + 5;
      }
    }

    if (bestBaselineEnd < 0 || bestBaselineEnd >= bbtLogs.length - 3) {
      return null;
    }

    // Cek 3 hari berturut-turut naik >= 0.2°C dari baseline
    final t1 = bbtLogs[bestBaselineEnd + 1].bbt!;
    final t2 = bbtLogs[bestBaselineEnd + 2].bbt!;
    final t3 = bbtLogs[bestBaselineEnd + 3].bbt!;

    if (t1 >= bestBaseline + 0.15 &&
        t2 >= bestBaseline + 0.15 &&
        t3 >= bestBaseline + 0.15) {
      // Ovulasi terjadi 1 hari sebelum hari naik pertama
      return bbtLogs[bestBaselineEnd + 1].date.dateOnly.subtract(
        const Duration(days: 1),
      );
    }

    return null;
  }

  /// Belajar luteal phase (ovulation → next period) dari siklus historis
  /// yang punya data BBT. Return null kalau tidak ada data BBT historis.
  static int? _learnLutealPhaseFromBBT(
    List<Cycle> sortedCycles,
    List<DayLog> logs,
  ) {
    if (sortedCycles.length < 2 || logs.isEmpty) return null;

    final lutealPhases = <int>[];

    for (var i = 0; i < sortedCycles.length - 1; i++) {
      final cycle = sortedCycles[i];
      final nextCycle = sortedCycles[i + 1];
      final cycleEnd = nextCycle.startDate.dateOnly;

      // Cari ovulasi via BBT di siklus ini
      final ovulation = _detectBBTOvulationInCycle(
        logs,
        cycle.startDate.dateOnly,
        cycleEnd,
      );
      if (ovulation == null) continue;

      final luteal = ovulation.daysBetween(cycleEnd);
      // Valid range luteal phase: 10-16 hari (medical standard)
      if (luteal >= 10 && luteal <= 16) {
        lutealPhases.add(luteal);
      }
    }

    if (lutealPhases.isEmpty) return null;
    // Gunakan median (lebih robust terhadap outlier dari rata-rata)
    lutealPhases.sort();
    return lutealPhases[lutealPhases.length ~/ 2];
  }

  /// Deteksi ovulasi dari discharge pattern di siklus berjalan.
  /// Egg white = peak fertility (ovulasi dalam 24-48 jam).
  /// Watery = fertile window (ovulasi mendekat).
  /// Return null kalau tidak ada data discharge fertile.
  static DateTime? _detectOvulationFromDischarge(
    List<DayLog> logs,
    DateTime cycleStart,
    DateTime upToDate,
  ) {
    final cycleLogs = _logsInRange(logs, cycleStart, upToDate)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Cari egg white (paling akurat) — ovulasi biasanya H+1 dari egg white
    for (final log in cycleLogs) {
      if (log.discharge == Discharge.eggWhite) {
        return log.date.dateOnly.add(const Duration(days: 1));
      }
    }

    // Watery juga indikasi fertile approaching — ovulasi H+1
    for (final log in cycleLogs) {
      if (log.discharge == Discharge.watery) {
        return log.date.dateOnly.add(const Duration(days: 1));
      }
    }

    return null;
  }

  /// Prediksi ovulasi dari symptom patterns yang dikorelasikan historis.
  /// Belajar: symptom apa yang paling konsisten muncul dekat ovulasi
  /// untuk user ini, lalu prediksi dari symptom di siklus berjalan.
  /// Return hari ovulasi (1-based dari cycleStart), atau null.
  static int? _predictOvulationFromSymptoms(
    List<DayLog> logs,
    List<Cycle> sortedCycles,
    DateTime cycleStart,
    DateTime upToDate,
  ) {
    if (sortedCycles.length < 2 || logs.isEmpty) return null;

    // Symptom yang paling relevan untuk ovulasi
    const ovulationSymptoms = {
      Symptom.breastTenderness,
      Symptom.bloating,
      Symptom.cramps,
      Symptom.headache,
    };

    // Step 1: Belajar korelasi symptom-ovulasi dari historis
    // (Asumsi ovulasi di hari 14 dari cycleStart untuk historical cycles)
    final symptomOffsetCounts = <Symptom, Map<int, int>>{};

    for (var i = 0; i < sortedCycles.length - 1; i++) {
      final c = sortedCycles[i];
      final cycleLogs = _logsInRange(
        logs,
        c.startDate.dateOnly,
        sortedCycles[i + 1].startDate.dateOnly,
      );

      // Asumsikan ovulasi historis di hari 14 (atau BBT-confirmed kalau ada)
      var ovDay = 14;
      final bbtOv = _detectBBTOvulationInCycle(
        logs,
        c.startDate.dateOnly,
        sortedCycles[i + 1].startDate.dateOnly,
      );
      if (bbtOv != null) {
        ovDay = c.startDate.dateOnly.daysBetween(bbtOv) + 1;
      }

      for (final log in cycleLogs) {
        final dayNum = c.startDate.dateOnly.daysBetween(log.date.dateOnly) + 1;
        final offset = dayNum - ovDay; // offset dari ovulasi

        for (final symptom in log.symptoms) {
          if (!ovulationSymptoms.contains(symptom)) continue;
          symptomOffsetCounts.putIfAbsent(symptom, () => <int, int>{})[offset] =
              (symptomOffsetCounts[symptom]![offset] ?? 0) + 1;
        }
      }
    }

    if (symptomOffsetCounts.isEmpty) return null;

    // Step 2: Cari symptom pattern di siklus berjalan
    final currentLogs = _logsInRange(logs, cycleStart, upToDate);
    final symptomDays = <int>[];

    for (final log in currentLogs) {
      final dayNum = cycleStart.daysBetween(log.date.dateOnly) + 1;
      for (final symptom in log.symptoms) {
        if (!ovulationSymptoms.contains(symptom)) continue;
        final offsets = symptomOffsetCounts[symptom];
        if (offsets == null || offsets.isEmpty) continue;

        // Cari offset paling umum untuk symptom ini
        final mostCommonOffset = offsets.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
        symptomDays.add(dayNum - mostCommonOffset);
      }
    }

    if (symptomDays.isEmpty) return null;

    // Step 3: Ambil median dari prediksi symptom (robust terhadap outlier)
    symptomDays.sort();
    return symptomDays[symptomDays.length ~/ 2];
  }

  /// Utility: filter logs dalam range tanggal [start, end).
  static List<DayLog> _logsInRange(
    List<DayLog> logs,
    DateTime start,
    DateTime end,
  ) {
    return logs.where((l) {
      final d = l.date.dateOnly;
      return !d.isBefore(start) && d.isBefore(end);
    }).toList();
  }

  /// Sesuaikan panjang haid dari logs aktual user di siklus berjalan.
  ///
  /// Logika:
  /// - Kalau user log aliran darah melebihi prediksi → extend periodLength.
  /// - Kalau user log hari tanpa aliran (hasAnyData=true, flowIntensity=null)
  ///   setelah hari terakhir ada darah → period dianggap sudah selesai
  ///   lebih awal.
  /// - Kalau ada gap 2+ hari tanpa log setelah hari terakhir ada darah,
  ///   dan ref sudah melewati gap tersebut → asumsi period selesai lebih awal.
  static int _adjustPeriodLengthFromLogs(
    List<DayLog> logs,
    DateTime cycleStart,
    DateTime ref,
    int predictedLength,
  ) {
    final cycleLogs = _logsInRange(
      logs,
      cycleStart,
      ref.add(const Duration(days: 1)),
    );

    // Cari log aliran darah di 10 hari pertama siklus (window period).
    final flowLogs = cycleLogs.where((l) {
      if (l.flowIntensity == null) return false;
      final day = cycleStart.daysBetween(l.date.dateOnly) + 1;
      return day >= 1 && day <= 10;
    }).toList();

    if (flowLogs.isEmpty) return predictedLength;

    // Hari terakhir user log ada darah.
    final lastFlowLog = flowLogs.reduce(
      (a, b) => a.date.dateOnly.isAfter(b.date.dateOnly) ? a : b,
    );
    final lastFlowDay = cycleStart.daysBetween(lastFlowLog.date.dateOnly) + 1;

    // --- Kasus 1: user masih mens melebihi prediksi → extend ---
    if (lastFlowDay > predictedLength) return lastFlowDay;

    // --- Kasus 2: user log hari "tidak ada darah" setelah hari terakhir
    // ada darah → period selesai lebih awal.
    final noFlowAfter = cycleLogs.where((l) {
      if (!l.hasAnyData || l.flowIntensity != null) return false;
      final day = cycleStart.daysBetween(l.date.dateOnly) + 1;
      return day > lastFlowDay && day <= predictedLength + 2;
    }).toList();

    if (noFlowAfter.isNotEmpty) {
      final firstNoFlowDay = noFlowAfter
          .map((l) => cycleStart.daysBetween(l.date.dateOnly) + 1)
          .reduce((a, b) => a < b ? a : b);

      // Kalau gap antara hari terakhir darah dan hari pertama "no flow"
      // adalah 1 hari → period kemungkinan selesai di hari terakhir darah.
      if (firstNoFlowDay - lastFlowDay >= 1) {
        return lastFlowDay;
      }
    }

    // --- Kasus 3: gap 2+ hari tanpa log SAMA SEKALI setelah terakhir
    // darah, dan ref sudah melewati gap tersebut.
    final refDay = cycleStart.daysBetween(ref.dateOnly) + 1;
    if (refDay > lastFlowDay + 2) {
      var emptyGapDays = 0;
      for (var d = lastFlowDay + 1; d <= refDay; d++) {
        final date = cycleStart.add(Duration(days: d - 1)).dateOnly;
        final hasLog = cycleLogs.any((l) => l.date.dateOnly == date);
        if (!hasLog) {
          emptyGapDays++;
        } else {
          break;
        }
      }
      if (emptyGapDays >= 2 && refDay >= lastFlowDay + emptyGapDays) {
        return lastFlowDay;
      }
    }

    return predictedLength;
  }

  /// Deteksi cycle start aktual dari flow logs.
  /// Kalau user log aliran darah di tanggal yang beda dari cycle start
  /// di Firestore (misal haid mulai H-1 atau H+2 dari prediksi),
  /// return tanggal flow log yang paling masuk akal.
  ///
  /// Return null kalau tidak ada evidence di logs atau cycle start sudah
  /// sesuai dengan data user.
  static DateTime? _detectActualCycleStartFromLogs(
    List<DayLog> logs,
    List<Cycle> sortedCycles,
    DateTime currentStart,
    DateTime ref,
  ) {
    // Window: 3 hari sebelum sampai 5 hari setelah currentStart
    final windowLogs = _logsInRange(
      logs,
      currentStart.subtract(const Duration(days: 3)),
      currentStart.add(const Duration(days: 6)),
    )..sort((a, b) => a.date.compareTo(b.date));

    final flowLogs = windowLogs.where((l) => l.flowIntensity != null).toList();
    if (flowLogs.isEmpty) return null;

    // Kasus A: flow log paling awal sebelum currentStart → shift lebih awal
    final firstFlow = flowLogs.first.date.dateOnly;
    if (firstFlow.isBefore(currentStart)) {
      // Cek apakah ini mungkin backlog dari cycle sebelumnya
      if (sortedCycles.length >= 2) {
        final prevStart =
            sortedCycles[sortedCycles.length - 2].startDate.dateOnly;
        if (firstFlow.difference(prevStart).inDays.abs() <= 3) {
          return null; // kemungkinan backlog, jangan override
        }
      }
      return firstFlow;
    }

    // Kasus B: flow log paling awal setelah currentStart → shift lebih lambat
    final hasFlowOnStart = flowLogs.any((l) => l.date.dateOnly == currentStart);
    if (!hasFlowOnStart) {
      for (final log in flowLogs) {
        final logDate = log.date.dateOnly;
        if (!logDate.isBefore(currentStart)) {
          final gap = currentStart.daysBetween(logDate);
          if (gap >= 1 && gap <= 3) {
            return logDate;
          }
          break; // gap terlalu besar, abaikan
        }
      }
    }

    return null;
  }
}

/// Cache hasil enhanced ovulation prediction untuk satu cycleStartDate.
class _CycleOvulation {
  const _CycleOvulation({
    required this.ovulationDate,
    required this.fertileStart,
    required this.fertileEnd,
    required this.confidence,
    required this.method,
  });

  final DateTime ovulationDate;
  final DateTime fertileStart;
  final DateTime fertileEnd;
  final double confidence;
  final PredictionMethod method;
}
