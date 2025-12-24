import 'package:flutter/foundation.dart';
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
import 'utils/responsive_helper.dart';

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
  bool _isInitializing = true; // İlk yükleme durumu
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
            _isInitializing = false; // Yükleme tamamlandı
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
        if (mounted) {
          setState(() {
            _isInitializing = false; // Yükleme tamamlandı
          });
        }
      }
    } on TimeoutException catch (e) {
      debugPrint('⚠️ Admin ayarları yükleme timeout: $e');
      // Varsayılan değerleri kullan
      if (mounted) {
        setState(() {
          adminUsername = 'admin';
          adminPassword = 'admin123';
          _isInitializing = false; // Yükleme tamamlandı
        });
      }
    } catch (e) {
      debugPrint('⚠️ Admin ayarları yüklenirken hata: $e');
      // Admin ayarları yüklenirken hata - varsayılan değerleri kullan
      if (mounted) {
        setState(() {
          adminUsername = 'admin';
          adminPassword = 'admin123';
          _isInitializing = false; // Yükleme tamamlandı
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // İlk yükleme sırasında sadece loading göster
    if (_isInitializing) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue[800]!, Colors.blue[600]!],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 4,
            ),
          ),
        ),
      );
    }
    
    // Responsive design
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
            margin: ResponsiveHelper.responsivePadding(context),
            elevation: 8,
            child: Container(
              width: ResponsiveHelper.responsiveWidth(
                context,
                mobile: 0.9,
                tablet: 0.7,
                laptop: 0.5,
                desktop: 0.45,
              ),
              padding: ResponsiveHelper.responsivePadding(
                context,
                mobile: 20.0,
                tablet: 28.0,
                laptop: 32.0,
                desktop: 36.0,
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Container(
                        width: ResponsiveHelper.responsiveIconSize(
                          context,
                          mobile: 60.0,
                          tablet: 70.0,
                          laptop: 80.0,
                          desktop: 90.0,
                        ),
                        height: ResponsiveHelper.responsiveIconSize(
                          context,
                          mobile: 60.0,
                          tablet: 70.0,
                          laptop: 80.0,
                          desktop: 90.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.admin_panel_settings,
                          size: ResponsiveHelper.responsiveIconSize(
                            context,
                            mobile: 30.0,
                            tablet: 35.0,
                            laptop: 40.0,
                            desktop: 45.0,
                          ),
                          color: Colors.blue[800],
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveHelper.responsiveSpacing(
                          context,
                          mobile: 16.0,
                          tablet: 20.0,
                          laptop: 24.0,
                          desktop: 28.0,
                        ),
                      ),
                      
                      // Başlık
                      Text(
                        'Admin Panel',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.responsiveFontSize(
                            context,
                            mobile: 22.0,
                            tablet: 25.0,
                            laptop: 28.0,
                            desktop: 32.0,
                          ),
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveHelper.responsiveSpacing(
                          context,
                          mobile: 6.0,
                          tablet: 8.0,
                          laptop: 10.0,
                          desktop: 12.0,
                        ),
                      ),
                      Text(
                        'Tuning App Yönetim Paneli',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: ResponsiveHelper.responsiveFontSize(
                            context,
                            mobile: 14.0,
                            tablet: 15.0,
                            laptop: 16.0,
                            desktop: 18.0,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveHelper.responsiveSpacing(
                          context,
                          mobile: 24.0,
                          tablet: 28.0,
                          laptop: 32.0,
                          desktop: 36.0,
                        ),
                      ),
                      
                      // Kullanıcı adı veya E-posta
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Kullanıcı Adı veya E-posta',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                          hintText: 'Kullanıcı adı veya e-posta adresinizi girin',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Kullanıcı adı veya e-posta gerekli';
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
                          // Minimum 1 karakter kontrolü (hiçbir engel yok)
                          if (value.length < 1) {
                            return 'Şifre en az 1 karakter olmalıdır';
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
                          
                          // Şifre unutma ve kayıt ol butonları
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () => _showForgotPasswordDialog(),
                                child: const Text('Şifremi Unuttum'),
                              ),
                              TextButton(
                                onPressed: () => _showRegisterDialog(),
                                child: const Text('Kayıt Ol'),
                              ),
                            ],
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
      
      setState(() {
        _isLoading = true;
      });
      
      try {
        final enteredUsername = _usernameController.text.trim();
        final enteredPassword = _passwordController.text.trim();
        
        if (kDebugMode) {
          debugPrint('Giriş denemesi: username="$enteredUsername", password uzunluğu=${enteredPassword.length}');
        }
        
        // Önce varsayılan admin kontrolü (hızlı ve güvenilir)
        if (enteredUsername.toLowerCase() == 'admin' && enteredPassword == 'admin123') {
          if (kDebugMode) {
            debugPrint('Varsayılan admin ile giriş başarılı');
          }
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
            
            // Audit log (hata olsa bile devam et)
            AuditLogService.logAction(
              userId: 'admin',
              action: 'login',
              resource: 'auth',
              details: {'username': 'admin'},
            ).catchError((e) {
              if (kDebugMode) {
                debugPrint('Audit log hatası: $e');
              }
            });
            
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const WebAdminDashboard(),
              ),
            );
          }
          return;
        }
        
        // Firebase'den admin ayarlarını direkt oku (cache'den değil)
        try {
          final settings = await _adminSettingsService.getAdminSettings()
              .timeout(const Duration(seconds: 8));
          
          if (settings != null) {
            final expectedUsername = settings.adminUsername.trim().toLowerCase();
            final expectedPassword = settings.adminPassword.trim();
            
            if (kDebugMode) {
              debugPrint('Firebase ayarları: username="$expectedUsername", password uzunluğu=${expectedPassword.length}');
            }
            
            if (enteredUsername.toLowerCase() == expectedUsername && 
                enteredPassword == expectedPassword) {
              if (kDebugMode) {
                debugPrint('Firebase admin ayarları ile giriş başarılı');
              }
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                PermissionService.setCurrentUser(
                  'admin',
                  ['all'],
                  username: settings.adminUsername,
                  userId: 'admin',
                );
                
                // Audit log (hata olsa bile devam et)
                AuditLogService.logAction(
                  userId: 'admin',
                  action: 'login',
                  resource: 'auth',
                  details: {'username': settings.adminUsername},
                ).catchError((e) {
                  if (kDebugMode) {
                    debugPrint('Audit log hatası: $e');
                  }
                });
                
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WebAdminDashboard(),
                  ),
                );
              }
              return;
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Admin ayarları yüklenemedi: $e');
          }
          // Devam et, Firestore kullanıcıları kontrol edilecek
        }
        
        if (!mounted) return;
        
        // Firestore'dan admin_users koleksiyonundan kontrol et
        List<AdminUser> adminUsers = [];
        try {
          final adminService = AdminService();
          adminUsers = await adminService.getUsers()
              .timeout(const Duration(seconds: 15))
              .first;
          
          if (kDebugMode) {
            debugPrint('Firestore\'dan ${adminUsers.length} kullanıcı yüklendi');
          }
        } on TimeoutException {
          if (kDebugMode) {
            debugPrint('Firestore timeout - kullanıcılar yüklenemedi');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Firestore kullanıcı getirme hatası: $e');
          }
        }
        
        // Admin kullanıcı kontrolü (hem kullanıcı adı hem e-posta ile)
        AdminUser? foundAdminUser;
        for (var user in adminUsers) {
          final storedUsername = user.username.trim().toLowerCase();
          final storedEmail = user.email.trim().toLowerCase();
          final storedPassword = user.password.trim();
          final enteredUserLower = enteredUsername.toLowerCase();
          
          // Hem kullanıcı adı hem e-posta ile kontrol et
          final isUsernameMatch = storedUsername == enteredUserLower;
          final isEmailMatch = storedEmail == enteredUserLower;
          final isPasswordMatch = storedPassword == enteredPassword;
          
          if (kDebugMode && (isUsernameMatch || isEmailMatch)) {
            debugPrint('Kullanıcı bulundu: username="$storedUsername", email="$storedEmail", active=${user.isActive}, role="${user.role}", şifre eşleşiyor=$isPasswordMatch');
          }
          
          if ((isUsernameMatch || isEmailMatch) &&
              isPasswordMatch &&
              user.isActive &&
              (user.role.toLowerCase() == 'admin' || user.role.toLowerCase() == 'administrator')) {
            foundAdminUser = user;
            if (kDebugMode) {
              debugPrint('Admin kullanıcı ile giriş başarılı: ${user.username} (${isUsernameMatch ? "username" : "email"} ile)');
            }
            break;
          }
        }
        
        if (foundAdminUser != null) {
          // Admin kullanıcı girişi başarılı
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            PermissionService.setCurrentUser(
              'admin',
              ['all'],
              username: foundAdminUser.username,
              userId: foundAdminUser.id,
            );
            
            // Audit log (hata olsa bile devam et)
            AuditLogService.logAction(
              userId: foundAdminUser.id,
              action: 'login',
              resource: 'auth',
              details: {'username': foundAdminUser.username},
            ).catchError((e) {
              if (kDebugMode) {
                debugPrint('Audit log hatası: $e');
              }
            });
            
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const WebAdminDashboard(),
              ),
            );
          }
          return;
        }
        
        // Normal kullanıcı kontrolü (Admin rolü olmayanlar) - hem kullanıcı adı hem e-posta ile
        AdminUser? foundNormalUser;
        for (var user in adminUsers) {
          final storedUsername = user.username.trim().toLowerCase();
          final storedEmail = user.email.trim().toLowerCase();
          final storedPassword = user.password.trim();
          final enteredUserLower = enteredUsername.toLowerCase();
          
          // Hem kullanıcı adı hem e-posta ile kontrol et
          final isUsernameMatch = storedUsername == enteredUserLower;
          final isEmailMatch = storedEmail == enteredUserLower;
          final isPasswordMatch = storedPassword == enteredPassword;
          
          if ((isUsernameMatch || isEmailMatch) &&
              isPasswordMatch &&
              user.isActive &&
              user.role.toLowerCase() != 'admin' &&
              user.role.toLowerCase() != 'administrator') {
            foundNormalUser = user;
            if (kDebugMode) {
              debugPrint('Normal kullanıcı ile giriş başarılı: ${user.username} (${isUsernameMatch ? "username" : "email"} ile)');
            }
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
        if (kDebugMode) {
          debugPrint('Giriş hatası: $e');
        debugPrint('Stack trace: $stackTrace');
        }
        
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
                      _resetPassword(newPasswordController.text);
                      Navigator.pop(context);
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

  // Kayıt olma dialogu
  void _showRegisterDialog() {
    showDialog(
      context: context,
      builder: (context) => _RegisterDialog(
        onRegisterSuccess: (String username) {
          // Kayıt başarılı olduğunda kullanıcı adını login sayfasına aktar
          if (mounted) {
            setState(() {
              _usernameController.text = username;
            });
          }
        },
      ),
    );
  }
}

// Kayıt olma dialog widget'ı
class _RegisterDialog extends StatefulWidget {
  final Function(String username) onRegisterSuccess;

  const _RegisterDialog({
    required this.onRegisterSuccess,
  });

  @override
  State<_RegisterDialog> createState() => _RegisterDialogState();
}

class _RegisterDialogState extends State<_RegisterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final AdminService _adminService = AdminService();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.responsiveBorderRadius(
            context,
            mobile: 16.0,
            tablet: 18.0,
            laptop: 20.0,
            desktop: 22.0,
          ),
        ),
      ),
      child: Container(
        width: ResponsiveHelper.responsiveDialogWidth(context),
        constraints: BoxConstraints(
          maxHeight: ResponsiveHelper.responsiveDialogHeight(context),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Başlık
                  Row(
                    children: [
                      Icon(Icons.person_add, color: Colors.blue[800], size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Yeni Hesap Oluştur',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Kapat',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Kullanıcı adı
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Kullanıcı Adı',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                      hintText: 'Kullanıcı adınızı girin',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Kullanıcı adı gerekli';
                      }
                      if (value.length < 3) {
                        return 'Kullanıcı adı en az 3 karakter olmalıdır';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      // Kullanıcı adı müsaitlik kontrolü (opsiyonel - gerçek zamanlı)
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // E-posta
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'E-posta',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                      hintText: 'E-posta adresinizi girin',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'E-posta gerekli';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Geçerli bir e-posta adresi girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Tam ad
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Tam Ad',
                      prefixIcon: Icon(Icons.badge),
                      border: OutlineInputBorder(),
                      hintText: 'Adınız ve soyadınız',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Tam ad gerekli';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Şifre
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                      hintText: 'Şifrenizi girin (min 1 karakter)',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Şifre gerekli';
                      }
                      if (value.length < 1) {
                        return 'Şifre en az 1 karakter olmalıdır';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Şifre tekrar
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Şifre Tekrar',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                      hintText: 'Şifrenizi tekrar girin',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Şifre tekrar gerekli';
                      }
                      if (value != _passwordController.text) {
                        return 'Şifreler eşleşmiyor';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Kayıt ol butonu
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Kayıt Ol',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Zaten hesabınız var mı?
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Zaten hesabınız var mı? '),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Giriş Yap'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Kullanıcı adı ve e-posta müsaitlik kontrolü
        final usernameAvailable = await _adminService.isUsernameAvailable(
          _usernameController.text.trim(),
        );
        
        if (!usernameAvailable) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bu kullanıcı adı zaten kullanılıyor'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
        
        final emailAvailable = await _adminService.isEmailAvailable(
          _emailController.text.trim(),
        );
        
        if (!emailAvailable) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bu e-posta adresi zaten kullanılıyor'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
        
        // Yeni kullanıcı oluştur
        final newUser = AdminUser(
          id: '', // Boş bırak, AdminService otomatik oluşturacak
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          fullName: _fullNameController.text.trim(),
          role: 'user', // Varsayılan rol: user
          password: _passwordController.text.trim(),
          isActive: true,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );
        
        // Kullanıcıyı kaydet
        await _adminService.addUser(newUser);
        
        // Audit log (username ile, çünkü ID henüz bilinmiyor)
        try {
          await AuditLogService.logAction(
            userId: newUser.username,
            action: 'register',
            resource: 'auth',
            details: {
              'username': newUser.username,
              'email': newUser.email,
              'fullName': newUser.fullName,
            },
          );
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Audit log hatası: $e');
          }
        }
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          // Dialog'u önce kapat
          Navigator.pop(context);
          
          // Kısa bir gecikme sonrası callback çağır (mesaj gösterimi için)
          await Future.delayed(const Duration(milliseconds: 300));
          
          // Callback çağır - kullanıcı adını login sayfasına aktar
          widget.onRegisterSuccess(newUser.username);
          
          // Başarı mesajı - login sayfasında göster
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Kayıt başarılı! ${newUser.username} olarak giriş yapabilirsiniz.'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          String errorMessage = 'Kayıt olurken hata oluştu: $e';
          
          if (e.toString().contains('zaten kullanılıyor')) {
            errorMessage = e.toString().replaceAll('Exception: ', '');
          }
          
          // Hata mesajını göster (dialog açık kalır)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }
}