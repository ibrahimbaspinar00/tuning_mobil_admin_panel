import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type; // 'system', 'order', 'product', 'stock', 'user'
  final String? imageUrl;
  final String? actionUrl;
  final String target; // 'all', 'specific'
  final String? userId; // Eğer target 'specific' ise
  final DateTime createdAt;
  final DateTime? scheduledDate;
  final bool isRead;
  final String? readBy;
  final DateTime? readAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.imageUrl,
    this.actionUrl,
    this.target = 'all',
    this.userId,
    required this.createdAt,
    this.scheduledDate,
    this.isRead = false,
    this.readBy,
    this.readAt,
  });

  // Firestore'dan veri almak için
  factory AppNotification.fromFirestore(Map<String, dynamic> data, String id) {
    return AppNotification(
      id: id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? 'system',
      imageUrl: data['imageUrl'],
      actionUrl: data['actionUrl'],
      target: data['target'] ?? 'all',
      userId: data['userId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      scheduledDate: (data['scheduledDate'] as Timestamp?)?.toDate(),
      isRead: data['isRead'] ?? false,
      readBy: data['readBy'],
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
    );
  }

  // Firestore'a veri göndermek için
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'target': target,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'scheduledDate': scheduledDate != null ? Timestamp.fromDate(scheduledDate!) : null,
      'isRead': isRead,
      'readBy': readBy,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    };
  }

  // Notification kopyalama için
  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    String? imageUrl,
    String? actionUrl,
    String? target,
    String? userId,
    DateTime? createdAt,
    DateTime? scheduledDate,
    bool? isRead,
    String? readBy,
    DateTime? readAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      target: target ?? this.target,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      isRead: isRead ?? this.isRead,
      readBy: readBy ?? this.readBy,
      readAt: readAt ?? this.readAt,
    );
  }
}

