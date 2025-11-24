import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/product_review.dart';

class ReviewService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collectionName = 'product_reviews';

  // Firestore verisini ProductReview için hazırla (Timestamp'leri DateTime'a çevir)
  static Map<String, dynamic> _prepareReviewData(Map<String, dynamic> data, String docId) {
    // Önce data'yı kopyala, sonra ID'yi ekle (ID her zaman docId olmalı)
    final processedData = <String, dynamic>{
      ...data,
      'id': docId, // ID'yi en son ekle ki override edilmesin
    };
    
    // Timestamp'leri String'e çevir
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        processedData['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
      } else if (data['createdAt'] is String) {
        // Zaten string ise değiştirme
      }
    }
    
    if (data['updatedAt'] != null) {
      if (data['updatedAt'] is Timestamp) {
        processedData['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
      } else if (data['updatedAt'] is String) {
        // Zaten string ise değiştirme
      }
    }
    
    if (data['adminResponseDate'] != null && data['adminResponseDate'] is Timestamp) {
      processedData['adminResponseDate'] = (data['adminResponseDate'] as Timestamp).toDate().toIso8601String();
    }
    
    // ID'nin boş olmadığından emin ol
    if (processedData['id'] == null || (processedData['id'] as String).isEmpty) {
      processedData['id'] = docId;
    }
    
    return processedData;
  }

  // Ürün için tüm yorumları getir
  static Future<List<ProductReview>> getProductReviews(String productId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('productId', isEqualTo: productId)
          .where('isApproved', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      final reviews = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            return ProductReview.fromJson(_prepareReviewData(
              Map<String, dynamic>.from(data),
              doc.id,
            ));
          })
          .toList();

      // Gerçek yorumları döndür (yorum yoksa boş liste)
      return reviews;
    } catch (e) {
      print('❌ Yorumlar getirilirken hata oluştu: $e');
      // Hata durumunda boş liste döndür (demo yorumlar gösterilmez)
      return [];
    }
  }


  // Kullanıcının bir ürün için yorumunu getir
  static Future<ProductReview?> getUserReviewForProduct(String productId, String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('productId', isEqualTo: productId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        return ProductReview.fromJson(_prepareReviewData(
          Map<String, dynamic>.from(data),
          doc.id,
        ));
      }
      return null;
    } catch (e) {
      print('Kullanıcı yorumu getirilirken hata oluştu: $e');
      return null;
    }
  }

  // Kullanıcının ürünü satın alıp almadığını kontrol et
  static Future<bool> hasUserPurchasedProduct(String productId, String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();

      for (var doc in querySnapshot.docs) {
        final orderData = doc.data();
        final products = orderData['products'] as List<dynamic>?;
        if (products != null) {
          for (var product in products) {
            if (product['productId'] == productId) {
              return true;
            }
          }
        }
      }
      return false;
    } catch (e) {
      print('Satın alma kontrolü yapılırken hata: $e');
      return false;
    }
  }

  // Yorum ekle
  static Future<String?> addReview({
    required String productId,
    required int rating,
    required String comment,
    List<String>? imageUrls,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      // Demo için satın alma kontrolünü atla
      // final hasPurchased = await hasUserPurchasedProduct(productId, user.uid);
      // if (!hasPurchased) {
      //   throw Exception('Bu ürünü satın almadığınız için yorum yapamazsınız');
      // }

      // Kullanıcının daha önce bu ürün için yorum yapıp yapmadığını kontrol et
      final existingReview = await getUserReviewForProduct(productId, user.uid);
      if (existingReview != null) {
        throw Exception('Bu ürün için zaten yorum yapmışsınız');
      }

      // Firestore'a direkt Timestamp olarak ekle
      final reviewData = {
        'productId': productId,
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonim Kullanıcı',
        'userEmail': user.email ?? '',
        'rating': rating,
        'comment': comment,
        'imageUrls': imageUrls ?? [],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'isApproved': false, // Admin onayı bekliyor
        'isEdited': false,
        'adminResponse': null,
        'adminResponseDate': null,
      };

      final docRef = await _firestore.collection(_collectionName).add(reviewData);
      
      // Ürünün ortalama rating'ini güncelle
      await _updateProductRating(productId);
      
      return docRef.id;
    } catch (e) {
      print('Yorum eklenirken hata oluştu: $e');
      rethrow;
    }
  }

  // Yorum güncelle
  static Future<bool> updateReview({
    required String reviewId,
    required int rating,
    required String comment,
    List<String>? imageUrls,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      // Yorumun kullanıcıya ait olup olmadığını kontrol et
      final reviewDoc = await _firestore.collection(_collectionName).doc(reviewId).get();
      if (!reviewDoc.exists) {
        throw Exception('Yorum bulunamadı');
      }

      final reviewData = reviewDoc.data()!;
      if (reviewData['userId'] != user.uid) {
        throw Exception('Bu yorumu düzenleme yetkiniz yok');
      }

      final updateData = {
        'rating': rating,
        'comment': comment,
        'updatedAt': Timestamp.now(),
        'isEdited': true,
      };

      if (imageUrls != null) {
        updateData['imageUrls'] = imageUrls;
      }

      await _firestore.collection(_collectionName).doc(reviewId).update(updateData);

      // Ürünün ortalama rating'ini güncelle
      final productId = reviewData['productId'];
      if (productId != null) {
        await _updateProductRating(productId);
      }

      return true;
    } catch (e) {
      print('Yorum güncellenirken hata oluştu: $e');
      return false;
    }
  }

  // Yorum sil (kullanıcı için)
  static Future<bool> deleteReview(String reviewId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      // Yorumun kullanıcıya ait olup olmadığını kontrol et
      final reviewDoc = await _firestore.collection(_collectionName).doc(reviewId).get();
      if (!reviewDoc.exists) {
        throw Exception('Yorum bulunamadı');
      }

      final reviewData = reviewDoc.data()!;
      if (reviewData['userId'] != user.uid) {
        throw Exception('Bu yorumu silme yetkiniz yok');
      }

      await _firestore.collection(_collectionName).doc(reviewId).delete();

      // Ürünün ortalama rating'ini güncelle
      final productId = reviewData['productId'];
      if (productId != null) {
        await _updateProductRating(productId);
      }

      return true;
    } catch (e) {
      print('Yorum silinirken hata oluştu: $e');
      return false;
    }
  }

  // Admin: Yorum sil
  static Future<bool> deleteReviewAdmin(String reviewId) async {
    try {
      if (reviewId.trim().isEmpty) {
        throw Exception('Yorum ID\'si geçersiz veya boş');
      }

      print('🔍 Admin yorum silme işlemi başlatılıyor...');
      print('   - Yorum ID: "$reviewId"');

      // Yorumun var olup olmadığını kontrol et
      final reviewDoc = await _firestore.collection(_collectionName).doc(reviewId.trim()).get();
      if (!reviewDoc.exists) {
        throw Exception('Yorum bulunamadı');
      }

      final reviewData = reviewDoc.data();
      if (reviewData == null) {
        throw Exception('Yorum verisi boş');
      }

      final productId = reviewData['productId'] as String?;
      
      // Yorumu sil
      print('   - Yorum siliniyor...');
      await _firestore.collection(_collectionName).doc(reviewId.trim()).delete();
      print('   - Yorum silindi');

      // Ürünün ortalama rating'ini güncelle
      if (productId != null && productId.isNotEmpty) {
        print('   - Ürün rating\'i güncelleniyor...');
        try {
          await _updateProductRating(productId);
          print('   - Ürün rating\'i güncellendi');
        } catch (ratingError) {
          // Rating güncelleme hatası kritik değil, sadece logla
          print('⚠️ Ürün rating güncellenirken hata (devam ediliyor): $ratingError');
        }
      }

      print('✅ Yorum başarıyla silindi');
      return true;
    } catch (e) {
      print('❌ Yorum silme hatası: $e');
      final errorMsg = e.toString();
      
      // Firebase izin hatası kontrolü
      if (errorMsg.contains('permission-denied') || 
          errorMsg.contains('permission denied') ||
          errorMsg.contains('Missing or insufficient permissions')) {
        throw Exception('Firebase izin hatası: Yorum işlemleri için gerekli izinler yapılandırılmamış. Lütfen Firebase Console\'dan Firestore Rules\'ı kontrol edin.');
      }
      
      // Network hatası kontrolü
      if (errorMsg.contains('network') || errorMsg.contains('connection') || errorMsg.contains('timeout')) {
        throw Exception('Bağlantı hatası: İnternet bağlantınızı kontrol edin ve tekrar deneyin.');
      }
      
      // Diğer hatalar için orijinal mesajı koru
      if (e is Exception) {
        rethrow;
      }
      
      throw Exception('Yorum silinirken hata oluştu: $e');
    }
  }

  // Ürün adını ID'ye göre getir
  static Future<String?> getProductName(String productId) async {
    try {
      if (productId.trim().isEmpty) {
        return null;
      }

      final productDoc = await _firestore.collection('products').doc(productId.trim()).get();
      if (productDoc.exists) {
        final data = productDoc.data();
        return data?['name'] as String?;
      }
      return null;
    } catch (e) {
      print('Ürün adı getirilirken hata: $e');
      return null;
    }
  }

  // Admin: Yorum onayla/reddet
  static Future<bool> approveReview(String reviewId, bool isApproved) async {
    try {
      // ID kontrolü - trim ve boş kontrolü
      final trimmedId = reviewId.trim();
      if (trimmedId.isEmpty) {
        print('❌ Yorum ID boş: "$reviewId"');
        throw Exception('Yorum ID\'si geçersiz veya boş');
      }
      
      print('🔍 Yorum onay durumu güncelleniyor...');
      print('   - Yorum ID: "$trimmedId"');
      print('   - Onay durumu: $isApproved');

      print('🔍 Yorum onay durumu güncelleniyor...');
      print('   - Yorum ID: $reviewId');
      print('   - Onay durumu: $isApproved');

      // Önce yorumun var olup olmadığını kontrol et
      final reviewDoc = await _firestore.collection(_collectionName).doc(trimmedId).get();
      if (!reviewDoc.exists) {
        throw Exception('Yorum bulunamadı');
      }

      final reviewData = reviewDoc.data();
      if (reviewData == null) {
        throw Exception('Yorum verisi boş');
      }

      final productId = reviewData['productId'] as String?;
      if (productId == null || productId.isEmpty) {
        throw Exception('Ürün ID\'si bulunamadı');
      }

      print('   - Ürün ID: $productId');

      // Firestore Timestamp kullan
      print('   - Yorum durumu güncelleniyor...');
      await _firestore.collection(_collectionName).doc(trimmedId).update({
        'isApproved': isApproved,
        'updatedAt': Timestamp.now(),
      });
      print('   - Yorum durumu güncellendi');

      // Ürünün ortalama rating'ini güncelle
      print('   - Ürün rating\'i güncelleniyor...');
      try {
        await _updateProductRating(productId);
        print('   - Ürün rating\'i güncellendi');
      } catch (ratingError) {
        // Rating güncelleme hatası kritik değil, sadece logla
        print('⚠️ Ürün rating güncellenirken hata (devam ediliyor): $ratingError');
      }

      print('✅ Yorum onay durumu başarıyla güncellendi');
      return true;
    } catch (e) {
      print('❌ Yorum onay durumu güncellenirken hata oluştu: $e');
      final errorMsg = e.toString();
      
      // Firebase izin hatası kontrolü
      if (errorMsg.contains('permission-denied') || 
          errorMsg.contains('permission denied') ||
          errorMsg.contains('Missing or insufficient permissions')) {
        throw Exception('Firebase izin hatası: Yorum işlemleri için gerekli izinler yapılandırılmamış. Lütfen Firebase Console\'dan Firestore Rules\'ı kontrol edin.');
      }
      
      // Network hatası kontrolü
      if (errorMsg.contains('network') || errorMsg.contains('connection') || errorMsg.contains('timeout')) {
        throw Exception('Bağlantı hatası: İnternet bağlantınızı kontrol edin ve tekrar deneyin.');
      }
      
      // Diğer hatalar için orijinal mesajı koru
      if (e is Exception) {
        rethrow;
      }
      
      throw Exception('Yorum onay durumu güncellenirken hata oluştu: $e');
    }
  }

  // Admin: Yorum yanıtla
  static Future<bool> respondToReview({
    required String reviewId,
    required String adminResponse,
  }) async {
    try {
      // ID kontrolü - trim ve boş kontrolü
      final trimmedId = reviewId.trim();
      if (trimmedId.isEmpty) {
        print('❌ Yorum ID boş: "$reviewId"');
        throw Exception('Yorum ID\'si geçersiz veya boş');
      }

      if (adminResponse.trim().isEmpty) {
        throw Exception('Yanıt metni boş olamaz');
      }

      print('🔍 Admin yanıtı ekleniyor...');
      print('   - Yorum ID: "$trimmedId"');

      // Yorumun var olup olmadığını kontrol et
      final reviewDoc = await _firestore.collection(_collectionName).doc(trimmedId).get();
      if (!reviewDoc.exists) {
        throw Exception('Yorum bulunamadı');
      }

      final existingResponse = reviewDoc.data()?['adminResponse'];
      final isUpdate = existingResponse != null && existingResponse.toString().isNotEmpty;

      await _firestore.collection(_collectionName).doc(trimmedId).update({
        'adminResponse': adminResponse.trim(),
        'adminResponseDate': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      print('✅ Admin yanıtı başarıyla ${isUpdate ? 'güncellendi' : 'eklendi'}');
      return true;
    } catch (e) {
      print('❌ Admin yanıtı eklenirken hata oluştu: $e');
      final errorMsg = e.toString();
      
      // Firebase izin hatası kontrolü
      if (errorMsg.contains('permission-denied') || 
          errorMsg.contains('permission denied') ||
          errorMsg.contains('Missing or insufficient permissions')) {
        throw Exception('Firebase izin hatası: Yorum işlemleri için gerekli izinler yapılandırılmamış. Lütfen Firebase Console\'dan Firestore Rules\'ı kontrol edin.');
      }
      
      // Network hatası kontrolü
      if (errorMsg.contains('network') || errorMsg.contains('connection') || errorMsg.contains('timeout')) {
        throw Exception('Bağlantı hatası: İnternet bağlantınızı kontrol edin ve tekrar deneyin.');
      }
      
      // Diğer hatalar için orijinal mesajı koru
      if (e is Exception) {
        rethrow;
      }
      
      throw Exception('Admin yanıtı eklenirken hata oluştu: $e');
    }
  }

  // Admin: Admin yanıtını sil
  static Future<bool> deleteAdminResponse(String reviewId) async {
    try {
      if (reviewId.trim().isEmpty) {
        throw Exception('Yorum ID\'si geçersiz veya boş');
      }

      print('🔍 Admin yanıtı siliniyor...');
      print('   - Yorum ID: "$reviewId"');

      // Yorumun var olup olmadığını kontrol et
      final reviewDoc = await _firestore.collection(_collectionName).doc(reviewId.trim()).get();
      if (!reviewDoc.exists) {
        throw Exception('Yorum bulunamadı');
      }

      await _firestore.collection(_collectionName).doc(reviewId.trim()).update({
        'adminResponse': FieldValue.delete(),
        'adminResponseDate': FieldValue.delete(),
        'updatedAt': Timestamp.now(),
      });

      print('✅ Admin yanıtı başarıyla silindi');
      return true;
    } catch (e) {
      print('❌ Admin yanıtı silinirken hata oluştu: $e');
      final errorMsg = e.toString();
      
      // Firebase izin hatası kontrolü
      if (errorMsg.contains('permission-denied') || 
          errorMsg.contains('permission denied') ||
          errorMsg.contains('Missing or insufficient permissions')) {
        throw Exception('Firebase izin hatası: Yorum işlemleri için gerekli izinler yapılandırılmamış. Lütfen Firebase Console\'dan Firestore Rules\'ı kontrol edin.');
      }
      
      // Network hatası kontrolü
      if (errorMsg.contains('network') || errorMsg.contains('connection') || errorMsg.contains('timeout')) {
        throw Exception('Bağlantı hatası: İnternet bağlantınızı kontrol edin ve tekrar deneyin.');
      }
      
      // Diğer hatalar için orijinal mesajı koru
      if (e is Exception) {
        rethrow;
      }
      
      throw Exception('Admin yanıtı silinirken hata oluştu: $e');
    }
  }

  // Admin: Tüm yorumları getir (onay bekleyenler dahil)
  static Future<List<ProductReview>> getAllReviews({bool? isApproved}) async {
    try {
      Query query = _firestore.collection(_collectionName);
      
      if (isApproved != null) {
        query = query.where('isApproved', isEqualTo: isApproved);
      }
      
      final querySnapshot = await query
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) {
              print('⚠️ Yorum verisi null: ${doc.id}');
              return null;
            }
            
            // ID kontrolü
            if (doc.id.isEmpty) {
              print('⚠️ Yorum ID boş: ${doc.id}');
              return null;
            }
            
            final preparedData = _prepareReviewData(data, doc.id);
            final review = ProductReview.fromJson(preparedData);
            
            // ID'nin doğru şekilde set edildiğini kontrol et
            if (review.id.isEmpty) {
              print('⚠️ Review ID boş oluşturuldu. Doc ID: ${doc.id}, Prepared data ID: ${preparedData['id']}');
              return null;
            }
            
            return review;
          })
          .whereType<ProductReview>()
          .toList();
    } catch (e) {
      print('Tüm yorumlar getirilirken hata oluştu: $e');
      return [];
    }
  }

  // Ürünün ortalama rating'ini güncelle
  static Future<void> _updateProductRating(String productId) async {
    try {
      if (productId.isEmpty) {
        print('⚠️ Ürün ID boş, rating güncellenemiyor');
        return;
      }

      print('   🔄 Ürün rating hesaplanıyor...');
      final reviews = await getProductReviews(productId);
      final averageRating = ProductReview.calculateAverageRating(reviews);
      final totalReviews = reviews.length;

      print('   📊 Hesaplanan rating: $averageRating, Toplam yorum: $totalReviews');

      // Ürünün var olup olmadığını kontrol et
      final productDoc = await _firestore.collection('products').doc(productId).get();
      if (!productDoc.exists) {
        print('⚠️ Ürün bulunamadı, rating güncellenemiyor: $productId');
        return;
      }

      // Ürünün rating bilgilerini güncelle
      await _firestore.collection('products').doc(productId).update({
        'averageRating': averageRating,
        'totalReviews': totalReviews,
        'lastRatingUpdate': DateTime.now().toIso8601String(),
      });
      print('   ✅ Ürün rating güncellendi');
    } catch (e) {
      print('❌ Ürün rating güncellenirken hata oluştu: $e');
      // Rating güncelleme hatası kritik değil, sadece logla
      // Exception fırlatma, ana işlemi etkilemesin
    }
  }

  // Kullanıcının tüm yorumlarını getir
  static Future<List<ProductReview>> getUserReviews(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) return null;
            return ProductReview.fromJson(_prepareReviewData(
              data,
              doc.id,
            ));
          })
          .whereType<ProductReview>()
          .toList();
    } catch (e) {
      print('Kullanıcı yorumları getirilirken hata oluştu: $e');
      return [];
    }
  }

  // En çok yorum alan ürünleri getir
  static Future<List<Map<String, dynamic>>> getTopRatedProducts({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .orderBy('averageRating', descending: true)
          .orderBy('totalReviews', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      print('En çok yorum alan ürünler getirilirken hata oluştu: $e');
      return [];
    }
  }
}
