import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'model/admin_product.dart';
import 'services/admin_service.dart';

class AdminProductManagement extends StatefulWidget {
  const AdminProductManagement({super.key});

  @override
  State<AdminProductManagement> createState() => _AdminProductManagementState();
}

class _AdminProductManagementState extends State<AdminProductManagement> {
  final AdminService _adminService = AdminService();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ürün Yönetimi',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddProductDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Yeni Ürün'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Ürün listesi
          Expanded(
            child: StreamBuilder<List<AdminProduct>>(
              stream: _adminService.getProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Hata: ${snapshot.error}'),
                  );
                }
                
                final products = snapshot.data ?? [];
                
                if (products.isEmpty) {
                  return const Center(
                    child: Text('Henüz ürün eklenmemiş'),
                  );
                }
                
                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: const Icon(Icons.inventory),
                        ),
                        title: Text(product.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kategori: ${product.category}'),
                            Text('Stok: ${product.stock}'),
                            Text('Fiyat: ₺${product.price.toStringAsFixed(2)}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _showEditProductDialog(product),
                              icon: const Icon(Icons.edit),
                              color: Colors.blue,
                            ),
                            IconButton(
                              onPressed: () => _deleteProduct(product),
                              icon: const Icon(Icons.delete),
                              color: Colors.red,
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
        ],
      ),
    );
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => ProductDialog(
        onSave: _addProduct,
      ),
    );
  }

  void _showEditProductDialog(AdminProduct product) {
    showDialog(
      context: context,
      builder: (context) => ProductDialog(
        product: product,
        onSave: _updateProduct,
      ),
    );
  }

  Future<void> _addProduct(AdminProduct product) async {
    try {
      await _adminService.addProduct(product);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ürün başarıyla eklendi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  Future<void> _updateProduct(AdminProduct product) async {
    try {
      await _adminService.updateProduct(product.id, product);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ürün başarıyla güncellendi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  Future<void> _deleteProduct(AdminProduct product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ürünü Sil'),
        content: Text('${product.name} ürününü silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminService.deleteProduct(product.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ürün başarıyla silindi')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e')),
          );
        }
      }
    }
  }
}

class ProductDialog extends StatefulWidget {
  final AdminProduct? product;
  final Function(AdminProduct) onSave;

  const ProductDialog({
    super.key,
    this.product,
    required this.onSave,
  });

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _categoryController = TextEditingController();
  final _imageUrlController = TextEditingController();
  
  bool _isActive = true;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description;
      _priceController.text = widget.product!.price.toString();
      _stockController.text = widget.product!.stock.toString();
      _categoryController.text = widget.product!.category;
      _imageUrlController.text = widget.product!.imageUrl;
      _isActive = widget.product!.isActive;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Yeni Ürün' : 'Ürün Düzenle'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Resim seçimi
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.cover)
                      : _imageUrlController.text.isNotEmpty
                          ? Image.network(_imageUrlController.text, fit: BoxFit.cover)
                          : const Icon(Icons.add_photo_alternate),
                ),
              ),
              const SizedBox(height: 16),
              
              // Ürün adı
              TextFormField(
                controller: _nameController,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Ürün Adı',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ürün adı gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Açıklama
              TextFormField(
                controller: _descriptionController,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              // Fiyat
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Fiyat',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                textCapitalization: TextCapitalization.none,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Fiyat gerekli';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Geçerli bir fiyat girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Stok
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Stok',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                textCapitalization: TextCapitalization.none,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Stok gerekli';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Geçerli bir stok girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Kategori
              TextFormField(
                controller: _categoryController,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kategori gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Resim URL
              TextFormField(
                controller: _imageUrlController,
                keyboardType: TextInputType.url,
                textCapitalization: TextCapitalization.none,
                decoration: const InputDecoration(
                  labelText: 'Resim URL',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Aktif durumu
              SwitchListTile(
                title: const Text('Aktif'),
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
          onPressed: _saveProduct,
          child: const Text('Kaydet'),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      final product = AdminProduct(
        id: widget.product?.id ?? '',
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        stock: int.parse(_stockController.text),
        category: _categoryController.text,
        imageUrl: _imageUrlController.text,
        isActive: _isActive,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      widget.onSave(product);
      Navigator.pop(context);
    }
  }
}
