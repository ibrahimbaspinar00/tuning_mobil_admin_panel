import 'package:cloud_firestore/cloud_firestore.dart';

class MobileUser {
  final String id;
  final String? username;
  final String? email;
  final String? phoneNumber;
  final String? fullName;
  final double balance;
  final bool isActive;
  final bool isFrozen;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final String? avatarUrl;
  final Map<String, dynamic>? additionalInfo;

  MobileUser({
    required this.id,
    this.username,
    this.email,
    this.phoneNumber,
    this.fullName,
    this.balance = 0.0,
    this.isActive = true,
    this.isFrozen = false,
    required this.createdAt,
    this.lastLogin,
    this.avatarUrl,
    this.additionalInfo,
  });

  factory MobileUser.fromFirestore(Map<String, dynamic> data, String id) {
    return MobileUser(
      id: id,
      username: data['username'],
      email: data['email'],
      phoneNumber: data['phoneNumber'],
      fullName: data['fullName'],
      balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
      isActive: data['isActive'] ?? true,
      isFrozen: data['isFrozen'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
      avatarUrl: data['avatarUrl'],
      additionalInfo: data['additionalInfo'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (username != null) 'username': username,
      if (email != null) 'email': email,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (fullName != null) 'fullName': fullName,
      'balance': balance,
      'isActive': isActive,
      'isFrozen': isFrozen,
      'createdAt': Timestamp.fromDate(createdAt),
      if (lastLogin != null) 'lastLogin': Timestamp.fromDate(lastLogin!),
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (additionalInfo != null) 'additionalInfo': additionalInfo,
    };
  }

  MobileUser copyWith({
    String? id,
    String? username,
    String? email,
    String? phoneNumber,
    String? fullName,
    double? balance,
    bool? isActive,
    bool? isFrozen,
    DateTime? createdAt,
    DateTime? lastLogin,
    String? avatarUrl,
    Map<String, dynamic>? additionalInfo,
  }) {
    return MobileUser(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fullName: fullName ?? this.fullName,
      balance: balance ?? this.balance,
      isActive: isActive ?? this.isActive,
      isFrozen: isFrozen ?? this.isFrozen,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}

