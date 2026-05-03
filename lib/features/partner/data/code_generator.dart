import 'dart:math';

/// Generator kode pasangan 8-char uppercase alfanumerik.
///
/// Charset sengaja exclude karakter ambigu: `0` (nol) vs `O`, `1` vs `I` / `L`,
/// supaya user tidak salah ketik saat berbagi kode verbal / screenshot.
class PartnerCodeGenerator {
  PartnerCodeGenerator({Random? random}) : _random = random ?? Random.secure();

  /// 32 karakter (lebih dari cukup, dan semuanya unambiguous).
  static const _charset = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  static const _length = 8;

  final Random _random;

  /// Generate satu kode random 8 karakter (tanpa dash).
  String generate() {
    final buf = StringBuffer();
    for (var i = 0; i < _length; i++) {
      buf.write(_charset[_random.nextInt(_charset.length)]);
    }
    return buf.toString();
  }

  /// Format untuk display: `XXXX-XXXX` biar enak dibaca.
  static String formatForDisplay(String code) {
    final clean = code.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (clean.length != _length) return code;
    return '${clean.substring(0, 4)}-${clean.substring(4)}';
  }

  /// Normalisasi input user: uppercase + strip dash/spasi.
  static String normalize(String input) {
    return input.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  /// Validasi format (setelah normalize): panjang 8 dan semua char valid.
  static bool isValid(String input) {
    final normalized = normalize(input);
    if (normalized.length != _length) return false;
    for (final c in normalized.split('')) {
      if (!_charset.contains(c)) return false;
    }
    return true;
  }
}
