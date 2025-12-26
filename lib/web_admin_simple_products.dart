import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'model/admin_product.dart';
import 'services/admin_service.dart';
import 'services/audit_log_service.dart';
import 'services/permission_service.dart';
import 'services/performance_service.dart';
import 'widgets/professional_image_uploader.dart';
import 'widgets/optimized_list_view.dart';
import 'utils/responsive_helper.dart';

class WebAdminSimpleProducts extends StatefulWidget {
  const WebAdminSimpleProducts({super.key});

  @override
  State<WebAdminSimpleProducts> createState() => _WebAdminSimpleProductsState();
}

class _WebAdminSimpleProductsState extends State<WebAdminSimpleProducts> {
  final AdminService _adminService = AdminService();
  List<AdminProduct> _products = [];
  List<AdminProduct> _filteredProducts = [];
  List<AdminProduct> _displayedProducts = []; // Pagination için
  bool _isLoading = false;
  String _searchQuery = '';
  String _sortBy = 'name';
  String _sortOrder = 'asc';
  String _selectedCategory = 'Tümü';
  bool _showOnlyLowStock = false;
  List<ProductCategory> _categories = [];
  List<String> _availableCategories = ['Tümü'];
  
  // Pagination
  static const int _itemsPerPage = 20;
  int _currentPage = 0;
  bool _hasMore = true;
  
  // Bulk operations
  Set<String> _selectedProductIds = {};
  bool _isSelectionMode = false;
  
  // Performance optimizations
  final Debouncer _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 300));
  final PerformanceService _performance = PerformanceService();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadProducts();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _adminService.getCategories().first;
      setState(() {
        _categories = categories;
        _updateCategoriesFromProducts();
      });
    } catch (e) {
      debugPrint('Kategoriler yüklenirken hata: $e');
    }
  }

  void _updateCategoriesFromProducts() {
    final categorySet = <String>{'Tümü'};
    // Firestore'dan gelen kategorileri ekle
    for (final cat in _categories) {
      categorySet.add(cat.name);
    }
    // Mevcut ürünlerden de kategorileri al (kategori sistemi olmayan ürünler için)
    if (_products.isNotEmpty) {
      final productCategories = _products.map((p) => p.category).where((c) => c.isNotEmpty).toSet();
      categorySet.addAll(productCategories);
    }
    setState(() {
      _availableCategories = categorySet.toList()..sort();
    });
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    
    _performance.startOperation('loadProducts');
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Cache kullanarak server-side fetch
      final products = await _adminService.getProductsFromServer(useCache: true);
      if (mounted) {
        setState(() {
          _products = products;
          _filteredProducts = products;
          _isLoading = false;
        });
        // Ürünler yüklendikten sonra kategorileri güncelle
        _updateCategoriesFromProducts();
        _applyFilters();
        _performance.endOperation('loadProducts');
      }
    } catch (e) {
      _performance.endOperation('loadProducts');
      debugPrint('❌ _loadProducts() hatası: $e');
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
        appBar: AppBar(
          title: const Text('Ürün Yönetimi'),
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.white,
          actions: [
            if (_isSelectionMode) ...[
              Text('${_selectedProductIds.length} seçili'),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _exitSelectionMode,
                icon: const Icon(Icons.close),
                tooltip: 'Seçimi İptal Et',
              ),
              IconButton(
                onPressed: _selectedProductIds.isEmpty ? null : _showBulkActionsDialog,
                icon: const Icon(Icons.more_vert),
                tooltip: 'Toplu İşlemler',
              ),
            ] else ...[
              IconButton(
                onPressed: _enterSelectionMode,
                icon: const Icon(Icons.checklist),
                tooltip: 'Toplu Seçim',
              ),
              IconButton(
                onPressed: _showFilterDialog,
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filtreler',
              ),
              IconButton(
                onPressed: _showSortDialog,
                icon: const Icon(Icons.sort),
                tooltip: 'Sırala',
              ),
              ElevatedButton(
                onPressed: _showAddProductDialog,
                child: const Text('Yeni Ürün'),
              ),
            ],
            const SizedBox(width: 16),
          ],
        ),
        body: Column(
          children: [
            // Arama ve Filtre Bölümü - Sabit yükseklik
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Arama çubuğu - Debounced
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      // Debounce ile filtreleme
                      _searchDebouncer.call(() {
                        _applyFilters();
                      });
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
                  
                  // Kategori Filtreleme Çipleri
                  if (_availableCategories.length > 1)
                    Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _availableCategories.map((category) {
                            final isSelected = _selectedCategory == category;
                            return Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(category),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategory = category;
                                  });
                                  _applyFilters();
                                },
                                selectedColor: Colors.blue[200],
                                checkmarkColor: Colors.blue[900],
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.blue[900] : Colors.grey[700],
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
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
            
            // Ürün listesi - Kalan tüm alanı kapla
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
                    : OptimizedListView<AdminProduct>(
                        items: _displayedProducts,
                        padding: const EdgeInsets.all(16),
                        hasMore: _hasMore,
                        onLoadMore: _loadMoreProducts,
                        itemBuilder: (context, product, index) {
                          final isSelected = _selectedProductIds.contains(product.id);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: isSelected ? Colors.blue[50] : null,
                            key: ValueKey(product.id), // Widget rebuild optimizasyonu
                            child: ListTile(
                              leading: _isSelectionMode
                                  ? Checkbox(
                                      value: isSelected,
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == true) {
                                            _selectedProductIds.add(product.id);
                                          } else {
                                            _selectedProductIds.remove(product.id);
                                          }
                                        });
                                      },
                                    )
                                  : CircleAvatar(
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
                              trailing: _isSelectionMode
                                  ? null
                                  : PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _showEditProductDialog(product);
                                        } else if (value == 'delete') {
                                          _showDeleteProductDialog(product);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                                        const PopupMenuItem(value: 'delete', child: Text('Sil')),
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
    _performance.startOperation('applyFilters');
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
          default:
            comparison = a.name.compareTo(b.name);
        }
        return _sortOrder == 'asc' ? comparison : -comparison;
      });
      
      // Pagination reset
      _currentPage = 0;
      _updateDisplayedProducts();
    });
    _performance.endOperation('applyFilters');
  }
  
  void _updateDisplayedProducts() {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _filteredProducts.length);
    
    setState(() {
      _displayedProducts = _filteredProducts.sublist(0, endIndex);
      _hasMore = endIndex < _filteredProducts.length;
    });
  }
  
  void _loadMoreProducts() {
    if (!_hasMore || _isLoading) return;
    
    setState(() {
      _currentPage++;
    });
    _updateDisplayedProducts();
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
                value: _availableCategories.contains(_selectedCategory) 
                    ? _selectedCategory 
                    : 'Tümü',
                decoration: InputDecoration(labelText: 'Kategori'),
                items: _availableCategories.map((category) => 
                  DropdownMenuItem(
                    value: category,
                    child: Text(category == 'Tümü' ? 'Tüm Kategoriler' : category),
                  )
                ).toList(),
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
      
      // Audit log
      final userId = PermissionService.getCurrentUserId() ?? 'unknown';
      await AuditLogService.logAction(
        userId: userId,
        action: 'create',
        resource: 'product',
        details: {
          'productId': product.id,
          'productName': product.name,
          'price': product.price,
          'stock': product.stock,
        },
      );
      
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
      
      // Audit log
      final userId = PermissionService.getCurrentUserId() ?? 'unknown';
      await AuditLogService.logAction(
        userId: userId,
        action: 'update',
        resource: 'product',
        details: {
          'productId': product.id,
          'productName': product.name,
          'price': product.price,
          'stock': product.stock,
        },
      );
      
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
      
      // Audit log
      final userId = PermissionService.getCurrentUserId() ?? 'unknown';
      await AuditLogService.logAction(
        userId: userId,
        action: 'delete',
        resource: 'product',
        details: {
          'productId': product.id,
          'productName': product.name,
        },
      );
      
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

  // Bulk operations
  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedProductIds.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedProductIds.clear();
    });
  }

  void _showBulkActionsDialog() {
    if (_selectedProductIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Toplu İşlemler'),
        content: Text('${_selectedProductIds.length} ürün seçildi. Ne yapmak istersiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showBulkCategoryDialog();
            },
            child: const Text('Kategori Değiştir'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showBulkPriceDialog();
            },
            child: const Text('Fiyat Güncelle'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showBulkStockDialog();
            },
            child: const Text('Stok Güncelle'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showBulkStatusDialog();
            },
            child: const Text('Durum Değiştir'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showBulkDeleteDialog();
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showBulkCategoryDialog() {
    String? selectedCategory;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Toplu Kategori Değiştir'),
          content: DropdownButtonFormField<String>(
            value: selectedCategory,
            decoration: const InputDecoration(labelText: 'Yeni Kategori'),
            items: _availableCategories.where((c) => c != 'Tümü').map((cat) {
              return DropdownMenuItem(value: cat, child: Text(cat));
            }).toList(),
            onChanged: (value) => setState(() => selectedCategory = value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: selectedCategory == null
                  ? null
                  : () async {
                      await _bulkUpdateCategory(selectedCategory!);
                      Navigator.pop(context);
                    },
              child: const Text('Güncelle'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkPriceDialog() {
    final priceController = TextEditingController();
    String priceType = 'set'; // 'set', 'increase', 'decrease'
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Toplu Fiyat Güncelle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: priceType,
                decoration: const InputDecoration(labelText: 'İşlem Tipi'),
                items: const [
                  DropdownMenuItem(value: 'set', child: Text('Belirli Fiyat')),
                  DropdownMenuItem(value: 'increase', child: Text('Artır (%)')),
                  DropdownMenuItem(value: 'decrease', child: Text('Azalt (%)')),
                ],
                onChanged: (value) => setState(() => priceType = value!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: InputDecoration(
                  labelText: priceType == 'set' ? 'Yeni Fiyat (₺)' : 'Yüzde',
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: priceController.text.isEmpty
                  ? null
                  : () async {
                      await _bulkUpdatePrice(priceType, priceController.text);
                      Navigator.pop(context);
                    },
              child: const Text('Güncelle'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkStockDialog() {
    final stockController = TextEditingController();
    String stockType = 'set'; // 'set', 'increase', 'decrease'
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Toplu Stok Güncelle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: stockType,
                decoration: const InputDecoration(labelText: 'İşlem Tipi'),
                items: const [
                  DropdownMenuItem(value: 'set', child: Text('Belirli Stok')),
                  DropdownMenuItem(value: 'increase', child: Text('Artır')),
                  DropdownMenuItem(value: 'decrease', child: Text('Azalt')),
                ],
                onChanged: (value) => setState(() => stockType = value!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(
                  labelText: 'Miktar',
                  prefixIcon: Icon(Icons.inventory),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: stockController.text.isEmpty
                  ? null
                  : () async {
                      await _bulkUpdateStock(stockType, stockController.text);
                      Navigator.pop(context);
                    },
              child: const Text('Güncelle'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkStatusDialog() {
    bool? newStatus;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Toplu Durum Değiştir'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<bool>(
                title: const Text('Aktif'),
                value: true,
                groupValue: newStatus,
                onChanged: (value) => setState(() => newStatus = value),
              ),
              RadioListTile<bool>(
                title: const Text('Pasif'),
                value: false,
                groupValue: newStatus,
                onChanged: (value) => setState(() => newStatus = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: newStatus == null
                  ? null
                  : () async {
                      await _bulkUpdateStatus(newStatus!);
                      Navigator.pop(context);
                    },
              child: const Text('Güncelle'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Toplu Silme'),
        content: Text('${_selectedProductIds.length} ürün silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _bulkDelete();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _bulkUpdateCategory(String category) async {
    int successCount = 0;
    int failCount = 0;

    for (final productId in _selectedProductIds) {
      try {
        await _adminService.updateProductFields(productId, {'category': category});
        successCount++;
      } catch (e) {
        failCount++;
        debugPrint('Ürün kategori güncelleme hatası ($productId): $e');
      }
    }

    _loadProducts();
    _exitSelectionMode();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$successCount ürün güncellendi. ${failCount > 0 ? "$failCount hata." : ""}'),
          backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
        ),
      );
    }
  }

  Future<void> _bulkUpdatePrice(String type, String value) async {
    final numValue = double.tryParse(value);
    if (numValue == null) return;

    int successCount = 0;
    int failCount = 0;

    for (final productId in _selectedProductIds) {
      try {
        final product = _products.firstWhere((p) => p.id == productId);
        double newPrice;
        if (type == 'set') {
          newPrice = numValue;
        } else if (type == 'increase') {
          newPrice = product.price * (1 + numValue / 100);
        } else {
          newPrice = product.price * (1 - numValue / 100);
        }
        await _adminService.updateProductFields(productId, {'price': newPrice});
        successCount++;
      } catch (e) {
        failCount++;
        debugPrint('Ürün fiyat güncelleme hatası ($productId): $e');
      }
    }

    _loadProducts();
    _exitSelectionMode();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$successCount ürün güncellendi. ${failCount > 0 ? "$failCount hata." : ""}'),
          backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
        ),
      );
    }
  }

  Future<void> _bulkUpdateStock(String type, String value) async {
    final numValue = int.tryParse(value);
    if (numValue == null) return;

    int successCount = 0;
    int failCount = 0;

    for (final productId in _selectedProductIds) {
      try {
        if (type == 'set') {
          await _adminService.updateStock(productId, numValue);
        } else if (type == 'increase') {
          await _adminService.increaseStock(productId, numValue);
        } else {
          await _adminService.decreaseStock(productId, numValue);
        }
        successCount++;
      } catch (e) {
        failCount++;
        debugPrint('Ürün stok güncelleme hatası ($productId): $e');
      }
    }

    _loadProducts();
    _exitSelectionMode();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$successCount ürün güncellendi. ${failCount > 0 ? "$failCount hata." : ""}'),
          backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
        ),
      );
    }
  }

  Future<void> _bulkUpdateStatus(bool isActive) async {
    int successCount = 0;
    int failCount = 0;

    for (final productId in _selectedProductIds) {
      try {
        await _adminService.toggleProductStatus(productId, isActive);
        successCount++;
      } catch (e) {
        failCount++;
        debugPrint('Ürün durum güncelleme hatası ($productId): $e');
      }
    }

    _loadProducts();
    _exitSelectionMode();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$successCount ürün güncellendi. ${failCount > 0 ? "$failCount hata." : ""}'),
          backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
        ),
      );
    }
  }

  Future<void> _bulkDelete() async {
    int successCount = 0;
    int failCount = 0;

    for (final productId in _selectedProductIds) {
      try {
        await _adminService.deleteProduct(productId);
        successCount++;
      } catch (e) {
        failCount++;
        debugPrint('Ürün silme hatası ($productId): $e');
      }
    }

    _loadProducts();
    _exitSelectionMode();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$successCount ürün silindi. ${failCount > 0 ? "$failCount hata." : ""}'),
          backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
        ),
      );
    }
  }
}

class _ProductDialog extends StatefulWidget {
  final AdminProduct? product;
  final Future<void> Function(AdminProduct) onSave;

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
  final _descriptionController = TextEditingController();
  
  String? _uploadedImageUrl;
  final GlobalKey<ProfessionalImageUploaderState> _imageUploaderKey = GlobalKey();
  String? _selectedCategory;
  List<String> _allCategoryNames = [];
  final AdminService _adminService = AdminService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _priceController.text = widget.product!.price.toString();
      _stockController.text = widget.product!.stock.toString();
      _selectedCategory = widget.product!.category;
      _descriptionController.text = widget.product!.description;
      _uploadedImageUrl = widget.product!.imageUrl.isNotEmpty ? widget.product!.imageUrl : null;
    }
  }

  Future<void> _loadCategories() async {
    try {
      // Firestore'dan TÜM kategorileri çek (aktif ve pasif)
      final allCategories = await _adminService.getAllCategories().first;
      
      // Mevcut ürünlerden de kategorileri al
      final allProducts = await _adminService.getProductsFromServer();
      final productCategories = allProducts
          .map((p) => p.category)
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList();
      
      setState(() {
        // Tüm kategori isimlerini birleştir
        _allCategoryNames = [];
        
        // Firestore'dan gelen TÜM kategorileri ekle (aktif ve pasif)
        for (final cat in allCategories) {
          if (!_allCategoryNames.contains(cat.name)) {
            _allCategoryNames.add(cat.name);
          }
        }
        
        // Ürünlerden gelen kategorileri de ekle (Firestore'da olmayanlar için)
        for (final catName in productCategories) {
          if (!_allCategoryNames.contains(catName)) {
            _allCategoryNames.add(catName);
          }
        }
        
        // Alfabetik sırala
        _allCategoryNames.sort();
        
        // Seçili kategori listede yoksa null yap (silinen kategori olabilir)
        if (_selectedCategory != null && !_allCategoryNames.contains(_selectedCategory)) {
          _selectedCategory = null;
        }
        
        // Eğer seçili kategori yoksa ve kategoriler varsa ilkini seç
        if (_selectedCategory == null && _allCategoryNames.isNotEmpty) {
          _selectedCategory = _allCategoryNames.first;
        }
      });
    } catch (e) {
      debugPrint('Kategoriler yüklenirken hata: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive dialog genişliği ve yüksekliği
    final dialogWidth = ResponsiveHelper.responsiveDialogWidth(context);
    final dialogHeight = ResponsiveHelper.responsiveDialogHeight(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: dialogHeight,
          maxWidth: dialogWidth,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Başlık
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.product == null ? Icons.add_circle : Icons.edit,
                    color: Colors.purple[700],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.product == null ? 'Yeni Ürün' : 'Ürün Düzenle',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[800],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Kapat',
                  ),
                ],
              ),
            ),
            // İçerik
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profesyonel Resim Yükleme Widget'ı
                      ProfessionalImageUploader(
                        key: _imageUploaderKey,
                        label: 'Ürün Resmi',
                        initialImageUrl: _uploadedImageUrl,
                        productId: widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                        aspectRatio: 1.0, // Kare format
                        autoUpload: false, // Upload "Kaydet" sırasında yapılacak
                        onImageUploaded: (imageUrl) {
                          setState(() {
                            _uploadedImageUrl = imageUrl;
                          });
                        },
                        onError: (error) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Hata: $error'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Ürün Adı',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.shopping_bag),
                        ),
                        validator: (value) => value?.isEmpty == true ? 'Ürün adı gerekli' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              decoration: const InputDecoration(
                                labelText: 'Fiyat (₺)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.attach_money),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) => value?.isEmpty == true ? 'Fiyat gerekli' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _stockController,
                              decoration: const InputDecoration(
                                labelText: 'Stok Miktarı',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.inventory),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) => value?.isEmpty == true ? 'Stok gerekli' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _allCategoryNames.isEmpty
                        ? TextFormField(
                            initialValue: _selectedCategory ?? '',
                            decoration: const InputDecoration(
                              labelText: 'Kategori',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.category),
                              hintText: 'Kategori adı girin',
                              helperText: 'Kategoriler yükleniyor...',
                            ),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            },
                            validator: (value) => value?.isEmpty == true ? 'Kategori gerekli' : null,
                          )
                        : DropdownButtonFormField<String>(
                            value: _selectedCategory != null && _allCategoryNames.contains(_selectedCategory) 
                                ? _selectedCategory 
                                : null,
                            decoration: const InputDecoration(
                              labelText: 'Kategori',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.category),
                              helperText: 'Kategori seçiniz',
                            ),
                            isExpanded: true,
                            items: _allCategoryNames.map((categoryName) {
                              return DropdownMenuItem<String>(
                                value: categoryName,
                                child: Text(
                                  categoryName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            },
                            validator: (value) => value == null || value.isEmpty ? 'Kategori seçiniz' : null,
                            menuMaxHeight: 300,
                          ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Açıklama',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Alt butonlar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Kaydet'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveProduct() async {
    if (!_formKey.currentState!.validate() || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Fotoğraf yüklenmemişse önce yükle
      String finalImageUrl = _uploadedImageUrl ?? '';
      
      if (_imageUploaderKey.currentState != null) {
        final uploaderState = _imageUploaderKey.currentState!;
        
        // Eğer fotoğraf seçilmiş ama yüklenmemişse, önce yükle
        if (uploaderState.hasUnuploadedImage) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📤 Fotoğraf yükleniyor, lütfen bekleyin...'),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 2),
              ),
            );
          }
          
          try {
            final uploadedUrl = await uploaderState.ensureImageUploaded();
            if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
              finalImageUrl = uploadedUrl;
              setState(() {
                _uploadedImageUrl = uploadedUrl;
              });
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Fotoğraf yüklenirken hata: $e'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
            setState(() {
              _isSaving = false;
            });
            return; // Hata varsa kaydetme
          }
        } else if (uploaderState.uploadedImageUrl != null) {
          finalImageUrl = uploaderState.uploadedImageUrl!;
        }
      }
      
      // Fiyat parse işlemi - Türkçe format desteği (2.519,99 -> 2519.99)
      String priceText = _priceController.text.trim();
      // Binlik ayırıcı noktaları kaldır, virgülü noktaya çevir
      priceText = priceText.replaceAll('.', '').replaceAll(',', '.');
      final price = double.tryParse(priceText);
      if (price == null || price <= 0) {
        throw Exception('Geçerli bir fiyat giriniz');
      }

      // Stok parse işlemi
      final stock = int.tryParse(_stockController.text.trim());
      if (stock == null || stock < 0) {
        throw Exception('Geçerli bir stok miktarı giriniz');
      }

      // Kategori kontrolü
      if (_selectedCategory == null || _selectedCategory!.isEmpty) {
        throw Exception('Lütfen bir kategori seçiniz');
      }
      
      // Ürün oluştur ve kaydet
      final product = AdminProduct(
        id: widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        stock: stock,
        category: _selectedCategory!,
        imageUrl: finalImageUrl,
        isActive: widget.product?.isActive ?? true,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Ürünü kaydet (await ile)
      await widget.onSave(product);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Ürün başarıyla kaydedildi'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Ürün kaydetme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Ürün kaydedilirken hata: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
