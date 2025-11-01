import 'package:flutter/foundation.dart';
import '../model/admin_product.dart';

class AIRecommendationService {
  static final AIRecommendationService _instance = AIRecommendationService._internal();
  factory AIRecommendationService() => _instance;
  AIRecommendationService._internal();

  // Kullanıcı davranış verileri
  final Map<String, List<String>> _userBehavior = {};
  final Map<String, int> _productViews = {};
  final Map<String, int> _productPurchases = {};
  final Map<String, List<String>> _userCategories = {};

  /// Kullanıcı davranışını kaydet
  void trackUserBehavior(String userId, String action, String productId) {
    if (!_userBehavior.containsKey(userId)) {
      _userBehavior[userId] = [];
    }
    _userBehavior[userId]!.add('$action:$productId');
    
    // Son 50 davranışı tut
    if (_userBehavior[userId]!.length > 50) {
      _userBehavior[userId]!.removeAt(0);
    }
  }

  /// Ürün görüntüleme sayısını artır
  void trackProductView(String productId) {
    _productViews[productId] = (_productViews[productId] ?? 0) + 1;
  }

  /// Ürün satın alma sayısını artır
  void trackProductPurchase(String productId) {
    _productPurchases[productId] = (_productPurchases[productId] ?? 0) + 1;
  }

  /// Kullanıcı kategorilerini güncelle
  void updateUserCategories(String userId, String category) {
    if (!_userCategories.containsKey(userId)) {
      _userCategories[userId] = [];
    }
    if (!_userCategories[userId]!.contains(category)) {
      _userCategories[userId]!.add(category);
    }
  }

  /// AI destekli ürün önerileri
  Future<List<AdminProduct>> getRecommendations(
    String userId,
    List<AdminProduct> allProducts, {
    int limit = 10,
  }) async {
    try {
      // Kullanıcı davranış analizi
      final userPreferences = _analyzeUserPreferences(userId);
      
      // Benzer kullanıcılar analizi
      final similarUsers = _findSimilarUsers(userId);
      
      // Popüler ürünler
      final popularProducts = _getPopularProducts();
      
      // Kategori bazlı öneriler
      final categoryRecommendations = _getCategoryRecommendations(userId, allProducts);
      
      // Fiyat bazlı öneriler
      final priceRecommendations = _getPriceRecommendations(userId, allProducts);
      
      // Tüm önerileri birleştir ve skorla
      final recommendations = _combineRecommendations(
        allProducts,
        userPreferences,
        similarUsers,
        popularProducts,
        categoryRecommendations,
        priceRecommendations,
      );
      
      // En iyi önerileri döndür
      return recommendations.take(limit).toList();
    } catch (e) {
      debugPrint('AI Recommendation error: $e');
      return _getFallbackRecommendations(allProducts, limit);
    }
  }

  /// Kullanıcı tercihlerini analiz et
  Map<String, double> _analyzeUserPreferences(String userId) {
    final preferences = <String, double>{};
    
    if (!_userBehavior.containsKey(userId)) {
      return preferences;
    }
    
    final behaviors = _userBehavior[userId]!;
    final categoryScores = <String, double>{};
    final priceScores = <String, double>{};
    
    for (final behavior in behaviors) {
      final parts = behavior.split(':');
      if (parts.length == 2) {
        final action = parts[0];
        final productId = parts[1];
        
        // Kategori skorları
        final category = _getProductCategory(productId);
        if (category != null) {
          categoryScores[category] = (categoryScores[category] ?? 0) + 
              (action == 'view' ? 1.0 : action == 'purchase' ? 3.0 : 0.5);
        }
        
        // Fiyat skorları
        final price = _getProductPrice(productId);
        if (price != null) {
          final priceRange = _getPriceRange(price);
          priceScores[priceRange] = (priceScores[priceRange] ?? 0) + 
              (action == 'view' ? 1.0 : action == 'purchase' ? 3.0 : 0.5);
        }
      }
    }
    
    // Normalize scores
    final totalCategoryScore = categoryScores.values.fold(0.0, (a, b) => a + b);
    final totalPriceScore = priceScores.values.fold(0.0, (a, b) => a + b);
    
    for (final entry in categoryScores.entries) {
      preferences['category_${entry.key}'] = entry.value / totalCategoryScore;
    }
    
    for (final entry in priceScores.entries) {
      preferences['price_${entry.key}'] = entry.value / totalPriceScore;
    }
    
    return preferences;
  }

  /// Benzer kullanıcıları bul
  List<String> _findSimilarUsers(String userId) {
    final similarUsers = <String, double>{};
    final userBehaviors = _userBehavior[userId] ?? [];
    
    for (final otherUserId in _userBehavior.keys) {
      if (otherUserId == userId) continue;
      
      final similarity = _calculateSimilarity(userBehaviors, _userBehavior[otherUserId]!);
      
      if (similarity > 0.3) {
        similarUsers[otherUserId] = similarity;
      }
    }
    
    final sortedEntries = similarUsers.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.map((e) => e.key).take(5).toList();
  }

  /// Popüler ürünleri getir
  List<String> _getPopularProducts() {
    final productScores = <String, double>{};
    
    for (final entry in _productViews.entries) {
      final productId = entry.key;
      final views = entry.value;
      final purchases = _productPurchases[productId] ?? 0;
      
      // Popülerlik skoru: görüntüleme * 0.3 + satın alma * 0.7
      productScores[productId] = views * 0.3 + purchases * 0.7;
    }
    
    final sortedEntries = productScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.map((e) => e.key).take(10).toList();
  }

  /// Kategori bazlı öneriler
  List<AdminProduct> _getCategoryRecommendations(String userId, List<AdminProduct> allProducts) {
    final userCategories = _userCategories[userId] ?? [];
    if (userCategories.isEmpty) return [];
    
    return allProducts.where((product) {
      return userCategories.any((category) => 
          product.category.toLowerCase().contains(category.toLowerCase()));
    }).toList();
  }

  /// Fiyat bazlı öneriler
  List<AdminProduct> _getPriceRecommendations(String userId, List<AdminProduct> allProducts) {
    // Kullanıcının ortalama fiyat tercihini hesapla
    final userBehaviors = _userBehavior[userId] ?? [];
    final prices = <double>[];
    
    for (final behavior in userBehaviors) {
      final parts = behavior.split(':');
      if (parts.length == 2) {
        final productId = parts[1];
        final price = _getProductPrice(productId);
        if (price != null) {
          prices.add(price);
        }
      }
    }
    
    if (prices.isEmpty) return [];
    
    final avgPrice = prices.reduce((a, b) => a + b) / prices.length;
    final priceRange = avgPrice * 0.5; // %50 tolerans
    
    return allProducts.where((product) {
      return (product.price >= avgPrice - priceRange && 
              product.price <= avgPrice + priceRange);
    }).toList();
  }

  /// Önerileri birleştir ve skorla
  List<AdminProduct> _combineRecommendations(
    List<AdminProduct> allProducts,
    Map<String, double> userPreferences,
    List<String> similarUsers,
    List<String> popularProducts,
    List<AdminProduct> categoryRecommendations,
    List<AdminProduct> priceRecommendations,
  ) {
    final productScores = <AdminProduct, double>{};
    
    for (final product in allProducts) {
      double score = 0.0;
      
      // Kategori skoru
      final categoryKey = 'category_${product.category}';
      if (userPreferences.containsKey(categoryKey)) {
        score += userPreferences[categoryKey]! * 0.4;
      }
      
      // Fiyat skoru
      final priceRange = _getPriceRange(product.price);
      final priceKey = 'price_$priceRange';
      if (userPreferences.containsKey(priceKey)) {
        score += userPreferences[priceKey]! * 0.3;
      }
      
      // Popülerlik skoru
      if (popularProducts.contains(product.id)) {
        score += 0.2;
      }
      
      // Kategori önerisi skoru
      if (categoryRecommendations.contains(product)) {
        score += 0.3;
      }
      
      // Fiyat önerisi skoru
      if (priceRecommendations.contains(product)) {
        score += 0.2;
      }
      
      // Benzer kullanıcılar skoru
      for (final similarUserId in similarUsers) {
        final similarBehaviors = _userBehavior[similarUserId] ?? [];
        for (final behavior in similarBehaviors) {
          final parts = behavior.split(':');
          if (parts.length == 2 && parts[1] == product.id) {
            score += 0.1;
            break;
          }
        }
      }
      
      productScores[product] = score;
    }
    
    // Skorlara göre sırala
    final sortedProducts = productScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedProducts.map((e) => e.key).toList();
  }

  /// Fallback öneriler
  List<AdminProduct> _getFallbackRecommendations(List<AdminProduct> allProducts, int limit) {
    // Popüler ürünleri döndür
    final popularProducts = allProducts.where((product) => 
        _productViews[product.id] != null && _productViews[product.id]! > 0
    ).toList();
    
    popularProducts.sort((a, b) => 
        (_productViews[b.id] ?? 0).compareTo(_productViews[a.id] ?? 0));
    
    return popularProducts.take(limit).toList();
  }

  /// Yardımcı metodlar
  String? _getProductCategory(String productId) {
    // Bu gerçek uygulamada veritabanından gelecek
    return null;
  }

  double? _getProductPrice(String productId) {
    // Bu gerçek uygulamada veritabanından gelecek
    return null;
  }

  String _getPriceRange(double price) {
    if (price < 50) return '0-50';
    if (price < 100) return '50-100';
    if (price < 250) return '100-250';
    if (price < 500) return '250-500';
    return '500+';
  }

  double _calculateSimilarity(List<String> behaviors1, List<String> behaviors2) {
    final set1 = behaviors1.toSet();
    final set2 = behaviors2.toSet();
    final intersection = set1.intersection(set2);
    final union = set1.union(set2);
    
    return intersection.length / union.length;
  }

  /// Analitik verileri getir
  Map<String, dynamic> getAnalytics() {
    return {
      'totalUsers': _userBehavior.length,
      'totalViews': _productViews.values.fold(0, (a, b) => a + b),
      'totalPurchases': _productPurchases.values.fold(0, (a, b) => a + b),
      'mostViewedProduct': _productViews.entries.isNotEmpty 
          ? _productViews.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : null,
      'mostPurchasedProduct': _productPurchases.entries.isNotEmpty
          ? _productPurchases.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : null,
    };
  }

  /// Verileri temizle
  void clearData() {
    _userBehavior.clear();
    _productViews.clear();
    _productPurchases.clear();
    _userCategories.clear();
  }
}
