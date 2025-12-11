import 'package:flutter/material.dart';
import 'model/mobile_user.dart';
import 'services/mobile_user_service.dart';
import 'services/fcm_service.dart';

class WebAdminMobileUsers extends StatefulWidget {
  const WebAdminMobileUsers({super.key});

  @override
  State<WebAdminMobileUsers> createState() => _WebAdminMobileUsersState();
}

class _WebAdminMobileUsersState extends State<WebAdminMobileUsers> {
  final MobileUserService _userService = MobileUserService();
  final FCMService _fcmService = FCMService();
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  String _selectedStatus = 'Tümü';
  int _totalUsers = 0;
  double _totalBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    try {
      _totalUsers = await _userService.getUserCount();
      _totalBalance = await _userService.getTotalBalance();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('İstatistikler yüklenirken hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header - Responsive
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              return Container(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
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
                child: Column(
                  children: [
                    isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mobil Kullanıcılar',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Mobil uygulama kullanıcılarını yönetin',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      'Toplam Kullanıcı',
                                      '$_totalUsers',
                                      Icons.people,
                                      const Color(0xFF3B82F6),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      'Toplam Bakiye',
                                      '₺${_totalBalance.toStringAsFixed(2)}',
                                      Icons.account_balance_wallet,
                                      const Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Mobil Kullanıcılar',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Mobil uygulama kullanıcılarını yönetin',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Statistics
                              _buildStatCard(
                                'Toplam Kullanıcı',
                                '$_totalUsers',
                                Icons.people,
                                const Color(0xFF3B82F6),
                              ),
                              const SizedBox(width: 16),
                              _buildStatCard(
                                'Toplam Bakiye',
                                '₺${_totalBalance.toStringAsFixed(2)}',
                                Icons.account_balance_wallet,
                                const Color(0xFF10B981),
                              ),
                            ],
                          ),
                    const SizedBox(height: 24),
                    // Search and Filters - Responsive
                    LayoutBuilder(
                      builder: (context, filterConstraints) {
                        final isMobile = filterConstraints.maxWidth < 600;
                        
                        if (isMobile) {
                          // Mobil için dikey layout
                          return Column(
                            children: [
                              TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Kullanıcı ara...',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            setState(() {
                                              _searchQuery = '';
                                              _searchController.clear();
                                            });
                                          },
                                        )
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: DropdownButton<String>(
                                  value: _selectedStatus,
                                  underline: const SizedBox(),
                                  isExpanded: true,
                                  items: const [
                                    DropdownMenuItem(value: 'Tümü', child: Text('Tüm Durumlar')),
                                    DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                                    DropdownMenuItem(value: 'Pasif', child: Text('Pasif')),
                                    DropdownMenuItem(value: 'Dondurulmuş', child: Text('Dondurulmuş')),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedStatus = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          );
                        } else {
                          // Desktop için yatay layout
                          return Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Kullanıcı adı, e-posta, telefon ile ara...',
                                    prefixIcon: const Icon(Icons.search),
                                    suffixIcon: _searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              setState(() {
                                                _searchQuery = '';
                                                _searchController.clear();
                                              });
                                            },
                                          )
                                        : null,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _searchQuery = value;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: DropdownButton<String>(
                                  value: _selectedStatus,
                                  underline: const SizedBox(),
                                  items: const [
                                    DropdownMenuItem(value: 'Tümü', child: Text('Tüm Durumlar')),
                                    DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                                    DropdownMenuItem(value: 'Pasif', child: Text('Pasif')),
                                    DropdownMenuItem(value: 'Dondurulmuş', child: Text('Dondurulmuş')),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedStatus = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),

          // User List - Responsive padding
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                return Padding(
                  padding: EdgeInsets.all(isMobile ? 12 : 24),
                  child: _searchQuery.isEmpty
                      ? _buildUserStream()
                      : _buildSearchResults(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 20,
            vertical: isMobile ? 12 : 16,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: isMobile ? 20 : 28),
              SizedBox(width: isMobile ? 8 : 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: isMobile ? 10 : 12,
                        color: Colors.grey[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserStream() {
    return StreamBuilder<List<MobileUser>>(
      stream: _userService.getUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          final error = snapshot.error.toString();
          final isPermissionError = error.contains('permission-denied') || 
                                   error.contains('permission denied') ||
                                   error.contains('Missing or insufficient permissions');
          
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    isPermissionError 
                        ? 'Firebase İzin Hatası'
                        : 'Kullanıcılar yüklenirken hata oluştu',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isPermissionError) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange[700]),
                              const SizedBox(width: 8),
                              Text(
                                'Çözüm Adımları:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[900],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '1. Firebase Console\'a gidin (https://console.firebase.google.com)',
                            style: TextStyle(color: Colors.orange[900]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '2. Projenizi seçin',
                            style: TextStyle(color: Colors.orange[900]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '3. Firestore Database > Rules sekmesine gidin',
                            style: TextStyle(color: Colors.orange[900]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '4. firestore.rules dosyasındaki kuralları kopyalayıp yapıştırın',
                            style: TextStyle(color: Colors.orange[900]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '5. "Publish" butonuna tıklayın',
                            style: TextStyle(color: Colors.orange[900]),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Text(
                      error,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tekrar Dene'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Kullanıcı bulunamadı',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        List<MobileUser> users = snapshot.data!;
        
        // Filter by status
        if (_selectedStatus != 'Tümü') {
          users = users.where((user) {
            if (_selectedStatus == 'Aktif') return user.isActive && !user.isFrozen;
            if (_selectedStatus == 'Pasif') return !user.isActive;
            if (_selectedStatus == 'Dondurulmuş') return user.isFrozen;
            return true;
          }).toList();
        }

        return _buildUserGrid(users);
      },
    );
  }

  Widget _buildSearchResults() {
    return FutureBuilder<List<MobileUser>>(
      future: _userService.searchUsers(_searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          final error = snapshot.error.toString();
          final isPermissionError = error.contains('permission-denied') || 
                                   error.contains('permission denied') ||
                                   error.contains('Missing or insufficient permissions');
          
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    isPermissionError 
                        ? 'Firebase İzin Hatası'
                        : 'Arama sırasında hata oluştu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[600],
                    ),
                  ),
                  if (!isPermissionError) ...[
                    const SizedBox(height: 8),
                    Text(
                      error,
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
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Sonuç bulunamadı',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        List<MobileUser> users = snapshot.data!;
        
        // Filter by status
        if (_selectedStatus != 'Tümü') {
          users = users.where((user) {
            if (_selectedStatus == 'Aktif') return user.isActive && !user.isFrozen;
            if (_selectedStatus == 'Pasif') return !user.isActive;
            if (_selectedStatus == 'Dondurulmuş') return user.isFrozen;
            return true;
          }).toList();
        }

        return _buildUserGrid(users);
      },
    );
  }

  Widget _buildUserGrid(List<MobileUser> users) {
    // Responsive grid: mobil için 1-2, tablet için 3, desktop için 4-5 sütun
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        int crossAxisCount;
        double childAspectRatio;
        
        if (screenWidth < 600) {
          // Mobil
          crossAxisCount = 1;
          childAspectRatio = 2.8;
        } else if (screenWidth < 900) {
          // Küçük tablet
          crossAxisCount = 2;
          childAspectRatio = 1.8;
        } else if (screenWidth < 1200) {
          // Tablet
          crossAxisCount = 3;
          childAspectRatio = 1.5;
        } else if (screenWidth < 1600) {
          // Küçük desktop
          crossAxisCount = 4;
          childAspectRatio = 1.2;
        } else {
          // Büyük desktop
          crossAxisCount = 5;
          childAspectRatio = 1.0;
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: users.length,
          itemBuilder: (context, index) {
            return _buildUserCard(users[index]);
          },
        );
      },
    );
  }

  Widget _buildUserCard(MobileUser user) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: user.isFrozen
              ? Colors.red.withValues(alpha: 0.5)
              : user.isActive
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2),
          width: user.isFrozen ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showUserDetails(user),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF6366F1),
                    backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                        ? Text(
                            (user.fullName?.isNotEmpty == true
                                ? user.fullName![0].toUpperCase()
                                : user.email?.isNotEmpty == true
                                    ? user.email![0].toUpperCase()
                                    : 'U'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          )
                        : null,
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey[600], size: 20),
                    onSelected: (value) => _handleMenuAction(value, user),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Düzenle'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'balance',
                        child: Row(
                          children: [
                            Icon(Icons.account_balance_wallet, size: 18),
                            SizedBox(width: 8),
                            Text('Bakiye İşlemleri'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: user.isActive ? 'deactivate' : 'activate',
                        child: Row(
                          children: [
                            Icon(
                              user.isActive ? Icons.block : Icons.check_circle,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(user.isActive ? 'Pasifleştir' : 'Aktifleştir'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: user.isFrozen ? 'unfreeze' : 'freeze',
                        child: Row(
                          children: [
                            Icon(
                              user.isFrozen ? Icons.lock_open : Icons.lock,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(user.isFrozen ? 'Donmayı Kaldır' : 'Hesabı Dondur'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'close',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Hesabı Kapat', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: Text(
                  user.fullName ?? user.username ?? user.email ?? 'İsimsiz',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              if (user.email != null)
                Flexible(
                  child: Text(
                    user.email!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bakiye',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        '₺${user.balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (user.isFrozen)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'DONDURULDU',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else if (!user.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PASIF',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'AKTIF',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(String action, MobileUser user) {
    switch (action) {
      case 'edit':
        _showEditUserDialog(user);
        break;
      case 'balance':
        _showBalanceDialog(user);
        break;
      case 'activate':
        _activateUser(user);
        break;
      case 'deactivate':
        _deactivateUser(user);
        break;
      case 'freeze':
        _freezeUser(user, true);
        break;
      case 'unfreeze':
        _freezeUser(user, false);
        break;
      case 'close':
        _closeAccount(user);
        break;
    }
  }

  Future<void> _showUserDetails(MobileUser user) async {
    final tokens = await _fcmService.getUserFCMTokens(user.id);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${user.fullName ?? user.username ?? "Kullanıcı"} Detayları'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Kullanıcı ID', user.id),
              if (user.username != null) _buildDetailRow('Kullanıcı Adı', user.username!),
              if (user.email != null) _buildDetailRow('E-posta', user.email!),
              if (user.phoneNumber != null) _buildDetailRow('Telefon', user.phoneNumber!),
              if (user.fullName != null) _buildDetailRow('Ad Soyad', user.fullName!),
              _buildDetailRow('Bakiye', '₺${user.balance.toStringAsFixed(2)}'),
              _buildDetailRow('Durum', user.isActive ? 'Aktif' : 'Pasif'),
              _buildDetailRow('Dondurma', user.isFrozen ? 'Dondurulmuş' : 'Normal'),
              _buildDetailRow('Kayıt Tarihi', _formatDate(user.createdAt)),
              if (user.lastLogin != null) _buildDetailRow('Son Giriş', _formatDate(user.lastLogin!)),
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tokens.isNotEmpty
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: tokens.isNotEmpty
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          tokens.isNotEmpty ? Icons.check_circle : Icons.warning,
                          color: tokens.isNotEmpty ? Colors.green : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'FCM Token Durumu',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: tokens.isNotEmpty ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (tokens.isNotEmpty)
                      Text(
                        '✅ ${tokens.length} aktif cihaz bulundu',
                        style: const TextStyle(fontSize: 12, color: Colors.green),
                      )
                    else
                      Text(
                        '⚠️ FCM token bulunamadı',
                        style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditUserDialog(user);
            },
            child: const Text('Düzenle'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showEditUserDialog(MobileUser user) {
    final emailController = TextEditingController(text: user.email ?? '');
    final phoneController = TextEditingController(text: user.phoneNumber ?? '');
    final passwordController = TextEditingController();
    final nameController = TextEditingController(text: user.fullName ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcı Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefon Numarası',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Yeni Şifre (Değiştirmek için)',
                  border: OutlineInputBorder(),
                  helperText: 'Boş bırakırsanız şifre değişmez',
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _updateUser(
                user,
                emailController.text,
                phoneController.text,
                passwordController.text,
                nameController.text,
              );
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUser(
    MobileUser user,
    String email,
    String phone,
    String password,
    String name,
  ) async {
    // Loading göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final updatedUser = user.copyWith(
        email: email.isNotEmpty ? email : null,
        phoneNumber: phone.isNotEmpty ? phone : null,
        fullName: name.isNotEmpty ? name : null,
      );

      await _userService.updateUser(updatedUser);

      if (password.isNotEmpty) {
        await _userService.changePassword(user.id, password);
      }

      if (email.isNotEmpty && email != user.email) {
        await _userService.updateEmail(user.id, email);
      }

      if (phone.isNotEmpty && phone != user.phoneNumber) {
        await _userService.updatePhoneNumber(user.id, phone);
      }

      if (mounted) {
        Navigator.pop(context); // Loading'i kapat
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kullanıcı başarıyla güncellendi'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Loading'i kapat
        
        final errorMsg = e.toString();
        final isPermissionError = errorMsg.contains('permission-denied') || 
                                  errorMsg.contains('permission denied') ||
                                  errorMsg.contains('Missing or insufficient permissions');
        
        if (isPermissionError) {
          _showPermissionErrorDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  void _showBalanceDialog(MobileUser user) {
    showDialog(
      context: context,
      builder: (context) => _BalanceDialog(
        user: user,
        userService: _userService,
      ),
    ).then((_) => _loadStatistics());
  }

  Future<void> _activateUser(MobileUser user) async {
    // Loading göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await _userService.toggleUserStatus(user.id, true);
      if (mounted) {
        Navigator.pop(context); // Loading'i kapat
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kullanıcı aktifleştirildi'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Loading'i kapat
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _deactivateUser(MobileUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcıyı Pasifleştir'),
        content: const Text('Bu kullanıcıyı pasifleştirmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Pasifleştir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        await _userService.toggleUserStatus(user.id, false);
        if (mounted) {
          Navigator.pop(context); // Loading'i kapat
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kullanıcı pasifleştirildi'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Loading'i kapat
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  Future<void> _freezeUser(MobileUser user, bool freeze) async {
    final action = freeze ? 'Dondur' : 'Donmayı Kaldır';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hesabı $action'),
        content: Text(
          freeze
              ? 'Bu hesabı dondurmak istediğinizden emin misiniz? Kullanıcı sisteme giriş yapamayacak.'
              : 'Hesabın donmasını kaldırmak istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: freeze ? Colors.red : Colors.green,
            ),
            child: Text(action),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        await _userService.freezeUser(user.id, freeze);
        if (mounted) {
          Navigator.pop(context); // Loading'i kapat
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(freeze ? 'Hesap donduruldu' : 'Hesap donması kaldırıldı'),
              backgroundColor: freeze ? Colors.red : Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Loading'i kapat
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  Future<void> _closeAccount(MobileUser user) async {
    String? action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesap İşlemi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hesap için ne yapmak istersiniz?'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, 'deactivate'),
              icon: const Icon(Icons.block, size: 20),
              label: const Text('Hesabı Kapat (Pasif Yap)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, 'delete'),
              icon: const Icon(Icons.delete_forever, size: 20),
              label: const Text('Hesabı Tamamen Sil'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );

    if (action == null) return;

    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Hesabı Sil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bu işlem geri alınamaz! Hesap ve tüm verileri kalıcı olarak silinecek.',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 12),
              Text('Kullanıcı: ${user.fullName ?? user.username ?? user.email ?? "Bilinmeyen"}'),
              Text('Bakiye: ₺${user.balance.toStringAsFixed(2)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('EVET, SİL'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Loading göster
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        try {
          await _userService.deleteUser(user.id);
          if (mounted) {
            Navigator.pop(context); // Loading'i kapat
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Hesap başarıyla silindi'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            _loadStatistics();
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context); // Loading'i kapat
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Hesap silinirken hata oluştu: ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
    } else if (action == 'deactivate') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Hesabı Kapat'),
          content: const Text(
            'Hesap pasif yapılacak ve kullanıcı sisteme giriş yapamayacak. Hesap verileri korunacak.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Kapat'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Loading göster
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        try {
          await _userService.deactivateUser(user.id);
          if (mounted) {
            Navigator.pop(context); // Loading'i kapat
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Hesap kapatıldı (pasif yapıldı)'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context); // Loading'i kapat
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Hata: ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showPermissionErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Firebase İzin Hatası'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Firebase Firestore izinleri yapılandırılmamış. Lütfen aşağıdaki adımları izleyin:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStep('1', 'Firebase Console\'a gidin (https://console.firebase.google.com)'),
            _buildStep('2', 'Projenizi seçin'),
            _buildStep('3', 'Firestore Database > Rules sekmesine gidin'),
            _buildStep('4', 'firestore.rules dosyasındaki kuralları kopyalayıp yapıştırın'),
            _buildStep('5', 'Publish butonuna tıklayın'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// Bakiye İşlemleri Dialogu
class _BalanceDialog extends StatefulWidget {
  final MobileUser user;
  final MobileUserService userService;

  const _BalanceDialog({
    required this.user,
    required this.userService,
  });

  @override
  State<_BalanceDialog> createState() => _BalanceDialogState();
}

class _BalanceDialogState extends State<_BalanceDialog> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = false;
  String _selectedAction = 'deposit';

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance_wallet, color: Color(0xFF10B981)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.fullName ?? widget.user.email ?? 'Kullanıcı',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Mevcut Bakiye: ₺${widget.user.balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'deposit',
                  label: Text('Bakiye Yükle'),
                  icon: Icon(Icons.add),
                ),
                ButtonSegment(
                  value: 'withdraw',
                  label: Text('Bakiye Çek'),
                  icon: Icon(Icons.remove),
                ),
              ],
              selected: {_selectedAction},
              onSelectionChanged: (Set<String> selection) {
                setState(() {
                  _selectedAction = selection.first;
                });
              },
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Miktar (₺)',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Not (Opsiyonel)',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _processBalance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedAction == 'deposit'
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_selectedAction == 'deposit' ? 'Yükle' : 'Çek'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processBalance() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Miktar girmelisiniz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geçerli bir miktar girin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_selectedAction == 'deposit') {
        await widget.userService.addBalance(
          widget.user.id,
          amount,
          _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('₺${amount.toStringAsFixed(2)} bakiyesi yüklendi'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await widget.userService.deductBalance(
          widget.user.id,
          amount,
          _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('₺${amount.toStringAsFixed(2)} bakiyesi çekildi'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString();
        final isPermissionError = errorMsg.contains('permission-denied') || 
                                  errorMsg.contains('permission denied') ||
                                  errorMsg.contains('Missing or insufficient permissions') ||
                                  errorMsg.contains('Firebase izin hatası');
        
        if (isPermissionError) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Firebase İzin Hatası'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Firebase Firestore izinleri yapılandırılmamış. Lütfen aşağıdaki adımları izleyin:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildStep('1', 'Firebase Console\'a gidin'),
                  _buildStep('2', 'Firestore Database > Rules'),
                  _buildStep('3', 'firestore.rules dosyasındaki kuralları yapıştırın'),
                  _buildStep('4', 'Publish butonuna tıklayın'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tamam'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: ${errorMsg.replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

