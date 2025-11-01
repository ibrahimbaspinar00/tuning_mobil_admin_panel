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

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Ürün ekleme
  Future<void> addProduct(AdminProduct product) async {
    try {
      await _firestore
          .collection('products')
          .doc(product.id)
          .set(product.toFirestore());
    } catch (e) {
      throw Exception('Ürün eklenirken hata oluştu: $e');
    }
  }

  // Ürün silme
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore
          .collection('products')
          .doc(productId)
          .delete();
    } catch (e) {
      throw Exception('Ürün silinirken hata oluştu: $e');
    }
  }

  // Tüm ürünleri getirme - Optimized
  Stream<List<AdminProduct>> getProducts() {
    return _firestore
        .collection('products')
        .orderBy('createdAt', descending: true)
        .limit(20) // Reduced limit for better performance
        .snapshots()
        .map((snapshot) {
      // Non-blocking processing
      return snapshot.docs.map((doc) {
        try {
          return AdminProduct.fromFirestore(doc.data(), doc.id);
        } catch (e) {
          // Skip invalid documents
          return null;
        }
      }).where((product) => product != null).cast<AdminProduct>().toList();
    });
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

  // Kategorileri getirme
  Stream<List<ProductCategory>> getCategories() {
    return _firestore
        .collection('categories')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProductCategory.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
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
    try {
      await _firestore
          .collection('products')
          .doc(productId)
          .update(product.toFirestore());
    } catch (e) {
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

  // Siparişleri getir
  Stream<List<OrderModel.Order>> getOrders() {
    return _firestore
        .collection('orders')
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return OrderModel.Order(
          id: doc.id,
          products: (data['products'] as List<dynamic>?)
              ?.map((p) => Product.fromMap(p as Map<String, dynamic>))
              .toList() ?? [],
          totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
          orderDate: (data['orderDate'] as Timestamp).toDate(),
          status: data['status'] ?? 'pending',
          customerName: data['customerName'] ?? '',
          customerEmail: data['customerEmail'] ?? '',
          customerPhone: data['customerPhone'] ?? '',
          shippingAddress: data['shippingAddress'] ?? '',
        );
      }).toList();
    });
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
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AdminUser.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> addUser(AdminUser user) async {
    try {
      // Kullanıcı adı ve email kontrolü
      final existingUsers = await _firestore
          .collection('admin_users')
          .where('username', isEqualTo: user.username)
          .limit(1)
          .get();
      
      if (existingUsers.docs.isNotEmpty) {
        throw Exception('Bu kullanıcı adı zaten kullanılıyor');
      }

      final existingEmails = await _firestore
          .collection('admin_users')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();
      
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
      final existingUsers = await _firestore
          .collection('admin_users')
          .where('username', isEqualTo: user.username)
          .limit(1)
          .get();
      
      if (existingUsers.docs.isNotEmpty && existingUsers.docs.first.id != user.id) {
        throw Exception('Bu kullanıcı adı zaten kullanılıyor');
      }

      final existingEmails = await _firestore
          .collection('admin_users')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();
      
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
      await _firestore
          .collection('admin_users')
          .doc(userId)
          .delete();
    } catch (e) {
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
