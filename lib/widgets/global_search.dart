import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Global arama widget'ı - Tüm sayfalarda kullanılabilir
class GlobalSearch extends StatefulWidget {
  const GlobalSearch({super.key});

  @override
  State<GlobalSearch> createState() => _GlobalSearchState();
}

class _GlobalSearchState extends State<GlobalSearch> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  List<SearchResult> _results = [];
  String _selectedCategory = 'all'; // 'all', 'products', 'orders', 'users'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = <SearchResult>[];

      if (_selectedCategory == 'all' || _selectedCategory == 'products') {
        final products = await _adminService.getProductsFromServer();
        for (final product in products) {
          if (_matchesQuery(query, [product.name, product.category, product.description])) {
            results.add(SearchResult(
              type: 'product',
              id: product.id,
              title: product.name,
              subtitle: 'Kategori: ${product.category} | Fiyat: ₺${product.price.toStringAsFixed(2)}',
              data: product,
            ));
          }
        }
      }

      if (_selectedCategory == 'all' || _selectedCategory == 'orders') {
        final orders = await _adminService.getOrders().first;
        for (final order in orders) {
          if (_matchesQuery(query, [
            order.id,
            order.customerName,
            order.customerEmail,
            order.status,
          ])) {
            results.add(SearchResult(
              type: 'order',
              id: order.id,
              title: 'Sipariş #${order.id}',
              subtitle: 'Müşteri: ${order.customerName} | Tutar: ₺${order.totalAmount.toStringAsFixed(2)}',
              data: order,
            ));
          }
        }
      }

      if (_selectedCategory == 'all' || _selectedCategory == 'users') {
        try {
          final usersSnapshot = await FirebaseFirestore.instance
              .collection('adminUsers')
              .get();
          
          for (final doc in usersSnapshot.docs) {
            final data = doc.data();
            final userName = data['name']?.toString() ?? '';
            final userEmail = data['email']?.toString() ?? '';
            
            if (_matchesQuery(query, [userName, userEmail, doc.id])) {
              results.add(SearchResult(
                type: 'user',
                id: doc.id,
                title: userName.isNotEmpty ? userName : userEmail,
                subtitle: userEmail,
                data: data,
              ));
            }
          }
        } catch (e) {
          debugPrint('Kullanıcı arama hatası: $e');
        }
      }

      setState(() {
        _results = results;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('Arama hatası: $e');
      setState(() => _isSearching = false);
    }
  }

  bool _matchesQuery(String query, List<String> fields) {
    final lowerQuery = query.toLowerCase();
    return fields.any((field) => field.toLowerCase().contains(lowerQuery));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arama'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Ara...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _results = [];
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _performSearch(value);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Tümü'),
                      selected: _selectedCategory == 'all',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = 'all');
                          _performSearch(_searchQuery);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Ürünler'),
                      selected: _selectedCategory == 'products',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = 'products');
                          _performSearch(_searchQuery);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Siparişler'),
                      selected: _selectedCategory == 'orders',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = 'orders');
                          _performSearch(_searchQuery);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Kullanıcılar'),
                      selected: _selectedCategory == 'users',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = 'users');
                          _performSearch(_searchQuery);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : _searchQuery.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Arama yapmak için yukarıdaki kutuya yazın',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : _results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Sonuç bulunamadı',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final result = _results[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(_getIconForType(result.type)),
                            title: Text(result.title),
                            subtitle: Text(result.subtitle),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () => _handleResultTap(result),
                          ),
                        );
                      },
                    ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'product':
        return Icons.inventory_2;
      case 'order':
        return Icons.shopping_bag;
      case 'user':
        return Icons.person;
      default:
        return Icons.info;
    }
  }

  void _handleResultTap(SearchResult result) {
    // Burada sonuç tıklandığında ne yapılacağı belirlenir
    // Örneğin, ürün sayfasına yönlendirme, sipariş detayına gitme vb.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${result.type} - ${result.title}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class SearchResult {
  final String type;
  final String id;
  final String title;
  final String subtitle;
  final dynamic data;

  SearchResult({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.data,
  });
}

