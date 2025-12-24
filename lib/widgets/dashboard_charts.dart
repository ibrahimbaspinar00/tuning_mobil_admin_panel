import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../model/order.dart' as OrderModel;
import '../model/admin_product.dart';
import '../services/admin_service.dart';

/// Dashboard için gelişmiş grafikler ve analizler
class DashboardCharts extends StatefulWidget {
  const DashboardCharts({super.key});

  @override
  State<DashboardCharts> createState() => _DashboardChartsState();
}

class _DashboardChartsState extends State<DashboardCharts> {
  final AdminService _adminService = AdminService();
  String _selectedPeriod = 'month'; // 'day', 'week', 'month'
  bool _isLoading = true;
  
  List<OrderModel.Order> _orders = [];
  List<AdminProduct> _products = [];
  Map<String, double> _categorySales = {};
  List<Map<String, dynamic>> _topProducts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _adminService.getOrders().first;
      final products = await _adminService.getProductsFromServer();
      
      setState(() {
        _orders = orders;
        _products = products;
        _calculateStats();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Dashboard verileri yüklenirken hata: $e');
      setState(() => _isLoading = false);
    }
  }

  void _calculateStats() {
    // Kategori bazlı satış analizi
    _categorySales = {};
    for (final order in _orders) {
      for (final product in order.products) {
        final productData = _products.firstWhere(
          (p) => p.id == product.id,
          orElse: () => AdminProduct(
            id: '',
            name: product.name,
            description: '',
            price: product.price,
            stock: 0,
            category: '',
            imageUrl: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        final category = productData.category.isEmpty ? 'Kategori Yok' : productData.category;
        _categorySales[category] = (_categorySales[category] ?? 0) + (product.price * product.quantity);
      }
    }

    // En çok satılan ürünler
    final productSales = <String, Map<String, dynamic>>{};
    for (final order in _orders) {
      for (final product in order.products) {
        if (!productSales.containsKey(product.id)) {
          productSales[product.id] = {
            'name': product.name,
            'quantity': 0,
            'revenue': 0.0,
          };
        }
        productSales[product.id]!['quantity'] = 
            (productSales[product.id]!['quantity'] as int) + product.quantity;
        productSales[product.id]!['revenue'] = 
            (productSales[product.id]!['revenue'] as double) + (product.price * product.quantity);
      }
    }
    
    _topProducts = productSales.values.toList()
      ..sort((a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int));
    _topProducts = _topProducts.take(10).toList();
  }

  List<FlSpot> _getSalesData() {
    final now = DateTime.now();
    final data = <FlSpot>[];
    
    if (_selectedPeriod == 'day') {
      // Son 7 gün
      for (int i = 6; i >= 0; i--) {
        final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        final dayOrders = _orders.where((o) => 
          o.orderDate.year == date.year &&
          o.orderDate.month == date.month &&
          o.orderDate.day == date.day
        ).toList();
        final revenue = dayOrders.fold(0.0, (sum, o) => sum + o.totalAmount);
        data.add(FlSpot(i.toDouble(), revenue));
      }
    } else if (_selectedPeriod == 'week') {
      // Son 4 hafta
      for (int i = 3; i >= 0; i--) {
        final weekStart = now.subtract(Duration(days: i * 7));
        final weekEnd = weekStart.add(const Duration(days: 6));
        final weekOrders = _orders.where((o) => 
          o.orderDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
          o.orderDate.isBefore(weekEnd.add(const Duration(days: 1)))
        ).toList();
        final revenue = weekOrders.fold(0.0, (sum, o) => sum + o.totalAmount);
        data.add(FlSpot(i.toDouble(), revenue));
      }
    } else {
      // Son 6 ay
      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final monthEnd = DateTime(now.year, now.month - i + 1, 0);
        final monthOrders = _orders.where((o) => 
          o.orderDate.isAfter(month.subtract(const Duration(days: 1))) &&
          o.orderDate.isBefore(monthEnd.add(const Duration(days: 1)))
        ).toList();
        final revenue = monthOrders.fold(0.0, (sum, o) => sum + o.totalAmount);
        data.add(FlSpot(i.toDouble(), revenue));
      }
    }
    
    return data;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period selector
          Row(
            children: [
              const Text(
                'Satış Grafikleri',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'day', label: Text('Günlük')),
                  ButtonSegment(value: 'week', label: Text('Haftalık')),
                  ButtonSegment(value: 'month', label: Text('Aylık')),
                ],
                selected: {_selectedPeriod},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _selectedPeriod = newSelection.first;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Sales Line Chart
          _buildSalesChart(),
          const SizedBox(height: 32),
          
          // Category Sales Pie Chart
          _buildCategoryChart(),
          const SizedBox(height: 32),
          
          // Top Products List
          _buildTopProductsList(),
        ],
      ),
    );
  }

  Widget _buildSalesChart() {
    final salesData = _getSalesData();
    final maxY = salesData.isEmpty ? 1000.0 : salesData.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.2;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedPeriod == 'day' ? 'Son 7 Günlük Satış' :
              _selectedPeriod == 'week' ? 'Son 4 Haftalık Satış' :
              'Son 6 Aylık Satış',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text('₺${value.toInt()}');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (_selectedPeriod == 'day') {
                            final date = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
                            return Text('${date.day}/${date.month}');
                          } else if (_selectedPeriod == 'week') {
                            return Text('H${value.toInt() + 1}');
                          } else {
                            final month = DateTime.now().month - (5 - value.toInt());
                            final monthNames = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
                            return Text(monthNames[(month.clamp(1, 12) - 1) % 12]);
                          }
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: salesData,
                      isCurved: true,
                      color: const Color(0xFF6366F1),
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                      ),
                    ),
                  ],
                  minY: 0,
                  maxY: maxY,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart() {
    if (_categorySales.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Kategori satış verisi bulunamadı',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    final sortedCategories = _categorySales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedCategories.take(5).toList();
    final total = _categorySales.values.fold(0.0, (sum, val) => sum + val);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kategori Bazlı Satış Analizi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: topCategories.asMap().entries.map((entry) {
                        final index = entry.key;
                        final category = entry.value;
                        final percentage = (category.value / total * 100);
                        final colors = [
                          const Color(0xFF6366F1),
                          const Color(0xFF8B5CF6),
                          const Color(0xFF10B981),
                          const Color(0xFFF59E0B),
                          const Color(0xFFEF4444),
                        ];
                        return PieChartSectionData(
                          value: category.value,
                          title: '${percentage.toStringAsFixed(1)}%',
                          color: colors[index % colors.length],
                          radius: 80,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: topCategories.asMap().entries.map((entry) {
                      final index = entry.key;
                      final category = entry.value;
                      final percentage = (category.value / total * 100);
                      final colors = [
                        const Color(0xFF6366F1),
                        const Color(0xFF8B5CF6),
                        const Color(0xFF10B981),
                        const Color(0xFFF59E0B),
                        const Color(0xFFEF4444),
                      ];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: colors[index % colors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                category.key,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '₺${category.value.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${percentage.toStringAsFixed(1)}%)',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsList() {
    if (_topProducts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Ürün satış verisi bulunamadı',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'En Çok Satılan Ürünler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _topProducts.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final product = _topProducts[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    product['name'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    '${product['quantity']} adet satıldı',
                  ),
                  trailing: Text(
                    '₺${(product['revenue'] as double).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

