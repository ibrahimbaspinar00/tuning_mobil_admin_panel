import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../model/mobile_user.dart';

class MobileUserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tüm mobil kullanıcıları getir
  Stream<List<MobileUser>> getUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) {
      final users = snapshot.docs.map((doc) {
        try {
          return MobileUser.fromFirestore(doc.data(), doc.id);
        } catch (e) {
          // Eğer veri yapısı uyumsuzsa null döndür ve filtrele
          debugPrint('⚠️ Kullanıcı parse hatası: $e');
          return null;
        }
      }).whereType<MobileUser>().toList();
      users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return users;
    });
  }

  // Kullanıcı sayısını getir
  Future<int> getUserCount() async {
    try {
      final snapshot = await _firestore.collection('users').count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Kullanıcı sayısı alınırken hata oluştu: $e');
    }
  }

  // Tek kullanıcı getir
  Future<MobileUser?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return MobileUser.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Kullanıcı getirilirken hata oluştu: $e');
    }
  }

  // Kullanıcı arama
  Future<List<MobileUser>> searchUsers(String query) async {
    try {
      final snapshot = await _firestore.collection('users').get();
      final allUsers = snapshot.docs
          .map((doc) {
            try {
              return MobileUser.fromFirestore(doc.data(), doc.id);
            } catch (e) {
              return null;
            }
          })
          .whereType<MobileUser>()
          .toList();

      final lowerQuery = query.toLowerCase();
      return allUsers.where((user) {
        final username = user.username?.toLowerCase() ?? '';
        final email = user.email?.toLowerCase() ?? '';
        final phone = user.phoneNumber?.toLowerCase() ?? '';
        final name = user.fullName?.toLowerCase() ?? '';
        return username.contains(lowerQuery) ||
            email.contains(lowerQuery) ||
            phone.contains(lowerQuery) ||
            name.contains(lowerQuery);
      }).toList();
    } catch (e) {
      throw Exception('Kullanıcı arama hatası: $e');
    }
  }

  // Kullanıcı güncelle
  Future<void> updateUser(MobileUser user) async {
    try {
      if (user.id.isEmpty) {
        throw Exception('Kullanıcı ID\'si bulunamadı');
      }

      await _firestore
          .collection('users')
          .doc(user.id)
          .update(user.toFirestore());
    } catch (e) {
      throw Exception('Kullanıcı güncellenirken hata oluştu: $e');
    }
  }

  // Şifre değiştir (eğer şifre alanı varsa)
  Future<void> changePassword(String userId, String newPassword) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'password': newPassword,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Şifre değiştirilirken hata oluştu: $e');
    }
  }

  // E-posta güncelle
  Future<void> updateEmail(String userId, String newEmail) async {
    try {
      // E-posta kontrolü
      final existingUsers = await _firestore
          .collection('users')
          .where('email', isEqualTo: newEmail)
          .limit(1)
          .get();

      if (existingUsers.docs.isNotEmpty &&
          existingUsers.docs.first.id != userId) {
        throw Exception('Bu e-posta adresi zaten kullanılıyor');
      }

      await _firestore.collection('users').doc(userId).update({
        'email': newEmail,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (e.toString().contains('zaten kullanılıyor')) {
        rethrow;
      }
      throw Exception('E-posta güncellenirken hata oluştu: $e');
    }
  }

  // Telefon numarası güncelle
  Future<void> updatePhoneNumber(String userId, String newPhone) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'phoneNumber': newPhone,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Telefon numarası güncellenirken hata oluştu: $e');
    }
  }

  // Kullanıcı durumunu değiştir (aktif/pasif)
  Future<void> toggleUserStatus(String userId, bool isActive) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Kullanıcı durumu güncellenirken hata oluştu: $e');
    }
  }

  // Hesabı dondur/kaldır
  Future<void> freezeUser(String userId, bool freeze) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isFrozen': freeze,
        'isActive': !freeze, // Dondurulunca aktif olmamalı
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Hesap durumu güncellenirken hata oluştu: $e');
    }
  }

  // Hesabı kapat (soft delete - sadece pasif yap)
  Future<void> deactivateUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': false,
        'isFrozen': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Hesap kapatılırken hata oluştu: $e');
    }
  }

  // Hesabı sil (hard delete - tamamen kaldır)
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      throw Exception('Hesap silinirken hata oluştu: $e');
    }
  }

  // Bakiye işlemleri

  // Mevcut bakiyeyi getir
  Future<double> getBalance(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        return (data?['balance'] as num?)?.toDouble() ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      throw Exception('Bakiye bilgisi alınırken hata oluştu: $e');
    }
  }

  // Bakiye yükle
  Future<void> addBalance(String userId, double amount, String? note) async {
    try {
      if (amount <= 0) {
        throw Exception('Bakiye miktarı pozitif olmalıdır');
      }

      final user = await getUser(userId);
      if (user == null) {
        throw Exception('Kullanıcı bulunamadı');
      }

      final newBalance = user.balance + amount;

      // Kullanıcı bakiyesini güncelle
      await _firestore.collection('users').doc(userId).update({
        'balance': newBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Bakiye işlemini kaydet
      await _firestore.collection('balance_transactions').add({
        'userId': userId,
        'type': 'deposit',
        'amount': amount,
        'balanceBefore': user.balance,
        'balanceAfter': newBalance,
        'note': note ?? 'Admin tarafından bakiye yükleme',
        'createdBy': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Bakiye yüklenirken hata oluştu: $e');
    }
  }

  // Bakiye çek (admin onayıyla)
  Future<void> deductBalance(String userId, double amount, String? note) async {
    try {
      if (amount <= 0) {
        throw Exception('Miktar pozitif olmalıdır');
      }

      final user = await getUser(userId);
      if (user == null) {
        throw Exception('Kullanıcı bulunamadı');
      }

      if (user.balance < amount) {
        throw Exception('Yetersiz bakiye');
      }

      final newBalance = user.balance - amount;

      // Kullanıcı bakiyesini güncelle
      await _firestore.collection('users').doc(userId).update({
        'balance': newBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Bakiye işlemini kaydet
      await _firestore.collection('balance_transactions').add({
        'userId': userId,
        'type': 'withdrawal',
        'amount': amount,
        'balanceBefore': user.balance,
        'balanceAfter': newBalance,
        'note': note ?? 'Admin tarafından bakiye çekme',
        'createdBy': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Bakiye çekilirken hata oluştu: $e');
    }
  }

  // Bakiye işlemlerini getir
  Stream<List<Map<String, dynamic>>> getBalanceTransactions(String userId) {
    return _firestore
        .collection('balance_transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
        };
      }).toList();
    });
  }

  // Tüm kullanıcıların toplam bakiyesi
  Future<double> getTotalBalance() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      double total = 0.0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final balance = (data['balance'] as num?)?.toDouble() ?? 0.0;
        total += balance;
      }
      return total;
    } catch (e) {
      throw Exception('Toplam bakiye hesaplanırken hata oluştu: $e');
    }
  }
}

