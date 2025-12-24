import 'package:flutter/material.dart';
import '../model/admin_product.dart';
import '../services/admin_service.dart';

class SmartNotificationsWidget extends StatefulWidget {
  const SmartNotificationsWidget({super.key});

  @override
  State<SmartNotificationsWidget> createState() => _SmartNotificationsWidgetState();
}

class _SmartNotificationsWidgetState extends State<SmartNotificationsWidget> {
  final AdminService _adminService = AdminService();
  List<NotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      // Server-side fetch kullan (cache bypass) - Web uygulaması için kritik
      final products = await _adminService.getProductsFromServer();
      final notifications = <NotificationItem>[];

      // Düşük stok uyarıları
      final validProducts = products;
      final lowStockProducts = validProducts.where((p) => p.stock <= 10).toList();
      if (lowStockProducts.isNotEmpty) {
        notifications.add(NotificationItem(
          type: NotificationType.warning,
          title: 'Düşük Stok Uyarısı',
          message: '${lowStockProducts.length} ürünün stoku düşük',
          icon: Icons.warning,
          color: Colors.orange,
          action: () => _showLowStockDetails(lowStockProducts),
        ));
      }

      // Pasif ürünler
      final inactiveProducts = validProducts.where((p) => !p.isActive).toList();
      if (inactiveProducts.isNotEmpty) {
        notifications.add(NotificationItem(
          type: NotificationType.info,
          title: 'Pasif Ürünler',
          message: '${inactiveProducts.length} ürün pasif durumda',
          icon: Icons.visibility_off,
          color: Colors.grey,
          action: () => _showInactiveProducts(inactiveProducts),
        ));
      }

      // Yeni ürünler (son 7 gün)
      final now = DateTime.now();
      final newProducts = validProducts.where((p) => 
        p.createdAt.isAfter(now.subtract(Duration(days: 7)))
      ).toList();
      if (newProducts.isNotEmpty) {
        notifications.add(NotificationItem(
          type: NotificationType.success,
          title: 'Yeni Ürünler',
          message: 'Son 7 günde ${newProducts.length} yeni ürün eklendi',
          icon: Icons.new_releases,
          color: Colors.green,
          action: () => _showNewProducts(newProducts),
        ));
      }

      // Stok değeri analizi
      final totalStockValue = validProducts.fold(0.0, (sum, p) => sum + (p.price * p.stock));
      if (totalStockValue > 100000) {
        notifications.add(NotificationItem(
          type: NotificationType.info,
          title: 'Yüksek Stok Değeri',
          message: 'Toplam stok değeri: ₺${totalStockValue.toStringAsFixed(0)}',
          icon: Icons.attach_money,
          color: Colors.blue,
          action: () => _showStockValueAnalysis(validProducts),
        ));
      }

      setState(() {
        _notifications = notifications;
      });
    } catch (e) {
      print('Bildirimler yüklenirken hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_notifications.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              Icon(Icons.check_circle, color: Colors.green, size: 48),
              const SizedBox(height: 8),
              Text(
                'Tüm sistemler normal çalışıyor',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
              Text(
                'Herhangi bir uyarı bulunmuyor',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Akıllı Bildirimler',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                Spacer(),
                TextButton(
                  onPressed: _loadNotifications,
                  child: Text('Yenile'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._notifications.map((notification) => _buildNotificationItem(notification)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: notification.action,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: notification.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: notification.color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: notification.color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  notification.icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: notification.color,
                      ),
                    ),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: notification.color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLowStockDetails(List<AdminProduct> products) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Düşük Stok Ürünleri'),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: product.stock <= 5 ? Colors.red : Colors.orange,
                  child: Text(
                    product.stock.toString(),
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(product.name),
                subtitle: Text('Kategori: ${product.category}'),
                trailing: Text(
                  '₺${product.price.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showInactiveProducts(List<AdminProduct> products) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pasif Ürünler'),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.visibility_off, color: Colors.white),
                ),
                title: Text(product.name),
                subtitle: Text('Kategori: ${product.category}'),
                trailing: ElevatedButton(
                  onPressed: () => _activateProduct(product),
                  child: Text('Aktifleştir'),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showNewProducts(List<AdminProduct> products) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Yeni Ürünler'),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.new_releases, color: Colors.white),
                ),
                title: Text(product.name),
                subtitle: Text('Eklenme: ${_formatDate(product.createdAt)}'),
                trailing: Text(
                  '₺${product.price.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showStockValueAnalysis(List<AdminProduct> products) {
    final totalValue = products.fold(0.0, (sum, p) => sum + (p.price * p.stock));
    final averageValue = totalValue / products.length;
    final highValueProducts = products.where((p) => (p.price * p.stock) > averageValue * 2).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Stok Değeri Analizi'),
        content: Container(
          width: double.maxFinite,
          height: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              _buildAnalysisItem('Toplam Değer', '₺${totalValue.toStringAsFixed(0)}', Colors.blue),
              _buildAnalysisItem('Ortalama Değer', '₺${averageValue.toStringAsFixed(0)}', Colors.green),
              _buildAnalysisItem('Yüksek Değerli Ürün', '${highValueProducts.length} adet', Colors.orange),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: highValueProducts.length,
                  itemBuilder: (context, index) {
                    final product = highValueProducts[index];
                    final value = product.price * product.stock;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange,
                        child: Text(
                          '₺${(value / 1000).toStringAsFixed(0)}K',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                      title: Text(product.name),
                      subtitle: Text('Stok: ${product.stock} × ₺${product.price.toStringAsFixed(2)}'),
                      trailing: Text(
                        '₺${value.toStringAsFixed(0)}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisItem(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _activateProduct(AdminProduct product) async {
    try {
      await _adminService.updateProduct(
        product.id,
        AdminProduct(
          id: product.id,
          name: product.name,
          description: product.description,
          price: product.price,
          stock: product.stock,
          imageUrl: product.imageUrl,
          category: product.category,
          isActive: true,
          createdAt: product.createdAt,
          updatedAt: DateTime.now(),
        ),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} aktifleştirildi'),
          backgroundColor: Colors.green,
        ),
      );
      
      _loadNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class NotificationItem {
  final NotificationType type;
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback action;

  NotificationItem({
    required this.type,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.action,
  });
}

enum NotificationType {
  success,
  warning,
  info,
  error,
}
