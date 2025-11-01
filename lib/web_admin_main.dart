import 'package:flutter/material.dart';
import 'dart:async';
import 'web_admin_dashboard.dart';
import 'model/admin_user.dart';
import 'services/permission_service.dart';
import 'services/admin_settings_service.dart';
import 'services/admin_service.dart';
import 'services/email_service.dart';
import 'services/firebase_email_service.dart';
import 'services/gmail_smtp_service.dart';
import 'services/sendgrid_free_service.dart';

// Global admin şifre değişkeni
String adminPassword = 'admin123';

// Global admin kullanıcı adı değişkeni
String adminUsername = 'admin';

class WebAdminApp extends StatelessWidget {
  const WebAdminApp({super.key});

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
      final settings = await _adminSettingsService.getAdminSettings();
      if (settings != null) {
        if (mounted) {
          setState(() {
            adminUsername = settings.adminUsername;
            adminPassword = settings.adminPassword;
          });
        }
        // Firebase'den admin ayarları yüklendi
      } else {
        // Varsayılan ayarları oluştur
        await _adminSettingsService.createDefaultAdminSettings();
        // Varsayılan admin ayarları oluşturuldu
      }
    } catch (e) {
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
      
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Her giriş denemesinde Firebase'den admin ayarlarını yükle
        await _loadAdminSettings();
        
        if (!mounted) return;
        
        // Debug: Admin bilgilerini konsola yazdır
        debugPrint('Admin Username: $adminUsername');
        debugPrint('Admin Password: $adminPassword');
        debugPrint('Entered Username: ${_usernameController.text}');
        debugPrint('Entered Password: ${_passwordController.text}');
        
        final enteredUsername = _usernameController.text.trim();
        final enteredPassword = _passwordController.text.trim();
        
        // Önce admin_users koleksiyonundan kontrol et
        final adminService = AdminService();
        final adminUsers = await adminService.getUsers().first;
        
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
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            // Admin için tüm yetkileri ayarla
            PermissionService.setCurrentUser(
              'admin',
              ['all'], // Admin tüm yetkilere sahip
              username: adminUser.username,
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
        
        // Global admin kontrolü (fallback - varsayılan admin)
        final expectedUsername = adminUsername.trim().toLowerCase();
        final expectedPassword = adminPassword.trim();
        
        if (enteredUsername.toLowerCase() == expectedUsername && enteredPassword == expectedPassword) {
          // Global admin girişi başarılı
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            // Admin için tüm yetkileri ayarla
            PermissionService.setCurrentUser(
              'admin',
              ['all'], // Admin tüm yetkilere sahip
              username: adminUsername,
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
        
        // Normal kullanıcı kontrolü (Admin rolü olmayanlar) - Daha esnek karşılaştırma
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
            debugPrint('Found normal user: ${user.username}');
            break;
          }
        }
        
        final normalUser = foundNormalUser ?? AdminUser(
          id: '',
          username: '',
          email: '',
          fullName: '',
          role: '',
          password: '',
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );
        
        if (normalUser.id.isNotEmpty) {
          // Normal kullanıcı girişi başarılı
          setState(() {
            _isLoading = false;
          });
          // Kullanıcı için temel yetkileri ayarla
          PermissionService.setCurrentUser(
            'user',
            ['view_products', 'view_stock'], // Normal kullanıcı sadece görüntüleme yetkisi
            username: normalUser.username,
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const WebAdminDashboard(),
            ),
          );
        } else {
          // Kullanıcı bulunamadı veya pasif
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            final enteredUser = _usernameController.text.trim();
            final enteredPass = _passwordController.text.trim();
            
            // Detaylı hata mesajı
            String errorMessage = 'Giriş başarısız!\n\n';
            errorMessage += 'Girilen bilgiler:\n';
            errorMessage += 'Kullanıcı adı: "$enteredUser"\n';
            errorMessage += 'Şifre: "${enteredPass.isNotEmpty ? '***' : '(boş)'}"\n\n';
            
            // Admin users koleksiyonundaki kullanıcıları göster
            if (adminUsers.isNotEmpty) {
              errorMessage += 'Kayıtlı kullanıcılar:\n';
              for (var user in adminUsers.take(5)) {
                errorMessage += '- ${user.username} (Rol: ${user.role}, Aktif: ${user.isActive})\n';
              }
            }
            
            errorMessage += '\nVarsayılan admin:\nKullanıcı adı: $adminUsername\nŞifre: $adminPassword';
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 8),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Giriş hatası: $e'),
              backgroundColor: Colors.red,
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

          // Email servis seçimi dialogu
          final emailService = await _showEmailServiceDialog();
          
          bool emailSent = false;
          
          switch (emailService) {
            case 'simulated':
              // Simüle edilmiş email gönderimi (ücretsiz)
              emailSent = await EmailService.sendPasswordResetCode(email, resetCode);
              break;
            case 'gmail':
              // Gmail SMTP ile email gönderimi (ücretsiz)
              emailSent = await GmailSMTPService.sendPasswordResetCode(email, resetCode);
              break;
            case 'sendgrid':
              // SendGrid ücretsiz plan ile email gönderimi
              emailSent = await SendGridFreeService.sendPasswordResetCode(email, resetCode);
              break;
            case 'firebase':
              // Firebase Functions ile email gönderimi (ücretli)
              emailSent = await FirebaseEmailService.sendPasswordResetCode(email, resetCode);
              break;
            default:
              // Varsayılan olarak simüle edilmiş email
              emailSent = await EmailService.sendPasswordResetCode(email, resetCode);
          }

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
                  content: Text('Doğrulama kodu $email adresine gönderildi!'),
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

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Email gönderilemedi. Lütfen tekrar deneyin.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }

        } catch (e) {
          setState(() {
            _isLoading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Kod gönderilirken hata oluştu: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
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

      // Email servis seçimi dialogu
      Future<String> _showEmailServiceDialog() async {
        return await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Email Servis Seçimi'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Hangi email servisini kullanmak istiyorsunuz?'),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.sim_card, color: Colors.blue),
                  title: const Text('Simüle Edilmiş Email'),
                  subtitle: const Text('Ücretsiz - Sadece konsola yazdırır'),
                  onTap: () => Navigator.pop(context, 'simulated'),
                ),
                ListTile(
                  leading: const Icon(Icons.email, color: Colors.green),
                  title: const Text('Gmail SMTP'),
                  subtitle: const Text('Ücretsiz - Gmail hesabı gerekli'),
                  onTap: () => Navigator.pop(context, 'gmail'),
                ),
                ListTile(
                  leading: const Icon(Icons.cloud, color: Colors.orange),
                  title: const Text('SendGrid Ücretsiz'),
                  subtitle: const Text('100 email/gün - API key gerekli'),
                  onTap: () => Navigator.pop(context, 'sendgrid'),
                ),
                ListTile(
                  leading: const Icon(Icons.cloud, color: Colors.red),
                  title: const Text('Firebase Functions'),
                  subtitle: const Text('Ücretli - Billing gerekli'),
                  onTap: () => Navigator.pop(context, 'firebase'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'simulated'),
                child: const Text('Varsayılan (Simüle)'),
              ),
            ],
          ),
        ) ?? 'simulated';
      }

}