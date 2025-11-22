import 'package:cloud_firestore/cloud_firestore.dart';

class ThemeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Karanlık mod tercihini Firestore'dan yükle
  static Future<bool> getDarkMode(String userId) async {
    try {
      final userDoc = await _firestore.collection('admin_users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data?['preferences'] != null) {
          final preferences = data!['preferences'] as Map<String, dynamic>?;
          if (preferences?['darkMode'] != null) {
            return preferences!['darkMode'] as bool;
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  // Karanlık mod tercihini Firestore'a kaydet
  static Future<void> setDarkMode(String userId, bool isDark) async {
    try {
      await _firestore.collection('admin_users').doc(userId).set({
        'preferences': {
          'darkMode': isDark,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Tema tercihi kaydedilemedi: $e');
    }
  }
  
  // Dil tercihini Firestore'dan yükle
  static Future<String> getLanguage(String userId) async {
    try {
      final userDoc = await _firestore.collection('admin_users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data?['preferences'] != null) {
          final preferences = data!['preferences'] as Map<String, dynamic>?;
          if (preferences?['language'] != null) {
            return preferences!['language'] as String;
          }
        }
      }
      return 'tr';
    } catch (e) {
      return 'tr';
    }
  }
  
  // Dil tercihini Firestore'a kaydet
  static Future<void> setLanguage(String userId, String language) async {
    try {
      await _firestore.collection('admin_users').doc(userId).set({
        'preferences': {
          'language': language,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Dil tercihi kaydedilemedi: $e');
    }
  }
  
  // 2FA durumunu Firestore'dan yükle
  static Future<bool> getTwoFactorEnabled(String userId) async {
    try {
      final userDoc = await _firestore.collection('admin_users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data?['twoFactorEnabled'] != null) {
          return data!['twoFactorEnabled'] as bool;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  // 2FA durumunu Firestore'a kaydet
  static Future<void> setTwoFactorEnabled(String userId, bool enabled) async {
    try {
      await _firestore.collection('admin_users').doc(userId).update({
        'twoFactorEnabled': enabled,
        'twoFactorUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('2FA durumu kaydedilemedi: $e');
    }
  }
  
  // Cihaz bilgilerini Firestore'dan al
  static Future<List<Map<String, dynamic>>> getDevices(String userId) async {
    try {
      final devicesSnapshot = await _firestore
          .collection('admin_users')
          .doc(userId)
          .collection('devices')
          .orderBy('lastActive', descending: true)
          .get();
      
      return devicesSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Bilinmeyen Cihaz',
          'platform': data['platform'] ?? 'Unknown',
          'lastActive': (data['lastActive'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'isCurrent': data['isCurrent'] ?? false,
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }
  
  // Cihaz bilgisini Firestore'a kaydet
  static Future<void> saveDevice(String userId, Map<String, dynamic> deviceInfo) async {
    try {
      await _firestore
          .collection('admin_users')
          .doc(userId)
          .collection('devices')
          .doc(deviceInfo['id'] as String)
          .set({
        'name': deviceInfo['name'] ?? 'Bilinmeyen Cihaz',
        'platform': deviceInfo['platform'] ?? 'Web',
        'lastActive': FieldValue.serverTimestamp(),
        'isCurrent': deviceInfo['isCurrent'] ?? true,
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Cihaz bilgisi kaydedilemedi: $e');
    }
  }
  
  // Cihazı sil
  static Future<void> removeDevice(String userId, String deviceId) async {
    try {
      await _firestore
          .collection('admin_users')
          .doc(userId)
          .collection('devices')
          .doc(deviceId)
          .delete();
    } catch (e) {
      throw Exception('Cihaz silinemedi: $e');
    }
  }
}

