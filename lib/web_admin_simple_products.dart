import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
// Firebase Storage kaldırıldı - Base64 kullanılıyor
import 'dart:html' as html;
import 'model/admin_product.dart';
import 'services/admin_service.dart';
import 'services/audit_log_service.dart';
import 'services/permission_service.dart';
import 'widgets/professional_image_uploader.dart';

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
  
  // Pagination
  static const int _itemsPerPage = 20;
  int _currentPage = 0;
  bool _hasMore = true;

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
            // Arama ve Filtre Bölümü - Sabit yükseklik
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.grey[100],
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
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _displayedProducts.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Load more indicator
                          if (index == _displayedProducts.length) {
                            return Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: ElevatedButton(
                                  onPressed: _loadMoreProducts,
                                  child: Text('Daha Fazla Yükle (${_filteredProducts.length - _displayedProducts.length} kaldı)'),
                                ),
                              ),
                            );
                          }
                          
                          final product = _displayedProducts[index];
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
          default:
            comparison = a.name.compareTo(b.name);
        }
        return _sortOrder == 'asc' ? comparison : -comparison;
      });
      
      // Pagination reset
      _currentPage = 0;
      _updateDisplayedProducts();
    });
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
      
      // Audit log (hata olsa bile devam et)
      final userId = PermissionService.getCurrentUserId() ?? 'unknown';
      AuditLogService.logAction(
        userId: userId,
        action: 'delete',
        resource: 'product',
        details: {
          'productId': product.id,
          'productName': product.name,
        },
      ).catchError((e) {
        if (kDebugMode) {
          debugPrint('Audit log hatası: $e');
        }
      });
      
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
  
  String? _uploadedImageUrl;
  final GlobalKey<ProfessionalImageUploaderState> _imageUploaderKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _priceController.text = widget.product!.price.toString();
      _stockController.text = widget.product!.stock.toString();
      _categoryController.text = widget.product!.category;
      _descriptionController.text = widget.product!.description;
      _uploadedImageUrl = widget.product!.imageUrl.isNotEmpty ? widget.product!.imageUrl : null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Responsive dialog genişliği
    final dialogWidth = screenWidth > 800 
        ? 600.0 
        : screenWidth > 600 
            ? screenWidth * 0.85 
            : screenWidth * 0.95;
    
    // Responsive dialog yüksekliği
    final dialogHeight = screenHeight > 800 
        ? 700.0 
        : screenHeight * 0.85;
    
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
                        autoUpload: true, // Otomatik yükleme - resim seçildiğinde direkt yüklenir
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
                      TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        validator: (value) => value?.isEmpty == true ? 'Kategori gerekli' : null,
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
                    onPressed: _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Kaydet'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Firebase Storage kaldırıldı - artık ProfessionalImageUploader Base64 kullanıyor
  // Bu metod artık kullanılmıyor
  @Deprecated('Firebase Storage kaldırıldı. ProfessionalImageUploader widget\'ını kullanın.')
  Future<String> _uploadWebImage(html.File file, String productId) async {
    throw UnimplementedError('Firebase Storage kaldırıldı. ProfessionalImageUploader widget\'ını kullanın.');
    /* Eski kod - artık kullanılmıyor
    try {
      debugPrint('📤 Firebase Storage\'a yükleniyor...');
      debugPrint('Dosya adı: ${file.name}, Boyut: ${file.size} bytes, Tip: ${file.type}');
      
      // Firebase Storage instance'ı kontrol et
      final storage = FirebaseStorage.instance;
      */
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
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
            return; // Hata varsa kaydetme
          }
        } else if (uploaderState.uploadedImageUrl != null) {
          finalImageUrl = uploaderState.uploadedImageUrl!;
        }
      }
      
      // Ürün oluştur ve kaydet
      final product = AdminProduct(
        id: widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        stock: int.parse(_stockController.text),
        category: _categoryController.text,
        imageUrl: finalImageUrl,
        isActive: widget.product?.isActive ?? true,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      widget.onSave(product);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
}
