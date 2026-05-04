import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_x.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/models/cycle.dart';
import '../../../data/models/day_log.dart';
import '../../../data/models/enums.dart';
import '../../../data/repositories/cycle_repository.dart';
import 'widgets/chip_grid.dart';
import 'widgets/flow_picker.dart';

/// Sheet log harian — full-screen ala Apple Reminders edit.
class LogSheet extends ConsumerStatefulWidget {
  const LogSheet({super.key, required this.date});

  final DateTime date;

  static Future<void> show(BuildContext context, DateTime date) {
    return Navigator.of(context, rootNavigator: true).push<void>(
      CupertinoPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => LogSheet(date: date),
      ),
    );
  }

  @override
  ConsumerState<LogSheet> createState() => _LogSheetState();
}

class _LogSheetState extends ConsumerState<LogSheet> {
  late DayLog _log;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    // Ambil log dari cache stream provider (sudah ter-warm oleh today/calendar).
    // Kalau belum ada cache, mulai dengan empty log; nanti akan kelihatan kalau
    // data lebih dulu masuk via build().
    final cached = ref.read(logForDateProvider(widget.date));
    _log = cached.value ?? DayLog(date: widget.date.dateOnly);
    _notesController = TextEditingController(text: _log.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Defense-in-depth: male tidak boleh save log harian.
    if (ref.read(isReadOnlyProvider)) {
      Navigator.of(context).pop();
      return;
    }
    // Defense-in-depth: tidak boleh menyimpan log untuk tanggal masa depan.
    if (widget.date.isAfter(DateTime.now().dateOnly)) {
      Navigator.of(context).pop();
      return;
    }
    Haptics.success();
    _log.notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();
    await ref.read(logRepositoryProvider).save(_log);

    // Sinkronkan cycle: buat saat flow diisi, hapus (jika auto-1hari) saat flow dikosongkan.
    if (_log.flowIntensity != null) {
      await _syncCycleForLog();
    } else {
      await _removeSingleDayCycleForLog();
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _syncCycleForLog() async {
    final cycleRepo = ref.read(cycleRepositoryProvider);
    final cycles = ref.read(cyclesProvider).value ?? const <Cycle>[];
    final existing = CycleRepository.findByDateIn(cycles, widget.date);
    if (existing != null) return;
    // Buat siklus baru bila belum ada — start = today, end = today (1 hari).
    const uuid = Uuid();
    final cycle = Cycle(
      id: uuid.v4(),
      startDate: widget.date.dateOnly,
      endDate: widget.date.dateOnly,
    );
    await cycleRepo.update(cycle);
  }

  /// Hapus cycle auto-1hari bila flow dikosongkan.
  /// Hanya hapus kalau cycle itu tepat 1 hari dan tanggalnya sama persis
  /// (menghindari menghapus cycle multi-hari yang dikonfigurasi manual).
  Future<void> _removeSingleDayCycleForLog() async {
    final cycleRepo = ref.read(cycleRepositoryProvider);
    final cycles = ref.read(cyclesProvider).value ?? const <Cycle>[];
    final existing = CycleRepository.findByDateIn(cycles, widget.date);
    if (existing == null) return;
    final start = existing.startDate.dateOnly;
    final end = (existing.endDate ?? existing.startDate).dateOnly;
    // Hanya hapus kalau ini siklus 1 hari persis di tanggal ini.
    if (start.isSameDate(widget.date.dateOnly) &&
        end.isSameDate(widget.date.dateOnly)) {
      await cycleRepo.delete(existing.id);
    }
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
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Batal',
            style: TextStyle(color: AppColors.accentPrimary),
          ),
        ),
        middle: Text(
          DateFormatter.relativeDay(widget.date),
          style: AppTypography.headline,
        ),
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
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            const SectionHeader(title: 'Flow menstruasi'),
            FlowPicker(
              value: _log.flowIntensity,
              onChanged: (v) {
                Haptics.selection();
                setState(() => _log.flowIntensity = v);
              },
            ),
            const SectionHeader(title: 'Mood'),
            _buildMoodGrid(),
            const SectionHeader(title: 'Gejala fisik'),
            _buildSymptomGrid(),
            const SectionHeader(title: 'Discharge'),
            _buildDischargeRow(),
            const SectionHeader(title: 'Aktivitas seksual'),
            _buildSexualActivity(),
            const SectionHeader(title: 'Catatan'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CupertinoTextField(
                controller: _notesController,
                placeholder: 'Bagaimana harimu?',
                maxLines: 4,
                padding: const EdgeInsets.all(14),
                style: AppTypography.body,
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.separator, width: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ChipGrid<Mood>(
        options: Mood.values,
        selected: _log.moods.toSet(),
        labelOf: (m) => m.label,
        emojiOf: (m) => _moodEmoji(m),
        onToggle: (m) {
          HapticFeedback.selectionClick();
          setState(() {
            if (_log.moods.contains(m)) {
              _log.moods.remove(m);
            } else {
              _log.moods.add(m);
            }
          });
        },
      ),
    );
  }

  Widget _buildSymptomGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ChipGrid<Symptom>(
        options: Symptom.values,
        selected: _log.symptoms.toSet(),
        labelOf: (s) => s.label,
        emojiOf: (s) => _symptomEmoji(s),
        onToggle: (s) {
          HapticFeedback.selectionClick();
          setState(() {
            if (_log.symptoms.contains(s)) {
              _log.symptoms.remove(s);
            } else {
              _log.symptoms.add(s);
            }
          });
        },
      ),
    );
  }

  Widget _buildDischargeRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final d in Discharge.values)
            _SimpleChip(
              label: d.label,
              selected: _log.discharge == d,
              onTap: () {
                Haptics.selection();
                setState(() {
                  _log.discharge = _log.discharge == d ? null : d;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSexualActivity() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ChipGrid<SexualActivity>(
        options: SexualActivity.values
            .where((s) => s != SexualActivity.none)
            .toList(),
        selected: _log.sexualActivities.toSet(),
        labelOf: (s) => s.label,
        emojiOf: (s) => _sexualActivityEmoji(s),
        onToggle: (s) {
          HapticFeedback.selectionClick();
          setState(() {
            if (_log.sexualActivities.contains(s)) {
              _log.sexualActivities.remove(s);
            } else {
              _log.sexualActivities.add(s);
            }
          });
        },
      ),
    );
  }

  String _moodEmoji(Mood m) => switch (m) {
    Mood.happy => '😊',
    Mood.calm => '😌',
    Mood.energetic => '⚡',
    Mood.sad => '😢',
    Mood.anxious => '😟',
    Mood.irritable => '😤',
    Mood.tired => '😴',
  };

  String _symptomEmoji(Symptom s) => switch (s) {
    Symptom.cramps => '🌀',
    Symptom.headache => '🤕',
    Symptom.fatigue => '😩',
    Symptom.bloating => '🎈',
    Symptom.breastTenderness => '💗',
    Symptom.acne => '🧴',
    Symptom.backache => '🪨',
    Symptom.nausea => '🤢',
    Symptom.cravings => '🍫',
    Symptom.insomnia => '🌙',
  };

  String _sexualActivityEmoji(SexualActivity s) => switch (s) {
    SexualActivity.none => '🚫',
    SexualActivity.protected => '🛡️',
    SexualActivity.unprotected => '🔓',
    SexualActivity.oral => '💋',
    SexualActivity.anal => '🍑',
    SexualActivity.masturbation => '✋',
  };
}

class _SimpleChip extends StatelessWidget {
  const _SimpleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentSoft.withValues(alpha: 0.55)
              : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? AppColors.accentPrimary : AppColors.separator,
            width: selected ? 1.2 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.subheadline.copyWith(
            color: selected ? AppColors.accentPressed : AppColors.labelPrimary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
