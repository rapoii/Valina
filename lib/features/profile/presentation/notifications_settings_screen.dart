import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../data/models/user_profile.dart';
import '../../notifications/notification_service.dart';
import 'widgets/settings_tile.dart';

class NotificationsSettingsScreen extends ConsumerStatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  ConsumerState<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends ConsumerState<NotificationsSettingsScreen> {
  Future<void> _persist(UserProfile updated) async {
    await ref.read(profileRepositoryProvider).save(updated);
    final forecast = ref.read(todayForecastProvider);
    await NotificationService.instance.rescheduleAll(
      profile: updated,
      forecast: forecast,
    );
  }

  Future<void> _persistReminderChange(UserProfile updated) async {
    final needsPermission =
        updated.periodReminderEnabled ||
        updated.ovulationReminderEnabled ||
        updated.dailyReminderEnabled;
    if (needsPermission) {
      final allowed = await NotificationService.instance.requestPermission();
      if (!allowed) {
        if (!mounted) return;
        await showCupertinoDialog<void>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Izin notifikasi dibutuhkan'),
            content: const Text(
              'Aktifkan izin notifikasi dari pengaturan sistem agar reminder bisa berjalan.',
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
    }
    await _persist(updated);
  }

  Future<void> _pickTime(UserProfile profile) async {
    var picked = DateTime(
      2024,
      1,
      1,
      profile.dailyReminderHour,
      profile.dailyReminderMinute,
    );
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 300,
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
                    onPressed: () async {
                      Navigator.pop(ctx);
                      Haptics.success();
                      final updated = profile.copyWith(
                        dailyReminderHour: picked.hour,
                        dailyReminderMinute: picked.minute,
                      );
                      await _persist(updated);
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
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: picked,
                use24hFormat: true,
                onDateTimeChanged: (d) => picked = d,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Notifikasi adalah preferensi own user, bukan pasangan.
    final profile = ref.watch(ownProfileProvider).value;
    if (profile == null) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
    final timeLabel =
        '${profile.dailyReminderHour.toString().padLeft(2, '0')}:${profile.dailyReminderMinute.toString().padLeft(2, '0')}';

    return CupertinoPageScaffold(
      backgroundColor: AppColors.bgGrouped,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.glassNavBar,
        border: const Border(
          bottom: BorderSide(color: AppColors.separator, width: 0.3),
        ),
        middle: const Text('Notifikasi'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(top: 12, bottom: 60),
          children: [
            SettingsSection(
              header: 'Reminder siklus',
              children: [
                SettingsTile(
                  icon: CupertinoIcons.drop,
                  iconColor: AppColors.phaseMenstrual,
                  label: 'Pengingat haid',
                  trailing: CupertinoSwitch(
                    value: profile.periodReminderEnabled,
                    activeTrackColor: AppColors.accentPrimary,
                    onChanged: (v) async {
                      Haptics.selection();
                      await _persistReminderChange(
                        profile.copyWith(periodReminderEnabled: v),
                      );
                    },
                  ),
                ),
                SettingsTile(
                  icon: CupertinoIcons.sparkles,
                  iconColor: AppColors.lavender,
                  label: 'Pengingat ovulasi',
                  trailing: CupertinoSwitch(
                    value: profile.ovulationReminderEnabled,
                    activeTrackColor: AppColors.accentPrimary,
                    onChanged: (v) async {
                      Haptics.selection();
                      await _persistReminderChange(
                        profile.copyWith(ovulationReminderEnabled: v),
                      );
                    },
                  ),
                ),
              ],
            ),
            SettingsSection(
              header: 'Reminder harian',
              footer:
                  'Aplikasi akan mengingatkanmu setiap hari pada jam yang dipilih.',
              children: [
                SettingsTile(
                  icon: CupertinoIcons.clock,
                  iconColor: AppColors.accentPrimary,
                  label: 'Aktifkan reminder log',
                  trailing: CupertinoSwitch(
                    value: profile.dailyReminderEnabled,
                    activeTrackColor: AppColors.accentPrimary,
                    onChanged: (v) async {
                      Haptics.selection();
                      await _persistReminderChange(
                        profile.copyWith(dailyReminderEnabled: v),
                      );
                    },
                  ),
                ),
                if (profile.dailyReminderEnabled)
                  SettingsTile(
                    icon: CupertinoIcons.bell,
                    iconColor: AppColors.peach,
                    label: 'Waktu reminder',
                    value: timeLabel,
                    onTap: () => _pickTime(profile),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Text(
                'Beberapa perangkat membutuhkan izin notifikasi tambahan. '
                'Pastikan kamu mengizinkan notifikasi dari pengaturan sistem.',
                style: AppTypography.caption1.copyWith(
                  color: AppColors.labelSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
