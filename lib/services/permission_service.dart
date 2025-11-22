import '../model/admin_user.dart';

class PermissionService {
  static String? _currentUserRole;
  static List<String> _currentUserPermissions = [];
  static String? _currentUserName;
  static String? _currentUserId;

  // Mevcut kullanıcı bilgilerini ayarla
  static void setCurrentUser(String role, List<String> permissions, {String? username, String? userId}) {
    _currentUserRole = role;
    _currentUserPermissions = permissions;
    _currentUserName = username;
    _currentUserId = userId;
  }
  
  // Mevcut kullanıcı ID'sini al
  static String? getCurrentUserId() {
    return _currentUserId;
  }

  // Kullanıcının belirli bir yetkisi var mı kontrol et
  static bool hasPermission(String permission) {
    if (_isAdmin()) {
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

  // Basit yetki kontrolleri (büyük/küçük harf duyarsız)
  static bool _isAdmin() {
    return _currentUserRole != null && _currentUserRole!.toLowerCase() == 'admin';
  }

  static bool canViewProducts() {
    return _isAdmin() || _currentUserPermissions.contains('view_products');
  }

  static bool canCreateProducts() {
    return _isAdmin();
  }

  static bool canUpdateProducts() {
    return _isAdmin();
  }

  static bool canDeleteProducts() {
    return _isAdmin();
  }

  static bool canViewStock() {
    return _isAdmin() || _currentUserPermissions.contains('view_stock');
  }

  static bool canUpdateStock() {
    return _isAdmin();
  }

  static bool canViewUsers() {
    return _isAdmin();
  }

  static bool canCreateUsers() {
    return _isAdmin();
  }

  static bool canUpdateUsers() {
    return _isAdmin();
  }

  static bool canDeleteUsers() {
    return _isAdmin();
  }

  static bool canViewReports() {
    return _isAdmin();
  }

  static bool canExportReports() {
    return _isAdmin();
  }

  static bool canAccessSettings() {
    return _isAdmin();
  }

  static bool canAccessBackup() {
    return _isAdmin();
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
