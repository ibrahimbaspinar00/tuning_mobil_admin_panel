// lib/services/sendgrid_free_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class SendGridFreeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // SendGrid ayarları - Firebase'den yüklenecek
  static String? _sendGridApiKey;
  static String? _senderEmail;
  
  // Firebase'den SendGrid ayarlarını yükle
  static Future<void> _loadCredentials() async {
    try {
      final settingsDoc = await _firestore
          .collection('admin_settings')
          .doc('system_settings')
          .get();
      
      if (settingsDoc.exists) {
        final data = settingsDoc.data();
        _sendGridApiKey = data?['sendGridApiKey'] as String?;
        _senderEmail = data?['sendGridSenderEmail'] as String?;
      }
    } catch (e) {
      print('❌ SendGrid ayarları yüklenirken hata: $e');
    }
  }
  
  // SendGrid ayarlarını Firebase'e kaydet
  static Future<bool> saveCredentials(String apiKey, String senderEmail) async {
    try {
      await _firestore
          .collection('admin_settings')
          .doc('system_settings')
          .set({
        'sendGridApiKey': apiKey.trim(),
        'sendGridSenderEmail': senderEmail.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Cache'i güncelle
      _sendGridApiKey = apiKey.trim();
      _senderEmail = senderEmail.trim();
      
      return true;
    } catch (e) {
      print('❌ SendGrid ayarları kaydedilirken hata: $e');
      return false;
    }
  }
  
  // SendGrid ayarlarını kontrol et
  static Future<bool> _checkCredentials() async {
    // Önce cache'den kontrol et
    if (_sendGridApiKey != null && _senderEmail != null) {
      if (_sendGridApiKey!.isNotEmpty && _senderEmail!.isNotEmpty) {
        // Varsayılan değerler kontrolü
        if (_sendGridApiKey != 'YOUR_SENDGRID_API_KEY' && 
            _senderEmail != 'noreply@yourdomain.com') {
          return true;
        }
      }
    }
    
    // Cache'de yoksa Firebase'den yükle
    await _loadCredentials();
    
    if (_sendGridApiKey == null || _senderEmail == null) {
      return false;
    }
    
    if (_sendGridApiKey!.isEmpty || _senderEmail!.isEmpty) {
      return false;
    }
    
    // Varsayılan değerler kontrolü
    if (_sendGridApiKey == 'YOUR_SENDGRID_API_KEY' || 
        _senderEmail == 'noreply@yourdomain.com') {
      return false;
    }
    
    return true;
  }
  
  // Ücretsiz SendGrid ile email gönder
  static Future<bool> sendPasswordResetCode(String email, String code) async {
    try {
      print('📧 SendGrid ücretsiz plan ile email gönderiliyor...');
      print('📧 Alıcı: $email');
      print('📧 Kod: $code');
      
      // SendGrid ayarları kontrol et
      final hasCredentials = await _checkCredentials();
      if (!hasCredentials) {
        print('❌ SendGrid ayarları yapılmamış!');
        print('📧 Ayarlar sayfasından SendGrid API Key ve Sender Email girin');
        print('📧 SendGrid API Key: SendGrid hesabınızdan alın');
        print('📧 Sender Email: Doğrulanmış gönderen email adresi');
        return false;
      }
      
      // Kimlik bilgileri kontrol edildi, null olamazlar
      final apiKey = _sendGridApiKey!;
      final senderEmail = _senderEmail!;
      
      final url = Uri.parse('https://api.sendgrid.com/v3/mail/send');
      final headers = {
        'Authorization': 'Bearer $apiKey',
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
        'from': {'email': senderEmail, 'name': 'Tuning App Admin'},
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
      
      // SendGrid ayarları kontrol et
      final hasCredentials = await _checkCredentials();
      if (!hasCredentials) {
        print('❌ SendGrid ayarları yapılmamış!');
        print('📧 Ayarlar sayfasından SendGrid API Key ve Sender Email girin');
        return false;
      }
      
      // Kimlik bilgileri kontrol edildi, null olamazlar
      final apiKey = _sendGridApiKey!;
      final senderEmail = _senderEmail!;
      
      final url = Uri.parse('https://api.sendgrid.com/v3/mail/send');
      final headers = {
        'Authorization': 'Bearer $apiKey',
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
        'from': {'email': senderEmail, 'name': 'Tuning App Admin'},
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
