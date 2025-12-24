import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';
import '../model/admin_product.dart';
import '../model/admin_user.dart';
import '../model/order.dart' as OrderModel;
import '../model/product.dart';
import 'cache_service.dart';
import 'performance_service.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CacheService _cache = CacheService();
  final PerformanceService _performance = PerformanceService();
  
  // Pagination constants
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Ürün ekleme
  Future<void> addProduct(AdminProduct product) async {
    _performance.startOperation('addProduct');
    try {
      await _firestore
          .collection('products')
          .doc(product.id)
          .set(product.toFirestore());
      
      // Cache'i temizle
      _cache.clearPattern('products');
      
      _performance.endOperation('addProduct');
    } catch (e) {
      _performance.endOperation('addProduct');
      throw Exception('Ürün eklenirken hata oluştu: $e');
    }
  }

  // Ürün silme
  Future<void> deleteProduct(String productId) async {
    _performance.startOperation('deleteProduct');
    try {
      await _firestore
          .collection('products')
          .doc(productId)
          .delete();
      
      // Cache'i temizle
      _cache.clearPattern('products');
      
      _performance.endOperation('deleteProduct');
    } catch (e) {
      _performance.endOperation('deleteProduct');
      throw Exception('Ürün silinirken hata oluştu: $e');
    }
  }

  // Tüm ürünleri getirme - Tüm ürünler gösteriliyor
  // Web uygulaması için cache bypass ile server-side fetch
  Stream<List<AdminProduct>> getProducts() {
    return _firestore
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots(includeMetadataChanges: false)
        .map((snapshot) {
      // Non-blocking processing
      return snapshot.docs.map((doc) {
        try {
          return AdminProduct.fromFirestore(doc.data(), doc.id);
        } catch (e) {
          debugPrint('⚠️ Ürün parse hatası (${doc.id}): $e');
          // Skip invalid documents
          return null;
        }
      }).where((product) => product != null).cast<AdminProduct>().toList();
    }).handleError((error) {
      debugPrint('❌ getProducts() stream hatası: $error');
      // Hata durumunda boş liste döndür, stream'i kırmayalım
      return <AdminProduct>[];
    });
  }

  // Tüm ürünleri getirme - Server-side fetch (cache bypass) - Web uygulaması için
  Future<List<AdminProduct>> getProductsFromServer({bool useCache = true}) async {
    _performance.startOperation('getProductsFromServer');
    
    // Cache kontrolü
    if (useCache) {
      final cached = _cache.get<List<AdminProduct>>('products_all');
      if (cached != null) {
        _performance.endOperation('getProductsFromServer');
        return cached;
      }
    }
    
    try {
      // Önce orderBy ile dene
      try {
        final snapshot = await _firestore
            .collection('products')
            .orderBy('createdAt', descending: true)
            .get(const GetOptions(source: Source.server));
        
        final products = snapshot.docs.map((doc) {
          try {
            return AdminProduct.fromFirestore(doc.data(), doc.id);
          } catch (e) {
            debugPrint('⚠️ Ürün parse hatası (${doc.id}): $e');
            return null;
          }
        }).where((product) => product != null).cast<AdminProduct>().toList();
        
        // Cache'e kaydet
        if (useCache) {
          _cache.set('products_all', products, ttl: const Duration(minutes: 2));
        }
        
        _performance.endOperation('getProductsFromServer');
        debugPrint('✅ getProductsFromServer() başarılı: ${products.length} ürün bulundu');
        return products;
      } catch (orderByError) {
        // orderBy hatası varsa (index eksik olabilir), orderBy olmadan dene
        debugPrint('⚠️ orderBy hatası, orderBy olmadan deneniyor: $orderByError');
        final snapshot = await _firestore
            .collection('products')
            .get(const GetOptions(source: Source.server));
        
        final products = snapshot.docs.map((doc) {
          try {
            return AdminProduct.fromFirestore(doc.data(), doc.id);
          } catch (e) {
            debugPrint('⚠️ Ürün parse hatası (${doc.id}): $e');
            return null;
          }
        }).where((product) => product != null).cast<AdminProduct>().toList();
        
        // createdAt'e göre manuel sıralama
        products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        // Cache'e kaydet
        if (useCache) {
          _cache.set('products_all', products, ttl: const Duration(minutes: 2));
        }
        
        _performance.endOperation('getProductsFromServer');
        debugPrint('✅ getProductsFromServer() başarılı (orderBy olmadan): ${products.length} ürün bulundu');
        return products;
      }
    } catch (e) {
      _performance.endOperation('getProductsFromServer');
      debugPrint('❌ getProductsFromServer() kritik hata: $e');
      rethrow;
    }
  }

  // Pagination ile ürünleri getir - Cursor-based pagination
  Future<Map<String, dynamic>> getProductsPaginated({
    int page = 0,
    int pageSize = defaultPageSize,
    String? category,
    bool? isActive,
    DocumentSnapshot? lastDocument,
  }) async {
    _performance.startOperation('getProductsPaginated');
    
    final pageSizeClamped = pageSize.clamp(1, maxPageSize);
    
    try {
      Query query = _firestore.collection('products');
      
      // Filtreler
      if (category != null && category.isNotEmpty && category != 'Tümü') {
        query = query.where('category', isEqualTo: category);
      }
      if (isActive != null) {
        query = query.where('isActive', isEqualTo: isActive);
      }
      
      // Sıralama ve limit
      query = query.orderBy('createdAt', descending: true);
      
      // Cursor-based pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      // Toplam sayı için ayrı sorgu (sadece ilk sayfa için)
      int totalCount = 0;
      if (page == 0) {
        try {
          final countSnapshot = await query.count().get();
          totalCount = countSnapshot.count ?? 0;
        } catch (e) {
          debugPrint('⚠️ Count sorgusu hatası: $e');
        }
      }
      
      // Sayfalama
      final snapshot = await query
          .limit(pageSizeClamped + 1) // Bir fazla çek, hasMore kontrolü için
          .get(const GetOptions(source: Source.server));
      
      final hasMore = snapshot.docs.length > pageSizeClamped;
      final docs = hasMore 
          ? snapshot.docs.take(pageSizeClamped).toList()
          : snapshot.docs;
      
      final products = docs.map((doc) {
        try {
          final data = doc.data();
          if (data == null) return null;
          final dataMap = data as Map<String, dynamic>;
          if (dataMap.isEmpty) return null;
          return AdminProduct.fromFirestore(dataMap, doc.id);
        } catch (e) {
          debugPrint('⚠️ Ürün parse hatası (${doc.id}): $e');
          return null;
        }
      }).where((product) => product != null).cast<AdminProduct>().toList();
      
      final lastDoc = docs.isNotEmpty ? docs.last : null;
      
      final result = {
        'products': products,
        'totalCount': totalCount,
        'page': page,
        'pageSize': pageSizeClamped,
        'totalPages': totalCount > 0 ? (totalCount / pageSizeClamped).ceil() : null,
        'hasMore': hasMore,
        'lastDocument': lastDoc,
      };
      
      _performance.endOperation('getProductsPaginated');
      return result;
    } catch (e) {
      _performance.endOperation('getProductsPaginated');
      debugPrint('❌ getProductsPaginated() hatası: $e');
      rethrow;
    }
  }

  // Aktif ürünleri getirme - Mobil ve web uygulamaları için
  Stream<List<AdminProduct>> getActiveProducts() {
    return _firestore
        .collection('products')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots(includeMetadataChanges: false)
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          return AdminProduct.fromFirestore(doc.data(), doc.id);
        } catch (e) {
          debugPrint('⚠️ Ürün parse hatası (${doc.id}): $e');
          return null;
        }
      }).where((product) => product != null).cast<AdminProduct>().toList();
    }).handleError((error) {
      debugPrint('❌ getActiveProducts() stream hatası: $error');
      return <AdminProduct>[];
    });
  }

  // Aktif ürünleri getirme - Server-side fetch (cache bypass) - Web uygulaması için
  Future<List<AdminProduct>> getActiveProductsFromServer() async {
    try {
      // Önce orderBy ile dene
      try {
        final snapshot = await _firestore
            .collection('products')
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .get(const GetOptions(source: Source.server));
        
        final products = snapshot.docs.map((doc) {
          try {
            return AdminProduct.fromFirestore(doc.data(), doc.id);
          } catch (e) {
            debugPrint('⚠️ Ürün parse hatası (${doc.id}): $e');
            return null;
          }
        }).where((product) => product != null).cast<AdminProduct>().toList();
        
        debugPrint('✅ getActiveProductsFromServer() başarılı: ${products.length} aktif ürün bulundu');
        return products;
      } catch (orderByError) {
        // orderBy hatası varsa (index eksik olabilir), orderBy olmadan dene
        debugPrint('⚠️ orderBy hatası, orderBy olmadan deneniyor: $orderByError');
        final snapshot = await _firestore
            .collection('products')
            .where('isActive', isEqualTo: true)
            .get(const GetOptions(source: Source.server));
        
        final products = snapshot.docs.map((doc) {
          try {
            return AdminProduct.fromFirestore(doc.data(), doc.id);
          } catch (e) {
            debugPrint('⚠️ Ürün parse hatası (${doc.id}): $e');
            return null;
          }
        }).where((product) => product != null).cast<AdminProduct>().toList();
        
        // createdAt'e göre manuel sıralama
        products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        debugPrint('✅ getActiveProductsFromServer() başarılı (orderBy olmadan): ${products.length} aktif ürün bulundu');
        return products;
      }
    } catch (e) {
      debugPrint('❌ getActiveProductsFromServer() kritik hata: $e');
      rethrow;
    }
  }

  // Tek ürün getirme
  Future<AdminProduct?> getProduct(String productId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('products')
          .doc(productId)
          .get();
      
      if (doc.exists) {
        return AdminProduct.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Ürün getirilirken hata oluştu: $e');
    }
  }

  // Stok güncelleme
  Future<void> updateStock(String productId, int newStock) async {
    try {
      await _firestore
          .collection('products')
          .doc(productId)
          .update({
        'stock': newStock,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Stok güncellenirken hata oluştu: $e');
    }
  }

  // Stok artırma
  Future<void> increaseStock(String productId, int amount) async {
    try {
      await _firestore
          .collection('products')
          .doc(productId)
          .update({
        'stock': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Stok artırılırken hata oluştu: $e');
    }
  }

  // Stok azaltma
  Future<void> decreaseStock(String productId, int amount) async {
    try {
      await _firestore
          .collection('products')
          .doc(productId)
          .update({
        'stock': FieldValue.increment(-amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Stok azaltılırken hata oluştu: $e');
    }
  }

  // Fiyat artırma (yüzde bazında)
  Future<void> increasePrice(String productId, double percentage) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (doc.exists) {
        final currentPrice = (doc.data()!['price'] as num).toDouble();
        final newPrice = currentPrice * (1 + percentage / 100);
        await _firestore.collection('products').doc(productId).update({
          'price': newPrice,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Fiyat artırma hatası: $e');
    }
  }

  // Fiyat düşürme (yüzde bazında)
  Future<void> decreasePrice(String productId, double percentage) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (doc.exists) {
        final currentPrice = (doc.data()!['price'] as num).toDouble();
        final newPrice = currentPrice * (1 - percentage / 100);
        // Fiyat negatif olamaz
        final finalPrice = newPrice.clamp(0, double.infinity);
        await _firestore.collection('products').doc(productId).update({
          'price': finalPrice,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Fiyat düşürme hatası: $e');
    }
  }

  // Ürün durumu değiştirme (aktif/pasif)
  Future<void> toggleProductStatus(String productId, bool isActive) async {
    try {
      await _firestore
          .collection('products')
          .doc(productId)
          .update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ürün durumu güncellenirken hata oluştu: $e');
    }
  }

  // Resim yükleme
  Future<String> uploadImage(File imageFile, String productId) async {
    try {
      String fileName = 'products/$productId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage.ref().child(fileName);
      
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Resim yüklenirken hata oluştu: $e');
    }
  }

  // Firebase Storage bağlantı testi
  Future<bool> testStorageConnection() async {
    try {
      if (Firebase.apps.isEmpty) {
        print('Debug: Firebase başlatılmamış');
        return false;
      }
      
      // Test dosyası oluştur
      final testRef = _storage.ref().child('test/connection_test.txt');
      await testRef.putString('test');
      await testRef.delete();
      
      print('Debug: Firebase Storage bağlantısı başarılı');
      return true;
    } catch (e) {
      print('Debug: Firebase Storage bağlantı hatası: $e');
      return false;
    }
  }

  // Serbest yol ile yükleme (koleksiyon vb. için)
  Future<String> uploadToPath(File imageFile, String pathPrefix) async {
    try {
      // Firebase'in başlatıldığını kontrol et
      if (!Firebase.apps.isNotEmpty) {
        throw Exception('Firebase başlatılmamış. Lütfen uygulamayı yeniden başlatın.');
      }
      
      final String fileName = '$pathPrefix/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref().child(fileName);
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      // Daha açıklayıcı Firebase hatası
      String errorMessage = 'Firebase Storage hatası: ${e.code}';
      if (e.message != null) {
        errorMessage += ' - ${e.message}';
      }
      
      // Yaygın hatalar için Türkçe açıklama
      switch (e.code) {
        case 'storage/unauthorized':
          errorMessage = 'Yükleme izni yok. Lütfen giriş yapın.';
          break;
        case 'storage/canceled':
          errorMessage = 'Yükleme iptal edildi.';
          break;
        case 'storage/unknown':
          errorMessage = 'Bilinmeyen Firebase hatası.';
          break;
        case 'storage/invalid-argument':
          errorMessage = 'Geçersiz dosya.';
          break;
        case 'storage/invalid-checksum':
          errorMessage = 'Dosya bozuk.';
          break;
        case 'storage/retry-limit-exceeded':
          errorMessage = 'Çok fazla deneme. Lütfen tekrar deneyin.';
          break;
        case 'storage/invalid-format':
          errorMessage = 'Desteklenmeyen dosya formatı.';
          break;
        case 'storage/invalid-event-name':
          errorMessage = 'Geçersiz işlem.';
          break;
        case 'storage/invalid-url':
          errorMessage = 'Geçersiz URL.';
          break;
        case 'storage/no-default-bucket':
          errorMessage = 'Firebase Storage yapılandırılmamış.';
          break;
        case 'storage/cannot-slice-blob':
          errorMessage = 'Dosya işlenemiyor.';
          break;
        case 'storage/server-file-wrong-size':
          errorMessage = 'Dosya boyutu uyumsuz.';
          break;
      }
      
      throw Exception(errorMessage);
    } catch (e) {
      if (e.toString().contains('no object') || e.toString().contains('Firebase')) {
        throw Exception('Firebase bağlantı hatası. Lütfen internet bağlantınızı kontrol edin ve uygulamayı yeniden başlatın.');
      }
      throw Exception('Dosya yüklenemedi: $e');
    }
  }

  // Kategori ekleme
  Future<String> addCategory(ProductCategory category) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('categories')
          .add(category.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Kategori eklenirken hata oluştu: $e');
    }
  }

  // Kategorileri getirme (sadece aktif)
  Stream<List<ProductCategory>> getCategories() {
    return _firestore
        .collection('categories')
        .where('isActive', isEqualTo: true)
        .snapshots(includeMetadataChanges: false)
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          return ProductCategory.fromFirestore(doc.data(), doc.id);
        } catch (e) {
          debugPrint('⚠️ Kategori parse hatası (${doc.id}): $e');
          // Skip invalid documents
          return null;
        }
      }).where((category) => category != null).cast<ProductCategory>().toList();
    }).handleError((error) {
      debugPrint('❌ getCategories() stream hatası: $error');
      // Hata durumunda boş liste döndür, stream'i kırmayalım
      return <ProductCategory>[];
    });
  }

  // Tüm kategorileri getirme (aktif ve pasif)
  Stream<List<ProductCategory>> getAllCategories() {
    return _firestore
        .collection('categories')
        .snapshots(includeMetadataChanges: false)
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          return ProductCategory.fromFirestore(doc.data(), doc.id);
        } catch (e) {
          debugPrint('⚠️ Kategori parse hatası (${doc.id}): $e');
          // Skip invalid documents
          return null;
        }
      }).where((category) => category != null).cast<ProductCategory>().toList();
    }).handleError((error) {
      debugPrint('❌ getAllCategories() stream hatası: $error');
      // Hata durumunda boş liste döndür, stream'i kırmayalım
      return <ProductCategory>[];
    });
  }

  // Kategori güncelleme
  Future<void> updateCategory(ProductCategory category) async {
    try {
      await _firestore
          .collection('categories')
          .doc(category.id)
          .update(category.toFirestore());
    } catch (e) {
      throw Exception('Kategori güncellenirken hata oluştu: $e');
    }
  }

  // Kategori silme
  Future<void> deleteCategory(String categoryId) async {
    try {
      if (categoryId.trim().isEmpty) {
        throw Exception('Kategori ID\'si geçersiz');
      }

      final docRef = _firestore.collection('categories').doc(categoryId.trim());
      
      // Önce belgenin var olup olmadığını kontrol et (server'dan)
      final docSnapshot = await docRef.get(const GetOptions(source: Source.server));
      if (!docSnapshot.exists) {
        // Belge zaten yoksa, silme işlemi başarılı sayılabilir
        return;
      }

      // Belgeyi sil
      await docRef.delete();
      
      // Silme işleminin başarılı olduğunu doğrula (server'dan kontrol et)
      // Bu, cache sorunlarını önlemek ve stream'in güncellenmesini garanti etmek için önemlidir
      await Future.delayed(const Duration(milliseconds: 100));
      final verifySnapshot = await docRef.get(const GetOptions(source: Source.server));
      
      if (verifySnapshot.exists) {
        // Belge hala varsa, tekrar silmeyi dene
        await docRef.delete();
        // Bir kez daha kontrol et
        await Future.delayed(const Duration(milliseconds: 100));
        final finalVerify = await docRef.get(const GetOptions(source: Source.server));
        if (finalVerify.exists) {
          throw Exception('Kategori silinemedi. Lütfen tekrar deneyin.');
        }
      }
    } catch (e) {
      if (e.toString().contains('geçersiz') || e.toString().contains('silinemedi')) {
        rethrow;
      }
      throw Exception('Kategori silinirken hata oluştu: $e');
    }
  }

  // Ürün arama
  Stream<List<AdminProduct>> searchProducts(String query) {
    return _firestore
        .collection('products')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: query + 'z')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AdminProduct.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  // Kategoriye göre ürün getirme
  Stream<List<AdminProduct>> getProductsByCategory(String category) {
    return _firestore
        .collection('products')
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AdminProduct.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  // Ürün güncelleme
  Future<void> updateProduct(String productId, AdminProduct product) async {
    _performance.startOperation('updateProduct');
    try {
      await _firestore
          .collection('products')
          .doc(productId)
          .update(product.toFirestore());
      
      // Cache'i temizle
      _cache.clearPattern('products');
      
      _performance.endOperation('updateProduct');
    } catch (e) {
      _performance.endOperation('updateProduct');
      throw Exception('Ürün güncellenirken hata oluştu: $e');
    }
  }

  // Stok kontrolü ve sipariş oluşturma
  Future<Map<String, dynamic>> createOrderWithStockCheck(List<Map<String, dynamic>> orderProducts, Map<String, String> customerInfo) async {
    try {
      // Önce stok kontrolü yap
      for (var orderProduct in orderProducts) {
        final productName = orderProduct['name'];
        final requestedQuantity = orderProduct['quantity'];
        
        // Ürün adına göre arama yap
        final querySnapshot = await _firestore
            .collection('products')
            .where('name', isEqualTo: productName)
            .limit(1)
            .get();
        
        if (querySnapshot.docs.isEmpty) {
          throw Exception('Ürün bulunamadı: $productName');
        }
        
        final productDoc = querySnapshot.docs.first;
        final currentStock = productDoc.data()['stock'] as int;
        if (currentStock < requestedQuantity) {
          throw Exception('Yetersiz stok: $productName (Mevcut: $currentStock, İstenen: $requestedQuantity)');
        }
      }
      
      // Stok kontrolü başarılı, siparişi oluştur ve stokları düş
      final orderId = 'ORD${DateTime.now().millisecondsSinceEpoch}';
      final orderData = {
        'id': orderId,
        'userId': _auth.currentUser?.uid,
        'products': orderProducts,
        'totalAmount': orderProducts.fold(0.0, (sum, p) => sum + (p['price'] * p['quantity'])),
        'orderDate': FieldValue.serverTimestamp(),
        'status': 'pending',
        'customerName': customerInfo['name'],
        'customerEmail': customerInfo['email'],
        'customerPhone': customerInfo['phone'],
        'shippingAddress': customerInfo['address'],
      };
      
      // Siparişi kaydet
      await _firestore.collection('orders').doc(orderId).set(orderData);
      
      // Stokları düş
      for (var orderProduct in orderProducts) {
        final productName = orderProduct['name'];
        final requestedQuantity = orderProduct['quantity'];
        
        // Ürün adına göre arama yap
        final querySnapshot = await _firestore
            .collection('products')
            .where('name', isEqualTo: productName)
            .limit(1)
            .get();
        
        if (querySnapshot.docs.isNotEmpty) {
          final productDoc = querySnapshot.docs.first;
          await productDoc.reference.update({
            'stock': FieldValue.increment(-requestedQuantity),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      
      return {
        'success': true,
        'orderId': orderId,
        'message': 'Sipariş başarıyla oluşturuldu ve stoklar güncellendi'
      };
      
    } catch (e) {
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }

  // Siparişleri getir - Optimize edilmiş
  Stream<List<OrderModel.Order>> getOrders({int? limit}) {
    Query query = _firestore
        .collection('orders')
        .orderBy('orderDate', descending: true);
    
    if (limit != null && limit > 0) {
      query = query.limit(limit);
    }
    
      return query
        .snapshots(includeMetadataChanges: false)
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          if (data == null) return null;
          final dataMap = data as Map<String, dynamic>;
          if (dataMap.isEmpty) return null;
          return OrderModel.Order(
            id: doc.id,
            userId: dataMap['userId'] as String?,
            products: (dataMap['products'] as List<dynamic>?)
                ?.map((p) => Product.fromMap(p as Map<String, dynamic>))
                .toList() ?? [],
            totalAmount: (dataMap['totalAmount'] ?? 0.0).toDouble(),
            orderDate: (dataMap['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
            status: dataMap['status'] as String? ?? 'pending',
            customerName: dataMap['customerName'] as String? ?? '',
            customerEmail: dataMap['customerEmail'] as String? ?? '',
            customerPhone: dataMap['customerPhone'] as String? ?? '',
            shippingAddress: dataMap['shippingAddress'] as String? ?? '',
            trackingNumber: dataMap['trackingNumber'] as String?,
            notes: dataMap['notes'] as String?,
          );
        } catch (e) {
          debugPrint('⚠️ Sipariş parse hatası (${doc.id}): $e');
          return null;
        }
      }).whereType<OrderModel.Order>().toList();
    }).handleError((error) {
      debugPrint('❌ getOrders() stream hatası: $error');
      return <OrderModel.Order>[];
    });
  }

  // Pagination ile siparişleri getir - Cursor-based pagination
  Future<Map<String, dynamic>> getOrdersPaginated({
    int page = 0,
    int pageSize = defaultPageSize,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    DocumentSnapshot? lastDocument,
  }) async {
    _performance.startOperation('getOrdersPaginated');
    
    final pageSizeClamped = pageSize.clamp(1, maxPageSize);
    
    try {
      Query query = _firestore.collection('orders');
      
      // Filtreler
      if (status != null && status.isNotEmpty && status != 'Tümü') {
        query = query.where('status', isEqualTo: status);
      }
      if (startDate != null) {
        query = query.where('orderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('orderDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      
      // Sıralama
      query = query.orderBy('orderDate', descending: true);
      
      // Cursor-based pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      // Toplam sayı (sadece ilk sayfa için)
      int totalCount = 0;
      if (page == 0) {
        try {
          final countSnapshot = await query.count().get();
          totalCount = countSnapshot.count ?? 0;
        } catch (e) {
          debugPrint('⚠️ Count sorgusu hatası: $e');
        }
      }
      
      // Sayfalama
      final snapshot = await query
          .limit(pageSizeClamped + 1) // Bir fazla çek, hasMore kontrolü için
          .get(const GetOptions(source: Source.server));
      
      final hasMore = snapshot.docs.length > pageSizeClamped;
      final docs = hasMore 
          ? snapshot.docs.take(pageSizeClamped).toList()
          : snapshot.docs;
      
      final orders = docs.map((doc) {
        try {
          final data = doc.data();
          if (data == null) return null;
          final dataMap = data as Map<String, dynamic>;
          if (dataMap.isEmpty) return null;
          return OrderModel.Order(
            id: doc.id,
            userId: dataMap['userId'] as String?,
            products: (dataMap['products'] as List<dynamic>?)
                ?.map((p) => Product.fromMap(p as Map<String, dynamic>))
                .toList() ?? [],
            totalAmount: (dataMap['totalAmount'] ?? 0.0).toDouble(),
            orderDate: (dataMap['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
            status: dataMap['status'] as String? ?? 'pending',
            customerName: dataMap['customerName'] as String? ?? '',
            customerEmail: dataMap['customerEmail'] as String? ?? '',
            customerPhone: dataMap['customerPhone'] as String? ?? '',
            shippingAddress: dataMap['shippingAddress'] as String? ?? '',
            trackingNumber: dataMap['trackingNumber'] as String?,
            notes: dataMap['notes'] as String?,
          );
        } catch (e) {
          debugPrint('⚠️ Sipariş parse hatası (${doc.id}): $e');
          return null;
        }
      }).whereType<OrderModel.Order>().toList();
      
      final lastDoc = docs.isNotEmpty ? docs.last : null;
      
      final result = {
        'orders': orders,
        'totalCount': totalCount,
        'page': page,
        'pageSize': pageSizeClamped,
        'totalPages': totalCount > 0 ? (totalCount / pageSizeClamped).ceil() : null,
        'hasMore': hasMore,
        'lastDocument': lastDoc,
      };
      
      _performance.endOperation('getOrdersPaginated');
      return result;
    } catch (e) {
      _performance.endOperation('getOrdersPaginated');
      debugPrint('❌ getOrdersPaginated() hatası: $e');
      rethrow;
    }
  }

  // Sipariş durumu güncelle
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Sipariş durumu güncellenirken hata oluştu: $e');
    }
  }

  // Sipariş alanlarını güncelleme
  Future<void> updateOrderFields(String orderId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('orders').doc(orderId).update(updates);
    } catch (e) {
      throw Exception('Sipariş güncellenirken hata oluştu: $e');
    }
  }

  // Mevcut siparişlerdeki rasgele adresleri temizle
  Future<void> cleanRandomAddresses() async {
    try {
      final ordersSnapshot = await _firestore.collection('orders').get();
      int cleanedCount = 0;
      
      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        final address = data['shippingAddress'] as String?;
        
        // Rasgele adresleri tespit et ve temizle
        if (address != null && (
          address.contains('Teslimat adresi belirtilmedi') ||
          address.contains('Adres belirtilmedi') ||
          address.contains('Misafir') ||
          address.contains('Test') ||
          address.contains('Atatürk Mahallesi') ||
          address.contains('Cumhuriyet Caddesi') ||
          address.contains('Levent Mahallesi') ||
          address.contains('Büyükdere Caddesi') ||
          address.contains('Kadıköy') ||
          address.contains('Beşiktaş') ||
          address.contains('İstanbul') ||
          address.contains('34710') ||
          address.contains('34330') ||
          address.length < 10
        )) {
          await doc.reference.update({
            'shippingAddress': 'Adres belirtilmedi',
            'updatedAt': FieldValue.serverTimestamp(),
          });
          cleanedCount++;
        }
      }
      
      print('$cleanedCount adet rasgele adres temizlendi');
    } catch (e) {
      print('Adres temizleme hatası: $e');
    }
  }

  // Ürün stok kontrolü
  Future<Map<String, dynamic>> checkProductStock(String productName, int requestedQuantity) async {
    debugPrint('📦 [STOK KONTROL] ===========================================');
    debugPrint('📦 [STOK KONTROL] Fonksiyon başladı - ${DateTime.now()}');
    debugPrint('📦 [STOK KONTROL] Parametreler:');
    debugPrint('   - Ürün adı: $productName');
    debugPrint('   - İstenen miktar: $requestedQuantity');
    
    try {
      debugPrint('📦 [STOK KONTROL] Firestore sorgusu başlatılıyor...');
      debugPrint('   - Collection: products');
      debugPrint('   - Where: name == "$productName"');
      
      // Ürün adına göre arama yap
      final querySnapshot = await _firestore
          .collection('products')
          .where('name', isEqualTo: productName)
          .limit(1)
          .get();
      
      debugPrint('📦 [STOK KONTROL] Firestore sorgusu tamamlandı');
      debugPrint('   - Bulunan döküman sayısı: ${querySnapshot.docs.length}');
      
      if (querySnapshot.docs.isEmpty) {
        debugPrint('❌ [STOK KONTROL] Ürün bulunamadı!');
        debugPrint('   - Aranan ürün adı: $productName');
        final result = {
          'success': false,
          'error': 'Ürün bulunamadı: $productName'
        };
        debugPrint('📦 [STOK KONTROL] Dönen sonuç: $result');
        debugPrint('📦 [STOK KONTROL] ===========================================');
        return result;
      }
      
      debugPrint('✅ [STOK KONTROL] Ürün bulundu!');
      final productDoc = querySnapshot.docs.first;
      debugPrint('   - Döküman ID: ${productDoc.id}');
      
      final productData = productDoc.data();
      debugPrint('📦 [STOK KONTROL] Ürün verisi alındı:');
      debugPrint('   - Veri anahtarları: ${productData.keys.toList()}');
      
      final currentStock = productData['stock'] as int? ?? 0;
      debugPrint('📦 [STOK KONTROL] Stok bilgisi:');
      debugPrint('   - Mevcut stok: $currentStock');
      debugPrint('   - İstenen miktar: $requestedQuantity');
      debugPrint('   - Stok yeterli mi? ${currentStock >= requestedQuantity}');
      
      if (currentStock < requestedQuantity) {
        debugPrint('❌ [STOK KONTROL] Stok yetersiz!');
        debugPrint('   - Mevcut stok: $currentStock');
        debugPrint('   - İstenen miktar: $requestedQuantity');
        debugPrint('   - Eksik miktar: ${requestedQuantity - currentStock}');
        final result = {
          'success': false,
          'error': 'Ürün tükendi: $productName (Mevcut stok: $currentStock)',
          'currentStock': currentStock
        };
        debugPrint('📦 [STOK KONTROL] Dönen sonuç: $result');
        debugPrint('📦 [STOK KONTROL] ===========================================');
        return result;
      }
      
      debugPrint('✅ [STOK KONTROL] Stok yeterli!');
      final result = {
        'success': true,
        'currentStock': currentStock,
        'productId': productDoc.id
      };
      debugPrint('📦 [STOK KONTROL] Dönen sonuç: $result');
      debugPrint('📦 [STOK KONTROL] ===========================================');
      return result;
      
    } catch (e, stackTrace) {
      debugPrint('❌ [STOK KONTROL] KRİTİK HATA YAKALANDI!');
      debugPrint('   - Hata tipi: ${e.runtimeType}');
      debugPrint('   - Hata mesajı: $e');
      debugPrint('   - Stack trace:');
      debugPrint('$stackTrace');
      final result = {
        'success': false,
        'error': 'Stok kontrolü sırasında hata: $e'
      };
      debugPrint('📦 [STOK KONTROL] Dönen sonuç: $result');
      debugPrint('📦 [STOK KONTROL] ===========================================');
      return result;
    }
  }

  // Fiyat yönetimi metodları
  Future<void> updateProductFields(String productId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('products').doc(productId).update(updates);
    } catch (e) {
      throw Exception('Ürün güncellenirken hata: $e');
    }
  }

  Future<void> bulkUpdatePrices(List<String> productIds, double percentage, {bool increase = true}) async {
    try {
      final batch = _firestore.batch();
      
      for (final productId in productIds) {
        final productRef = _firestore.collection('products').doc(productId);
        final productDoc = await productRef.get();
        
        if (productDoc.exists) {
          final currentPrice = productDoc.data()?['price'] as double? ?? 0.0;
          double newPrice;
          
          if (increase) {
            newPrice = currentPrice * (1 + percentage / 100);
          } else {
            newPrice = currentPrice * (1 - percentage / 100);
          }
          
          if (newPrice > 0) {
            batch.update(productRef, {'price': newPrice});
          }
        }
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Toplu fiyat güncelleme hatası: $e');
    }
  }

  Future<void> bulkUpdatePricesByAmount(List<String> productIds, double amount, {bool increase = true}) async {
    try {
      final batch = _firestore.batch();
      
      for (final productId in productIds) {
        final productRef = _firestore.collection('products').doc(productId);
        final productDoc = await productRef.get();
        
        if (productDoc.exists) {
          final currentPrice = productDoc.data()?['price'] as double? ?? 0.0;
          double newPrice;
          
          if (increase) {
            newPrice = currentPrice + amount;
          } else {
            newPrice = currentPrice - amount;
          }
          
          if (newPrice > 0) {
            batch.update(productRef, {'price': newPrice});
          }
        }
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Toplu fiyat güncelleme hatası: $e');
    }
  }

  Future<Map<String, dynamic>> getPriceStatistics() async {
    try {
      final productsSnapshot = await _firestore.collection('products').get();
      
      if (productsSnapshot.docs.isEmpty) {
        return {
          'totalProducts': 0,
          'averagePrice': 0.0,
          'minPrice': 0.0,
          'maxPrice': 0.0,
          'totalValue': 0.0,
        };
      }
      
      double totalValue = 0.0;
      double minPrice = double.infinity;
      double maxPrice = 0.0;
      
      for (final doc in productsSnapshot.docs) {
        final data = doc.data();
        final price = (data['price'] as num?)?.toDouble() ?? 0.0;
        final stock = (data['stock'] as num?)?.toInt() ?? 0;
        
        totalValue += price * stock;
        if (price < minPrice) minPrice = price;
        if (price > maxPrice) maxPrice = price;
      }
      
      final averagePrice = totalValue / productsSnapshot.docs.length;
      
      return {
        'totalProducts': productsSnapshot.docs.length,
        'averagePrice': averagePrice,
        'minPrice': minPrice == double.infinity ? 0.0 : minPrice,
        'maxPrice': maxPrice,
        'totalValue': totalValue,
      };
    } catch (e) {
      throw Exception('Fiyat istatistikleri alınırken hata: $e');
    }
  }

  // Kullanıcı yönetimi metodları
  Stream<List<AdminUser>> getUsers() {
    return _firestore
        .collection('admin_users')
        .snapshots()
        .map((snapshot) {
      final users = snapshot.docs.map((doc) {
        try {
          return AdminUser.fromFirestore(doc.data(), doc.id);
        } catch (e) {
          debugPrint('⚠️ Admin kullanıcı parse hatası: $e');
          return null;
        }
      }).whereType<AdminUser>().toList();
      users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return users;
    });
  }

  // Kullanıcı adı müsaitlik kontrolü (anlık validasyon için)
  // Server'dan sorgu yaparak cache'i bypass eder - silinen kullanıcıların kullanıcı adları hemen müsait olur
  Future<bool> isUsernameAvailable(String username, {String? excludeUserId}) async {
    try {
      if (username.trim().isEmpty) {
        return false;
      }
      
      // Server'dan sorgu yap (cache'i bypass et) - silinen kullanıcıların kullanıcı adları hemen müsait olur
      final existingUsers = await _firestore
          .collection('admin_users')
          .where('username', isEqualTo: username.trim())
          .limit(1)
          .get(const GetOptions(source: Source.server));
      
      if (existingUsers.docs.isEmpty) {
        return true;
      }
      
      // Eğer excludeUserId verilmişse ve o ID'ye aitse, müsait say
      if (excludeUserId != null && existingUsers.docs.first.id == excludeUserId) {
        return true;
      }
      
      return false;
    } catch (e) {
      // Hata durumunda false döndür (güvenli taraf)
      return false;
    }
  }

  // E-posta müsaitlik kontrolü (anlık validasyon için)
  // Server'dan sorgu yaparak cache'i bypass eder - silinen kullanıcıların e-postaları hemen müsait olur
  Future<bool> isEmailAvailable(String email, {String? excludeUserId}) async {
    try {
      if (email.trim().isEmpty) {
        return false;
      }
      
      // Server'dan sorgu yap (cache'i bypass et) - silinen kullanıcıların e-postaları hemen müsait olur
      final existingEmails = await _firestore
          .collection('admin_users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get(const GetOptions(source: Source.server));
      
      if (existingEmails.docs.isEmpty) {
        return true;
      }
      
      // Eğer excludeUserId verilmişse ve o ID'ye aitse, müsait say
      if (excludeUserId != null && existingEmails.docs.first.id == excludeUserId) {
        return true;
      }
      
      return false;
    } catch (e) {
      // Hata durumunda false döndür (güvenli taraf)
      return false;
    }
  }

  Future<void> addUser(AdminUser user) async {
    try {
      // Kullanıcı adı ve email kontrolü - Server'dan sorgu yap (cache'i bypass et)
      // Böylece silinen kullanıcıların e-postaları ve kullanıcı adları hemen müsait olur
      final existingUsers = await _firestore
          .collection('admin_users')
          .where('username', isEqualTo: user.username)
          .limit(1)
          .get(const GetOptions(source: Source.server));
      
      if (existingUsers.docs.isNotEmpty) {
        throw Exception('Bu kullanıcı adı zaten kullanılıyor');
      }

      final existingEmails = await _firestore
          .collection('admin_users')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get(const GetOptions(source: Source.server));
      
      if (existingEmails.docs.isNotEmpty) {
        throw Exception('Bu e-posta adresi zaten kullanılıyor');
      }

      // Yeni kullanıcı için ID yoksa otomatik oluştur
      if (user.id.isEmpty) {
        final docRef = _firestore.collection('admin_users').doc();
        await docRef.set(user.copyWith(id: docRef.id).toFirestore());
      } else {
        await _firestore
            .collection('admin_users')
            .doc(user.id)
            .set(user.toFirestore());
      }
    } catch (e) {
      if (e.toString().contains('zaten kullanılıyor')) {
        rethrow;
      }
      throw Exception('Kullanıcı eklenirken hata oluştu: $e');
    }
  }

  Future<void> updateUser(AdminUser user) async {
    try {
      if (user.id.isEmpty) {
        throw Exception('Kullanıcı ID\'si bulunamadı');
      }

      // Kullanıcı adı ve email kontrolü (mevcut kullanıcı hariç)
      // Server'dan sorgu yap (cache'i bypass et) - silinen kullanıcıların verileri hemen müsait olur
      final existingUsers = await _firestore
          .collection('admin_users')
          .where('username', isEqualTo: user.username)
          .limit(1)
          .get(const GetOptions(source: Source.server));
      
      if (existingUsers.docs.isNotEmpty && existingUsers.docs.first.id != user.id) {
        throw Exception('Bu kullanıcı adı zaten kullanılıyor');
      }

      final existingEmails = await _firestore
          .collection('admin_users')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get(const GetOptions(source: Source.server));
      
      if (existingEmails.docs.isNotEmpty && existingEmails.docs.first.id != user.id) {
        throw Exception('Bu e-posta adresi zaten kullanılıyor');
      }

      // Firestore'da belge var mı kontrol et
      final docRef = _firestore.collection('admin_users').doc(user.id);
      final docSnapshot = await docRef.get();
      
      if (docSnapshot.exists) {
        // Belge varsa update kullan (sadece değişen alanları günceller)
        await docRef.update(user.toFirestore());
      } else {
        // Belge yoksa set kullan (tüm belgeyi oluşturur)
        await docRef.set(user.toFirestore(), SetOptions(merge: true));
      }
    } catch (e) {
      if (e.toString().contains('zaten kullanılıyor') || e.toString().contains('bulunamadı')) {
        rethrow;
      }
      throw Exception('Kullanıcı güncellenirken hata oluştu: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      if (userId.trim().isEmpty) {
        throw Exception('Kullanıcı ID\'si geçersiz');
      }

      final docRef = _firestore.collection('admin_users').doc(userId.trim());
      
      // Önce belgenin var olup olmadığını kontrol et
      final docSnapshot = await docRef.get(const GetOptions(source: Source.server));
      if (!docSnapshot.exists) {
        // Belge zaten yoksa, silme işlemi başarılı sayılabilir
        return;
      }

      // Belgeyi sil
      await docRef.delete();

      // Silme işleminin başarılı olduğunu doğrula (server'dan kontrol et)
      // Bu, cache sorunlarını önlemek için önemlidir
      await Future.delayed(const Duration(milliseconds: 100));
      final verifySnapshot = await docRef.get(const GetOptions(source: Source.server));
      
      if (verifySnapshot.exists) {
        // Belge hala varsa, tekrar silmeyi dene
        await docRef.delete();
        // Bir kez daha kontrol et
        await Future.delayed(const Duration(milliseconds: 100));
        final finalVerify = await docRef.get(const GetOptions(source: Source.server));
        if (finalVerify.exists) {
          throw Exception('Kullanıcı silinemedi. Lütfen tekrar deneyin.');
        }
      }
    } catch (e) {
      if (e.toString().contains('geçersiz') || e.toString().contains('silinemedi')) {
        rethrow;
      }
      throw Exception('Kullanıcı silinirken hata oluştu: $e');
    }
  }

  // Sistem ayarları
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    try {
      await _firestore
          .collection('admin_settings')
          .doc('system_settings')
          .set({
        ...settings,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ayarlar kaydedilirken hata oluştu: $e');
    }
  }

  Future<Map<String, dynamic>> getSettings() async {
    try {
      final doc = await _firestore
          .collection('admin_settings')
          .doc('system_settings')
          .get();
      
      if (doc.exists) {
        return doc.data() ?? {};
      }
      return {};
    } catch (e) {
      throw Exception('Ayarlar alınırken hata oluştu: $e');
    }
  }

}
