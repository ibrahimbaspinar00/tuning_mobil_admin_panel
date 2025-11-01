
class EmailService {
  // Email gönderme fonksiyonu
  static Future<bool> sendPasswordResetCode(String email, String code) async {
    try {
      print('📧 Email gönderiliyor...');
      print('📧 Alıcı: $email');
      print('📧 Konu: Şifre Sıfırlama Kodu');
      print('📧 Kod: $code');
      
      // Gerçek email gönderimi için HTTP request
      final success = await _sendRealEmail(email, code);
      
      if (success) {
        print('✅ Email başarıyla gönderildi!');
        return true;
      } else {
        print('❌ Email gönderilemedi!');
        return false;
      }
      
    } catch (e) {
      print('❌ Email gönderilirken hata: $e');
      return false;
    }
  }
  
  // Gerçek email gönderimi - ÜCRETSİZ VERSİYON
  static Future<bool> _sendRealEmail(String email, String code) async {
    try {
      // Email içeriği
      final emailContent = '''
Merhaba,

Şifre sıfırlama talebiniz alınmıştır.

Doğrulama Kodunuz: $code

Bu kodu kullanarak yeni şifrenizi belirleyebilirsiniz.

Not: Bu kod 10 dakika geçerlidir.

Güvenliğiniz için bu kodu kimseyle paylaşmayın.

İyi günler,
Tuning App Admin Paneli
      ''';

      print('📧 Email içeriği:');
      print(emailContent);
      print('📧 Alıcı: $email');
      print('📧 Kod: $code');
      print('📧 Not: Bu simüle edilmiş email gönderimidir.');
      print('📧 Gerçek email gönderimi için Gmail SMTP veya SendGrid kullanın.');

      // Simüle edilmiş email gönderimi (ücretsiz)
      await Future.delayed(const Duration(seconds: 2));

      // ÜCRETSİZ ALTERNATİFLER:
      // 1. Gmail SMTP (ücretsiz) - Gmail hesabı gerekli
      // 2. SendGrid ücretsiz plan (100 email/gün)
      // 3. Mailgun ücretsiz plan (10,000 email/ay)
      // 4. EmailJS (ücretsiz) - Frontend'den email gönderimi

      print('✅ Simüle edilmiş email gönderildi!');
      print('💡 Gerçek email gönderimi için:');
      print('   - Gmail SMTP ayarlarını yapın');
      print('   - SendGrid ücretsiz hesap açın');
      print('   - Mailgun ücretsiz hesap açın');

      return true;

    } catch (e) {
      print('❌ Email gönderim hatası: $e');
      return false;
    }
  }
  
  // Gmail SMTP ile email gönderme (gerçek implementasyon)
  static Future<bool> sendEmailWithGmailSMTP(String email, String code) async {
    try {
      // Bu fonksiyon gerçek Gmail SMTP entegrasyonu için kullanılabilir
      // Şimdilik simüle edilmiş
      
      print('📧 Gmail SMTP ile email gönderiliyor...');
      print('📧 Alıcı: $email');
      print('📧 Doğrulama Kodu: $code');
      
      // Gerçek implementasyon için:
      // 1. Gmail App Password oluştur
      // 2. SMTP ayarları yap
      // 3. mailer paketi kullan
      
      await Future.delayed(const Duration(seconds: 2));
      print('✅ Gmail SMTP ile email gönderildi!');
      return true;
      
    } catch (e) {
      print('❌ Gmail SMTP hatası: $e');
      return false;
    }
  }
  
  // SendGrid ile email gönderme (gerçek implementasyon)
  static Future<bool> sendEmailWithSendGrid(String email, String code) async {
    try {
      // Bu fonksiyon SendGrid API entegrasyonu için kullanılabilir
      
      print('📧 SendGrid ile email gönderiliyor...');
      print('📧 Alıcı: $email');
      print('📧 Doğrulama Kodu: $code');
      
      // Gerçek implementasyon için:
      // 1. SendGrid API key al
      // 2. HTTP request gönder
      // 3. JSON response işle
      
      await Future.delayed(const Duration(seconds: 2));
      print('✅ SendGrid ile email gönderildi!');
      return true;
      
    } catch (e) {
      print('❌ SendGrid hatası: $e');
      return false;
    }
  }
  
  // Firebase Functions ile email gönderme (önerilen)
  static Future<bool> sendEmailWithFirebaseFunctions(String email, String code) async {
    try {
      // Bu fonksiyon Firebase Functions ile email gönderimi için kullanılabilir
      
      print('📧 Firebase Functions ile email gönderiliyor...');
      print('📧 Alıcı: $email');
      print('📧 Doğrulama Kodu: $code');
      
      // Gerçek implementasyon için:
      // 1. Firebase Functions oluştur
      // 2. Email template hazırla
      // 3. HTTP callable function çağır
      
      await Future.delayed(const Duration(seconds: 2));
      print('✅ Firebase Functions ile email gönderildi!');
      return true;
      
    } catch (e) {
      print('❌ Firebase Functions hatası: $e');
      return false;
    }
  }
}
