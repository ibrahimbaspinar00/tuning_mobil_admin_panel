import 'package:flutter/material.dart';
import 'model/admin_product.dart';
import 'services/admin_service.dart';

class WebAdminSimpleProducts extends StatefulWidget {
  const WebAdminSimpleProducts({super.key});

  @override
  State<WebAdminSimpleProducts> createState() => _WebAdminSimpleProductsState();
}

class _WebAdminSimpleProductsState extends State<WebAdminSimpleProducts> {
  final AdminService _adminService = AdminService();
  List<AdminProduct> _products = [];
  List<AdminProduct> _filteredProducts = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _sortBy = 'name';
  String _sortOrder = 'asc';
  String _selectedCategory = 'Tümü';
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
      final products = await _adminService.getProducts().first;
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
          SnackBar(content: Text('Ürünler yüklenirken hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ürün Yönetimi'),
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.white,
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
            ElevatedButton(
              onPressed: _showAddProductDialog,
              child: const Text('Yeni Ürün'),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: Column(
          children: [
            // Arama ve Filtre Bölümü
            Flexible(
              child: Container(
                padding: EdgeInsets.all(16),
                color: Colors.grey[100],
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Arama çubuğu
                      TextField(
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
                      
                      // Filtre bilgileri
                      if (_hasActiveFilters())
                        Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.filter_list, size: 16, color: Colors.blue),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _getFilterInfo(),
                                    style: TextStyle(color: Colors.blue[700], fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                TextButton(
                                  onPressed: _clearFilters,
                                  child: Text('Temizle', style: TextStyle(color: Colors.blue[700])),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Ürün listesi
            Expanded(
              child: _isLoading 
                ? Center(child: CircularProgressIndicator())
                : _products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Henüz ürün bulunmuyor'),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _showAddProductDialog,
                            child: Text('İlk Ürünü Ekle'),
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
                                backgroundColor: product.isActive ? Colors.green : Colors.red,
                                child: Icon(
                                  product.isActive ? Icons.check : Icons.close,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(product.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Fiyat: ₺${product.price.toStringAsFixed(2)}'),
                                  Text('Stok: ${product.stock} adet'),
                                  Text('Kategori: ${product.category}'),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditProductDialog(product);
                                  } else if (value == 'delete') {
                                    _showDeleteProductDialog(product);
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                                  PopupMenuItem(value: 'delete', child: Text('Sil')),
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
          title: const Text('Ürün Yönetimi'),
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.white,
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
              !product.category.toLowerCase().contains(query) &&
              !product.description.toLowerCase().contains(query)) {
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
          case 'price':
            comparison = a.price.compareTo(b.price);
            break;
          case 'stock':
            comparison = a.stock.compareTo(b.stock);
            break;
          case 'category':
            comparison = a.category.compareTo(b.category);
            break;
          case 'createdAt':
            comparison = a.createdAt.compareTo(b.createdAt);
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
          title: Text('Filtreler'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Kategori filtresi
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(labelText: 'Kategori'),
                items: [
                  DropdownMenuItem(value: 'Tümü', child: Text('Tüm Kategoriler')),
                  ..._products.map((p) => p.category).toSet().map((category) => 
                    DropdownMenuItem(value: category, child: Text(category))
                  ),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              SizedBox(height: 16),
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
          title: Text('Sıralama'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sıralama kriteri
              DropdownButtonFormField<String>(
                initialValue: _sortBy,
                decoration: InputDecoration(labelText: 'Sırala'),
                items: [
                  DropdownMenuItem(value: 'name', child: Text('İsim')),
                  DropdownMenuItem(value: 'price', child: Text('Fiyat')),
                  DropdownMenuItem(value: 'stock', child: Text('Stok')),
                  DropdownMenuItem(value: 'category', child: Text('Kategori')),
                  DropdownMenuItem(value: 'createdAt', child: Text('Oluşturma Tarihi')),
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

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => _ProductDialog(
        onSave: _addProduct,
      ),
    );
  }

  void _showEditProductDialog(AdminProduct product) {
    showDialog(
      context: context,
      builder: (context) => _ProductDialog(
        product: product,
        onSave: _updateProduct,
      ),
    );
  }

  void _showDeleteProductDialog(AdminProduct product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ürünü Sil'),
        content: Text('${product.name} ürününü silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct(product);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _addProduct(AdminProduct product) async {
    try {
      await _adminService.addProduct(product);
      _loadProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ürün başarıyla eklendi')),
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

  Future<void> _updateProduct(AdminProduct product) async {
    try {
      await _adminService.updateProduct(product.id, product);
      _loadProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ürün başarıyla güncellendi')),
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

  Future<void> _deleteProduct(AdminProduct product) async {
    try {
      await _adminService.deleteProduct(product.id);
      _loadProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ürün başarıyla silindi')),
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

class _ProductDialog extends StatefulWidget {
  final AdminProduct? product;
  final Function(AdminProduct) onSave;

  const _ProductDialog({
    this.product,
    required this.onSave,
  });

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _priceController.text = widget.product!.price.toString();
      _stockController.text = widget.product!.stock.toString();
      _categoryController.text = widget.product!.category;
      _descriptionController.text = widget.product!.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Yeni Ürün' : 'Ürün Düzenle'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Ürün Adı'),
                validator: (value) => value?.isEmpty == true ? 'Ürün adı gerekli' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Fiyat (₺)'),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty == true ? 'Fiyat gerekli' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stok Miktarı'),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty == true ? 'Stok gerekli' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Kategori'),
                validator: (value) => value?.isEmpty == true ? 'Kategori gerekli' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Açıklama'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _saveProduct,
          child: const Text('Kaydet'),
        ),
      ],
    );
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      final product = AdminProduct(
        id: widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        stock: int.parse(_stockController.text),
        category: _categoryController.text,
        imageUrl: '',
        isActive: true,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      widget.onSave(product);
      Navigator.pop(context);
    }
  }
}
