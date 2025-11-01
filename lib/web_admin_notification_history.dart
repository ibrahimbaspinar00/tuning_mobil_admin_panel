import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'model/notification.dart';

class WebAdminNotificationHistory extends StatefulWidget {
  const WebAdminNotificationHistory({super.key});

  @override
  State<WebAdminNotificationHistory> createState() => _WebAdminNotificationHistoryState();
}

class _WebAdminNotificationHistoryState extends State<WebAdminNotificationHistory> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Removed unused field _selectedFilter
  String _selectedType = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Bildirim Geçmişi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_list, color: Colors.white),
            tooltip: 'Filtrele',
          ),
          IconButton(
            onPressed: _exportHistory,
            icon: const Icon(Icons.download, color: Colors.white),
            tooltip: 'Dışa Aktar',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsCards(),
          const SizedBox(height: 16),
          Expanded(
            child: _buildNotificationsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: 'Toplam Bildirim',
              value: '0',
              icon: Icons.notifications,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              title: 'Bu Ay',
              value: '0',
              icon: Icons.calendar_month,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              title: 'Başarılı',
              value: '0',
              icon: Icons.check_circle,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              title: 'Başarısız',
              value: '0',
              icon: Icons.error,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
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
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getNotificationsStream(),
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
                  'Bildirimler yüklenemedi',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final notifications = snapshot.data?.docs ?? [];
        
        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Henüz bildirim gönderilmemiş',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Admin panelinden bildirim gönderdiğinizde burada görünecek',
                  style: TextStyle(color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final doc = notifications[index];
            final data = doc.data() as Map<String, dynamic>;
            final notification = AppNotification.fromFirestore(data, doc.id);
            
            return _buildNotificationCard(notification, data);
          },
        );
      },
    );
  }

  Widget _buildNotificationCard(AppNotification notification, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getTypeIcon(notification.type),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(data['status'] ?? 'sent'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(notification.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                const Spacer(),
                if (notification.userId != null) ...[
                  Icon(Icons.person, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'Kullanıcı: ${notification.userId!.substring(0, 8)}...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ] else ...[
                  Icon(Icons.group, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'Tüm Kullanıcılar',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
            if (notification.imageUrl != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  notification.imageUrl!,
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 100,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _getTypeIcon(String type) {
    switch (type) {
      case 'order':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.shopping_bag, color: Colors.blue[600], size: 20),
        );
      case 'promotion':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.local_offer, color: Colors.orange[600], size: 20),
        );
      case 'stock':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.inventory, color: Colors.red[600], size: 20),
        );
      case 'payment':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.payment, color: Colors.green[600], size: 20),
        );
      case 'shipping':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.local_shipping, color: Colors.purple[600], size: 20),
        );
      default:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.notifications, color: Colors.grey[600], size: 20),
        );
    }
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    
    switch (status) {
      case 'sent':
        color = Colors.green;
        text = 'Gönderildi';
        break;
      case 'failed':
        color = Colors.red;
        text = 'Başarısız';
        break;
      case 'pending':
        color = Colors.orange;
        text = 'Beklemede';
        break;
      default:
        color = Colors.grey;
        text = 'Bilinmeyen';
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
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }

  Stream<QuerySnapshot> _getNotificationsStream() {
    Query query = _firestore.collection('notifications');
    
    // Filtreleme
    if (_selectedType != 'all') {
      query = query.where('type', isEqualTo: _selectedType);
    }
    
    // Tarih filtresi
    if (_startDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: _startDate);
    }
    if (_endDate != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: _endDate);
    }
    
    return query.orderBy('createdAt', descending: true).snapshots();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrele'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Bildirim Türü'),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Tümü')),
                DropdownMenuItem(value: 'system', child: Text('Sistem')),
                DropdownMenuItem(value: 'order', child: Text('Sipariş')),
                DropdownMenuItem(value: 'promotion', child: Text('Promosyon')),
                DropdownMenuItem(value: 'stock', child: Text('Stok')),
                DropdownMenuItem(value: 'payment', child: Text('Ödeme')),
                DropdownMenuItem(value: 'shipping', child: Text('Kargo')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _startDate = date;
                        });
                      }
                    },
                    child: Text(_startDate == null 
                        ? 'Başlangıç Tarihi' 
                        : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _endDate = date;
                        });
                      }
                    },
                    child: Text(_endDate == null 
                        ? 'Bitiş Tarihi' 
                        : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedType = 'all';
                _startDate = null;
                _endDate = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Temizle'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _exportHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dışa aktarma özelliği yakında eklenecek'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
