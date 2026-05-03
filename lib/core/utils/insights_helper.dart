import '../../data/models/enums.dart';
import '../theme/app_colors.dart';
import 'cycle_calculator.dart';

class DailyInsight {
  const DailyInsight({
    required this.title,
    required this.body,
    required this.emoji,
    required this.tone,
  });

  final String title;
  final String body;
  final String emoji;
  final CyclePhaseColor tone;
}

abstract final class InsightsHelper {
  /// Mengembalikan insight berdasarkan fase + posisi pada siklus.
  static DailyInsight forForecast(CycleForecast f) {
    return switch (f.phase) {
      CyclePhase.menstrual => const DailyInsight(
        title: 'Fase Menstruasi',
        body:
            'Tubuhmu sedang membersihkan diri. Istirahat cukup, hindari kafein berlebih, dan utamakan asupan zat besi seperti bayam atau daging tanpa lemak.',
        emoji: '🌸',
        tone: CyclePhaseColor.menstrual,
      ),
      CyclePhase.follicular => const DailyInsight(
        title: 'Fase Folikular',
        body:
            'Energimu meningkat, ini saat ideal untuk olahraga, proyek baru, atau kegiatan sosial. Estrogen sedang naik!',
        emoji: '🌿',
        tone: CyclePhaseColor.follicular,
      ),
      CyclePhase.ovulation => const DailyInsight(
        title: 'Fase Ovulasi',
        body:
            'Kamu sedang dalam fertile window. Libido cenderung naik, mood positif. Catat suhu basal untuk akurasi prediksi yang lebih baik.',
        emoji: '✨',
        tone: CyclePhaseColor.ovulation,
      ),
      CyclePhase.luteal => const DailyInsight(
        title: 'Fase Luteal',
        body:
            'Progesteron mendominasi. Mood swing & ngidam wajar terjadi. Perbanyak magnesium (pisang, almond, dark chocolate) dan tidur yang cukup.',
        emoji: '🍵',
        tone: CyclePhaseColor.luteal,
      ),
    };
  }

  /// Pesan ringkas untuk header (status hari ini).
  static String headlineForForecast(CycleForecast f) {
    if (f.phase == CyclePhase.menstrual) {
      return 'Hari ke-${f.cycleDay} haid';
    }
    if (f.isInFertileWindow) {
      return 'Fertile window';
    }
    final days = f.daysUntilNextPeriod;
    if (days <= 0) return 'Haid mungkin sudah dimulai';
    if (days == 1) return 'Haid besok';
    return 'Haid ~$days hari lagi';
  }

  static String phaseColorLabel(CyclePhase phase) => switch (phase) {
    CyclePhase.menstrual => 'Menstruasi',
    CyclePhase.follicular => 'Folikular',
    CyclePhase.ovulation => 'Ovulasi',
    CyclePhase.luteal => 'Luteal',
  };

  static CyclePhaseColor phaseColorEnum(CyclePhase phase) => switch (phase) {
    CyclePhase.menstrual => CyclePhaseColor.menstrual,
    CyclePhase.follicular => CyclePhaseColor.follicular,
    CyclePhase.ovulation => CyclePhaseColor.ovulation,
    CyclePhase.luteal => CyclePhaseColor.luteal,
  };
}
