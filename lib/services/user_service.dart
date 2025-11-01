import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/admin_user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcı ekleme
  Future<void> addUser(AdminUser user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .set(user.toFirestore());
    } catch (e) {
      throw Exception('Kullanıcı eklenirken hata oluştu: $e');
    }
  }

  // Kullanıcı güncelleme
  Future<void> updateUser(String userId, AdminUser user) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update(user.toFirestore());
    } catch (e) {
      throw Exception('Kullanıcı güncellenirken hata oluştu: $e');
    }
  }

  // Kullanıcı silme
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .delete();
    } catch (e) {
      throw Exception('Kullanıcı silinirken hata oluştu: $e');
    }
  }

  // Tüm kullanıcıları getirme
  Stream<List<AdminUser>> getUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AdminUser.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  // Tek kullanıcı getirme
  Future<AdminUser?> getUser(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      if (doc.exists) {
        return AdminUser.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Kullanıcı getirilirken hata oluştu: $e');
    }
  }

  // Kullanıcı durumu değiştirme (aktif/pasif)
  Future<void> toggleUserStatus(String userId, bool isActive) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
        'isActive': isActive,
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Kullanıcı durumu güncellenirken hata oluştu: $e');
    }
  }

  // Kullanıcı arama
  Stream<List<AdminUser>> searchUsers(String query) {
    return _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThan: query + 'z')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AdminUser.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  // Role göre kullanıcı getirme
  Stream<List<AdminUser>> getUsersByRole(String role) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: role)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AdminUser.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  // Aktif kullanıcıları getirme
  Stream<List<AdminUser>> getActiveUsers() {
    return _firestore
        .collection('users')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AdminUser.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  // Kullanıcı istatistikleri
  Future<Map<String, int>> getUserStats() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final users = usersSnapshot.docs.map((doc) {
        return AdminUser.fromFirestore(doc.data(), doc.id);
      }).toList();

      return {
        'total': users.length,
        'active': users.where((u) => u.isActive).length,
        'inactive': users.where((u) => !u.isActive).length,
        'admin': users.where((u) => u.role == 'admin').length,
        'moderator': users.where((u) => u.role == 'moderator').length,
        'user': users.where((u) => u.role == 'user').length,
      };
    } catch (e) {
      throw Exception('Kullanıcı istatistikleri alınırken hata oluştu: $e');
    }
  }
}

