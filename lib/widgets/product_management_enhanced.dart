import 'package:flutter/material.dart';
// Firebase Storage kaldırıldı - Base64 kullanılıyor
import '../model/admin_product.dart';
import '../services/admin_service.dart';
import 'professional_image_uploader.dart';
import 'optimized_image.dart';

class ProductManagementEnhanced extends StatefulWidget {
  const ProductManagementEnhanced({super.key});

  @override
  State<ProductManagementEnhanced> createState() => _ProductManagementEnhancedState();
}

class _ProductManagementEnhancedState extends State<ProductManagementEnhanced> {
  final AdminService _adminService = AdminService();
  List<AdminProduct> _selectedProducts = [];
  String _sortBy = 'name';
  bool _sortAscending = true;
  String _viewMode = 'grid'; // 'grid' or 'list'
  Map<String, bool> _columnVisibility = {
    'name': true,
    'price': true,
    'stock': true,
    'category': true,
    'status': true,
    'actions': true,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Gelişmiş Kontroller
        _buildEnhancedControls(),
        
        // Ürün Listesi
        SizedBox(
          height: 600,
          child: StreamBuilder<List<AdminProduct>>(
            stream: _adminService.getProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(child: Text('Hata: ${snapshot.error}'));
              }
              
              final products = snapshot.data ?? [];
              final sortedProducts = _sortProducts(products);
              
              if (_viewMode == 'grid') {
                return _buildGridView(sortedProducts);
              } else {
                return _buildListView(sortedProducts);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Üst satır - Arama ve filtreler
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Ürün Ara',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                DropdownButton<String>(
                  value: _sortBy,
                  items: const [
                    DropdownMenuItem(value: 'name', child: Text('İsim')),
                    DropdownMenuItem(value: 'price', child: Text('Fiyat')),
                    DropdownMenuItem(value: 'stock', child: Text('Stok')),
                    DropdownMenuItem(value: 'category', child: Text('Kategori')),
                    DropdownMenuItem(value: 'createdAt', child: Text('Tarih')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                    });
                  },
                ),
                SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _sortAscending = !_sortAscending;
                    });
                  },
                  icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Alt satır - Görünüm ve seçenekler
            Row(
              children: [
                // Ürün ekle butonu
                ElevatedButton.icon(
                  onPressed: () => _showAddProductDialog(context),
                  icon: Icon(Icons.add),
                  label: Text('Yeni Ürün'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),

                SizedBox(width: 16),

                // Debug butonu
                ElevatedButton.icon(
                  onPressed: () => _debugProductImageUrls(),
                  icon: Icon(Icons.bug_report),
                  label: Text('Debug Resimler'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                
                SizedBox(width: 16),
                
                // Görünüm modu
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'grid', icon: Icon(Icons.grid_view), label: Text('Grid')),
                    ButtonSegment(value: 'list', icon: Icon(Icons.list), label: Text('Liste')),
                  ],
                  selected: {_viewMode},
                  onSelectionChanged: (Set<String> selection) {
                    setState(() {
                      _viewMode = selection.first;
                    });
                  },
                ),
                
                SizedBox(width: 16),
                
                // Sütun görünürlüğü
                PopupMenuButton<String>(
                  icon: Icon(Icons.view_column),
                  tooltip: 'Sütunları Gizle/Göster',
                  itemBuilder: (context) => _columnVisibility.entries.map((entry) {
                    return PopupMenuItem<String>(
                      value: entry.key,
                      child: CheckboxListTile(
                        title: Text(_getColumnName(entry.key)),
                        value: entry.value,
                        onChanged: (value) {
                          setState(() {
                            _columnVisibility[entry.key] = value!;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
                
                Spacer(),
                
                // Seçili ürün sayısı
                if (_selectedProducts.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_selectedProducts.length} ürün seçildi',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(List<AdminProduct> products) {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getGridColumns(),
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildListView(List<AdminProduct> products) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductListItem(product);
      },
    );
  }

  Widget _buildProductCard(AdminProduct product) {
    final isSelected = _selectedProducts.contains(product);
    
    return Card(
      elevation: isSelected ? 8 : 2,
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedProducts.remove(product);
            } else {
              _selectedProducts.add(product);
            }
          });
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ürün resmi
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: product.imageUrl.isNotEmpty
                      ? OptimizedImage(
                          imageUrl: product.imageUrl,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                          errorWidget: Icon(Icons.image, size: 48, color: Colors.grey[400]),
                        )
                      : Icon(Icons.image, size: 48, color: Colors.grey[400]),
                ),
              ),
              
              // Ürün bilgileri
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        '₺${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.inventory, size: 10, color: Colors.grey[600]),
                          SizedBox(width: 2),
                          Text(
                            '${product.stock}',
                            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      Spacer(),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: product.isActive ? Colors.green[100] : Colors.red[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              product.isActive ? 'Aktif' : 'Pasif',
                              style: TextStyle(
                                fontSize: 10,
                                color: product.isActive ? Colors.green[800] : Colors.red[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Spacer(),
                          if (isSelected)
                            Icon(Icons.check_circle, color: Colors.blue, size: 16),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductListItem(AdminProduct product) {
    final isSelected = _selectedProducts.contains(product);
    
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _selectedProducts.add(product);
            } else {
              _selectedProducts.remove(product);
            }
          });
        },
        title: Text(product.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('₺${product.price.toStringAsFixed(2)} - Stok: ${product.stock}'),
            Text('Kategori: ${product.category}'),
          ],
        ),
                        secondary: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: product.isActive ? Colors.green[100] : Colors.red[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                product.isActive ? 'Aktif' : 'Pasif',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: product.isActive ? Colors.green[800] : Colors.red[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showEditProductDialog(context, product);
                                } else if (value == 'delete') {
                                  _showDeleteDialog(context, product);
                                } else if (value == 'duplicate') {
                                  _duplicateProduct(product);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                                PopupMenuItem(value: 'delete', child: Text('Sil')),
                                PopupMenuItem(value: 'duplicate', child: Text('Kopyala')),
                              ],
                            ),
                          ],
                        ),
      ),
    );
  }

  List<AdminProduct> _sortProducts(List<AdminProduct> products) {
    products.sort((a, b) {
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
      
      return _sortAscending ? comparison : -comparison;
    });
    
    return products;
  }

  int _getGridColumns() {
    // Responsive grid columns
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }

  String _getColumnName(String key) {
    switch (key) {
      case 'name': return 'İsim';
      case 'price': return 'Fiyat';
      case 'stock': return 'Stok';
      case 'category': return 'Kategori';
      case 'status': return 'Durum';
      case 'actions': return 'İşlemler';
      default: return key;
    }
  }

  void _showAddProductDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ProductDialog(
        onSave: _addProduct,
      ),
    );
  }

  void _showEditProductDialog(BuildContext context, AdminProduct product) {
    showDialog(
      context: context,
      builder: (context) => _ProductDialog(
        product: product,
        onSave: _updateProduct,
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, AdminProduct product) {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ürün başarıyla eklendi'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateProduct(AdminProduct product) async {
    try {
      await _adminService.updateProduct(product.id, product);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ürün başarıyla güncellendi'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteProduct(AdminProduct product) async {
    try {
      await _adminService.deleteProduct(product.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ürün başarıyla silindi'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _duplicateProduct(AdminProduct product) async {
    final duplicatedProduct = AdminProduct(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '${product.name} (Kopya)',
      description: product.description,
      price: product.price,
      stock: product.stock,
      category: product.category,
      imageUrl: product.imageUrl,
      isActive: product.isActive,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _addProduct(duplicatedProduct);
  }

  Future<void> _debugProductImageUrls() async {
    await _adminService.debugProductImageUrls();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Debug bilgileri konsola yazıldı')),
      );
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
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _categoryController = TextEditingController();
  String? _uploadedImageUrl;
  final GlobalKey<ProfessionalImageUploaderState> _imageUploaderKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description;
      _priceController.text = widget.product!.price.toString();
      _stockController.text = widget.product!.stock.toString();
      _categoryController.text = widget.product!.category;
      _uploadedImageUrl = widget.product!.imageUrl.isNotEmpty ? widget.product!.imageUrl : null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    super.dispose();
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Ürün Adı'),
                validator: (value) => value?.isEmpty == true ? 'Ürün adı gerekli' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Açıklama'),
                maxLines: 3,
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

  // Bu metodlar artık kullanılmıyor - ProfessionalImageUploader widget'ı kullanılıyor

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      debugPrint('=== ÜRÜN KAYDETME BAŞLADI ===');
      
      // Fotoğraf yüklenmemişse önce yükle
      String finalImageUrl = _uploadedImageUrl ?? '';
      debugPrint('Başlangıç imageUrl: ${finalImageUrl.isNotEmpty ? (finalImageUrl.length > 50 ? finalImageUrl.substring(0, 50) + '...' : finalImageUrl) : 'BOŞ'}');
      
      if (_imageUploaderKey.currentState != null) {
        final uploaderState = _imageUploaderKey.currentState!;
        debugPrint('Uploader state kontrolü:');
        debugPrint('  - hasUnuploadedImage: ${uploaderState.hasUnuploadedImage}');
        debugPrint('  - uploadedImageUrl: ${uploaderState.uploadedImageUrl != null ? (uploaderState.uploadedImageUrl!.length > 50 ? uploaderState.uploadedImageUrl!.substring(0, 50) + '...' : uploaderState.uploadedImageUrl) : 'NULL'}');
        
        // Eğer fotoğraf seçilmiş ama yüklenmemişse, önce yükle
        if (uploaderState.hasUnuploadedImage) {
          debugPrint('📤 Yüklenmemiş resim var, yükleme başlatılıyor...');
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
            debugPrint('ensureImageUploaded sonucu: ${uploadedUrl != null ? (uploadedUrl.length > 50 ? uploadedUrl.substring(0, 50) + '...' : uploadedUrl) : 'NULL'}');
            
            if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
              finalImageUrl = uploadedUrl.trim();
              setState(() {
                _uploadedImageUrl = finalImageUrl;
              });
              debugPrint('✅ Resim URL güncellendi: ${finalImageUrl.length} karakter');
            } else {
              debugPrint('⚠️ Yüklenen URL boş veya null');
            }
          } catch (e, stackTrace) {
            debugPrint('❌ Fotoğraf yükleme hatası: $e');
            debugPrint('Stack trace: $stackTrace');
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
          finalImageUrl = uploaderState.uploadedImageUrl!.trim();
          debugPrint('✅ Zaten yüklenmiş resim kullanılıyor: ${finalImageUrl.length} karakter');
        } else {
          debugPrint('⚠️ Resim yüklenmemiş ve yüklenecek resim de yok');
        }
      }
      
      debugPrint('Final imageUrl: ${finalImageUrl.isNotEmpty ? (finalImageUrl.length > 50 ? finalImageUrl.substring(0, 50) + '...' : finalImageUrl) : 'BOŞ'}');
      debugPrint('Final imageUrl format: ${finalImageUrl.isNotEmpty ? (finalImageUrl.startsWith('data:') ? 'Base64' : finalImageUrl.startsWith('http') ? 'HTTP URL' : 'Diğer') : 'BOŞ'}');
      
      final product = AdminProduct(
        id: widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        stock: int.parse(_stockController.text),
        category: _categoryController.text,
        imageUrl: finalImageUrl.trim(), // Trim ekle
        isActive: widget.product?.isActive ?? true,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      debugPrint('Ürün oluşturuldu, Firestore\'a kaydediliyor...');
      widget.onSave(product);
      
      if (mounted) {
        Navigator.pop(context);
      }
      
      debugPrint('=== ÜRÜN KAYDETME TAMAMLANDI ===');
    }
  }
}
