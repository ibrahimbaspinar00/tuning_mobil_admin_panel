import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class RateLimitService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Map<String, List<DateTime>> _requestHistory = {};
  static final Map<String, Timer> _cleanupTimers = {};
  
  // Rate limit kontrolü
  static Future<bool> checkRateLimit({
    required String identifier, // IP address veya user ID
    required int maxRequests,
    required Duration window,
  }) async {
    final now = DateTime.now();
    final key = identifier;
    
    // Memory'deki geçmişi temizle
    _requestHistory[key] = _requestHistory[key]?.where((timestamp) {
      return now.difference(timestamp) < window;
    }).toList() ?? [];
    
    // Firestore'dan da kontrol et (daha güvenilir)
    try {
      final logsSnapshot = await _firestore
          .collection('rate_limit_logs')
          .where('identifier', isEqualTo: identifier)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(now.subtract(window)))
          .get();
      
      final firestoreCount = logsSnapshot.docs.length;
      
      // Memory ve Firestore toplamı
      final totalCount = (_requestHistory[key]?.length ?? 0) + firestoreCount;
      
      if (totalCount >= maxRequests) {
        // Rate limit aşıldı
        await _logRateLimit(identifier, false);
        return false;
      }
      
      // İsteği kaydet
      _requestHistory[key] = (_requestHistory[key] ?? [])..add(now);
      await _logRateLimit(identifier, true);
      
      // Cleanup timer
      _cleanupTimers[key]?.cancel();
      _cleanupTimers[key] = Timer(window, () {
        _requestHistory.remove(key);
        _cleanupTimers.remove(key);
      });
      
      return true;
    } catch (e) {
      // Firestore hatası durumunda memory'den kontrol et
      final memoryCount = _requestHistory[key]?.length ?? 0;
      if (memoryCount >= maxRequests) {
        return false;
      }
      
      _requestHistory[key] = (_requestHistory[key] ?? [])..add(now);
      return true;
    }
  }
  
  // Rate limit log kaydet
  static Future<void> _logRateLimit(String identifier, bool allowed) async {
    try {
      await _firestore.collection('rate_limit_logs').add({
        'identifier': identifier,
        'allowed': allowed,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Eski logları temizle (30 günden eski)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final oldLogs = await _firestore
          .collection('rate_limit_logs')
          .where('timestamp', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .limit(100)
          .get();
      
      for (var doc in oldLogs.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      // Rate limit log hatası uygulamayı durdurmamalı
      debugPrint('Rate limit log kaydedilemedi: $e');
    }
  }
  
  // IP adresini al (web için)
  static String? getClientIP() {
    // Web için IP adresi alınamaz (güvenlik nedeniyle)
    // Bu durumda session ID veya user ID kullanılabilir
    return null;
  }
}

