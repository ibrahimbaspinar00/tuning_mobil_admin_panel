// lib/services/gmail_smtp_service.dart
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GmailSMTPService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Gmail SMTP ayarları - Firebase'den yüklenecek
  static String? _gmailUsername;
  static String? _gmailAppPassword;
  
  // Firebase'den Gmail SMTP ayarlarını yükle
  static Future<void> _loadCredentials() async {
    try {
      final settingsDoc = await _firestore
          .collection('admin_settings')
          .doc('system_settings')
          .get();
      
      if (settingsDoc.exists) {
        final data = settingsDoc.data();
        _gmailUsername = data?['gmailUsername'] as String?;
        _gmailAppPassword = data?['gmailAppPassword'] as String?;
      }
    } catch (e) {
      print('❌ Gmail SMTP ayarları yüklenirken hata: $e');
    }
  }
  
  // Gmail SMTP ayarlarını Firebase'e kaydet
  static Future<bool> saveCredentials(String username, String appPassword) async {
    try {
      await _firestore
          .collection('admin_settings')
          .doc('system_settings')
          .set({
        'gmailUsername': username.trim(),
        'gmailAppPassword': appPassword.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Cache'i güncelle
      _gmailUsername = username.trim();
      _gmailAppPassword = appPassword.trim();
      
      return true;
    } catch (e) {
      print('❌ Gmail SMTP ayarları kaydedilirken hata: $e');
      return false;
    }
  }
  
  // Gmail SMTP ayarlarını kontrol et
  static Future<bool> _checkCredentials() async {
    // Önce cache'den kontrol et
    if (_gmailUsername != null && _gmailAppPassword != null) {
      if (_gmailUsername!.isNotEmpty && _gmailAppPassword!.isNotEmpty) {
        return true;
      }
    }
    
    // Cache'de yoksa Firebase'den yükle
    await _loadCredentials();
    
    if (_gmailUsername == null || _gmailAppPassword == null) {
      return false;
    }
    
    if (_gmailUsername!.isEmpty || _gmailAppPassword!.isEmpty) {
      return false;
    }
    
    // Varsayılan değerler kontrolü
    if (_gmailUsername == 'your-email@gmail.com' || 
        _gmailAppPassword == 'your-app-password') {
      return false;
    }
    
    return true;
  }
  
  // Gmail API ile email gönderimi (ücretsiz)
  static Future<bool> sendPasswordResetCode(String email, String code) async {
    try {
      print('📧 Gmail SMTP ile email gönderiliyor...');
      print('📧 Alıcı: $email');
      print('📧 Kod: $code');
      
      // Gmail API kullanarak email gönder
      final success = await _sendWithGmailAPI(email, code);
      
      if (success) {
        print('✅ Email başarıyla gönderildi!');
        return true;
      } else {
        print('❌ Email gönderilemedi!');
        return false;
      }
      
    } catch (e) {
      print('❌ Email gönderim hatası: $e');
      return false;
    }
  }
  
  // Gmail SMTP ile gerçek email gönderimi
  static Future<bool> _sendWithGmailAPI(String email, String code) async {
    try {
      // Gmail SMTP ayarları kontrol et
      final hasCredentials = await _checkCredentials();
      if (!hasCredentials) {
        print('❌ Gmail SMTP ayarları yapılmamış!');
        print('📧 Ayarlar sayfasından Gmail SMTP bilgilerinizi girin');
        print('📧 Gmail Username: Gmail adresiniz (örn: example@gmail.com)');
        print('📧 Gmail App Password: Gmail App Password (16 haneli)');
        print('📧 App Password nasıl alınır:');
        print('   1. Google hesabınıza giriş yapın');
        print('   2. Güvenlik > 2 Adımlı Doğrulama > Uygulama şifreleri');
        print('   3. Yeni uygulama şifresi oluşturun');
        return false;
      }
      
      // Kimlik bilgileri kontrol edildi, null olamazlar
      final username = _gmailUsername!;
      final appPassword = _gmailAppPassword!;
      
      print('📧 Gmail SMTP ile gerçek email gönderiliyor...');
      print('📧 Gönderen: $username');
      print('📧 Alıcı: $email');
      
      // SMTP sunucusu oluştur
      final smtpServer = gmail(
        username,
        appPassword.replaceAll(' ', ''), // Boşlukları kaldır
      );
      
      // Email mesajı oluştur
      final message = Message()
        ..from = Address(username, 'Tuning App Admin Panel')
        ..recipients.add(email)
        ..subject = 'Şifre Sıfırlama Kodunuz'
        ..text = '''
Merhaba,

Şifre sıfırlama talebiniz alınmıştır.

Doğrulama Kodunuz: $code

Bu kodu kullanarak yeni şifrenizi belirleyebilirsiniz.

Not: Bu kod 10 dakika geçerlidir.

Güvenliğiniz için bu kodu kimseyle paylaşmayın.

İyi günler,
Tuning App Admin Paneli
        ''';
      
      // Email gönder
      final sendReport = await send(message, smtpServer);
      
      print('✅ Gmail SMTP ile email gönderildi!');
      print('📧 Message ID: ${sendReport.toString()}');
      return true;
      
    } catch (e) {
      print('❌ Gmail SMTP hatası: $e');
      return false;
    }
  }
  
  // Test email gönder
  static Future<bool> sendTestEmail(String email) async {
    try {
      print('📧 Test email gönderiliyor...');
      print('📧 Alıcı: $email');
      
      // Gmail SMTP ayarları kontrol et
      final hasCredentials = await _checkCredentials();
      if (!hasCredentials) {
        print('❌ Gmail SMTP ayarları yapılmamış!');
        print('📧 Ayarlar sayfasından Gmail SMTP bilgilerinizi girin');
        return false;
      }
      
      // Kimlik bilgileri kontrol edildi, null olamazlar
      final username = _gmailUsername!;
      final appPassword = _gmailAppPassword!;
      
      final smtpServer = gmail(
        username,
        appPassword.replaceAll(' ', ''),
      );
      
      final message = Message()
        ..from = Address(username, 'Tuning App Admin Panel')
        ..recipients.add(email)
        ..subject = 'Test Email'
        ..text = 'Bu bir test emailidir.';
      
      await send(message, smtpServer);
      print('✅ Test email gönderildi!');
      return true;
      
    } catch (e) {
      print('❌ Test email hatası: $e');
      return false;
    }
  }
}
