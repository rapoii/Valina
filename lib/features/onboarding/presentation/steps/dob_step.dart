import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import 'step_scaffold.dart';

class DobStep extends StatelessWidget {
  const DobStep({super.key, required this.initial, required this.onChanged});

  final DateTime? initial;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Default ke umur 22 tahun (date-only).
    DateTime defaultDate;
    if (initial != null) {
      final stripped = DateTime(initial!.year, initial!.month, initial!.day);
      defaultDate = stripped.isAfter(today) ? today : stripped;
    } else {
      defaultDate = DateTime(now.year - 22, now.month, now.day);
    }
    return StepScaffold(
      emoji: '🎂',
      title: 'Kapan kamu lahir?',
      subtitle: 'Membantu kami menyesuaikan rekomendasi dengan usiamu.',
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
          minimumYear: now.year - 70,
          maximumYear: now.year - 8,
          onDateTimeChanged: onChanged,
        ),
      ),
    );
  }
}
