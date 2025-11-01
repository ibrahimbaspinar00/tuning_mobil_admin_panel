import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSettings {
  final String id;
  final String adminUsername;
  final String adminPassword;
  final DateTime lastUpdated;

  AdminSettings({
    required this.id,
    required this.adminUsername,
    required this.adminPassword,
    required this.lastUpdated,
  });

  // Firestore'dan veri almak için
  factory AdminSettings.fromFirestore(Map<String, dynamic> data, String id) {
    return AdminSettings(
      id: id,
      adminUsername: data['adminUsername'] ?? 'admin',
      adminPassword: data['adminPassword'] ?? 'admin123',
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Firestore'a veri göndermek için
  Map<String, dynamic> toFirestore() {
    return {
      'adminUsername': adminUsername,
      'adminPassword': adminPassword,
      'lastUpdated': lastUpdated,
    };
  }

  // Admin ayarları kopyalama için
  AdminSettings copyWith({
    String? id,
    String? adminUsername,
    String? adminPassword,
    DateTime? lastUpdated,
  }) {
    return AdminSettings(
      id: id ?? this.id,
      adminUsername: adminUsername ?? this.adminUsername,
      adminPassword: adminPassword ?? this.adminPassword,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
