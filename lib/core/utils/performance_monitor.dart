import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Utility untuk monitoring performa aplikasi di debug mode.
///
/// Usage: Tambahkan [PerformanceMonitor.wrap] di root aplikasi
/// atau gunakan [PerformanceMonitor.reportBuildTime] di widget build.
class PerformanceMonitor {
  PerformanceMonitor._();

  /// Frame timing constants untuk 60fps
  static const double targetFrameTimeMs = 16.67; // 1000ms / 60fps
  static const double warningThresholdMs = 16.0;
  static const double criticalThresholdMs = 33.0; // < 30fps

  /// Wrap aplikasi dengan performance monitoring
  static Widget wrap(Widget child) {
    if (!kDebugMode) return child;

    return Stack(
      children: [
        child,
        const Positioned.fill(
          child: Align(
            alignment: Alignment.topLeft,
            child: PerformanceOverlay(),
          ),
        ),
      ],
    );
  }

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

/// Mixin untuk tracking rebuild count pada widget
mixin RebuildTracker<T extends StatefulWidget> on State<T> {
  int _rebuildCount = 0;
  final Map<String, int> _providerRebuilds = {};

  @override
  void setState(VoidCallback fn) {
    _rebuildCount++;
    if (kDebugMode && _rebuildCount % 30 == 0) {
      developer.log(
        '${widget.runtimeType} rebuilt $_rebuildCount times',
        name: 'RebuildTracker',
      );
    }
    super.setState(fn);
  }

  void trackProviderRebuild(String providerName) {
    if (!kDebugMode) return;
    _providerRebuilds[providerName] =
        (_providerRebuilds[providerName] ?? 0) + 1;
  }
}
