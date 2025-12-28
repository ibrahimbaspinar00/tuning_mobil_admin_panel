import 'package:flutter/material.dart';
import 'services/admin_service.dart';
import 'utils/responsive_helper.dart';
import 'widgets/optimized_image.dart';

class WebAdminProductAnalytics extends StatefulWidget {
  const WebAdminProductAnalytics({super.key});

  @override
  State<WebAdminProductAnalytics> createState() => _WebAdminProductAnalyticsState();
}

class _WebAdminProductAnalyticsState extends State<WebAdminProductAnalytics> with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  late TabController _tabController;
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _topSellingProducts = [];
  List<Map<String, dynamic>> _mostFavoritedProducts = [];
  List<Map<String, dynamic>> _mostAddedToCartProducts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _adminService.getTopSellingProducts(limit: 50),
        _adminService.getMostFavoritedProducts(limit: 50),
        _adminService.getMostAddedToCartProducts(limit: 50),
      ]);

      setState(() {
        _topSellingProducts = results[0];
        _mostFavoritedProducts = results[1];
        _mostAddedToCartProducts = results[2];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Ürün analitikleri yüklenirken hata: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veriler yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ürün Analitikleri',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'En çok satan, favorilenen ve sepete eklenen ürünleri görüntüleyin',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!ResponsiveHelper.isMobile(context))
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: _loadData,
                    tooltip: 'Yenile',
                  ),
              ],
            ),
          ),

          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF6366F1),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF6366F1),
              indicatorWeight: 3,
              tabs: const [
                Tab(
                  icon: Icon(Icons.trending_up_rounded),
                  text: 'En Çok Satan',
                ),
                Tab(
                  icon: Icon(Icons.favorite_rounded),
                  text: 'En Çok Favorilenen',
                ),
                Tab(
                  icon: Icon(Icons.shopping_cart_rounded),
                  text: 'En Çok Sepete Eklenen',
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTopSellingProducts(),
                      _buildMostFavoritedProducts(),
                      _buildMostAddedToCartProducts(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSellingProducts() {
    if (_topSellingProducts.isEmpty) {
      return _buildEmptyState(
        'Satış verisi bulunamadı',
        'Henüz hiçbir sipariş verilmemiş. Siparişler oluşturuldukça bu liste dolacaktır.',
      );
    }

    return _buildProductList(
      _topSellingProducts,
      (product) => [
        _buildStatItem(
          Icons.shopping_bag_rounded,
          'Satış',
          '${product['quantity']} adet',
          const Color(0xFF10B981),
        ),
        _buildStatItem(
          Icons.attach_money_rounded,
          'Gelir',
          '₺${(product['revenue'] as double).toStringAsFixed(2)}',
          const Color(0xFF3B82F6),
        ),
      ],
    );
  }

  Widget _buildMostFavoritedProducts() {
    if (_mostFavoritedProducts.isEmpty) {
      return _buildEmptyState(
        'Favori verisi bulunamadı',
        'Henüz hiçbir ürün favorilere eklenmemiş. Mobil uygulamadan ürünleri favorilere ekleyerek bu listeyi oluşturabilirsiniz.',
      );
    }

    return _buildProductList(
      _mostFavoritedProducts,
      (product) => [
        _buildStatItem(
          Icons.favorite_rounded,
          'Favori',
          '${product['favoriteCount']} kez',
          const Color(0xFFEF4444),
        ),
      ],
    );
  }

  Widget _buildMostAddedToCartProducts() {
    if (_mostAddedToCartProducts.isEmpty) {
      return _buildEmptyState(
        'Sepet verisi bulunamadı',
        'Henüz hiçbir ürün sepete eklenmemiş. Mobil uygulamadan ürünleri sepete ekleyerek bu listeyi oluşturabilirsiniz.',
      );
    }

    return _buildProductList(
      _mostAddedToCartProducts,
      (product) => [
        _buildStatItem(
          Icons.shopping_cart_rounded,
          'Sepete Ekleme',
          '${product['cartAddCount']} kez',
          const Color(0xFF8B5CF6),
        ),
        _buildStatItem(
          Icons.inventory_2_rounded,
          'Toplam Miktar',
          '${product['totalCartQuantity']} adet',
          const Color(0xFFF59E0B),
        ),
      ],
    );
  }

  Widget _buildProductList(
    List<Map<String, dynamic>> products,
    List<Widget> Function(Map<String, dynamic>) buildStats,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final rank = index + 1;
        
        return _buildProductCard(product, rank, buildStats(product));
      },
    );
  }

  Widget _buildProductCard(
    Map<String, dynamic> product,
    int rank,
    List<Widget> stats,
  ) {
    final imageUrl = product['productImage'] as String? ?? '';
    final productName = product['productName'] as String? ?? 'Bilinmeyen Ürün';
    final productPrice = (product['productPrice'] as num?)?.toDouble() ?? 0.0;
    final productCategory = product['productCategory'] as String? ?? 'Kategori Yok';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Ürün detayına git (isteğe bağlı)
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Rank
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: rank <= 3
                        ? const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                          )
                        : null,
                    color: rank <= 3 ? null : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: rank <= 3 ? Colors.white : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: OptimizedImage(
                    imageUrl: imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_rounded, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.category_rounded, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            productCategory,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '₺${productPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: stats,
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

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, [String? subtitle]) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

