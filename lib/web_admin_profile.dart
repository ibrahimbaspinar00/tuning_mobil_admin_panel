import 'dart:async';
import 'package:flutter/material.dart';
import 'model/admin_user.dart';
import 'services/admin_service.dart';
import 'services/permission_service.dart';

class WebAdminProfile extends StatefulWidget {
  const WebAdminProfile({super.key});

  @override
  State<WebAdminProfile> createState() => _WebAdminProfileState();
}

class _WebAdminProfileState extends State<WebAdminProfile> with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  final _formKey = GlobalKey<FormState>();
  
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  
  AdminUser? _currentUser;
  String? _avatarUrl;
  
  late TabController _tabController;
  Map<String, dynamic> _userStats = {};
  bool _twoFactorEnabled = false;
  bool _emailNotifications = true;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _currentPasswordController.dispose();
    
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUsername = PermissionService.getCurrentUserName();
      debugPrint('Mevcut kullanıcı adı: $currentUsername');
      
      // Timeout ile kullanıcı listesini al
      List<AdminUser> users;
      try {
        users = await _adminService.getUsers()
            .timeout(const Duration(seconds: 15))
            .first;
        debugPrint('Firestore\'dan ${users.length} kullanıcı yüklendi');
      } on TimeoutException {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Veri yükleme zaman aşımına uğradı. Lütfen internet bağlantınızı kontrol edin.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      } catch (e) {
        debugPrint('Kullanıcı verileri yüklenirken hata: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Veri yükleme hatası: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Tekrar Dene',
                textColor: Colors.white,
                onPressed: () => _loadUserProfile(),
              ),
            ),
          );
        }
        return;
      }
      
      if (users.isEmpty) {
        debugPrint('Firestore\'da hiç kullanıcı bulunamadı');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Firestore\'da hiç kullanıcı bulunamadı. Lütfen sistem yöneticisi ile iletişime geçin.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // Kullanıcı adı varsa eşleşen kullanıcıyı bul
      AdminUser? foundUser;
      if (currentUsername != null && currentUsername.isNotEmpty) {
        try {
          foundUser = users.firstWhere(
            (user) => user.username.toLowerCase().trim() == currentUsername.toLowerCase().trim(),
          );
          debugPrint('Kullanıcı bulundu: ${foundUser.username} (ID: ${foundUser.id})');
        } catch (e) {
          debugPrint('Kullanıcı adı eşleşmedi ($currentUsername). Mevcut kullanıcılar: ${users.map((u) => u.username).join(", ")}');
          // Eşleşen kullanıcı yoksa ilk kullanıcıyı kullan
          foundUser = users.first;
          debugPrint('İlk kullanıcı kullanılıyor: ${foundUser.username}');
        }
      } else {
        // Kullanıcı adı yoksa ilk kullanıcıyı kullan
        debugPrint('Kullanıcı adı yok, ilk kullanıcı kullanılıyor');
        foundUser = users.first;
        debugPrint('Seçilen kullanıcı: ${foundUser.username}');
      }

      // foundUser asla null olamaz çünkü users.isEmpty kontrolü yukarıda yapıldı
      _currentUser = foundUser;

      // PermissionService'i her zaman güncelle (username doğru olsun)
      PermissionService.setCurrentUser(
        _currentUser!.role.toLowerCase(),
        _currentUser!.permissions,
        username: _currentUser!.username,
      );
      debugPrint('PermissionService güncellendi: ${_currentUser!.username}');

      // Kullanıcı istatistiklerini yükle (hata olsa bile devam et)
      try {
        await _loadUserStatistics();
      } catch (e) {
        debugPrint('İstatistikler yüklenirken hata: $e');
        // İstatistikler yüklenemezse devam et
      }

      if (mounted) {
        setState(() {
          _fullNameController.text = _currentUser!.fullName;
          _emailController.text = _currentUser!.email;
          _usernameController.text = _currentUser!.username;
          _avatarUrl = _currentUser!.avatarUrl;
          _isLoading = false;
        });
        debugPrint('Profil başarıyla yüklendi');
      }
    } catch (e, stackTrace) {
      debugPrint('Profil yüklenirken beklenmeyen hata: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Beklenmeyen bir hata oluştu: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Tekrar Dene',
              textColor: Colors.white,
              onPressed: () => _loadUserProfile(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadUserStatistics() async {
    try {
      final products = await _adminService.getProducts().first;
      final orders = await _adminService.getOrders().first;
      
      setState(() {
        _userStats = {
          'productsManaged': products.length,
          'ordersProcessed': orders.length,
          'activeProducts': products.where((p) => p.isActive).length,
          'totalRevenue': orders.fold(0.0, (sum, order) => sum + order.totalAmount),
        };
      });
    } catch (e) {
      debugPrint('İstatistikler yüklenirken hata: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcı bilgisi bulunamadı. Lütfen sayfayı yenileyin.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedUser = _currentUser!.copyWith(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        avatarUrl: _avatarUrl ?? '',
        password: _currentUser!.password,
        role: _currentUser!.role,
        isActive: _currentUser!.isActive,
        createdAt: _currentUser!.createdAt,
        lastLogin: _currentUser!.lastLogin,
        permissions: _currentUser!.permissions,
      );

      debugPrint('Güncellenecek kullanıcı ID: ${updatedUser.id}');
      debugPrint('Yeni bilgiler - Ad: ${updatedUser.fullName}, Email: ${updatedUser.email}, Username: ${updatedUser.username}');
      
      await _adminService.updateUser(updatedUser);
      
      debugPrint('Kullanıcı başarıyla güncellendi');

      if (mounted) {
        PermissionService.setCurrentUser(
          updatedUser.role.toLowerCase(),
          updatedUser.permissions,
          username: updatedUser.username,
        );
        
        setState(() {
          _isSaving = false;
          _currentUser = updatedUser;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil başarıyla güncellendi'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        await Future.delayed(const Duration(milliseconds: 500));
        await _loadUserProfile();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil güncellenirken hata oluştu: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tüm şifre alanları doldurulmalıdır'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yeni şifreler eşleşmiyor'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yeni şifre en az 6 karakter olmalıdır'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_currentUser == null) return;

    if (_currentUser!.password != _currentPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mevcut şifre hatalı'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedUser = _currentUser!.copyWith(
        password: _newPasswordController.text,
        fullName: _currentUser!.fullName,
        email: _currentUser!.email,
        username: _currentUser!.username,
        role: _currentUser!.role,
        isActive: _currentUser!.isActive,
        createdAt: _currentUser!.createdAt,
        lastLogin: _currentUser!.lastLogin,
        avatarUrl: _currentUser!.avatarUrl,
        permissions: _currentUser!.permissions,
      );

      await _adminService.updateUser(updatedUser);

      if (mounted) {
        setState(() {
          _isSaving = false;
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şifre başarıyla değiştirildi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Şifre değiştirilirken hata oluştu: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Profil Ayarları'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF6366F1),
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Bilgilerim'),
            Tab(icon: Icon(Icons.security), text: 'Güvenlik'),
            Tab(icon: Icon(Icons.settings), text: 'Tercihler'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
              ? const Center(child: Text('Kullanıcı bilgisi yüklenemedi'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProfileTab(),
                    _buildSecurityTab(),
                    _buildPreferencesTab(),
                  ],
                ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profil Özeti Kartı
            _buildProfileSummaryCard(),
            const SizedBox(height: 24),

            // Profil Bilgileri Kartı
            _buildProfileInfoCard(),
            const SizedBox(height: 24),

            // İstatistikler Kartı
            _buildStatisticsCard(),
            const SizedBox(height: 24),

            // Aktivite Geçmişi Kartı
            _buildActivityCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSummaryCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                      ? NetworkImage(_avatarUrl!)
                      : null,
                  child: _avatarUrl == null || _avatarUrl!.isEmpty
                      ? Text(
                          (_currentUser?.fullName.isNotEmpty == true
                              ? _currentUser!.fullName[0].toUpperCase()
                              : 'A'),
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6366F1),
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF6366F1), width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, color: Color(0xFF6366F1), size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _currentUser!.fullName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _currentUser!.email,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _currentUser!.role,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Profil Bilgileri',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Ad Soyad',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ad soyad gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Kullanıcı Adı',
                prefixIcon: Icon(Icons.account_circle_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Kullanıcı adı gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-posta',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'E-posta gerekli';
                }
                if (!value.contains('@')) {
                  return 'Geçerli bir e-posta adresi girin';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Bilgileri Kaydet',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.analytics_outlined, color: Color(0xFF10B981), size: 24),
                ),
                const SizedBox(width: 16),
                const Text(
                  'İstatistiklerim',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Yönetilen Ürün',
                    '${_userStats['productsManaged'] ?? 0}',
                    Icons.inventory_2_rounded,
                    const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    'İşlenen Sipariş',
                    '${_userStats['ordersProcessed'] ?? 0}',
                    Icons.shopping_bag_rounded,
                    const Color(0xFF8B5CF6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Aktif Ürün',
                    '${_userStats['activeProducts'] ?? 0}',
                    Icons.check_circle_rounded,
                    const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    'Toplam Gelir',
                    '₺${((_userStats['totalRevenue'] ?? 0.0) as double).toStringAsFixed(0)}',
                    Icons.attach_money_rounded,
                    const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.history, color: Color(0xFFF59E0B), size: 24),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Son Aktiviteler',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildActivityItem(
              Icons.person_add,
              'Profil oluşturuldu',
              _currentUser!.createdAt,
              const Color(0xFF10B981),
            ),
            _buildActivityItem(
              Icons.login,
              'Son giriş',
              _currentUser!.lastLogin,
              const Color(0xFF3B82F6),
            ),
            _buildActivityItem(
              Icons.edit,
              'Profil güncellendi',
              DateTime.now().subtract(const Duration(hours: 2)),
              const Color(0xFF8B5CF6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(IconData icon, String title, DateTime date, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(date),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Şifre Değiştirme
          _buildPasswordChangeCard(),
          const SizedBox(height: 24),

          // Güvenlik Ayarları
          _buildSecuritySettingsCard(),
          const SizedBox(height: 24),

          // Oturum Yönetimi
          _buildSessionCard(),
        ],
      ),
    );
  }

  Widget _buildPasswordChangeCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.lock_outline, color: Color(0xFFEF4444), size: 24),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Şifre Değiştir',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _currentPasswordController,
              obscureText: !_showCurrentPassword,
              decoration: InputDecoration(
                labelText: 'Mevcut Şifre',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showCurrentPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _showCurrentPassword = !_showCurrentPassword;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _newPasswordController,
              obscureText: !_showNewPassword,
              decoration: InputDecoration(
                labelText: 'Yeni Şifre',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showNewPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _showNewPassword = !_showNewPassword;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty && value.length < 6) {
                  return 'Şifre en az 6 karakter olmalı';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _confirmPasswordController,
              obscureText: !_showConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Yeni Şifre Tekrar',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _showConfirmPassword = !_showConfirmPassword;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Şifreyi Değiştir',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySettingsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield_outlined, color: Color(0xFF8B5CF6), size: 24),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Güvenlik Ayarları',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            SwitchListTile(
              title: const Text('İki Faktörlü Kimlik Doğrulama'),
              subtitle: const Text('Hesabınız için ekstra güvenlik katmanı'),
              value: _twoFactorEnabled,
              onChanged: (value) {
                setState(() {
                  _twoFactorEnabled = value;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value 
                      ? 'İki faktörlü kimlik doğrulama etkinleştirildi'
                      : 'İki faktörlü kimlik doğrulama devre dışı bırakıldı'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              secondary: const Icon(Icons.verified_user_outlined),
            ),
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.password_outlined),
              title: const Text('Şifre Güvenliği'),
              subtitle: Text('Son değişiklik: ${_formatDate(_currentUser!.createdAt)}'),
              trailing: const Icon(Icons.chevron_right),
            ),
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.devices_outlined),
              title: const Text('Cihazlar'),
              subtitle: const Text('Aktif oturumlarınızı yönetin'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cihaz yönetimi yakında eklenecek'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.devices, color: Color(0xFF3B82F6), size: 24),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Oturum Yönetimi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildSessionItem('Mevcut Oturum', 'Bu Cihaz', _currentUser!.lastLogin, true),
            const SizedBox(height: 12),
            _buildSessionItem('Son Oturum', 'Bilinmeyen Cihaz', 
                _currentUser!.lastLogin.subtract(const Duration(days: 1)), false),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionItem(String title, String device, DateTime date, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF3B82F6).withValues(alpha: 0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? const Color(0xFF3B82F6).withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.phone_android,
            color: isActive ? const Color(0xFF3B82F6) : Colors.grey[600],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isActive ? const Color(0xFF3B82F6) : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$device • ${_formatDateTime(date)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Aktif',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Oturum sonlandırıldı'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Sonlandır'),
            ),
        ],
      ),
    );
  }

  Widget _buildPreferencesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bildirim Tercihleri
          _buildNotificationPreferencesCard(),
          const SizedBox(height: 24),

          // Görünüm Ayarları
          _buildAppearanceCard(),
          const SizedBox(height: 24),

          // Hesap Bilgileri
          _buildAccountInfoCard(),
        ],
      ),
    );
  }

  Widget _buildNotificationPreferencesCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.notifications_outlined, color: Color(0xFFEF4444), size: 24),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Bildirim Tercihleri',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            SwitchListTile(
              title: const Text('E-posta Bildirimleri'),
              subtitle: const Text('Önemli bildirimleri e-posta ile al'),
              value: _emailNotifications,
              onChanged: (value) {
                setState(() {
                  _emailNotifications = value;
                });
              },
              secondary: const Icon(Icons.email_outlined),
            ),
            const Divider(),
            
            SwitchListTile(
              title: const Text('Sipariş Bildirimleri'),
              subtitle: const Text('Yeni siparişler için bildirim al'),
              value: true,
              onChanged: (value) {},
              secondary: const Icon(Icons.shopping_bag_outlined),
            ),
            const Divider(),
            
            SwitchListTile(
              title: const Text('Stok Uyarıları'),
              subtitle: const Text('Düşük stok uyarıları için bildirim al'),
              value: true,
              onChanged: (value) {},
              secondary: const Icon(Icons.warning_outlined),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.palette_outlined, color: Color(0xFF8B5CF6), size: 24),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Görünüm Ayarları',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            SwitchListTile(
              title: const Text('Karanlık Mod'),
              subtitle: const Text('Karanlık temayı kullan'),
              value: _darkMode,
              onChanged: (value) {
                setState(() {
                  _darkMode = value;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value 
                      ? 'Karanlık mod etkinleştirildi'
                      : 'Karanlık mod devre dışı bırakıldı'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              secondary: const Icon(Icons.dark_mode_outlined),
            ),
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.language_outlined),
              title: const Text('Dil Tercihi'),
              subtitle: const Text('Türkçe'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dil ayarları yakında eklenecek'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.info_outline, color: Color(0xFF10B981), size: 24),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Hesap Bilgileri',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoRow('Rol', _currentUser!.role, Icons.badge_outlined),
            _buildInfoRow('Durum', _currentUser!.isActive ? 'Aktif' : 'Pasif', 
                _currentUser!.isActive ? Icons.check_circle_outline : Icons.cancel_outlined),
            _buildInfoRow('Hesap Oluşturulma', 
                '${_currentUser!.createdAt.day}/${_currentUser!.createdAt.month}/${_currentUser!.createdAt.year}', 
                Icons.calendar_today_outlined),
            _buildInfoRow('Son Giriş', 
                _formatDateTime(_currentUser!.lastLogin), 
                Icons.access_time_outlined),
            if (_currentUser!.permissions.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Yetkiler',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _currentUser!.permissions.map((permission) {
                  return Chip(
                    label: Text(permission),
                    backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    labelStyle: const TextStyle(
                      color: Color(0xFF6366F1),
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} dakika önce';
      }
      return '${difference.inHours} saat önce';
    } else if (difference.inDays == 1) {
      return 'Dün ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
