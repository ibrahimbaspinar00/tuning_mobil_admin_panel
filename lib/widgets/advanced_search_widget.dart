import 'package:flutter/material.dart';
import '../model/admin_product.dart';

class AdvancedSearchWidget extends StatefulWidget {
  final List<AdminProduct> products;
  final Function(List<AdminProduct>) onSearchResults;
  final Function(String) onSearchQuery;

  const AdvancedSearchWidget({
    super.key,
    required this.products,
    required this.onSearchResults,
    required this.onSearchQuery,
  });

  @override
  State<AdvancedSearchWidget> createState() => _AdvancedSearchWidgetState();
}

class _AdvancedSearchWidgetState extends State<AdvancedSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _selectedCategories = [];
  final List<String> _selectedPriceRanges = [];
  double _minPrice = 0;
  double _maxPrice = 10000;
  String _sortBy = 'name';
  bool _isAscending = true;
  bool _showFilters = false;

  final List<String> _categories = [
    'Araç Temizlik',
    'Koku & Parfüm',
    'Telefon Aksesuar',
    'Organizatör',
    'Güvenlik',
    'Elektronik',
    'Aksesuar',
  ];

  final List<Map<String, dynamic>> _priceRanges = [
    {'label': '0-50₺', 'min': 0, 'max': 50},
    {'label': '50-100₺', 'min': 50, 'max': 100},
    {'label': '100-250₺', 'min': 100, 'max': 250},
    {'label': '250-500₺', 'min': 250, 'max': 500},
    {'label': '500₺+', 'min': 500, 'max': 10000},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Arama Çubuğu
          _buildSearchBar(),
          
          // Filtre Butonu
          _buildFilterButton(),
          
          // Filtre Paneli
          if (_showFilters) _buildFilterPanel(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Ürün ara...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
        ),
        onChanged: (value) {
          setState(() {});
          _performSearch();
        },
        onSubmitted: (value) => _performSearch(),
      ),
    );
  }

  Widget _buildFilterButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showFilters = !_showFilters;
                });
              },
              icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
              label: Text(_showFilters ? 'Filtreleri Gizle' : 'Filtrele'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _showFilters ? Colors.orange : Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _clearAllFilters,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Tüm Filtreleri Temizle',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kategori Filtreleri
          _buildCategoryFilters(),
          const SizedBox(height: 16),
          
          // Fiyat Filtreleri
          _buildPriceFilters(),
          const SizedBox(height: 16),
          
          // Sıralama
          _buildSortingOptions(),
          const SizedBox(height: 16),
          
          // Uygula Butonu
          _buildApplyButton(),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategoriler',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((category) {
            final isSelected = _selectedCategories.contains(category);
            return FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCategories.add(category);
                  } else {
                    _selectedCategories.remove(category);
                  }
                });
              },
              selectedColor: Colors.blue[100],
              checkmarkColor: Colors.blue[700],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fiyat Aralığı',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _priceRanges.map((range) {
            final isSelected = _selectedPriceRanges.contains(range['label']);
            return FilterChip(
              label: Text(range['label']),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedPriceRanges.add(range['label']);
                  } else {
                    _selectedPriceRanges.remove(range['label']);
                  }
                });
              },
              selectedColor: Colors.green[100],
              checkmarkColor: Colors.green[700],
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // Özel Fiyat Aralığı
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Min Fiyat',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _minPrice = double.tryParse(value) ?? 0;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Max Fiyat',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _maxPrice = double.tryParse(value) ?? 10000;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSortingOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sıralama',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _sortBy,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Sırala',
                ),
                items: const [
                  DropdownMenuItem(value: 'name', child: Text('İsim')),
                  DropdownMenuItem(value: 'price', child: Text('Fiyat')),
                  DropdownMenuItem(value: 'category', child: Text('Kategori')),
                ],
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<bool>(
                value: _isAscending,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Sıra',
                ),
                items: const [
                  DropdownMenuItem(value: true, child: Text('Artan')),
                  DropdownMenuItem(value: false, child: Text('Azalan')),
                ],
                onChanged: (value) {
                  setState(() {
                    _isAscending = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildApplyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _applyFilters,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text('Filtreleri Uygula'),
      ),
    );
  }

  void _performSearch() {
    final query = _searchController.text.toLowerCase();
    widget.onSearchQuery(query);
    
    List<AdminProduct> results = widget.products.where((product) {
      // Arama sorgusu kontrolü
      final matchesSearch = query.isEmpty || 
          product.name.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query);
      
      return matchesSearch;
    }).toList();
    
    widget.onSearchResults(results);
  }

  void _applyFilters() {
    List<AdminProduct> results = widget.products.where((product) {
      // Kategori filtresi
      if (_selectedCategories.isNotEmpty) {
        if (!_selectedCategories.any((category) => 
            product.category.toLowerCase().contains(category.toLowerCase()))) {
          return false;
        }
      }
      
      // Fiyat filtresi
      if (_selectedPriceRanges.isNotEmpty) {
        bool priceMatches = false;
        for (final range in _selectedPriceRanges) {
          final rangeData = _priceRanges.firstWhere((r) => r['label'] == range);
          if (product.price >= rangeData['min'] && product.price <= rangeData['max']) {
            priceMatches = true;
            break;
          }
        }
        if (!priceMatches) return false;
      }
      
      // Özel fiyat aralığı
      if (product.price < _minPrice || product.price > _maxPrice) {
        return false;
      }
      
      return true;
    }).toList();
    
    // Sıralama
    results.sort((a, b) {
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
      }
      return _isAscending ? comparison : -comparison;
    });
    
    widget.onSearchResults(results);
  }

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategories.clear();
      _selectedPriceRanges.clear();
      _minPrice = 0;
      _maxPrice = 10000;
      _sortBy = 'name';
      _isAscending = true;
    });
    widget.onSearchResults(widget.products);
  }
}