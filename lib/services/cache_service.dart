import 'dart:async';
import 'package:flutter/foundation.dart';

/// Performans optimizasyonu için cache servisi
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // Cache storage
  final Map<String, _CacheItem> _cache = {};
  final Map<String, Timer> _timers = {};

  // Cache configuration
  static const Duration defaultTtl = Duration(minutes: 5);
  static const int maxCacheSize = 100; // Maximum number of cached items

  /// Cache'e veri ekle
  void set<T>(String key, T value, {Duration? ttl}) {
    final cacheTtl = ttl ?? defaultTtl;
    
    // Cache boyutu kontrolü
    if (_cache.length >= maxCacheSize) {
      _evictOldest();
    }

    // Eski timer'ı iptal et
    _timers[key]?.cancel();

    // Yeni cache item oluştur
    _cache[key] = _CacheItem<T>(
      value: value,
      timestamp: DateTime.now(),
      ttl: cacheTtl,
    );

    // TTL sonrası otomatik silme
    _timers[key] = Timer(cacheTtl, () {
      _cache.remove(key);
      _timers.remove(key);
    });

    debugPrint('✅ Cache set: $key (TTL: ${cacheTtl.inMinutes} min)');
  }

  /// Cache'den veri al
  T? get<T>(String key) {
    final item = _cache[key];
    
    if (item == null) {
      debugPrint('❌ Cache miss: $key');
      return null;
    }

    // TTL kontrolü
    if (DateTime.now().difference(item.timestamp) > item.ttl) {
      debugPrint('⏰ Cache expired: $key');
      _cache.remove(key);
      _timers[key]?.cancel();
      _timers.remove(key);
      return null;
    }

    debugPrint('✅ Cache hit: $key');
    return item.value as T;
  }

  /// Cache'den veri al veya yoksa oluştur
  Future<T> getOrSet<T>(
    String key,
    Future<T> Function() fetcher, {
    Duration? ttl,
  }) async {
    final cached = get<T>(key);
    if (cached != null) {
      return cached;
    }

    final value = await fetcher();
    set(key, value, ttl: ttl);
    return value;
  }

  /// Cache'i temizle
  void clear({String? key}) {
    if (key != null) {
      _cache.remove(key);
      _timers[key]?.cancel();
      _timers.remove(key);
      debugPrint('🗑️ Cache cleared: $key');
    } else {
      _cache.clear();
      for (final timer in _timers.values) {
        timer.cancel();
      }
      _timers.clear();
      debugPrint('🗑️ All cache cleared');
    }
  }

  /// Belirli pattern'e uyan cache'leri temizle
  void clearPattern(String pattern) {
    final keysToRemove = _cache.keys.where((key) => key.contains(pattern)).toList();
    for (final key in keysToRemove) {
      clear(key: key);
    }
    debugPrint('🗑️ Cache cleared for pattern: $pattern');
  }

  /// En eski cache item'ı sil
  void _evictOldest() {
    if (_cache.isEmpty) return;

    String? oldestKey;
    DateTime? oldestTime;

    _cache.forEach((key, item) {
      if (oldestTime == null || item.timestamp.isBefore(oldestTime!)) {
        oldestTime = item.timestamp;
        oldestKey = key;
      }
    });

    if (oldestKey != null) {
      clear(key: oldestKey);
      debugPrint('🗑️ Evicted oldest cache: $oldestKey');
    }
  }

  /// Cache istatistikleri
  Map<String, dynamic> getStats() {
    return {
      'size': _cache.length,
      'maxSize': maxCacheSize,
      'keys': _cache.keys.toList(),
    };
  }
}

class _CacheItem<T> {
  final T value;
  final DateTime timestamp;
  final Duration ttl;

  _CacheItem({
    required this.value,
    required this.timestamp,
    required this.ttl,
  });
}

