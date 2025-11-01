import 'package:flutter/material.dart';
import '../model/admin_product.dart';
import '../services/admin_service.dart';

class BulkOperationsWidget extends StatefulWidget {
  final List<AdminProduct> selectedProducts;
  final Function() onOperationComplete;

  const BulkOperationsWidget({
    super.key,
    required this.selectedProducts,
    required this.onOperationComplete,
  });

  @override
  State<BulkOperationsWidget> createState() => _BulkOperationsWidgetState();
}

class _BulkOperationsWidgetState extends State<BulkOperationsWidget> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (widget.selectedProducts.isEmpty) {
      return SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  '${widget.selectedProducts.length} ürün seçildi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                Spacer(),
                TextButton(
                  onPressed: () {
                    // Clear selection
                  },
                  child: Text('Seçimi Temizle'),
                ),
              ],
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildBulkButton(
                  'Stok Artır',
                  Icons.add,
                  Colors.green,
                  () => _showBulkStockDialog(true),
                ),
                _buildBulkButton(
                  'Stok Azalt',
                  Icons.remove,
                  Colors.orange,
                  () => _showBulkStockDialog(false),
                ),
                _buildBulkButton(
                  'Aktifleştir',
                  Icons.check_circle,
                  Colors.blue,
                  () => _bulkToggleActive(true),
                ),
                _buildBulkButton(
                  'Pasifleştir',
                  Icons.cancel,
                  Colors.red,
                  () => _bulkToggleActive(false),
                ),
                _buildBulkButton(
                  'Kategori Değiştir',
                  Icons.category,
                  Colors.purple,
                  () => _showBulkCategoryDialog(),
                ),
                _buildBulkButton(
                  'Fiyat Güncelle',
                  Icons.attach_money,
                  Colors.teal,
                  () => _showBulkPriceDialog(),
                ),
                _buildBulkButton(
                  'Sil',
                  Icons.delete,
                  Colors.red[700]!,
                  () => _showBulkDeleteDialog(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkButton(String title, IconData icon, Color color, VoidCallback onPressed) {
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

  void _showBulkStockDialog(bool isIncrease) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isIncrease ? 'Stok Artır' : 'Stok Azalt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${widget.selectedProducts.length} ürün için ${isIncrease ? 'artırılacak' : 'azaltılacak'} miktarı:'),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textCapitalization: TextCapitalization.none,
              decoration: InputDecoration(
                labelText: 'Miktar',
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
              final amount = int.tryParse(controller.text);
              if (amount != null && amount > 0) {
                Navigator.pop(context);
                _bulkUpdateStock(amount, isIncrease);
              }
            },
            child: Text('Uygula'),
          ),
        ],
      ),
    );
  }

  void _showBulkCategoryDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Kategori Değiştir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${widget.selectedProducts.length} ürün için yeni kategori:'),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Yeni Kategori',
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
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                _bulkUpdateCategory(controller.text);
              }
            },
            child: Text('Uygula'),
          ),
        ],
      ),
    );
  }

  void _showBulkPriceDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Fiyat Güncelle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${widget.selectedProducts.length} ürün için yeni fiyat:'),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textCapitalization: TextCapitalization.none,
              decoration: InputDecoration(
                labelText: 'Yeni Fiyat (₺)',
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
              final price = double.tryParse(controller.text);
              if (price != null && price > 0) {
                Navigator.pop(context);
                _bulkUpdatePrice(price);
              }
            },
            child: Text('Uygula'),
          ),
        ],
      ),
    );
  }

  void _showBulkDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ürünleri Sil'),
        content: Text('${widget.selectedProducts.length} ürünü silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _bulkDeleteProducts();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _bulkUpdateStock(int amount, bool isIncrease) async {
    setState(() {
      _isLoading = true;
    });

    try {
      for (final product in widget.selectedProducts) {
        if (isIncrease) {
          await AdminService().increaseStock(product.id, amount);
        } else {
          await AdminService().decreaseStock(product.id, amount);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.selectedProducts.length} ürünün stoku güncellendi'),
          backgroundColor: Colors.green,
        ),
      );

      widget.onOperationComplete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _bulkToggleActive(bool isActive) async {
    setState(() {
      _isLoading = true;
    });

    try {
      for (final product in widget.selectedProducts) {
        await AdminService().updateProduct(
          product.id,
          AdminProduct(
            id: product.id,
            name: product.name,
            description: product.description,
            price: product.price,
            stock: product.stock,
            imageUrl: product.imageUrl,
            category: product.category,
            isActive: isActive,
            createdAt: product.createdAt,
            updatedAt: DateTime.now(),
          ),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.selectedProducts.length} ürün ${isActive ? 'aktifleştirildi' : 'pasifleştirildi'}'),
          backgroundColor: Colors.green,
        ),
      );

      widget.onOperationComplete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _bulkUpdateCategory(String newCategory) async {
    setState(() {
      _isLoading = true;
    });

    try {
      for (final product in widget.selectedProducts) {
        await AdminService().updateProduct(
          product.id,
          AdminProduct(
            id: product.id,
            name: product.name,
            description: product.description,
            price: product.price,
            stock: product.stock,
            imageUrl: product.imageUrl,
            category: newCategory,
            isActive: product.isActive,
            createdAt: product.createdAt,
            updatedAt: DateTime.now(),
          ),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.selectedProducts.length} ürünün kategorisi güncellendi'),
          backgroundColor: Colors.green,
        ),
      );

      widget.onOperationComplete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _bulkUpdatePrice(double newPrice) async {
    setState(() {
      _isLoading = true;
    });

    try {
      for (final product in widget.selectedProducts) {
        await AdminService().updateProduct(
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
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.selectedProducts.length} ürünün fiyatı güncellendi'),
          backgroundColor: Colors.green,
        ),
      );

      widget.onOperationComplete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _bulkDeleteProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      for (final product in widget.selectedProducts) {
        await AdminService().deleteProduct(product.id);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.selectedProducts.length} ürün silindi'),
          backgroundColor: Colors.green,
        ),
      );

      widget.onOperationComplete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
