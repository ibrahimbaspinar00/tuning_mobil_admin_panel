import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../model/admin_product.dart';

/// Mobil ve Web uygulamaları için kategori filtreleme widget'ı
class CategoryFilterWidget extends StatefulWidget {
  final String? selectedCategory;
  final Function(String?) onCategorySelected;
  final List<AdminProduct>? products; // Opsiyonel: Ürünlerden kategori çıkarmak için
  final bool showAllOption;
  final bool horizontalScroll;

  const CategoryFilterWidget({
    super.key,
    this.selectedCategory,
    required this.onCategorySelected,
    this.products,
    this.showAllOption = true,
    this.horizontalScroll = true,
  });

  @override
  State<CategoryFilterWidget> createState() => _CategoryFilterWidgetState();
}

class _CategoryFilterWidgetState extends State<CategoryFilterWidget> {
  final AdminService _adminService = AdminService();
  List<String> _availableCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      // Firestore'dan kategorileri çek
      final categories = await _adminService.getCategories().first;
      
      setState(() {
        _availableCategories = [];
        
        // "Tümü" seçeneğini ekle
        if (widget.showAllOption) {
          _availableCategories.add('Tümü');
        }
        
        // Firestore'dan gelen kategorileri ekle
        for (final cat in categories) {
          if (cat.isActive && !_availableCategories.contains(cat.name)) {
            _availableCategories.add(cat.name);
          }
        }
        
        // Ürünlerden de kategorileri al (kategori sistemi olmayan ürünler için)
        if (widget.products != null && widget.products!.isNotEmpty) {
          final productCategories = widget.products!
              .map((p) => p.category)
              .where((c) => c.isNotEmpty)
              .where((c) => !_availableCategories.contains(c))
              .toSet();
          
          for (final cat in productCategories) {
            if (!_availableCategories.contains(cat)) {
              _availableCategories.add(cat);
            }
          }
        }
        
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Kategoriler yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 50,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_availableCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedCategory = widget.selectedCategory ?? (widget.showAllOption ? 'Tümü' : null);

    if (widget.horizontalScroll) {
      return SizedBox(
        height: 50,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: _availableCategories.length,
          itemBuilder: (context, index) {
            final category = _availableCategories[index];
            final isSelected = selectedCategory == category;
            
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  widget.onCategorySelected(selected ? category : (widget.showAllOption ? 'Tümü' : null));
                },
                selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                checkmarkColor: Theme.of(context).primaryColor,
                labelStyle: TextStyle(
                  color: isSelected 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                avatar: isSelected 
                  ? Icon(
                      Icons.check_circle,
                      size: 18,
                      color: Theme.of(context).primaryColor,
                    )
                  : null,
              ),
            );
          },
        ),
      );
    } else {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _availableCategories.map((category) {
          final isSelected = selectedCategory == category;
          
          return FilterChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (selected) {
              widget.onCategorySelected(selected ? category : (widget.showAllOption ? 'Tümü' : null));
            },
            selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
            checkmarkColor: Theme.of(context).primaryColor,
            labelStyle: TextStyle(
              color: isSelected 
                ? Theme.of(context).primaryColor 
                : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            avatar: isSelected 
              ? Icon(
                  Icons.check_circle,
                  size: 18,
                  color: Theme.of(context).primaryColor,
                )
              : null,
          );
        }).toList(),
      );
    }
  }
}

/// Kategori dropdown widget'ı (daha kompakt görünüm için)
class CategoryDropdownFilter extends StatefulWidget {
  final String? selectedCategory;
  final Function(String?) onCategorySelected;
  final List<AdminProduct>? products;
  final bool showAllOption;

  const CategoryDropdownFilter({
    super.key,
    this.selectedCategory,
    required this.onCategorySelected,
    this.products,
    this.showAllOption = true,
  });

  @override
  State<CategoryDropdownFilter> createState() => _CategoryDropdownFilterState();
}

class _CategoryDropdownFilterState extends State<CategoryDropdownFilter> {
  final AdminService _adminService = AdminService();
  List<String> _availableCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _adminService.getCategories().first;
      
      setState(() {
        _availableCategories = [];
        
        if (widget.showAllOption) {
          _availableCategories.add('Tümü');
        }
        
        for (final cat in categories) {
          if (cat.isActive && !_availableCategories.contains(cat.name)) {
            _availableCategories.add(cat.name);
          }
        }
        
        if (widget.products != null && widget.products!.isNotEmpty) {
          final productCategories = widget.products!
              .map((p) => p.category)
              .where((c) => c.isNotEmpty && !_availableCategories.contains(c))
              .toSet();
          
          _availableCategories.addAll(productCategories);
        }
        
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Kategoriler yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 50,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_availableCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedCategory = widget.selectedCategory ?? (widget.showAllOption ? 'Tümü' : null);
    
    // Seçili kategori listede yoksa null yap (silinen kategori olabilir)
    final safeSelectedCategory = selectedCategory != null && _availableCategories.contains(selectedCategory)
        ? selectedCategory
        : (widget.showAllOption ? 'Tümü' : null);

    return DropdownButtonFormField<String>(
      value: safeSelectedCategory,
      decoration: const InputDecoration(
        labelText: 'Kategori',
        prefixIcon: Icon(Icons.category),
        border: OutlineInputBorder(),
      ),
      items: _availableCategories.map((category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(category == 'Tümü' ? 'Tüm Kategoriler' : category),
        );
      }).toList(),
      onChanged: (value) {
        widget.onCategorySelected(value);
      },
    );
  }
}

