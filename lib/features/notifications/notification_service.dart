import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../core/utils/cycle_calculator.dart';
import '../../data/models/user_profile.dart';

/// Service notifikasi lokal untuk reminder haid, ovulasi, dan log harian.
/// Pada platform web, semua method menjadi no-op (notifikasi tidak didukung).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb) {
      _initialized = true;
      return;
    }
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    await init();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      return result ?? false;
    }
    return false;
  }

  /// Jadwalkan ulang semua reminder berdasarkan profile + forecast.
  Future<void> rescheduleAll({
    required UserProfile profile,
    required CycleForecast forecast,
  }) async {
    if (kIsWeb) return;
    await init();
    await _plugin.cancelAll();

    if (profile.periodReminderEnabled) {
      await _scheduleAtDate(
        id: 1001,
        title: 'Haid mungkin mulai besok 🌸',
        body: 'Siapkan dirimu — prediksi haid besok berdasarkan siklusmu.',
        date: forecast.nextPeriodStart.subtract(const Duration(days: 1)),
        atHour: 9,
      );
      await _scheduleAtDate(
        id: 1002,
        title: 'Hari prediksi haid 🌸',
        body: 'Catat hari pertama haidmu untuk akurasi prediksi.',
        date: forecast.nextPeriodStart,
        atHour: 9,
      );
    }

    if (profile.ovulationReminderEnabled) {
      await _scheduleAtDate(
        id: 1003,
        title: 'Fertile window dimulai ✨',
        body: 'Periode subur dimulai hari ini.',
        date: forecast.fertileWindowStart,
        atHour: 9,
      );
      await _scheduleAtDate(
        id: 1004,
        title: 'Ovulasi hari ini ✨',
        body: 'Suhu basal mungkin naik. Yuk catat datanya.',
        date: forecast.ovulationDate,
        atHour: 9,
      );
    }

    if (profile.dailyReminderEnabled) {
      await _scheduleDaily(
        id: 1005,
        title: 'Saatnya catat hari ini 📝',
        body: 'Bagaimana mood & tubuhmu hari ini?',
        hour: profile.dailyReminderHour,
        minute: profile.dailyReminderMinute,
      );
    }
  }

  Future<void> _scheduleAtDate({
    required int id,
    required String title,
    required String body,
    required DateTime date,
    required int atHour,
  }) async {
    final tzDate = tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      atHour,
    );
    if (tzDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        debugPrint('Schedule error: $e');
      }
    }
  }

  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var first = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (first.isBefore(now)) {
      first = first.add(const Duration(days: 1));
    }
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        first,
        _details(),
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Schedule daily error: $e');
    }
  }

  NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'cycle_reminders',
        'Pengingat Siklus',
        channelDescription: 'Pengingat haid, ovulasi, dan log harian.',
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await init();
    await _plugin.cancelAll();
  }
}
