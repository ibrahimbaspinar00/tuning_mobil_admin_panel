import 'dart:async';
import 'package:flutter/material.dart';
import 'model/admin_user.dart';
import 'services/admin_service.dart';
import 'services/permission_service.dart';

class WebAdminUserManagement extends StatefulWidget {
  const WebAdminUserManagement({super.key});

  @override
  State<WebAdminUserManagement> createState() => _WebAdminUserManagementState();
}

class _WebAdminUserManagementState extends State<WebAdminUserManagement> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = 'Tümü';
  String _selectedStatus = 'Tümü';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                                'Admin Kullanıcı Yönetimi',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sistem yöneticilerini ve yetkilerini yönetin',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                              if (PermissionService.canCreateUsers()) ...[
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _showAddUserDialog(),
                                    icon: const Icon(Icons.person_add),
                                    label: const Text('Yeni Kullanıcı'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6366F1),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Admin Kullanıcı Yönetimi',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Sistem yöneticilerini ve yetkilerini yönetin',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (PermissionService.canCreateUsers())
                                ElevatedButton.icon(
                                  onPressed: () => _showAddUserDialog(),
                                  icon: const Icon(Icons.person_add),
                                  label: const Text('Yeni Kullanıcı'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6366F1),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                    const SizedBox(height: 24),
                    // Filters - Responsive layout
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
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
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
                            onChanged: (value) => setState(() {}),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: DropdownButton<String>(
                                    value: _selectedRole,
                                    underline: const SizedBox(),
                                    isExpanded: true,
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
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
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
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedStatus = value!;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
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
                                hintText: 'Kullanıcı adı, email veya ad soyad ile ara...',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          setState(() {
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
                              onChanged: (value) => setState(() {}),
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
                  child: _buildUserList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<List<AdminUser>>(
      stream: _adminService.getUsers(),
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

        List<AdminUser> users = snapshot.data ?? [];

        // Filtering
        if (_searchController.text.isNotEmpty) {
          final query = _searchController.text.toLowerCase();
          users = users.where((user) =>
              user.fullName.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query) ||
              user.username.toLowerCase().contains(query)).toList();
        }

        if (_selectedRole != 'Tümü') {
          users = users.where((user) =>
              user.role.toLowerCase() == _selectedRole.toLowerCase()).toList();
        }

        if (_selectedStatus != 'Tümü') {
          final isActive = _selectedStatus == 'Aktif';
          users = users.where((user) => user.isActive == isActive).toList();
        }

        if (users.isEmpty) {
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
                const SizedBox(height: 8),
                Text(
                  'Arama kriterlerinizi değiştirmeyi deneyin',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        // Responsive grid: mobil için 1-2, tablet için 3, desktop için 4-5 sütun
        final screenWidth = MediaQuery.of(context).size.width;
        int crossAxisCount;
        double childAspectRatio;
        
        if (screenWidth < 600) {
          // Mobil
          crossAxisCount = 1;
          childAspectRatio = 3.5;
        } else if (screenWidth < 900) {
          // Küçük tablet
          crossAxisCount = 2;
          childAspectRatio = 2.2;
        } else if (screenWidth < 1200) {
          // Tablet
          crossAxisCount = 3;
          childAspectRatio = 1.8;
        } else if (screenWidth < 1600) {
          // Küçük desktop
          crossAxisCount = 4;
          childAspectRatio = 1.5;
        } else {
          // Büyük desktop
          crossAxisCount = 5;
          childAspectRatio = 1.3;
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

  Widget _buildUserCard(AdminUser user) {
    final roleColor = _getRoleColor(user.role);
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: user.isActive
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
          width: 1,
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
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: roleColor.withValues(alpha: 0.2),
                    child: Text(
                      user.fullName.isNotEmpty
                          ? user.fullName[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        color: roleColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey[600], size: 20),
                    onSelected: (value) => _handleMenuAction(value, user),
                    itemBuilder: (context) => [
                      if (PermissionService.canUpdateUsers())
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
                      if (PermissionService.canDeleteUsers())
                        const PopupMenuDivider(),
                      if (PermissionService.canDeleteUsers())
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Sil', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                user.fullName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getRoleDisplayName(user.role),
                      style: TextStyle(
                        fontSize: 12,
                        color: roleColor,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: user.isActive
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      user.isActive ? 'Aktif' : 'Pasif',
                      style: TextStyle(
                        fontSize: 12,
                        color: user.isActive ? Colors.green[700] : Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Admin';
      case 'moderator':
        return 'Moderatör';
      case 'user':
        return 'Kullanıcı';
      default:
        return role;
    }
  }

  void _handleMenuAction(String action, AdminUser user) {
    switch (action) {
      case 'edit':
        _showEditUserDialog(user);
        break;
      case 'activate':
        _toggleUserStatus(user, true);
        break;
      case 'deactivate':
        _toggleUserStatus(user, false);
        break;
      case 'delete':
        _showDeleteUserDialog(user);
        break;
    }
  }

  void _showUserDetails(AdminUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.fullName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Kullanıcı Adı', user.username),
              _buildDetailRow('E-posta', user.email),
              _buildDetailRow('Ad Soyad', user.fullName),
              _buildDetailRow('Rol', _getRoleDisplayName(user.role)),
              _buildDetailRow('Durum', user.isActive ? 'Aktif' : 'Pasif'),
              _buildDetailRow('Oluşturulma', _formatDate(user.createdAt)),
              _buildDetailRow('Son Giriş', _formatDate(user.lastLogin)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          if (PermissionService.canUpdateUsers())
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
            width: 100,
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

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => _UserDialog(
        user: null,
        onSave: (user) async {
          await _addUser(user);
        },
      ),
    );
  }

  void _showEditUserDialog(AdminUser user) {
    showDialog(
      context: context,
      builder: (context) => _UserDialog(
        user: user,
        onSave: (updatedUser) async {
          await _updateUser(updatedUser);
        },
      ),
    );
  }

  void _showDeleteUserDialog(AdminUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcı Sil'),
        content: Text(
          '${user.fullName} kullanıcısını silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(user);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _addUser(AdminUser user) async {
    // Loading göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await _adminService.addUser(user);
      if (mounted) {
        Navigator.pop(context); // Loading'i kapat
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.fullName} başarıyla eklendi'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
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
              content: Text('Hata: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        // Hata durumunda exception fırlat ki dialog açık kalsın
        rethrow;
      }
    }
  }

  Future<void> _updateUser(AdminUser user) async {
    // Loading göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await _adminService.updateUser(user);
      if (mounted) {
        Navigator.pop(context); // Loading'i kapat
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.fullName} başarıyla güncellendi'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
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
              content: Text('Hata: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        // Hata durumunda exception fırlat ki dialog açık kalsın
        rethrow;
      }
    }
  }

  Future<void> _deleteUser(AdminUser user) async {
    // Loading göster
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
        Navigator.pop(context); // Loading'i kapat
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

  Future<void> _toggleUserStatus(AdminUser user, bool isActive) async {
    // Loading göster
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
        Navigator.pop(context); // Loading'i kapat
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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

class _UserDialog extends StatefulWidget {
  final AdminUser? user;
  final Future<void> Function(AdminUser) onSave;

  const _UserDialog({
    required this.user,
    required this.onSave,
  });

  @override
  State<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _adminService = AdminService();
  String _selectedRole = 'user';
  bool _isActive = true;
  
  // Kullanıcı adı validasyon durumu
  bool? _isUsernameAvailable;
  bool _isCheckingUsername = false;
  Timer? _usernameCheckTimer;
  String? _usernameError;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _nameController.text = widget.user!.fullName;
      _emailController.text = widget.user!.email;
      _usernameController.text = widget.user!.username;
      _selectedRole = widget.user!.role.toLowerCase();
      _isActive = widget.user!.isActive;
    }
    
    // Kullanıcı adı değişikliklerini dinle
    _usernameController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _usernameCheckTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.removeListener(_onUsernameChanged);
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    // Debounce: Kullanıcı yazmayı bıraktıktan 500ms sonra kontrol et
    _usernameCheckTimer?.cancel();
    _usernameError = null;
    _isUsernameAvailable = null;
    
    final username = _usernameController.text.trim();
    
    if (username.isEmpty) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = null;
      });
      return;
    }
    
    setState(() {
      _isCheckingUsername = true;
    });
    
    _usernameCheckTimer = Timer(const Duration(milliseconds: 500), () {
      _checkUsernameAvailability(username);
    });
  }

  Future<void> _checkUsernameAvailability(String username) async {
    if (username.trim().isEmpty) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = null;
      });
      return;
    }
    
    // Düzenleme modunda ve kullanıcı adı değişmemişse kontrol etme
    if (widget.user != null && username.trim() == widget.user!.username) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = true; // Kendi kullanıcı adı, müsait say
        _usernameError = null;
      });
      return;
    }
    
    try {
      final isAvailable = await _adminService.isUsernameAvailable(
        username,
        excludeUserId: widget.user?.id,
      );
      
      if (mounted) {
        setState(() {
          _isCheckingUsername = false;
          _isUsernameAvailable = isAvailable;
          if (!isAvailable) {
            _usernameError = 'Bu kullanıcı adı zaten kullanılıyor';
          } else {
            _usernameError = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingUsername = false;
          _isUsernameAvailable = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.user == null ? 'Yeni Kullanıcı' : 'Kullanıcı Düzenle'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Ad Soyad',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ad soyad gerekli';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'E-posta gerekli';
                    }
                    if (!value.contains('@')) {
                      return 'Geçerli bir e-posta adresi girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Kullanıcı Adı',
                    border: const OutlineInputBorder(),
                    suffixIcon: _isCheckingUsername
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _isUsernameAvailable == true
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : _isUsernameAvailable == false
                                ? const Icon(Icons.error, color: Colors.red)
                                : null,
                    errorText: _usernameError,
                  ),
                  onChanged: (value) {
                    // Validator'ı tetikle
                    _formKey.currentState?.validate();
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Kullanıcı adı gerekli';
                    }
                    if (_isUsernameAvailable == false) {
                      return 'Bu kullanıcı adı zaten kullanılıyor';
                    }
                    if (_isCheckingUsername) {
                      return 'Kontrol ediliyor...';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: widget.user == null
                        ? 'Şifre'
                        : 'Yeni Şifre (Boş bırakılırsa eski şifre korunur)',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (widget.user == null) {
                      if (value == null || value.isEmpty) {
                        return 'Şifre gerekli';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
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
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Aktif'),
                  subtitle: const Text('Kullanıcı sisteme giriş yapabilir'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _saveUser,
          child: Text(widget.user == null ? 'Ekle' : 'Güncelle'),
        ),
      ],
    );
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Kullanıcı adı kontrolü devam ediyorsa bekle
    if (_isCheckingUsername) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen kullanıcı adı kontrolünün tamamlanmasını bekleyin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Kullanıcı adı müsait değilse hata göster
    if (_isUsernameAvailable == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu kullanıcı adı zaten kullanılıyor. Lütfen farklı bir kullanıcı adı seçin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (widget.user == null && _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yeni kullanıcı için şifre gereklidir'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final password = widget.user == null
        ? _passwordController.text
        : (_passwordController.text.isNotEmpty
            ? _passwordController.text
            : widget.user!.password);

    final user = AdminUser(
      id: widget.user?.id ?? '',
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      fullName: _nameController.text.trim(),
      role: _selectedRole,
      password: password,
      isActive: _isActive,
      createdAt: widget.user?.createdAt ?? DateTime.now(),
      lastLogin: widget.user?.lastLogin ?? DateTime.now(),
    );

    // Dialog'u kapatmadan önce kaydetmeyi dene
    // Başarılı olursa dialog kapanacak, hata olursa açık kalacak
    try {
      await widget.onSave(user);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // Hata durumunda dialog açık kalır, form verileri korunur
      // Hata mesajı zaten _addUser veya _updateUser'da gösteriliyor
    }
  }
}

