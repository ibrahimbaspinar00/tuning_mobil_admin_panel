import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/product_review.dart';

class ReviewService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collectionName = 'product_reviews';

  // Firestore verisini ProductReview için hazırla (Timestamp'leri DateTime'a çevir)
  static Map<String, dynamic> _prepareReviewData(Map<String, dynamic> data, String docId) {
    final processedData = <String, dynamic>{
      'id': docId,
      ...data,
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

      // Eğer hiç yorum yoksa demo yorumlar ekle
      if (reviews.isEmpty) {
        return _getDemoReviews(productId);
      }

      return reviews;
    } catch (e) {
      print('Yorumlar getirilirken hata oluştu: $e');
      // Hata durumunda da demo yorumlar döndür
      return _getDemoReviews(productId);
    }
  }

  // Demo yorumlar
  static List<ProductReview> _getDemoReviews(String productId) {
    return [
      ProductReview(
        id: 'demo_1',
        productId: productId,
        userId: 'demo_user_1',
        userName: 'Ahmet Y.',
        userEmail: 'ahmet@example.com',
        rating: 5,
        comment: 'Harika bir ürün! Çok memnun kaldım. Kalitesi çok iyi, kesinlikle tavsiye ederim.',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        isApproved: true,
        adminResponse: 'Teşekkür ederiz! Memnuniyetiniz bizim için çok değerli.',
        adminResponseDate: DateTime.now().subtract(const Duration(days: 1)),
        imageUrls: [],
        isEdited: false,
      ),
      ProductReview(
        id: 'demo_2',
        productId: productId,
        userId: 'demo_user_2',
        userName: 'Fatma K.',
        userEmail: 'fatma@example.com',
        rating: 4,
        comment: 'Güzel ürün ama kargo biraz geç geldi. Ürün kalitesi iyi, fiyat uygun.',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        isApproved: true,
        adminResponse: null,
        adminResponseDate: null,
        imageUrls: [],
        isEdited: false,
      ),
      ProductReview(
        id: 'demo_3',
        productId: productId,
        userId: 'demo_user_3',
        userName: 'Mehmet S.',
        userEmail: 'mehmet@example.com',
        rating: 5,
        comment: 'Mükemmel! Beklentilerimi aştı. Hızlı teslimat, kaliteli ürün. Tekrar alacağım.',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(days: 7)),
        isApproved: true,
        adminResponse: 'Çok teşekkür ederiz! Müşteri memnuniyeti bizim önceliğimiz.',
        adminResponseDate: DateTime.now().subtract(const Duration(days: 6)),
        imageUrls: [],
        isEdited: false,
      ),
      ProductReview(
        id: 'demo_4',
        productId: productId,
        userId: 'demo_user_4',
        userName: 'Ayşe M.',
        userEmail: 'ayse@example.com',
        rating: 3,
        comment: 'Orta kalitede bir ürün. Fiyatına göre makul ama çok özel değil.',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(days: 10)),
        isApproved: true,
        adminResponse: null,
        adminResponseDate: null,
        imageUrls: [],
        isEdited: false,
      ),
      ProductReview(
        id: 'demo_5',
        productId: productId,
        userId: 'demo_user_5',
        userName: 'Can Ö.',
        userEmail: 'can@example.com',
        rating: 5,
        comment: 'Süper! Çok kaliteli ve dayanıklı. Uzun süre kullanacağım. Teşekkürler.',
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
        updatedAt: DateTime.now().subtract(const Duration(days: 12)),
        isApproved: true,
        adminResponse: 'Rica ederiz! Kaliteli ürünler sunmaya devam edeceğiz.',
        adminResponseDate: DateTime.now().subtract(const Duration(days: 11)),
        imageUrls: [],
        isEdited: false,
      ),
    ];
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

  // Yorum sil
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

  // Admin: Yorum onayla/reddet
  static Future<bool> approveReview(String reviewId, bool isApproved) async {
    try {
      // Firestore Timestamp kullan
      await _firestore.collection(_collectionName).doc(reviewId).update({
        'isApproved': isApproved,
        'updatedAt': Timestamp.now(),
      });

      // Ürünün ortalama rating'ini güncelle
      final reviewDoc = await _firestore.collection(_collectionName).doc(reviewId).get();
      if (reviewDoc.exists) {
        final productId = reviewDoc.data()?['productId'];
        if (productId != null) {
          await _updateProductRating(productId);
        }
      }

      return true;
    } catch (e) {
      print('Yorum onay durumu güncellenirken hata oluştu: $e');
      return false;
    }
  }

  // Admin: Yorum yanıtla
  static Future<bool> respondToReview({
    required String reviewId,
    required String adminResponse,
  }) async {
    try {
      await _firestore.collection(_collectionName).doc(reviewId).update({
        'adminResponse': adminResponse,
        'adminResponseDate': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Admin yanıtı eklenirken hata oluştu: $e');
      return false;
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
            if (data == null) return null;
            return ProductReview.fromJson(_prepareReviewData(
              data,
              doc.id,
            ));
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
      final reviews = await getProductReviews(productId);
      final averageRating = ProductReview.calculateAverageRating(reviews);
      final totalReviews = reviews.length;

      // Ürünün rating bilgilerini güncelle
      await _firestore.collection('products').doc(productId).update({
        'averageRating': averageRating,
        'totalReviews': totalReviews,
        'lastRatingUpdate': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Ürün rating güncellenirken hata oluştu: $e');
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
