import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/admin_service.dart';
import 'model/admin_product.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Panel',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const WebAdminSimple(),
    );
  }
}

class WebAdminSimple extends StatefulWidget {
  const WebAdminSimple({super.key});

  @override
  State<WebAdminSimple> createState() => _WebAdminSimpleState();
}

class _WebAdminSimpleState extends State<WebAdminSimple> {
  final AdminService _adminService = AdminService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel - Basit Versiyon'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ürün Yönetimi',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showAddProductDialog,
              child: const Text('Yeni Ürün Ekle'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<AdminProduct>>(
                stream: _adminService.getProducts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(child: Text('Hata: ${snapshot.error}'));
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
                          title: Text(product.name),
                          subtitle: Text('₺${product.price.toStringAsFixed(2)} - Stok: ${product.stock}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _showEditProductDialog(product),
                                icon: const Icon(Icons.edit),
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
      ),
    );
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => _ProductDialog(
        onSave: _addProduct,
      ),
    );
  }

  void _showEditProductDialog(AdminProduct product) {
    showDialog(
      context: context,
      builder: (context) => _ProductDialog(
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

class _ProductDialog extends StatefulWidget {
  final AdminProduct? product;
  final Function(AdminProduct) onSave;

  const _ProductDialog({
    this.product,
    required this.onSave,
  });

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _priceController.text = widget.product!.price.toString();
      _stockController.text = widget.product!.stock.toString();
      _categoryController.text = widget.product!.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Yeni Ürün' : 'Ürün Düzenle'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Ürün Adı'),
              validator: (value) => value?.isEmpty == true ? 'Ürün adı gerekli' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Fiyat'),
              keyboardType: TextInputType.number,
              validator: (value) => value?.isEmpty == true ? 'Fiyat gerekli' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stockController,
              decoration: const InputDecoration(labelText: 'Stok'),
              keyboardType: TextInputType.number,
              validator: (value) => value?.isEmpty == true ? 'Stok gerekli' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Kategori'),
              validator: (value) => value?.isEmpty == true ? 'Kategori gerekli' : null,
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
          onPressed: _saveProduct,
          child: const Text('Kaydet'),
        ),
      ],
    );
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      final product = AdminProduct(
        id: widget.product?.id ?? '',
        name: _nameController.text,
        description: '',
        price: double.parse(_priceController.text),
        stock: int.parse(_stockController.text),
        category: _categoryController.text,
        imageUrl: '',
        isActive: true,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      widget.onSave(product);
      Navigator.pop(context);
    }
  }
}
