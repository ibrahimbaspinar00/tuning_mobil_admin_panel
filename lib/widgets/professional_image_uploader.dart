import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image/image.dart' as img;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class ProfessionalImageUploader extends StatefulWidget {
  final String? initialImageUrl;
  final Function(String imageUrl) onImageUploaded;
  final Function(String? error)? onError;
  final String productId;
  final double? aspectRatio;
  final String? label;
  final bool autoUpload; // Otomatik yükleme seçeneği

  const ProfessionalImageUploader({
    super.key,
    this.initialImageUrl,
    required this.onImageUploaded,
    this.onError,
    required this.productId,
    this.aspectRatio,
    this.label,
    this.autoUpload = false,
  });

  @override
  State<ProfessionalImageUploader> createState() =>
      ProfessionalImageUploaderState();
}

// State'i dışarıdan erişilebilir yapmak için public yapıyoruz
class ProfessionalImageUploaderState extends State<ProfessionalImageUploader> {
  html.File? _selectedWebFile;
  File? _selectedMobileFile;
  Uint8List? _croppedImageBytes;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;
  bool _isDragging = false;
  StreamSubscription<TaskSnapshot>? _uploadProgressSubscription;
  String? _currentUploadedUrl; // Yüklenen URL'i sakla

  String? get uploadedImageUrl => _currentUploadedUrl;
  bool get hasUnuploadedImage => _hasImage() && _currentUploadedUrl == null && !_isUploading;

  @override
  void initState() {
    super.initState();
    _currentUploadedUrl = widget.initialImageUrl;
  }

  // Dışarıdan çağrılabilir: fotoğraf yüklenmemişse yükle
  Future<String?> ensureImageUploaded() async {
    if (!_hasImage()) {
      return null;
    }
    
    // Zaten yüklenmişse URL'i döndür
    if (_currentUploadedUrl != null && _currentUploadedUrl!.isNotEmpty) {
      return _currentUploadedUrl;
    }
    
    // Yüklenmemişse yükle
    if (hasUnuploadedImage) {
      await _uploadImage();
      return _currentUploadedUrl;
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // Drag & Drop Zone veya Preview
        _buildImageArea(),
        
        const SizedBox(height: 12),
        
        // Action Buttons
        _buildActionButtons(),
        
        // Progress Indicator
        if (_isUploading) ...[
          const SizedBox(height: 12),
          _buildProgressIndicator(),
        ],
        
        // Error Message
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          _buildErrorMessage(),
        ],
      ],
    );
  }

  Widget _buildImageArea() {
    final hasImage = _croppedImageBytes != null ||
        _selectedWebFile != null ||
        _selectedMobileFile != null ||
        (widget.initialImageUrl != null && widget.initialImageUrl!.isNotEmpty);

    if (hasImage) {
      return _buildPreview();
    } else {
      return _buildDropZone();
    }
  }

  Widget _buildDropZone() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: _isDragging ? Colors.blue[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isDragging ? Colors.blue : Colors.grey[300]!,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Stack(
          children: [
            // Drag overlay - Web için drag & drop desteği gelecekte eklenebilir
            // Şimdilik sadece click ile dosya seçimi destekleniyor
            
            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 48,
                    color: _isDragging ? Colors.blue : Colors.grey[600],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isDragging ? 'Bırakın' : 'Resim Yükleyin',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _isDragging ? Colors.blue : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    kIsWeb
                        ? 'Dosyayı buraya sürükleyin veya tıklayın'
                        : 'Galeriden seçin',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PNG, JPG, JPEG (Max: 5MB)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
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

  Widget _buildPreview() {
    Widget imageWidget;
    
    if (_croppedImageBytes != null) {
      imageWidget = Image.memory(
        _croppedImageBytes!,
        fit: BoxFit.cover,
      );
    } else if (kIsWeb && _selectedWebFile != null) {
      imageWidget = _buildWebImagePreview();
    } else if (!kIsWeb && _selectedMobileFile != null) {
      imageWidget = Image.file(
        _selectedMobileFile!,
        fit: BoxFit.cover,
      );
    } else if (widget.initialImageUrl != null &&
        widget.initialImageUrl!.isNotEmpty) {
      imageWidget = Image.network(
        widget.initialImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
          );
        },
      );
    } else {
      imageWidget = const Center(
        child: Icon(Icons.image, size: 48, color: Colors.grey),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageWidget,
          ),
          
          // Overlay with actions
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          
          // Action buttons
          Positioned(
            bottom: 8,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_croppedImageBytes != null ||
                    _selectedWebFile != null ||
                    _selectedMobileFile != null)
                  IconButton(
                    onPressed: _showCropDialog,
                    icon: const Icon(Icons.crop, color: Colors.white),
                    tooltip: 'Kırp',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.edit, color: Colors.white),
                  tooltip: 'Değiştir',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green[700],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _removeImage,
                  icon: const Icon(Icons.delete, color: Colors.white),
                  tooltip: 'Sil',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebImagePreview() {
    if (_selectedWebFile == null) {
      return const Center(
        child: Icon(Icons.image, size: 48, color: Colors.grey),
      );
    }

    return FutureBuilder<String>(
      future: _getWebImageUrl(_selectedWebFile!),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.network(
            snapshot.data!,
            fit: BoxFit.cover,
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Future<String> _getWebImageUrl(html.File file) async {
    final reader = html.FileReader();
    reader.readAsDataUrl(file);
    await reader.onLoad.first;
    return reader.result as String;
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isUploading ? null : _pickImage,
            icon: const Icon(Icons.photo_library, size: 18),
            label: Text(_hasImage() ? 'Resim Değiştir' : 'Resim Seç'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        if (_hasImage() && !_isUploading) ...[
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _showCropDialog,
              icon: const Icon(Icons.crop, size: 18),
              label: const Text('Kırp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _uploadImage,
              icon: const Icon(Icons.cloud_upload, size: 18),
              label: const Text('Yükle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        LinearProgressIndicator(
          value: _uploadProgress,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
          minHeight: 8,
        ),
        const SizedBox(height: 8),
        Text(
          '${(_uploadProgress * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: Colors.red[700],
            onPressed: () {
              setState(() => _errorMessage = null);
            },
          ),
        ],
      ),
    );
  }

  bool _hasImage() {
    // Yüklenmiş URL varsa true
    if (_currentUploadedUrl != null && _currentUploadedUrl!.isNotEmpty) {
      return true;
    }
    // Initial URL varsa true
    if (widget.initialImageUrl != null && widget.initialImageUrl!.isNotEmpty) {
      return true;
    }
    // Seçilmiş dosya varsa true
    return _croppedImageBytes != null ||
        _selectedWebFile != null ||
        _selectedMobileFile != null;
  }

  Future<void> _pickImage() async {
    _clearError();
    
    if (kIsWeb) {
      html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((e) {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          _handleWebFile(files[0]);
        }
      });
    } else {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedImage = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedImage != null) {
        _handleMobileFile(File(pickedImage.path));
      }
    }
  }

  void _handleWebFile(html.File file) {
    // Validate file size (max 3MB - retry limit hatası için küçültüldü)
    if (file.size > 3 * 1024 * 1024) {
      _showError('Dosya boyutu çok büyük. Maksimum 3MB olmalıdır. Lütfen resmi küçültün.');
      return;
    }

    // Validate file type
    if (!file.type.startsWith('image/')) {
      _showError('Lütfen geçerli bir resim dosyası seçin.');
      return;
    }

    setState(() {
      _selectedWebFile = file;
      _selectedMobileFile = null;
      _croppedImageBytes = null;
      _currentUploadedUrl = null; // Yeni resim seçildi, URL'i temizle
    });
    
    // Otomatik yükleme açıksa
    if (widget.autoUpload) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _uploadImage();
      });
    }
  }

  void _handleMobileFile(File file) {
    setState(() {
      _selectedMobileFile = file;
      _selectedWebFile = null;
      _croppedImageBytes = null;
      _currentUploadedUrl = null; // Yeni resim seçildi, URL'i temizle
    });
    
    // Otomatik yükleme açıksa
    if (widget.autoUpload) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _uploadImage();
      });
    }
  }

  Future<void> _showCropDialog() async {
    if (!_hasImage()) return;

    _clearError();

    if (kIsWeb) {
      await _cropWebImage();
    } else {
      await _cropMobileImage();
    }
  }

  Future<void> _cropWebImage() async {
    if (_selectedWebFile == null &&
        widget.initialImageUrl == null) return;

    try {
      Uint8List imageBytes;
      
      if (_selectedWebFile != null) {
        // Read file as bytes
        final reader = html.FileReader();
        reader.readAsArrayBuffer(_selectedWebFile!);
        await reader.onLoad.first;
        imageBytes = reader.result as Uint8List;
      } else if (widget.initialImageUrl != null) {
        // Download image from URL
        final response = await html.HttpRequest.request(
          widget.initialImageUrl!,
          method: 'GET',
          responseType: 'arraybuffer',
        );
        imageBytes = response.response as Uint8List;
      } else {
        return;
      }

      // Decode image
      img.Image? decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) {
        _showError('Resim işlenemedi.');
        return;
      }

      // Show crop dialog
        final croppedBytes = await _showWebCropDialog(decodedImage);
        if (croppedBytes != null) {
          setState(() {
            _croppedImageBytes = croppedBytes;
            _currentUploadedUrl = null; // Kırpıldı, URL'i temizle
          });
          
          // Otomatik yükleme açıksa
          if (widget.autoUpload) {
            Future.delayed(const Duration(milliseconds: 500), () {
              _uploadImage();
            });
          }
        }
    } catch (e) {
      _showError('Kırpma işlemi sırasında hata: $e');
    }
  }

  Future<Uint8List?> _showWebCropDialog(img.Image originalImage) async {
    return showDialog<Uint8List>(
      context: context,
      builder: (context) => _WebImageCropDialog(
        originalImage: originalImage,
        aspectRatio: widget.aspectRatio ?? 1.0,
      ),
    );
  }

  Future<void> _cropMobileImage() async {
    if (_selectedMobileFile == null) {
      // Try to use initial image URL for mobile
      if (widget.initialImageUrl == null) return;
      
      // Download and save temporarily
      // For now, just return
      return;
    }

    final CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: _selectedMobileFile!.path,
      aspectRatio: CropAspectRatio(
        ratioX: widget.aspectRatio ?? 1.0,
        ratioY: 1.0,
      ),
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Resmi Kırp',
          toolbarColor: Colors.blue[800]!,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Resmi Kırp',
          aspectRatioLockDimensionSwapEnabled: false,
          resetAspectRatioEnabled: false,
        ),
      ],
    );

    if (croppedFile != null) {
      final croppedBytes = await croppedFile.readAsBytes();
      setState(() {
        _croppedImageBytes = croppedBytes;
        _selectedMobileFile = File(croppedFile.path);
        _currentUploadedUrl = null; // Kırpıldı, URL'i temizle
      });
      
      // Otomatik yükleme açıksa
      if (widget.autoUpload) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _uploadImage();
        });
      }
    }
  }

  Future<void> _uploadImage() async {
    if (!_hasImage()) {
      _showError('Lütfen önce bir resim seçin.');
      return;
    }

    _clearError();
    
    debugPrint('📤 Resim yükleme başlatılıyor...');
    debugPrint('Platform: ${kIsWeb ? "Web" : "Mobile"}');
    
    // Önce state'i güncelle
    if (mounted) {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.01; // %1 başlangıç göster (0'dan farklı)
      });
    }

    try {
      String imageUrl;
      final productId = widget.productId;
      debugPrint('Product ID: $productId');

      if (kIsWeb) {
        if (_croppedImageBytes != null) {
          debugPrint('Web: Kırpılmış resim yükleniyor (${_croppedImageBytes!.length} bytes)');
          imageUrl = await _uploadWebCroppedImage(_croppedImageBytes!, productId);
        } else if (_selectedWebFile != null) {
          debugPrint('Web: Dosya yükleniyor (${_selectedWebFile!.name}, ${_selectedWebFile!.size} bytes)');
          imageUrl = await _uploadWebFile(_selectedWebFile!, productId);
        } else {
          debugPrint('❌ Web: Yüklenecek resim bulunamadı');
          throw Exception('Yüklenecek resim bulunamadı');
        }
      } else {
        if (_croppedImageBytes != null) {
          debugPrint('Mobile: Kırpılmış resim yükleniyor (${_croppedImageBytes!.length} bytes)');
          // Save cropped bytes to temp file and upload
          final tempFile = await _saveCroppedBytesToFile(_croppedImageBytes!);
          imageUrl = await _uploadMobileFile(tempFile, productId);
          await tempFile.delete();
        } else if (_selectedMobileFile != null) {
          debugPrint('Mobile: Dosya yükleniyor (${_selectedMobileFile!.path})');
          imageUrl = await _uploadMobileFile(_selectedMobileFile!, productId);
        } else {
          debugPrint('❌ Mobile: Yüklenecek resim bulunamadı');
          throw Exception('Yüklenecek resim bulunamadı');
        }
      }
      
      debugPrint('✅ Resim başarıyla yüklendi: $imageUrl');

      setState(() {
        _isUploading = false;
        _uploadProgress = 1.0;
      });

      setState(() {
        _currentUploadedUrl = imageUrl;
      });
      
      widget.onImageUploaded(imageUrl);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Resim başarıyla yüklendi'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on FirebaseException catch (e, stackTrace) {
      debugPrint('❌ FirebaseException: ${e.code}');
      debugPrint('   Message: ${e.message}');
      debugPrint('   StackTrace: $stackTrace');
      
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
      
      String errorMessage;
      switch (e.code) {
        case 'storage/retry-limit-exceeded':
          errorMessage = 'Yükleme çok uzun sürdü. Lütfen daha küçük bir resim seçin (max 3MB) veya internet bağlantınızı kontrol edin.';
          break;
        case 'storage/unauthorized':
          errorMessage = 'Yükleme izni yok. Lütfen Firebase Storage kurallarını kontrol edin.';
          break;
        case 'storage/canceled':
          errorMessage = 'Yükleme iptal edildi.';
          break;
        case 'storage/unknown':
          errorMessage = 'Firebase Storage hatası. Lütfen Firebase Console\'dan Storage\'ın aktif olduğunu kontrol edin.';
          break;
        case 'storage/object-not-found':
          errorMessage = 'Storage bucket bulunamadı. Firebase Console\'dan Storage bucket oluşturun.';
          break;
        case 'storage/quota-exceeded':
          errorMessage = 'Firebase Storage kotası dolmuş. Lütfen Firebase Console\'dan kontrol edin.';
          break;
        default:
          errorMessage = 'Firebase Storage hatası: ${e.code}\n${e.message ?? ""}\n\nLütfen Firebase Console\'dan Storage ayarlarını kontrol edin.';
      }
      
      debugPrint('Hata mesajı: $errorMessage');
      _showError(errorMessage);
      widget.onError?.call(errorMessage);
    } catch (e, stackTrace) {
      debugPrint('❌ Genel hata: $e');
      debugPrint('Hata tipi: ${e.runtimeType}');
      debugPrint('StackTrace: $stackTrace');
      
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
      
      String errorMessage = 'Yükleme hatası: ';
      
      if (e.toString().contains('retry-limit-exceeded') || 
          e.toString().contains('timeout') ||
          e.toString().contains('zaman aşımı')) {
        errorMessage = 'Yükleme çok uzun sürdü. Lütfen daha küçük bir resim seçin (max 3MB) veya internet bağlantınızı kontrol edin.';
      } else if (e.toString().contains('unauthorized') || 
                 e.toString().contains('permission')) {
        errorMessage = 'Yükleme izni yok. Firebase Storage kurallarını kontrol edin.';
      } else if (e.toString().contains('bucket') || 
                 e.toString().contains('not found')) {
        errorMessage = 'Firebase Storage bucket bulunamadı. Firebase Console\'dan Storage bucket oluşturun.';
      } else {
        errorMessage = 'Yükleme hatası: ${e.toString()}\n\nLütfen Firebase Console\'dan Storage ayarlarını kontrol edin.';
      }
      
      debugPrint('Hata mesajı: $errorMessage');
      _showError(errorMessage);
      widget.onError?.call(errorMessage);
    }
  }

  Future<String> _uploadWebCroppedImage(
      Uint8List imageBytes, String productId) async {
    debugPrint('📤 Web kırpılmış resim yükleme başlatılıyor...');
    debugPrint('Resim boyutu: ${imageBytes.length} bytes');
    
    final storage = FirebaseStorage.instance;
    debugPrint('Storage bucket: ${storage.app.options.storageBucket}');
    
    final fileName =
        'product_images/$productId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    debugPrint('Dosya yolu: $fileName');
    
    final ref = storage.ref().child(fileName);
    debugPrint('Reference oluşturuldu: ${ref.fullPath}');

    // Create blob from bytes
    debugPrint('Blob oluşturuluyor...');
    final blob = html.Blob([imageBytes], 'image/jpeg');
    debugPrint('Blob oluşturuldu, boyut: ${imageBytes.length} bytes');
    
    debugPrint('Upload task başlatılıyor...');
    final uploadTask = ref.putBlob(
      blob,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    debugPrint('Upload task oluşturuldu');

    // Track progress with proper subscription management
    _uploadProgressSubscription?.cancel();
    
    // İlk progress'i hemen göster
    if (mounted) {
      setState(() {
        _uploadProgress = 0.05; // %5 başlangıç
      });
    }
    
    _uploadProgressSubscription = uploadTask.snapshotEvents.listen(
      (snapshot) {
        if (!mounted) return;
        
        if (snapshot.totalBytes > 0) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          final clampedProgress = progress.clamp(0.05, 0.95);
          setState(() {
            _uploadProgress = clampedProgress;
          });
        } else if (snapshot.bytesTransferred > 0) {
          if (mounted) {
            setState(() {
              _uploadProgress = 0.1;
            });
          }
        }
        
        if (snapshot.state == TaskState.success) {
          if (mounted) {
            setState(() {
              _uploadProgress = 1.0;
            });
          }
        } else if (snapshot.state == TaskState.error) {
          if (mounted) {
            setState(() {
              _uploadProgress = 0.0;
            });
          }
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _uploadProgress = 0.0;
            _isUploading = false;
          });
          _showError('Yükleme hatası: $error');
        }
      },
      cancelOnError: false,
    );

    try {
      // Timeout ile beklemek (5 dakika)
      final snapshot = await uploadTask.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          uploadTask.cancel();
          throw Exception('Yükleme zaman aşımına uğradı. Lütfen tekrar deneyin.');
        },
      );
      
      await _uploadProgressSubscription?.cancel();
      _uploadProgressSubscription = null;
      
      if (mounted) {
        setState(() {
          _uploadProgress = 1.0;
        });
      }
      
      // Download URL al (timeout ile)
      final downloadUrl = await snapshot.ref.getDownloadURL().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Download URL alınamadı. Lütfen tekrar deneyin.');
        },
      );
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      await _uploadProgressSubscription?.cancel();
      _uploadProgressSubscription = null;
      
      String errorMessage = 'Yükleme hatası: ';
      if (e.code == 'storage/retry-limit-exceeded') {
        errorMessage = 'Yükleme çok uzun sürdü. Lütfen daha küçük bir resim seçin veya internet bağlantınızı kontrol edin.';
      } else if (e.code == 'storage/unauthorized') {
        errorMessage = 'Yükleme izni yok. Lütfen giriş yapın.';
      } else {
        errorMessage = 'Firebase Storage hatası: ${e.message ?? e.code}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      await _uploadProgressSubscription?.cancel();
      _uploadProgressSubscription = null;
      rethrow;
    }
  }

  Future<String> _uploadWebFile(html.File file, String productId) async {
    try {
      debugPrint('📤 Web dosya yükleme başlatılıyor...');
      debugPrint('Dosya adı: ${file.name}, Boyut: ${file.size} bytes, Tip: ${file.type}');
      
      final storage = FirebaseStorage.instance;
      debugPrint('Storage bucket: ${storage.app.options.storageBucket}');
      
      final fileName =
          'product_images/$productId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      debugPrint('Dosya yolu: $fileName');
      
      final ref = storage.ref().child(fileName);
      debugPrint('Reference oluşturuldu: ${ref.fullPath}');

      debugPrint('Blob oluşturuluyor...');
      final blob = file.slice(0, file.size, file.type);
      debugPrint('Blob oluşturuldu, boyut: ${file.size} bytes');
      
      debugPrint('Upload task başlatılıyor...');
      final uploadTask = ref.putBlob(
        blob,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      debugPrint('Upload task oluşturuldu');

      // Track progress with proper subscription management
      _uploadProgressSubscription?.cancel();
      
      // İlk progress'i hemen göster
      if (mounted) {
        setState(() {
          _uploadProgress = 0.05; // %5 başlangıç
        });
      }
      
      _uploadProgressSubscription = uploadTask.snapshotEvents.listen(
        (snapshot) {
          if (!mounted) return;
          
          if (snapshot.totalBytes > 0) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            final clampedProgress = progress.clamp(0.05, 0.95);
            setState(() {
              _uploadProgress = clampedProgress;
            });
          } else if (snapshot.bytesTransferred > 0) {
            if (mounted) {
              setState(() {
                _uploadProgress = 0.1;
              });
            }
          }
          
          if (snapshot.state == TaskState.success) {
            if (mounted) {
              setState(() {
                _uploadProgress = 1.0;
              });
            }
          } else if (snapshot.state == TaskState.error) {
            if (mounted) {
              setState(() {
                _uploadProgress = 0.0;
              });
            }
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _uploadProgress = 0.0;
              _isUploading = false;
            });
            _showError('Yükleme hatası: $error');
          }
        },
        cancelOnError: false,
      );

      // Timeout ile beklemek (5 dakika)
      final snapshot = await uploadTask.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          uploadTask.cancel();
          throw Exception('Yükleme zaman aşımına uğradı. Lütfen tekrar deneyin.');
        },
      );
      
      await _uploadProgressSubscription?.cancel();
      _uploadProgressSubscription = null;
      
      if (mounted) {
        setState(() {
          _uploadProgress = 1.0;
        });
      }
      
      // Download URL al (timeout ile)
      final downloadUrl = await snapshot.ref.getDownloadURL().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Download URL alınamadı. Lütfen tekrar deneyin.');
        },
      );
      
      debugPrint('✅ Download URL alındı: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      await _uploadProgressSubscription?.cancel();
      _uploadProgressSubscription = null;
      
      debugPrint('❌ FirebaseException: ${e.code} - ${e.message}');
      
      String errorMessage = 'Yükleme hatası: ';
      if (e.code == 'storage/retry-limit-exceeded') {
        errorMessage = 'Yükleme çok uzun sürdü. Lütfen daha küçük bir resim seçin veya internet bağlantınızı kontrol edin.';
      } else if (e.code == 'storage/unauthorized') {
        errorMessage = 'Yükleme izni yok. Lütfen giriş yapın.';
      } else {
        errorMessage = 'Firebase Storage hatası: ${e.message ?? e.code}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      await _uploadProgressSubscription?.cancel();
      _uploadProgressSubscription = null;
      debugPrint('❌ Genel hata: $e');
      rethrow;
    }
  }

  Future<String> _uploadMobileFile(File file, String productId) async {
    // Use AdminService if available, otherwise direct upload
    final storage = FirebaseStorage.instance;
    final fileName =
        'product_images/$productId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = storage.ref().child(fileName);

    final uploadTask = ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    // Track progress with proper subscription management
    _uploadProgressSubscription?.cancel();
    
    // İlk progress'i hemen göster
    if (mounted) {
      setState(() {
        _uploadProgress = 0.05; // %5 başlangıç
      });
    }
    
    _uploadProgressSubscription = uploadTask.snapshotEvents.listen(
      (snapshot) {
        if (!mounted) return;
        
        if (snapshot.totalBytes > 0) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          final clampedProgress = progress.clamp(0.05, 0.95);
          setState(() {
            _uploadProgress = clampedProgress;
          });
        } else if (snapshot.bytesTransferred > 0) {
          if (mounted) {
            setState(() {
              _uploadProgress = 0.1;
            });
          }
        }
        
        if (snapshot.state == TaskState.success) {
          if (mounted) {
            setState(() {
              _uploadProgress = 1.0;
            });
          }
        } else if (snapshot.state == TaskState.error) {
          if (mounted) {
            setState(() {
              _uploadProgress = 0.0;
            });
          }
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _uploadProgress = 0.0;
            _isUploading = false;
          });
          _showError('Yükleme hatası: $error');
        }
      },
      cancelOnError: false,
    );

    try {
      // Timeout ile beklemek (5 dakika)
      final snapshot = await uploadTask.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          uploadTask.cancel();
          throw Exception('Yükleme zaman aşımına uğradı. Lütfen tekrar deneyin.');
        },
      );
      
      await _uploadProgressSubscription?.cancel();
      _uploadProgressSubscription = null;
      
      if (mounted) {
        setState(() {
          _uploadProgress = 1.0;
        });
      }
      
      // Download URL al (timeout ile)
      final downloadUrl = await snapshot.ref.getDownloadURL().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Download URL alınamadı. Lütfen tekrar deneyin.');
        },
      );
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      await _uploadProgressSubscription?.cancel();
      _uploadProgressSubscription = null;
      
      String errorMessage = 'Yükleme hatası: ';
      if (e.code == 'storage/retry-limit-exceeded') {
        errorMessage = 'Yükleme çok uzun sürdü. Lütfen daha küçük bir resim seçin veya internet bağlantınızı kontrol edin.';
      } else if (e.code == 'storage/unauthorized') {
        errorMessage = 'Yükleme izni yok. Lütfen giriş yapın.';
      } else {
        errorMessage = 'Firebase Storage hatası: ${e.message ?? e.code}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      await _uploadProgressSubscription?.cancel();
      _uploadProgressSubscription = null;
      rethrow;
    }
  }

  Future<File> _saveCroppedBytesToFile(Uint8List bytes) async {
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(bytes);
    return tempFile;
  }

  @override
  void dispose() {
    _uploadProgressSubscription?.cancel();
    super.dispose();
  }

  void _removeImage() {
    _uploadProgressSubscription?.cancel();
    setState(() {
      _selectedWebFile = null;
      _selectedMobileFile = null;
      _croppedImageBytes = null;
      _errorMessage = null;
      _uploadProgress = 0.0;
      _currentUploadedUrl = null;
    });
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
    widget.onError?.call(message);
  }

  void _clearError() {
    setState(() {
      _errorMessage = null;
    });
  }
}

// Web Image Crop Dialog
class _WebImageCropDialog extends StatefulWidget {
  final img.Image originalImage;
  final double aspectRatio;

  const _WebImageCropDialog({
    required this.originalImage,
    required this.aspectRatio,
  });

  @override
  State<_WebImageCropDialog> createState() => _WebImageCropDialogState();
}

class _WebImageCropDialogState extends State<_WebImageCropDialog> {
  double _cropX = 0.0;
  double _cropY = 0.0;
  double _cropWidth = 100.0;
  double _cropHeight = 100.0;
  late double _imageWidth;
  late double _imageHeight;

  @override
  void initState() {
    super.initState();
    _imageWidth = widget.originalImage.width.toDouble();
    _imageHeight = widget.originalImage.height.toDouble();
    
    // Calculate initial crop size (square)
    final size = _imageWidth < _imageHeight ? _imageWidth : _imageHeight;
    _cropWidth = size * 0.8;
    _cropHeight = _cropWidth / widget.aspectRatio;
    _cropX = (_imageWidth - _cropWidth) / 2;
    _cropY = (_imageHeight - _cropHeight) / 2;
  }

  @override
  Widget build(BuildContext context) {
    final imageBytes = Uint8List.fromList(img.encodeJpg(widget.originalImage));
    
    return Dialog(
      child: Container(
        width: 600,
        height: 700,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Resmi Kırp',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Center(
                          child: Image.memory(
                            imageBytes,
                            fit: BoxFit.contain,
                          ),
                        ),
                        _buildCropOverlay(constraints),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _applyCrop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Kırp ve Uygula'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropOverlay(BoxConstraints constraints) {
    // Calculate image display size
    final imageAspectRatio = _imageWidth / _imageHeight;
    final containerAspectRatio = constraints.maxWidth / constraints.maxHeight;
    
    double displayWidth, displayHeight;
    if (imageAspectRatio > containerAspectRatio) {
      displayWidth = constraints.maxWidth;
      displayHeight = constraints.maxWidth / imageAspectRatio;
    } else {
      displayHeight = constraints.maxHeight;
      displayWidth = constraints.maxHeight * imageAspectRatio;
    }
    
    // Scale crop coordinates to display size
    final scaleX = displayWidth / _imageWidth;
    final scaleY = displayHeight / _imageHeight;
    final displayCropX = _cropX * scaleX;
    final displayCropY = _cropY * scaleY;
    final displayCropWidth = _cropWidth * scaleX;
    final displayCropHeight = _cropHeight * scaleY;
    
    return Positioned(
      left: (constraints.maxWidth - displayWidth) / 2 + displayCropX,
      top: (constraints.maxHeight - displayHeight) / 2 + displayCropY,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _cropX += details.delta.dx / scaleX;
            _cropY += details.delta.dy / scaleY;
            
            // Constrain to image bounds
            _cropX = _cropX.clamp(0.0, _imageWidth - _cropWidth);
            _cropY = _cropY.clamp(0.0, _imageHeight - _cropHeight);
          });
        },
        child: Container(
          width: displayCropWidth,
          height: displayCropHeight,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue, width: 2),
            color: Colors.transparent,
          ),
          child: Stack(
            children: [
              // Corner handles
              ..._buildCornerHandles(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCornerHandles() {
    return [
      // Top-left
      Positioned(
        left: -8,
        top: -8,
        child: _buildHandle(),
      ),
      // Top-right
      Positioned(
        right: -8,
        top: -8,
        child: _buildHandle(),
      ),
      // Bottom-left
      Positioned(
        left: -8,
        bottom: -8,
        child: _buildHandle(),
      ),
      // Bottom-right
      Positioned(
        right: -8,
        bottom: -8,
        child: _buildHandle(),
      ),
    ];
  }

  Widget _buildHandle() {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.blue,
        border: Border.all(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  void _applyCrop() {
    final croppedImage = img.copyCrop(
      widget.originalImage,
      x: _cropX.toInt(),
      y: _cropY.toInt(),
      width: _cropWidth.toInt(),
      height: _cropHeight.toInt(),
    );

    final croppedBytes = Uint8List.fromList(img.encodeJpg(croppedImage));
    Navigator.pop(context, croppedBytes);
  }
}

