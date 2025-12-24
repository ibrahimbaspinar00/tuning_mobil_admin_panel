import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Kampanya ve indirim yönetimi sayfası
class WebAdminCampaigns extends StatefulWidget {
  const WebAdminCampaigns({super.key});

  @override
  State<WebAdminCampaigns> createState() => _WebAdminCampaignsState();
}

class _WebAdminCampaignsState extends State<WebAdminCampaigns> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kampanya Yönetimi'),
        actions: [
          ElevatedButton.icon(
            onPressed: _showAddCampaignDialog,
            icon: const Icon(Icons.add),
            label: const Text('Yeni Kampanya'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('campaigns').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          final campaigns = snapshot.data?.docs ?? [];

          if (campaigns.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz kampanya bulunmuyor',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showAddCampaignDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('İlk Kampanyayı Oluştur'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: campaigns.length,
            itemBuilder: (context, index) {
              final campaign = campaigns[index];
              final data = campaign.data() as Map<String, dynamic>;
              return _buildCampaignCard(campaign.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildCampaignCard(String id, Map<String, dynamic> data) {
    final name = data['name'] ?? '';
    final description = data['description'] ?? '';
    final discountType = data['discountType'] ?? 'percentage'; // 'percentage' or 'fixed'
    final discountValue = (data['discountValue'] ?? 0).toDouble();
    final startDate = (data['startDate'] as Timestamp?)?.toDate();
    final endDate = (data['endDate'] as Timestamp?)?.toDate();
    final isActive = data['isActive'] ?? true;
    final couponCode = data['couponCode'] ?? '';

    final now = DateTime.now();
    final isExpired = endDate != null && endDate.isBefore(now);
    final isUpcoming = startDate != null && startDate.isAfter(now);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isExpired
                        ? Colors.red
                        : isUpcoming
                            ? Colors.orange
                            : isActive
                                ? Colors.green
                                : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isExpired
                        ? 'Süresi Dolmuş'
                        : isUpcoming
                            ? 'Yakında'
                            : isActive
                                ? 'Aktif'
                                : 'Pasif',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.local_offer, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  discountType == 'percentage'
                      ? '%$discountValue İndirim'
                      : '₺$discountValue İndirim',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                if (couponCode.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tag, size: 14, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          couponCode,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            if (startDate != null || endDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    startDate != null && endDate != null
                        ? '${DateFormat('dd.MM.yyyy').format(startDate)} - ${DateFormat('dd.MM.yyyy').format(endDate)}'
                        : startDate != null
                            ? 'Başlangıç: ${DateFormat('dd.MM.yyyy').format(startDate)}'
                            : endDate != null
                                ? 'Bitiş: ${DateFormat('dd.MM.yyyy').format(endDate)}'
                                : '',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showEditCampaignDialog(id, data),
                  icon: const Icon(Icons.edit),
                  label: const Text('Düzenle'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _toggleCampaignStatus(id, !isActive),
                  icon: Icon(isActive ? Icons.pause : Icons.play_arrow),
                  label: Text(isActive ? 'Duraklat' : 'Aktif Et'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _deleteCampaign(id),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Sil', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCampaignDialog() {
    _showCampaignDialog();
  }

  void _showEditCampaignDialog(String id, Map<String, dynamic> data) {
    _showCampaignDialog(campaignId: id, initialData: data);
  }

  void _showCampaignDialog({String? campaignId, Map<String, dynamic>? initialData}) {
    final nameController = TextEditingController(text: initialData?['name'] ?? '');
    final descriptionController = TextEditingController(text: initialData?['description'] ?? '');
    final couponCodeController = TextEditingController(text: initialData?['couponCode'] ?? '');
    final discountValueController = TextEditingController(
      text: initialData?['discountValue']?.toString() ?? '',
    );
    String discountType = initialData?['discountType'] ?? 'percentage';
    DateTime? startDate = (initialData?['startDate'] as Timestamp?)?.toDate();
    DateTime? endDate = (initialData?['endDate'] as Timestamp?)?.toDate();
    bool isActive = initialData?['isActive'] ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(campaignId == null ? 'Yeni Kampanya' : 'Kampanya Düzenle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Kampanya Adı',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: discountType,
                  decoration: const InputDecoration(
                    labelText: 'İndirim Tipi',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'percentage', child: Text('Yüzde (%)')),
                    DropdownMenuItem(value: 'fixed', child: Text('Sabit Tutar (₺)')),
                  ],
                  onChanged: (value) => setState(() => discountType = value!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: discountValueController,
                  decoration: const InputDecoration(
                    labelText: 'İndirim Değeri',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: couponCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Kupon Kodu (Opsiyonel)',
                    border: OutlineInputBorder(),
                    hintText: 'Örn: YAZ2024',
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Başlangıç Tarihi'),
                  subtitle: Text(
                    startDate != null
                        ? DateFormat('dd.MM.yyyy').format(startDate!)
                        : 'Tarih seçin',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => startDate = date);
                    }
                  },
                ),
                ListTile(
                  title: const Text('Bitiş Tarihi'),
                  subtitle: Text(
                    endDate != null
                        ? DateFormat('dd.MM.yyyy').format(endDate!)
                        : 'Tarih seçin',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: endDate ?? DateTime.now().add(const Duration(days: 30)),
                      firstDate: startDate ?? DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => endDate = date);
                    }
                  },
                ),
                SwitchListTile(
                  title: const Text('Aktif'),
                  value: isActive,
                  onChanged: (value) => setState(() => isActive = value),
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
                if (nameController.text.isEmpty || discountValueController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lütfen tüm gerekli alanları doldurun'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final discountValue = double.tryParse(discountValueController.text);
                if (discountValue == null || discountValue <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Geçerli bir indirim değeri girin'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  final campaignData = {
                    'name': nameController.text,
                    'description': descriptionController.text,
                    'discountType': discountType,
                    'discountValue': discountValue,
                    'couponCode': couponCodeController.text.trim(),
                    'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
                    'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
                    'isActive': isActive,
                    'createdAt': campaignId == null
                        ? Timestamp.now()
                        : (initialData?['createdAt'] as Timestamp?),
                    'updatedAt': Timestamp.now(),
                  };

                  if (campaignId == null) {
                    await _firestore.collection('campaigns').add(campaignData);
                  } else {
                    await _firestore.collection('campaigns').doc(campaignId).update(campaignData);
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(campaignId == null
                            ? 'Kampanya oluşturuldu'
                            : 'Kampanya güncellendi'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Hata: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(campaignId == null ? 'Oluştur' : 'Güncelle'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleCampaignStatus(String id, bool isActive) async {
    try {
      await _firestore.collection('campaigns').doc(id).update({
        'isActive': isActive,
        'updatedAt': Timestamp.now(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isActive ? 'Kampanya aktif edildi' : 'Kampanya duraklatıldı'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
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

  Future<void> _deleteCampaign(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kampanyayı Sil'),
        content: const Text('Bu kampanyayı silmek istediğinizden emin misiniz?'),
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
        await _firestore.collection('campaigns').doc(id).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kampanya silindi'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
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
  }
}

