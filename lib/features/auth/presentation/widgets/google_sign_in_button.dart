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
            const _GoogleLogo(),
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

/// Logo "G" Google sederhana yang bersih tanpa asset eksternal.
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Color(0xFF4285F4), // Blue
            Color(0xFF34A853), // Green
            Color(0xFFFBBC05), // Yellow
            Color(0xFFEA4335), // Red
          ],
          stops: [0.0, 0.33, 0.66, 1.0],
        ),
      ),
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          color: CupertinoColors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          height: 1.0,
        ),
      ),
    );
  }
}
