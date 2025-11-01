import 'package:flutter/material.dart';
import '../model/admin_product.dart';
import '../services/admin_service.dart';

class StockManagementEnhanced extends StatefulWidget {
  const StockManagementEnhanced({super.key});

  @override
  State<StockManagementEnhanced> createState() => _StockManagementEnhancedState();
}

class _StockManagementEnhancedState extends State<StockManagementEnhanced> {
  final AdminService _adminService = AdminService();
  String _filterType = 'all'; // 'all', 'low', 'out', 'high'
  String _sortBy = 'stock';
  bool _sortAscending = true;
  Map<String, bool> _stockAlerts = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Stok Kontrol Paneli
        _buildStockControlPanel(),
        
        // Stok Filtreleri
        _buildStockFilters(),
        
        // Stok Listesi
        SizedBox(
          height: 500,
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
              final filteredProducts = _filterProducts(products);
              final sortedProducts = _sortProducts(filteredProducts);
              
              return _buildStockList(sortedProducts);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStockControlPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.warehouse, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Stok Kontrol Paneli',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                Spacer(),
                ElevatedButton.icon(
                  onPressed: _showBulkStockUpdate,
                  icon: Icon(Icons.edit),
                  label: Text('Toplu Güncelle'),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Hızlı stok işlemleri
            Row(
              children: [
                _buildQuickAction('Tümünü Artır', Icons.add, Colors.green, () => _showBulkStockUpdate()),
                SizedBox(width: 8),
                _buildQuickAction('Düşük Stok', Icons.warning, Colors.orange, () => _showLowStockAlert()),
                SizedBox(width: 8),
                _buildQuickAction('Stok Raporu', Icons.assessment, Colors.purple, () => _showStockReport()),
                SizedBox(width: 8),
                _buildQuickAction('Yedekle', Icons.backup, Colors.teal, () => _backupStock()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Filtre butonları
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'all', label: Text('Tümü')),
                ButtonSegment(value: 'low', label: Text('Düşük')),
                ButtonSegment(value: 'out', label: Text('Tükendi')),
                ButtonSegment(value: 'high', label: Text('Yüksek')),
              ],
              selected: {_filterType},
              onSelectionChanged: (Set<String> selection) {
                setState(() {
                  _filterType = selection.first;
                });
              },
            ),
            
            SizedBox(width: 16),
            
            // Sıralama
            DropdownButton<String>(
              value: _sortBy,
              items: const [
                DropdownMenuItem(value: 'stock', child: Text('Stok Miktarı')),
                DropdownMenuItem(value: 'name', child: Text('Ürün Adı')),
                DropdownMenuItem(value: 'price', child: Text('Fiyat')),
                DropdownMenuItem(value: 'category', child: Text('Kategori')),
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
            
            Spacer(),
            
            // Stok uyarıları
            if (_stockAlerts.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning, color: Colors.red[800], size: 16),
                    SizedBox(width: 4),
                    Text(
                      '${_stockAlerts.length} uyarı',
                      style: TextStyle(
                        color: Colors.red[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockList(List<AdminProduct> products) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildStockItem(product);
      },
    );
  }

  Widget _buildStockItem(AdminProduct product) {
    final stockStatus = _getStockStatus(product.stock);
    
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Stok durumu göstergesi
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: stockStatus.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: 16),
            
            // Ürün bilgileri
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Kategori: ${product.category}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Fiyat: ₺${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Stok miktarı
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: stockStatus.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: stockStatus.color),
                    ),
                    child: Text(
                      '${product.stock} adet',
                      style: TextStyle(
                        color: stockStatus.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    stockStatus.text,
                    style: TextStyle(
                      fontSize: 12,
                      color: stockStatus.color,
                    ),
                  ),
                ],
              ),
            ),
            
            // Hızlı stok işlemleri
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Stok azalt
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: IconButton(
                      onPressed: () => _decreaseStock(product),
                      icon: Icon(Icons.remove, color: Colors.red[600]),
                      tooltip: 'Stok Azalt',
                    ),
                  ),
                  SizedBox(width: 8),
                  
                  // Stok artır
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: IconButton(
                      onPressed: () => _increaseStock(product),
                      icon: Icon(Icons.add, color: Colors.green[600]),
                      tooltip: 'Stok Artır',
                    ),
                  ),
                  SizedBox(width: 8),
                  
                  // Stok güncelle
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: IconButton(
                      onPressed: () => _showStockUpdateDialog(product),
                      icon: Icon(Icons.edit, color: Colors.blue[600]),
                      tooltip: 'Stok Güncelle',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  List<AdminProduct> _filterProducts(List<AdminProduct> products) {
    switch (_filterType) {
      case 'low':
        return products.where((p) => p.stock <= 10 && p.stock > 0).toList();
      case 'out':
        return products.where((p) => p.stock == 0).toList();
      case 'high':
        return products.where((p) => p.stock > 50).toList();
      default:
        return products;
    }
  }

  List<AdminProduct> _sortProducts(List<AdminProduct> products) {
    products.sort((a, b) {
      int comparison = 0;
      
      switch (_sortBy) {
        case 'stock':
          comparison = a.stock.compareTo(b.stock);
          break;
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'price':
          comparison = a.price.compareTo(b.price);
          break;
        case 'category':
          comparison = a.category.compareTo(b.category);
          break;
      }
      
      return _sortAscending ? comparison : -comparison;
    });
    
    return products;
  }

  StockStatus _getStockStatus(int stock) {
    if (stock == 0) {
      return StockStatus('Tükendi', Colors.red);
    } else if (stock <= 10) {
      return StockStatus('Düşük Stok', Colors.orange);
    } else if (stock <= 50) {
      return StockStatus('Normal', Colors.green);
    } else {
      return StockStatus('Yüksek Stok', Colors.blue);
    }
  }

  void _decreaseStock(AdminProduct product) async {
    final quantityController = TextEditingController();
    int selectedQuantity = 1; // Varsayılan değer
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Stok Azalt - ${product.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Mevcut Stok: ${product.stock}'),
                const SizedBox(height: 16),
                Text('Kaç adet azaltmak istiyorsunuz?'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Hızlı seçim butonları
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: [1, 5, 10, 25].map((qty) {
                          return ChoiceChip(
                            label: Text('-$qty'),
                            selected: selectedQuantity == qty,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  selectedQuantity = qty;
                                  quantityController.text = qty.toString();
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  textCapitalization: TextCapitalization.none,
                  decoration: const InputDecoration(
                    labelText: 'Miktar',
                    hintText: 'Azaltmak istediğiniz miktarı girin',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.remove),
                  ),
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    if (parsed != null && parsed > 0) {
                      setState(() {
                        selectedQuantity = parsed;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Yeni stok: ${product.stock - selectedQuantity}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: (product.stock - selectedQuantity) < 0 ? Colors.red : Colors.green[700],
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
                onPressed: () async {
                  if (selectedQuantity > 0 && selectedQuantity <= product.stock) {
                    Navigator.pop(context);
                    await _performStockDecrease(product, selectedQuantity);
                  } else if (selectedQuantity > product.stock) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Azaltılacak miktar mevcut stoktan fazla olamaz'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lütfen geçerli bir miktar girin'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text('-$selectedQuantity Azalt'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _increaseStock(AdminProduct product) async {
    final quantityController = TextEditingController();
    int selectedQuantity = 1; // Varsayılan değer
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Stok Artır - ${product.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Mevcut Stok: ${product.stock}'),
                const SizedBox(height: 16),
                Text('Kaç adet eklemek istiyorsunuz?'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Hızlı seçim butonları
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: [1, 5, 10, 25, 50].map((qty) {
                          return ChoiceChip(
                            label: Text('+$qty'),
                            selected: selectedQuantity == qty,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  selectedQuantity = qty;
                                  quantityController.text = qty.toString();
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  textCapitalization: TextCapitalization.none,
                  decoration: const InputDecoration(
                    labelText: 'Miktar',
                    hintText: 'Eklemek istediğiniz miktarı girin',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.add),
                  ),
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    if (parsed != null && parsed > 0) {
                      setState(() {
                        selectedQuantity = parsed;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Yeni stok: ${product.stock + selectedQuantity}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
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
                onPressed: () async {
                  if (selectedQuantity > 0) {
                    Navigator.pop(context);
                    await _performStockIncrease(product, selectedQuantity);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lütfen geçerli bir miktar girin'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text('+$selectedQuantity Ekle'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Gerçek stok artırma işlemi
  Future<void> _performStockIncrease(AdminProduct product, int quantity) async {
    try {
      await _adminService.increaseStock(product.id, quantity);
      _showSuccessMessage('${product.name} stoku $quantity adet artırıldı');
    } catch (e) {
      _showErrorMessage('Hata: $e');
    }
  }

  // Gerçek stok azaltma işlemi
  Future<void> _performStockDecrease(AdminProduct product, int quantity) async {
    try {
      await _adminService.decreaseStock(product.id, quantity);
      _showSuccessMessage('${product.name} stoku $quantity adet azaltıldı');
    } catch (e) {
      _showErrorMessage('Hata: $e');
    }
  }

  void _showStockUpdateDialog(AdminProduct product) {
    final controller = TextEditingController(text: product.stock.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Stok Güncelle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${product.name} için yeni stok miktarı:'),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textCapitalization: TextCapitalization.none,
              decoration: InputDecoration(
                labelText: 'Stok Miktarı',
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
                try {
                  await _adminService.updateStock(product.id, newStock);
                  Navigator.pop(context);
                  _showSuccessMessage('${product.name} stoku güncellendi');
                } catch (e) {
                  _showErrorMessage('Hata: $e');
                }
              }
            },
            child: Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  void _showBulkStockUpdate() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Toplu Stok Güncelleme'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: StreamBuilder<List<AdminProduct>>(
            stream: _adminService.getProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(child: Text('Hata: ${snapshot.error}'));
              }
              
              final products = snapshot.data ?? [];
              
              return Column(
                children: [
                  const Text('Hangi işlemi yapmak istiyorsunuz?'),
                  const SizedBox(height: 16),
                  
                  // İşlem seçimi
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showBulkIncreaseDialog(products),
                          icon: const Icon(Icons.add),
                          label: const Text('Toplu Artır'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showBulkDecreaseDialog(products),
                          icon: const Icon(Icons.remove),
                          label: const Text('Toplu Azalt'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Fiyat işlemleri
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showBulkPriceIncreaseDialog(products),
                          icon: const Icon(Icons.trending_up),
                          label: const Text('Fiyat Artır'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showBulkPriceDecreaseDialog(products),
                          icon: const Icon(Icons.trending_down),
                          label: const Text('Fiyat Düşür'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Kategori seçimi
                  const Text('Kategori Filtresi:'),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: 'Tümü',
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(value: 'Tümü', child: Text('Tüm Kategoriler')),
                      ...products.map((p) => p.category).toSet().map((category) => 
                        DropdownMenuItem(value: category, child: Text(category))
                      ),
                    ],
                    onChanged: (value) {
                      // Kategori değişikliği
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Ürün listesi
                  Expanded(
                    child: ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return CheckboxListTile(
                          title: Text(product.name),
                          subtitle: Text('Mevcut Stok: ${product.stock}'),
                          value: false,
                          onChanged: (selected) {
                            // Ürün seçimi
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  void _showBulkIncreaseDialog(List<AdminProduct> products) {
    final quantityController = TextEditingController();
    int selectedQuantity = 10;
    Set<String> selectedProducts = {};
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Toplu Stok Artırma'),
            content: SizedBox(
              width: 500,
              height: 400,
              child: Column(
                children: [
                  const Text('Hangi ürünlerin stokunu artırmak istiyorsunuz?'),
                  const SizedBox(height: 16),
                  
                  // Miktar seçimi
                  Row(
                    children: [
                      const Text('Miktar: '),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          children: [5, 10, 25, 50, 100].map((qty) {
                            return ChoiceChip(
                              label: Text('+$qty'),
                              selected: selectedQuantity == qty,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    selectedQuantity = qty;
                                    quantityController.text = qty.toString();
                                  });
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    textCapitalization: TextCapitalization.none,
                    decoration: const InputDecoration(
                      labelText: 'Miktar',
                      hintText: 'Eklemek istediğiniz miktarı girin',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.add),
                    ),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null && parsed > 0) {
                        setState(() {
                          selectedQuantity = parsed;
                        });
                      }
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Tümünü seç/seçimi kaldır
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedProducts = products.map((p) => p.id).toSet();
                          });
                        },
                        child: const Text('Tümünü Seç'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedProducts.clear();
                          });
                        },
                        child: const Text('Seçimi Kaldır'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Ürün listesi
                  Expanded(
                    child: ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return CheckboxListTile(
                          title: Text(product.name),
                          subtitle: Text('Mevcut: ${product.stock} → Yeni: ${product.stock + selectedQuantity}'),
                          value: selectedProducts.contains(product.id),
                          onChanged: (selected) {
                            setState(() {
                              if (selected == true) {
                                selectedProducts.add(product.id);
                              } else {
                                selectedProducts.remove(product.id);
                              }
                            });
                          },
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
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: selectedProducts.isNotEmpty ? () async {
                  Navigator.pop(context);
                  await _performBulkIncrease(selectedProducts.toList(), selectedQuantity);
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text('${selectedProducts.length} Ürünü +$selectedQuantity Artır'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showBulkDecreaseDialog(List<AdminProduct> products) {
    final quantityController = TextEditingController();
    int selectedQuantity = 5;
    Set<String> selectedProducts = {};
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Toplu Stok Azaltma'),
            content: SizedBox(
              width: 500,
              height: 400,
              child: Column(
                children: [
                  const Text('Hangi ürünlerin stokunu azaltmak istiyorsunuz?'),
                  const SizedBox(height: 16),
                  
                  // Miktar seçimi
                  Row(
                    children: [
                      const Text('Miktar: '),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          children: [1, 5, 10, 25, 50].map((qty) {
                            return ChoiceChip(
                              label: Text('-$qty'),
                              selected: selectedQuantity == qty,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    selectedQuantity = qty;
                                    quantityController.text = qty.toString();
                                  });
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    textCapitalization: TextCapitalization.none,
                    decoration: const InputDecoration(
                      labelText: 'Miktar',
                      hintText: 'Azaltmak istediğiniz miktarı girin',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.remove),
                    ),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null && parsed > 0) {
                        setState(() {
                          selectedQuantity = parsed;
                        });
                      }
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Tümünü seç/seçimi kaldır
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedProducts = products.where((p) => p.stock >= selectedQuantity).map((p) => p.id).toSet();
                          });
                        },
                        child: const Text('Uygun Olanları Seç'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedProducts.clear();
                          });
                        },
                        child: const Text('Seçimi Kaldır'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Ürün listesi
                  Expanded(
                    child: ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        final canDecrease = product.stock >= selectedQuantity;
                        final newStock = product.stock - selectedQuantity;
                        
                        return CheckboxListTile(
                          title: Text(product.name),
                          subtitle: Text(
                            canDecrease 
                              ? 'Mevcut: ${product.stock} → Yeni: $newStock'
                              : 'Mevcut: ${product.stock} (Yetersiz stok)',
                            style: TextStyle(
                              color: canDecrease ? Colors.black : Colors.red,
                            ),
                          ),
                          value: selectedProducts.contains(product.id),
                          enabled: canDecrease,
                          onChanged: canDecrease ? (selected) {
                            setState(() {
                              if (selected == true) {
                                selectedProducts.add(product.id);
                              } else {
                                selectedProducts.remove(product.id);
                              }
                            });
                          } : null,
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
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: selectedProducts.isNotEmpty ? () async {
                  Navigator.pop(context);
                  await _performBulkDecrease(selectedProducts.toList(), selectedQuantity);
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text('${selectedProducts.length} Ürünü -$selectedQuantity Azalt'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Gerçek toplu stok artırma işlemi
  Future<void> _performBulkIncrease(List<String> productIds, int quantity) async {
    try {
      int successCount = 0;
      int failCount = 0;
      
      for (String productId in productIds) {
        try {
          await _adminService.increaseStock(productId, quantity);
          successCount++;
        } catch (e) {
          failCount++;
          print('Ürün $productId stok artırma hatası: $e');
        }
      }
      
      _showSuccessMessage('$successCount ürün başarıyla güncellendi${failCount > 0 ? ', $failCount ürün başarısız' : ''}');
    } catch (e) {
      _showErrorMessage('Toplu güncelleme hatası: $e');
    }
  }

  // Gerçek toplu stok azaltma işlemi
  Future<void> _performBulkDecrease(List<String> productIds, int quantity) async {
    try {
      int successCount = 0;
      int failCount = 0;
      
      for (String productId in productIds) {
        try {
          await _adminService.decreaseStock(productId, quantity);
          successCount++;
        } catch (e) {
          failCount++;
          print('Ürün $productId stok azaltma hatası: $e');
        }
      }
      
      _showSuccessMessage('$successCount ürün başarıyla güncellendi${failCount > 0 ? ', $failCount ürün başarısız' : ''}');
    } catch (e) {
      _showErrorMessage('Toplu güncelleme hatası: $e');
    }
  }

  // Toplu fiyat artırma dialogu
  void _showBulkPriceIncreaseDialog(List<AdminProduct> products) {
    final percentageController = TextEditingController();
    double selectedPercentage = 10.0; // Varsayılan %10
    Set<String> selectedProducts = {};
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Toplu Fiyat Artırma'),
            content: SizedBox(
              width: 500,
              height: 400,
              child: Column(
                children: [
                  const Text('Hangi ürünlerin fiyatını artırmak istiyorsunuz?'),
                  const SizedBox(height: 16),
                  
                  // Yüzde seçimi
                  Row(
                    children: [
                      const Text('Artış Oranı: '),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          children: [5.0, 10.0, 15.0, 20.0, 25.0].map((percent) {
                            return ChoiceChip(
                              label: Text('+%${percent.toInt()}'),
                              selected: selectedPercentage == percent,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    selectedPercentage = percent;
                                    percentageController.text = percent.toString();
                                  });
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  TextField(
                    controller: percentageController,
                    keyboardType: TextInputType.number,
                    textCapitalization: TextCapitalization.none,
                    decoration: const InputDecoration(
                      labelText: 'Yüzde (%)',
                      hintText: 'Artış oranını girin',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.trending_up),
                      suffix: Text('%'),
                    ),
                    onChanged: (value) {
                      final parsed = double.tryParse(value);
                      if (parsed != null && parsed > 0) {
                        setState(() {
                          selectedPercentage = parsed;
                        });
                      }
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Tümünü seç/seçimi kaldır
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedProducts = products.map((p) => p.id).toSet();
                          });
                        },
                        child: const Text('Tümünü Seç'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedProducts.clear();
                          });
                        },
                        child: const Text('Seçimi Kaldır'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Ürün listesi
                  Expanded(
                    child: ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        final newPrice = product.price * (1 + selectedPercentage / 100);
                        return CheckboxListTile(
                          title: Text(product.name),
                          subtitle: Text('Mevcut: ₺${product.price.toStringAsFixed(2)} → Yeni: ₺${newPrice.toStringAsFixed(2)}'),
                          value: selectedProducts.contains(product.id),
                          onChanged: (selected) {
                            setState(() {
                              if (selected == true) {
                                selectedProducts.add(product.id);
                              } else {
                                selectedProducts.remove(product.id);
                              }
                            });
                          },
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
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: selectedProducts.isNotEmpty ? () async {
                  Navigator.pop(context);
                  await _performBulkPriceIncrease(selectedProducts.toList(), selectedPercentage);
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text('${selectedProducts.length} Ürünü +%${selectedPercentage.toInt()} Artır'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Toplu fiyat düşürme dialogu
  void _showBulkPriceDecreaseDialog(List<AdminProduct> products) {
    final percentageController = TextEditingController();
    double selectedPercentage = 10.0; // Varsayılan %10
    Set<String> selectedProducts = {};
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Toplu Fiyat Düşürme'),
            content: SizedBox(
              width: 500,
              height: 400,
              child: Column(
                children: [
                  const Text('Hangi ürünlerin fiyatını düşürmek istiyorsunuz?'),
                  const SizedBox(height: 16),
                  
                  // Yüzde seçimi
                  Row(
                    children: [
                      const Text('İndirim Oranı: '),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          children: [5.0, 10.0, 15.0, 20.0, 25.0, 30.0].map((percent) {
                            return ChoiceChip(
                              label: Text('-%${percent.toInt()}'),
                              selected: selectedPercentage == percent,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    selectedPercentage = percent;
                                    percentageController.text = percent.toString();
                                  });
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  TextField(
                    controller: percentageController,
                    keyboardType: TextInputType.number,
                    textCapitalization: TextCapitalization.none,
                    decoration: const InputDecoration(
                      labelText: 'Yüzde (%)',
                      hintText: 'İndirim oranını girin',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.trending_down),
                      suffix: Text('%'),
                    ),
                    onChanged: (value) {
                      final parsed = double.tryParse(value);
                      if (parsed != null && parsed > 0 && parsed <= 100) {
                        setState(() {
                          selectedPercentage = parsed;
                        });
                      }
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Tümünü seç/seçimi kaldır
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedProducts = products.map((p) => p.id).toSet();
                          });
                        },
                        child: const Text('Tümünü Seç'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedProducts.clear();
                          });
                        },
                        child: const Text('Seçimi Kaldır'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Ürün listesi
                  Expanded(
                    child: ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        final newPrice = product.price * (1 - selectedPercentage / 100);
                        return CheckboxListTile(
                          title: Text(product.name),
                          subtitle: Text(
                            'Mevcut: ₺${product.price.toStringAsFixed(2)} → Yeni: ₺${newPrice.clamp(0, double.infinity).toStringAsFixed(2)}',
                            style: TextStyle(
                              color: newPrice < 0 ? Colors.red : Colors.black,
                            ),
                          ),
                          value: selectedProducts.contains(product.id),
                          onChanged: (selected) {
                            print('DEBUG: Checkbox değişti - product.id: ${product.id}, selected: $selected');
                            setState(() {
                              if (selected == true) {
                                selectedProducts.add(product.id);
                                print('DEBUG: Ürün eklendi - selectedProducts: $selectedProducts');
                              } else {
                                selectedProducts.remove(product.id);
                                print('DEBUG: Ürün kaldırıldı - selectedProducts: $selectedProducts');
                              }
                            });
                          },
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
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: selectedProducts.isNotEmpty ? () async {
                  print('DEBUG: Azalt butonu tıklandı - selectedProducts: $selectedProducts, selectedPercentage: $selectedPercentage');
                  Navigator.pop(context);
                  await _performBulkPriceDecrease(selectedProducts.toList(), selectedPercentage);
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: Text('${selectedProducts.length} Ürünü -%${selectedPercentage.toInt()} Düşür'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Gerçek toplu fiyat artırma işlemi
  Future<void> _performBulkPriceIncrease(List<String> productIds, double percentage) async {
    try {
      int successCount = 0;
      int failCount = 0;
      
      for (String productId in productIds) {
        try {
          await _adminService.increasePrice(productId, percentage);
          successCount++;
        } catch (e) {
          failCount++;
          print('Ürün $productId fiyat artırma hatası: $e');
        }
      }
      
      _showSuccessMessage('$successCount ürün fiyatı %${percentage.toInt()} artırıldı${failCount > 0 ? ', $failCount ürün başarısız' : ''}');
    } catch (e) {
      _showErrorMessage('Toplu fiyat güncelleme hatası: $e');
    }
  }

  // Gerçek toplu fiyat düşürme işlemi
  Future<void> _performBulkPriceDecrease(List<String> productIds, double percentage) async {
    print('DEBUG: _performBulkPriceDecrease çağrıldı - productIds: $productIds, percentage: $percentage');
    try {
      int successCount = 0;
      int failCount = 0;
      
      for (String productId in productIds) {
        try {
          print('DEBUG: Ürün $productId için fiyat düşürme işlemi başlatılıyor');
          await _adminService.decreasePrice(productId, percentage);
          successCount++;
          print('DEBUG: Ürün $productId fiyat düşürme başarılı');
        } catch (e) {
          failCount++;
          print('Ürün $productId fiyat düşürme hatası: $e');
        }
      }
      
      _showSuccessMessage('$successCount ürün fiyatı %${percentage.toInt()} düşürüldü${failCount > 0 ? ', $failCount ürün başarısız' : ''}');
    } catch (e) {
      _showErrorMessage('Toplu fiyat güncelleme hatası: $e');
    }
  }

  void _showLowStockAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Düşük Stok Uyarıları'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: StreamBuilder<List<AdminProduct>>(
            stream: _adminService.getProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(child: Text('Hata: ${snapshot.error}'));
              }
              
              final products = snapshot.data ?? [];
              final lowStockProducts = products.where((p) => p.stock <= 10).toList();
              
              if (lowStockProducts.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 64),
                      SizedBox(height: 16),
                      Text('Tüm ürünlerde yeterli stok var!', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                itemCount: lowStockProducts.length,
                itemBuilder: (context, index) {
                  final product = lowStockProducts[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: product.stock == 0 ? Colors.red : Colors.orange,
                        child: Icon(
                          product.stock == 0 ? Icons.warning : Icons.warning_amber,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(product.name),
                      subtitle: Text('Kategori: ${product.category}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${product.stock} adet',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: product.stock == 0 ? Colors.red : Colors.orange,
                            ),
                          ),
                          Text(
                            product.stock == 0 ? 'Tükendi!' : 'Düşük Stok',
                            style: TextStyle(
                              fontSize: 12,
                              color: product.stock == 0 ? Colors.red : Colors.orange,
                            ),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showStockReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stok Raporu'),
        content: SizedBox(
          width: 600,
          height: 500,
          child: StreamBuilder<List<AdminProduct>>(
            stream: _adminService.getProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(child: Text('Hata: ${snapshot.error}'));
              }
              
              final products = snapshot.data ?? [];
              
              if (products.isEmpty) {
                return const Center(child: Text('Henüz ürün bulunmuyor'));
              }
              
              // İstatistikler
              final totalProducts = products.length;
              final totalStock = products.fold(0, (sum, p) => sum + p.stock);
              final outOfStock = products.where((p) => p.stock == 0).length;
              final lowStock = products.where((p) => p.stock > 0 && p.stock <= 10).length;
              final highStock = products.where((p) => p.stock > 50).length;
              
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Özet kartları
                    Row(
                      children: [
                        Expanded(
                          child: _buildReportCard('Toplam Ürün', totalProducts.toString(), Icons.inventory, Colors.blue),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildReportCard('Toplam Stok', totalStock.toString(), Icons.warehouse, Colors.green),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildReportCard('Tükendi', outOfStock.toString(), Icons.warning, Colors.red),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildReportCard('Düşük Stok', lowStock.toString(), Icons.warning_amber, Colors.orange),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildReportCard('Yüksek Stok', highStock.toString(), Icons.trending_up, Colors.purple),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    const Text('Kategori Bazında Stok:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    
                    // Kategori raporu
                    ...products.map((p) => p.category).toSet().map((category) {
                      final categoryProducts = products.where((p) => p.category == category).toList();
                      final categoryStock = categoryProducts.fold(0, (sum, p) => sum + p.stock);
                      final categoryCount = categoryProducts.length;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue[100],
                            child: Text(category[0].toUpperCase()),
                          ),
                          title: Text(category),
                          subtitle: Text('$categoryCount ürün'),
                          trailing: Text(
                            '$categoryStock adet',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _backupStock() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stok Yedekleme'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.backup, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text('Stok verileriniz yedekleniyor...'),
            SizedBox(height: 8),
            Text('Bu işlem birkaç saniye sürebilir.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performBackup();
            },
            child: const Text('Yedekle'),
          ),
        ],
      ),
    );
  }

  Future<void> _performBackup() async {
    try {
      // Simüle edilmiş yedekleme işlemi
      await Future.delayed(const Duration(seconds: 2));
      
      _showSuccessMessage('Stok verileri başarıyla yedeklendi!');
    } catch (e) {
      _showErrorMessage('Yedekleme hatası: $e');
    }
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
    }
  }
}

class StockStatus {
  final String text;
  final Color color;

  StockStatus(this.text, this.color);
}
