import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUser {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final String role;
  final String password; // Şifre eklendi
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastLogin;
  final String avatarUrl;
  final List<String> permissions; // Yetkiler eklendi

  AdminUser({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
    required this.password,
    this.isActive = true,
    required this.createdAt,
    required this.lastLogin,
    this.avatarUrl = '',
    this.permissions = const [], // Varsayılan boş yetki listesi
  });

  // Firestore'dan veri almak için
  factory AdminUser.fromFirestore(Map<String, dynamic> data, String id) {
    return AdminUser(
      id: id,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      role: data['role'] ?? 'user',
      password: data['password'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate() ?? DateTime.now(),
      avatarUrl: data['avatarUrl'] ?? '',
      permissions: List<String>.from(data['permissions'] ?? []),
    );
  }

  // Firestore'a veri göndermek için
  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'email': email,
      'fullName': fullName,
      'role': role,
      'password': password,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
      'avatarUrl': avatarUrl,
      'permissions': permissions,
    };
  }

  // Kullanıcı kopyalama için
  AdminUser copyWith({
    String? id,
    String? username,
    String? email,
    String? fullName,
    String? role,
    String? password,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLogin,
    String? avatarUrl,
    List<String>? permissions,
  }) {
    return AdminUser(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      password: password ?? this.password,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      permissions: permissions ?? this.permissions,
    );
  }
}

// Kullanıcı rolleri
class UserRole {
  static const String admin = 'admin';
  static const String moderator = 'moderator';
  static const String user = 'user';
  static const String guest = 'guest';

  static List<String> getAllRoles() {
    return [admin, moderator, user, guest];
  }

  static String getRoleDisplayName(String role) {
    switch (role) {
      case admin:
        return 'Yönetici';
      case moderator:
        return 'Moderatör';
      case user:
        return 'Kullanıcı';
      case guest:
        return 'Misafir';
      default:
        return 'Bilinmiyor';
    }
  }
}

// Yetki sistemi
class UserPermission {
  // Ürün yetkileri
  static const String productView = 'product.view';
  static const String productCreate = 'product.create';
  static const String productUpdate = 'product.update';
  static const String productDelete = 'product.delete';
  
  // Stok yetkileri
  static const String stockView = 'stock.view';
  static const String stockUpdate = 'stock.update';
  
  // Kullanıcı yetkileri
  static const String userView = 'user.view';
  static const String userCreate = 'user.create';
  static const String userUpdate = 'user.update';
  static const String userDelete = 'user.delete';
  
  // Rapor yetkileri
  static const String reportView = 'report.view';
  static const String reportExport = 'report.export';
  
  // Sistem yetkileri
  static const String systemSettings = 'system.settings';
  static const String systemBackup = 'system.backup';
  
  // Tüm yetkiler
  static List<String> getAllPermissions() {
    return [
      productView, productCreate, productUpdate, productDelete,
      stockView, stockUpdate,
      userView, userCreate, userUpdate, userDelete,
      reportView, reportExport,
      systemSettings, systemBackup,
    ];
  }
  
  // Rol bazlı varsayılan yetkiler
  static List<String> getDefaultPermissions(String role) {
    switch (role) {
      case UserRole.admin:
        return getAllPermissions(); // Admin tüm yetkilere sahip
      case UserRole.moderator:
        return [
          productView, productCreate, productUpdate,
          stockView, stockUpdate,
          userView,
          reportView,
        ];
      case UserRole.user:
        return [
          productView,
          stockView,
        ];
      case UserRole.guest:
        return [productView];
      default:
        return [];
    }
  }
  
  // Yetki görüntüleme adı
  static String getPermissionDisplayName(String permission) {
    switch (permission) {
      case productView:
        return 'Ürünleri Görüntüle';
      case productCreate:
        return 'Ürün Oluştur';
      case productUpdate:
        return 'Ürün Güncelle';
      case productDelete:
        return 'Ürün Sil';
      case stockView:
        return 'Stok Görüntüle';
      case stockUpdate:
        return 'Stok Güncelle';
      case userView:
        return 'Kullanıcıları Görüntüle';
      case userCreate:
        return 'Kullanıcı Oluştur';
      case userUpdate:
        return 'Kullanıcı Güncelle';
      case userDelete:
        return 'Kullanıcı Sil';
      case reportView:
        return 'Raporları Görüntüle';
      case reportExport:
        return 'Rapor Dışa Aktar';
      case systemSettings:
        return 'Sistem Ayarları';
      case systemBackup:
        return 'Sistem Yedekleme';
      default:
        return 'Bilinmeyen Yetki';
    }
  }
  
  // Yetki kategorileri
  static Map<String, List<String>> getPermissionCategories() {
    return {
      'Ürün Yönetimi': [productView, productCreate, productUpdate, productDelete],
      'Stok Yönetimi': [stockView, stockUpdate],
      'Kullanıcı Yönetimi': [userView, userCreate, userUpdate, userDelete],
      'Raporlar': [reportView, reportExport],
      'Sistem': [systemSettings, systemBackup],
    };
  }
}

