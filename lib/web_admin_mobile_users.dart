import 'package:flutter/material.dart';
import 'model/mobile_user.dart';
import 'services/mobile_user_service.dart';

class WebAdminMobileUsers extends StatefulWidget {
  const WebAdminMobileUsers({super.key});

  @override
  State<WebAdminMobileUsers> createState() => _WebAdminMobileUsersState();
}

class _WebAdminMobileUsersState extends State<WebAdminMobileUsers> {
  final MobileUserService _userService = MobileUserService();
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
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
          // Üst Bar
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'Mobil Kullanıcılar',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const Spacer(),
                    // İstatistikler
                    _buildStatCard('Toplam Kullanıcı', '$_totalUsers', Icons.people, const Color(0xFF3B82F6)),
                    const SizedBox(width: 16),
                    _buildStatCard('Toplam Bakiye', '₺${_totalBalance.toStringAsFixed(2)}', Icons.account_balance_wallet, const Color(0xFF10B981)),
                  ],
                ),
                const SizedBox(height: 16),
                // Arama
                TextField(
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
              ],
            ),
          ),

          // Kullanıcı Listesi
          Expanded(
            child: _searchQuery.isEmpty
                ? StreamBuilder<List<MobileUser>>(
                    stream: _userService.getUsers(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Hata: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('Kullanıcı bulunamadı'));
                      }
                      return _buildUserList(snapshot.data!);
                    },
                  )
                : FutureBuilder<List<MobileUser>>(
                    future: _userService.searchUsers(_searchQuery),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Hata: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('Sonuç bulunamadı'));
                      }
                      return _buildUserList(snapshot.data!);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(List<MobileUser> users) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(MobileUser user) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
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
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 30,
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
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              
              // Bilgiler
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user.fullName ?? user.username ?? user.email ?? 'İsimsiz',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (user.isFrozen)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'DONDURULDU',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else if (!user.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'PASIF',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (user.email != null)
                      Text(
                        user.email!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    if (user.phoneNumber != null)
                      Text(
                        user.phoneNumber!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                  ],
                ),
              ),

              // Bakiye
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Bakiye',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '₺${user.balance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // İşlemler
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value, user),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Düzenle'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'balance',
                    child: Row(
                      children: [
                        Icon(Icons.account_balance_wallet, size: 20),
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
                        Icon(user.isActive ? Icons.block : Icons.check_circle, size: 20),
                        const SizedBox(width: 8),
                        Text(user.isActive ? 'Pasifleştir' : 'Aktifleştir'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: user.isFrozen ? 'unfreeze' : 'freeze',
                    child: Row(
                      children: [
                        Icon(user.isFrozen ? Icons.lock_open : Icons.lock, size: 20),
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
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Hesabı Kapat', style: TextStyle(color: Colors.red)),
                      ],
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

  void _showUserDetails(MobileUser user) {
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
              await _updateUser(user, emailController.text, phoneController.text,
                  passwordController.text, nameController.text);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUser(MobileUser user, String email, String phone,
      String password, String name) async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kullanıcı başarıyla güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBalanceDialog(MobileUser user) {
    showDialog(
      context: context,
      builder: (context) => _BalanceDialog(user: user, userService: _userService),
    ).then((_) => _loadStatistics());
  }

  Future<void> _activateUser(MobileUser user) async {
    try {
      await _userService.toggleUserStatus(user.id, true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kullanıcı aktifleştirildi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
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
      try {
        await _userService.toggleUserStatus(user.id, false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kullanıcı pasifleştirildi'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: ${e.toString()}'),
              backgroundColor: Colors.red,
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
      try {
        await _userService.freezeUser(user.id, freeze);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(freeze ? 'Hesap donduruldu' : 'Hesap donması kaldırıldı'),
              backgroundColor: freeze ? Colors.red : Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _closeAccount(MobileUser user) async {
    // İşlem tipini seç
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
      // Silme işlemi için onay
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
        try {
          await _userService.deleteUser(user.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Hesap başarıyla silindi'),
                backgroundColor: Colors.green,
              ),
            );
            // İstatistikleri yenile
            _loadStatistics();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Hesap silinirken hata oluştu: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } else if (action == 'deactivate') {
      // Pasif yapma işlemi
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
        try {
          await _userService.deactivateUser(user.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Hesap kapatıldı (pasif yapıldı)'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Hata: ${e.toString()}'),
                backgroundColor: Colors.red,
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
            
            // İşlem Tipi
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

            // Miktar
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

            // Not
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

            // Bakiye Geçmişi
            TextButton.icon(
              onPressed: () => _showBalanceHistory(),
              icon: const Icon(Icons.history),
              label: const Text('Bakiye İşlem Geçmişi'),
            ),
            const SizedBox(height: 16),

            // Butonlar
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showBalanceHistory() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bakiye İşlem Geçmişi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: widget.userService.getBalanceTransactions(widget.user.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Hata: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('İşlem geçmişi bulunamadı'));
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final transaction = snapshot.data![index];
                        final isDeposit = transaction['type'] == 'deposit';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              isDeposit ? Icons.add_circle : Icons.remove_circle,
                              color: isDeposit ? Colors.green : Colors.red,
                            ),
                            title: Text(
                              isDeposit ? 'Bakiye Yükleme' : 'Bakiye Çekme',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDeposit ? Colors.green : Colors.red,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Miktar: ₺${(transaction['amount'] as num).toStringAsFixed(2)}'),
                                Text(
                                  'Önceki: ₺${(transaction['balanceBefore'] as num).toStringAsFixed(2)} → '
                                  'Sonraki: ₺${(transaction['balanceAfter'] as num).toStringAsFixed(2)}',
                                ),
                                if (transaction['note'] != null)
                                  Text('Not: ${transaction['note']}'),
                                if (transaction['createdAt'] != null)
                                  Text(
                                    'Tarih: ${_formatDate((transaction['createdAt'] as DateTime))}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kapat'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

