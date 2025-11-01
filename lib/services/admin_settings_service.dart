import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/admin_settings.dart';

class AdminSettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'admin_settings';

  // Admin ayarlarını getir
  Future<AdminSettings?> getAdminSettings() async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc('main')
          .get();
      
      if (doc.exists) {
        return AdminSettings.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Admin ayarları getirilirken hata: $e');
      return null;
    }
  }

  // Admin ayarlarını güncelle
  Future<void> updateAdminSettings(AdminSettings settings) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc('main')
          .set(settings.toFirestore());
    } catch (e) {
      throw Exception('Admin ayarları güncellenirken hata oluştu: $e');
    }
  }

  // Admin kullanıcı adını güncelle
  Future<void> updateAdminUsername(String newUsername) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc('main')
          .update({
        'adminUsername': newUsername,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Admin kullanıcı adı güncellenirken hata oluştu: $e');
    }
  }

  // Admin şifresini güncelle
  Future<void> updateAdminPassword(String newPassword) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc('main')
          .update({
        'adminPassword': newPassword,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Admin şifresi güncellenirken hata oluştu: $e');
    }
  }

  // Varsayılan admin ayarlarını oluştur
  Future<void> createDefaultAdminSettings() async {
    try {
      final defaultSettings = AdminSettings(
        id: 'main',
        adminUsername: 'admin',
        adminPassword: 'admin123',
        lastUpdated: DateTime.now(),
      );
      
      await _firestore
          .collection(_collectionName)
          .doc('main')
          .set(defaultSettings.toFirestore());
    } catch (e) {
      throw Exception('Varsayılan admin ayarları oluşturulurken hata oluştu: $e');
    }
  }

  // Admin ayarlarını sil
  Future<void> deleteAdminSettings() async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc('main')
          .delete();
    } catch (e) {
      throw Exception('Admin ayarları silinirken hata oluştu: $e');
    }
  }
}
