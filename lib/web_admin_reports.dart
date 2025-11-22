import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'model/admin_product.dart';
import 'model/order.dart' as OrderModel;
import 'services/admin_service.dart';

// Web için html import (sadece web'de çalışır)
import 'dart:html' as html;

class WebAdminReports extends StatefulWidget {
  const WebAdminReports({super.key});

  @override
  State<WebAdminReports> createState() => _WebAdminReportsState();
}

class _WebAdminReportsState extends State<WebAdminReports> {
  final AdminService _adminService = AdminService();
  List<AdminProduct> _products = [];
  List<OrderModel.Order> _orders = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final products = await _adminService.getProducts().first;
      final orders = await _adminService.getOrders().first;
      if (mounted) {
        setState(() {
          _products = products;
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veriler yüklenirken hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Raporlar'),
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
        body: _isLoading 
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rapor kartları
                  Row(
                    children: [
                      Expanded(
                        child: _buildReportCard(
                          'Toplam Ürün',
                          _products.length.toString(),
                          Icons.inventory,
                          Colors.blue,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildReportCard(
                          'Toplam Sipariş',
                          _orders.length.toString(),
                          Icons.shopping_cart,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildReportCard(
                          'Toplam Satış',
                          '₺${_getTotalSales().toStringAsFixed(2)}',
                          Icons.attach_money,
                          Colors.orange,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildReportCard(
                          'Düşük Stok',
                          _getLowStockCount().toString(),
                          Icons.warning,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  
                  // Detaylı raporlar
                  Text(
                    'Detaylı Raporlar',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  
                  // En çok satan ürünler
                  _buildTopProductsReport(),
                  SizedBox(height: 16),
                  
                  // Stok durumu
                  _buildStockReport(),
                  SizedBox(height: 16),
                  
                  // Son siparişler
                  _buildRecentOrdersReport(),
                ],
              ),
            ),
      );
    } catch (e) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Raporlar'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Hata: $e', style: TextStyle(fontSize: 16)),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                },
                child: Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildReportCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }

  double _getTotalSales() {
    return _orders.fold(0.0, (sum, order) => sum + order.totalAmount);
  }

  int _getLowStockCount() {
    return _products.where((p) => p.stock <= 10).length;
  }

  Widget _buildTopProductsReport() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'En Çok Satan Ürünler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ..._products.take(5).map((product) => ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text(product.stock.toString()),
              ),
              title: Text(product.name),
              subtitle: Text('Stok: ${product.stock} | Fiyat: ₺${product.price.toStringAsFixed(2)}'),
              trailing: Text(product.category),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildStockReport() {
    final lowStockProducts = _products.where((p) => p.stock <= 10).toList();
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stok Durumu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            if (lowStockProducts.isEmpty)
              Text('Tüm ürünlerde yeterli stok var!', style: TextStyle(color: Colors.green))
            else
              ...lowStockProducts.map((product) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: product.stock == 0 ? Colors.red : Colors.orange,
                  child: Text(product.stock.toString()),
                ),
                title: Text(product.name),
                subtitle: Text('Kategori: ${product.category}'),
                trailing: Text(
                  product.stock == 0 ? 'Tükendi' : 'Düşük Stok',
                  style: TextStyle(
                    color: product.stock == 0 ? Colors.red : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersReport() {
    final recentOrders = _orders.take(5).toList();
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Son Siparişler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            if (recentOrders.isEmpty)
              Text('Henüz sipariş bulunmuyor')
            else
              ...recentOrders.map((order) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getOrderStatusColor(order.status),
                  child: Icon(
                    _getOrderStatusIcon(order.status),
                    color: Colors.white,
                  ),
                ),
                title: Text('Sipariş #${order.id}'),
                subtitle: Text('Tutar: ₺${order.totalAmount.toStringAsFixed(2)}'),
                trailing: Text(
                  _getOrderStatusText(order.status),
                  style: TextStyle(
                    color: _getOrderStatusColor(order.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }

  Color _getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getOrderStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'completed':
        return Icons.check;
      case 'cancelled':
        return Icons.close;
      default:
        return Icons.help;
    }
  }

  String _getOrderStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Beklemede';
      case 'completed':
        return 'Tamamlandı';
      case 'cancelled':
        return 'İptal';
      default:
        return status;
    }
  }

  // PDF olarak export et
  Future<void> _exportToPDF() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final pdf = pw.Document();
      final now = DateTime.now();
      final dateStr = '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}';

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // Başlık
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Tuning App - Admin Raporu',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Rapor Tarihi: $dateStr',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 30),

              // Özet İstatistikler
              pw.Text(
                'Özet İstatistikler',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Toplam Ürün', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(_products.length.toString()),
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
                        child: pw.Text(_orders.length.toString()),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Toplam Satış', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('₺${_getTotalSales().toStringAsFixed(2)}'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Düşük Stok', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(_getLowStockCount().toString()),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // En Çok Satan Ürünler
              pw.Text(
                'En Çok Satan Ürünler',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1),
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
                        child: pw.Text('Stok', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Fiyat', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Kategori', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ..._products.take(10).map((product) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(product.name),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(product.stock.toString()),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('₺${product.price.toStringAsFixed(2)}'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(product.category),
                      ),
                    ],
                  )),
                ],
              ),
              pw.SizedBox(height: 30),

              // Düşük Stok Ürünleri
              if (_getLowStockCount() > 0) ...[
                pw.Text(
                  'Düşük Stok Ürünleri',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(2),
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
                          child: pw.Text('Stok', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Durum', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    ..._products.where((p) => p.stock <= 10).map((product) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(product.name),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(product.stock.toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(product.stock == 0 ? 'Tükendi' : 'Düşük Stok'),
                        ),
                      ],
                    )),
                  ],
                ),
                pw.SizedBox(height: 30),
              ],

              // Son Siparişler
              pw.Text(
                'Son Siparişler',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Sipariş ID', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Tutar', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Durum', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ..._orders.take(10).map((order) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(order.id.substring(0, order.id.length > 20 ? 20 : order.id.length)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('₺${order.totalAmount.toStringAsFixed(2)}'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(_getOrderStatusText(order.status)),
                      ),
                    ],
                  )),
                ],
              ),
            ];
          },
        ),
      );

      // PDF'i byte array'e çevir
      final bytes = await pdf.save();

      // Web'de dosya indir
      if (kIsWeb) {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', 'rapor_${DateTime.now().millisecondsSinceEpoch}.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF raporu başarıyla indirildi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF oluşturulurken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Excel (CSV) olarak export et
  Future<void> _exportToExcel() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final csv = StringBuffer();
      final now = DateTime.now();
      final dateStr = '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}';

      // Başlık
      csv.writeln('Tuning App - Admin Raporu');
      csv.writeln('Rapor Tarihi: $dateStr');
      csv.writeln('');

      // Özet İstatistikler
      csv.writeln('Özet İstatistikler');
      csv.writeln('Toplam Ürün,${_products.length}');
      csv.writeln('Toplam Sipariş,${_orders.length}');
      csv.writeln('Toplam Satış,₺${_getTotalSales().toStringAsFixed(2)}');
      csv.writeln('Düşük Stok,${_getLowStockCount()}');
      csv.writeln('');

      // Ürünler
      csv.writeln('Ürünler');
      csv.writeln('Ürün Adı,Stok,Fiyat,Kategori');
      for (var product in _products) {
        csv.writeln('"${product.name}",${product.stock},₺${product.price.toStringAsFixed(2)},"${product.category}"');
      }
      csv.writeln('');

      // Düşük Stok Ürünleri
      final lowStockProducts = _products.where((p) => p.stock <= 10).toList();
      if (lowStockProducts.isNotEmpty) {
        csv.writeln('Düşük Stok Ürünleri');
        csv.writeln('Ürün Adı,Stok,Durum');
        for (var product in lowStockProducts) {
          csv.writeln('"${product.name}",${product.stock},${product.stock == 0 ? "Tükendi" : "Düşük Stok"}');
        }
        csv.writeln('');
      }

      // Siparişler
      csv.writeln('Siparişler');
      csv.writeln('Sipariş ID,Tutar,Durum,Tarih');
      for (var order in _orders) {
        final orderDateStr = order.orderDate.toString().substring(0, 10);
        csv.writeln('"${order.id}",₺${order.totalAmount.toStringAsFixed(2)},${_getOrderStatusText(order.status)},$orderDateStr');
      }

      // Web'de dosya indir
      if (kIsWeb) {
        final blob = html.Blob([utf8.encode(csv.toString())], 'text/csv');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', 'rapor_${DateTime.now().millisecondsSinceEpoch}.csv')
          ..click();
        html.Url.revokeObjectUrl(url);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Excel (CSV) raporu başarıyla indirildi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel oluşturulurken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
