import 'package:flutter/material.dart';
import 'model/admin_product.dart';
import 'services/admin_service.dart';

class WebAdminStockManagement extends StatefulWidget {
  const WebAdminStockManagement({super.key});

  @override
  State<WebAdminStockManagement> createState() => _WebAdminStockManagementState();
}

class _WebAdminStockManagementState extends State<WebAdminStockManagement> {
  final AdminService _adminService = AdminService();
  List<AdminProduct> _products = [];
  List<AdminProduct> _filteredProducts = [];
  bool _isLoading = false;
  String _selectedCategory = 'Tümü';
  String _searchQuery = '';
  String _sortBy = 'name';
  String _sortOrder = 'asc';
  bool _showOnlyLowStock = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Server-side fetch kullan (cache bypass) - Web uygulaması için kritik
      final products = await _adminService.getProductsFromServer();
      if (mounted) {
        setState(() {
          _products = products;
          _filteredProducts = products;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ürünler yüklenirken hata: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
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
        title: const Text('Stok Yönetimi'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: Icon(Icons.filter_list),
            tooltip: 'Filtreler',
          ),
          IconButton(
            onPressed: _showSortDialog,
            icon: Icon(Icons.sort),
            tooltip: 'Sırala',
          ),
          DropdownButton<String>(
            value: () {
              final availableCategories = ['Tümü', ..._products.map((p) => p.category).where((c) => c.isNotEmpty).toSet()];
              return availableCategories.contains(_selectedCategory) ? _selectedCategory : 'Tümü';
            }(),
            items: [
              DropdownMenuItem(value: 'Tümü', child: Text('Tüm Kategoriler')),
              ..._products.map((p) => p.category).where((c) => c.isNotEmpty).toSet().map((category) => 
                DropdownMenuItem(value: category, child: Text(category))
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategory = value!;
              });
              _applyFilters();
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
              children: [
          // Arama çubuğu
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _applyFilters();
              },
              decoration: InputDecoration(
                hintText: 'Ürün ara...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                        _applyFilters();
                      },
                      icon: Icon(Icons.clear),
                    )
                  : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          
          // Filtre bilgileri
          if (_hasActiveFilters())
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.orange[50],
              child: Row(
                children: [
                  Icon(Icons.filter_list, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    _getFilterInfo(),
                    style: TextStyle(color: Colors.orange[700], fontSize: 12),
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: _clearFilters,
                    child: Text('Temizle', style: TextStyle(color: Colors.orange[700])),
                  ),
                ],
              ),
            ),
          
          // Stok listesi
          Expanded(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator())
              : _products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warehouse, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Stok bulunmuyor'),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadProducts,
                          child: Text('Yenile'),
                        ),
                      ],
                    ),
                  )
                : _filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Arama kriterlerinize uygun ürün bulunamadı'),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _clearFilters,
                            child: Text('Filtreleri Temizle'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStockColor(product.stock),
                      child: Text(
                        product.stock.toString(),
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(product.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kategori: ${product.category}'),
                        Text('Fiyat: ₺${product.price.toStringAsFixed(2)}'),
                        Text('Durum: ${_getStockStatus(product.stock)}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _showStockUpdateDialog(product),
                          icon: Icon(Icons.edit, color: Colors.blue),
                          tooltip: 'Stok Güncelle',
                        ),
                        IconButton(
                          onPressed: () => _increaseStock(product),
                          icon: Icon(Icons.add, color: Colors.green),
                          tooltip: 'Stok Artır',
                        ),
                        IconButton(
                          onPressed: () => _decreaseStock(product),
                          icon: Icon(Icons.remove, color: Colors.red),
                          tooltip: 'Stok Azalt',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
    } catch (e) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Stok Yönetimi'),
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

  void _applyFilters() {
    setState(() {
      _filteredProducts = _products.where((product) {
        // Arama filtresi
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          if (!product.name.toLowerCase().contains(query) &&
              !product.category.toLowerCase().contains(query)) {
            return false;
          }
        }
        
        // Kategori filtresi
        if (_selectedCategory != 'Tümü' && product.category != _selectedCategory) {
          return false;
        }
        
        // Düşük stok filtresi
        if (_showOnlyLowStock && product.stock > 10) {
          return false;
        }
        
        return true;
      }).toList();
      
      // Sıralama
      _filteredProducts.sort((a, b) {
        int comparison = 0;
        switch (_sortBy) {
          case 'name':
            comparison = a.name.compareTo(b.name);
            break;
          case 'stock':
            comparison = a.stock.compareTo(b.stock);
            break;
          case 'category':
            comparison = a.category.compareTo(b.category);
            break;
        }
        return _sortOrder == 'asc' ? comparison : -comparison;
      });
    });
  }

  bool _hasActiveFilters() {
    return _searchQuery.isNotEmpty || 
           _selectedCategory != 'Tümü' || 
           _showOnlyLowStock;
  }

  String _getFilterInfo() {
    List<String> filters = [];
    if (_searchQuery.isNotEmpty) filters.add('Arama: "$_searchQuery"');
    if (_selectedCategory != 'Tümü') filters.add('Kategori: $_selectedCategory');
    if (_showOnlyLowStock) filters.add('Düşük Stok');
    return filters.join(' • ');
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = 'Tümü';
      _showOnlyLowStock = false;
    });
    _applyFilters();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Stok Filtreleri'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Düşük stok filtresi
              CheckboxListTile(
                title: Text('Sadece düşük stoklu ürünler'),
                subtitle: Text('10 adet ve altı'),
                value: _showOnlyLowStock,
                onChanged: (value) {
                  setDialogState(() {
                    _showOnlyLowStock = value ?? false;
                  });
                },
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
                Navigator.pop(context);
                _applyFilters();
              },
              child: Text('Uygula'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Stok Sıralama'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sıralama kriteri
              DropdownButtonFormField<String>(
                initialValue: _sortBy,
                decoration: InputDecoration(labelText: 'Sırala'),
                items: [
                  DropdownMenuItem(value: 'name', child: Text('İsim')),
                  DropdownMenuItem(value: 'stock', child: Text('Stok Miktarı')),
                  DropdownMenuItem(value: 'category', child: Text('Kategori')),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    _sortBy = value!;
                  });
                },
              ),
              SizedBox(height: 16),
              // Sıralama yönü
              DropdownButtonFormField<String>(
                initialValue: _sortOrder,
                decoration: InputDecoration(labelText: 'Yön'),
                items: [
                  DropdownMenuItem(value: 'asc', child: Text('Artan (A-Z)')),
                  DropdownMenuItem(value: 'desc', child: Text('Azalan (Z-A)')),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    _sortOrder = value!;
                  });
                },
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
                Navigator.pop(context);
                _applyFilters();
              },
              child: Text('Uygula'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStockColor(int stock) {
    if (stock == 0) return Colors.red;
    if (stock <= 10) return Colors.orange;
    return Colors.green;
  }

  String _getStockStatus(int stock) {
    if (stock == 0) return 'Tükendi';
    if (stock <= 10) return 'Düşük Stok';
    return 'Normal';
  }

  void _showStockUpdateDialog(AdminProduct product) {
    final controller = TextEditingController(text: product.stock.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Stok Güncelle - ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Mevcut Stok: ${product.stock}'),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Yeni Stok Miktarı',
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
            onPressed: () async {
              final newStock = int.tryParse(controller.text);
              if (newStock != null && newStock >= 0) {
                Navigator.pop(context);
                await _updateStock(product, newStock);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Geçerli bir stok miktarı girin')),
                );
              }
            },
            child: Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  void _increaseStock(AdminProduct product) {
    _showStockChangeDialog(product, true);
  }

  void _decreaseStock(AdminProduct product) {
    _showStockChangeDialog(product, false);
  }

  void _showStockChangeDialog(AdminProduct product, bool isIncrease) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Stok ${isIncrease ? 'Artır' : 'Azalt'} - ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Mevcut Stok: ${product.stock}'),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Miktar',
                border: OutlineInputBorder(),
                prefixIcon: Icon(isIncrease ? Icons.add : Icons.remove),
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
            onPressed: () async {
              final amount = int.tryParse(controller.text);
              if (amount != null && amount > 0) {
                Navigator.pop(context);
                if (isIncrease) {
                  await _updateStock(product, product.stock + amount);
                } else {
                  if (amount <= product.stock) {
                    await _updateStock(product, product.stock - amount);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Azaltılacak miktar mevcut stoktan fazla olamaz')),
                    );
                  }
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Geçerli bir miktar girin')),
                );
              }
            },
            child: Text(isIncrease ? 'Artır' : 'Azalt'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStock(AdminProduct product, int newStock) async {
    try {
      await _adminService.updateStock(product.id, newStock);
      _loadProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product.name} stoku güncellendi: $newStock')),
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
