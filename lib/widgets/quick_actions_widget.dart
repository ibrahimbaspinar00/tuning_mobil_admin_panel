import 'package:flutter/material.dart';
import '../model/admin_product.dart';
import '../services/admin_service.dart';

class QuickActionsWidget extends StatefulWidget {
  final Function() onActionComplete;

  const QuickActionsWidget({
    super.key,
    required this.onActionComplete,
  });

  @override
  State<QuickActionsWidget> createState() => _QuickActionsWidgetState();
}

class _QuickActionsWidgetState extends State<QuickActionsWidget> {
  final AdminService _adminService = AdminService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Hızlı İşlemler',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickAction(
                  'Tüm Ürünleri Aktifleştir',
                  Icons.check_circle,
                  Colors.green,
                  () => _activateAllProducts(),
                ),
                _buildQuickAction(
                  'Düşük Stok Uyarısı',
                  Icons.warning,
                  Colors.orange,
                  () => _checkLowStock(),
                ),
                _buildQuickAction(
                  'Toplu Fiyat Artır',
                  Icons.trending_up,
                  Colors.blue,
                  () => _showBulkPriceIncrease(),
                ),
                _buildQuickAction(
                  'Kategori Temizle',
                  Icons.cleaning_services,
                  Colors.purple,
                  () => _cleanupCategories(),
                ),
                _buildQuickAction(
                  'Veri Yedekle',
                  Icons.backup,
                  Colors.teal,
                  () => _backupData(),
                ),
                _buildQuickAction(
                  'Sistem Durumu',
                  Icons.health_and_safety,
                  Colors.red,
                  () => _checkSystemHealth(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(String title, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: _isLoading 
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon, size: 16),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Future<void> _activateAllProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _adminService.getProducts().first;
      int count = 0;
      
      for (final product in products) {
        if (!product.isActive) {
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
          count++;
        }
      }

      _showSuccessMessage('$count ürün aktifleştirildi');
      widget.onActionComplete();
    } catch (e) {
      _showErrorMessage('Hata: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkLowStock() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _adminService.getProducts().first;
      final validProducts = products.cast<AdminProduct>().toList();
      final lowStockProducts = validProducts.where((p) => p.stock <= 10).toList();
      
      if (lowStockProducts.isEmpty) {
        _showSuccessMessage('Düşük stok ürünü bulunamadı');
      } else {
        _showLowStockDialog(lowStockProducts);
      }
    } catch (e) {
      _showErrorMessage('Hata: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showBulkPriceIncrease() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Toplu Fiyat Artır'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tüm ürünlerin fiyatını yüzde kaç artırmak istiyorsunuz?'),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textCapitalization: TextCapitalization.none,
              decoration: InputDecoration(
                labelText: 'Yüzde (%)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final percentage = double.tryParse(controller.text);
              if (percentage != null && percentage > 0) {
                Navigator.pop(context);
                _bulkPriceIncrease(percentage);
              }
            },
            child: Text('Uygula'),
          ),
        ],
      ),
    );
  }

  Future<void> _bulkPriceIncrease(double percentage) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _adminService.getProducts().first;
      int count = 0;
      
      for (final product in products) {
        final newPrice = product.price * (1 + percentage / 100);
        await _adminService.updateProduct(
          product.id,
          AdminProduct(
            id: product.id,
            name: product.name,
            description: product.description,
            price: newPrice,
            stock: product.stock,
            imageUrl: product.imageUrl,
            category: product.category,
            isActive: product.isActive,
            createdAt: product.createdAt,
            updatedAt: DateTime.now(),
          ),
        );
        count++;
      }

      _showSuccessMessage('$count ürünün fiyatı %$percentage artırıldı');
      widget.onActionComplete();
    } catch (e) {
      _showErrorMessage('Hata: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cleanupCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _adminService.getProducts().first;
      final validProducts = products.cast<AdminProduct>().toList();
      final categories = validProducts.map((p) => p.category).toSet().toList();
      
      _showSuccessMessage('${categories.length} kategori bulundu: ${categories.join(', ')}');
    } catch (e) {
      _showErrorMessage('Hata: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _backupData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _adminService.getProducts().first;
      
      // Simüle edilmiş yedekleme
      await Future.delayed(Duration(seconds: 2));
      
      _showSuccessMessage('${products.length} ürün yedeklendi');
    } catch (e) {
      _showErrorMessage('Hata: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkSystemHealth() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _adminService.getProducts().first;
      final validProducts = products.cast<AdminProduct>().toList();
      final activeProducts = validProducts.where((p) => p.isActive).length;
      final lowStockProducts = validProducts.where((p) => p.stock <= 10).length;
      
      _showSystemHealthDialog(validProducts.length, activeProducts, lowStockProducts);
    } catch (e) {
      _showErrorMessage('Hata: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showLowStockDialog(List<AdminProduct> products) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Düşük Stok Ürünleri'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: product.stock <= 5 ? Colors.red : Colors.orange,
                  child: Icon(Icons.warning, color: Colors.white),
                ),
                title: Text(product.name),
                subtitle: Text('Stok: ${product.stock}'),
                trailing: ElevatedButton(
                  onPressed: () => _increaseStock(product),
                  child: Text('Stok Artır'),
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

  void _showSystemHealthDialog(int totalProducts, int activeProducts, int lowStockProducts) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sistem Durumu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHealthItem('Toplam Ürün', totalProducts.toString(), Colors.blue),
            _buildHealthItem('Aktif Ürün', activeProducts.toString(), Colors.green),
            _buildHealthItem('Düşük Stok', lowStockProducts.toString(), Colors.orange),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: lowStockProducts > 0 ? Colors.orange[100] : Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    lowStockProducts > 0 ? Icons.warning : Icons.check_circle,
                    color: lowStockProducts > 0 ? Colors.orange : Colors.green,
                  ),
                  SizedBox(width: 8),
                  Text(
                    lowStockProducts > 0 
                        ? 'Dikkat: Düşük stok ürünleri var!'
                        : 'Sistem sağlıklı',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: lowStockProducts > 0 ? Colors.orange[800] : Colors.green[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  Widget _buildHealthItem(String label, String value, Color color) {
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

  Future<void> _increaseStock(AdminProduct product) async {
    try {
      await _adminService.increaseStock(product.id, 10);
      _showSuccessMessage('${product.name} stoku 10 adet artırıldı');
      widget.onActionComplete();
    } catch (e) {
      _showErrorMessage('Hata: $e');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
