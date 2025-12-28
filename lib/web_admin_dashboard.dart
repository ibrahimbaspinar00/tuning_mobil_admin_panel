import 'package:flutter/material.dart';
import 'services/admin_service.dart';
import 'model/order.dart' as OrderModel;
import 'web_admin_simple_products.dart';
import 'web_admin_stock_management.dart';
import 'web_admin_user_management.dart';
import 'web_admin_reports.dart';
import 'web_admin_settings.dart';
import 'web_admin_orders.dart';
import 'web_admin_price_management.dart';
import 'web_admin_notifications.dart';
import 'web_admin_main.dart';
import 'services/permission_service.dart';
import 'services/theme_service.dart';
import 'services/app_theme.dart';
import 'admin_review_management.dart';
import 'web_admin_profile.dart';
import 'web_admin_mobile_users.dart';
import 'web_admin_registered_users.dart';
import 'web_admin_category_management.dart';
import 'web_admin_top_customers.dart';
import 'utils/responsive_helper.dart';
import 'widgets/dashboard_charts.dart';
import 'widgets/global_search.dart';
import 'web_admin_campaigns.dart';
import 'web_admin_advanced_reports.dart';
import 'web_admin_product_analytics.dart';

class WebAdminDashboard extends StatefulWidget {
  const WebAdminDashboard({super.key});

  @override
  State<WebAdminDashboard> createState() => _WebAdminDashboardState();
}

class _WebAdminDashboardState extends State<WebAdminDashboard> {
  int _selectedIndex = 0;
  bool _sidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    // Build tamamlandıktan sonra tema yükle
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final userId = PermissionService.getCurrentUserId();
        if (userId != null && mounted) {
          final darkMode = await ThemeService.getDarkMode(userId);
          if (mounted) {
            final appTheme = AppTheme.of(context);
            if (appTheme != null) {
              appTheme.onThemeChanged(darkMode);
            }
          }
        }
      } catch (e) {
        debugPrint('Tema tercihi yüklenirken hata: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = ResponsiveHelper.isMobile(context);
          final sidebarWidth = ResponsiveHelper.responsiveSidebarWidth(
            context,
            collapsed: _sidebarCollapsed,
          );
          
          return Row(
            children: [
              // Modern Sidebar
              if (!isMobile) ...[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: sidebarWidth,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1E293B),
                        Color(0xFF0F172A),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(4, 0),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildSidebarHeader(),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _buildSidebarMenu(),
                      ),
                      _buildSidebarFooter(),
                    ],
                  ),
                ),
              ],
              
              // Main Content
              Expanded(
                child: Scaffold(
                  appBar: isMobile ? _buildMobileAppBar() : _buildDesktopAppBar(),
                  body: _getCurrentPage(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: EdgeInsets.all(_sidebarCollapsed ? 16 : 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (!_sidebarCollapsed) ...[
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.dashboard_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    PermissionService.getCurrentUserName() ?? 'Admin',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ] else
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.dashboard_rounded, color: Colors.white, size: 26),
            ),
          if (!_sidebarCollapsed)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _sidebarCollapsed = true),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSidebarMenu() {
    final menuItems = _getMenuItems();
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        if (item['isDivider'] == true) {
          if (_sidebarCollapsed) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              item['title'] as String,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          );
        }
        
        return _buildMenuTile(
          item['index'] as int,
          item['icon'] as IconData,
          item['title'] as String,
          item['color'] as Color?,
        );
      },
    );
  }

  List<Map<String, dynamic>> _getMenuItems() {
    return [
      {'isDivider': false, 'index': 0, 'icon': Icons.dashboard_rounded, 'title': 'Ana Sayfa', 'color': null},
      {'isDivider': false, 'index': 14, 'icon': Icons.search_rounded, 'title': 'Arama', 'color': null},
      {'isDivider': true, 'title': 'ÜRÜN YÖNETİMİ'},
      if (PermissionService.canViewProducts())
        {'isDivider': false, 'index': 12, 'icon': Icons.category_rounded, 'title': 'Kategoriler', 'color': null},
      if (PermissionService.canViewProducts())
        {'isDivider': false, 'index': 1, 'icon': Icons.inventory_2_rounded, 'title': 'Ürünler', 'color': null},
      if (PermissionService.canViewStock())
        {'isDivider': false, 'index': 2, 'icon': Icons.warehouse_rounded, 'title': 'Stok', 'color': null},
      if (PermissionService.canViewStock())
        {'isDivider': false, 'index': 3, 'icon': Icons.price_change_rounded, 'title': 'Fiyatlar', 'color': null},
      {'isDivider': true, 'title': 'SİPARİŞLER'},
      {'isDivider': false, 'index': 4, 'icon': Icons.shopping_bag_rounded, 'title': 'Siparişler', 'color': null},
      {'isDivider': false, 'index': 13, 'icon': Icons.star_rounded, 'title': 'En Çok Alışveriş Yapanlar', 'color': null},
      {'isDivider': false, 'index': 17, 'icon': Icons.analytics_rounded, 'title': 'Ürün Analitikleri', 'color': null},
      {'isDivider': true, 'title': 'YÖNETİM'},
      {'isDivider': false, 'index': 11, 'icon': Icons.manage_accounts_rounded, 'title': 'Kullanıcı Yönetim Paneli', 'color': null},
      if (PermissionService.canViewUsers())
        {'isDivider': false, 'index': 5, 'icon': Icons.people_rounded, 'title': 'Admin Kullanıcılar', 'color': null},
      {'isDivider': false, 'index': 7, 'icon': Icons.notifications_rounded, 'title': 'Bildirimler', 'color': null},
      {'isDivider': false, 'index': 8, 'icon': Icons.star_rounded, 'title': 'Yorumlar', 'color': null},
      if (PermissionService.canViewReports())
        {'isDivider': false, 'index': 6, 'icon': Icons.analytics_rounded, 'title': 'Raporlar', 'color': null},
      if (PermissionService.canViewReports())
        {'isDivider': false, 'index': 16, 'icon': Icons.bar_chart_rounded, 'title': 'Gelişmiş Raporlar', 'color': null},
      if (PermissionService.canAccessSettings())
        {'isDivider': false, 'index': 9, 'icon': Icons.settings_rounded, 'title': 'Ayarlar', 'color': null},
      {'isDivider': true, 'title': 'KAMPANYALAR'},
      {'isDivider': false, 'index': 15, 'icon': Icons.campaign_rounded, 'title': 'Kampanyalar', 'color': null},{'isDivider': false, 'index': 9, 'icon': Icons.settings_rounded, 'title': 'Ayarlar', 'color': null},
    ];
  }

  Widget _buildMenuTile(int index, IconData icon, String title, Color? color) {
    final isSelected = _selectedIndex == index;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: isSelected ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedIndex = index),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: _sidebarCollapsed ? 12 : 18,
              vertical: 12,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.8),
                    size: 22,
                  ),
                ),
                if (!_sidebarCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showLogoutDialog,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: _sidebarCollapsed ? 12 : 18,
              vertical: 12,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
                ),
                if (!_sidebarCollapsed) ...[
                  const SizedBox(width: 12),
                  const Text(
                    'Çıkış Yap',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildDesktopAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1E293B),
      surfaceTintColor: Colors.transparent,
      title: _getPageTitle().isEmpty
          ? null
          : Row(
              children: [
                if (_sidebarCollapsed)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _sidebarCollapsed = false),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.menu_rounded, size: 24),
                      ),
                    ),
                  ),
                if (_sidebarCollapsed) const SizedBox(width: 8),
                Text(
                  _getPageTitle(),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
      actions: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _selectedIndex = 7),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Stack(
                children: [
                  const Icon(Icons.notifications_outlined, size: 24),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          icon: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: Colors.transparent,
              radius: 20,
              child: Text(
                (PermissionService.getCurrentUserName() ?? 'A')[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person_rounded, size: 20, color: Color(0xFF6366F1)),
                  SizedBox(width: 12),
                  Text('Profil', style: TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings_rounded, size: 20, color: Color(0xFF6366F1)),
                  SizedBox(width: 12),
                  Text('Ayarlar', style: TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                  SizedBox(width: 12),
                  Text('Çıkış Yap', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'logout') {
              _showLogoutDialog();
            } else if (value == 'settings') {
              setState(() => _selectedIndex = 9);
            } else if (value == 'profile') {
              _showProfilePage();
            }
          },
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      title: Text(_getPageTitle()),
      backgroundColor: const Color(0xFF1E293B),
      foregroundColor: Colors.white,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _showMobileDrawer(context),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => setState(() => _selectedIndex = 7),
        ),
      ],
    );
  }

  String _getPageTitle() {
    final titles = [
      'Ana Sayfa',
      'Ürün Yönetimi',
      'Stok Yönetimi',
      'Fiyat Yönetimi',
      'Sipariş Yönetimi',
      'Kullanıcı Yönetimi',
      'Raporlar',
      'Bildirim Yönetimi',
      'Yorum Yönetimi',
      'Ayarlar',
      'Mobil Kullanıcılar',
      'Kullanıcı Yönetim Paneli',
      'Kategori Yönetimi',
      'En Çok Alışveriş Yapanlar',
      '', // Index 14: Arama (başlık gösterilmeyecek)
      'Kampanyalar',
      'Gelişmiş Raporlar',
      'Ürün Analitikleri',
    ];
    if (_selectedIndex < titles.length) {
      return titles[_selectedIndex];
    }
    return 'Ana Sayfa';
  }

  void _showProfilePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WebAdminProfile(),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Çıkış Yap'),
        content: const Text('Admin panelinden çıkmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const WebAdminApp()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }

  void _showMobileDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.dashboard, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Admin Panel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        PermissionService.getCurrentUserName() ?? 'Admin',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _getMenuItems().length,
                itemBuilder: (context, index) {
                  final item = _getMenuItems()[index];
                  if (item['isDivider'] == true) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Text(
                        item['title'] as String,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    );
                  }
                  return _buildMobileNavItem(
                    item['index'] as int,
                    item['icon'] as IconData,
                    item['title'] as String,
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                title: const Text('Çıkış', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutDialog();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileNavItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () {
          setState(() => _selectedIndex = index);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _getCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return const WebDashboardHome();
      case 1:
        return PermissionService.canViewProducts() 
            ? const WebAdminSimpleProducts() 
            : _buildAccessDeniedPage('Ürün Yönetimi');
      case 2:
        return PermissionService.canViewStock() 
            ? const WebAdminStockManagement() 
            : _buildAccessDeniedPage('Stok Yönetimi');
      case 3:
        return PermissionService.canViewStock() 
            ? const WebAdminPriceManagement() 
            : _buildAccessDeniedPage('Fiyat Yönetimi');
      case 4:
        return const WebAdminOrders();
      case 5:
        return PermissionService.canViewUsers() 
            ? const WebAdminUserManagement() 
            : _buildAccessDeniedPage('Kullanıcı Yönetimi');
      case 6:
        return PermissionService.canViewReports() 
            ? const WebAdminReports() 
            : _buildAccessDeniedPage('Raporlar');
      case 7:
        return WebAdminNotifications();
      case 8:
        return const AdminReviewManagement();
      case 9:
        return PermissionService.canAccessSettings() 
            ? const WebAdminSettings() 
            : _buildAccessDeniedPage('Ayarlar');
      case 10:
        return const WebAdminMobileUsers();
      case 11:
        return const WebAdminRegisteredUsers();
      case 12:
        return const WebAdminCategoryManagement();
      case 13:
        return const WebAdminTopCustomers();
      case 14:
        return const GlobalSearch();
      case 15:
        return const WebAdminCampaigns();
      case 16:
        return PermissionService.canViewReports() 
            ? const WebAdminAdvancedReports() 
            : _buildAccessDeniedPage('Gelişmiş Raporlar');
      case 17:
        return const WebAdminProductAnalytics();
      default:
        return const WebDashboardHome();
    }
  }

  Widget _buildAccessDeniedPage(String pageName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Erişim Reddedildi',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$pageName sayfasına erişim yetkiniz bulunmamaktadır.',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class WebDashboardHome extends StatelessWidget {
  const WebDashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            _buildWelcomeCard(),
            const SizedBox(height: 24),
            
            // Statistics Grid
            _buildStatisticsGrid(),
            const SizedBox(height: 32),
            
            // Charts and Analytics
            const DashboardCharts(),
            const SizedBox(height: 32),
            
            // Quick Actions
            _buildQuickActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hoş Geldiniz! 👋',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${PermissionService.getCurrentUserName() ?? 'Admin'} olarak giriş yaptınız.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Bugün ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.dashboard_rounded,
              size: 60,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getDashboardStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Hata: ${snapshot.error}'),
          );
        }
        
        final stats = snapshot.data ?? {};
        
        // Trend değerlerini al
        final productTrend = (stats['productTrend'] as double?) ?? 0.0;
        final orderTrend = (stats['orderTrend'] as double?) ?? 0.0;
        final revenueTrend = (stats['revenueTrend'] as double?) ?? 0.0;
        
        final cards = [
          _StatCard(
            title: 'Toplam Ürün',
            value: (stats['totalProducts'] ?? 0).toString(),
            icon: Icons.inventory_2_rounded,
            color: const Color(0xFF3B82F6),
            trend: _formatTrend(productTrend),
          ),
          _StatCard(
            title: 'Düşük Stok',
            value: (stats['lowStockProducts'] ?? 0).toString(),
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFF59E0B),
            trend: stats['lowStockProducts'] == 0 ? '✓ Yeterli' : 'Dikkat',
          ),
          _StatCard(
            title: 'Aktif Ürün',
            value: (stats['activeProducts'] ?? 0).toString(),
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF10B981),
          ),
          _StatCard(
            title: 'Toplam Sipariş',
            value: (stats['totalOrders'] ?? 0).toString(),
            icon: Icons.shopping_bag_rounded,
            color: const Color(0xFF8B5CF6),
            trend: _formatTrend(orderTrend),
          ),
          _StatCard(
            title: 'Bekleyen',
            value: (stats['pendingOrders'] ?? 0).toString(),
            icon: Icons.pending_actions_rounded,
            color: const Color(0xFFEF4444),
          ),
          _StatCard(
            title: 'Toplam Gelir',
            value: '₺${(stats['totalRevenue'] ?? 0.0).toStringAsFixed(0)}',
            icon: Icons.attach_money_rounded,
            color: const Color(0xFF10B981),
            trend: _formatTrend(revenueTrend),
          ),
        ];
        
        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = ResponsiveHelper.responsiveColumns(
              context,
              mobile: 1,
              tablet: 2,
              laptop: 3,
              desktop: 3,
            );
            
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: ResponsiveHelper.responsiveGridSpacing(context),
                mainAxisSpacing: ResponsiveHelper.responsiveGridSpacing(context),
                childAspectRatio: 1.5,
              ),
              itemCount: cards.length,
              itemBuilder: (context, index) => cards[index],
            );
          },
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hızlı İşlemler',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _QuickActionButton(
              icon: Icons.add_circle_outline,
              label: 'Yeni Ürün',
              color: const Color(0xFF10B981),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WebAdminSimpleProducts()),
              ),
            ),
            _QuickActionButton(
              icon: Icons.update,
              label: 'Stok Güncelle',
              color: const Color(0xFFF59E0B),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WebAdminStockManagement()),
              ),
            ),
            _QuickActionButton(
              icon: Icons.analytics_outlined,
              label: 'Raporlar',
              color: const Color(0xFF8B5CF6),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WebAdminReports()),
              ),
            ),
            _QuickActionButton(
              icon: Icons.notifications_outlined,
              label: 'Bildirimler',
              color: const Color(0xFF3B82F6),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => WebAdminNotifications()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _getDashboardStats() async {
    try {
      final adminService = AdminService();
      
      // Mevcut dönem (bu ay)
      final now = DateTime.now();
      final currentMonthStart = DateTime(now.year, now.month, 1);
      final currentMonthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      
      // Önceki dönem (geçen ay)
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);
      
      // Tüm ürünleri al - Server-side fetch (cache bypass)
      final products = await adminService.getProductsFromServer();
      final validProducts = products;
      
      // Mevcut dönem ürün sayısı
      int totalProducts = validProducts.length;
      int currentMonthProducts = validProducts.where((p) => 
        p.createdAt.isAfter(currentMonthStart.subtract(const Duration(days: 1))) &&
        p.createdAt.isBefore(currentMonthEnd.add(const Duration(days: 1)))
      ).length;
      
      // Önceki dönem ürün sayısı
      int lastMonthProducts = validProducts.where((p) => 
        p.createdAt.isAfter(lastMonthStart.subtract(const Duration(days: 1))) &&
        p.createdAt.isBefore(lastMonthEnd.add(const Duration(days: 1)))
      ).length;
      
      // Ürün trend hesaplama
      double productTrend = _calculateTrend(currentMonthProducts.toDouble(), lastMonthProducts.toDouble());
      
      int lowStockProducts = validProducts.where((p) => p.stock < 10).length;
      int activeProducts = validProducts.where((p) => p.isActive).length;
      
      // Siparişler
      final orders = await adminService.getOrders().first;
      final validOrders = orders.whereType<OrderModel.Order>().toList();
      
      // Mevcut dönem siparişleri
      final currentMonthOrders = validOrders.where((o) => 
        o.orderDate.isAfter(currentMonthStart.subtract(const Duration(days: 1))) &&
        o.orderDate.isBefore(currentMonthEnd.add(const Duration(days: 1)))
      ).toList();
      
      // Önceki dönem siparişleri
      final lastMonthOrders = validOrders.where((o) => 
        o.orderDate.isAfter(lastMonthStart.subtract(const Duration(days: 1))) &&
        o.orderDate.isBefore(lastMonthEnd.add(const Duration(days: 1)))
      ).toList();
      
      int totalOrders = validOrders.length;
      int pendingOrders = validOrders.where((o) => o.status == 'pending').length;
      
      // Sipariş trend hesaplama
      double orderTrend = _calculateTrend(currentMonthOrders.length.toDouble(), lastMonthOrders.length.toDouble());
      
      // Gelir hesaplama
      double totalRevenue = validOrders.fold(0.0, (sum, order) => sum + order.totalAmount);
      double currentMonthRevenue = currentMonthOrders.fold(0.0, (sum, order) => sum + order.totalAmount);
      double lastMonthRevenue = lastMonthOrders.fold(0.0, (sum, order) => sum + order.totalAmount);
      
      // Gelir trend hesaplama
      double revenueTrend = _calculateTrend(currentMonthRevenue, lastMonthRevenue);
      
      return {
        'totalProducts': totalProducts,
        'lowStockProducts': lowStockProducts,
        'activeProducts': activeProducts,
        'totalOrders': totalOrders,
        'pendingOrders': pendingOrders,
        'totalRevenue': totalRevenue,
        'productTrend': productTrend,
        'orderTrend': orderTrend,
        'revenueTrend': revenueTrend,
      };
    } catch (e) {
      debugPrint('Dashboard istatistikleri yüklenirken hata: $e');
      return {};
    }
  }
  
  // Trend hesaplama (yüzde değişim)
  double _calculateTrend(double current, double previous) {
    if (previous == 0) {
      // Önceki dönem veri yoksa, mevcut veri varsa %100 artış
      return current > 0 ? 100.0 : 0.0;
    }
    return ((current - previous) / previous) * 100;
  }
  
  // Trend string formatı
  String _formatTrend(double trend) {
    if (trend > 0) {
      return '+${trend.toStringAsFixed(1)}%';
    } else if (trend < 0) {
      return '${trend.toStringAsFixed(1)}%';
    } else {
      return '0%';
    }
  }
}

class _StatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _animationController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.color.withValues(alpha: _isHovered ? 0.3 : 0.1),
                  width: _isHovered ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isHovered
                        ? widget.color.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.06),
                    blurRadius: _isHovered ? 16 : 12,
                    offset: Offset(0, _isHovered ? 6 : 4),
                    spreadRadius: _isHovered ? 0 : 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.color.withValues(alpha: 0.15),
                              widget.color.withValues(alpha: 0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: widget.color.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(widget.icon, color: widget.color, size: 26),
                      ),
                      if (widget.trend != null)
                        Builder(
                          builder: (context) {
                            final trendValue = widget.trend!;
                            final isPositive = trendValue.contains('+') || trendValue == '✓ Yeterli';
                            final isNegative = trendValue.contains('-');
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isPositive
                                    ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                    : isNegative
                                        ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                                        : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isPositive
                                        ? Icons.trending_up_rounded
                                        : isNegative
                                            ? Icons.trending_down_rounded
                                            : Icons.trending_flat_rounded,
                                    size: 14,
                                    color: isPositive
                                        ? const Color(0xFF10B981)
                                        : isNegative
                                            ? const Color(0xFFEF4444)
                                            : const Color(0xFFF59E0B),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    trendValue,
                                    style: TextStyle(
                                      color: isPositive
                                          ? const Color(0xFF10B981)
                                          : isNegative
                                              ? const Color(0xFFEF4444)
                                              : const Color(0xFFF59E0B),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.value,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: widget.color,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 15,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuickActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _animationController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  decoration: BoxDecoration(
                    gradient: _isHovered
                        ? LinearGradient(
                            colors: [
                              widget.color.withValues(alpha: 0.15),
                              widget.color.withValues(alpha: 0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: _isHovered ? null : widget.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.color.withValues(alpha: _isHovered ? 0.4 : 0.25),
                      width: _isHovered ? 1.5 : 1,
                    ),
                    boxShadow: _isHovered
                        ? [
                            BoxShadow(
                              color: widget.color.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(widget.icon, color: widget.color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: widget.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
