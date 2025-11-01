import 'package:flutter/material.dart';
import 'model/admin_product.dart';
import 'model/order.dart' as OrderModel;
import 'services/admin_service.dart';

class WebAdminReports extends StatefulWidget {
  const WebAdminReports({super.key});

  @override
  State<WebAdminReports> createState() => _WebAdminReportsState();
}

class _WebAdminReportsState extends State<WebAdminReports> {
  final AdminService _adminService = AdminService();
  List<AdminProduct> _products = [];
  List<OrderModel.Order> _orders = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final products = await _adminService.getProducts().first;
      final orders = await _adminService.getOrders().first;
      if (mounted) {
        setState(() {
          _products = products;
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veriler yüklenirken hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Raporlar'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Rapor özelliği test modunda!')),
                );
              },
              icon: const Icon(Icons.download),
              tooltip: 'Raporu İndir',
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: _isLoading 
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rapor kartları
                  Row(
                    children: [
                      Expanded(
                        child: _buildReportCard(
                          'Toplam Ürün',
                          _products.length.toString(),
                          Icons.inventory,
                          Colors.blue,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildReportCard(
                          'Toplam Sipariş',
                          _orders.length.toString(),
                          Icons.shopping_cart,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildReportCard(
                          'Toplam Satış',
                          '₺${_getTotalSales().toStringAsFixed(2)}',
                          Icons.attach_money,
                          Colors.orange,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildReportCard(
                          'Düşük Stok',
                          _getLowStockCount().toString(),
                          Icons.warning,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  
                  // Detaylı raporlar
                  Text(
                    'Detaylı Raporlar',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  
                  // En çok satan ürünler
                  _buildTopProductsReport(),
                  SizedBox(height: 16),
                  
                  // Stok durumu
                  _buildStockReport(),
                  SizedBox(height: 16),
                  
                  // Son siparişler
                  _buildRecentOrdersReport(),
                ],
              ),
            ),
      );
    } catch (e) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Raporlar'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Hata: $e', style: TextStyle(fontSize: 16)),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                },
                child: Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildReportCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }

  double _getTotalSales() {
    return _orders.fold(0.0, (sum, order) => sum + order.totalAmount);
  }

  int _getLowStockCount() {
    return _products.where((p) => p.stock <= 10).length;
  }

  Widget _buildTopProductsReport() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'En Çok Satan Ürünler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ..._products.take(5).map((product) => ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text(product.stock.toString()),
              ),
              title: Text(product.name),
              subtitle: Text('Stok: ${product.stock} | Fiyat: ₺${product.price.toStringAsFixed(2)}'),
              trailing: Text(product.category),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildStockReport() {
    final lowStockProducts = _products.where((p) => p.stock <= 10).toList();
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stok Durumu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            if (lowStockProducts.isEmpty)
              Text('Tüm ürünlerde yeterli stok var!', style: TextStyle(color: Colors.green))
            else
              ...lowStockProducts.map((product) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: product.stock == 0 ? Colors.red : Colors.orange,
                  child: Text(product.stock.toString()),
                ),
                title: Text(product.name),
                subtitle: Text('Kategori: ${product.category}'),
                trailing: Text(
                  product.stock == 0 ? 'Tükendi' : 'Düşük Stok',
                  style: TextStyle(
                    color: product.stock == 0 ? Colors.red : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersReport() {
    final recentOrders = _orders.take(5).toList();
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Son Siparişler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            if (recentOrders.isEmpty)
              Text('Henüz sipariş bulunmuyor')
            else
              ...recentOrders.map((order) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getOrderStatusColor(order.status),
                  child: Icon(
                    _getOrderStatusIcon(order.status),
                    color: Colors.white,
                  ),
                ),
                title: Text('Sipariş #${order.id}'),
                subtitle: Text('Tutar: ₺${order.totalAmount.toStringAsFixed(2)}'),
                trailing: Text(
                  _getOrderStatusText(order.status),
                  style: TextStyle(
                    color: _getOrderStatusColor(order.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }

  Color _getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getOrderStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'completed':
        return Icons.check;
      case 'cancelled':
        return Icons.close;
      default:
        return Icons.help;
    }
  }

  String _getOrderStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Beklemede';
      case 'completed':
        return 'Tamamlandı';
      case 'cancelled':
        return 'İptal';
      default:
        return status;
    }
  }
}
