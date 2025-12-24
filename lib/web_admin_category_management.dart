import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'services/admin_service.dart';
import 'model/admin_product.dart';
import 'utils/responsive_helper.dart';
import 'widgets/professional_image_uploader.dart';

class WebAdminCategoryManagement extends StatefulWidget {
  const WebAdminCategoryManagement({super.key});

  @override
  State<WebAdminCategoryManagement> createState() => _WebAdminCategoryManagementState();
}

class _WebAdminCategoryManagementState extends State<WebAdminCategoryManagement> {
  final AdminService _adminService = AdminService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  ProductCategory? _editingCategory;
  List<String> _productCategories = []; // Ürünlerden gelen kategoriler
  bool _showProductCategories = true; // Ürünlerden gelen kategorileri göster/gizle
  int _refreshKey = 0; // StreamBuilder'ı yeniden build etmek için key

  @override
  void initState() {
    super.initState();
    _loadProductCategories();
  }

  Future<void> _loadProductCategories() async {
    try {
      final products = await _adminService.getProductsFromServer();
      final categories = products
          .map((p) => p.category)
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList();
      setState(() {
        _productCategories = categories;
      });
    } catch (e) {
      debugPrint('Ürün kategorileri yüklenirken hata: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: ResponsiveHelper.responsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kategori Yönetimi',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Row(
                  children: [
                    // Filtre butonu
                    IconButton(
                      icon: Icon(
                        _showProductCategories ? Icons.visibility : Icons.visibility_off,
                      ),
                      tooltip: _showProductCategories 
                        ? 'Ürünlerden gelen kategorileri gizle' 
                        : 'Ürünlerden gelen kategorileri göster',
                      onPressed: () {
                        setState(() {
                          _showProductCategories = !_showProductCategories;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _showAddCategoryDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Yeni Kategori'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Statistics Cards
            _buildStatisticsCards(),
            const SizedBox(height: 32),

            // Categories List
            const Text(
              'Kategoriler',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<ProductCategory>>(
              key: ValueKey(_refreshKey), // StreamBuilder'ı yeniden build etmek için
              stream: _adminService.getAllCategories(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Hata: ${snapshot.error}'),
                  );
                }

                final firestoreCategories = snapshot.data ?? [];
                
                // Firestore kategorilerinin isimlerini al
                final firestoreCategoryNames = firestoreCategories.map((c) => c.name).toSet();
                
                // Ürünlerden gelen ama Firestore'da olmayan kategorileri bul
                final missingCategories = _productCategories
                    .where((catName) => !firestoreCategoryNames.contains(catName))
                    .toList();

                // Tüm kategorileri birleştir
                final allCategories = <ProductCategory>[];
                
                // Önce Firestore kategorilerini ekle
                allCategories.addAll(firestoreCategories);
                
                // Sonra eksik kategorileri ekle (ürünlerden gelen ama Firestore'da olmayanlar)
                if (_showProductCategories) {
                  for (final catName in missingCategories) {
                    allCategories.add(ProductCategory(
                      id: 'product_${catName.hashCode}', // Geçici ID
                      name: catName,
                      description: 'Ürünlerden otomatik eklenen kategori',
                      isActive: true,
                    ));
                  }
                }

                if (allCategories.isEmpty && _productCategories.isEmpty) {
                  return _buildEmptyState();
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = ResponsiveHelper.responsiveColumns(
                      context,
                      mobile: 1,
                      tablet: 2,
                      laptop: 3,
                      desktop: 4,
                    );

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: ResponsiveHelper.responsiveGridSpacing(context),
                        mainAxisSpacing: ResponsiveHelper.responsiveGridSpacing(context),
                        childAspectRatio: 1.2,
                      ),
                      itemCount: allCategories.length,
                      itemBuilder: (context, index) => _buildCategoryCard(allCategories[index], firestoreCategoryNames.contains(allCategories[index].name)),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return StreamBuilder<List<ProductCategory>>(
      key: ValueKey('stats_$_refreshKey'), // StreamBuilder'ı yeniden build etmek için
      stream: _adminService.getAllCategories(),
      builder: (context, snapshot) {
        final firestoreCategories = snapshot.data ?? [];
        final firestoreCategoryNames = firestoreCategories.map((c) => c.name).toSet();
        
        // Ürünlerden gelen ama Firestore'da olmayan kategorileri say
        final missingCategoriesList = _productCategories
            .where((catName) => !firestoreCategoryNames.contains(catName))
            .toList();
        final missingCategories = _showProductCategories ? missingCategoriesList.length : 0;
        
        // Toplam kategori sayısı (Firestore + ürünlerden gelen)
        final totalCategories = firestoreCategories.length + missingCategories;
        final activeCategories = firestoreCategories.where((c) => c.isActive).length;
        final inactiveCategories = firestoreCategories.length - activeCategories;

        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = ResponsiveHelper.responsiveColumns(
              context,
              mobile: 1,
              tablet: 2,
              laptop: 2,
              desktop: 4,
            );

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: ResponsiveHelper.responsiveGridSpacing(context),
                mainAxisSpacing: ResponsiveHelper.responsiveGridSpacing(context),
                childAspectRatio: 2.5,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                switch (index) {
                  case 0:
                    return _StatCard(
                      title: 'Toplam Kategori',
                      value: totalCategories.toString(),
                      icon: Icons.category_rounded,
                      color: const Color(0xFF3B82F6),
                    );
                  case 1:
                    return _StatCard(
                      title: 'Aktif Kategori',
                      value: activeCategories.toString(),
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF10B981),
                    );
                  case 2:
                    return _StatCard(
                      title: 'Pasif Kategori',
                      value: inactiveCategories.toString(),
                      icon: Icons.cancel_rounded,
                      color: const Color(0xFFEF4444),
                    );
                  case 3:
                    return _StatCard(
                      title: 'Ürünlerden Gelen',
                      value: missingCategories.toString(),
                      icon: Icons.inventory_2_rounded,
                      color: const Color(0xFFF59E0B),
                    );
                  default:
                    return const SizedBox();
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryCard(ProductCategory category, bool isFromFirestore) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: category.isActive 
            ? const Color(0xFF10B981).withValues(alpha: 0.3)
            : Colors.grey.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: category.isActive 
                ? const Color(0xFF10B981).withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: category.isActive 
                      ? const Color(0xFF10B981)
                      : Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    category.isActive ? 'Aktif' : 'Pasif',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Description
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                category.description.isEmpty ? 'Açıklama yok' : category.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Ürünleri görüntüle butonu (tüm kategoriler için)
                IconButton(
                  icon: const Icon(Icons.inventory_2, size: 20),
                  color: const Color(0xFF8B5CF6),
                  onPressed: () => _showCategoryProductsDialog(category.name),
                  tooltip: 'Ürünleri Görüntüle',
                ),
                if (isFromFirestore) ...[
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    color: const Color(0xFF3B82F6),
                    onPressed: () => _showEditCategoryDialog(category),
                    tooltip: 'Düzenle',
                  ),
                  IconButton(
                    icon: Icon(
                      category.isActive ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                    ),
                    color: const Color(0xFFF59E0B),
                    onPressed: () => _toggleCategoryStatus(category),
                    tooltip: category.isActive ? 'Pasif Yap' : 'Aktif Yap',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    color: const Color(0xFFEF4444),
                    onPressed: () => _showDeleteCategoryDialog(category),
                    tooltip: 'Sil',
                  ),
                ] else ...[
                  // Ürünlerden gelen kategori için Firestore'a ekle ve sil butonları
                  Tooltip(
                    message: 'Firestore\'a ekle',
                    child: IconButton(
                      icon: const Icon(Icons.add_circle, size: 20),
                      color: const Color(0xFF10B981),
                      onPressed: () => _addCategoryFromProduct(category.name),
                      tooltip: 'Firestore\'a Ekle',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    color: const Color(0xFFEF4444),
                    onPressed: () => _showDeleteProductCategoryDialog(category.name),
                    tooltip: 'Kategoriyi Ürünlerden Kaldır',
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Ürünlerden',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz kategori bulunmuyor',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'İlk kategoriyi ekleyerek başlayın',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddCategoryDialog,
            icon: const Icon(Icons.add),
            label: const Text('Kategori Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    _nameController.clear();
    _descriptionController.clear();
    _editingCategory = null;

    showDialog(
      context: context,
      builder: (context) => _CategoryDialog(
        nameController: _nameController,
        descriptionController: _descriptionController,
        editingCategory: _editingCategory,
        onSave: (name, description) async {
          try {
            final category = ProductCategory(
              id: '',
              name: name,
              description: description,
              isActive: true,
            );
            await _adminService.addCategory(category);
            if (mounted) {
              // StreamBuilder'ı yeniden build etmek için key'i güncelle
              setState(() {
                _refreshKey++;
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Kategori başarıyla eklendi'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Hata: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditCategoryDialog(ProductCategory category) {
    _nameController.text = category.name;
    _descriptionController.text = category.description;
    _editingCategory = category;

    showDialog(
      context: context,
      builder: (context) => _CategoryDialog(
        nameController: _nameController,
        descriptionController: _descriptionController,
        editingCategory: _editingCategory,
        onSave: (name, description) async {
          try {
            final updatedCategory = ProductCategory(
              id: category.id,
              name: name,
              description: description,
              isActive: category.isActive,
            );
            await _adminService.updateCategory(updatedCategory);
            if (mounted) {
              // StreamBuilder'ı yeniden build etmek için key'i güncelle
              setState(() {
                _refreshKey++;
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Kategori başarıyla güncellendi'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Hata: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _toggleCategoryStatus(ProductCategory category) async {
    try {
      final updatedCategory = ProductCategory(
        id: category.id,
        name: category.name,
        description: category.description,
        isActive: !category.isActive,
      );
      await _adminService.updateCategory(updatedCategory);
      if (mounted) {
        // StreamBuilder'ı yeniden build etmek için key'i güncelle
        setState(() {
          _refreshKey++;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedCategory.isActive 
                ? 'Kategori aktif edildi'
                : 'Kategori pasif edildi',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addCategoryFromProduct(String categoryName) async {
    _nameController.text = categoryName;
    _descriptionController.clear();
    _editingCategory = null;

    showDialog(
      context: context,
      builder: (context) => _CategoryDialog(
        nameController: _nameController,
        descriptionController: _descriptionController,
        editingCategory: _editingCategory,
        onSave: (name, description) async {
          try {
            final category = ProductCategory(
              id: '',
              name: name,
              description: description,
              isActive: true,
            );
            await _adminService.addCategory(category);
            if (mounted) {
              // StreamBuilder'ı yeniden build etmek için key'i güncelle
              setState(() {
                _refreshKey++;
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Kategori başarıyla Firestore\'a eklendi'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
              // Kategorileri yeniden yükle
              _loadProductCategories();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Hata: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showDeleteProductCategoryDialog(String categoryName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Kategoriyi Ürünlerden Kaldır'),
        content: Text(
          '$categoryName kategorisini tüm ürünlerden kaldırmak istediğinizden emin misiniz? Bu işlem geri alınamaz ve bu kategorideki tüm ürünlerin kategorisi boşaltılacaktır.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteCategoryFromProducts(categoryName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Kaldır'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategoryFromProducts(String categoryName) async {
    try {
      // Tüm ürünleri al
      final allProducts = await _adminService.getProductsFromServer();
      
      // Bu kategorideki ürünleri bul
      final productsInCategory = allProducts
          .where((p) => p.category == categoryName)
          .toList();

      if (productsInCategory.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bu kategoride ürün bulunamadı'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Bu kategorideki tüm ürünlerin kategorisini boşalt
      int updatedCount = 0;
      for (final product in productsInCategory) {
        await _adminService.updateProductFields(product.id, {'category': ''});
        updatedCount++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$updatedCount ürünün kategorisi kaldırıldı. Kategori listeden kaybolacak.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCategoryProductsDialog(String categoryName) async {
    try {
      // Tüm ürünleri al
      final allProducts = await _adminService.getProductsFromServer();
      
      // Bu kategorideki ürünleri filtrele
      final productsInCategory = allProducts
          .where((p) => p.category == categoryName)
          .toList();
      
      // Tüm kategorileri al (dropdown için)
      final allCategories = await _adminService.getAllCategories().first;
      final allProductsList = await _adminService.getProductsFromServer();
      final productCategories = allProductsList
          .map((p) => p.category)
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList();
      
      final allCategoryNames = <String>[];
      for (final cat in allCategories) {
        if (!allCategoryNames.contains(cat.name)) {
          allCategoryNames.add(cat.name);
        }
      }
      for (final catName in productCategories) {
        if (!allCategoryNames.contains(catName)) {
          allCategoryNames.add(catName);
        }
      }
      allCategoryNames.sort();
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '$categoryName Kategorisindeki Ürünler',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${productsInCategory.length} ürün bulundu',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                // Kategoriye ürün ekle butonu
                ElevatedButton.icon(
                  onPressed: () {
                    _showAddProductsToCategoryDialog(categoryName, allCategoryNames, allProducts);
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Kategoriye Ürün Ekle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                // Ürün listesi
                Expanded(
                  child: productsInCategory.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Bu kategoride ürün bulunmuyor',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: productsInCategory.length,
                          itemBuilder: (context, index) {
                            final product = productsInCategory[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: product.imageUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          product.imageUrl,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              width: 50,
                                              height: 50,
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.image),
                                            );
                                          },
                                        ),
                                      )
                                    : Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.image),
                                      ),
                                title: Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('Fiyat: ${product.price.toStringAsFixed(2)} ₺'),
                                    Text('Stok: ${product.stock}'),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Düzenle butonu
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      color: const Color(0xFF3B82F6),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _showEditProductDialog(product, allCategoryNames, categoryName);
                                      },
                                      tooltip: 'Düzenle',
                                    ),
                                    const SizedBox(width: 8),
                                    // Kategori dropdown
                                    SizedBox(
                                      width: 180,
                                      child: DropdownButtonFormField<String>(
                                        value: product.category,
                                        decoration: const InputDecoration(
                                          labelText: 'Kategori',
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          isDense: true,
                                        ),
                                        isExpanded: true,
                                        items: allCategoryNames.map((catName) {
                                          return DropdownMenuItem<String>(
                                            value: catName,
                                            child: Text(catName),
                                          );
                                        }).toList(),
                                        onChanged: (newCategory) async {
                                          if (newCategory != null && newCategory != product.category) {
                                            try {
                                              await _adminService.updateProductFields(
                                                product.id,
                                                {'category': newCategory},
                                              );
                                              
                                              // Başarılı mesajı göster
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('${product.name} ürününün kategorisi "$newCategory" olarak güncellendi'),
                                                    backgroundColor: Colors.green,
                                                    duration: const Duration(seconds: 2),
                                                  ),
                                                );
                                              }
                                              
                                              // Dialog'u yenile
                                              Navigator.pop(context);
                                              _showCategoryProductsDialog(categoryName);
                                            } catch (e) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Hata: $e'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          }
                                        },
                                      ),
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
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ürünler yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddProductsToCategoryDialog(String categoryName, List<String> allCategoryNames, List<AdminProduct> initialProducts) async {
    // Ürünleri state içinde tutmak için
    List<AdminProduct> currentProducts = List.from(initialProducts);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Tüm ürünleri göster (bu kategoride olanlar ve olmayanlar)
          final allProductsList = currentProducts;
          
          // Bu kategoride olan ve olmayan ürünleri ayır
          final productsInCategory = allProductsList
              .where((p) => p.category == categoryName)
              .toList();
          final productsNotInCategory = allProductsList
              .where((p) => p.category != categoryName)
              .toList();
          
          if (allProductsList.isEmpty) {
            return const SizedBox.shrink();
          }

          return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.7,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '$categoryName Kategorisine Ürün Ekle',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Toplam: ${allProductsList.length} ürün',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Bu kategoride: ${productsInCategory.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Eklenebilir: ${productsNotInCategory.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              // Ürün listesi
              Expanded(
                child: ListView.builder(
                  itemCount: allProductsList.length,
                  itemBuilder: (context, index) {
                    final product = allProductsList[index];
                    final isInCategory = product.category == categoryName;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: product.imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  product.imageUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image),
                                    );
                                  },
                                ),
                              )
                            : Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.image),
                              ),
                        title: Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Fiyat: ${product.price.toStringAsFixed(2)} ₺'),
                            Text('Stok: ${product.stock}'),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isInCategory 
                                    ? Colors.orange.withValues(alpha: 0.1)
                                    : Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isInCategory 
                                      ? Colors.orange
                                      : Colors.blue,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isInCategory 
                                        ? Icons.info_outline
                                        : Icons.category_outlined,
                                    size: 14,
                                    color: isInCategory 
                                        ? Colors.orange
                                        : Colors.blue,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      isInCategory
                                          ? 'Bu ürün bu kategoride zaten ekli.'
                                          : 'Mevcut Kategori: ${product.category.isEmpty ? "Kategori Yok" : product.category}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isInCategory 
                                            ? Colors.orange[700]
                                            : Colors.blue[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isInCategory)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Farklı bir kategoriye ekleyebilirsiniz.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: isInCategory
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Zaten Ekli',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await _adminService.updateProductFields(
                                product.id,
                                {'category': categoryName},
                              );
                              
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${product.name} ürünü "$categoryName" kategorisine eklendi'),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                              
                              // Ürünleri yeniden yükle ve dialog'u güncelle
                              final updatedProducts = await _adminService.getProductsFromServer();
                              setDialogState(() {
                                currentProducts = updatedProducts;
                              });
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Hata: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Ekle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
        },
      ),
    );
  }

  void _showEditProductDialog(AdminProduct product, List<String> allCategoryNames, String currentCategoryName) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: product.name);
    final _priceController = TextEditingController(text: product.price.toString());
    final _stockController = TextEditingController(text: product.stock.toString());
    final _descriptionController = TextEditingController(text: product.description);
    String? _uploadedImageUrl = product.imageUrl.isNotEmpty ? product.imageUrl : null;
    final GlobalKey<ProfessionalImageUploaderState> _imageUploaderKey = GlobalKey();
    String? _selectedCategory = product.category;
    bool _isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.6,
            constraints: const BoxConstraints(maxHeight: 800),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF3B82F6),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ürünü Düzenle',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _isSaving ? null : () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Form
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Resim yükleme
                          ProfessionalImageUploader(
                            key: _imageUploaderKey,
                            label: 'Ürün Resmi',
                            initialImageUrl: _uploadedImageUrl,
                            productId: product.id,
                            aspectRatio: 1.0,
                            autoUpload: false,
                            onImageUploaded: (imageUrl) {
                              setDialogState(() {
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
                          // Ürün adı
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
                          // Fiyat ve Stok
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
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                          // Kategori
                          DropdownButtonFormField<String>(
                            value: _selectedCategory != null && allCategoryNames.contains(_selectedCategory)
                                ? _selectedCategory
                                : (allCategoryNames.isNotEmpty ? allCategoryNames.first : null),
                            decoration: const InputDecoration(
                              labelText: 'Kategori',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.category),
                            ),
                            isExpanded: true,
                            items: allCategoryNames.map((catName) {
                              return DropdownMenuItem<String>(
                                value: catName,
                                child: Text(catName),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setDialogState(() {
                                _selectedCategory = value;
                              });
                            },
                            validator: (value) => value == null || value.isEmpty ? 'Kategori seçiniz' : null,
                          ),
                          const SizedBox(height: 16),
                          // Açıklama
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
                // Butonlar
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSaving ? null : () => Navigator.pop(context),
                        child: const Text('İptal'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isSaving ? null : () async {
                          if (_formKey.currentState!.validate()) {
                            setDialogState(() {
                              _isSaving = true;
                            });

                            try {
                              // Fotoğraf yüklenmemişse önce yükle
                              String finalImageUrl = _uploadedImageUrl ?? '';
                              
                              if (_imageUploaderKey.currentState != null) {
                                final uploaderState = _imageUploaderKey.currentState!;
                                
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
                                    setDialogState(() {
                                      _isSaving = false;
                                    });
                                    return;
                                  }
                                } else if (uploaderState.uploadedImageUrl != null) {
                                  finalImageUrl = uploaderState.uploadedImageUrl!;
                                }
                              }
                              
                              // Ürün güncelle
                              final updatedProduct = AdminProduct(
                                id: product.id,
                                name: _nameController.text,
                                description: _descriptionController.text,
                                price: double.parse(_priceController.text),
                                stock: int.parse(_stockController.text),
                                category: _selectedCategory ?? '',
                                imageUrl: finalImageUrl,
                                isActive: product.isActive,
                                createdAt: product.createdAt,
                                updatedAt: DateTime.now(),
                              );
                              
                              await _adminService.updateProduct(product.id, updatedProduct);
                              
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Ürün başarıyla güncellendi'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                // Dialog'u yenile
                                _showCategoryProductsDialog(currentCategoryName);
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Hata: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                              setDialogState(() {
                                _isSaving = false;
                              });
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
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
        ),
      ),
    );
  }

  void _showDeleteCategoryDialog(ProductCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Kategoriyi Sil'),
        content: Text(
          '${category.name} kategorisini silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _adminService.deleteCategory(category.id);
                if (mounted) {
                  // StreamBuilder'ı yeniden build etmek için key'i güncelle
                  setState(() {
                    _refreshKey++;
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kategori başarıyla silindi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hata: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final ProductCategory? editingCategory;
  final Function(String name, String description) onSave;

  const _CategoryDialog({
    required this.nameController,
    required this.descriptionController,
    this.editingCategory,
    required this.onSave,
  });

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: ResponsiveHelper.responsiveDialogWidth(context),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.editingCategory == null ? 'Yeni Kategori' : 'Kategori Düzenle',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: widget.nameController,
                decoration: const InputDecoration(
                  labelText: 'Kategori Adı',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Kategori adı gereklidir';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: widget.descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Açıklama gereklidir';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        widget.onSave(
                          widget.nameController.text.trim(),
                          widget.descriptionController.text.trim(),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Kaydet'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

