// lib/services/sendgrid_free_service.dart
import 'package:flutter/foundation.dart';
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
      if (kDebugMode) {
        debugPrint('SendGrid ayarları yüklenirken hata: $e');
      }
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
      if (kDebugMode) {
        debugPrint('SendGrid ayarları kaydedilirken hata: $e');
      }
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
      // SendGrid ayarları kontrol et
      final hasCredentials = await _checkCredentials();
      if (!hasCredentials) {
        if (kDebugMode) {
          debugPrint('SendGrid ayarları yapılmamış');
        }
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
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('SendGrid hatası: ${response.statusCode} ${response.body}');
        }
        return false;
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SendGrid hatası: $e');
      }
      return false;
    }
  }
  
  // Test email gönder - detaylı hata mesajı ile
  static Future<Map<String, dynamic>> sendTestEmail(String email) async {
    try {
      
      // Email formatı kontrolü
      if (email.trim().isEmpty || !email.contains('@')) {
        return {
          'success': false,
          'message': 'Geçersiz email adresi',
        };
      }
      
      // SendGrid ayarları kontrol et
      final hasCredentials = await _checkCredentials();
      if (!hasCredentials) {
        return {
          'success': false,
          'message': 'SendGrid ayarları yapılmamış! Lütfen API Key ve Sender Email girin.',
        };
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
              {'email': email.trim()}
            ]
          }
        ],
        'from': {'email': senderEmail, 'name': 'Tuning App Admin'},
        'subject': 'Test Email - Tuning App Admin',
        'content': [
          {
            'type': 'text/plain',
            'value': 'Bu bir test emailidir.\n\nSendGrid ayarlarınız doğru çalışıyor! ✅'
          }
        ]
      };
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(emailData),
      );
      
      if (response.statusCode == 202) {
        return {
          'success': true,
          'message': 'Test email başarıyla gönderildi!',
        };
      } else {
        // Hata mesajını parse et
        String errorMessage = 'Bilinmeyen hata';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('errors')) {
            final errors = errorBody['errors'] as List;
            if (errors.isNotEmpty) {
              errorMessage = errors[0]['message'] ?? 'SendGrid hatası';
            }
          } else {
            errorMessage = 'HTTP ${response.statusCode}: ${response.body}';
          }
        } catch (e) {
          errorMessage = 'HTTP ${response.statusCode}: ${response.body}';
        }
        
        if (kDebugMode) {
          debugPrint('SendGrid test hatası: ${response.statusCode} ${response.body}');
        }
        return {
          'success': false,
          'message': 'SendGrid hatası: $errorMessage',
        };
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SendGrid test hatası: $e');
      }
      return {
        'success': false,
        'message': 'Bağlantı hatası: ${e.toString()}',
      };
    }
  }
}
