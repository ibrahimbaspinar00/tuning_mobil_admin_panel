class ProductReview {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String userEmail;
  final int rating; // 1-5 arası
  final String comment;
  final List<String> imageUrls; // Fotoğraf URL'leri
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isApproved;
  final String? adminResponse;
  final DateTime? adminResponseDate;
  final bool isEdited; // Yorum düzenlenmiş mi?

  ProductReview({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.rating,
    required this.comment,
    this.imageUrls = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isApproved = false,
    this.adminResponse,
    this.adminResponseDate,
    this.isEdited = false,
  });

  // JSON'dan ProductReview oluştur
  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      id: json['id'] ?? '',
      productId: json['productId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userEmail: json['userEmail'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      imageUrls: (json['imageUrls'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      isApproved: json['isApproved'] ?? false,
      adminResponse: json['adminResponse'],
      adminResponseDate: json['adminResponseDate'] != null 
          ? DateTime.parse(json['adminResponseDate']) 
          : null,
      isEdited: json['isEdited'] ?? false,
    );
  }

  // Map'ten oluşturma (Firebase için)
  factory ProductReview.fromMap(Map<String, dynamic> map) {
    return ProductReview(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      rating: map['rating'] ?? 0,
      comment: map['comment'] ?? '',
      imageUrls: (map['imageUrls'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      isApproved: map['isApproved'] ?? false,
      adminResponse: map['adminResponse'],
      adminResponseDate: map['adminResponseDate'] != null 
          ? DateTime.parse(map['adminResponseDate']) 
          : null,
      isEdited: map['isEdited'] ?? false,
    );
  }

  // ProductReview'ı JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'rating': rating,
      'comment': comment,
      'imageUrls': imageUrls,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isApproved': isApproved,
      'adminResponse': adminResponse,
      'adminResponseDate': adminResponseDate?.toIso8601String(),
      'isEdited': isEdited,
    };
  }

  // ProductReview'ı kopyala ve güncelle
  ProductReview copyWith({
    String? id,
    String? productId,
    String? userId,
    String? userName,
    String? userEmail,
    int? rating,
    String? comment,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isApproved,
    String? adminResponse,
    DateTime? adminResponseDate,
    bool? isEdited,
  }) {
    return ProductReview(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isApproved: isApproved ?? this.isApproved,
      adminResponse: adminResponse ?? this.adminResponse,
      adminResponseDate: adminResponseDate ?? this.adminResponseDate,
      isEdited: isEdited ?? this.isEdited,
    );
  }

  // Ortalama rating hesapla
  static double calculateAverageRating(List<ProductReview> reviews) {
    if (reviews.isEmpty) return 0.0;
    
    final approvedReviews = reviews.where((review) => review.isApproved).toList();
    if (approvedReviews.isEmpty) return 0.0;
    
    final totalRating = approvedReviews.fold(0, (sum, review) => sum + review.rating);
    return totalRating / approvedReviews.length;
  }

  // Rating dağılımını hesapla
  static Map<int, int> calculateRatingDistribution(List<ProductReview> reviews) {
    final approvedReviews = reviews.where((review) => review.isApproved).toList();
    final distribution = <int, int>{};
    
    for (int i = 1; i <= 5; i++) {
      distribution[i] = approvedReviews.where((review) => review.rating == i).length;
    }
    
    return distribution;
  }

  @override
  String toString() {
    return 'ProductReview(id: $id, productId: $productId, userName: $userName, rating: $rating, comment: $comment)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductReview && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
