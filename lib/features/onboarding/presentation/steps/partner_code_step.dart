import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../partner/data/code_generator.dart';
import 'step_scaffold.dart';

/// Step input kode pasangan (8 karakter, format XXXX-XXXX).
///
/// Menerima input bebas lalu otomatis normalisasi ke format yang benar.
/// Tombol lanjut di-enable hanya kalau 8 karakter valid.
class PartnerCodeStep extends StatefulWidget {
  const PartnerCodeStep({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  final String initial;
  final ValueChanged<String> onChanged;

  @override
  State<PartnerCodeStep> createState() => _PartnerCodeStepState();
}

class _PartnerCodeStepState extends State<PartnerCodeStep> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: PartnerCodeGenerator.formatForDisplay(widget.initial),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChange(String raw) {
    final normalized = PartnerCodeGenerator.normalize(raw);
    // Truncate ke 8 char agar tidak bisa ngetik lebih.
    final clipped = normalized.length > 8
        ? normalized.substring(0, 8)
        : normalized;
    final formatted = PartnerCodeGenerator.formatForDisplay(clipped);

    if (formatted != _controller.text) {
      _controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    widget.onChanged(clipped);
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      emoji: '🔗',
      title: 'Kode pasanganmu',
      subtitle:
          'Minta pasanganmu generate kode di Profile > Pasangan, lalu masukkan '
          '8 karakternya di sini.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CupertinoTextField(
            controller: _controller,
            autofocus: true,
            maxLength: 9, // 8 char + 1 dash
            textCapitalization: TextCapitalization.characters,
            keyboardType: TextInputType.visiblePassword,
            autocorrect: false,
            enableSuggestions: false,
            placeholder: 'XXXX-XXXX',
            placeholderStyle: AppTypography.title2.copyWith(
              color: AppColors.labelTertiary,
              letterSpacing: 4,
            ),
            style: AppTypography.title2.copyWith(letterSpacing: 4),
            textAlign: TextAlign.center,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.separator),
            ),
            onChanged: _handleChange,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(
                CupertinoIcons.info_circle,
                size: 16,
                color: AppColors.labelTertiary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Kode bersifat sensitif — hanya bagikan ke pasanganmu.',
                  style: AppTypography.footnote.copyWith(
                    color: AppColors.labelSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
