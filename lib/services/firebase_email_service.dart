import 'package:cloud_functions/cloud_functions.dart';

class FirebaseEmailService {
  // Firebase Functions ile email gönderme
  static Future<bool> sendPasswordResetCode(String email, String code) async {
    try {
      print('📧 Firebase Functions ile email gönderiliyor...');
      print('📧 Alıcı: $email');
      print('📧 Kod: $code');
      
      // Firebase Functions çağır
      final callable = FirebaseFunctions.instance.httpsCallable('sendPasswordResetEmail');
      
      final result = await callable.call({
        'email': email,
        'code': code,
        'subject': 'Şifre Sıfırlama Kodu',
      });
      
      if (result.data['success'] == true) {
        print('✅ Firebase Functions ile email gönderildi!');
        print('📧 Message ID: ${result.data['messageId']}');
        return true;
      } else {
        print('❌ Firebase Functions ile email gönderilemedi!');
        print('❌ Hata: ${result.data['error']}');
        return false;
      }
      
    } catch (e) {
      print('❌ Firebase Functions hatası: $e');
      return false;
    }
  }
  
  // Test email gönderme
  static Future<bool> sendTestEmail(String email) async {
    try {
      print('📧 Test email gönderiliyor...');
      print('📧 Alıcı: $email');
      
      // Firebase Functions çağır
      final callable = FirebaseFunctions.instance.httpsCallable('testEmail');
      
      final result = await callable.call({
        'email': email,
      });
      
      if (result.data['success'] == true) {
        print('✅ Test email gönderildi!');
        print('📧 Message ID: ${result.data['messageId']}');
        return true;
      } else {
        print('❌ Test email gönderilemedi!');
        print('❌ Hata: ${result.data['error']}');
        return false;
      }
      
    } catch (e) {
      print('❌ Test email hatası: $e');
      return false;
    }
  }
  
  // Kurulum talimatları
  static void showSetupInstructions() {
    print('''
🔧 Firebase Functions Kurulum Talimatları:

1. Firebase Console'a git: https://console.firebase.google.com
2. Projenizi seçin
3. Functions bölümüne git
4. "Get started" butonuna tıkla
5. Firebase CLI ile deploy et

Deploy komutları:
cd firebase-functions
npm install
firebase deploy --only functions

6. Gmail SMTP ayarlarını yap:
   - Gmail hesabında 2-Factor Authentication aktifleştir
   - App Password oluştur
   - index.js dosyasındaki email ve password'ü güncelle

7. Test et:
   - Firebase Console > Functions
   - "sendPasswordResetEmail" fonksiyonunu test et

Not: Bu yöntem en güvenli ve ölçeklenebilir!
    ''');
  }
}
