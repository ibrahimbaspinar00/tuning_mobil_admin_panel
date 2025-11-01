import 'package:flutter/material.dart';
import '../model/admin_product.dart';
import '../services/admin_service.dart';

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
                      ? ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                          child: Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.image, size: 48, color: Colors.grey[400]);
                            },
                          ),
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
                                // İşlem seçildi
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
}
