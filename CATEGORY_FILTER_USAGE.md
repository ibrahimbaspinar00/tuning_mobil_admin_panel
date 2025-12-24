# Kategori Filtreleme Kullanım Kılavuzu

## Admin Panelinde Kategori Filtreleme

Admin panelinde (`lib/web_admin_simple_products.dart`) kategori filtreleme otomatik olarak çalışır:

1. **Görsel Kategori Çipleri**: Ürün listesi sayfasında arama çubuğunun altında kategori filtreleme çipleri görünür
2. **Firestore Entegrasyonu**: Kategoriler Firestore'dan otomatik olarak çekilir
3. **Dinamik Kategori Listesi**: Hem Firestore'dan hem de mevcut ürünlerden kategoriler toplanır

## Mobil/Web Uygulamasında Kullanım

### 1. CategoryFilterWidget (Chip Tasarımı)

```dart
import 'package:your_app/widgets/category_filter_widget.dart';

String? _selectedCategory;

CategoryFilterWidget(
  selectedCategory: _selectedCategory,
  onCategorySelected: (category) {
    setState(() {
      _selectedCategory = category; // 'Tümü' veya kategori adı
    });
    // Ürünleri filtrele
    _filterProductsByCategory(category);
  },
  products: _allProducts, // Opsiyonel: Ürünlerden kategori çıkarmak için
  showAllOption: true, // 'Tümü' seçeneğini göster
  horizontalScroll: true, // Yatay kaydırma
)
```

### 2. CategoryDropdownFilter (Dropdown Tasarımı)

```dart
import 'package:your_app/widgets/category_filter_widget.dart';

String? _selectedCategory;

CategoryDropdownFilter(
  selectedCategory: _selectedCategory,
  onCategorySelected: (category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterProductsByCategory(category);
  },
  products: _allProducts,
  showAllOption: true,
)
```

### 3. Ürün Filtreleme Örneği

```dart
List<Product> _allProducts = [];
List<Product> _filteredProducts = [];

void _filterProductsByCategory(String? category) {
  setState(() {
    if (category == null || category == 'Tümü') {
      _filteredProducts = _allProducts;
    } else {
      _filteredProducts = _allProducts.where((product) {
        return product.category == category;
      }).toList();
    }
  });
}
```

### 4. Tam Örnek: Ürün Listesi Sayfası

```dart
class ProductListPage extends StatefulWidget {
  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final AdminService _adminService = AdminService();
  List<AdminProduct> _allProducts = [];
  List<AdminProduct> _filteredProducts = [];
  String? _selectedCategory;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _adminService.getActiveProductsFromServer();
      setState(() {
        _allProducts = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterByCategory(String? category) {
    setState(() {
      _selectedCategory = category;
      if (category == null || category == 'Tümü') {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts.where((product) {
          return product.category == category;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ürünler'),
      ),
      body: Column(
        children: [
          // Kategori Filtreleme
          CategoryFilterWidget(
            selectedCategory: _selectedCategory,
            onCategorySelected: _filterByCategory,
            products: _allProducts,
            showAllOption: true,
            horizontalScroll: true,
          ),
          
          // Ürün Listesi
          Expanded(
            child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _filteredProducts.isEmpty
                ? Center(child: Text('Ürün bulunamadı'))
                : ListView.builder(
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return ListTile(
                        leading: Image.network(product.imageUrl),
                        title: Text(product.name),
                        subtitle: Text('₺${product.price.toStringAsFixed(2)}'),
                        trailing: Text(product.category),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
```

## Özellikler

✅ **Firestore Entegrasyonu**: Kategoriler otomatik olarak Firestore'dan çekilir  
✅ **Dinamik Liste**: Hem Firestore kategorileri hem de ürünlerden kategoriler gösterilir  
✅ **Responsive**: Hem mobil hem web için uyumlu  
✅ **İki Tasarım**: Chip (çip) ve Dropdown seçenekleri  
✅ **Kolay Kullanım**: Tek satır kod ile entegrasyon  

## Notlar

- Kategoriler Firestore'dan `getCategories()` metodu ile çekilir
- Sadece aktif kategoriler gösterilir (`isActive: true`)
- "Tümü" seçeneği opsiyoneldir (`showAllOption` parametresi ile kontrol edilir)
- Ürünlerden de kategoriler çıkarılabilir (geriye dönük uyumluluk için)

