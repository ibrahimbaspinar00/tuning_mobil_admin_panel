
import 'product.dart';

enum OrderStatus {
  pending,    // Beklemede
  confirmed,  // Onaylandı
  shipped,    // Kargoya verildi
  delivered,  // Teslim edildi
  cancelled,  // İptal edildi
}

class Order {
  final String id;
  final List<Product> products;
  final double totalAmount;
  final DateTime orderDate;
  final String status;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String shippingAddress;
  final String? trackingNumber;
  final String? notes;

  Order({
    required this.id,
    required this.products,
    required this.totalAmount,
    required this.orderDate,
    this.status = 'pending',
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.shippingAddress,
    this.trackingNumber,
    this.notes,
  });

  // Toplam ürün sayısı
  int get totalItems => products.fold(0, (sum, product) => sum + product.quantity);

  // Sipariş durumu metni
  String get statusText {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Beklemede';
      case 'confirmed':
        return 'Onaylandı';
      case 'shipped':
        return 'Kargoya Verildi';
      case 'delivered':
        return 'Teslim Edildi';
      case 'cancelled':
        return 'İptal Edildi';
      default:
        return 'Bilinmiyor';
    }
  }

  // Sipariş durumu rengi
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'orange';
      case 'confirmed':
        return 'blue';
      case 'shipped':
        return 'purple';
      case 'delivered':
        return 'green';
      case 'cancelled':
        return 'red';
      default:
        return 'grey';
    }
  }

  // Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'products': products.map((p) => p.toMap()).toList(),
      'totalAmount': totalAmount,
      'orderDate': orderDate.toIso8601String(),
      'status': status,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'shippingAddress': shippingAddress,
      'trackingNumber': trackingNumber,
      'notes': notes,
    };
  }

  // Map'ten oluşturma
  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] ?? '',
      products: (map['products'] as List<dynamic>?)
          ?.map((p) => Product.fromMap(p as Map<String, dynamic>))
          .toList() ?? [],
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      orderDate: DateTime.parse(map['orderDate'] ?? DateTime.now().toIso8601String()),
      status: map['status'] ?? 'pending',
      customerName: map['customerName'] ?? '',
      customerEmail: map['customerEmail'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      shippingAddress: map['shippingAddress'] ?? '',
      trackingNumber: map['trackingNumber'],
      notes: map['notes'],
    );
  }
}
