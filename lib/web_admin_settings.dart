import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/permission_service.dart';
import 'services/admin_service.dart';
import 'services/gmail_smtp_service.dart';
import 'services/sendgrid_free_service.dart';

class WebAdminSettings extends StatefulWidget {
  const WebAdminSettings({super.key});

  @override
  State<WebAdminSettings> createState() => _WebAdminSettingsState();
}

class _WebAdminSettingsState extends State<WebAdminSettings> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AdminService _adminService = AdminService();
  
  bool _isLoading = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isSearchVisible = false;
  
  // Ayarlar durumu
  bool _isDarkMode = false;
  bool _autoBackup = true;
  bool _lowStockNotification = true;
  bool _newOrderNotification = true;
  bool _emailNotification = false;
  
  // Kullanıcı adı değiştirme
  final _usernameController = TextEditingController();
  
  // FCM Server Key
  final _fcmServerKeyController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _showFcmKey = false;
  
  // Gmail SMTP Ayarları
  final _gmailUsernameController = TextEditingController();
  final _gmailAppPasswordController = TextEditingController();
  bool _showGmailPassword = false;
  
  // SendGrid Ayarları
  final _sendGridApiKeyController = TextEditingController();
  final _sendGridSenderEmailController = TextEditingController();
  bool _showSendGridKey = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadFcmServerKey();
    _loadGmailCredentials();
    _loadSendGridCredentials();
  }

  @override
  void dispose() {
    _fcmServerKeyController.dispose();
    _gmailUsernameController.dispose();
    _gmailAppPasswordController.dispose();
    _sendGridApiKeyController.dispose();
    _sendGridSenderEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _adminService.getSettings();
      setState(() {
        _isDarkMode = settings['isDarkMode'] ?? false;
        _autoBackup = settings['autoBackup'] ?? true;
        _lowStockNotification = settings['lowStockNotification'] ?? true;
        _newOrderNotification = settings['newOrderNotification'] ?? true;
        _emailNotification = settings['emailNotification'] ?? false;
      });
    } catch (e) {
      // Hata durumunda varsayılan değerler kullanılır
    }
  }

  Future<void> _loadFcmServerKey() async {
    try {
      final settingsDoc = await _firestore.collection('admin_settings').doc('system_settings').get();
      if (settingsDoc.exists) {
        final data = settingsDoc.data();
        if (data?['fcmServerKey'] != null) {
          _fcmServerKeyController.text = data!['fcmServerKey'].toString();
        }
      }
    } catch (e) {
      debugPrint('FCM Server Key yüklenirken hata: $e');
    }
  }

  Future<void> _saveFcmServerKey() async {
    try {
      await _firestore.collection('admin_settings').doc('system_settings').set({
        'fcmServerKey': _fcmServerKeyController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('FCM Server Key başarıyla kaydedildi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('FCM Server Key kaydedilemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadGmailCredentials() async {
    try {
      final settingsDoc = await _firestore.collection('admin_settings').doc('system_settings').get();
      if (settingsDoc.exists) {
        final data = settingsDoc.data();
        if (data?['gmailUsername'] != null) {
          _gmailUsernameController.text = data!['gmailUsername'].toString();
        }
        if (data?['gmailAppPassword'] != null) {
          _gmailAppPasswordController.text = data!['gmailAppPassword'].toString();
        }
      }
    } catch (e) {
      debugPrint('Gmail SMTP ayarları yüklenirken hata: $e');
    }
  }

  Future<void> _saveGmailCredentials() async {
    if (_gmailUsernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gmail adresi boş olamaz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_gmailAppPasswordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gmail App Password boş olamaz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final success = await GmailSMTPService.saveCredentials(
        _gmailUsernameController.text.trim(),
        _gmailAppPasswordController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
                ? 'Gmail SMTP ayarları başarıyla kaydedildi!'
                : 'Gmail SMTP ayarları kaydedilemedi'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gmail SMTP ayarları kaydedilirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadSendGridCredentials() async {
    try {
      final settingsDoc = await _firestore.collection('admin_settings').doc('system_settings').get();
      if (settingsDoc.exists) {
        final data = settingsDoc.data();
        if (data?['sendGridApiKey'] != null) {
          _sendGridApiKeyController.text = data!['sendGridApiKey'].toString();
        }
        if (data?['sendGridSenderEmail'] != null) {
          _sendGridSenderEmailController.text = data!['sendGridSenderEmail'].toString();
        }
      }
    } catch (e) {
      debugPrint('SendGrid ayarları yüklenirken hata: $e');
    }
  }

  Future<void> _saveSendGridCredentials() async {
    if (_sendGridApiKeyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SendGrid API Key boş olamaz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_sendGridSenderEmailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SendGrid Sender Email boş olamaz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final success = await SendGridFreeService.saveCredentials(
        _sendGridApiKeyController.text.trim(),
        _sendGridSenderEmailController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
                ? 'SendGrid ayarları başarıyla kaydedildi!'
                : 'SendGrid ayarları kaydedilemedi'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SendGrid ayarları kaydedilirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama çubuğu
          if (_isSearchVisible)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Ayarlarda ara...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          
          // Ana içerik
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık
                  Text(
                    'Sistem Ayarları',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hesap ve sistem ayarlarınızı buradan yönetebilirsiniz',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Kullanıcı Bilgileri Kartı
                  _buildUserInfoCard(),
                  const SizedBox(height: 24),

                  // Şifre Değiştirme Kartı
                  _buildPasswordChangeCard(),
                  const SizedBox(height: 24),

                  // Sistem Ayarları Kartı
                  _buildSystemSettingsCard(),
                  const SizedBox(height: 24),

                  // Bildirim Ayarları Kartı
                  _buildNotificationSettingsCard(),
                  const SizedBox(height: 24),

                  // FCM Server Key Kartı
                  _buildFcmServerKeyCard(),
                  const SizedBox(height: 24),

                  // Gmail SMTP Ayarları Kartı
                  _buildGmailSmtpCard(),
                  const SizedBox(height: 24),

                  // SendGrid Ayarları Kartı
                  _buildSendGridCard(),
                  const SizedBox(height: 24),

                  // Hakkında Kartı
                  _buildAboutCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.purple[600], size: 24),
                const SizedBox(width: 12),
                Text(
                  'Kullanıcı Bilgileri',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Mevcut kullanıcı bilgileri
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_circle, size: 40, color: Colors.purple),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Kullanıcı adı - Anlık güncelleme
                            StreamBuilder<String>(
                              stream: Stream.periodic(const Duration(milliseconds: 500), (_) => PermissionService.getCurrentUserName() ?? 'admin'),
                              builder: (context, snapshot) {
                                return Text(
                                  'Kullanıcı Adı: ${snapshot.data ?? 'admin'}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple[800],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Yetki: ${_getUserRoleDisplay()}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.purple[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _showChangeUsernameDialog,
                        icon: const Icon(Icons.edit, color: Colors.purple),
                        tooltip: 'Kullanıcı adını değiştir',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordChangeCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock, color: Colors.purple[600], size: 24),
                const SizedBox(width: 12),
                Text(
                  'Şifre Değiştir',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Mevcut şifre
                  TextFormField(
                    controller: _currentPasswordController,
                    obscureText: !_showCurrentPassword,
                    decoration: InputDecoration(
                      labelText: 'Mevcut Şifre',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_showCurrentPassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _showCurrentPassword = !_showCurrentPassword),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Mevcut şifre gerekli';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Yeni şifre
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: !_showNewPassword,
                    decoration: InputDecoration(
                      labelText: 'Yeni Şifre',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_showNewPassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _showNewPassword = !_showNewPassword),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Yeni şifre gerekli';
                      }
                      if (value.length < 6) {
                        return 'Şifre en az 6 karakter olmalı';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Şifre onayı
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_showConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Şifre Onayı',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_showConfirmPassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Şifre onayı gerekli';
                      }
                      if (value != _newPasswordController.text) {
                        return 'Şifreler eşleşmiyor';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Şifre değiştir butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Şifre Değiştir',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemSettingsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.purple[600], size: 24),
                const SizedBox(width: 12),
                Text(
                  'Sistem Ayarları',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Tema ayarı
            ListTile(
              leading: Icon(_isDarkMode ? Icons.dark_mode : Icons.light_mode, color: Colors.purple[600]),
              title: const Text('Tema'),
              subtitle: Text(_isDarkMode ? 'Karanlık Tema' : 'Açık Tema'),
              trailing: Switch(
                value: _isDarkMode,
                onChanged: (value) => _changeTheme(),
                activeThumbColor: Colors.purple[600],
              ),
            ),
            
            // Dil ayarı
            ListTile(
              leading: const Icon(Icons.language, color: Colors.purple),
              title: const Text('Dil'),
              subtitle: const Text('Türkçe'),
              trailing: IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: _showLanguageDialog,
              ),
            ),
            
            // Otomatik yedekleme
            ListTile(
              leading: const Icon(Icons.backup, color: Colors.purple),
              title: const Text('Otomatik Yedekleme'),
              subtitle: const Text('Günlük otomatik yedekleme'),
              trailing: Switch(
                value: _autoBackup,
                onChanged: (value) => _toggleAutoBackup(),
                activeThumbColor: Colors.purple[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettingsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications, color: Colors.purple[600], size: 24),
                const SizedBox(width: 12),
                Text(
                  'Bildirim Ayarları',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Düşük stok bildirimi
            ListTile(
              leading: const Icon(Icons.warning, color: Colors.orange),
              title: const Text('Düşük Stok Bildirimi'),
              subtitle: const Text('Stok seviyesi düştüğünde bildirim al'),
              trailing: Switch(
                value: _lowStockNotification,
                onChanged: (value) => _toggleLowStockNotification(),
                activeThumbColor: Colors.purple[600],
              ),
            ),
            
            // Yeni sipariş bildirimi
            ListTile(
              leading: const Icon(Icons.shopping_cart, color: Colors.green),
              title: const Text('Yeni Sipariş Bildirimi'),
              subtitle: const Text('Yeni sipariş geldiğinde bildirim al'),
              trailing: Switch(
                value: _newOrderNotification,
                onChanged: (value) => _toggleNewOrderNotification(),
                activeThumbColor: Colors.purple[600],
              ),
            ),
            
            // E-posta bildirimi
            ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: const Text('E-posta Bildirimi'),
              subtitle: const Text('Önemli olaylarda e-posta bildirimi al'),
              trailing: Switch(
                value: _emailNotification,
                onChanged: (value) => _toggleEmailNotification(),
                activeThumbColor: Colors.purple[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFcmServerKeyCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_upload, color: Colors.purple[600], size: 24),
                const SizedBox(width: 12),
                Text(
                  'FCM Push Notification Ayarları',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'FCM Server Key Nasıl Alınır?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '⚠️ ÖNEMLİ: Firebase artık Server Key\'i kaldırdı!\n\n'
                    'Çözüm 1 - Legacy Server Key (Hala çalışıyorsa):\n'
                    '1. Firebase Console > Project Settings > Cloud Messaging\n'
                    '2. Eğer "Server key" görünüyorsa kopyalayın\n'
                    '3. Yoksa aşağıdaki Çözüm 2\'yi kullanın\n\n'
                    'Çözüm 2 - Service Account (Önerilen):\n'
                    '1. Firebase Console > Project Settings > Service Accounts\n'
                    '2. "Generate new private key" butonuna tıklayın\n'
                    '3. İndirilen JSON dosyasını masaüstüne kaydedin\n'
                    '4. Service Account aktif - bildirimler Firestore üzerinden gönderilecek',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[800],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _fcmServerKeyController,
              obscureText: !_showFcmKey,
              decoration: InputDecoration(
                labelText: 'FCM Server Key',
                hintText: 'AAAA...',
                prefixIcon: const Icon(Icons.vpn_key),
                suffixIcon: IconButton(
                  icon: Icon(_showFcmKey ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _showFcmKey = !_showFcmKey),
                ),
                border: const OutlineInputBorder(),
                helperText: 'Push notification göndermek için gerekli',
              ),
            ),
            const SizedBox(height: 16),
            
            ElevatedButton.icon(
              onPressed: _fcmServerKeyController.text.trim().isEmpty ? null : _saveFcmServerKey,
              icon: const Icon(Icons.save),
              label: const Text('FCM Server Key Kaydet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGmailSmtpCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.email, color: Colors.purple[600], size: 24),
                const SizedBox(width: 12),
                Text(
                  'Gmail SMTP Ayarları',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.green[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Gmail App Password Nasıl Alınır?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Google hesabınıza giriş yapın\n'
                    '2. Google Hesap Ayarları > Güvenlik\n'
                    '3. "2 Adımlı Doğrulama" özelliğini açın (gerekirse)\n'
                    '4. "Uygulama şifreleri" bölümüne gidin\n'
                    '5. "Uygulama seç" > "E-posta" seçin\n'
                    '6. "Cihaz seç" > "Diğer (Özel ad)" yazın\n'
                    '7. "Oluştur" butonuna tıklayın\n'
                    '8. 16 haneli şifreyi kopyalayın ve aşağıya yapıştırın\n\n'
                    '⚠️ ÖNEMLİ: Normal Gmail şifrenizi değil, App Password kullanın!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[800],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _gmailUsernameController,
              decoration: const InputDecoration(
                labelText: 'Gmail Adresi',
                hintText: 'example@gmail.com',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
                helperText: 'Email göndermek için kullanılacak Gmail adresi',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _gmailAppPasswordController,
              obscureText: !_showGmailPassword,
              decoration: InputDecoration(
                labelText: 'Gmail App Password',
                hintText: '16 haneli şifre',
                prefixIcon: const Icon(Icons.vpn_key),
                suffixIcon: IconButton(
                  icon: Icon(_showGmailPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _showGmailPassword = !_showGmailPassword),
                ),
                border: const OutlineInputBorder(),
                helperText: 'Gmail App Password (16 haneli)',
              ),
            ),
            const SizedBox(height: 16),
            
            ElevatedButton.icon(
              onPressed: _gmailUsernameController.text.trim().isEmpty || 
                        _gmailAppPasswordController.text.trim().isEmpty 
                  ? null 
                  : _saveGmailCredentials,
              icon: const Icon(Icons.save),
              label: const Text('Gmail SMTP Ayarlarını Kaydet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendGridCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.send, color: Colors.purple[600], size: 24),
                const SizedBox(width: 12),
                Text(
                  'SendGrid Ayarları',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'SendGrid API Key Nasıl Alınır?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. SendGrid hesabı oluşturun (ücretsiz plan: 100 email/gün)\n'
                    '2. SendGrid Dashboard > Settings > API Keys\n'
                    '3. "Create API Key" butonuna tıklayın\n'
                    '4. API Key adı verin (örn: "Admin Panel")\n'
                    '5. "Full Access" veya "Mail Send" izni verin\n'
                    '6. Oluşturulan API Key\'i kopyalayın ve aşağıya yapıştırın\n'
                    '7. Sender Email: SendGrid\'de doğrulanmış email adresiniz\n\n'
                    '⚠️ ÖNEMLİ: Sender Email SendGrid\'de doğrulanmış olmalı!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[800],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _sendGridApiKeyController,
              obscureText: !_showSendGridKey,
              decoration: InputDecoration(
                labelText: 'SendGrid API Key',
                hintText: 'SG.xxxxxxxxxxxxx',
                prefixIcon: const Icon(Icons.vpn_key),
                suffixIcon: IconButton(
                  icon: Icon(_showSendGridKey ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _showSendGridKey = !_showSendGridKey),
                ),
                border: const OutlineInputBorder(),
                helperText: 'SendGrid API Key (SG. ile başlar)',
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _sendGridSenderEmailController,
              decoration: const InputDecoration(
                labelText: 'Sender Email',
                hintText: 'noreply@yourdomain.com',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
                helperText: 'SendGrid\'de doğrulanmış gönderen email adresi',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            
            ElevatedButton.icon(
              onPressed: _sendGridApiKeyController.text.trim().isEmpty || 
                        _sendGridSenderEmailController.text.trim().isEmpty 
                  ? null 
                  : _saveSendGridCredentials,
              icon: const Icon(Icons.save),
              label: const Text('SendGrid Ayarlarını Kaydet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.purple[600], size: 24),
                const SizedBox(width: 12),
                Text(
                  'Hakkında',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.apps),
              title: const Text('Uygulama Adı'),
              subtitle: const Text('Tuning Mobil Admin Panel'),
            ),
            
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('Versiyon'),
              subtitle: const Text('1.0.0'),
            ),
            
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Son Güncelleme'),
              subtitle: Text('${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
            ),
            
            ListTile(
              leading: const Icon(Icons.developer_mode),
              title: const Text('Geliştirici'),
              subtitle: const Text('Tuning Mobil Team'),
            ),
            
            const SizedBox(height: 16),
            
            // Geliştirici bilgileri
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Geliştirici Bilgileri',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Bu uygulama Flutter ile geliştirilmiştir.'),
                  const Text('Firebase backend servisleri kullanılmaktadır.'),
                  const Text('Modern ve kullanıcı dostu arayüz tasarımı.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getUserRoleDisplay() {
    return 'Yönetici';
  }

  void _showChangeUsernameDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcı Adı Değiştir'),
        content: TextField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: 'Yeni kullanıcı adı',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: _changeUsername,
            child: const Text('Değiştir'),
          ),
        ],
      ),
    );
  }

  void _changeUsername() async {
    if (_usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcı adı boş olamaz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);
      
      // Kullanıcı adı değiştirme işlemi burada yapılacak
      await Future.delayed(const Duration(seconds: 1)); // Simüle edilmiş işlem
      
      Navigator.pop(context);
      _usernameController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcı adı başarıyla güncellendi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kullanıcı adı güncellenirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _changePassword() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() => _isLoading = true);
        
        // Şifre değiştirme işlemi burada yapılacak
        await Future.delayed(const Duration(seconds: 1)); // Simüle edilmiş işlem
        
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şifre başarıyla değiştirildi'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Şifre değiştirilirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _changeTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isDarkMode ? 'Karanlık tema aktif' : 'Açık tema aktif'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dil Seçimi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Türkçe'),
              onTap: () => _changeLanguage('tr'),
            ),
            ListTile(
              title: const Text('English'),
              onTap: () => _changeLanguage('en'),
            ),
            ListTile(
              title: const Text('العربية'),
              onTap: () => _changeLanguage('ar'),
            ),
          ],
        ),
      ),
    );
  }

  void _changeLanguage(String languageCode) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dil değiştirildi: $languageCode'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _toggleAutoBackup() {
    setState(() {
      _autoBackup = !_autoBackup;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_autoBackup ? 'Otomatik yedekleme aktif' : 'Otomatik yedekleme pasif'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _toggleLowStockNotification() {
    setState(() {
      _lowStockNotification = !_lowStockNotification;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_lowStockNotification ? 'Düşük stok bildirimi aktif' : 'Düşük stok bildirimi pasif'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _toggleNewOrderNotification() {
    setState(() {
      _newOrderNotification = !_newOrderNotification;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_newOrderNotification ? 'Yeni sipariş bildirimi aktif' : 'Yeni sipariş bildirimi pasif'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _toggleEmailNotification() {
    setState(() {
      _emailNotification = !_emailNotification;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_emailNotification ? 'E-posta bildirimi aktif' : 'E-posta bildirimi pasif'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
