import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuditLogService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Audit log kaydet
  static Future<void> logAction({
    required String userId,
    required String action,
    required String resource,
    Map<String, dynamic>? details,
    String? ipAddress,
  }) async {
    try {
      await _firestore.collection('audit_logs').add({
        'userId': userId,
        'action': action, // 'create', 'update', 'delete', 'view', 'login', 'logout'
        'resource': resource, // 'product', 'order', 'user', 'settings'
        'details': details ?? {},
        'ipAddress': ipAddress,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Audit log hatası uygulamayı durdurmamalı
      debugPrint('Audit log kaydedilemedi: $e');
    }
  }
  
  // Audit logları getir
  static Stream<List<Map<String, dynamic>>> getAuditLogs({
    String? userId,
    String? action,
    String? resource,
    int? limit,
  }) {
    Query query = _firestore.collection('audit_logs');
    
    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }
    if (action != null) {
      query = query.where('action', isEqualTo: action);
    }
    if (resource != null) {
      query = query.where('resource', isEqualTo: resource);
    }
    
    query = query.orderBy('timestamp', descending: true);
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) {
          return <String, dynamic>{
            'id': doc.id,
            'userId': 'unknown',
            'action': 'unknown',
            'resource': 'unknown',
            'details': <String, dynamic>{},
            'ipAddress': null,
            'timestamp': DateTime.now(),
          };
        }
        return {
          'id': doc.id,
          'userId': data['userId'] ?? 'unknown',
          'action': data['action'] ?? 'unknown',
          'resource': data['resource'] ?? 'unknown',
          'details': data['details'] ?? <String, dynamic>{},
          'ipAddress': data['ipAddress'],
          'timestamp': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
    });
  }
}

