import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import 'step_scaffold.dart';

class LastPeriodStep extends StatelessWidget {
  const LastPeriodStep({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  final DateTime? initial;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    // Pakai date-only (00:00:00) untuk semua bound supaya tidak kena edge
    // case `minimumDate.isAfter(initialDateTime)` yg dipicu beda time-of-day.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final minDate = today.subtract(const Duration(days: 180));

    DateTime defaultDate;
    if (initial != null) {
      final stripped = DateTime(initial!.year, initial!.month, initial!.day);
      if (stripped.isBefore(minDate)) {
        defaultDate = minDate;
      } else if (stripped.isAfter(today)) {
        defaultDate = today;
      } else {
        defaultDate = stripped;
      }
    } else {
      defaultDate = today.subtract(const Duration(days: 7));
    }

    return StepScaffold(
      emoji: '🌸',
      title: 'Kapan haid terakhirmu mulai?',
      subtitle:
          'Tanggal hari pertama haid terakhir. Tidak perlu sempurna — bisa diubah nanti.',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.separator, width: 0.5),
        ),
        clipBehavior: Clip.hardEdge,
        height: 220,
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          initialDateTime: defaultDate,
          maximumDate: today,
          minimumDate: minDate,
          onDateTimeChanged: onChanged,
        ),
      ),
    );
  }
}
