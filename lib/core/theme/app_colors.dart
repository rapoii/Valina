import 'package:flutter/cupertino.dart';

/// Palet warna aplikasi yang mengikuti filosofi Apple HIG:
/// soft, feminine, hangat, namun modern dan netral.
///
/// Token diatur per kategori: brand, semantic cycle phases,
/// neutrals (mengikuti iOS System Grouped), status, dan glass.
abstract final class AppColors {
  // ============================================================
  // Brand & Aksen
  // ============================================================
  /// Rose Quartz — aksen utama (tombol, ring, ikon aktif).
  static const Color accentPrimary = Color(0xFFFF6F91);

  /// Blush — background highlight, chip terpilih.
  static const Color accentSoft = Color(0xFFFFD3DC);

  /// Rose tua untuk pressed state.
  static const Color accentPressed = Color(0xFFE85A7C);

  // ============================================================
  // Semantic Cycle Phases
  // ============================================================
  static const Color phaseMenstrual = Color(0xFFFF6F91);
  static const Color phaseFollicular = Color(0xFFA8DCC6);
  static const Color phaseOvulation = Color(0xFFB8A4E3);
  static const Color phaseLuteal = Color(0xFFFFC8A2);

  /// Lavender (untuk fertile window overlay).
  static const Color lavender = Color(0xFFB8A4E3);
  static const Color peach = Color(0xFFFFC8A2);
  static const Color mint = Color(0xFFA8DCC6);

  // ============================================================
  // Neutrals (iOS System Grouped Background)
  // ============================================================
  /// Background utama (system grouped).
  static const Color bgGrouped = Color(0xFFF2F2F7);

  /// Background scaffold sekunder (sedikit lebih terang).
  static const Color bgPrimary = Color(0xFFFAFAFA);

  /// Card, sheet, navigation bar (sebelum blur).
  static const Color bgElevated = Color(0xFFFFFFFF);

  /// Divider tipis.
  static const Color separator = Color(0xFFE5E5EA);

  /// Divider lebih halus untuk grouped list.
  static const Color separatorOpaque = Color(0xFFC6C6C8);

  // ============================================================
  // Labels (teks)
  // ============================================================
  static const Color labelPrimary = Color(0xFF1C1C1E);
  static const Color labelSecondary = Color(0xFF6E6E73);
  static const Color labelTertiary = Color(0xFFAEAEB2);
  static const Color labelQuaternary = Color(0xFFC7C7CC);

  // ============================================================
  // Fills
  // ============================================================
  static const Color fillSubtle = Color(0xFFF2F2F7);
  static const Color fillSecondary = Color(0xFFE5E5EA);
  static const Color fillTertiary = Color(0xFFD1D1D6);

  // ============================================================
  // Status
  // ============================================================
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF0A84FF);

  // ============================================================
  // Translucency / Glass
  // ============================================================
  /// Background tab bar / nav bar dengan blur.
  static Color glassNavBar = const Color(0xFFFFFFFF).withValues(alpha: 0.72);

  /// Background modal sheet dengan blur.
  static Color glassSheet = const Color(0xFFFFFFFF).withValues(alpha: 0.85);

  /// Glass card hero (ringan).
  static Color glassCard = const Color(0xFFFFFFFF).withValues(alpha: 0.60);

  static Color glassBorder = const Color(0xFFFFFFFF).withValues(alpha: 0.50);

  // ============================================================
  // Helpers
  // ============================================================
  /// Mendapatkan warna fase berdasarkan nama fase siklus.
  static Color phaseColor(CyclePhaseColor phase) => switch (phase) {
        CyclePhaseColor.menstrual => phaseMenstrual,
        CyclePhaseColor.follicular => phaseFollicular,
        CyclePhaseColor.ovulation => phaseOvulation,
        CyclePhaseColor.luteal => phaseLuteal,
      };
}

enum CyclePhaseColor { menstrual, follicular, ovulation, luteal }
