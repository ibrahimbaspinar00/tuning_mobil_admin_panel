import 'package:flutter/material.dart';
import '../model/order.dart' as OrderModel;
import '../services/admin_service.dart';
import 'package:intl/intl.dart';

/// Detaylı sipariş görüntüleme sayfası
class WebAdminOrderDetail extends StatefulWidget {
  final OrderModel.Order order;

  const WebAdminOrderDetail({
    super.key,
    required this.order,
  });

  @override
  State<WebAdminOrderDetail> createState() => _WebAdminOrderDetailState();
}

class _WebAdminOrderDetailState extends State<WebAdminOrderDetail> {
  final AdminService _adminService = AdminService();
  late OrderModel.Order _order;
  final TextEditingController _trackingNumberController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _trackingNumberController.text = _order.trackingNumber ?? '';
    _notesController.text = _order.notes ?? '';
  }

  @override
  void dispose() {
    _trackingNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _updateOrder() async {
    setState(() => _isUpdating = true);
    try {
      await _adminService.updateOrderFields(_order.id, {
        'trackingNumber': _trackingNumberController.text.trim().isEmpty
            ? null
            : _trackingNumberController.text.trim(),
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      });

      // Order'ı yeniden yükle
      final orders = await _adminService.getOrders().first;
      final updatedOrder = orders.firstWhere(
        (o) => o.id == _order.id,
        orElse: () => _order,
      );

      setState(() {
        _order = updatedOrder;
        _isUpdating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sipariş başarıyla güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUpdating = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sipariş Detayı #${_order.id}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isUpdating ? null : _updateOrder,
            tooltip: 'Kaydet',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Timeline
            _buildStatusTimeline(),
            const SizedBox(height: 24),
            
            // Order Info Card
            _buildOrderInfoCard(),
            const SizedBox(height: 24),
            
            // Customer Info Card
            _buildCustomerInfoCard(),
            const SizedBox(height: 24),
            
            // Products Card
            _buildProductsCard(),
            const SizedBox(height: 24),
            
            // Tracking & Notes Card
            _buildTrackingNotesCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline() {
    final statuses = [
      {'key': 'pending', 'label': 'Beklemede', 'icon': Icons.pending},
      {'key': 'confirmed', 'label': 'Onaylandı', 'icon': Icons.check_circle},
      {'key': 'shipped', 'label': 'Kargoya Verildi', 'icon': Icons.local_shipping},
      {'key': 'delivered', 'label': 'Teslim Edildi', 'icon': Icons.done_all},
    ];

    final currentStatusIndex = statuses.indexWhere((s) => s['key'] == _order.status);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sipariş Durumu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...statuses.asMap().entries.map((entry) {
              final index = entry.key;
              final status = entry.value;
              final isCompleted = index <= currentStatusIndex;
              final isCurrent = index == currentStatusIndex;

              return Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? (isCurrent ? Colors.blue : Colors.green)
                          : Colors.grey[300],
                    ),
                    child: Icon(
                      status['icon'] as IconData,
                      color: isCompleted ? Colors.white : Colors.grey[600],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status['label'] as String,
                          style: TextStyle(
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCurrent ? Colors.blue : Colors.black87,
                          ),
                        ),
                        if (isCurrent)
                          Text(
                            'Mevcut durum',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (index < statuses.length - 1)
                    Container(
                      width: 2,
                      height: 30,
                      color: isCompleted ? Colors.green : Colors.grey[300],
                      margin: const EdgeInsets.only(left: 20),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sipariş Bilgileri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Sipariş ID', _order.id),
            _buildInfoRow('Sipariş Tarihi', _formatDate(_order.orderDate)),
            _buildInfoRow('Durum', _getStatusText(_order.status)),
            _buildInfoRow('Toplam Tutar', '₺${_order.totalAmount.toStringAsFixed(2)}'),
            _buildInfoRow('Toplam Ürün', '${_order.totalItems} adet'),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Müşteri Bilgileri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Ad Soyad', _order.customerName),
            _buildInfoRow('E-posta', _order.customerEmail),
            _buildInfoRow('Telefon', _order.customerPhone),
            _buildInfoRow('Adres', _order.shippingAddress),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ürünler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._order.products.map((product) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${product.quantity} adet x ₺${product.price.toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₺${(product.price * product.quantity).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Toplam',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '₺${_order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kargo Takip ve Notlar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _trackingNumberController,
              decoration: const InputDecoration(
                labelText: 'Kargo Takip Numarası',
                hintText: 'Kargo takip numarasını girin',
                prefixIcon: Icon(Icons.local_shipping),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notlar',
                hintText: 'Sipariş hakkında notlar...',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUpdating ? null : _updateOrder,
                icon: _isUpdating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isUpdating ? 'Kaydediliyor...' : 'Kaydet'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
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
}

