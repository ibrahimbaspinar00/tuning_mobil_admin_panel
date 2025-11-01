import '../model/admin_user.dart';

class PermissionService {
  static String? _currentUserRole;
  static List<String> _currentUserPermissions = [];
  static String? _currentUserName;

  // Mevcut kullanıcı bilgilerini ayarla
  static void setCurrentUser(String role, List<String> permissions, {String? username}) {
    _currentUserRole = role;
    _currentUserPermissions = permissions;
    _currentUserName = username;
  }

  // Kullanıcının belirli bir yetkisi var mı kontrol et
  static bool hasPermission(String permission) {
    if (_currentUserRole == 'admin') {
      return true; // Admin tüm yetkilere sahip
    }
    return _currentUserPermissions.contains(permission);
  }

  // Kullanıcının belirli bir rolü var mı kontrol et
  static bool hasRole(String role) {
    return _currentUserRole == role;
  }

  // Kullanıcının admin olup olmadığını kontrol et
  static bool isAdmin() {
    return _currentUserRole == UserRole.admin;
  }

  // Kullanıcının moderatör olup olmadığını kontrol et
  static bool isModerator() {
    return _currentUserRole == UserRole.moderator;
  }

  // Kullanıcının normal kullanıcı olup olmadığını kontrol et
  static bool isUser() {
    return _currentUserRole == UserRole.user;
  }

  // Kullanıcının misafir olup olmadığını kontrol et
  static bool isGuest() {
    return _currentUserRole == UserRole.guest;
  }

  // Basit yetki kontrolleri
  static bool canViewProducts() {
    return _currentUserRole == 'admin' || _currentUserPermissions.contains('view_products');
  }

  static bool canCreateProducts() {
    return _currentUserRole == 'admin';
  }

  static bool canUpdateProducts() {
    return _currentUserRole == 'admin';
  }

  static bool canDeleteProducts() {
    return _currentUserRole == 'admin';
  }

  static bool canViewStock() {
    return _currentUserRole == 'admin' || _currentUserPermissions.contains('view_stock');
  }

  static bool canUpdateStock() {
    return _currentUserRole == 'admin';
  }

  static bool canViewUsers() {
    return _currentUserRole == 'admin';
  }

  static bool canCreateUsers() {
    return _currentUserRole == 'admin';
  }

  static bool canUpdateUsers() {
    return _currentUserRole == 'admin';
  }

  static bool canDeleteUsers() {
    return _currentUserRole == 'admin';
  }

  static bool canViewReports() {
    return _currentUserRole == 'admin';
  }

  static bool canExportReports() {
    return _currentUserRole == 'admin';
  }

  static bool canAccessSettings() {
    return _currentUserRole == 'admin';
  }

  static bool canAccessBackup() {
    return _currentUserRole == 'admin';
  }

  // Kullanıcının tüm yetkilerini getir
  static List<String> getCurrentUserPermissions() {
    return List.from(_currentUserPermissions);
  }

  // Kullanıcının rolünü getir
  static String? getCurrentUserRole() {
    return _currentUserRole;
  }

  // Kullanıcı adını getir
  static String? getCurrentUserName() {
    return _currentUserName;
  }

  // Yetki durumunu sıfırla
  static void clearPermissions() {
    _currentUserRole = null;
    _currentUserPermissions.clear();
    _currentUserName = null;
  }
}
