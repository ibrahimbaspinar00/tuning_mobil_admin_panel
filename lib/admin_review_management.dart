import 'package:flutter/material.dart';
import 'model/product_review.dart';
import 'services/review_service.dart';
import 'widgets/star_rating.dart';
import 'widgets/error_handler.dart';

class AdminReviewManagement extends StatefulWidget {
  const AdminReviewManagement({super.key});

  @override
  State<AdminReviewManagement> createState() => _AdminReviewManagementState();
}

class _AdminReviewManagementState extends State<AdminReviewManagement> {
  List<ProductReview> _reviews = [];
  List<ProductReview> _filteredReviews = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, approved, pending
  final TextEditingController _searchController = TextEditingController();
  final Map<String, String> _productNames = {}; // productId -> productName cache

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reviews = await ReviewService.getAllReviews();
      
      // Ürün adlarını yükle
      await _loadProductNames(reviews);
      
      setState(() {
        _reviews = reviews;
        _filteredReviews = reviews;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ErrorHandler.showError(context, 'Yorumlar yüklenirken hata oluştu');
      }
    }
  }

  Future<void> _loadProductNames(List<ProductReview> reviews) async {
    final productIds = reviews.map((r) => r.productId).toSet();
    
    for (final productId in productIds) {
      if (productId.isNotEmpty && !_productNames.containsKey(productId)) {
        try {
          final productName = await ReviewService.getProductName(productId);
          if (productName != null) {
            _productNames[productId] = productName;
          }
        } catch (e) {
          print('Ürün adı yüklenirken hata: $e');
        }
      }
    }
  }

  void _filterReviews() {
    setState(() {
      _filteredReviews = _reviews.where((review) {
        // Durum filtresi
        bool statusMatch = true;
        if (_selectedFilter == 'approved') {
          statusMatch = review.isApproved;
        } else if (_selectedFilter == 'pending') {
          statusMatch = !review.isApproved;
        }

        // Arama filtresi
        bool searchMatch = true;
        if (_searchController.text.isNotEmpty) {
          final searchText = _searchController.text.toLowerCase();
          searchMatch = review.userName.toLowerCase().contains(searchText) ||
                       review.comment.toLowerCase().contains(searchText) ||
                       review.productId.toLowerCase().contains(searchText);
        }

        return statusMatch && searchMatch;
      }).toList();
    });
  }

  Future<void> _approveReview(ProductReview review) async {
    // ID kontrolü
    if (review.id.isEmpty) {
      ErrorHandler.showError(context, 'Yorum ID\'si bulunamadı. Lütfen sayfayı yenileyin ve tekrar deneyin.');
      return;
    }

    print('🔍 Yorum onaylama başlatılıyor...');
    print('   - Review ID: "${review.id}"');
    print('   - Review: ${review.toString()}');

    // Loading göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final success = await ReviewService.approveReview(review.id, true);
      if (mounted) {
        Navigator.pop(context); // Loading'i kapat
        if (success) {
          ErrorHandler.showSuccess(context, 'Yorum başarıyla onaylandı');
          await _loadReviews(); // Yorumları yeniden yükle
        } else {
          ErrorHandler.showError(context, 'Yorum onaylanırken bir hata oluştu. Lütfen tekrar deneyin.');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Loading'i kapat
        
        final errorMsg = e.toString();
        final isPermissionError = errorMsg.contains('permission-denied') || 
                                  errorMsg.contains('permission denied') ||
                                  errorMsg.contains('Missing or insufficient permissions') ||
                                  errorMsg.contains('Firebase izin hatası');
        
        if (isPermissionError) {
          _showPermissionErrorDialog();
        } else {
          ErrorHandler.showError(
            context, 
            'Yorum onaylanırken hata oluştu: ${errorMsg.replaceAll('Exception: ', '')}',
          );
        }
      }
    }
  }

  Future<void> _rejectReview(ProductReview review) async {
    // ID kontrolü
    if (review.id.isEmpty) {
      ErrorHandler.showError(context, 'Yorum ID\'si bulunamadı. Lütfen sayfayı yenileyin ve tekrar deneyin.');
      return;
    }

    print('🔍 Yorum reddetme başlatılıyor...');
    print('   - Review ID: "${review.id}"');
    print('   - Review: ${review.toString()}');

    // Onay dialogu göster
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yorumu Reddet'),
        content: const Text('Bu yorumu reddetmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reddet'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Loading göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final success = await ReviewService.approveReview(review.id, false);
      if (mounted) {
        Navigator.pop(context); // Loading'i kapat
        if (success) {
          ErrorHandler.showSuccess(context, 'Yorum başarıyla reddedildi');
          await _loadReviews(); // Yorumları yeniden yükle
        } else {
          ErrorHandler.showError(context, 'Yorum reddedilirken bir hata oluştu. Lütfen tekrar deneyin.');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Loading'i kapat
        
        final errorMsg = e.toString();
        final isPermissionError = errorMsg.contains('permission-denied') || 
                                  errorMsg.contains('permission denied') ||
                                  errorMsg.contains('Missing or insufficient permissions') ||
                                  errorMsg.contains('Firebase izin hatası');
        
        if (isPermissionError) {
          _showPermissionErrorDialog();
        } else {
          ErrorHandler.showError(
            context, 
            'Yorum reddedilirken hata oluştu: ${errorMsg.replaceAll('Exception: ', '')}',
          );
        }
      }
    }
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

  void _showAdminResponseDialog(ProductReview review, {bool isEditing = false}) {
    final responseController = TextEditingController();
    
    // Eğer düzenleme modundaysa mevcut yanıtı yükle
    if (isEditing && review.adminResponse != null) {
      responseController.text = review.adminResponse!;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Admin Yanıtını Düzenle' : 'Admin Yanıtı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kullanıcı: ${review.userName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('Yorum: ${review.comment}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: responseController,
              decoration: InputDecoration(
                labelText: 'Admin Yanıtı',
                hintText: isEditing ? 'Yanıtınızı düzenleyin...' : 'Yanıtınızı yazın...',
                border: const OutlineInputBorder(),
              ),
              maxLines: 5,
              autofocus: true,
            ),
            if (isEditing && review.adminResponseDate != null) ...[
              const SizedBox(height: 8),
              Text(
                'Son düzenleme: ${_formatDate(review.adminResponseDate!)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (isEditing && review.adminResponse != null)
            TextButton.icon(
              onPressed: () async {
                // Silme onayı
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Yanıtı Sil'),
                    content: const Text('Admin yanıtını silmek istediğinizden emin misiniz?'),
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
                  try {
                    final success = await ReviewService.deleteAdminResponse(review.id);
                    if (mounted) {
                      Navigator.pop(context); // Ana dialog'u kapat
                      if (success) {
                        ErrorHandler.showSuccess(context, 'Yanıt silindi');
                        _loadReviews();
                      } else {
                        ErrorHandler.showError(context, 'Yanıt silinirken hata oluştu');
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      final errorMsg = e.toString();
                      final isPermissionError = errorMsg.contains('permission-denied') || 
                                                errorMsg.contains('permission denied') ||
                                                errorMsg.contains('Missing or insufficient permissions') ||
                                                errorMsg.contains('Firebase izin hatası');
                      
                      if (isPermissionError) {
                        Navigator.pop(context); // Ana dialog'u kapat
                        _showPermissionErrorDialog();
                      } else {
                        ErrorHandler.showError(
                          context, 
                          'Yanıt silinirken hata oluştu: ${errorMsg.replaceAll('Exception: ', '')}',
                        );
                      }
                    }
                  }
                }
              },
              icon: const Icon(Icons.delete, size: 16, color: Colors.red),
              label: const Text('Sil', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (responseController.text.trim().isNotEmpty) {
                // Loading göster
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  final success = await ReviewService.respondToReview(
                    reviewId: review.id,
                    adminResponse: responseController.text.trim(),
                  );
                  if (mounted) {
                    Navigator.pop(context); // Loading'i kapat
                    if (success) {
                      ErrorHandler.showSuccess(
                        context, 
                        isEditing ? 'Yanıt güncellendi' : 'Yanıt eklendi',
                      );
                      Navigator.pop(context); // Dialog'u kapat
                      _loadReviews();
                    } else {
                      ErrorHandler.showError(
                        context, 
                        isEditing ? 'Yanıt güncellenirken hata oluştu' : 'Yanıt eklenirken hata oluştu',
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context); // Loading'i kapat
                    final errorMsg = e.toString();
                    final isPermissionError = errorMsg.contains('permission-denied') || 
                                              errorMsg.contains('permission denied') ||
                                              errorMsg.contains('Missing or insufficient permissions') ||
                                              errorMsg.contains('Firebase izin hatası');
                    
                    if (isPermissionError) {
                      Navigator.pop(context); // Dialog'u kapat
                      _showPermissionErrorDialog();
                    } else {
                      ErrorHandler.showError(
                        context, 
                        '${isEditing ? 'Yanıt güncellenirken' : 'Yanıt eklenirken'} hata oluştu: ${errorMsg.replaceAll('Exception: ', '')}',
                      );
                    }
                  }
                }
              } else {
                ErrorHandler.showError(context, 'Yanıt boş olamaz');
              }
            },
            child: Text(isEditing ? 'Güncelle' : 'Gönder'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yorum Yönetimi'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filtreler
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Arama
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Kullanıcı, yorum veya ürün ID ile ara...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterReviews();
                      },
                    ),
                  ),
                  onChanged: (_) => _filterReviews(),
                ),
                const SizedBox(height: 12),
                
                // Durum filtresi
                Row(
                  children: [
                    const Text('Durum: '),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedFilter,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Tümü')),
                        DropdownMenuItem(value: 'pending', child: Text('Onay Bekleyen')),
                        DropdownMenuItem(value: 'approved', child: Text('Onaylanan')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedFilter = value!;
                        });
                        _filterReviews();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Yorum listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredReviews.isEmpty
                    ? const Center(
                        child: Text(
                          'Yorum bulunamadı',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredReviews.length,
                        itemBuilder: (context, index) {
                          final review = _filteredReviews[index];
                          return _buildReviewCard(review);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ProductReview review) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.shopping_bag, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _productNames[review.productId] ?? 'Ürün: ${review.productId}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: review.isApproved ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    review.isApproved ? 'Onaylandı' : 'Bekliyor',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Rating
            StarRatingDisplay(
              rating: review.rating.toDouble(),
              size: 16,
            ),
            
            const SizedBox(height: 8),
            
            // Yorum
            Text(
              review.comment,
              style: const TextStyle(fontSize: 14),
            ),
            
            const SizedBox(height: 8),
            
            // Tarih
            Text(
              'Tarih: ${_formatDate(review.createdAt)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            
            // Admin yanıtı
            if (review.adminResponse != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Admin Yanıtı:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                          onPressed: () => _showAdminResponseDialog(review, isEditing: true),
                          tooltip: 'Düzenle',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    Text(
                      review.adminResponse!,
                      style: const TextStyle(fontSize: 13),
                    ),
                    if (review.adminResponseDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Tarih: ${_formatDate(review.adminResponseDate!)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Aksiyon butonları
            if (!review.isApproved) ...[
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _approveReview(review),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Onayla'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _rejectReview(review),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reddet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
            
            // Admin yanıt butonu
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _showAdminResponseDialog(review),
                  icon: const Icon(Icons.reply, size: 16),
                  label: const Text('Yanıtla'),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _deleteReview(review),
                  icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                  label: const Text('Sil', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteReview(ProductReview review) async {
    // ID kontrolü
    if (review.id.isEmpty) {
      ErrorHandler.showError(context, 'Yorum ID\'si bulunamadı. Lütfen sayfayı yenileyin ve tekrar deneyin.');
      return;
    }

    // Onay dialogu göster
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yorumu Sil'),
        content: const Text('Bu yorumu silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Loading göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final success = await ReviewService.deleteReviewAdmin(review.id);
      if (mounted) {
        Navigator.pop(context); // Loading'i kapat
        if (success) {
          ErrorHandler.showSuccess(context, 'Yorum başarıyla silindi');
          await _loadReviews(); // Yorumları yeniden yükle
        } else {
          ErrorHandler.showError(context, 'Yorum silinirken bir hata oluştu. Lütfen tekrar deneyin.');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Loading'i kapat
        
        final errorMsg = e.toString();
        final isPermissionError = errorMsg.contains('permission-denied') || 
                                  errorMsg.contains('permission denied') ||
                                  errorMsg.contains('Missing or insufficient permissions') ||
                                  errorMsg.contains('Firebase izin hatası');
        
        if (isPermissionError) {
          _showPermissionErrorDialog();
        } else {
          ErrorHandler.showError(
            context, 
            'Yorum silinirken hata oluştu: ${errorMsg.replaceAll('Exception: ', '')}',
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
