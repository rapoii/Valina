import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';

/// Tombol "Lanjutkan dengan Google" bergaya iOS.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    this.onPressed,
    this.loading = false,
    this.label = 'Lanjutkan dengan Google',
  });

  final VoidCallback? onPressed;
  final bool loading;
  final String label;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      borderRadius: BorderRadius.circular(AppRadius.md),
      color: AppColors.bgElevated,
      minimumSize: const Size.fromHeight(52),
      onPressed: (onPressed == null || loading)
          ? null
          : () {
              HapticFeedback.lightImpact();
              onPressed!();
            },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading)
            const CupertinoActivityIndicator(radius: 9)
          else ...[
            Image.asset(
              'assets/images/google-color.png',
              width: 22,
              height: 22,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTypography.headline.copyWith(
                color: AppColors.labelPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
