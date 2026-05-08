import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

enum DevicePerformanceTier {
  /// Low-end device (<= 2GB RAM atau old CPU).
  /// Reduce shadows, disable BackdropFilter, skip animations.
  low,

  /// Mid-range device (3-6GB RAM).
  /// Standard quality.
  medium,

  /// High-end device (> 6GB RAM, latest CPU).
  /// Full quality, 120Hz+.
  high,
}

class DeviceTier {
  static DevicePerformanceTier _currentTier = DevicePerformanceTier.medium;
  static bool _initialized = false;

  /// Inisialisasi device tier (dipanggil di `main.dart` atau `App`).
  static Future<void> init() async {
    if (_initialized) return;

    try {
      if (kIsWeb) {
        _currentTier = DevicePerformanceTier.medium;
      } else if (Platform.isAndroid) {
        // Total physical memory (bytes).
        // Kalau memori <= 2.5GB (2500 MB), masuk low-end.
        // Fallback ke low kalau tidak bisa baca sysinfo.
        // Coba baca dari /proc/meminfo langsung karena Android API kadang tidak akurat
        int ramMB = 4000;
        try {
          final memInfo = await File('/proc/meminfo').readAsString();
          final match = RegExp(r'MemTotal:\s+(\d+)\s+kB').firstMatch(memInfo);
          if (match != null) {
            ramMB = int.parse(match.group(1)!) ~/ 1024;
          }
        } catch (_) {
          // Ignore
        }

        if (ramMB <= 2500) {
          _currentTier = DevicePerformanceTier.low;
        } else if (ramMB <= 6000) {
          _currentTier = DevicePerformanceTier.medium;
        } else {
          _currentTier = DevicePerformanceTier.high;
        }
      } else if (Platform.isIOS) {
        final info = await DeviceInfoPlugin().iosInfo;
        // iPhone SE 1st gen, iPhone 6s = 2GB RAM
        // Model iPhone bisa di-map manual, tapi sebagai general rule,
        // iOS device sangat efisien. Kita bisa asumsi medium/high kecuali
        // model lama (iPhone 6/7/8).
        final machine = info.utsname.machine;
        if (machine.startsWith('iPhone8') || machine.startsWith('iPhone9')) {
          _currentTier = DevicePerformanceTier.low;
        } else {
          _currentTier = DevicePerformanceTier.high;
        }
      }
    } catch (e) {
      debugPrint('Error detecting device tier: $e');
    } finally {
      _initialized = true;
      debugPrint('Device Tier Detected: $_currentTier');
    }
  }

  static bool get isLowEnd => _currentTier == DevicePerformanceTier.low;
  static bool get isHighEnd => _currentTier == DevicePerformanceTier.high;
  static DevicePerformanceTier get tier => _currentTier;
}
