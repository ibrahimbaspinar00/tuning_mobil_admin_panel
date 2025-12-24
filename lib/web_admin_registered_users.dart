import 'package:flutter/material.dart';
import 'model/admin_user.dart';
import 'model/mobile_user.dart';
import 'services/admin_service.dart';
import 'services/mobile_user_service.dart';

class WebAdminRegisteredUsers extends StatefulWidget {
  const WebAdminRegisteredUsers({super.key});

  @override
  State<WebAdminRegisteredUsers> createState() => _WebAdminRegisteredUsersState();
}

class _WebAdminRegisteredUsersState extends State<WebAdminRegisteredUsers> with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  final MobileUserService _mobileUserService = MobileUserService();
  final TextEditingController _searchController = TextEditingController();
  
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedRole = 'Tümü'; // Admin kullanıcılar için
  String _selectedStatus = 'Tümü'; // Mobil kullanıcılar için
  String _viewMode = 'list'; // 'grid' or 'list'
  String _sortBy = 'createdAt'; // 'name', 'email', 'createdAt', 'lastLogin'
  Set<String> _selectedAdminUserIds = {};
  Set<String> _selectedMobileUserIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kullanıcı Yönetim Paneli',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tüm kullanıcıları görüntüleyin, yönetin ve detaylı analiz yapın',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Tab Bar
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF6366F1),
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: const Color(0xFF6366F1),
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.admin_panel_settings),
                      text: 'Admin Kullanıcılar',
                    ),
                    Tab(
                      icon: Icon(Icons.phone_android),
                      text: 'Mobil/Web Kullanıcılar',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Filtreler ve Arama
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Kullanıcı adı, e-posta veya ad soyad ile ara...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
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
                    const SizedBox(width: 12),
                    // Görünüm modu
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'list',
                          icon: Icon(Icons.list),
                          label: Text('Liste'),
                        ),
                        ButtonSegment(
                          value: 'grid',
                          icon: Icon(Icons.grid_view),
                          label: Text('Grid'),
                        ),
                      ],
                      selected: {_viewMode},
                      onSelectionChanged: (Set<String> selection) {
                        setState(() {
                          _viewMode = selection.first;
                        });
                      },
                    ),
                  ],
                ),
                // Filtreler (Tab'a göre)
                if (_tabController.index == 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedRole,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 'Tümü', child: Text('Tüm Roller')),
                            DropdownMenuItem(value: 'admin', child: Text('Admin')),
                            DropdownMenuItem(value: 'moderator', child: Text('Moderatör')),
                            DropdownMenuItem(value: 'user', child: Text('Kullanıcı')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
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
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedStatus = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButton<String>(
                          value: _sortBy,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 'createdAt', child: Text('Kayıt Tarihi')),
                            DropdownMenuItem(value: 'name', child: Text('İsim')),
                            DropdownMenuItem(value: 'email', child: Text('E-posta')),
                            DropdownMenuItem(value: 'lastLogin', child: Text('Son Giriş')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _sortBy = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
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
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButton<String>(
                          value: _sortBy,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 'createdAt', child: Text('Kayıt Tarihi')),
                            DropdownMenuItem(value: 'name', child: Text('İsim')),
                            DropdownMenuItem(value: 'email', child: Text('E-posta')),
                            DropdownMenuItem(value: 'balance', child: Text('Bakiye')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _sortBy = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
                // Toplu işlem butonu
                if ((_tabController.index == 0 && _selectedAdminUserIds.isNotEmpty) ||
                    (_tabController.index == 1 && _selectedMobileUserIds.isNotEmpty)) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_tabController.index == 0) {
                        _showBulkAdminActionsDialog();
                      } else {
                        _showBulkMobileActionsDialog();
                      }
                    },
                    icon: const Icon(Icons.batch_prediction),
                    label: Text(
                      'Toplu İşlem (${_tabController.index == 0 ? _selectedAdminUserIds.length : _selectedMobileUserIds.length})',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // User List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAdminUsersList(),
                _buildMobileUsersList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminUsersList() {
    return StreamBuilder<List<AdminUser>>(
      stream: _adminService.getUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Hata: ${snapshot.error}',
                  style: TextStyle(color: Colors.red[600]),
                ),
              ],
            ),
          );
        }

        List<AdminUser> users = snapshot.data ?? [];
        
        // Arama filtresi
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          users = users.where((user) {
            return user.username.toLowerCase().contains(query) ||
                   user.email.toLowerCase().contains(query) ||
                   user.fullName.toLowerCase().contains(query);
          }).toList();
        }

        // Rol filtresi
        if (_selectedRole != 'Tümü') {
          users = users.where((user) =>
              user.role.toLowerCase() == _selectedRole.toLowerCase()).toList();
        }

        // Durum filtresi
        if (_selectedStatus != 'Tümü') {
          final isActive = _selectedStatus == 'Aktif';
          users = users.where((user) => user.isActive == isActive).toList();
        }

        // Sıralama
        users.sort((a, b) {
          switch (_sortBy) {
            case 'name':
              return a.fullName.compareTo(b.fullName);
            case 'email':
              return a.email.compareTo(b.email);
            case 'lastLogin':
              return b.lastLogin.compareTo(a.lastLogin);
            case 'createdAt':
            default:
              return b.createdAt.compareTo(a.createdAt);
          }
        });

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'Arama kriterlerinize uygun kullanıcı bulunamadı'
                      : 'Henüz admin kullanıcı bulunmuyor',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        if (_viewMode == 'grid') {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: users.length,
            itemBuilder: (context, index) {
              return _buildAdminUserCard(users[index]);
            },
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            return _buildAdminUserListItem(users[index]);
          },
        );
      },
    );
  }

  Widget _buildMobileUsersList() {
    return StreamBuilder<List<MobileUser>>(
      stream: _mobileUserService.getUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Hata: ${snapshot.error}',
                  style: TextStyle(color: Colors.red[600]),
                ),
              ],
            ),
          );
        }

        List<MobileUser> users = snapshot.data ?? [];
        
        // Arama filtresi
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          users = users.where((user) {
            return (user.username?.toLowerCase().contains(query) ?? false) ||
                   (user.email?.toLowerCase().contains(query) ?? false) ||
                   (user.fullName?.toLowerCase().contains(query) ?? false) ||
                   (user.phoneNumber?.toLowerCase().contains(query) ?? false);
          }).toList();
        }

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'Arama kriterlerinize uygun kullanıcı bulunamadı'
                      : 'Henüz mobil kullanıcı bulunmuyor',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        if (_viewMode == 'grid') {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: users.length + 1, // +1 for statistics
            itemBuilder: (context, index) {
              if (index == users.length) {
                return const SizedBox.shrink(); // Placeholder for grid
              }
              return _buildMobileUserCard(users[index]);
            },
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length + 1, // +1 for statistics
          itemBuilder: (context, index) {
            if (index == users.length) {
              // İstatistikler - En altta
              return StreamBuilder<List<AdminUser>>(
                stream: _adminService.getUsers(),
                builder: (context, adminSnapshot) {
                  return StreamBuilder<List<MobileUser>>(
                    stream: _mobileUserService.getUsers(),
                    builder: (context, mobileSnapshot) {
                      if (!adminSnapshot.hasData || !mobileSnapshot.hasData) {
                        return const SizedBox.shrink();
                      }
                      
                      final adminUsers = adminSnapshot.data ?? [];
                      final mobileUsers = mobileSnapshot.data ?? [];
                      
                      final totalAdmin = adminUsers.length;
                      final activeAdmin = adminUsers.where((u) => u.isActive).length;
                      final totalMobile = mobileUsers.length;
                      final activeMobile = mobileUsers.where((u) => u.isActive && !u.isFrozen).length;
                      final frozenMobile = mobileUsers.where((u) => u.isFrozen).length;
                      
                      return Container(
                        margin: const EdgeInsets.only(top: 24),
                        padding: const EdgeInsets.all(24),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'İstatistikler',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _buildStatCard('Toplam Admin', totalAdmin.toString(), Icons.admin_panel_settings, Colors.red),
                                const SizedBox(width: 12),
                                _buildStatCard('Aktif Admin', activeAdmin.toString(), Icons.check_circle, Colors.green),
                                const SizedBox(width: 12),
                                _buildStatCard('Toplam Mobil', totalMobile.toString(), Icons.phone_android, Colors.blue),
                                const SizedBox(width: 12),
                                _buildStatCard('Aktif Mobil', activeMobile.toString(), Icons.check_circle, Colors.green),
                                const SizedBox(width: 12),
                                _buildStatCard('Dondurulmuş', frozenMobile.toString(), Icons.lock, Colors.orange),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            }
            return _buildMobileUserListItem(users[index]);
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // İstatistik kartı
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Admin kullanıcı liste öğesi
  Widget _buildAdminUserListItem(AdminUser user) {
    final isSelected = _selectedAdminUserIds.contains(user.id);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF6366F1) : Colors.grey.withValues(alpha: 0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedAdminUserIds.add(user.id);
                  } else {
                    _selectedAdminUserIds.remove(user.id);
                  }
                });
              },
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: user.isActive ? Colors.green : Colors.red,
              child: Text(
                user.username.isNotEmpty 
                    ? user.username[0].toUpperCase() 
                    : user.email.isNotEmpty 
                        ? user.email[0].toUpperCase() 
                        : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        title: Text(
          user.fullName.isNotEmpty ? user.fullName : user.username,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kullanıcı Adı: ${user.username}'),
            Text('E-posta: ${user.email}'),
            Text('Rol: ${user.role}'),
            Text('Kayıt Tarihi: ${_formatDate(user.createdAt)}'),
            Text('Son Giriş: ${_formatDate(user.lastLogin)}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: user.isActive ? Colors.green[100] : Colors.red[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user.isActive ? 'Aktif' : 'Pasif',
                style: TextStyle(
                  color: user.isActive ? Colors.green[800] : Colors.red[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.menu),
              onSelected: (value) => _handleAdminUserAction(value, user),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: user.isActive ? 'deactivate' : 'activate',
                  child: Row(
                    children: [
                      Icon(
                        user.isActive ? Icons.block : Icons.check_circle,
                        size: 18,
                        color: user.isActive ? Colors.orange : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        user.isActive ? 'Pasifleştir' : 'Aktifleştir',
                        style: TextStyle(
                          color: user.isActive ? Colors.orange : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Hesap Sil', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  // Admin kullanıcı kartı (Grid)
  Widget _buildAdminUserCard(AdminUser user) {
    final isSelected = _selectedAdminUserIds.contains(user.id);
    
    return Card(
      elevation: isSelected ? 4 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? const Color(0xFF6366F1) : Colors.grey.withValues(alpha: 0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedAdminUserIds.add(user.id);
                      } else {
                        _selectedAdminUserIds.remove(user.id);
                      }
                    });
                  },
                ),
                Expanded(
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: user.isActive ? Colors.green : Colors.red,
                    child: Text(
                      user.username.isNotEmpty 
                          ? user.username[0].toUpperCase() 
                          : user.email.isNotEmpty 
                              ? user.email[0].toUpperCase() 
                              : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.menu, size: 20),
                  onSelected: (value) => _handleAdminUserAction(value, user),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: user.isActive ? 'deactivate' : 'activate',
                      child: Row(
                        children: [
                          Icon(
                            user.isActive ? Icons.block : Icons.check_circle,
                            size: 18,
                            color: user.isActive ? Colors.orange : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            user.isActive ? 'Pasifleştir' : 'Aktifleştir',
                            style: TextStyle(
                              color: user.isActive ? Colors.orange : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hesap Sil', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              user.fullName.isNotEmpty ? user.fullName : user.username,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getRoleColor(user.role).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                user.role,
                style: TextStyle(
                  color: _getRoleColor(user.role),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: user.isActive ? Colors.green[100] : Colors.red[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user.isActive ? 'Aktif' : 'Pasif',
                style: TextStyle(
                  color: user.isActive ? Colors.green[800] : Colors.red[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mobil kullanıcı liste öğesi
  Widget _buildMobileUserListItem(MobileUser user) {
    final isSelected = _selectedMobileUserIds.contains(user.id);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF6366F1) : Colors.grey.withValues(alpha: 0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedMobileUserIds.add(user.id);
                  } else {
                    _selectedMobileUserIds.remove(user.id);
                  }
                });
              },
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: user.isActive && !user.isFrozen 
                  ? Colors.green 
                  : user.isFrozen 
                      ? Colors.orange 
                      : Colors.red,
              child: Text(
                (user.username?.isNotEmpty ?? false)
                    ? user.username![0].toUpperCase()
                    : (user.email?.isNotEmpty ?? false)
                        ? user.email![0].toUpperCase()
                        : (user.fullName?.isNotEmpty ?? false)
                            ? user.fullName![0].toUpperCase()
                            : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        title: Text(
          user.fullName ?? user.username ?? user.email ?? 'Bilinmeyen',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.username != null) Text('Kullanıcı Adı: ${user.username}'),
            if (user.email != null) Text('E-posta: ${user.email}'),
            if (user.phoneNumber != null) Text('Telefon: ${user.phoneNumber}'),
            Text('Bakiye: ₺${user.balance.toStringAsFixed(2)}'),
            Text('Kayıt Tarihi: ${_formatDate(user.createdAt)}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: user.isActive && !user.isFrozen
                    ? Colors.green[100]
                    : user.isFrozen
                        ? Colors.orange[100]
                        : Colors.red[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user.isFrozen
                    ? 'Dondurulmuş'
                    : user.isActive
                        ? 'Aktif'
                        : 'Pasif',
                style: TextStyle(
                  color: user.isActive && !user.isFrozen
                      ? Colors.green[800]
                      : user.isFrozen
                          ? Colors.orange[800]
                          : Colors.red[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) => _handleMobileUserAction(value, user),
              itemBuilder: (context) => [
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
                      Icon(Icons.delete_outline, size: 18, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Hesabı Kapat', style: TextStyle(color: Colors.orange)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Kalıcı Sil', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  // Mobil kullanıcı kartı (Grid)
  Widget _buildMobileUserCard(MobileUser user) {
    final isSelected = _selectedMobileUserIds.contains(user.id);
    
    return Card(
      elevation: isSelected ? 4 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? const Color(0xFF6366F1) : Colors.grey.withValues(alpha: 0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedMobileUserIds.add(user.id);
                      } else {
                        _selectedMobileUserIds.remove(user.id);
                      }
                    });
                  },
                ),
                Expanded(
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: user.isActive && !user.isFrozen 
                        ? Colors.green 
                        : user.isFrozen 
                            ? Colors.orange 
                            : Colors.red,
                    child: Text(
                      (user.username?.isNotEmpty ?? false)
                          ? user.username![0].toUpperCase()
                          : (user.email?.isNotEmpty ?? false)
                              ? user.email![0].toUpperCase()
                              : (user.fullName?.isNotEmpty ?? false)
                                  ? user.fullName![0].toUpperCase()
                                  : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (value) => _handleMobileUserAction(value, user),
                  itemBuilder: (context) => [
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
                          Icon(Icons.delete_outline, size: 18, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Hesabı Kapat', style: TextStyle(color: Colors.orange)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_forever, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Kalıcı Sil', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              user.fullName ?? user.username ?? user.email ?? 'Bilinmeyen',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            if (user.email != null)
              Text(
                user.email!,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 8),
            Text(
              'Bakiye: ₺${user.balance.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: user.isActive && !user.isFrozen
                    ? Colors.green[100]
                    : user.isFrozen
                        ? Colors.orange[100]
                        : Colors.red[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user.isFrozen
                    ? 'Dondurulmuş'
                    : user.isActive
                        ? 'Aktif'
                        : 'Pasif',
                style: TextStyle(
                  color: user.isActive && !user.isFrozen
                      ? Colors.green[800]
                      : user.isFrozen
                          ? Colors.orange[800]
                          : Colors.red[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'moderator':
        return Colors.orange;
      case 'user':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Toplu işlemler
  void _showBulkAdminActionsDialog() {
    if (_selectedAdminUserIds.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Toplu İşlem (${_selectedAdminUserIds.length} kullanıcı)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _bulkToggleAdminUsers(true);
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Aktifleştir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _bulkToggleAdminUsers(false);
              },
              icon: const Icon(Icons.block),
              label: const Text('Pasifleştir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showBulkDeleteAdminDialog();
              },
              icon: const Icon(Icons.delete),
              label: const Text('Sil'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
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
  }

  void _showBulkMobileActionsDialog() {
    if (_selectedMobileUserIds.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Toplu İşlem (${_selectedMobileUserIds.length} kullanıcı)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _bulkToggleMobileUsers(true);
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Aktifleştir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _bulkToggleMobileUsers(false);
              },
              icon: const Icon(Icons.block),
              label: const Text('Pasifleştir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _bulkFreezeMobileUsers(true);
              },
              icon: const Icon(Icons.lock),
              label: const Text('Dondur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showBulkDeleteMobileDialog();
              },
              icon: const Icon(Icons.delete_forever),
              label: const Text('Kalıcı Sil'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[900],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
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
  }

  Future<void> _bulkToggleAdminUsers(bool isActive) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    int successCount = 0;
    int failCount = 0;

    try {
      final users = await _adminService.getUsers().first;
      final usersToUpdate = users.where((u) => _selectedAdminUserIds.contains(u.id)).toList();
      
      for (var user in usersToUpdate) {
        try {
          final updatedUser = user.copyWith(isActive: isActive);
          await _adminService.updateUser(updatedUser);
          successCount++;
        } catch (e) {
          failCount++;
        }
      }

      if (mounted) {
        Navigator.pop(context);
        setState(() {
          _selectedAdminUserIds.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$successCount kullanıcı ${isActive ? 'aktifleştirildi' : 'pasifleştirildi'}${failCount > 0 ? ', $failCount başarısız' : ''}',
            ),
            backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
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

  Future<void> _bulkToggleMobileUsers(bool isActive) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    int successCount = 0;
    int failCount = 0;

    try {
      final users = await _mobileUserService.getUsers().first;
      final usersToUpdate = users.where((u) => _selectedMobileUserIds.contains(u.id)).toList();
      
      for (var user in usersToUpdate) {
        try {
          await _mobileUserService.toggleUserStatus(user.id, isActive);
          successCount++;
        } catch (e) {
          failCount++;
        }
      }

      if (mounted) {
        Navigator.pop(context);
        setState(() {
          _selectedMobileUserIds.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$successCount kullanıcı ${isActive ? 'aktifleştirildi' : 'pasifleştirildi'}${failCount > 0 ? ', $failCount başarısız' : ''}',
            ),
            backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
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

  Future<void> _bulkFreezeMobileUsers(bool freeze) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    int successCount = 0;
    int failCount = 0;

    try {
      final users = await _mobileUserService.getUsers().first;
      final usersToUpdate = users.where((u) => _selectedMobileUserIds.contains(u.id)).toList();
      
      for (var user in usersToUpdate) {
        try {
          await _mobileUserService.freezeUser(user.id, freeze);
          successCount++;
        } catch (e) {
          failCount++;
        }
      }

      if (mounted) {
        Navigator.pop(context);
        setState(() {
          _selectedMobileUserIds.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$successCount kullanıcı ${freeze ? 'donduruldu' : 'donması kaldırıldı'}${failCount > 0 ? ', $failCount başarısız' : ''}',
            ),
            backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
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

  void _showBulkDeleteAdminDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Toplu Silme'),
        content: Text(
          '${_selectedAdminUserIds.length} admin kullanıcıyı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _bulkDeleteAdminUsers();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _showBulkDeleteMobileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Toplu Silme'),
        content: Text(
          '${_selectedMobileUserIds.length} mobil kullanıcıyı kalıcı olarak silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _bulkDeleteMobileUsers();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Kalıcı Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _bulkDeleteAdminUsers() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    int successCount = 0;
    int failCount = 0;

    try {
      final users = await _adminService.getUsers().first;
      final usersToDelete = users.where((u) => _selectedAdminUserIds.contains(u.id)).toList();
      
      for (var user in usersToDelete) {
        try {
          await _adminService.deleteUser(user.id);
          successCount++;
        } catch (e) {
          failCount++;
        }
      }

      if (mounted) {
        Navigator.pop(context);
        setState(() {
          _selectedAdminUserIds.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$successCount kullanıcı silindi${failCount > 0 ? ', $failCount başarısız' : ''}',
            ),
            backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
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

  Future<void> _bulkDeleteMobileUsers() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    int successCount = 0;
    int failCount = 0;

    try {
      final users = await _mobileUserService.getUsers().first;
      final usersToDelete = users.where((u) => _selectedMobileUserIds.contains(u.id)).toList();
      
      for (var user in usersToDelete) {
        try {
          await _mobileUserService.deleteUser(user.id);
          successCount++;
        } catch (e) {
          failCount++;
        }
      }

      if (mounted) {
        Navigator.pop(context);
        setState(() {
          _selectedMobileUserIds.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$successCount kullanıcı silindi${failCount > 0 ? ', $failCount başarısız' : ''}',
            ),
            backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
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

  // Admin kullanıcı işlemleri
  void _handleAdminUserAction(String action, AdminUser user) {
    switch (action) {
      case 'activate':
        _toggleAdminUserStatus(user, true);
        break;
      case 'deactivate':
        _toggleAdminUserStatus(user, false);
        break;
      case 'delete':
        _deleteAdminUser(user);
        break;
    }
  }

  // Mobil kullanıcı işlemleri
  void _handleMobileUserAction(String action, MobileUser user) {
    switch (action) {
      case 'activate':
        _activateMobileUser(user);
        break;
      case 'deactivate':
        _deactivateMobileUser(user);
        break;
      case 'freeze':
        _freezeMobileUser(user, true);
        break;
      case 'unfreeze':
        _freezeMobileUser(user, false);
        break;
      case 'close':
        _closeMobileUserAccount(user);
        break;
      case 'delete':
        _deleteMobileUser(user);
        break;
    }
  }

  // Admin kullanıcı durum değiştirme
  Future<void> _toggleAdminUserStatus(AdminUser user, bool isActive) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final updatedUser = user.copyWith(isActive: isActive);
      await _adminService.updateUser(updatedUser);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${user.fullName} ${isActive ? 'aktifleştirildi' : 'pasifleştirildi'}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
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

  // Admin kullanıcı silme
  Future<void> _deleteAdminUser(AdminUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcı Sil'),
        content: Text(
          '${user.fullName} kullanıcısını silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        await _adminService.deleteUser(user.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${user.fullName} silindi'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
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

  // Mobil kullanıcı aktifleştirme
  Future<void> _activateMobileUser(MobileUser user) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await _mobileUserService.toggleUserStatus(user.id, true);
      if (mounted) {
        Navigator.pop(context);
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
        Navigator.pop(context);
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

  // Mobil kullanıcı pasifleştirme
  Future<void> _deactivateMobileUser(MobileUser user) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await _mobileUserService.toggleUserStatus(user.id, false);
      if (mounted) {
        Navigator.pop(context);
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
        Navigator.pop(context);
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

  // Mobil kullanıcı dondurma
  Future<void> _freezeMobileUser(MobileUser user, bool freeze) async {
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        await _mobileUserService.freezeUser(user.id, freeze);
        if (mounted) {
          Navigator.pop(context);
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
          Navigator.pop(context);
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

  // Mobil kullanıcı hesabı kapatma
  Future<void> _closeMobileUserAccount(MobileUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabı Kapat'),
        content: Text(
          '${user.fullName ?? user.username ?? "Bu"} hesabını kapatmak istediğinizden emin misiniz? Hesap pasif hale gelecek ve dondurulacak.',
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        await _mobileUserService.deactivateUser(user.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hesap kapatıldı'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
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

  // Mobil kullanıcı silme
  Future<void> _deleteMobileUser(MobileUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcıyı Kalıcı Olarak Sil'),
        content: Text(
          '${user.fullName ?? user.username ?? "Bu"} kullanıcısını kalıcı olarak silmek istediğinizden emin misiniz? Bu işlem geri alınamaz ve tüm veriler silinecektir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Kalıcı Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        await _mobileUserService.deleteUser(user.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kullanıcı kalıcı olarak silindi'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
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

