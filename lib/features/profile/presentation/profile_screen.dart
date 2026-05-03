import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/cycle.dart';
import '../../../data/models/day_log.dart';
import '../../../data/models/enums.dart';
import '../../../features/auth/application/auth_providers.dart';
import '../../../routing/app_router.dart';
import 'widgets/partner_male_section.dart';
import 'widgets/partner_section.dart';
import 'widgets/settings_tile.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Profile screen selalu pakai OWN profile — biar male lihat info dirinya,
    // bukan info pasangan.
    final ownProfile = ref.watch(ownProfileProvider).value;
    // Cycles & logs hanya relevan untuk female (stats dirinya). Male: hide.
    final cycles = ref.watch(cyclesProvider).value ?? const <Cycle>[];
    final logs = ref.watch(allLogsProvider).value ?? const <DayLog>[];
    final user = ref.watch(currentUserProvider);

    final isMale = ownProfile?.gender == UserGender.male;
    // Untuk male: profile pasangan (bisa null kalau revoke / belum ada akses).
    final partnerProfile = isMale ? ref.watch(profileProvider).value : null;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.bgGrouped,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            backgroundColor: AppColors.glassNavBar,
            largeTitle: const Text('Saya'),
            border: const Border(),
            stretch: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                RepaintBoundary(
                  child: _ProfileHeader(
                    name: ownProfile?.name ?? 'Sahabat',
                    email: user?.email,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (!isMale)
                  RepaintBoundary(
                    child: _StatsRow(
                      cyclesCount: cycles.length,
                      logsCount: logs.length,
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                // Section pasangan tampil di bagian atas — fitur utama baru.
                if (isMale)
                  PartnerMaleSection(partnerProfile: partnerProfile)
                else if (ownProfile != null)
                  PartnerSection(profile: ownProfile),
                if (!isMale) ...[
                  SettingsSection(
                    header: 'Pengaturan',
                    children: [
                      SettingsTile(
                        icon: CupertinoIcons.heart,
                        iconColor: AppColors.accentPrimary,
                        label: 'Pengaturan siklus',
                        onTap: () => context.goNamed(AppRoute.cycleSettings),
                      ),
                      SettingsTile(
                        icon: CupertinoIcons.bell,
                        iconColor: AppColors.peach,
                        label: 'Notifikasi',
                        onTap: () =>
                            context.goNamed(AppRoute.notificationsSettings),
                      ),
                    ],
                  ),
                  SettingsSection(
                    header: 'Data',
                    children: [
                      SettingsTile(
                        icon: CupertinoIcons.delete,
                        iconColor: AppColors.error,
                        label: 'Reset semua data',
                        destructive: true,
                        onTap: () => _confirmReset(context, ref),
                      ),
                    ],
                  ),
                ],
                SettingsSection(
                  header: 'Tentang',
                  children: [
                    SettingsTile(
                      icon: CupertinoIcons.info,
                      iconColor: AppColors.info,
                      label: 'Tentang aplikasi',
                      onTap: () => context.goNamed(AppRoute.about),
                    ),
                  ],
                ),
                SettingsSection(
                  header: 'Akun',
                  children: [
                    SettingsTile(
                      icon: CupertinoIcons.square_arrow_right,
                      iconColor: AppColors.error,
                      label: 'Keluar',
                      destructive: true,
                      onTap: () => _confirmSignOut(context, ref),
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    HapticFeedback.heavyImpact();
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Reset semua data?'),
        content: const Text(
          'Semua siklus, log harian, dan profil akan dihapus permanen. '
          'Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(cycleRepositoryProvider).clearAll();
              await ref.read(logRepositoryProvider).clearAll();
              await ref.read(profileRepositoryProvider).clear();
              if (!context.mounted) return;
              // Setelah profile clear, router redirect otomatis ke /onboarding.
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Kamu akan keluar dari akun ini. Data tetap aman di cloud dan bisa diakses lagi saat login.',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authRepositoryProvider).signOut();
              // Router redirect otomatis ke /login.
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.name, this.email});

  final String name;
  final String? email;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accentSoft,
                  AppColors.accentPrimary.withValues(alpha: 0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: AppTypography.title1.copyWith(
                  color: CupertinoColors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTypography.title2),
                const SizedBox(height: 2),
                Text(
                  email ?? 'Tersinkronisasi di cloud',
                  style: AppTypography.footnote.copyWith(
                    color: AppColors.labelSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.cyclesCount, required this.logsCount});

  final int cyclesCount;
  final int logsCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _StatPill(
              icon: CupertinoIcons.calendar,
              value: '$cyclesCount',
              label: 'Siklus',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatPill(
              icon: CupertinoIcons.heart,
              value: '$logsCount',
              label: 'Log',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadow.subtle,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.accentPrimary),
          const SizedBox(width: 8),
          Text(value, style: AppTypography.title3),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.subheadline.copyWith(
              color: AppColors.labelSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
