import 'package:flutter/material.dart';
import 'dart:math';
import '../model/admin_product.dart';
import '../services/admin_service.dart';

class DashboardAnalyticsWidget extends StatefulWidget {
  const DashboardAnalyticsWidget({super.key});

  @override
  State<DashboardAnalyticsWidget> createState() => _DashboardAnalyticsWidgetState();
}

class _DashboardAnalyticsWidgetState extends State<DashboardAnalyticsWidget> {
  final AdminService _adminService = AdminService();
  String _selectedPeriod = 'Son 7 Gün';
  String _selectedMetric = 'Satış';

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Gelişmiş Analitik',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[800],
                  ),
                ),
                Spacer(),
                DropdownButton<String>(
                  value: _selectedPeriod,
                  items: const [
                    DropdownMenuItem(value: 'Son 7 Gün', child: Text('Son 7 Gün')),
                    DropdownMenuItem(value: 'Son 30 Gün', child: Text('Son 30 Gün')),
                    DropdownMenuItem(value: 'Son 3 Ay', child: Text('Son 3 Ay')),
                    DropdownMenuItem(value: 'Son 1 Yıl', child: Text('Son 1 Yıl')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedPeriod = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Metrik seçimi
            Row(
              children: [
                _buildMetricButton('Satış', Icons.trending_up, Colors.green),
                SizedBox(width: 8),
                _buildMetricButton('Stok', Icons.inventory, Colors.blue),
                SizedBox(width: 8),
                _buildMetricButton('Kategori', Icons.category, Colors.orange),
                SizedBox(width: 8),
                _buildMetricButton('Fiyat', Icons.attach_money, Colors.purple),
              ],
            ),
            const SizedBox(height: 16),
            
            // Analitik grafik
            Container(
              height: 200,
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
                  return _buildAnalyticsChart(products);
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Hızlı istatistikler
            StreamBuilder<List<AdminProduct>>(
              stream: _adminService.getProducts(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final products = snapshot.data!;
                  return Row(
                    children: [
                      Expanded(child: _buildQuickStat('Toplam Değer', '₺${_calculateTotalValue(products)}', Colors.green)),
                      SizedBox(width: 8),
                      Expanded(child: _buildQuickStat('Ortalama Fiyat', '₺${_calculateAveragePrice(products)}', Colors.blue)),
                      SizedBox(width: 8),
                      Expanded(child: _buildQuickStat('Düşük Stok', '${_countLowStock(products)}', Colors.orange)),
                    ],
                  );
                }
                return SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricButton(String label, IconData icon, Color color) {
    final isSelected = _selectedMetric == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMetric = label;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : color),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsChart(List<AdminProduct> products) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 48, color: Colors.grey[400]),
            SizedBox(height: 8),
            Text('Veri bulunamadı', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Grafik başlığı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_selectedMetric Analizi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  _selectedPeriod,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            
            // Grafik alanı
            Expanded(
              child: _buildChart(products),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<AdminProduct> products) {
    switch (_selectedMetric) {
      case 'Satış':
        return _buildLineChart(products);
      case 'Stok':
        return _buildBarChart(products);
      case 'Kategori':
        return _buildPieChart(products);
      case 'Fiyat':
        return _buildLineChart(products);
      default:
        return _buildBarChart(products);
    }
  }

  Widget _buildLineChart(List<AdminProduct> products) {
    return CustomPaint(
      painter: LineChartPainter(products, _selectedMetric),
      size: Size.infinite,
    );
  }

  Widget _buildBarChart(List<AdminProduct> products) {
    return CustomPaint(
      painter: BarChartPainter(products, _selectedMetric),
      size: Size.infinite,
    );
  }

  Widget _buildPieChart(List<AdminProduct> products) {
    return CustomPaint(
      painter: PieChartPainter(products),
      size: Size.infinite,
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _calculateTotalValue(List<AdminProduct> products) {
    final total = products.fold(0.0, (sum, product) => sum + (product.price * product.stock));
    return total.toStringAsFixed(0);
  }

  String _calculateAveragePrice(List<AdminProduct> products) {
    if (products.isEmpty) return '0';
    final average = products.fold(0.0, (sum, product) => sum + product.price) / products.length;
    return average.toStringAsFixed(0);
  }

  int _countLowStock(List<AdminProduct> products) {
    return products.where((product) => product.stock <= 10).length;
  }
}

// Çizgi Grafik Painter
class LineChartPainter extends CustomPainter {
  final List<AdminProduct> products;
  final String metric;

  LineChartPainter(this.products, this.metric);

  @override
  void paint(Canvas canvas, Size size) {
    if (products.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (products.length - 1);
    double maxValue = _getMaxValue();

    for (int i = 0; i < products.length; i++) {
      final product = products[i];
      final value = _getValue(product);
      final x = i * stepX;
      final y = size.height - (value / maxValue) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Noktalar
    final dotPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    for (int i = 0; i < products.length; i++) {
      final product = products[i];
      final value = _getValue(product);
      final x = i * stepX;
      final y = size.height - (value / maxValue) * size.height;

      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
  }

  double _getValue(AdminProduct product) {
    switch (metric) {
      case 'Satış':
        return product.stock.toDouble();
      case 'Fiyat':
        return product.price;
      default:
        return product.stock.toDouble();
    }
  }

  double _getMaxValue() {
    switch (metric) {
      case 'Satış':
        return products.fold(0.0, (max, product) => max > product.stock ? max : product.stock.toDouble());
      case 'Fiyat':
        return products.fold(0.0, (max, product) => max > product.price ? max : product.price);
      default:
        return products.fold(0.0, (max, product) => max > product.stock ? max : product.stock.toDouble());
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Bar Grafik Painter
class BarChartPainter extends CustomPainter {
  final List<AdminProduct> products;
  final String metric;

  BarChartPainter(this.products, this.metric);

  @override
  void paint(Canvas canvas, Size size) {
    if (products.isEmpty) return;

    final barWidth = size.width / products.length * 0.8;
    final spacing = size.width / products.length * 0.2;
    double maxValue = _getMaxValue();

    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red];

    for (int i = 0; i < products.length; i++) {
      final product = products[i];
      final value = _getValue(product);
      final height = (value / maxValue) * size.height;

      final x = i * (barWidth + spacing) + spacing / 2;
      final y = size.height - height;

      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(x, y, barWidth, height),
        paint,
      );

      // Değer etiketi
      final textPainter = TextPainter(
        text: TextSpan(
          text: value.toStringAsFixed(0),
          style: TextStyle(color: Colors.black, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + barWidth / 2 - textPainter.width / 2, y - 15),
      );
    }
  }

  double _getValue(AdminProduct product) {
    switch (metric) {
      case 'Stok':
        return product.stock.toDouble();
      default:
        return product.stock.toDouble();
    }
  }

  double _getMaxValue() {
    return products.fold(0.0, (max, product) => max > product.stock ? max : product.stock.toDouble());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Pasta Grafik Painter
class PieChartPainter extends CustomPainter {
  final List<AdminProduct> products;

  PieChartPainter(this.products);

  @override
  void paint(Canvas canvas, Size size) {
    if (products.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width < size.height ? size.width : size.height) / 2 - 20;

    // Kategori bazında grupla
    final categoryData = <String, double>{};
    for (final product in products) {
      categoryData[product.category] = (categoryData[product.category] ?? 0) + product.stock.toDouble();
    }

    final total = categoryData.values.fold(0.0, (sum, value) => sum + value);
    if (total == 0) return;

    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal];
    double startAngle = -90 * (3.14159 / 180); // -90 derece

    int colorIndex = 0;
    for (final entry in categoryData.entries) {
      final sweepAngle = (entry.value / total) * 2 * 3.14159;
      
      final paint = Paint()
        ..color = colors[colorIndex % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Etiket çizgisi
      final labelAngle = startAngle + sweepAngle / 2;
      final labelX = center.dx + (radius + 20) * cos(labelAngle);
      final labelY = center.dy + (radius + 20) * sin(labelAngle);

      final linePaint = Paint()
        ..color = colors[colorIndex % colors.length]
        ..strokeWidth = 2;

      canvas.drawLine(
        Offset(center.dx + radius * cos(labelAngle), center.dy + radius * sin(labelAngle)),
        Offset(labelX, labelY),
        linePaint,
      );

      // Kategori adı
      final textPainter = TextPainter(
        text: TextSpan(
          text: entry.key,
          style: TextStyle(color: Colors.black, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(labelX - textPainter.width / 2, labelY - textPainter.height / 2),
      );

      startAngle += sweepAngle;
      colorIndex++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
