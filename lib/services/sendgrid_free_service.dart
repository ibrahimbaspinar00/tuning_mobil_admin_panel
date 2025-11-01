// lib/services/sendgrid_free_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class SendGridFreeService {
  // SendGrid ücretsiz plan - 100 email/gün
  static const String _sendGridApiKey = 'YOUR_SENDGRID_API_KEY'; // SendGrid API Key
  static const String _senderEmail = 'noreply@yourdomain.com'; // Gönderen email
  
  // Ücretsiz SendGrid ile email gönder
  static Future<bool> sendPasswordResetCode(String email, String code) async {
    try {
      print('📧 SendGrid ücretsiz plan ile email gönderiliyor...');
      print('📧 Alıcı: $email');
      print('📧 Kod: $code');
      
      if (_sendGridApiKey == 'YOUR_SENDGRID_API_KEY') {
        print('❌ SendGrid API Key ayarlanmamış!');
        return false;
      }
      
      final url = Uri.parse('https://api.sendgrid.com/v3/mail/send');
      final headers = {
        'Authorization': 'Bearer $_sendGridApiKey',
        'Content-Type': 'application/json',
      };
      
      final emailData = {
        'personalizations': [
          {
            'to': [
              {'email': email}
            ]
          }
        ],
        'from': {'email': _senderEmail, 'name': 'Tuning App Admin'},
        'subject': 'Şifre Sıfırlama Kodunuz',
        'content': [
          {
            'type': 'text/plain',
            'value': '''
Merhaba,

Şifre sıfırlama talebiniz alınmıştır.

Doğrulama Kodunuz: $code

Bu kodu kullanarak yeni şifrenizi belirleyebilirsiniz.

Not: Bu kod 10 dakika geçerlidir.

Güvenliğiniz için bu kodu kimseyle paylaşmayın.

İyi günler,
Tuning App Admin Paneli
            '''
          }
        ]
      };
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(emailData),
      );
      
      if (response.statusCode == 202) {
        print('✅ SendGrid ile email gönderildi!');
        return true;
      } else {
        print('❌ SendGrid hatası: ${response.statusCode} ${response.body}');
        return false;
      }
      
    } catch (e) {
      print('❌ SendGrid hatası: $e');
      return false;
    }
  }
  
  // Test email gönder
  static Future<bool> sendTestEmail(String email) async {
    try {
      print('📧 SendGrid test email gönderiliyor...');
      print('📧 Alıcı: $email');
      
      final url = Uri.parse('https://api.sendgrid.com/v3/mail/send');
      final headers = {
        'Authorization': 'Bearer $_sendGridApiKey',
        'Content-Type': 'application/json',
      };
      
      final emailData = {
        'personalizations': [
          {
            'to': [
              {'email': email}
            ]
          }
        ],
        'from': {'email': _senderEmail, 'name': 'Tuning App Admin'},
        'subject': 'Test Email',
        'content': [
          {
            'type': 'text/plain',
            'value': 'Bu bir test emailidir.'
          }
        ]
      };
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(emailData),
      );
      
      if (response.statusCode == 202) {
        print('✅ SendGrid test email gönderildi!');
        return true;
      } else {
        print('❌ SendGrid test hatası: ${response.statusCode} ${response.body}');
        return false;
      }
      
    } catch (e) {
      print('❌ SendGrid test hatası: $e');
      return false;
    }
  }
}
