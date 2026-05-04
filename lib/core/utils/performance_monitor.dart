import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Utility untuk monitoring performa aplikasi di debug mode.
///
/// Usage: gunakan [PerformanceMonitor.trackBuildTime] di widget build
/// atau [PerformanceMonitor.trackAsync] untuk operasi async.
class PerformanceMonitor {
  PerformanceMonitor._();

  /// Threshold untuk warning build time (ms).
  static const double warningThresholdMs = 16.0;
  static const double criticalThresholdMs = 33.0; // < 30fps

  /// Log build time untuk widget
  static T trackBuildTime<T>(String widgetName, T Function() build) {
    if (!kDebugMode) return build();

    final stopwatch = Stopwatch()..start();
    final result = build();
    stopwatch.stop();

    final elapsedMs = stopwatch.elapsedMicroseconds / 1000;
    if (elapsedMs > warningThresholdMs) {
      final level = elapsedMs > criticalThresholdMs ? 'CRITICAL' : 'WARNING';
      developer.log(
        '[$level] $widgetName build took ${elapsedMs.toStringAsFixed(2)}ms',
        name: 'PerformanceMonitor',
      );
    }

    return result;
  }

  /// Track async operation
  static Future<T> trackAsync<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    if (!kDebugMode) return operation();

    final stopwatch = Stopwatch()..start();
    final result = await operation();
    stopwatch.stop();

    final elapsedMs = stopwatch.elapsedMicroseconds / 1000;
    if (elapsedMs > 100) {
      developer.log(
        'ASYNC: $operationName took ${elapsedMs.toStringAsFixed(2)}ms',
        name: 'PerformanceMonitor',
      );
    }

    return result;
  }
}
