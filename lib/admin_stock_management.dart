import 'package:flutter/material.dart';
import 'model/admin_product.dart';
import 'services/admin_service.dart';

class AdminStockManagement extends StatefulWidget {
  const AdminStockManagement({super.key});

  @override
  State<AdminStockManagement> createState() => _AdminStockManagementState();
}

class _AdminStockManagementState extends State<AdminStockManagement> {
  final AdminService _adminService = AdminService();
  String _selectedCategory = 'Tümü';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stok Yönetimi',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // Arama ve filtreleme
          Row(
            children: [
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Ürün ara...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                onChanged: (value) {
                  // Arama fonksiyonu
                },
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _selectedCategory,
                items: const [
                  DropdownMenuItem(value: 'Tümü', child: Text('Tüm Kategoriler')),
                  DropdownMenuItem(value: 'Elektronik', child: Text('Elektronik')),
                  DropdownMenuItem(value: 'Giyim', child: Text('Giyim')),
                  DropdownMenuItem(value: 'Ev & Yaşam', child: Text('Ev & Yaşam')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Stok listesi
          Expanded(
            child: StreamBuilder<List<AdminProduct>>(
              stream: _getFilteredProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Hata: ${snapshot.error}'),
                  );
                }
                
                final products = snapshot.data ?? [];
                
                if (products.isEmpty) {
                  return const Center(
                    child: Text('Ürün bulunamadı'),
                  );
                }
                
                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStockColor(product.stock),
                          child: Text(
                            product.stock.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(product.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kategori: ${product.category}'),
                            Text('Fiyat: ₺${product.price.toStringAsFixed(2)}'),
                            Text(
                              'Durum: ${product.isActive ? "Aktif" : "Pasif"}',
                              style: TextStyle(
                                color: product.isActive ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Stok artırma butonu
                            IconButton(
                              onPressed: () => _showStockDialog(product, true),
                              icon: const Icon(Icons.add),
                              color: Colors.green,
                              tooltip: 'Stok Artır',
                            ),
                            // Stok azaltma butonu
                            IconButton(
                              onPressed: () => _showStockDialog(product, false),
                              icon: const Icon(Icons.remove),
                              color: Colors.orange,
                              tooltip: 'Stok Azalt',
                            ),
                            // Stok güncelleme butonu
                            IconButton(
                              onPressed: () => _showUpdateStockDialog(product),
                              icon: const Icon(Icons.edit),
                              color: Colors.blue,
                              tooltip: 'Stok Güncelle',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<AdminProduct>> _getFilteredProducts() {
    if (_selectedCategory == 'Tümü') {
      return _adminService.getProducts();
    } else {
      return _adminService.getProductsByCategory(_selectedCategory);
    }
  }

  Color _getStockColor(int stock) {
    if (stock <= 0) {
      return Colors.red;
    } else if (stock <= 10) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  void _showStockDialog(AdminProduct product, bool isIncrease) {
    final TextEditingController amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isIncrease ? 'Stok Artır' : 'Stok Azalt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ürün: ${product.name}'),
            Text('Mevcut Stok: ${product.stock}'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              textCapitalization: TextCapitalization.none,
              decoration: const InputDecoration(
                labelText: 'Miktar',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = int.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                if (isIncrease) {
                  _increaseStock(product.id, amount);
                } else {
                  _decreaseStock(product.id, amount);
                }
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Geçerli bir miktar girin')),
                );
              }
            },
            child: Text(isIncrease ? 'Artır' : 'Azalt'),
          ),
        ],
      ),
    );
  }

  void _showUpdateStockDialog(AdminProduct product) {
    final TextEditingController stockController = TextEditingController(
      text: product.stock.toString(),
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stok Güncelle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ürün: ${product.name}'),
            const SizedBox(height: 16),
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              textCapitalization: TextCapitalization.none,
              decoration: const InputDecoration(
                labelText: 'Yeni Stok Miktarı',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final newStock = int.tryParse(stockController.text);
              if (newStock != null && newStock >= 0) {
                _updateStock(product.id, newStock);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Geçerli bir stok miktarı girin')),
                );
              }
            },
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  Future<void> _increaseStock(String productId, int amount) async {
    try {
      await _adminService.increaseStock(productId, amount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stok $amount adet artırıldı')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  Future<void> _decreaseStock(String productId, int amount) async {
    try {
      await _adminService.decreaseStock(productId, amount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stok $amount adet azaltıldı')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  Future<void> _updateStock(String productId, int newStock) async {
    try {
      await _adminService.updateStock(productId, newStock);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stok başarıyla güncellendi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }
}
