const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Firebase Admin SDK'yı başlat
// Production'da Firebase otomatik olarak service account kullanır
// Local development için serviceAccountKey.json dosyası gerekli
try {
  // Local development için service account key dosyasını dene
  const serviceAccount = require('./tuning-app-789ce-firebase-adminsdk-fbsvc-aa924058c5.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log('✅ Firebase Admin SDK Service Account ile başlatıldı (Local)');
} catch (error) {
  // Production'da veya dosya yoksa otomatik credentials kullan
  admin.initializeApp();
  console.log('✅ Firebase Admin SDK otomatik credentials ile başlatıldı (Production)');
}

/**
 * FCM push notification göndermek için Cloud Function
 * Kullanım: Callable function olarak çağrılır
 */
exports.sendNotification = functions.https.onCall(async (data, _context) => {
  try {
    const { token, title, body, imageUrl, data: extraData } = data;

    if (!token || !title || !body) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Token, title ve body gerekli'
      );
    }

    // FCM mesajı oluştur
    const message = {
      token: token,
      notification: {
        title: title,
        body: body,
      },
      data: {
        title: title,
        body: body,
        ...extraData,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          priority: 'high',
          defaultSound: true,
          defaultVibrateTimings: true,
          defaultLightSettings: true,
        },
      },
      apns: {
        headers: {
          'apns-priority': '10',
          'apns-push-type': 'alert',
        },
        payload: {
          aps: {
            alert: {
              title: title,
              body: body,
            },
            sound: 'default',
            badge: 1,
            'content-available': 1,
          },
        },
      },
      webpush: {
        notification: {
          title: title,
          body: body,
        },
      },
    };

    if (imageUrl) {
      message.notification.imageUrl = imageUrl;
      message.data.imageUrl = imageUrl;
    }

    // Bildirimi gönder
    const response = await admin.messaging().send(message);

    return {
      success: true,
      messageId: response,
    };
  } catch (error) {
    console.error('FCM gönderim hatası:', error);
    throw new functions.https.HttpsError(
      'internal',
      `Bildirim gönderilemedi: ${error.message}`
    );
  }
});

/**
 * Toplu bildirim göndermek için Cloud Function
 */
exports.sendNotificationToMultiple = functions.https.onCall(async (data, _context) => {
  try {
    const { tokens, title, body, imageUrl, data: extraData } = data;

    if (!tokens || !Array.isArray(tokens) || tokens.length === 0) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Token listesi gerekli'
      );
    }

    if (!title || !body) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Title ve body gerekli'
      );
    }

    // FCM mesajı oluştur
    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        title: title,
        body: body,
        ...extraData,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          priority: 'high',
          defaultSound: true,
          defaultVibrateTimings: true,
          defaultLightSettings: true,
        },
      },
      apns: {
        headers: {
          'apns-priority': '10',
          'apns-push-type': 'alert',
        },
        payload: {
          aps: {
            alert: {
              title: title,
              body: body,
            },
            sound: 'default',
            badge: 1,
            'content-available': 1,
          },
        },
      },
    };

    if (imageUrl) {
      message.notification.imageUrl = imageUrl;
      message.data.imageUrl = imageUrl;
    }

    // Multicast ile gönder (max 500 token)
    const maxTokens = 500;
    let successCount = 0;
    let failureCount = 0;

    for (let i = 0; i < tokens.length; i += maxTokens) {
      const batch = tokens.slice(i, i + maxTokens);
      message.tokens = batch;

      try {
        const response = await admin.messaging().sendEachForMulticast(message);
        successCount += response.successCount;
        failureCount += response.failureCount;
      } catch (error) {
        console.error(`Batch ${i} hatası:`, error);
        failureCount += batch.length;
      }
    }

    return {
      success: true,
      successCount: successCount,
      failureCount: failureCount,
      totalTokens: tokens.length,
    };
  } catch (error) {
    console.error('Toplu FCM gönderim hatası:', error);
    throw new functions.https.HttpsError(
      'internal',
      `Bildirimler gönderilemedi: ${error.message}`
    );
  }
});

/**
 * Ürün ekleme ve resim yükleme için Cloud Function
 * Kullanım: Callable function olarak çağrılır
 */
exports.uploadProduct = functions.https.onCall(async (data, _context) => {
  try {
    const { name, price, imageBytes, fileName, description, category, stock } = data;
    
    // Gerekli alanları kontrol et
    if (!name || !price) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Ürün adı ve fiyat gerekli'
      );
    }

    let imageUrl = '';
    
    // Resim varsa Firebase Storage'a yükle
    if (imageBytes && fileName) {
      try {
        const bucket = admin.storage().bucket();
        const file = bucket.file(`product_images/${fileName}`);
        
        // Base64 string'i Buffer'a çevir
        const buffer = Buffer.from(imageBytes, 'base64');
        
        await file.save(buffer, {
          metadata: { 
            contentType: 'image/jpeg',
            metadata: {
              uploadedBy: _context.auth?.uid || 'admin',
              uploadedAt: new Date().toISOString()
            }
          }
        });
        
        // Download URL al (10 yıl geçerli)
        const [url] = await file.getSignedUrl({ 
          action: 'read', 
          expires: '03-09-2491' 
        });
        
        imageUrl = url;
      } catch (storageError) {
        console.error('Storage yükleme hatası:', storageError);
        // Resim yükleme hatası olsa bile ürünü ekle
        throw new functions.https.HttpsError(
          'internal',
          `Resim yüklenirken hata: ${storageError.message}`
        );
      }
    }
    
    // Firestore'a ürün ekle
    const productData = {
      name,
      price: parseFloat(price),
      imageUrl: imageUrl,
      description: description || '',
      category: category || 'Genel',
      stock: stock ? parseInt(stock) : 0,
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    
    const docRef = await admin.firestore().collection('products').add(productData);
    
    return { 
      success: true,
      productId: docRef.id,
      imageUrl: imageUrl
    };
  } catch (error) {
    console.error('Ürün ekleme hatası:', error);
    
    // Hata zaten HttpsError ise direkt fırlat
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError(
      'internal',
      `Ürün eklenirken hata: ${error.message}`
    );
  }
});

