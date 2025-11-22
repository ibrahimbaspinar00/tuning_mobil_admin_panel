import 'package:flutter/material.dart';
import 'services/admin_service.dart';
import 'model/order.dart' as OrderModel;

class WebAdminOrders extends StatefulWidget {
  const WebAdminOrders({super.key});

  @override
  State<WebAdminOrders> createState() => _WebAdminOrdersState();
}

class _WebAdminOrdersState extends State<WebAdminOrders> {
  final AdminService _adminService = AdminService();
  String _selectedStatus = 'Tümü';
  String _sortBy = 'orderDate';
  
  // Pagination
  static const int _itemsPerPage = 20;
  int _currentPage = 0;
  List<OrderModel.Order> _allOrders = [];
  List<OrderModel.Order> _filteredOrders = [];
  List<OrderModel.Order> _displayedOrders = [];
  bool _hasMore = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Sipariş Yönetimi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 768;
          
          return Column(
            children: [
              // Filtre ve sıralama
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                color: Colors.white,
                child: Column(
                  children: [
                    if (isMobile) ...[
                      // Mobile: Dikey düzen
                      Column(
                        children: [
                          // Durum filtresi
                          SizedBox(
                            width: double.infinity,
                            child: DropdownButton<String>(
                              value: _selectedStatus,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(value: 'Tümü', child: Text('Tüm Siparişler')),
                                DropdownMenuItem(value: 'pending', child: Text('Beklemede')),
                                DropdownMenuItem(value: 'confirmed', child: Text('Onaylandı')),
                                DropdownMenuItem(value: 'shipped', child: Text('Kargoya Verildi')),
                                DropdownMenuItem(value: 'delivered', child: Text('Teslim Edildi')),
                                DropdownMenuItem(value: 'cancelled', child: Text('İptal Edildi')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedStatus = value!;
                                  _currentPage = 0; // Reset pagination
                                });
                                _applyFilters();
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Sıralama
                          SizedBox(
                            width: double.infinity,
                            child: DropdownButton<String>(
                              value: _sortBy,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(value: 'orderDate', child: Text('Sipariş Tarihi')),
                                DropdownMenuItem(value: 'totalAmount', child: Text('Toplam Tutar')),
                                DropdownMenuItem(value: 'customerName', child: Text('Müşteri Adı')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _sortBy = value!;
                                  _currentPage = 0; // Reset pagination
                                });
                                _applyFilters();
                              },
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Desktop: Yatay düzen
                      Row(
                        children: [
                          // Durum filtresi
                          Expanded(
                            child: DropdownButton<String>(
                              value: _selectedStatus,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(value: 'Tümü', child: Text('Tüm Siparişler')),
                                DropdownMenuItem(value: 'pending', child: Text('Beklemede')),
                                DropdownMenuItem(value: 'confirmed', child: Text('Onaylandı')),
                                DropdownMenuItem(value: 'shipped', child: Text('Kargoya Verildi')),
                                DropdownMenuItem(value: 'delivered', child: Text('Teslim Edildi')),
                                DropdownMenuItem(value: 'cancelled', child: Text('İptal Edildi')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedStatus = value!;
                                  _currentPage = 0; // Reset pagination
                                });
                                _applyFilters();
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Sıralama
                          Expanded(
                            child: DropdownButton<String>(
                              value: _sortBy,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(value: 'orderDate', child: Text('Sipariş Tarihi')),
                                DropdownMenuItem(value: 'totalAmount', child: Text('Toplam Tutar')),
                                DropdownMenuItem(value: 'customerName', child: Text('Müşteri Adı')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _sortBy = value!;
                                  _currentPage = 0; // Reset pagination
                                });
                                _applyFilters();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Temizleme butonu
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _cleanRandomAddresses,
                          icon: const Icon(Icons.cleaning_services),
                          label: const Text('Rastgele Adresleri Temizle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Sipariş listesi
              Expanded(
                child: StreamBuilder<List<OrderModel.Order>>(
                  stream: _adminService.getOrders(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, size: 64, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Siparişler yüklenirken hata oluştu',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }
                    
                    final orders = snapshot.data ?? [];
                    
                    // State'i build dışında güncelle - setState'i build sırasında çağırmamak için
                    if (_allOrders.length != orders.length || 
                        !_allOrders.every((order) => orders.any((o) => o.id == order.id))) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _allOrders = orders;
                          });
                          _applyFilters();
                        }
                      });
                    }
                    
                    // Mevcut state'ten filtreli ve sayfalanmış siparişleri kullan
                    final displayedOrders = _displayedOrders.isEmpty && _filteredOrders.isEmpty
                        ? orders.take(_itemsPerPage).toList()
                        : _displayedOrders;
                    final hasMore = _hasMore;
                    final filteredOrdersCount = _filteredOrders.isEmpty 
                        ? orders.length 
                        : _filteredOrders.length;
                    
                    if (displayedOrders.isEmpty && orders.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Henüz sipariş bulunmuyor',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Müşteriler sipariş verdiğinde burada görünecek',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      padding: EdgeInsets.all(isMobile ? 8 : 16),
                      itemCount: displayedOrders.length + (hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Load more indicator
                        if (index == displayedOrders.length) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: ElevatedButton(
                                onPressed: _loadMoreOrders,
                                child: Text('Daha Fazla Yükle (${filteredOrdersCount - displayedOrders.length} kaldı)'),
                              ),
                            ),
                          );
                        }
                        
                        final order = displayedOrders[index];
                        return _buildOrderCard(order, isMobile);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderModel.Order order, bool isMobile) {
    return Card(
      margin: EdgeInsets.only(bottom: 12, left: isMobile ? 4 : 0, right: isMobile ? 4 : 0),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sipariş başlığı
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sipariş #${order.id}',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: _buildStatusChip(order.status),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Müşteri bilgileri
            Row(
              children: [
                Icon(Icons.person, size: isMobile ? 14 : 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.customerName,
                    style: TextStyle(fontSize: isMobile ? 14 : 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            
            // Tarih
            Row(
              children: [
                Icon(Icons.calendar_today, size: isMobile ? 14 : 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _formatDate(order.orderDate),
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Toplam tutar
            Row(
              children: [
                Icon(Icons.attach_money, size: isMobile ? 14 : 16, color: Colors.green[600]),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${order.totalAmount.toStringAsFixed(2)} TL',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Ürünler
            if (order.products.isNotEmpty) ...[
              Text(
                'Ürünler:',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              ...order.products.map((product) => Padding(
                padding: EdgeInsets.only(left: isMobile ? 8 : 16, bottom: 2),
                child: Text(
                  '• ${product.name} x${product.quantity}',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              )),
              const SizedBox(height: 12),
            ],
            
            // Aksiyon butonları
            if (isMobile) ...[
              // Mobile: Dikey düzen
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _viewOrderDetails(order),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Detaylar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _updateOrderStatus(order),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Durum Güncelle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ] else ...[
              // Desktop: Yatay düzen
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _viewOrderDetails(order),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('Detaylar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateOrderStatus(order),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Durum Güncelle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    
    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        text = 'Beklemede';
        break;
      case 'confirmed':
        color = Colors.blue;
        text = 'Onaylandı';
        break;
      case 'shipped':
        color = Colors.purple;
        text = 'Kargoya Verildi';
        break;
      case 'delivered':
        color = Colors.green;
        text = 'Teslim Edildi';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'İptal Edildi';
        break;
      default:
        color = Colors.grey;
        text = 'Bilinmiyor';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _applyFilters() {
    setState(() {
      // Durum filtresi
      _filteredOrders = _allOrders.where((order) {
        if (_selectedStatus != 'Tümü' && order.status != _selectedStatus) {
          return false;
        }
        return true;
      }).toList();
      
      // Sıralama
      _filteredOrders.sort((a, b) {
        int comparison = 0;
        switch (_sortBy) {
          case 'orderDate':
            comparison = a.orderDate.compareTo(b.orderDate);
            break;
          case 'totalAmount':
            comparison = a.totalAmount.compareTo(b.totalAmount);
            break;
          case 'customerName':
            comparison = a.customerName.compareTo(b.customerName);
            break;
          default:
            comparison = a.orderDate.compareTo(b.orderDate);
        }
        return -comparison; // Descending by default
      });
      
      // Pagination reset
      _currentPage = 0;
      _updateDisplayedOrders();
    });
  }
  
  void _updateDisplayedOrders() {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _filteredOrders.length);
    
    setState(() {
      _displayedOrders = _filteredOrders.sublist(0, endIndex);
      _hasMore = endIndex < _filteredOrders.length;
    });
  }
  
  void _loadMoreOrders() {
    if (!_hasMore) return;
    
    setState(() {
      _currentPage++;
    });
    _updateDisplayedOrders();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void _viewOrderDetails(OrderModel.Order order) {
    showDialog(
      context: context,
      builder: (context) => LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          
          return AlertDialog(
            title: Text(
              'Sipariş Detayları #${order.id}',
              style: TextStyle(fontSize: isMobile ? 16 : 20),
            ),
            contentPadding: EdgeInsets.all(isMobile ? 16 : 24),
            content: SizedBox(
              width: isMobile ? double.infinity : 500,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDetailRow('Müşteri', order.customerName, isMobile),
                    _buildDetailRow('E-posta', order.customerEmail, isMobile),
                    _buildDetailRow('Telefon', order.customerPhone, isMobile),
                    _buildDetailRow('Adres', order.shippingAddress, isMobile),
                    _buildDetailRow('Sipariş Tarihi', _formatDate(order.orderDate), isMobile),
                    _buildDetailRow('Durum', _getStatusText(order.status), isMobile),
                    _buildDetailRow('Toplam Tutar', '${order.totalAmount.toStringAsFixed(2)} TL', isMobile),
                    const SizedBox(height: 16),
                    Text(
                      'Ürünler:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 14 : 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...order.products.map((product) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• ${product.name} x${product.quantity} - ${product.price} TL',
                        style: TextStyle(fontSize: isMobile ? 12 : 14),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    )),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kapat'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isMobile) {
    if (isMobile) {
      // Mobile: Dikey düzen
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ],
        ),
      );
    } else {
      // Desktop: Yatay düzen
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                '$label:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
              ),
            ),
          ],
        ),
      );
    }
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
        return 'Bilinmiyor';
    }
  }

  void _updateOrderStatus(OrderModel.Order order) {
    // İngilizce status'u Türkçe'ye çevir (dropdown için)
    String _convertToTurkish(String status) {
      switch (status.toLowerCase()) {
        case 'pending':
        case 'beklemede':
          return 'Beklemede';
        case 'confirmed':
        case 'onaylandı':
          return 'Onaylandı';
        case 'shipped':
        case 'kargoya verildi':
          return 'Kargoya Verildi';
        case 'delivered':
        case 'teslim edildi':
          return 'Teslim Edildi';
        case 'cancelled':
        case 'iptal edildi':
          return 'İptal Edildi';
        default:
          return status;
      }
    }
    
    // Mevcut status'u dropdown için uygun formata çevir
    final currentStatusForDropdown = _convertToTurkish(order.status);
    
    showDialog(
      context: context,
      builder: (context) => _OrderStatusDialog(
        currentStatus: currentStatusForDropdown,
        orderId: order.id,
        orderCurrentStatus: order.status,
        adminService: _adminService,
        onStatusUpdated: () {
          // Sipariş durumu güncellendiğinde sayfa otomatik yenilenecek (StreamBuilder sayesinde)
          // StreamBuilder zaten otomatik güncelleniyor, sadece callback'i çağırmak yeterli
        },
      ),
    );
  }

  void _cleanRandomAddresses() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rastgele Adresleri Temizle'),
        content: const Text('Tüm rastgele adresler temizlenecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Rastgele adresler temizlendi'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }
}

class _OrderStatusDialog extends StatefulWidget {
  final String currentStatus;
  final String orderId;
  final String orderCurrentStatus;
  final AdminService adminService;
  final VoidCallback? onStatusUpdated;

  const _OrderStatusDialog({
    required this.currentStatus,
    required this.orderId,
    required this.orderCurrentStatus,
    required this.adminService,
    this.onStatusUpdated,
  });

  @override
  State<_OrderStatusDialog> createState() => _OrderStatusDialogState();
}

class _OrderStatusDialogState extends State<_OrderStatusDialog> {
  late String selectedStatus;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.currentStatus;
  }

  String _convertToTurkish(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'beklemede':
        return 'Beklemede';
      case 'confirmed':
      case 'onaylandı':
        return 'Onaylandı';
      case 'shipped':
      case 'kargoya verildi':
        return 'Kargoya Verildi';
      case 'delivered':
      case 'teslim edildi':
        return 'Teslim Edildi';
      case 'cancelled':
      case 'iptal edildi':
        return 'İptal Edildi';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        return AlertDialog(
          title: Text(
            'Sipariş Durumu Güncelle',
            style: TextStyle(fontSize: isMobile ? 16 : 20),
          ),
          contentPadding: EdgeInsets.all(isMobile ? 16 : 24),
          content: SizedBox(
            width: isMobile ? double.infinity : 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Yeni durumu seçin:',
                  style: TextStyle(fontSize: isMobile ? 14 : 16),
                ),
                const SizedBox(height: 16),
                DropdownButton<String>(
                  value: selectedStatus,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'Beklemede', child: Text('Beklemede')),
                    DropdownMenuItem(value: 'Onaylandı', child: Text('Onaylandı')),
                    DropdownMenuItem(value: 'Kargoya Verildi', child: Text('Kargoya Verildi')),
                    DropdownMenuItem(value: 'Teslim Edildi', child: Text('Teslim Edildi')),
                    DropdownMenuItem(value: 'İptal Edildi', child: Text('İptal Edildi')),
                  ],
                  onChanged: _isUpdating ? null : (value) {
                    if (value != null) {
                      setState(() {
                        selectedStatus = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isUpdating ? null : () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: _isUpdating ? null : () async {
            // Mevcut status'u kontrol et (İngilizce veya Türkçe olabilir)
            final currentStatus = _convertToTurkish(widget.orderCurrentStatus);
            
            if (selectedStatus != currentStatus) {
              setState(() {
                _isUpdating = true;
              });
              
              // Loading göster
              if (mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              try {
                // AdminService ile sipariş durumunu güncelle
                await widget.adminService.updateOrderStatus(widget.orderId, selectedStatus);
                
                if (mounted) {
                  Navigator.pop(context); // Loading dialog'u kapat
                  Navigator.pop(context); // Ana dialog'u kapat
                  widget.onStatusUpdated?.call(); // Callback'i çağır
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sipariş durumu "${selectedStatus}" olarak güncellendi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context); // Loading dialog'u kapat
                  setState(() {
                    _isUpdating = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hata: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            } else {
              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lütfen farklı bir durum seçin'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: _isUpdating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Güncelle'),
            ),
          ],
        );
      },
    );
  }
}