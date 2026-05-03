import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../features/auth/application/auth_providers.dart';
import '../../../partner/application/partner_providers.dart';
import 'settings_tile.dart';

/// Section "Pasangan terhubung" untuk male user di Profile screen.
class PartnerMaleSection extends ConsumerWidget {
  const PartnerMaleSection({super.key, required this.partnerProfile});

  /// Profile pasangan (cewek) yang sedang dipantau. Bisa null kalau partner
  /// data tidak bisa dibaca (mis. cewek revoke).
  final UserProfile? partnerProfile;

  Future<void> _confirmDisconnect(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Putuskan koneksi?'),
        content: const Text(
          'Kamu akan kehilangan akses ke kalender pasangan. Untuk terhubung '
          'kembali, kamu perlu memasukkan kode lagi.',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Putuskan'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final repo = ref.read(partnerRepositoryProvider);
    await repo.revokeFromMale(maleUid: user.uid);
    Haptics.success();
    // Router redirect otomatis ke /onboarding karena partnerUid sekarang null.
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnerName = partnerProfile?.name ?? 'Pasangan';
    final partnerInitial = partnerName.isNotEmpty
        ? partnerName[0].toUpperCase()
        : '?';
    final notFound = partnerProfile == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(36, 24, 20, 8),
          child: Text(
            'PASANGAN TERHUBUNG',
            style: AppTypography.caption2.copyWith(
              color: AppColors.labelSecondary,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: notFound
                              ? [AppColors.error, AppColors.peach]
                              : [
                                  AppColors.accentSoft,
                                  AppColors.accentPrimary.withValues(
                                    alpha: 0.7,
                                  ),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          notFound ? '!' : partnerInitial,
                          style: AppTypography.title2.copyWith(
                            color: CupertinoColors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notFound ? 'Pasangan tidak ditemukan' : partnerName,
                            style: AppTypography.headline,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            notFound
                                ? 'Mungkin pasangan sudah memutuskan koneksi'
                                : 'Mode hanya-baca aktif',
                            style: AppTypography.footnote.copyWith(
                              color: AppColors.labelSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 60),
                height: 0.5,
                color: AppColors.separator,
              ),
              SettingsTile(
                icon: CupertinoIcons.link_circle,
                iconColor: AppColors.error,
                label: 'Putuskan koneksi',
                destructive: true,
                onTap: () => _confirmDisconnect(context, ref),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(36, 8, 20, 0),
          child: Text(
            'Kamu hanya bisa melihat data — tidak bisa mengubah, menambah, '
            'atau menghapus apapun di kalender pasangan.',
            style: AppTypography.caption1.copyWith(
              color: AppColors.labelSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
