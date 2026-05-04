import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import 'step_scaffold.dart';

class NameStep extends StatefulWidget {
  const NameStep({super.key, required this.initial, required this.onChanged});

  final String initial;
  final ValueChanged<String> onChanged;

  @override
  State<NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<NameStep> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      emoji: '👋',
      title: 'Apa nama panggilanmu?',
      subtitle: 'Kami akan menyapamu dengan nama ini.',
      child: CupertinoTextField(
        controller: _controller,
        autofocus: true,
        placeholder: 'Misal: Vaniola',
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        style: AppTypography.title3,
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.separator, width: 0.5),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}
