import 'package:intl/intl.dart';

/// Extension & utility tanggal yang sering dipakai.
extension DateOnlyX on DateTime {
  /// Mengembalikan DateTime dengan komponen waktu di-zero (00:00:00).
  DateTime get dateOnly => DateTime(year, month, day);

  /// True bila tanggal sama (mengabaikan waktu).
  bool isSameDate(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  /// Selisih hari (kalender, bukan jam) antara dua tanggal.
  int daysBetween(DateTime other) {
    final a = dateOnly;
    final b = other.dateOnly;
    return b.difference(a).inDays;
  }

  /// Tanggal awal bulan.
  DateTime get firstDayOfMonth => DateTime(year, month);

  /// Tanggal akhir bulan.
  DateTime get lastDayOfMonth => DateTime(year, month + 1, 0);
}

abstract final class DateFormatter {
  static final _dayMonth = DateFormat('d MMM', 'id_ID');
  static final _dayMonthYear = DateFormat('d MMMM y', 'id_ID');
  static final _fullDay = DateFormat('EEEE, d MMMM', 'id_ID');
  static final _monthYear = DateFormat('MMMM y', 'id_ID');
  static final _shortDay = DateFormat('EEE', 'id_ID');

  static String dayMonth(DateTime d) => _dayMonth.format(d);
  static String dayMonthYear(DateTime d) => _dayMonthYear.format(d);
  static String fullDay(DateTime d) => _fullDay.format(d);
  static String monthYear(DateTime d) => _monthYear.format(d);
  static String shortDay(DateTime d) => _shortDay.format(d);

  /// "Hari ini", "Kemarin", atau format tanggal.
  static String relativeDay(DateTime d) {
    final today = DateTime.now().dateOnly;
    final target = d.dateOnly;
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Hari ini';
    if (diff == -1) return 'Kemarin';
    if (diff == 1) return 'Besok';
    if (diff > 1 && diff <= 6) return '$diff hari lagi';
    if (diff < -1 && diff >= -6) return '${-diff} hari lalu';
    return dayMonth(d);
  }
}
