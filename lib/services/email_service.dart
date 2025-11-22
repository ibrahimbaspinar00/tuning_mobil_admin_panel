import 'gmail_smtp_service.dart';
import 'sendgrid_free_service.dart';
import 'firebase_email_service.dart';

class EmailService {
  // Email gönderme fonksiyonu
  static Future<bool> sendPasswordResetCode(String email, String code) async {
    try {
      print('📧 Email gönderiliyor...');
      print('📧 Alıcı: $email');
      print('📧 Konu: Şifre Sıfırlama Kodu');
      print('📧 Kod: $code');
      
      // Gerçek email gönderimi - GmailSMTPService kullan
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
  
  // Gerçek email gönderimi - GmailSMTPService kullan
  static Future<bool> _sendRealEmail(String email, String code) async {
    try {
      // Önce Gmail SMTP'yi dene
      final gmailSuccess = await GmailSMTPService.sendPasswordResetCode(email, code);
      if (gmailSuccess) {
        return true;
      }
      
      // Gmail başarısız olursa SendGrid'i dene
      final sendGridSuccess = await SendGridFreeService.sendPasswordResetCode(email, code);
      if (sendGridSuccess) {
        return true;
      }
      
      // SendGrid de başarısız olursa Firebase Functions'ı dene
      final firebaseSuccess = await FirebaseEmailService.sendPasswordResetCode(email, code);
      if (firebaseSuccess) {
        return true;
      }
      
      // Hepsi başarısız olursa simüle et (fallback)
      print('⚠️ Tüm email servisleri başarısız, simüle modda çalışıyor...');
      print('📧 Email içeriği:');
      print('Doğrulama Kodunuz: $code');
      await Future.delayed(const Duration(seconds: 1));
      return false; // Gerçek email gönderilmediği için false döndür
      
    } catch (e) {
      print('❌ Email gönderim hatası: $e');
      return false;
    }
  }
  
  // Gmail SMTP ile email gönderme (gerçek implementasyon)
  static Future<bool> sendEmailWithGmailSMTP(String email, String code) async {
    return await GmailSMTPService.sendPasswordResetCode(email, code);
  }
  
  // SendGrid ile email gönderme (gerçek implementasyon)
  static Future<bool> sendEmailWithSendGrid(String email, String code) async {
    return await SendGridFreeService.sendPasswordResetCode(email, code);
  }
  
  // Firebase Functions ile email gönderme (önerilen)
  static Future<bool> sendEmailWithFirebaseFunctions(String email, String code) async {
    return await FirebaseEmailService.sendPasswordResetCode(email, code);
  }
}
