import 'package:flutter/material.dart';
import 'services/admin_service.dart';
import 'model/admin_product.dart';

class WebAdminPriceManagement extends StatefulWidget {
  const WebAdminPriceManagement({super.key});

  @override
  State<WebAdminPriceManagement> createState() => _WebAdminPriceManagementState();
}

class _WebAdminPriceManagementState extends State<WebAdminPriceManagement> {
  final AdminService _adminService = AdminService();
  List<AdminProduct> _products = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _sortAscending = true;
  double _bulkPercentage = 0.0;
  double _bulkAmount = 0.0;
  String _bulkOperation = 'increase';
  List<String> _selectedCategories = [];
  List<String> _availableCategories = [];
  Set<String> _selectedProductIds = {};
  bool _isSelectionMode = false;
  String _activeTab = 'list'; // 'list', 'settings', 'analytics'
  
  // Fiyat Ayarları State
  bool _autoPriceIncrease = false;
  double _minProfitMargin = 20.0;
  double _maxDiscountRate = 50.0;
  bool _lowPriceWarning = true;
  bool _autoPriceUpdate = false;
  bool _discountLimit = true;
  Map<String, Map<String, dynamic>> _categorySettings = {}; // category -> {increaseRate, minPrice}
  late TextEditingController _minProfitMarginController;
  late TextEditingController _maxDiscountRateController;

  @override
  void initState() {
    super.initState();
    _minProfitMarginController = TextEditingController(text: _minProfitMargin.toStringAsFixed(1));
    _maxDiscountRateController = TextEditingController(text: _maxDiscountRate.toStringAsFixed(1));
    _loadProducts();
    _loadCategories();
  }
  
  @override
  void dispose() {
    _minProfitMarginController.dispose();
    _maxDiscountRateController.dispose();
    super.dispose();
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
          _isLoading = false;
        });
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

  Future<void> _loadCategories() async {
    try {
      final categories = _products.map((p) => p.category).toSet().toList();
      setState(() {
        _availableCategories = categories;
      });
    } catch (e) {
      // Kategoriler yüklenirken hata
    }
  }

  List<AdminProduct> get _filteredProducts {
    var filtered = _products.where((product) {
      final matchesSearch = product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           product.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategories.isEmpty || _selectedCategories.contains(product.category);
      return matchesSearch && matchesCategory;
    }).toList();

    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'price':
          comparison = a.price.compareTo(b.price);
          break;
        case 'category':
          comparison = a.category.compareTo(b.category);
          break;
        case 'stock':
          comparison = a.stock.compareTo(b.stock);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  Future<void> _updateProductPrice(AdminProduct product, double newPrice) async {
    try {
      await _adminService.updateProductFields(product.id, {'price': newPrice});
      setState(() {
        final index = _products.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          _products[index] = product.copyWith(price: newPrice);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fiyat başarıyla güncellendi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fiyat güncellenirken hata: $e')),
        );
      }
    }
  }

  Future<void> _bulkUpdatePrices() async {
    if (_bulkPercentage == 0.0 && _bulkAmount == 0.0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen yüzde veya miktar giriniz')),
        );
      }
      return;
    }

    // Seçili ürünler varsa sadece onları güncelle, yoksa tüm filtrelenmiş ürünleri güncelle
    final productsToUpdate = _selectedProductIds.isNotEmpty 
        ? _filteredProducts.where((p) => _selectedProductIds.contains(p.id)).toList()
        : _filteredProducts;

    if (productsToUpdate.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Güncellenecek ürün bulunamadı')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      int updatedCount = 0;
      for (var product in productsToUpdate) {
        double newPrice = product.price;
        
        if (_bulkPercentage > 0) {
          if (_bulkOperation == 'increase') {
            newPrice = product.price * (1 + _bulkPercentage / 100);
          } else {
            newPrice = product.price * (1 - _bulkPercentage / 100);
          }
        } else if (_bulkAmount > 0) {
          if (_bulkOperation == 'increase') {
            newPrice = product.price + _bulkAmount;
          } else {
            newPrice = product.price - _bulkAmount;
          }
        }

        if (newPrice > 0) {
          await _adminService.updateProductFields(product.id, {'price': newPrice});
          final index = _products.indexWhere((p) => p.id == product.id);
          if (index != -1) {
            _products[index] = product.copyWith(price: newPrice);
          }
          updatedCount++;
        }
      }

      setState(() {
        _isLoading = false;
        _selectedProductIds.clear();
        _isSelectionMode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$updatedCount ürünün fiyatı güncellendi')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Toplu güncelleme hatası: $e')),
        );
      }
    }
  }

  void _showBulkUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
        title: const Text('Toplu Fiyat Güncelleme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Artır'),
                    value: 'increase',
                    groupValue: _bulkOperation,
                    onChanged: (value) {
                      setDialogState(() {
                        _bulkOperation = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Azalt'),
                    value: 'decrease',
                    groupValue: _bulkOperation,
                    onChanged: (value) {
                      setDialogState(() {
                        _bulkOperation = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Yüzde (%)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setDialogState(() {
                  _bulkPercentage = double.tryParse(value) ?? 0.0;
                  _bulkAmount = 0.0;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Sabit Miktar (₺)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setDialogState(() {
                  _bulkAmount = double.tryParse(value) ?? 0.0;
                  _bulkPercentage = 0.0;
                });
              },
            ),
            const SizedBox(height: 16),
            Text(
              _selectedProductIds.isNotEmpty 
                  ? 'Seçili ${_selectedProductIds.length} ürün güncellenecek'
                  : 'Filtrelenmiş ${_filteredProducts.length} ürün güncellenecek',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
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
              Navigator.pop(context);
              _bulkUpdatePrices();
            },
            child: const Text('Güncelle'),
          ),
        ],
      ),
        ),
    );
  }

  void _showPriceEditDialog(AdminProduct product) {
    final priceController = TextEditingController(text: product.price.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${product.name} - Fiyat Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Yeni Fiyat (₺)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Text(
              'Mevcut fiyat: ₺${product.price.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
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
              final newPrice = double.tryParse(priceController.text);
              if (newPrice != null && newPrice > 0) {
                Navigator.pop(context);
                _updateProductPrice(product, newPrice);
              }
            },
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fiyat Yönetimi'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton('list', Icons.list, 'Ürün Listesi'),
                ),
                Expanded(
                  child: _buildTabButton('settings', Icons.settings, 'Fiyat Ayarları'),
                ),
                Expanded(
                  child: _buildTabButton('analytics', Icons.analytics, 'Fiyat Analizi'),
                ),
              ],
            ),
          ),
          
          // İçerik
          Expanded(
            child: _activeTab == 'list' ? _buildProductList() : 
                   _activeTab == 'settings' ? _buildPriceSettings() : 
                   _buildPriceAnalytics(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tab, IconData icon, String label) {
    final isActive = _activeTab == tab;
    return InkWell(
      onTap: () {
        setState(() {
          _activeTab = tab;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue[600] : Colors.transparent,
          border: isActive ? Border(bottom: BorderSide(color: Colors.blue[600]!, width: 3)) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList() {
    return Column(
      children: [
        // Filtreler ve Arama
        Flexible(
          flex: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
              // Arama
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Ürün Ara',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              
              // Filtreler
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 600) {
                    return Row(
                      children: [
                        // Kategori Filtresi
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Kategori',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem(value: '', child: Text('Tüm Kategoriler')),
                              ..._availableCategories.map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              )),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedCategories = value == null || value.isEmpty 
                                    ? [] 
                                    : [value];
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Sıralama
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Sırala',
                              border: OutlineInputBorder(),
                            ),
                            value: _sortBy,
                            items: const [
                              DropdownMenuItem(value: 'name', child: Text('İsim')),
                              DropdownMenuItem(value: 'price', child: Text('Fiyat')),
                              DropdownMenuItem(value: 'category', child: Text('Kategori')),
                              DropdownMenuItem(value: 'stock', child: Text('Stok')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _sortBy = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Sıralama Yönü
                        IconButton(
                          icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                          onPressed: () {
                            setState(() {
                              _sortAscending = !_sortAscending;
                            });
                          },
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Kategori',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(value: '', child: Text('Tüm Kategoriler')),
                            ..._availableCategories.map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedCategories = value == null || value.isEmpty 
                                  ? [] 
                                  : [value];
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Sırala',
                                  border: OutlineInputBorder(),
                                ),
                                value: _sortBy,
                                items: const [
                                  DropdownMenuItem(value: 'name', child: Text('İsim')),
                                  DropdownMenuItem(value: 'price', child: Text('Fiyat')),
                                  DropdownMenuItem(value: 'category', child: Text('Kategori')),
                                  DropdownMenuItem(value: 'stock', child: Text('Stok')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _sortBy = value!;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                              onPressed: () {
                                setState(() {
                                  _sortAscending = !_sortAscending;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              
              // Seçim ve Toplu İşlem Butonları
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Seçim Modu Butonu
                  ElevatedButton.icon(
                    onPressed: _filteredProducts.isNotEmpty ? () {
                      setState(() {
                        _isSelectionMode = !_isSelectionMode;
                        if (!_isSelectionMode) {
                          _selectedProductIds.clear();
                        }
                      });
                    } : null,
                    icon: Icon(_isSelectionMode ? Icons.check_box : Icons.check_box_outline_blank),
                    label: Text(_isSelectionMode ? 'Seçimi İptal' : 'Ürün Seç'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSelectionMode ? Colors.red[600] : Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                  
                  // Tümünü Seç/Seçimi Kaldır
                  if (_isSelectionMode)
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          if (_selectedProductIds.length == _filteredProducts.length) {
                            _selectedProductIds.clear();
                          } else {
                            _selectedProductIds = _filteredProducts.map((p) => p.id).toSet();
                          }
                        });
                      },
                      icon: Icon(_selectedProductIds.length == _filteredProducts.length 
                          ? Icons.check_box_outline_blank 
                          : Icons.check_box),
                      label: Text(_selectedProductIds.length == _filteredProducts.length 
                          ? 'Seçimi Kaldır' 
                          : 'Tümünü Seç'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  
                  // Toplu Fiyat Güncelleme Butonu
                  ElevatedButton.icon(
                    onPressed: _filteredProducts.isNotEmpty ? _showBulkUpdateDialog : null,
                    icon: const Icon(Icons.trending_up),
                    label: const Text('Toplu Fiyat Güncelle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                  
                  // Ürün Sayısı ve Seçim Bilgisi
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      _isSelectionMode 
                          ? '${_selectedProductIds.length}/${_filteredProducts.length} seçili'
                          : '${_filteredProducts.length} ürün bulundu',
                      style: TextStyle(
                        fontSize: 14, 
                        color: _isSelectionMode ? Colors.blue[600] : Colors.grey,
                        fontWeight: _isSelectionMode ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
      // Ürün Listesi
      Expanded(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _filteredProducts.isEmpty
                ? const Center(
                    child: Text(
                      'Ürün bulunamadı',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        final isSelected = _selectedProductIds.contains(product.id);
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          color: isSelected ? Colors.blue[50] : null,
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
                                    backgroundColor: Colors.blue[100],
                                    child: Text(
                                      '₺',
                                      style: TextStyle(
                                        color: Colors.blue[600],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                            title: Text(
                              product.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.blue[800] : null,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Kategori: ${product.category}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text('Stok: ${product.stock} adet'),
                              ],
                            ),
                            trailing: _isSelectionMode 
                                ? null
                                : ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 150,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '₺${product.price.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, size: 18),
                                              onPressed: () => _showPriceEditDialog(product),
                                              tooltip: 'Fiyat Düzenle',
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.trending_up, size: 18),
                                              onPressed: () => _showPriceEditDialog(product),
                                              tooltip: 'Fiyat Artır',
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
      ),
      ],
    );
  }

  Widget _buildPriceSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Genel Fiyat Ayarları
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      const Text(
                        'Genel Fiyat Ayarları',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Otomatik Fiyat Artışı
                  SwitchListTile(
                    title: const Text('Otomatik Fiyat Artışı'),
                    subtitle: const Text('Enflasyon oranında otomatik fiyat güncelleme'),
                    value: _autoPriceIncrease,
                    onChanged: (value) {
                      setState(() {
                        _autoPriceIncrease = value;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(value 
                            ? 'Otomatik fiyat artışı etkinleştirildi' 
                            : 'Otomatik fiyat artışı devre dışı bırakıldı'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  
                  // Minimum Kar Marjı
                  ListTile(
                    title: const Text('Minimum Kar Marjı (%)'),
                    subtitle: const Text('Ürünler için minimum kar marjı belirle'),
                    trailing: SizedBox(
                      width: 100,
                      child: TextField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          suffixText: '%',
                        ),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        controller: _minProfitMarginController,
                        onChanged: (value) {
                          final newValue = double.tryParse(value);
                          if (newValue != null && newValue >= 0 && newValue <= 100) {
                            setState(() {
                              _minProfitMargin = newValue;
                            });
                          } else {
                            // Reset to current value if invalid
                            _minProfitMarginController.value = TextEditingValue(
                              text: _minProfitMargin.toStringAsFixed(1),
                              selection: TextSelection.collapsed(offset: _minProfitMargin.toStringAsFixed(1).length),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                  
                  // Maksimum İndirim Oranı
                  ListTile(
                    title: const Text('Maksimum İndirim Oranı (%)'),
                    subtitle: const Text('Ürünlerde maksimum indirim sınırı'),
                    trailing: SizedBox(
                      width: 100,
                      child: TextField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          suffixText: '%',
                        ),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        controller: _maxDiscountRateController,
                        onChanged: (value) {
                          final newValue = double.tryParse(value);
                          if (newValue != null && newValue >= 0 && newValue <= 100) {
                            setState(() {
                              _maxDiscountRate = newValue;
                            });
                          } else {
                            // Reset to current value if invalid
                            _maxDiscountRateController.value = TextEditingValue(
                              text: _maxDiscountRate.toStringAsFixed(1),
                              selection: TextSelection.collapsed(offset: _maxDiscountRate.toStringAsFixed(1).length),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Kategori Bazlı Fiyat Ayarları
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.category, color: Colors.green[600]),
                      const SizedBox(width: 8),
                      const Text(
                        'Kategori Bazlı Ayarlar',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  ..._availableCategories.map((category) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(category),
                      subtitle: Text('Bu kategorideki ürünler için özel fiyat ayarları'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showCategoryPriceDialog(category),
                            tooltip: 'Kategori Fiyat Ayarları',
                          ),
                          IconButton(
                            icon: const Icon(Icons.trending_up),
                            onPressed: () => _showCategoryBulkUpdateDialog(category),
                            tooltip: 'Toplu Fiyat Güncelle',
                          ),
                        ],
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Fiyat Kuralları
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.rule, color: Colors.orange[600]),
                      const SizedBox(width: 8),
                      const Text(
                        'Fiyat Kuralları',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Fiyat Kuralları Listesi
                  ..._buildPriceRules(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceAnalytics() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fiyat İstatistikleri
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics, color: Colors.purple[600]),
                      const SizedBox(width: 8),
                      const Text(
                        'Fiyat İstatistikleri',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  FutureBuilder<Map<String, dynamic>>(
                    future: _adminService.getPriceStatistics(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (snapshot.hasError) {
                        return Text('Hata: ${snapshot.error}');
                      }
                      
                      final stats = snapshot.data ?? {};
                      
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Toplam Ürün',
                                  '${stats['totalProducts'] ?? 0}',
                                  Icons.inventory,
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildStatCard(
                                  'Ortalama Fiyat',
                                  '₺${(stats['averagePrice'] ?? 0).toStringAsFixed(2)}',
                                  Icons.attach_money,
                                  Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'En Düşük Fiyat',
                                  '₺${(stats['minPrice'] ?? 0).toStringAsFixed(2)}',
                                  Icons.trending_down,
                                  Colors.red,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildStatCard(
                                  'En Yüksek Fiyat',
                                  '₺${(stats['maxPrice'] ?? 0).toStringAsFixed(2)}',
                                  Icons.trending_up,
                                  Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Kategori Bazlı Analiz
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.pie_chart, color: Colors.indigo[600]),
                      const SizedBox(width: 8),
                      const Text(
                        'Kategori Bazlı Analiz',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  ..._buildCategoryAnalytics(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPriceRules() {
    return [
      ListTile(
        leading: const Icon(Icons.warning, color: Colors.orange),
        title: const Text('Düşük Fiyat Uyarısı'),
        subtitle: const Text('Belirlenen fiyatın altındaki ürünler için uyarı'),
        trailing: Switch(
          value: _lowPriceWarning,
          onChanged: (value) {
            setState(() {
              _lowPriceWarning = value;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(value 
                  ? 'Düşük fiyat uyarısı etkinleştirildi' 
                  : 'Düşük fiyat uyarısı devre dışı bırakıldı'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
      ListTile(
        leading: const Icon(Icons.trending_up, color: Colors.green),
        title: const Text('Otomatik Fiyat Artışı'),
        subtitle: const Text('Belirli aralıklarla otomatik fiyat güncelleme'),
        trailing: Switch(
          value: _autoPriceUpdate,
          onChanged: (value) {
            setState(() {
              _autoPriceUpdate = value;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(value 
                  ? 'Otomatik fiyat güncelleme etkinleştirildi' 
                  : 'Otomatik fiyat güncelleme devre dışı bırakıldı'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
      ListTile(
        leading: const Icon(Icons.discount, color: Colors.blue),
        title: const Text('İndirim Sınırı'),
        subtitle: const Text('Maksimum indirim oranı sınırı'),
        trailing: Switch(
          value: _discountLimit,
          onChanged: (value) {
            setState(() {
              _discountLimit = value;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(value 
                  ? 'İndirim sınırı etkinleştirildi' 
                  : 'İndirim sınırı devre dışı bırakıldı'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    ];
  }

  List<Widget> _buildCategoryAnalytics() {
    final categoryStats = <String, Map<String, dynamic>>{};
    
    for (final product in _products) {
      if (!categoryStats.containsKey(product.category)) {
        categoryStats[product.category] = {
          'count': 0,
          'totalPrice': 0.0,
          'minPrice': double.infinity,
          'maxPrice': 0.0,
        };
      }
      
      final stats = categoryStats[product.category]!;
      stats['count'] = (stats['count'] as int) + 1;
      stats['totalPrice'] = (stats['totalPrice'] as double) + product.price;
      stats['minPrice'] = (stats['minPrice'] as double) < product.price ? stats['minPrice'] : product.price;
      stats['maxPrice'] = (stats['maxPrice'] as double) > product.price ? stats['maxPrice'] : product.price;
    }
    
    return categoryStats.entries.map((entry) {
      final category = entry.key;
      final stats = entry.value;
      final avgPrice = (stats['totalPrice'] as double) / (stats['count'] as int);
      
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text(category),
          subtitle: Text('${stats['count']} ürün • Ortalama: ₺${avgPrice.toStringAsFixed(2)}'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₺${(stats['minPrice'] as double).toStringAsFixed(2)} - ₺${(stats['maxPrice'] as double).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _showCategoryPriceDialog(String category) {
    final settings = _categorySettings[category] ?? {'increaseRate': 0.0, 'minPrice': 0.0};
    final increaseRateController = TextEditingController(
      text: (settings['increaseRate'] as double?)?.toStringAsFixed(1) ?? '0.0'
    );
    final minPriceController = TextEditingController(
      text: (settings['minPrice'] as double?)?.toStringAsFixed(2) ?? '0.0'
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$category - Fiyat Ayarları'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: increaseRateController,
              decoration: const InputDecoration(
                labelText: 'Kategori Fiyat Artış Oranı (%)',
                border: OutlineInputBorder(),
                helperText: 'Bu kategori için varsayılan artış oranı',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: minPriceController,
              decoration: const InputDecoration(
                labelText: 'Minimum Fiyat (₺)',
                border: OutlineInputBorder(),
                helperText: 'Bu kategorideki ürünler için minimum fiyat',
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
            onPressed: () {
              final increaseRate = double.tryParse(increaseRateController.text) ?? 0.0;
              final minPrice = double.tryParse(minPriceController.text) ?? 0.0;
              
              setState(() {
                _categorySettings[category] = {
                  'increaseRate': increaseRate,
                  'minPrice': minPrice,
                };
              });
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$category kategorisi için fiyat ayarları kaydedildi'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showCategoryBulkUpdateDialog(String category) {
    final categoryProducts = _products.where((p) => p.category == category).toList();
    final percentageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('$category - Toplu Fiyat Güncelleme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: percentageController,
                decoration: const InputDecoration(
                  labelText: 'Fiyat Artış Oranı (%)',
                  border: OutlineInputBorder(),
                  helperText: 'Negatif değer indirim anlamına gelir',
                ),
                keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
              ),
              const SizedBox(height: 16),
              Text(
                'Bu kategorideki ${categoryProducts.length} ürün güncellenecek',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                final percentage = double.tryParse(percentageController.text);
                if (percentage == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen geçerli bir yüzde giriniz')),
                  );
                  return;
                }
                
                Navigator.pop(context);
                _updateCategoryPrices(category, percentage);
              },
              child: const Text('Güncelle'),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _updateCategoryPrices(String category, double percentage) async {
    final categoryProducts = _products.where((p) => p.category == category).toList();
    
    if (categoryProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu kategoride ürün bulunamadı')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      int updatedCount = 0;
      for (var product in categoryProducts) {
        final newPrice = product.price * (1 + percentage / 100);
        
        if (newPrice > 0) {
          await _adminService.updateProductFields(product.id, {'price': newPrice});
          final index = _products.indexWhere((p) => p.id == product.id);
          if (index != -1) {
            _products[index] = product.copyWith(price: newPrice);
          }
          updatedCount++;
        }
      }
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$category kategorisindeki $updatedCount ürünün fiyatı güncellendi'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kategori fiyat güncelleme hatası: $e')),
        );
      }
    }
  }
}
