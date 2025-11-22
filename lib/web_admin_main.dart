import 'package:flutter/material.dart';
import 'dart:async';
import 'web_admin_dashboard.dart';
import 'model/admin_user.dart';
import 'services/permission_service.dart';
import 'services/admin_settings_service.dart';
import 'services/admin_service.dart';
import 'services/email_service.dart';
import 'services/app_theme.dart';
import 'services/audit_log_service.dart';
import 'services/rate_limit_service.dart';

// Global admin şifre değişkeni
String adminPassword = 'admin123';

// Global admin kullanıcı adı değişkeni
String adminUsername = 'admin';

class WebAdminApp extends StatefulWidget {
  const WebAdminApp({super.key});

  @override
  State<WebAdminApp> createState() => _WebAdminAppState();
}

class _WebAdminAppState extends State<WebAdminApp> {
  bool _isDarkMode = false;

  void _updateTheme(bool isDark) {
    setState(() {
      _isDarkMode = isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tuning App - Admin Panel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        return AppTheme(
          isDarkMode: _isDarkMode,
          onThemeChanged: _updateTheme,
          child: child!,
        );
      },
      home: const WebAdminLogin(),
    );
  }
}

class WebAdminLogin extends StatefulWidget {
  const WebAdminLogin({super.key});

  @override
  State<WebAdminLogin> createState() => _WebAdminLoginState();
}

class _WebAdminLoginState extends State<WebAdminLogin> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final AdminSettingsService _adminSettingsService = AdminSettingsService();
  
  // Şifre sıfırlama için
  String _resetCode = '';
  String _resetEmail = '';
  int _resendTimer = 0;
  bool _canResend = true;

  @override
  void initState() {
    super.initState();
    // Varsayılan değerleri garanti et
    adminUsername = 'admin';
    adminPassword = 'admin123';
    _loadAdminSettings();
  }

  // Firebase'den admin ayarlarını yükle
  Future<void> _loadAdminSettings() async {
    try {
      final settings = await _adminSettingsService.getAdminSettings()
          .timeout(const Duration(seconds: 5));
      if (settings != null) {
        if (mounted) {
          setState(() {
            adminUsername = settings.adminUsername;
            adminPassword = settings.adminPassword;
          });
        }
        debugPrint('✅ Firebase\'den admin ayarları yüklendi');
      } else {
        // Varsayılan ayarları oluştur
        try {
          await _adminSettingsService.createDefaultAdminSettings()
              .timeout(const Duration(seconds: 5));
          debugPrint('✅ Varsayılan admin ayarları oluşturuldu');
        } catch (e) {
          debugPrint('⚠️ Varsayılan ayarlar oluşturulamadı: $e');
        }
      }
    } on TimeoutException catch (e) {
      debugPrint('⚠️ Admin ayarları yükleme timeout: $e');
      // Varsayılan değerleri kullan
      if (mounted) {
        setState(() {
          adminUsername = 'admin';
          adminPassword = 'admin123';
        });
      }
    } catch (e) {
      debugPrint('⚠️ Admin ayarları yüklenirken hata: $e');
      // Admin ayarları yüklenirken hata - varsayılan değerleri kullan
      if (mounted) {
        setState(() {
          adminUsername = 'admin';
          adminPassword = 'admin123';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[800]!, Colors.blue[600]!],
          ),
        ),
        child: Center(
          child: Card(
            margin: EdgeInsets.all(isMobile ? 16 : isTablet ? 24 : 32),
            elevation: 8,
            child: Container(
              width: isMobile ? screenWidth * 0.9 : isTablet ? 450 : 500,
              padding: EdgeInsets.all(isMobile ? 20 : isTablet ? 28 : 32),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Container(
                        width: isMobile ? 60 : isTablet ? 70 : 80,
                        height: isMobile ? 60 : isTablet ? 70 : 80,
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.admin_panel_settings,
                          size: isMobile ? 30 : isTablet ? 35 : 40,
                          color: Colors.blue[800],
                        ),
                      ),
                      SizedBox(height: isMobile ? 16 : isTablet ? 20 : 24),
                      
                      // Başlık
                      Text(
                        'Admin Panel',
                        style: TextStyle(
                          fontSize: isMobile ? 22 : isTablet ? 25 : 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      SizedBox(height: isMobile ? 6 : 8),
                      Text(
                        'Tuning App Yönetim Paneli',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: isMobile ? 14 : isTablet ? 15 : 16,
                        ),
                      ),
                      SizedBox(height: isMobile ? 24 : isTablet ? 28 : 32),
                      
                      // Kullanıcı adı
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Kullanıcı Adı',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Kullanıcı adı gerekli';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Şifre
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Şifre',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Şifre gerekli';
                          }
                          return null;
                        },
                      ),
                          const SizedBox(height: 24),
                          
                          // Giriş butonu
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[800],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('Giriş Yap', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Şifre unutma butonu
                          TextButton(
                            onPressed: () => _showForgotPasswordDialog(),
                            child: const Text('Şifremi Unuttum'),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      if (!mounted) return;
      
      // Rate limiting kontrolü
      final identifier = _usernameController.text.trim();
      final rateLimitOk = await RateLimitService.checkRateLimit(
        identifier: identifier,
        maxRequests: 5, // 5 dakikada 5 deneme
        window: const Duration(minutes: 5),
      );
      
      if (!rateLimitOk) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Çok fazla giriş denemesi. Lütfen 5 dakika sonra tekrar deneyin.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }
      
      setState(() {
        _isLoading = true;
      });
      
      try {
        final enteredUsername = _usernameController.text.trim();
        final enteredPassword = _passwordController.text.trim();
        
        debugPrint('🔐 Giriş denemesi başlatıldı');
        debugPrint('📝 Girilen kullanıcı adı: $enteredUsername');
        
        // Önce varsayılan admin kontrolü (hızlı ve güvenilir)
        if (enteredUsername.toLowerCase() == 'admin' && enteredPassword == 'admin123') {
          debugPrint('✅ Varsayılan admin ile giriş başarılı');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            PermissionService.setCurrentUser(
              'admin',
              ['all'],
              username: 'admin',
              userId: 'admin',
            );
            
            // Audit log
            await AuditLogService.logAction(
              userId: 'admin',
              action: 'login',
              resource: 'auth',
              details: {'username': 'admin'},
            );
            
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const WebAdminDashboard(),
              ),
            );
          }
          return;
        }
        
        // Firebase'den admin ayarlarını yükle (varsa)
        try {
          await _loadAdminSettings();
        } catch (e) {
          debugPrint('⚠️ Admin ayarları yüklenemedi: $e');
          // Devam et, varsayılan değerler kullanılacak
        }
        
        if (!mounted) return;
        
        // Firebase'den yüklenen admin kontrolü
        final expectedUsername = adminUsername.trim().toLowerCase();
        final expectedPassword = adminPassword.trim();
        
        if (enteredUsername.toLowerCase() == expectedUsername && enteredPassword == expectedPassword) {
          debugPrint('✅ Firebase admin ayarları ile giriş başarılı');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            PermissionService.setCurrentUser(
              'admin',
              ['all'],
              username: adminUsername,
              userId: 'admin',
            );
            
            // Audit log
            await AuditLogService.logAction(
              userId: 'admin',
              action: 'login',
              resource: 'auth',
              details: {'username': adminUsername},
            );
            
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const WebAdminDashboard(),
              ),
            );
          }
          return;
        }
        
        // Firestore'dan admin_users koleksiyonundan kontrol et
        List<AdminUser> adminUsers = [];
        try {
          debugPrint('📡 Firestore\'dan kullanıcılar getiriliyor...');
          final adminService = AdminService();
          adminUsers = await adminService.getUsers()
              .timeout(const Duration(seconds: 10))
              .first;
          debugPrint('✅ ${adminUsers.length} kullanıcı bulundu');
        } on TimeoutException catch (e) {
          debugPrint('❌ Timeout hatası: $e');
          // Timeout durumunda devam et, kullanıcı bulunamadı mesajı göster
        } catch (e) {
          debugPrint('❌ Firestore kullanıcı getirme hatası: $e');
          // Firestore hatası durumunda devam et
        }
        
        // Debug: Tüm kullanıcıları yazdır
        debugPrint('=== ADMIN USERS DEBUG ===');
        debugPrint('Total users in admin_users: ${adminUsers.length}');
        for (var user in adminUsers) {
          debugPrint('User: ${user.username}, Password: ${user.password}, Active: ${user.isActive}, Role: ${user.role}');
          debugPrint('  Entered: "$enteredUsername" vs Stored: "${user.username}"');
          debugPrint('  Passwords match: ${user.password == enteredPassword}');
        }
        debugPrint('========================');
        
        // Admin kullanıcı kontrolü - Daha esnek karşılaştırma
        AdminUser? foundAdminUser;
        for (var user in adminUsers) {
          // Kullanıcı adı karşılaştırması (trim ve case-insensitive)
          final storedUsername = user.username.trim();
          final storedPassword = user.password.trim();
          
          if (storedUsername.toLowerCase() == enteredUsername.toLowerCase() &&
              storedPassword == enteredPassword &&
              user.isActive &&
              (user.role.toLowerCase() == 'admin' || user.role.toLowerCase() == 'administrator')) {
            foundAdminUser = user;
            debugPrint('Found admin user: ${user.username}');
            break;
          }
        }
        
        final adminUser = foundAdminUser ?? AdminUser(
          id: '',
          username: '',
          email: '',
          fullName: '',
          role: '',
          password: '',
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );
        
        if (adminUser.id.isNotEmpty) {
          // Admin kullanıcı girişi başarılı
          debugPrint('✅ Firestore admin kullanıcı ile giriş başarılı: ${adminUser.username}');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            PermissionService.setCurrentUser(
              'admin',
              ['all'],
              username: adminUser.username,
              userId: adminUser.id,
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const WebAdminDashboard(),
              ),
            );
          }
          return;
        }
        
        // Normal kullanıcı kontrolü (Admin rolü olmayanlar)
        AdminUser? foundNormalUser;
        for (var user in adminUsers) {
          final storedUsername = user.username.trim();
          final storedPassword = user.password.trim();
          
          if (storedUsername.toLowerCase() == enteredUsername.toLowerCase() &&
              storedPassword == enteredPassword &&
              user.isActive &&
              user.role.toLowerCase() != 'admin' &&
              user.role.toLowerCase() != 'administrator') {
            foundNormalUser = user;
            debugPrint('✅ Normal kullanıcı bulundu: ${user.username}');
            break;
          }
        }
        
        if (foundNormalUser != null) {
          // Normal kullanıcı girişi başarılı
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            PermissionService.setCurrentUser(
              'user',
              ['view_products', 'view_stock'],
              username: foundNormalUser.username,
              userId: foundNormalUser.id,
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const WebAdminDashboard(),
              ),
            );
          }
          return;
        }
        
        // Kullanıcı bulunamadı
        debugPrint('❌ Kullanıcı bulunamadı');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _passwordController.clear();
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Kullanıcı adı veya şifre hatalı. Lütfen tekrar deneyiniz.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.orange[700],
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } catch (e, stackTrace) {
        // Hata detaylarını konsola yazdır
        debugPrint('❌ GİRİŞ HATASI: $e');
        debugPrint('Stack trace: $stackTrace');
        
        if (mounted) {
          setState(() {
            _isLoading = false;
            // Şifre alanını temizle
            _passwordController.clear();
          });
        }
        
        if (mounted) {
          // Hata tipine göre daha açıklayıcı mesaj göster
          String errorMessage = 'Giriş yapılırken bir hata oluştu.';
          
          if (e.toString().contains('TimeoutException') || 
              e.toString().contains('timeout') ||
              e.toString().contains('network')) {
            errorMessage = 'İnternet bağlantısı hatası. Lütfen bağlantınızı kontrol edin.';
          } else if (e.toString().contains('permission') || 
                     e.toString().contains('PERMISSION_DENIED')) {
            errorMessage = 'Firebase erişim izni hatası. Lütfen Firebase ayarlarını kontrol edin.';
          } else if (e.toString().contains('admin_users') || 
                     e.toString().contains('collection')) {
            errorMessage = 'Firestore bağlantı hatası. Lütfen Firebase yapılandırmasını kontrol edin.';
          } else if (e.toString().contains('Firebase')) {
            errorMessage = 'Firebase bağlantı hatası. Lütfen internet bağlantınızı kontrol edin.';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                errorMessage,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red[700],
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              action: SnackBarAction(
                label: 'Detay',
                textColor: Colors.white,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Hata Detayları'),
                      content: SingleChildScrollView(
                        child: Text('$e\n\n$stackTrace'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Kapat'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        }
      }
    }
  }

  // Şifre unutma dialogu
  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Şifremi Unuttum'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Email adresinizi girin, size şifre sıfırlama kodu gönderelim.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email Adresi',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (emailController.text.isNotEmpty && emailController.text.contains('@')) {
                _sendPasswordResetCode(emailController.text);
                Navigator.pop(context);
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lütfen geçerli bir email adresi girin'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Kod Gönder'),
          ),
        ],
      ),
    );
  }

      // Şifre sıfırlama kodu gönder
      Future<void> _sendPasswordResetCode(String email) async {
        try {
          setState(() {
            _isLoading = true;
          });

          // 6 haneli kod oluştur
          final resetCode = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();

          // Otomatik email servis seçimi - yapılandırılmış servisi kullan
          // EmailService otomatik olarak Gmail SMTP -> SendGrid -> Firebase Functions sırasını dener
          bool emailSent = await EmailService.sendPasswordResetCode(email, resetCode);

          if (emailSent) {
            // Email başarıyla gönderildi

            // Kodu kaydet
            _resetCode = resetCode;
            _resetEmail = email;

            setState(() {
              _isLoading = false;
            });

            // Başarı mesajı
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Doğrulama kodu $email adresine gönderildi!'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            }

            // Kod doğrulama dialogu
            _showCodeVerificationDialog();

          } else {
            setState(() {
              _isLoading = false;
            });

            // Email gönderilemedi - kullanıcıya bilgi ver
            if (mounted) {
              _showEmailConfigurationDialog(email, resetCode);
            }
          }

        } catch (e) {
          setState(() {
            _isLoading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Kod gönderilirken hata oluştu: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      }
      
      // Email yapılandırması eksik dialogu
      void _showEmailConfigurationDialog(String email, String resetCode) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Text('Email Servisi Yapılandırılmamış'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Email gönderilemedi çünkü email servisi yapılandırılmamış.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text('Yapılandırma seçenekleri:'),
                  const SizedBox(height: 8),
                  _buildConfigOption(
                    Icons.email,
                    'Gmail SMTP',
                    'Ücretsiz - Gmail hesabı ve App Password gerekli',
                    Colors.green,
                  ),
                  const SizedBox(height: 8),
                  _buildConfigOption(
                    Icons.cloud,
                    'SendGrid',
                    'Ücretsiz - 100 email/gün - API Key gerekli',
                    Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Geçici Çözüm:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Doğrulama Kodunuz: $resetCode',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Bu kodu kopyalayıp şifre sıfırlama ekranında kullanabilirsiniz.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tamam'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Ayarlar sayfasına yönlendir (eğer dashboard açıksa)
                  // Şimdilik sadece kodu göster
                },
                child: const Text('Ayarlara Git'),
              ),
            ],
          ),
        );
      }
      
      Widget _buildConfigOption(IconData icon, String title, String subtitle, Color color) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

  // Kod doğrulama dialogu
  void _showCodeVerificationDialog() {
    final codeController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    // Timer başlat
    _startResendTimer();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Kod Doğrulama'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${_resetEmail} adresine gönderilen 6 haneli kodu girin:'),
                const SizedBox(height: 16),
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Doğrulama Kodu',
                    prefixIcon: Icon(Icons.security),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Yeni Şifre',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Şifre Tekrar',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                // Yeniden kod gönder butonu
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_canResend)
                      TextButton(
                        onPressed: () async {
                          await _sendPasswordResetCode(_resetEmail);
                          _startResendTimer();
                          setState(() {});
                        },
                        child: const Text('Yeniden Kod Gönder'),
                      )
                    else
                      Text(
                        'Yeniden kod gönderebilirsiniz: ${_resendTimer}s',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (codeController.text == _resetCode) {
                    if (newPasswordController.text == confirmPasswordController.text) {
                      if (newPasswordController.text.length >= 6) {
                        _resetPassword(newPasswordController.text);
                        Navigator.pop(context);
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Şifre en az 6 karakter olmalı'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Şifreler eşleşmiyor'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Doğrulama kodu hatalı'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Şifreyi Sıfırla'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Şifre sıfırlama
  Future<void> _resetPassword(String newPassword) async {
    try {
      // Firebase'e yeni şifreyi kaydet
      await _adminSettingsService.updateAdminPassword(newPassword);
      
      // Global şifre değişkenini güncelle
      adminPassword = newPassword;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şifreniz başarıyla sıfırlandı!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Şifre sıfırlanırken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

      // Yeniden kod gönder timer'ı
      void _startResendTimer() {
        _resendTimer = 30;
        _canResend = false;

        Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_resendTimer > 0) {
            _resendTimer--;
            setState(() {});
          } else {
            _canResend = true;
            timer.cancel();
            setState(() {});
          }
        });
      }


}