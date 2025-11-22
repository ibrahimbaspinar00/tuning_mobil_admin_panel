import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Firebase Cloud Messaging Servisi
/// Push notification göndermek için kullanılır
/// Uygulama kapalıyken bile çalışır
class FCMService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  
  // FCM Legacy API endpoint (ücretsiz, Spark plan yeterli)
  static const String _fcmLegacyEndpoint = 'https://fcm.googleapis.com/fcm/send';
  
  // FCM Server Key'i Firestore'dan al
  Future<String?> _getFCMServerKey() async {
    try {
      final settingsDoc = await _firestore.collection('admin_settings').doc('system_settings').get();
      if (settingsDoc.exists) {
        final data = settingsDoc.data();
        if (data?['fcmServerKey'] != null && data!['fcmServerKey'].toString().isNotEmpty) {
          return data['fcmServerKey'].toString();
        }
      }
      return null;
    } catch (e) {
      debugPrint('FCM Server Key alma hatası: $e');
      return null;
    }
  }
  
  /// Tek bir FCM token'a bildirim gönder
  /// Uygulama açık veya kapalı olsun, bildirim gönderir
  Future<bool> sendToToken({
    required String token,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) async {
    // Token validation
    if (token.isEmpty || token.length < 50) {
      debugPrint('❌ Geçersiz FCM token: token çok kısa veya boş');
      return false;
    }
    
    try {
      // Önce Cloud Functions kullanmayı dene (en güvenilir yöntem - Blaze plan gerektirir)
      try {
        final callable = _functions.httpsCallable('sendNotification');
        final result = await callable.call({
          'token': token,
          'title': title,
          'body': body,
          if (imageUrl != null) 'imageUrl': imageUrl,
          if (data != null) 'data': data,
        });
        
        if (result.data['success'] == true) {
          debugPrint('✅ FCM bildirimi Cloud Functions ile başarıyla gönderildi (push notification aktif)');
          return true;
        } else {
          debugPrint('⚠️ Cloud Functions başarısız: ${result.data}');
          throw Exception('Cloud Functions başarısız');
        }
      } catch (cfError) {
        // Cloud Functions yoksa HTTP API ile dene (ücretsiz, Spark plan yeterli)
        debugPrint('ℹ️ Cloud Functions yok veya hata: $cfError');
        debugPrint('🔄 HTTP API ile gönderim deneniyor...');
        
        final serverKey = await _getFCMServerKey();
        if (serverKey == null || serverKey.isEmpty) {
          debugPrint('❌ FCM Server Key bulunamadı!');
          debugPrint('💡 Çözüm: Admin Panel > Ayarlar > FCM Push Notification Ayarları > FCM Server Key ekleyin');
          debugPrint('⚠️ Bildirim sadece Firestore\'a kaydedildi, push notification gönderilmedi');
          return false; // Push notification gönderilmedi
        }
        
        debugPrint('✅ FCM Server Key bulundu, HTTP API ile gönderiliyor...');
        // HTTP API ile FCM gönder (ücretsiz, Spark plan yeterli)
        final httpResult = await _sendViaHttpAPI(
          token: token,
          title: title,
          body: body,
          imageUrl: imageUrl,
          data: data,
          serverKey: serverKey,
        );
        
        if (!httpResult) {
          debugPrint('❌ HTTP API ile gönderim başarısız!');
        }
        
        return httpResult;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ FCM gönderim hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      return false; // Hata durumunda false döndür ki kullanıcı anlasın
    }
  }
  
  /// Kullanıcının FCM token'larını al (bir kullanıcının birden fazla cihazı olabilir)
  Future<List<String>> getUserFCMTokens(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return [];
      }
      
      final data = userDoc.data();
      final tokens = <String>[];
      
      // Farklı formatları kontrol et
      if (data?['fcmToken'] != null && data!['fcmToken'] is String) {
        tokens.add(data['fcmToken']);
      }
      
      if (data?['deviceTokens'] != null) {
        if (data!['deviceTokens'] is List) {
          tokens.addAll((data['deviceTokens'] as List).map((e) => e.toString()).toList());
        } else if (data['deviceTokens'] is String) {
          tokens.add(data['deviceTokens']);
        }
      }
      
      // additionalInfo içinde de olabilir
      if (data?['additionalInfo'] != null && data!['additionalInfo'] is Map) {
        final additionalInfo = data['additionalInfo'] as Map<String, dynamic>;
        if (additionalInfo['fcmToken'] != null) {
          tokens.add(additionalInfo['fcmToken'].toString());
        }
        if (additionalInfo['deviceTokens'] != null) {
          if (additionalInfo['deviceTokens'] is List) {
            tokens.addAll((additionalInfo['deviceTokens'] as List).map((e) => e.toString()).toList());
          }
        }
      }
      
      return tokens.where((token) => token.isNotEmpty).toList();
    } catch (e) {
      print('FCM token alma hatası: $e');
      return [];
    }
  }
  
  /// Tüm kullanıcılara bildirim gönder (FCM token'ları varsa)
  Future<Map<String, dynamic>> sendToAllUsers({
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) async {
    int successCount = 0;
    int failureCount = 0;
    int noTokenCount = 0;
    int tokenCount = 0;
    
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      
      // Tüm token'ları topla
      final allTokens = <String>[];
      for (final userDoc in usersSnapshot.docs) {
        final tokens = await getUserFCMTokens(userDoc.id);
        if (tokens.isEmpty) {
          noTokenCount++;
        } else {
          allTokens.addAll(tokens);
          tokenCount += tokens.length;
        }
      }
      
      // Token varsa bildirim gönder
      if (allTokens.isNotEmpty) {
        // Önce Cloud Functions ile toplu gönderimi dene
        try {
          final callable = _functions.httpsCallable('sendNotificationToMultiple');
          final result = await callable.call({
            'tokens': allTokens,
            'title': title,
            'body': body,
            if (imageUrl != null) 'imageUrl': imageUrl,
            if (data != null) 'data': data,
          });
          
          if (result.data['success'] == true) {
            successCount = (result.data['successCount'] ?? 0) as int;
            failureCount = (result.data['failureCount'] ?? 0) as int;
            debugPrint('✅ Cloud Functions ile toplu bildirim gönderildi: ${result.data}');
          } else {
            throw Exception('Cloud Functions başarısız');
          }
        } catch (cfError) {
          // Cloud Functions yoksa HTTP API ile tek tek gönder (ücretsiz, Spark plan yeterli)
          debugPrint('ℹ️ Cloud Functions yok, HTTP API ile gönderiliyor...');
          
          final serverKey = await _getFCMServerKey();
          if (serverKey == null || serverKey.isEmpty) {
            debugPrint('⚠️ FCM Server Key bulunamadı. Bildirimler sadece Firestore\'a kaydedildi.');
            successCount = usersSnapshot.docs.length - noTokenCount;
          } else {
            debugPrint('✅ FCM Server Key bulundu, HTTP API ile ${allTokens.length} token\'a gönderiliyor...');
            // HTTP API ile her token'a gönder
            for (int i = 0; i < allTokens.length; i++) {
              final token = allTokens[i];
              debugPrint('📤 [${i + 1}/${allTokens.length}] Token\'a bildirim gönderiliyor...');
              
              final success = await _sendViaHttpAPI(
                token: token,
                title: title,
                body: body,
                imageUrl: imageUrl,
                data: data,
                serverKey: serverKey,
              );
              
              if (success) {
                successCount++;
                debugPrint('✅ [${i + 1}/${allTokens.length}] Başarılı');
              } else {
                failureCount++;
                debugPrint('❌ [${i + 1}/${allTokens.length}] Başarısız');
              }
              
              // Rate limiting için kısa bekleme
              await Future.delayed(const Duration(milliseconds: 50));
            }
            
            debugPrint('📊 Toplam sonuç: $successCount başarılı, $failureCount başarısız');
          }
        }
      }
      
      return {
        'success': true,
        'successCount': successCount,
        'failureCount': failureCount,
        'noTokenCount': noTokenCount,
        'tokenCount': tokenCount,
        'totalUsers': usersSnapshot.docs.length,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'successCount': successCount,
        'failureCount': failureCount,
        'noTokenCount': noTokenCount,
        'tokenCount': tokenCount,
      };
    }
  }
  
  /// Belirli bir kullanıcıya bildirim gönder
  Future<bool> sendToUser({
    required String userId,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) async {
    try {
      final tokens = await getUserFCMTokens(userId);
      
      if (tokens.isEmpty) {
        // Token yoksa sadece Firestore'a kaydedildi, mobil uygulama dinleyecek
        return true;
      }
      
      bool allSuccess = true;
      for (final token in tokens) {
        final success = await sendToToken(
          token: token,
          title: title,
          body: body,
          imageUrl: imageUrl,
          data: data,
        );
        if (!success) {
          allSuccess = false;
        }
      }
      
      return allSuccess;
    } catch (e) {
      print('Kullanıcıya bildirim gönderme hatası: $e');
      return false;
    }
  }
  
  /// HTTP API ile FCM bildirimi gönder (ücretsiz, Spark plan yeterli)
  Future<bool> _sendViaHttpAPI({
    required String token,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
    required String serverKey,
  }) async {
    try {
      final payload = <String, dynamic>{
        'to': token,
        'notification': {
          'title': title,
          'body': body,
          'sound': 'default',
          'badge': '1',
          if (imageUrl != null) 'image': imageUrl,
        },
        'data': {
          'title': title,
          'body': body,
          if (imageUrl != null) 'imageUrl': imageUrl,
          ...?data,
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
        'android': {
          'priority': 'high',
          'ttl': '86400s',
          'notification': {
            'sound': 'default',
            'priority': 'high',
            'default_sound': true,
            'default_vibrate_timings': true,
            'default_light_settings': true,
            if (imageUrl != null) 'image': imageUrl,
          },
        },
        'apns': {
          'headers': {
            'apns-priority': '10',
            'apns-push-type': 'alert',
          },
          'payload': {
            'aps': {
              'alert': {
                'title': title,
                'body': body,
              },
              'sound': 'default',
              'badge': 1,
              'content-available': 1,
            },
          },
        },
        'webpush': {
          'notification': {
            'title': title,
            'body': body,
            'icon': imageUrl ?? '',
            'badge': imageUrl ?? '',
          },
        },
        'priority': 'high',
        'content_available': true,
      };
      
      final response = await http.post(
        Uri.parse(_fcmLegacyEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode(payload),
      );
      
      debugPrint('📡 FCM HTTP API Response: ${response.statusCode}');
      debugPrint('📡 Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final success = responseData['success'] == 1 || responseData['message_id'] != null;
        
        if (success) {
          debugPrint('✅ FCM bildirimi HTTP API ile başarıyla gönderildi!');
          debugPrint('📱 Token: ${token.substring(0, 30)}...');
          debugPrint('📨 Message ID: ${responseData['message_id'] ?? 'N/A'}');
          return true;
        } else {
          debugPrint('⚠️ FCM gönderim uyarısı: ${response.body}');
          if (responseData['results'] != null && responseData['results'].isNotEmpty) {
            final error = responseData['results'][0]['error'];
            if (error != null) {
              debugPrint('❌ FCM Hata: $error');
              if (error == 'InvalidRegistration' || error == 'NotRegistered') {
                debugPrint('⚠️ Token geçersiz veya kayıtlı değil. Kullanıcının mobil uygulamayı yeniden açması gerekebilir.');
                debugPrint('💡 Token\'ı Firestore\'dan silmek gerekebilir.');
              } else if (error == 'MismatchSenderId') {
                debugPrint('❌ Sender ID uyuşmazlığı! Firebase proje ayarlarını kontrol edin.');
              } else if (error == 'InvalidApiKey') {
                debugPrint('❌ Server Key geçersiz! Firebase Console\'dan doğru Server Key\'i alın.');
              }
            }
          }
          return false;
        }
      } else if (response.statusCode == 401) {
        debugPrint('❌ FCM Authentication hatası (401): Server Key geçersiz veya yanlış!');
        debugPrint('💡 Çözüm: Firebase Console > Project Settings > Cloud Messaging > Server Key kontrol edin');
        debugPrint('💡 Admin Panel > Ayarlar > FCM Push Notification Ayarları > Server Key\'i yenileyin');
        return false;
      } else if (response.statusCode == 400) {
        debugPrint('❌ FCM Bad Request (400): Gönderilen veri formatı hatalı!');
        debugPrint('📋 Response: ${response.body}');
        return false;
      } else {
        debugPrint('❌ FCM gönderim hatası: HTTP ${response.statusCode}');
        debugPrint('📋 Response: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ FCM HTTP API gönderim hatası: $e');
      debugPrint('📋 Stack trace: $stackTrace');
      return false;
    }
  }
}
