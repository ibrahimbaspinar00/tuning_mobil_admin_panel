import 'package:flutter/foundation.dart';
import '../model/order.dart' as OrderModel;
import '../model/admin_product.dart';
import 'admin_service.dart';

/// Gelişmiş raporlama servisi
class ReportService {
  final AdminService _adminService = AdminService();

  /// Finansal rapor - Gelir/Gider/Kar analizi
  Future<Map<String, dynamic>> getFinancialReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final orders = await _adminService.getOrders().first;
      
      // Tarih filtresi
      List<OrderModel.Order> filteredOrders = orders;
      if (startDate != null || endDate != null) {
        filteredOrders = orders.where((order) {
          if (startDate != null && order.orderDate.isBefore(startDate)) {
            return false;
          }
          if (endDate != null && order.orderDate.isAfter(endDate.add(const Duration(days: 1)))) {
            return false;
          }
          return true;
        }).toList();
      }

      // Gelir hesaplama
      final totalRevenue = filteredOrders.fold(0.0, (sum, order) => sum + order.totalAmount);
      
      // Durum bazlı gelir
      final revenueByStatus = <String, double>{};
      for (final order in filteredOrders) {
        revenueByStatus[order.status] = (revenueByStatus[order.status] ?? 0) + order.totalAmount;
      }

      // Günlük/haftalık/aylık gelir
      final dailyRevenue = <String, double>{};
      final weeklyRevenue = <String, double>{};
      final monthlyRevenue = <String, double>{};

      for (final order in filteredOrders) {
        // Günlük
        final dayKey = '${order.orderDate.year}-${order.orderDate.month.toString().padLeft(2, '0')}-${order.orderDate.day.toString().padLeft(2, '0')}';
        dailyRevenue[dayKey] = (dailyRevenue[dayKey] ?? 0) + order.totalAmount;

        // Haftalık
        final weekStart = order.orderDate.subtract(Duration(days: order.orderDate.weekday - 1));
        final weekKey = '${weekStart.year}-W${_getWeekNumber(weekStart)}';
        weeklyRevenue[weekKey] = (weeklyRevenue[weekKey] ?? 0) + order.totalAmount;

        // Aylık
        final monthKey = '${order.orderDate.year}-${order.orderDate.month.toString().padLeft(2, '0')}';
        monthlyRevenue[monthKey] = (monthlyRevenue[monthKey] ?? 0) + order.totalAmount;
      }

      // Ortalama sipariş değeri
      final averageOrderValue = filteredOrders.isEmpty 
          ? 0.0 
          : totalRevenue / filteredOrders.length;

      // İptal oranı
      final cancelledOrders = filteredOrders.where((o) => o.status == 'cancelled').length;
      final cancellationRate = filteredOrders.isEmpty 
          ? 0.0 
          : (cancelledOrders / filteredOrders.length) * 100;

      return {
        'totalRevenue': totalRevenue,
        'totalOrders': filteredOrders.length,
        'averageOrderValue': averageOrderValue,
        'revenueByStatus': revenueByStatus,
        'dailyRevenue': dailyRevenue,
        'weeklyRevenue': weeklyRevenue,
        'monthlyRevenue': monthlyRevenue,
        'cancelledOrders': cancelledOrders,
        'cancellationRate': cancellationRate,
        'startDate': startDate,
        'endDate': endDate,
      };
    } catch (e) {
      debugPrint('❌ Finansal rapor hatası: $e');
      rethrow;
    }
  }

  /// Satış raporu - Kategori/Ürün bazlı analiz
  Future<Map<String, dynamic>> getSalesReport({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    try {
      final orders = await _adminService.getOrders().first;
      final products = await _adminService.getProductsFromServer();

      // Tarih filtresi
      List<OrderModel.Order> filteredOrders = orders;
      if (startDate != null || endDate != null) {
        filteredOrders = orders.where((order) {
          if (startDate != null && order.orderDate.isBefore(startDate)) {
            return false;
          }
          if (endDate != null && order.orderDate.isAfter(endDate.add(const Duration(days: 1)))) {
            return false;
          }
          return true;
        }).toList();
      }

      // Kategori bazlı satış
      final categorySales = <String, Map<String, dynamic>>{};
      final productSales = <String, Map<String, dynamic>>{};

      for (final order in filteredOrders) {
        for (final orderProduct in order.products) {
          // Ürün bilgisini bul
          final product = products.firstWhere(
            (p) => p.id == orderProduct.id,
            orElse: () => AdminProduct(
              id: orderProduct.id,
              name: orderProduct.name,
              description: '',
              price: orderProduct.price,
              stock: 0,
              category: '',
              imageUrl: '',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          final productCategory = product.category.isEmpty ? 'Kategori Yok' : product.category;
          final revenue = orderProduct.price * orderProduct.quantity;

          // Kategori bazlı
          if (!categorySales.containsKey(productCategory)) {
            categorySales[productCategory] = {
              'revenue': 0.0,
              'quantity': 0,
              'orders': 0,
            };
          }
          categorySales[productCategory]!['revenue'] = 
              (categorySales[productCategory]!['revenue'] as double) + revenue;
          categorySales[productCategory]!['quantity'] = 
              (categorySales[productCategory]!['quantity'] as int) + orderProduct.quantity;
          categorySales[productCategory]!['orders'] = 
              (categorySales[productCategory]!['orders'] as int) + 1;

          // Ürün bazlı
          if (!productSales.containsKey(orderProduct.id)) {
            productSales[orderProduct.id] = {
              'name': orderProduct.name,
              'category': productCategory,
              'revenue': 0.0,
              'quantity': 0,
              'orders': 0,
            };
          }
          productSales[orderProduct.id]!['revenue'] = 
              (productSales[orderProduct.id]!['revenue'] as double) + revenue;
          productSales[orderProduct.id]!['quantity'] = 
              (productSales[orderProduct.id]!['quantity'] as int) + orderProduct.quantity;
          productSales[orderProduct.id]!['orders'] = 
              (productSales[orderProduct.id]!['orders'] as int) + 1;
        }
      }

      // En çok satan kategoriler
      final topCategories = categorySales.entries.toList()
        ..sort((a, b) => (b.value['revenue'] as double).compareTo(a.value['revenue'] as double));

      // En çok satan ürünler
      final topProducts = productSales.values.toList()
        ..sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));

      // Trend analizi (son 6 ay)
      final trendData = <String, Map<String, dynamic>>{};
      final now = DateTime.now();
      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final monthEnd = DateTime(now.year, now.month - i + 1, 0);
        final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
        
        final monthOrders = filteredOrders.where((o) => 
          o.orderDate.isAfter(month.subtract(const Duration(days: 1))) &&
          o.orderDate.isBefore(monthEnd.add(const Duration(days: 1)))
        ).toList();

        final monthRevenue = monthOrders.fold(0.0, (sum, o) => sum + o.totalAmount);
        final monthOrdersCount = monthOrders.length;

        trendData[monthKey] = {
          'revenue': monthRevenue,
          'orders': monthOrdersCount,
          'averageOrderValue': monthOrdersCount > 0 ? monthRevenue / monthOrdersCount : 0.0,
        };
      }

      return {
        'categorySales': categorySales,
        'productSales': productSales,
        'topCategories': topCategories.take(10).toList(),
        'topProducts': topProducts.take(20).toList(),
        'trendData': trendData,
        'totalRevenue': filteredOrders.fold(0.0, (sum, o) => sum + o.totalAmount),
        'totalOrders': filteredOrders.length,
        'startDate': startDate,
        'endDate': endDate,
      };
    } catch (e) {
      debugPrint('❌ Satış raporu hatası: $e');
      rethrow;
    }
  }

  /// Kar/Zarar analizi
  Future<Map<String, dynamic>> getProfitLossReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final financialReport = await getFinancialReport(
        startDate: startDate,
        endDate: endDate,
      );

      // Gelir
      final revenue = financialReport['totalRevenue'] as double;

      // Giderler (örnek - gerçek uygulamada Firestore'dan çekilebilir)
      // Şimdilik sabit giderler veya tahmini değerler kullanılabilir
      final estimatedCosts = revenue * 0.3; // %30 maliyet tahmini
      final netProfit = revenue - estimatedCosts;
      final profitMargin = revenue > 0 ? (netProfit / revenue) * 100 : 0.0;

      return {
        'revenue': revenue,
        'estimatedCosts': estimatedCosts,
        'netProfit': netProfit,
        'profitMargin': profitMargin,
        'startDate': startDate,
        'endDate': endDate,
      };
    } catch (e) {
      debugPrint('❌ Kar/Zarar raporu hatası: $e');
      rethrow;
    }
  }

  /// Hafta numarası hesaplama
  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday) / 7).ceil();
  }
}

