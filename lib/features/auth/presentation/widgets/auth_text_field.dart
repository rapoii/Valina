import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';

/// Text field bergaya iOS yang konsisten untuk halaman auth.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.placeholder,
    this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String? placeholder;
  final IconData? icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: AppTypography.footnoteEmphasized.copyWith(
              color: AppColors.labelSecondary,
            ),
          ),
        ),
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          keyboardType: keyboardType,
          obscureText: obscureText,
          autofillHints: autofillHints,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          enabled: enabled,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          style: AppTypography.body,
          placeholderStyle: AppTypography.body.copyWith(
            color: AppColors.labelTertiary,
          ),
          prefix: icon == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Icon(
                    icon,
                    size: 18,
                    color: AppColors.labelSecondary,
                  ),
                ),
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.separator),
          ),
        ),
      ],
    );
  }
}
