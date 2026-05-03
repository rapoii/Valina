import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../features/auth/application/auth_providers.dart';
import '../../../partner/application/partner_providers.dart';
import '../../../partner/data/code_generator.dart';
import '../../../partner/data/partner_repository.dart';
import 'settings_tile.dart';

/// Section "Pasangan" untuk female user di Profile screen.
///
/// Menampilkan:
/// - Tombol generate kode (atau kode yang sudah ada + copy + regenerate).
/// - Privacy toggles (sharePhase, shareLogs, shareNotes).
/// - Tombol "Putuskan pasangan" kalau cewek mau revoke.
///
/// Read fields dari `ownProfileProvider`. Write via `partnerRepository` &
/// `profileRepositoryProvider`.
class PartnerSection extends ConsumerStatefulWidget {
  const PartnerSection({super.key, required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<PartnerSection> createState() => _PartnerSectionState();
}

class _PartnerSectionState extends ConsumerState<PartnerSection> {
  bool _busy = false;

  Future<void> _generateCode() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;
      final repo = ref.read(partnerRepositoryProvider);
      await repo.generateCodeForFemale(
        femaleUid: user.uid,
        previousCode: widget.profile.partnerCode,
      );
      Haptics.success();
    } on PartnerException catch (e) {
      if (mounted) _showError(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyCode() async {
    final code = widget.profile.partnerCode;
    if (code == null || code.isEmpty) return;
    await Clipboard.setData(
      ClipboardData(text: PartnerCodeGenerator.formatForDisplay(code)),
    );
    Haptics.light();
    if (!mounted) return;
    _showToast('Kode disalin');
  }

  Future<void> _confirmRegenerate() async {
    HapticFeedback.mediumImpact();
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Buat kode baru?'),
        content: const Text(
          'Kode lama tidak akan berfungsi lagi. Pasangan yang sudah terhubung '
          'dengan kode lama akan kehilangan akses.',
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
            child: const Text('Buat baru'),
          ),
        ],
      ),
    );
    if (ok == true) await _generateCode();
  }

  Future<void> _confirmRevoke() async {
    HapticFeedback.mediumImpact();
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Putuskan pasangan?'),
        content: const Text(
          'Kode akan dihapus dan pasangan tidak bisa lagi melihat data kamu. '
          'Kamu bisa generate kode baru kapan saja.',
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

    setState(() => _busy = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;
      final repo = ref.read(partnerRepositoryProvider);
      await repo.revokeFromFemale(
        femaleUid: user.uid,
        code: widget.profile.partnerCode,
      );
      Haptics.success();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleShare({
    bool? sharePhase,
    bool? shareLogs,
    bool? shareNotes,
  }) async {
    Haptics.selection();
    final updated = widget.profile.copyWith(
      sharePhase: sharePhase,
      shareLogs: shareLogs,
      shareNotes: shareNotes,
    );
    await ref.read(profileRepositoryProvider).save(updated);
  }

  void _showError(String msg) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Gagal'),
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showToast(String msg) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        bottom: 100,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.labelPrimary.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              msg,
              style: AppTypography.subheadline.copyWith(
                color: CupertinoColors.white,
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future<void>.delayed(const Duration(milliseconds: 1400), entry.remove);
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.profile.partnerCode;
    final hasCode = code != null && code.isNotEmpty;
    final linkedPartner = ref.watch(linkedPartnerInfoProvider).value;
    final isLinked = linkedPartner != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(36, 24, 20, 8),
          child: Text(
            isLinked ? 'PASANGAN TERHUBUNG' : 'PASANGAN',
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
            children: isLinked
                ? _linkedPartnerChildren(linkedPartner)
                : hasCode
                ? _activeCodeChildren(code)
                : _emptyCodeChildren(),
          ),
        ),
        if (isLinked)
          Padding(
            padding: const EdgeInsets.fromLTRB(36, 8, 20, 0),
            child: Text(
              'Pasanganmu bisa melihat data siklusmu sesuai pengaturan privasi '
              'di bawah. Putuskan koneksi kapan saja.',
              style: AppTypography.caption1.copyWith(
                color: AppColors.labelSecondary,
              ),
            ),
          ),
        if (hasCode) ...[
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.fromLTRB(36, 0, 20, 8),
            child: Text(
              'PRIVASI',
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
                _ToggleTile(
                  icon: CupertinoIcons.calendar,
                  iconColor: AppColors.accentPrimary,
                  label: 'Bagikan fase & prediksi',
                  value: widget.profile.sharePhase,
                  onChanged: (v) => _toggleShare(sharePhase: v),
                ),
                const _Separator(),
                _ToggleTile(
                  icon: CupertinoIcons.heart_fill,
                  iconColor: AppColors.peach,
                  label: 'Bagikan log harian',
                  value: widget.profile.shareLogs,
                  onChanged: (v) => _toggleShare(shareLogs: v),
                ),
                const _Separator(),
                _ToggleTile(
                  icon: CupertinoIcons.text_quote,
                  iconColor: AppColors.info,
                  label: 'Bagikan catatan pribadi',
                  value: widget.profile.shareNotes,
                  onChanged: (v) => _toggleShare(shareNotes: v),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _linkedPartnerChildren(LinkedPartnerInfo partner) {
    final initial = partner.name.isNotEmpty
        ? partner.name.characters.first.toUpperCase()
        : '?';
    final subtitle = (partner.email ?? '').isNotEmpty
        ? partner.email!
        : 'Mode hanya-baca aktif';
    return [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accentSoft,
                    AppColors.accentPrimary.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  initial,
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
                    partner.name,
                    style: AppTypography.headline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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
      ),
      const _Separator(),
      SettingsTile(
        icon: CupertinoIcons.link_circle,
        iconColor: AppColors.error,
        label: 'Putuskan pasangan',
        destructive: true,
        onTap: _busy ? null : _confirmRevoke,
      ),
    ];
  }

  List<Widget> _activeCodeChildren(String code) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kode pasanganmu',
              style: AppTypography.footnote.copyWith(
                color: AppColors.labelSecondary,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _copyCode,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        PartnerCodeGenerator.formatForDisplay(code),
                        style: AppTypography.title2.copyWith(
                          color: AppColors.accentPressed,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.doc_on_doc,
                      size: 18,
                      color: AppColors.accentPressed,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Bagikan kode ini ke pasanganmu agar dia bisa memantau siklusmu.',
              style: AppTypography.footnote.copyWith(
                color: AppColors.labelSecondary,
              ),
            ),
          ],
        ),
      ),
      const _Separator(),
      SettingsTile(
        icon: CupertinoIcons.refresh,
        iconColor: AppColors.info,
        label: 'Buat kode baru',
        onTap: _busy ? null : _confirmRegenerate,
      ),
      const _Separator(),
      SettingsTile(
        icon: CupertinoIcons.link_circle,
        iconColor: AppColors.error,
        label: 'Putuskan pasangan',
        destructive: true,
        onTap: _busy ? null : _confirmRevoke,
      ),
    ];
  }

  List<Widget> _emptyCodeChildren() {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bagikan ke pasangan', style: AppTypography.headline),
            const SizedBox(height: 6),
            Text(
              'Buat kode untuk memberi pasanganmu akses melihat kalender '
              'siklusmu (tidak bisa edit). Kamu bisa cabut kapan saja.',
              style: AppTypography.subheadline.copyWith(
                color: AppColors.labelSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
      const _Separator(),
      SettingsTile(
        icon: CupertinoIcons.link,
        iconColor: AppColors.accentPrimary,
        label: _busy ? 'Membuat kode...' : 'Buat kode',
        onTap: _busy ? null : _generateCode,
      ),
    ];
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppTypography.body)),
          CupertinoSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  // ignore: unused_element_parameter
  const _Separator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 60),
      height: 0.5,
      color: AppColors.separator,
    );
  }
}
