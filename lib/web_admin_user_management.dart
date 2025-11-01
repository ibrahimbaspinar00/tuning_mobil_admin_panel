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
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = 'Tümü';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Kullanıcı Yönetimi'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
              });
            },
            icon: Icon(_isSearchVisible ? Icons.search_off : Icons.search),
          ),
          if (PermissionService.canCreateUsers())
            ElevatedButton.icon(
              onPressed: () => _showAddUserDialog(),
              icon: const Icon(Icons.person_add),
              label: const Text('Yeni Kullanıcı'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Arama çubuğu
          if (_isSearchVisible)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'Kullanıcı ara...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: _selectedRole,
                    items: const [
                      DropdownMenuItem(value: 'Tümü', child: Text('Tümü')),
                      DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                      DropdownMenuItem(value: 'Moderatör', child: Text('Moderatör')),
                      DropdownMenuItem(value: 'Kullanıcı', child: Text('Kullanıcı')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          
          // Ana içerik
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık ve istatistikler
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kullanıcı Yönetimi',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sistem kullanıcılarını yönetin ve yetkilerini düzenleyin',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Hızlı işlemler
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _showAddUserDialog(),
                            icon: const Icon(Icons.person_add),
                            label: const Text('Yeni Kullanıcı'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _exportUsers(),
                            icon: const Icon(Icons.download),
                            label: const Text('Dışa Aktar'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _importUsers(),
                            icon: const Icon(Icons.upload),
                            label: const Text('İçe Aktar'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Kullanıcı listesi
                  Expanded(
                    child: _buildUserList(),
                  ),
                ],
              ),
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Kullanıcılar yüklenirken hata oluştu',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.red[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          );
        }

        List<AdminUser> users = snapshot.data ?? [];
        
        // Filtreleme
        if (_searchController.text.isNotEmpty) {
          users = users.where((user) =>
              user.fullName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
              user.email.toLowerCase().contains(_searchController.text.toLowerCase())
          ).toList();
        }

        if (_selectedRole != 'Tümü') {
          users = users.where((user) => user.role == _selectedRole).toList();
        }

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people, size: 64, color: Colors.grey[400]),
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

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return _buildUserCard(user);
          },
        );
      },
    );
  }

  Widget _buildUserCard(AdminUser user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: _getRoleColor(user.role),
              child: Text(
                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Kullanıcı bilgileri
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kullanıcı Adı: ${user.username}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Şifre: ${user.password}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red[700],
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRoleColor(user.role).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.role,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getRoleColor(user.role),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (user.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Aktif',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Pasif',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Aksiyon butonları
            Row(
              children: [
                if (PermissionService.canUpdateUsers())
                  IconButton(
                    onPressed: () => _showEditUserDialog(user),
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'Düzenle',
                  ),
                if (PermissionService.canDeleteUsers())
                  IconButton(
                    onPressed: () => _showDeleteUserDialog(user),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Sil',
                  ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleUserAction(value, user),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Görüntüle'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'permissions',
                      child: Row(
                        children: [
                          Icon(Icons.security, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Yetkiler'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(Icons.toggle_on, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Durum Değiştir'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Admin':
        return Colors.red;
      case 'Moderatör':
        return Colors.orange;
      case 'Kullanıcı':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => _UserDialog(
        user: null,
        onSave: (user) => _addUser(user),
      ),
    );
  }

  void _showEditUserDialog(AdminUser user) {
    showDialog(
      context: context,
      builder: (context) => _UserDialog(
        user: user,
        onSave: (updatedUser) => _updateUser(updatedUser),
      ),
    );
  }

  void _showDeleteUserDialog(AdminUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcı Sil'),
        content: Text('${user.fullName} kullanıcısını silmek istediğinizden emin misiniz?'),
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

  void _handleUserAction(String action, AdminUser user) {
    switch (action) {
      case 'view':
        _showUserDetails(user);
        break;
      case 'permissions':
        _showPermissionsDialog(user);
        break;
      case 'toggle':
        _toggleUserStatus(user);
        break;
    }
  }

  void _showUserDetails(AdminUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.fullName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('E-posta: ${user.email}'),
            Text('Rol: ${user.role}'),
            Text('Durum: ${user.isActive ? 'Aktif' : 'Pasif'}'),
            Text('Oluşturulma: ${user.createdAt}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showPermissionsDialog(AdminUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yetki Ayarları'),
        content: const Text('Yetki ayarları burada gösterilecek'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _toggleUserStatus(AdminUser user) {
    // Kullanıcı durumunu değiştir
    setState(() {
      // Burada kullanıcı durumu değiştirilecek
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${user.fullName} kullanıcısının durumu değiştirildi'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _addUser(AdminUser user) async {
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
            content: Text('${user.fullName} kullanıcısı başarıyla eklendi'),
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
            content: Text('Kullanıcı eklenirken hata oluştu: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }


  void _updateUser(AdminUser user) async {
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
            content: Text('${user.fullName} kullanıcısı başarıyla güncellendi'),
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
            content: Text('Kullanıcı güncellenirken hata oluştu: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _deleteUser(AdminUser user) async {
    try {
      await _adminService.deleteUser(user.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.fullName} kullanıcısı silindi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kullanıcı silinirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _exportUsers() {
    // Kullanıcıları dışa aktar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kullanıcılar dışa aktarıldı'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _importUsers() {
    // Kullanıcıları içe aktar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kullanıcılar içe aktarıldı'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class _UserDialog extends StatefulWidget {
  final AdminUser? user;
  final Function(AdminUser) onSave;

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
  String _selectedRole = 'Kullanıcı';
  bool _isActive = true;
  final Map<String, bool> _selectedPermissions = {};

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _nameController.text = widget.user!.fullName;
      _emailController.text = widget.user!.email;
      _usernameController.text = widget.user!.username;
      _selectedRole = widget.user!.role;
      _isActive = widget.user!.isActive;
    }
    
    // Varsayılan yetkiler
    final defaultPermissions = ['read', 'write', 'delete'];
    for (String permission in defaultPermissions) {
      _selectedPermissions[permission] = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.user == null ? 'Yeni Kullanıcı' : 'Kullanıcı Düzenle'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ad
              TextFormField(
                controller: _nameController,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.words,
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
              
              // E-posta
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textCapitalization: TextCapitalization.none,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  border: OutlineInputBorder(),
                ),
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
              
              // Kullanıcı Adı
              TextFormField(
                controller: _usernameController,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.none,
                decoration: const InputDecoration(
                  labelText: 'Kullanıcı Adı',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kullanıcı adı gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Şifre
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.none,
                decoration: InputDecoration(
                  labelText: widget.user == null ? 'Şifre' : 'Yeni Şifre (Boş bırakılırsa eski şifre korunur)',
                  border: const OutlineInputBorder(),
                  hintText: widget.user == null ? 'En az 6 karakter' : 'Değiştirmek istemiyorsanız boş bırakın',
                ),
                validator: (value) {
                  // Yeni kullanıcı için şifre zorunlu
                  if (widget.user == null) {
                    if (value == null || value.isEmpty) {
                      return 'Şifre gerekli';
                    }
                    if (value.length < 6) {
                      return 'Şifre en az 6 karakter olmalı';
                    }
                  } else {
                    // Güncelleme için şifre girilmişse kontrol et
                    if (value != null && value.isNotEmpty && value.length < 6) {
                      return 'Şifre en az 6 karakter olmalı';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Rol
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Rol',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'Moderatör', child: Text('Moderatör')),
                  DropdownMenuItem(value: 'Kullanıcı', child: Text('Kullanıcı')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Durum
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

  void _saveUser() {
    if (_formKey.currentState!.validate()) {
      // Yeni kullanıcı için şifre kontrolü
      if (widget.user == null && _passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yeni kullanıcı için şifre gereklidir'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Güncelleme için şifre boşsa eski şifreyi koru
      final password = widget.user == null 
        ? _passwordController.text 
        : (_passwordController.text.isNotEmpty 
            ? _passwordController.text 
            : widget.user!.password);

      final user = AdminUser(
        id: widget.user?.id ?? '', // Boş olacak, addUser fonksiyonu otomatik oluşturacak
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        fullName: _nameController.text.trim(),
        role: _selectedRole,
        password: password,
        isActive: _isActive,
        createdAt: widget.user?.createdAt ?? DateTime.now(),
        lastLogin: widget.user?.lastLogin ?? DateTime.now(),
      );
      
      widget.onSave(user);
      Navigator.pop(context);
    }
  }

}
