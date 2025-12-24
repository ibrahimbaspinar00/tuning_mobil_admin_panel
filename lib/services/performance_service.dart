import 'package:flutter/foundation.dart';
import 'dart:async';

/// Performans izleme ve optimizasyon servisi
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  final Map<String, Stopwatch> _stopwatches = {};
  final Map<String, List<Duration>> _metrics = {};

  /// İşlem başlat
  void startOperation(String operationName) {
    _stopwatches[operationName] = Stopwatch()..start();
  }

  /// İşlem bitir ve süreyi kaydet
  Duration endOperation(String operationName) {
    final stopwatch = _stopwatches.remove(operationName);
    if (stopwatch == null) {
      debugPrint('⚠️ Operation not found: $operationName');
      return Duration.zero;
    }

    stopwatch.stop();
    final duration = stopwatch.elapsed;

    // Metrikleri kaydet
    _metrics.putIfAbsent(operationName, () => []).add(duration);
    
    // Son 100 metrik tut
    if (_metrics[operationName]!.length > 100) {
      _metrics[operationName]!.removeAt(0);
    }

    debugPrint('⏱️ $operationName: ${duration.inMilliseconds}ms');
    return duration;
  }

  /// Ortalama süre hesapla
  Duration? getAverageDuration(String operationName) {
    final durations = _metrics[operationName];
    if (durations == null || durations.isEmpty) return null;

    final total = durations.fold<int>(
      0,
      (sum, duration) => sum + duration.inMilliseconds,
    );
    return Duration(milliseconds: total ~/ durations.length);
  }

  /// Metrikleri temizle
  void clearMetrics({String? operationName}) {
    if (operationName != null) {
      _metrics.remove(operationName);
    } else {
      _metrics.clear();
    }
  }

  /// Tüm metrikleri getir
  Map<String, Map<String, dynamic>> getAllMetrics() {
    final result = <String, Map<String, dynamic>>{};
    
    _metrics.forEach((operation, durations) {
      if (durations.isEmpty) return;
      
      final total = durations.fold<int>(
        0,
        (sum, duration) => sum + duration.inMilliseconds,
      );
      final average = total / durations.length;
      final min = durations.map((d) => d.inMilliseconds).reduce((a, b) => a < b ? a : b);
      final max = durations.map((d) => d.inMilliseconds).reduce((a, b) => a > b ? a : b);

      result[operation] = {
        'count': durations.length,
        'average': average,
        'min': min,
        'max': max,
        'total': total,
      };
    });

    return result;
  }

  /// Yavaş işlemleri tespit et (threshold ms'den yavaş)
  List<String> getSlowOperations({int thresholdMs = 1000}) {
    final slow = <String>[];
    
    _metrics.forEach((operation, durations) {
      final avg = getAverageDuration(operation);
      if (avg != null && avg.inMilliseconds > thresholdMs) {
        slow.add(operation);
      }
    });

    return slow;
  }
}

/// Debounce helper - Çok sık çağrılan fonksiyonları sınırla
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// Throttle helper - Belirli sürede en fazla bir kez çalıştır
class Throttler {
  final Duration delay;
  DateTime? _lastRun;

  Throttler({this.delay = const Duration(milliseconds: 300)});

  bool call(VoidCallback action) {
    final now = DateTime.now();
    if (_lastRun == null || now.difference(_lastRun!) >= delay) {
      _lastRun = now;
      action();
      return true;
    }
    return false;
  }
}

