import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../data/models/user_profile.dart';

class CycleSettingsScreen extends ConsumerStatefulWidget {
  const CycleSettingsScreen({super.key});

  @override
  ConsumerState<CycleSettingsScreen> createState() =>
      _CycleSettingsScreenState();
}

class _CycleSettingsScreenState extends ConsumerState<CycleSettingsScreen> {
  late final TextEditingController _nameController;
  int _cycleLength = 28;
  int _periodLength = 5;

  @override
  void initState() {
    super.initState();
    // Cycle settings selalu edit own profile (female only — male tidak boleh
    // sampai sini, sudah di-redirect oleh router).
    final profile = ref.read(ownProfileProvider).value;
    _nameController = TextEditingController(text: profile?.name ?? '');
    _cycleLength = profile?.avgCycleLength ?? 28;
    _periodLength = profile?.avgPeriodLength ?? 5;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    Haptics.success();
    final repo = ref.read(profileRepositoryProvider);
    final current =
        ref.read(ownProfileProvider).value ?? UserProfile(name: 'Sahabat');
    final updated = current.copyWith(
      name: _nameController.text.trim(),
      avgCycleLength: _cycleLength,
      avgPeriodLength: _periodLength,
    );
    await repo.save(updated);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _pickNumber({
    required int initial,
    required int min,
    required int max,
    required String unit,
    required ValueChanged<int> onPick,
  }) async {
    var picked = initial;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 280,
        padding: const EdgeInsets.only(top: 6),
        color: AppColors.bgElevated,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Batal'),
                  ),
                  const Spacer(),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      onPick(picked);
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      'Selesai',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 40,
                scrollController: FixedExtentScrollController(
                  initialItem: initial - min,
                ),
                onSelectedItemChanged: (i) => picked = min + i,
                children: List.generate(
                  max - min + 1,
                  (i) => Center(
                    child: Text('${min + i} $unit', style: AppTypography.body),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.bgGrouped,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.glassNavBar,
        border: const Border(
          bottom: BorderSide(color: AppColors.separator, width: 0.3),
        ),
        middle: const Text('Pengaturan siklus'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _save,
          child: const Text(
            'Simpan',
            style: TextStyle(
              color: AppColors.accentPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Nama panggilan',
              style: AppTypography.footnoteEmphasized.copyWith(
                color: AppColors.labelSecondary,
              ),
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: _nameController,
              placeholder: 'Nama panggilanmu',
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              style: AppTypography.body,
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.separator, width: 0.5),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Siklus & haid',
              style: AppTypography.footnoteEmphasized.copyWith(
                color: AppColors.labelSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                children: [
                  _pickerRow(
                    label: 'Panjang siklus',
                    value: '$_cycleLength hari',
                    onTap: () => _pickNumber(
                      initial: _cycleLength,
                      min: 18,
                      max: 45,
                      unit: 'hari',
                      onPick: (v) => setState(() => _cycleLength = v),
                    ),
                  ),
                  Container(
                    height: 0.5,
                    color: AppColors.separator,
                    margin: const EdgeInsets.only(left: 16),
                  ),
                  _pickerRow(
                    label: 'Lama haid',
                    value: '$_periodLength hari',
                    onTap: () => _pickNumber(
                      initial: _periodLength,
                      min: 2,
                      max: 12,
                      unit: 'hari',
                      onPick: (v) => setState(() => _periodLength = v),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Prediksi otomatis menyesuaikan saat kamu mencatat lebih banyak siklus.',
              style: AppTypography.caption1.copyWith(
                color: AppColors.labelSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickerRow({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppTypography.body)),
            Text(
              value,
              style: AppTypography.body.copyWith(
                color: AppColors.labelSecondary,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              CupertinoIcons.chevron_forward,
              size: 16,
              color: AppColors.labelTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
