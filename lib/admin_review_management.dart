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
        ErrorHandler.showError(
          context, 
          'Yorum onaylanırken hata oluştu: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _rejectReview(ProductReview review) async {
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
        ErrorHandler.showError(
          context, 
          'Yorum reddedilirken hata oluştu: ${e.toString()}',
        );
      }
    }
  }

  void _showAdminResponseDialog(ProductReview review) {
    final responseController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Yanıtı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Kullanıcı: ${review.userName}'),
            const SizedBox(height: 8),
            Text('Yorum: ${review.comment}'),
            const SizedBox(height: 16),
            TextField(
              controller: responseController,
              decoration: const InputDecoration(
                labelText: 'Admin Yanıtı',
                hintText: 'Yanıtınızı yazın...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (responseController.text.trim().isNotEmpty) {
                try {
                  final success = await ReviewService.respondToReview(
                    reviewId: review.id,
                    adminResponse: responseController.text.trim(),
                  );
                  if (mounted) {
                    if (success) {
                      ErrorHandler.showSuccess(context, 'Yanıt eklendi');
                      Navigator.pop(context);
                      _loadReviews();
                    } else {
                      ErrorHandler.showError(context, 'Yanıt eklenirken hata oluştu');
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ErrorHandler.showError(context, e.toString());
                  }
                }
              }
            },
            child: const Text('Gönder'),
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
                      Text(
                        'Ürün ID: ${review.productId}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
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
                    const Text(
                      'Admin Yanıtı:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      review.adminResponse!,
                      style: const TextStyle(fontSize: 13),
                    ),
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
            TextButton.icon(
              onPressed: () => _showAdminResponseDialog(review),
              icon: const Icon(Icons.reply, size: 16),
              label: const Text('Yanıtla'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
