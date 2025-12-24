import 'package:flutter/material.dart';
import 'services/admin_service.dart';
import 'services/mobile_user_service.dart';
import 'utils/responsive_helper.dart';

class WebAdminTopCustomers extends StatefulWidget {
  const WebAdminTopCustomers({super.key});

  @override
  State<WebAdminTopCustomers> createState() => _WebAdminTopCustomersState();
}

class _WebAdminTopCustomersState extends State<WebAdminTopCustomers> {
  final AdminService _adminService = AdminService();
  final MobileUserService _userService = MobileUserService();
  List<CustomerStats> _customerStats = [];
  bool _isLoading = true;
  String _sortBy = 'totalSpent'; // 'totalSpent', 'orderCount', 'avgOrderValue'
  bool _sortDescending = true;

  @override
  void initState() {
    super.initState();
    _loadCustomerStats();
  }

  Future<void> _loadCustomerStats() async {
    setState(() => _isLoading = true);

    try {
      // Tüm siparişleri al
      final ordersStream = _adminService.getOrders();
      final orders = await ordersStream.first;
      
      // Kullanıcı bazında istatistikleri hesapla
      final Map<String, CustomerStats> statsMap = {};

      for (final order in orders) {
        // userId varsa onu kullan, yoksa customerEmail veya phone kullan
        final customerId = order.userId ?? 
          (order.customerEmail.isNotEmpty 
            ? order.customerEmail 
            : order.customerPhone.isNotEmpty 
              ? order.customerPhone 
              : order.customerName);

        if (!statsMap.containsKey(customerId)) {
          statsMap[customerId] = CustomerStats(
            customerId: customerId,
            customerName: order.customerName,
            customerEmail: order.customerEmail,
            customerPhone: order.customerPhone,
            totalSpent: 0.0,
            orderCount: 0,
            lastOrderDate: order.orderDate,
          );
        }

        final stats = statsMap[customerId]!;
        stats.totalSpent += order.totalAmount;
        stats.orderCount += 1;
        if (order.orderDate.isAfter(stats.lastOrderDate)) {
          stats.lastOrderDate = order.orderDate;
        }
      }

      // Mobile users ile eşleştir (userId, email veya phone ile)
      final allUsers = await _userService.getUsers().first;
      for (final user in allUsers) {
        // userId ile eşleştir
        if (user.id.isNotEmpty) {
          for (final stats in statsMap.values) {
            if (stats.customerId == user.id) {
              stats.userId = user.id;
              stats.avatarUrl = user.avatarUrl;
              stats.userCreatedAt = user.createdAt;
              stats.isActive = user.isActive;
              break;
            }
          }
        }
        
        // Email veya phone ile eşleştir
        final userIdentifier = user.email ?? user.phoneNumber ?? '';
        if (userIdentifier.isNotEmpty && statsMap.containsKey(userIdentifier)) {
          final stats = statsMap[userIdentifier]!;
          stats.userId = user.id;
          stats.avatarUrl = user.avatarUrl;
          stats.userCreatedAt = user.createdAt;
          stats.isActive = user.isActive;
        }
      }

      // Listeye çevir ve sırala
      _customerStats = statsMap.values.toList();
      _sortStats();

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('❌ Müşteri istatistikleri yüklenirken hata: $e');
      setState(() => _isLoading = false);
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

  void _sortStats() {
    _customerStats.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'totalSpent':
          comparison = a.totalSpent.compareTo(b.totalSpent);
          break;
        case 'orderCount':
          comparison = a.orderCount.compareTo(b.orderCount);
          break;
        case 'avgOrderValue':
          final avgA = a.orderCount > 0 ? a.totalSpent / a.orderCount : 0.0;
          final avgB = b.orderCount > 0 ? b.totalSpent / b.orderCount : 0.0;
          comparison = avgA.compareTo(avgB);
          break;
        default:
          comparison = a.totalSpent.compareTo(b.totalSpent);
      }
      return _sortDescending ? -comparison : comparison;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: ResponsiveHelper.responsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'En Çok Alışveriş Yapan Müşteriler',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadCustomerStats,
                      tooltip: 'Yenile',
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.sort),
                      tooltip: 'Sırala',
                      onSelected: (value) {
                        setState(() {
                          if (_sortBy == value) {
                            _sortDescending = !_sortDescending;
                          } else {
                            _sortBy = value;
                            _sortDescending = true;
                          }
                          _sortStats();
                        });
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'totalSpent',
                          child: Row(
                            children: [
                              if (_sortBy == 'totalSpent')
                                Icon(
                                  _sortDescending ? Icons.arrow_downward : Icons.arrow_upward,
                                  size: 16,
                                ),
                              const SizedBox(width: 8),
                              const Text('Toplam Harcama'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'orderCount',
                          child: Row(
                            children: [
                              if (_sortBy == 'orderCount')
                                Icon(
                                  _sortDescending ? Icons.arrow_downward : Icons.arrow_upward,
                                  size: 16,
                                ),
                              const SizedBox(width: 8),
                              const Text('Sipariş Sayısı'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'avgOrderValue',
                          child: Row(
                            children: [
                              if (_sortBy == 'avgOrderValue')
                                Icon(
                                  _sortDescending ? Icons.arrow_downward : Icons.arrow_upward,
                                  size: 16,
                                ),
                              const SizedBox(width: 8),
                              const Text('Ortalama Sipariş Değeri'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Statistics Cards
            _buildStatisticsCards(),
            const SizedBox(height: 32),

            // Customers List
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_customerStats.isEmpty)
              _buildEmptyState()
            else
              _buildCustomersList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    if (_customerStats.isEmpty) {
      return const SizedBox();
    }

    final totalRevenue = _customerStats.fold(0.0, (sum, stats) => sum + stats.totalSpent);
    final totalOrders = _customerStats.fold(0, (sum, stats) => sum + stats.orderCount);
    final avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = ResponsiveHelper.responsiveColumns(
          context,
          mobile: 1,
          tablet: 2,
          laptop: 2,
          desktop: 4,
        );

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: ResponsiveHelper.responsiveGridSpacing(context),
            mainAxisSpacing: ResponsiveHelper.responsiveGridSpacing(context),
            childAspectRatio: 2.5,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            switch (index) {
              case 0:
                return _StatCard(
                  title: 'Toplam Müşteri',
                  value: _customerStats.length.toString(),
                  icon: Icons.people_rounded,
                  color: const Color(0xFF3B82F6),
                );
              case 1:
                return _StatCard(
                  title: 'Toplam Gelir',
                  value: '₺${totalRevenue.toStringAsFixed(0)}',
                  icon: Icons.attach_money_rounded,
                  color: const Color(0xFF10B981),
                );
              case 2:
                return _StatCard(
                  title: 'Toplam Sipariş',
                  value: totalOrders.toString(),
                  icon: Icons.shopping_bag_rounded,
                  color: const Color(0xFF8B5CF6),
                );
              case 3:
                return _StatCard(
                  title: 'Ortalama Sipariş',
                  value: '₺${avgOrderValue.toStringAsFixed(0)}',
                  icon: Icons.analytics_rounded,
                  color: const Color(0xFFF59E0B),
                );
              default:
                return const SizedBox();
            }
          },
        );
      },
    );
  }

  Widget _buildCustomersList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: ResponsiveHelper.isMobile(context)
              ? const SizedBox()
              : Row(
                  children: [
                    Expanded(flex: 2, child: _buildHeaderCell('Müşteri')),
                    Expanded(flex: 1, child: _buildHeaderCell('Toplam Harcama')),
                    Expanded(flex: 1, child: _buildHeaderCell('Sipariş Sayısı')),
                    Expanded(flex: 1, child: _buildHeaderCell('Ortalama')),
                    Expanded(flex: 1, child: _buildHeaderCell('Son Sipariş')),
                  ],
                ),
          ),

          // Table Body
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _customerStats.length,
            itemBuilder: (context, index) {
              final stats = _customerStats[index];
              final rank = index + 1;
              return _buildCustomerRow(stats, rank);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Color(0xFF64748B),
        fontSize: 14,
      ),
    );
  }

  Widget _buildCustomerRow(CustomerStats stats, int rank) {
    final avgOrderValue = stats.orderCount > 0 
      ? stats.totalSpent / stats.orderCount 
      : 0.0;

    if (ResponsiveHelper.isMobile(context)) {
      return _buildMobileCustomerCard(stats, rank, avgOrderValue);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rank <= 3 
                ? const Color(0xFFF59E0B).withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? const Color(0xFFF59E0B) : Colors.grey[700],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Customer Info
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF6366F1),
                  backgroundImage: stats.avatarUrl != null 
                    ? NetworkImage(stats.avatarUrl!) 
                    : null,
                  child: stats.avatarUrl == null
                    ? Text(
                        (stats.customerName.isNotEmpty 
                          ? stats.customerName[0] 
                          : 'M').toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stats.customerName.isNotEmpty 
                          ? stats.customerName 
                          : 'İsimsiz Müşteri',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (stats.customerEmail.isNotEmpty)
                        Text(
                          stats.customerEmail,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      if (stats.customerPhone.isNotEmpty)
                        Text(
                          stats.customerPhone,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Total Spent
          Expanded(
            flex: 1,
            child: Text(
              '₺${stats.totalSpent.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF10B981),
              ),
            ),
          ),

          // Order Count
          Expanded(
            flex: 1,
            child: Text(
              '${stats.orderCount} sipariş',
              style: const TextStyle(fontSize: 14),
            ),
          ),

          // Average Order Value
          Expanded(
            flex: 1,
            child: Text(
              '₺${avgOrderValue.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),

          // Last Order Date
          Expanded(
            flex: 1,
            child: Text(
              _formatDate(stats.lastOrderDate),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCustomerCard(CustomerStats stats, int rank, double avgOrderValue) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: rank <= 3 
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: rank <= 3 ? const Color(0xFFF59E0B) : Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF6366F1),
                backgroundImage: stats.avatarUrl != null 
                  ? NetworkImage(stats.avatarUrl!) 
                  : null,
                child: stats.avatarUrl == null
                  ? Text(
                      (stats.customerName.isNotEmpty 
                        ? stats.customerName[0] 
                        : 'M').toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    )
                  : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.customerName.isNotEmpty 
                        ? stats.customerName 
                        : 'İsimsiz Müşteri',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (stats.customerEmail.isNotEmpty)
                      Text(
                        stats.customerEmail,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Toplam', '₺${stats.totalSpent.toStringAsFixed(0)}', Colors.green),
              _buildStatItem('Sipariş', '${stats.orderCount}', Colors.blue),
              _buildStatItem('Ortalama', '₺${avgOrderValue.toStringAsFixed(0)}', Colors.orange),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Son Sipariş: ${_formatDate(stats.lastOrderDate)}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz müşteri bulunmuyor',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sipariş verileri yüklendiğinde müşteriler burada görünecek',
            style: TextStyle(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Bugün';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks hafta önce';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class CustomerStats {
  String customerId;
  String customerName;
  String customerEmail;
  String customerPhone;
  double totalSpent;
  int orderCount;
  DateTime lastOrderDate;
  String? userId;
  String? avatarUrl;
  DateTime? userCreatedAt;
  bool? isActive;

  CustomerStats({
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.totalSpent,
    required this.orderCount,
    required this.lastOrderDate,
    this.userId,
    this.avatarUrl,
    this.userCreatedAt,
    this.isActive,
  });
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

