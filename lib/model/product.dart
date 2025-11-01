class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String description;
  final String category;
  final int stock;
  int quantity; // Sepetteki miktar
  final double discountPercentage;
  final double averageRating;
  final int reviewCount;
  final int salesCount;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.category,
    required this.stock,
    this.quantity = 1,
    this.discountPercentage = 0.0,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.salesCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Toplam fiyat hesaplama
  double get totalPrice {
    if (price.isNaN || quantity.isNaN || price.isInfinite || quantity.isInfinite) {
      return 0.0;
    }
    return price * quantity;
  }

  // İndirimli fiyat
  double get discountedPrice {
    if (discountPercentage > 0) {
      return price * (1 - discountPercentage / 100);
    }
    return price;
  }

  // Ürün kopyalama (miktar ile)
  Product copyWith({
    int? quantity,
    double? discountPercentage,
    double? averageRating,
    int? reviewCount,
    int? salesCount,
    DateTime? createdAt,
  }) {
    return Product(
      id: id,
      name: name,
      price: price,
      imageUrl: imageUrl,
      description: description,
      category: category,
      stock: stock,
      quantity: quantity ?? this.quantity,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      salesCount: salesCount ?? this.salesCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'description': description,
      'category': category,
      'stock': stock,
      'quantity': quantity,
      'discountPercentage': discountPercentage,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'salesCount': salesCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Map'ten oluşturma
  factory Product.fromMap(Map<String, dynamic> map) {
    // Güvenli sayı dönüşümü için yardımcı fonksiyonlar
    double _safeToDouble(dynamic value) {
      if (value == null) return 0.0;
      final doubleVal = value.toDouble();
      if (doubleVal.isNaN || doubleVal.isInfinite) return 0.0;
      return doubleVal;
    }
    
    int _safeToInt(dynamic value) {
      if (value == null) return 0;
      final intVal = value.toInt();
      if (intVal.isNaN || intVal.isInfinite) return 0;
      return intVal;
    }

    DateTime _parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      
      // Firebase Timestamp tipini kontrol et
      if (value.toString().contains('Timestamp')) {
        try {
          // Timestamp'i DateTime'a çevir
          return DateTime.fromMillisecondsSinceEpoch(value.millisecondsSinceEpoch);
        } catch (e) {
          return DateTime.now();
        }
      }
      
      // String tipini kontrol et
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      
      // DateTime tipini kontrol et
      if (value is DateTime) {
        return value;
      }
      
      return DateTime.now();
    }
    
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: _safeToDouble(map['price']),
      imageUrl: map['imageUrl'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      stock: _safeToInt(map['stock']),
      quantity: _safeToInt(map['quantity']) > 0 ? _safeToInt(map['quantity']) : 1,
      discountPercentage: _safeToDouble(map['discountPercentage']),
      averageRating: _safeToDouble(map['averageRating']),
      reviewCount: _safeToInt(map['reviewCount']),
      salesCount: _safeToInt(map['salesCount']),
      createdAt: map['createdAt'] != null 
          ? _parseDateTime(map['createdAt'])
          : DateTime.now(),
    );
  }

  static List<Product>? get dummyProducts => null;
}
