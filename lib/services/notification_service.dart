import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/notification.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Bildirim ekleme
  Future<void> addNotification(AppNotification notification) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toFirestore());
    } catch (e) {
      throw Exception('Bildirim eklenirken hata oluştu: $e');
    }
  }

  // Bildirim silme
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      throw Exception('Bildirim silinirken hata oluştu: $e');
    }
  }

  // Tüm bildirimleri getirme
  Stream<List<AppNotification>> getNotifications() {
    return _firestore
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AppNotification.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  // Bildirim güncelleme
  Future<void> updateNotification(AppNotification notification) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .update(notification.toFirestore());
    } catch (e) {
      throw Exception('Bildirim güncellenirken hata oluştu: $e');
    }
  }

  // Bildirimi okundu olarak işaretle
  Future<void> markAsRead(String notificationId, String userId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({
        'isRead': true,
        'readBy': userId,
        'readAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Bildirim okundu olarak işaretlenirken hata oluştu: $e');
    }
  }

  // Okunmamış bildirimleri getirme
  Stream<List<AppNotification>> getUnreadNotifications() {
    return _firestore
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AppNotification.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  // Kullanıcıya özel bildirimleri getirme
  Stream<List<AppNotification>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('target', isEqualTo: 'specific')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AppNotification.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }
}

