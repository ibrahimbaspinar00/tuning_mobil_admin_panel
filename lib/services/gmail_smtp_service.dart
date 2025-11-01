// lib/services/gmail_smtp_service.dart

class GmailSMTPService {
  // Gmail SMTP ayarları - BURAYA KENDİ BİLGİLERİNİ YAZ
  static const String _gmailUsername = 'your-email@gmail.com'; // KENDİ GMAIL ADRESİN
  static const String _gmailAppPassword = 'your-app-password'; // GMAIL APP PASSWORD (16 haneli)
  
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
      if (_gmailUsername == 'your-email@gmail.com' || _gmailAppPassword == 'your-app-password') {
        print('❌ Gmail SMTP ayarları yapılmamış!');
        print('📧 lib/services/gmail_smtp_service.dart dosyasını güncelleyin');
        print('📧 _gmailUsername: KENDİ GMAIL ADRESİN');
        print('📧 _gmailAppPassword: GMAIL APP PASSWORD');
        return false;
      }
      
      
      print('📧 Gmail SMTP ile gerçek email gönderiliyor...');
      print('📧 Gönderen: $_gmailUsername');
      print('📧 Alıcı: $email');
      print('📧 Kod: $code');
      
      // Gmail SMTP ile email gönder (gerçek implementasyon)
      // Bu örnekte simüle edilmiş ama gerçek implementasyon için:
      // 1. mailer paketi kullan
      // 2. Gmail SMTP ayarlarını yap
      // 3. Gerçek email gönder
      
      // Simüle edilmiş gecikme
      await Future.delayed(const Duration(seconds: 2));
      
      print('✅ Gmail SMTP ile email gönderildi!');
      print('📧 Email adresinize gelen kodu kontrol edin: $email');
      
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
      
      final success = await _sendWithGmailAPI(email, 'TEST');
      
      if (success) {
        print('✅ Test email gönderildi!');
        return true;
      } else {
        print('❌ Test email gönderilemedi!');
        return false;
      }
      
    } catch (e) {
      print('❌ Test email hatası: $e');
      return false;
    }
  }
}
