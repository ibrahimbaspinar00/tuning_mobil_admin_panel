import 'package:flutter/foundation.dart';
import 'gmail_smtp_service.dart';
import 'sendgrid_free_service.dart';

class EmailService {
  /// Email gönderme fonksiyonu - Gmail SMTP ve SendGrid fallback ile
  static Future<bool> sendPasswordResetCode(String email, String code) async {
    try {
      final success = await _sendRealEmail(email, code);
      return success;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Email gönderim hatası: $e');
      }
      return false;
    }
  }
  
  /// Gerçek email gönderimi - Gmail SMTP ve SendGrid fallback
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
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Email gönderim hatası: $e');
      }
      return false;
    }
  }
  
  /// Gmail SMTP ile email gönderme
  static Future<bool> sendEmailWithGmailSMTP(String email, String code) async {
    return await GmailSMTPService.sendPasswordResetCode(email, code);
  }
  
  /// SendGrid ile email gönderme
  static Future<bool> sendEmailWithSendGrid(String email, String code) async {
    return await SendGridFreeService.sendPasswordResetCode(email, code);
  }
}
