import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'services/report_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:html' as html;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Gelişmiş raporlama sayfası
class WebAdminAdvancedReports extends StatefulWidget {
  const WebAdminAdvancedReports({super.key});

  @override
  State<WebAdminAdvancedReports> createState() => _WebAdminAdvancedReportsState();
}

class _WebAdminAdvancedReportsState extends State<WebAdminAdvancedReports> {
  final ReportService _reportService = ReportService();
  
  String _selectedReportType = 'financial'; // 'financial', 'sales', 'profit'
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  
  Map<String, dynamic>? _financialReport;
  Map<String, dynamic>? _salesReport;
  Map<String, dynamic>? _profitLossReport;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      if (_selectedReportType == 'financial') {
        _financialReport = await _reportService.getFinancialReport(
          startDate: _startDate,
          endDate: _endDate,
        );
      } else if (_selectedReportType == 'sales') {
        _salesReport = await _reportService.getSalesReport(
          startDate: _startDate,
          endDate: _endDate,
        );
      } else if (_selectedReportType == 'profit') {
        _profitLossReport = await _reportService.getProfitLossReport(
          startDate: _startDate,
          endDate: _endDate,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rapor yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Gelişmiş Raporlar'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            tooltip: 'Raporu İndir',
            onSelected: (value) {
              if (value == 'pdf') {
                _exportToPDF();
              } else if (value == 'excel') {
                _exportToExcel();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red),
                    SizedBox(width: 8),
                    Text('PDF Olarak İndir'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Excel (CSV) Olarak İndir'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Filtreler
          _buildFilters(),
          
          // Rapor içeriği
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildReportContent(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Rapor tipi seçimi
          Row(
            children: [
              const Text('Rapor Tipi:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'financial',
                      label: Text('Finansal'),
                      icon: Icon(Icons.account_balance),
                    ),
                    ButtonSegment(
                      value: 'sales',
                      label: Text('Satış'),
                      icon: Icon(Icons.trending_up),
                    ),
                    ButtonSegment(
                      value: 'profit',
                      label: Text('Kar/Zarar'),
                      icon: Icon(Icons.attach_money),
                    ),
                  ],
                  selected: {_selectedReportType},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedReportType = newSelection.first;
                    });
                    _loadReports();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Tarih filtreleri
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: const Text('Başlangıç Tarihi'),
                  subtitle: Text(
                    _startDate != null
                        ? DateFormat('dd.MM.yyyy').format(_startDate!)
                        : 'Tarih seçin',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _startDate = date);
                      _loadReports();
                    }
                  },
                ),
              ),
              Expanded(
                child: ListTile(
                  title: const Text('Bitiş Tarihi'),
                  subtitle: Text(
                    _endDate != null
                        ? DateFormat('dd.MM.yyyy').format(_endDate!)
                        : 'Tarih seçin',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: _startDate ?? DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _endDate = date);
                      _loadReports();
                    }
                  },
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                  _loadReports();
                },
                icon: const Icon(Icons.clear),
                label: const Text('Temizle'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    if (_selectedReportType == 'financial') {
      return _buildFinancialReport();
    } else if (_selectedReportType == 'sales') {
      return _buildSalesReport();
    } else if (_selectedReportType == 'profit') {
      return _buildProfitLossReport();
    }
    return const SizedBox();
  }

  Widget _buildFinancialReport() {
    if (_financialReport == null) {
      return const Center(child: Text('Rapor yükleniyor...'));
    }

    final revenue = _financialReport!['totalRevenue'] as double;
    final orders = _financialReport!['totalOrders'] as int;
    final avgOrderValue = _financialReport!['averageOrderValue'] as double;
    final revenueByStatus = _financialReport!['revenueByStatus'] as Map<String, double>;
    final monthlyRevenue = _financialReport!['monthlyRevenue'] as Map<String, double>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Özet kartlar
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Toplam Gelir',
                '₺${revenue.toStringAsFixed(2)}',
                Icons.account_balance_wallet,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Toplam Sipariş',
                orders.toString(),
                Icons.shopping_bag,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Ortalama Sipariş',
                '₺${avgOrderValue.toStringAsFixed(2)}',
                Icons.trending_up,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Aylık gelir grafiği
        _buildMonthlyRevenueChart(monthlyRevenue),
        const SizedBox(height: 24),
        
        // Durum bazlı gelir
        _buildRevenueByStatus(revenueByStatus),
      ],
    );
  }

  Widget _buildSalesReport() {
    if (_salesReport == null) {
      return const Center(child: Text('Rapor yükleniyor...'));
    }

    final categorySales = _salesReport!['categorySales'] as Map<String, dynamic>;
    final topProducts = _salesReport!['topProducts'] as List<dynamic>;
    final trendData = _salesReport!['trendData'] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kategori bazlı satış
        _buildCategorySalesChart(categorySales),
        const SizedBox(height: 24),
        
        // Trend analizi
        _buildTrendChart(trendData),
        const SizedBox(height: 24),
        
        // En çok satan ürünler
        _buildTopProductsList(topProducts),
      ],
    );
  }

  Widget _buildProfitLossReport() {
    if (_profitLossReport == null) {
      return const Center(child: Text('Rapor yükleniyor...'));
    }

    final revenue = _profitLossReport!['revenue'] as double;
    final costs = _profitLossReport!['estimatedCosts'] as double;
    final profit = _profitLossReport!['netProfit'] as double;
    final margin = _profitLossReport!['profitMargin'] as double;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kar/Zarar özeti
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Toplam Gelir',
                '₺${revenue.toStringAsFixed(2)}',
                Icons.arrow_upward,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Tahmini Giderler',
                '₺${costs.toStringAsFixed(2)}',
                Icons.arrow_downward,
                Colors.red,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Net Kar',
                '₺${profit.toStringAsFixed(2)}',
                Icons.account_balance,
                profit >= 0 ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Kar Marjı',
                '%${margin.toStringAsFixed(2)}',
                Icons.percent,
                margin >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Kar/Zarar grafiği
        _buildProfitLossChart(revenue, costs, profit),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyRevenueChart(Map<String, double> monthlyRevenue) {
    if (monthlyRevenue.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('Veri bulunamadı')),
        ),
      );
    }

    final sortedMonths = monthlyRevenue.keys.toList()..sort();
    final spots = sortedMonths.asMap().entries.map((entry) {
      final index = entry.key;
      final monthKey = entry.value;
      final revenue = monthlyRevenue[monthKey]!;
      return FlSpot(index.toDouble(), revenue);
    }).toList();

    final maxY = spots.isEmpty ? 1000.0 : spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aylık Gelir Trendi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                          if (value.toInt() < sortedMonths.length) {
                            final monthKey = sortedMonths[value.toInt()];
                            final parts = monthKey.split('-');
                            return Text('${parts[1]}/${parts[0].substring(2)}');
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: const Color(0xFF10B981),
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF10B981).withOpacity(0.1),
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

  Widget _buildRevenueByStatus(Map<String, double> revenueByStatus) {
    if (revenueByStatus.isEmpty) {
      return const SizedBox();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Durum Bazlı Gelir',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...revenueByStatus.entries.map((entry) {
              final statusText = _getStatusText(entry.key);
              return ListTile(
                leading: Icon(_getStatusIcon(entry.key), color: _getStatusColor(entry.key)),
                title: Text(statusText),
                trailing: Text(
                  '₺${entry.value.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySalesChart(Map<String, dynamic> categorySales) {
    if (categorySales.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('Veri bulunamadı')),
        ),
      );
    }

    final sortedCategories = categorySales.entries.toList()
      ..sort((a, b) => (b.value['revenue'] as double).compareTo(a.value['revenue'] as double));
    final topCategories = sortedCategories.take(5).toList();
    final total = categorySales.values.fold<double>(
      0.0,
      (sum, val) => sum + (val['revenue'] as double),
    );

    return Card(
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
                        final categoryEntry = entry.value;
                        final categoryData = categoryEntry.value as Map<String, dynamic>;
                        final percentage = ((categoryData['revenue'] as double) / total * 100);
                        final colors = [
                          const Color(0xFF6366F1),
                          const Color(0xFF8B5CF6),
                          const Color(0xFF10B981),
                          const Color(0xFFF59E0B),
                          const Color(0xFFEF4444),
                        ];
                        return PieChartSectionData(
                          value: categoryData['revenue'] as double,
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
                      final categoryEntry = entry.value;
                      final categoryKey = categoryEntry.key;
                      final categoryData = categoryEntry.value as Map<String, dynamic>;
                      final percentage = ((categoryData['revenue'] as double) / total * 100);
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
                                categoryKey,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '₺${(categoryData['revenue'] as double).toStringAsFixed(0)}',
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

  Widget _buildTrendChart(Map<String, dynamic> trendData) {
    if (trendData.isEmpty) {
      return const SizedBox();
    }

    final sortedMonths = trendData.keys.toList()..sort();
    final revenueSpots = sortedMonths.asMap().entries.map((entry) {
      final index = entry.key;
      final monthKey = entry.value;
      final data = trendData[monthKey] as Map<String, dynamic>;
      final revenue = data['revenue'] as double;
      return FlSpot(index.toDouble(), revenue);
    }).toList();

    final maxY = revenueSpots.isEmpty 
        ? 1000.0 
        : revenueSpots.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Satış Trendi (Son 6 Ay)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                          if (value.toInt() < sortedMonths.length) {
                            final monthKey = sortedMonths[value.toInt()];
                            final parts = monthKey.split('-');
                            return Text('${parts[1]}/${parts[0].substring(2)}');
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: revenueSpots,
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

  Widget _buildTopProductsList(List<dynamic> topProducts) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'En Çok Satan Ürünler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topProducts.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final product = topProducts[index] as Map<String, dynamic>;
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
                    'Kategori: ${product['category']} | Adet: ${product['quantity']}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₺${(product['revenue'] as double).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      Text(
                        '${product['orders']} sipariş',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitLossChart(double revenue, double costs, double profit) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gelir/Gider/Kar Analizi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
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
                          switch (value.toInt()) {
                            case 0:
                              return const Text('Gelir');
                            case 1:
                              return const Text('Gider');
                            case 2:
                              return const Text('Net Kar');
                            default:
                              return const Text('');
                          }
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: revenue,
                          color: const Color(0xFF10B981),
                          width: 40,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: costs,
                          color: const Color(0xFFEF4444),
                          width: 40,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: profit,
                          color: profit >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          width: 40,
                        ),
                      ],
                    ),
                  ],
                  maxY: [revenue, costs, profit.abs()].reduce((a, b) => a > b ? a : b) * 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Beklemede';
      case 'confirmed':
        return 'Onaylandı';
      case 'shipped':
        return 'Kargoya Verildi';
      case 'delivered':
        return 'Teslim Edildi';
      case 'cancelled':
        return 'İptal Edildi';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'confirmed':
        return Icons.check_circle;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _exportToPDF() async {
    try {
      setState(() => _isLoading = true);

      final pdf = pw.Document();
      final now = DateTime.now();
      final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(now);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            final pages = <pw.Widget>[];

            // Başlık
            pages.add(
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Gelişmiş Rapor - ${_getReportTypeName()}',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            );
            pages.add(pw.SizedBox(height: 10));
            pages.add(
              pw.Text(
                'Rapor Tarihi: $dateStr',
                style: const pw.TextStyle(fontSize: 12),
              ),
            );
            if (_startDate != null || _endDate != null) {
              pages.add(
                pw.Text(
                  'Tarih Aralığı: ${_startDate != null ? DateFormat('dd.MM.yyyy').format(_startDate!) : 'Başlangıç'} - ${_endDate != null ? DateFormat('dd.MM.yyyy').format(_endDate!) : 'Bitiş'}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              );
            }
            pages.add(pw.SizedBox(height: 30));

            if (_selectedReportType == 'financial' && _financialReport != null) {
              pages.addAll(_buildFinancialReportPDF(_financialReport!));
            } else if (_selectedReportType == 'sales' && _salesReport != null) {
              pages.addAll(_buildSalesReportPDF(_salesReport!));
            } else if (_selectedReportType == 'profit' && _profitLossReport != null) {
              pages.addAll(_buildProfitLossReportPDF(_profitLossReport!));
            }

            return pages;
          },
        ),
      );

      final bytes = await pdf.save();

      if (kIsWeb) {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', 'gelismis_rapor_${_selectedReportType}_${DateTime.now().millisecondsSinceEpoch}.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF raporu başarıyla indirildi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF oluşturulurken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<pw.Widget> _buildFinancialReportPDF(Map<String, dynamic> report) {
    final pages = <pw.Widget>[];
    final revenue = report['totalRevenue'] as double;
    final orders = report['totalOrders'] as int;
    final avgOrderValue = report['averageOrderValue'] as double;

    pages.add(
      pw.Text(
        'Özet İstatistikler',
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
    pages.add(pw.SizedBox(height: 10));
    pages.add(
      pw.Table(
        border: pw.TableBorder.all(),
        children: [
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Toplam Gelir', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('₺${revenue.toStringAsFixed(2)}'),
              ),
            ],
          ),
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Toplam Sipariş', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(orders.toString()),
              ),
            ],
          ),
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Ortalama Sipariş Değeri', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('₺${avgOrderValue.toStringAsFixed(2)}'),
              ),
            ],
          ),
        ],
      ),
    );

    return pages;
  }

  List<pw.Widget> _buildSalesReportPDF(Map<String, dynamic> report) {
    final pages = <pw.Widget>[];
    final categorySales = report['categorySales'] as Map<String, dynamic>;
    final topProducts = report['topProducts'] as List<dynamic>;

    pages.add(
      pw.Text(
        'Kategori Bazlı Satış',
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
    pages.add(pw.SizedBox(height: 10));
    pages.add(
      pw.Table(
        border: pw.TableBorder.all(),
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(1),
          2: const pw.FlexColumnWidth(1),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey300),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Kategori', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Gelir', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Adet', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
            ],
          ),
          ...categorySales.entries.map((entry) {
            final data = entry.value as Map<String, dynamic>;
            return pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(entry.key),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('₺${(data['revenue'] as double).toStringAsFixed(2)}'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text((data['quantity'] as int).toString()),
                ),
              ],
            );
          }),
        ],
      ),
    );

    pages.add(pw.SizedBox(height: 30));
    pages.add(
      pw.Text(
        'En Çok Satan Ürünler',
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
    pages.add(pw.SizedBox(height: 10));
    pages.add(
      pw.Table(
        border: pw.TableBorder.all(),
        columnWidths: {
          0: const pw.FlexColumnWidth(3),
          1: const pw.FlexColumnWidth(1),
          2: const pw.FlexColumnWidth(1),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey300),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Ürün Adı', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Gelir', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Adet', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
            ],
          ),
          ...topProducts.take(20).map((product) {
            final p = product as Map<String, dynamic>;
            return pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(p['name'] as String),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('₺${(p['revenue'] as double).toStringAsFixed(2)}'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text((p['quantity'] as int).toString()),
                ),
              ],
            );
          }),
        ],
      ),
    );

    return pages;
  }

  List<pw.Widget> _buildProfitLossReportPDF(Map<String, dynamic> report) {
    final pages = <pw.Widget>[];
    final revenue = report['revenue'] as double;
    final costs = report['estimatedCosts'] as double;
    final profit = report['netProfit'] as double;
    final margin = report['profitMargin'] as double;

    pages.add(
      pw.Text(
        'Kar/Zarar Analizi',
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
    pages.add(pw.SizedBox(height: 10));
    pages.add(
      pw.Table(
        border: pw.TableBorder.all(),
        children: [
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Toplam Gelir', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('₺${revenue.toStringAsFixed(2)}'),
              ),
            ],
          ),
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Tahmini Giderler', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('₺${costs.toStringAsFixed(2)}'),
              ),
            ],
          ),
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Net Kar', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  '₺${profit.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    color: profit >= 0 ? PdfColors.green : PdfColors.red,
                  ),
                ),
              ),
            ],
          ),
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Kar Marjı', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  '%${margin.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    color: margin >= 0 ? PdfColors.green : PdfColors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return pages;
  }

  String _getReportTypeName() {
    switch (_selectedReportType) {
      case 'financial':
        return 'Finansal Rapor';
      case 'sales':
        return 'Satış Raporu';
      case 'profit':
        return 'Kar/Zarar Raporu';
      default:
        return 'Rapor';
    }
  }

  Future<void> _exportToExcel() async {
    try {
      setState(() => _isLoading = true);

      final csv = StringBuffer();
      final now = DateTime.now();
      final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(now);

      csv.writeln('Gelişmiş Rapor - ${_getReportTypeName()}');
      csv.writeln('Rapor Tarihi: $dateStr');
      if (_startDate != null || _endDate != null) {
        csv.writeln('Tarih Aralığı: ${_startDate != null ? DateFormat('dd.MM.yyyy').format(_startDate!) : 'Başlangıç'} - ${_endDate != null ? DateFormat('dd.MM.yyyy').format(_endDate!) : 'Bitiş'}');
      }
      csv.writeln('');

      if (_selectedReportType == 'financial' && _financialReport != null) {
        _buildFinancialReportCSV(_financialReport!, csv);
      } else if (_selectedReportType == 'sales' && _salesReport != null) {
        _buildSalesReportCSV(_salesReport!, csv);
      } else if (_selectedReportType == 'profit' && _profitLossReport != null) {
        _buildProfitLossReportCSV(_profitLossReport!, csv);
      }

      if (kIsWeb) {
        final blob = html.Blob([utf8.encode(csv.toString())], 'text/csv');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', 'gelismis_rapor_${_selectedReportType}_${DateTime.now().millisecondsSinceEpoch}.csv')
          ..click();
        html.Url.revokeObjectUrl(url);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Excel (CSV) raporu başarıyla indirildi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel oluşturulurken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _buildFinancialReportCSV(Map<String, dynamic> report, StringBuffer csv) {
    final revenue = report['totalRevenue'] as double;
    final orders = report['totalOrders'] as int;
    final avgOrderValue = report['averageOrderValue'] as double;
    final revenueByStatus = report['revenueByStatus'] as Map<String, double>;

    csv.writeln('Özet İstatistikler');
    csv.writeln('Toplam Gelir,₺${revenue.toStringAsFixed(2)}');
    csv.writeln('Toplam Sipariş,$orders');
    csv.writeln('Ortalama Sipariş Değeri,₺${avgOrderValue.toStringAsFixed(2)}');
    csv.writeln('');
    csv.writeln('Durum Bazlı Gelir');
    csv.writeln('Durum,Gelir');
    revenueByStatus.forEach((status, amount) {
      csv.writeln('${_getStatusText(status)},₺${amount.toStringAsFixed(2)}');
    });
  }

  void _buildSalesReportCSV(Map<String, dynamic> report, StringBuffer csv) {
    final categorySales = report['categorySales'] as Map<String, dynamic>;
    final topProducts = report['topProducts'] as List<dynamic>;

    csv.writeln('Kategori Bazlı Satış');
    csv.writeln('Kategori,Gelir,Adet,Sipariş Sayısı');
    categorySales.forEach((category, data) {
      final d = data as Map<String, dynamic>;
      csv.writeln('"$category",₺${(d['revenue'] as double).toStringAsFixed(2)},${d['quantity']},${d['orders']}');
    });
    csv.writeln('');
    csv.writeln('En Çok Satan Ürünler');
    csv.writeln('Ürün Adı,Kategori,Gelir,Adet,Sipariş Sayısı');
    for (final product in topProducts.take(50)) {
      final p = product as Map<String, dynamic>;
      csv.writeln('"${p['name']}","${p['category']}",₺${(p['revenue'] as double).toStringAsFixed(2)},${p['quantity']},${p['orders']}');
    }
  }

  void _buildProfitLossReportCSV(Map<String, dynamic> report, StringBuffer csv) {
    final revenue = report['revenue'] as double;
    final costs = report['estimatedCosts'] as double;
    final profit = report['netProfit'] as double;
    final margin = report['profitMargin'] as double;

    csv.writeln('Kar/Zarar Analizi');
    csv.writeln('Kalem,Tutar');
    csv.writeln('Toplam Gelir,₺${revenue.toStringAsFixed(2)}');
    csv.writeln('Tahmini Giderler,₺${costs.toStringAsFixed(2)}');
    csv.writeln('Net Kar,₺${profit.toStringAsFixed(2)}');
    csv.writeln('Kar Marjı,%${margin.toStringAsFixed(2)}');
  }
}

