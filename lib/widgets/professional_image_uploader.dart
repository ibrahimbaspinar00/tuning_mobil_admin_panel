import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image/image.dart' as img;
// Firebase Storage kaldırıldı - sadece Base64 kullanılıyor

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
  // Firebase Storage kaldırıldı - artık kullanılmıyor
  // StreamSubscription<TaskSnapshot>? _uploadProgressSubscription;
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
    debugPrint('🔍 ensureImageUploaded çağrıldı');
    
    if (!_hasImage()) {
      debugPrint('⚠️ Resim bulunamadı');
      return null;
    }
    
    // Zaten yüklenmişse URL'i döndür
    if (_currentUploadedUrl != null && _currentUploadedUrl!.isNotEmpty) {
      debugPrint('✅ Resim zaten yüklenmiş: ${_currentUploadedUrl!.substring(0, _currentUploadedUrl!.length > 50 ? 50 : _currentUploadedUrl!.length)}...');
      return _currentUploadedUrl;
    }
    
    // Yüklenmemişse yükle
    if (hasUnuploadedImage) {
      debugPrint('📤 Resim yükleniyor...');
      try {
        await _uploadImage();
        debugPrint('✅ Resim yükleme tamamlandı: ${_currentUploadedUrl != null ? (_currentUploadedUrl!.length > 50 ? _currentUploadedUrl!.substring(0, 50) + '...' : _currentUploadedUrl) : 'NULL'}');
        return _currentUploadedUrl;
      } catch (e) {
        debugPrint('❌ ensureImageUploaded hatası: $e');
        rethrow;
      }
    }
    
    debugPrint('⚠️ Yüklenecek resim yok');
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
          // Manuel yükleme butonu (autoUpload false ise)
          if (!widget.autoUpload && hasUnuploadedImage) ...[
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
    debugPrint('📁 Web dosyası seçildi: ${file.name}, Boyut: ${file.size} bytes, Tip: ${file.type}');
    
    // Validate file size (max 5MB)
    if (file.size > 5 * 1024 * 1024) {
      _showError('Dosya boyutu çok büyük. Maksimum 5MB olmalıdır. Lütfen resmi küçültün.');
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
    
    debugPrint('✅ Dosya state\'e eklendi. autoUpload: ${widget.autoUpload}');
    
    // Otomatik yükleme açıksa
    if (widget.autoUpload) {
      debugPrint('📤 Otomatik yükleme aktif, 500ms sonra yükleme başlatılacak...');
      Future.delayed(const Duration(milliseconds: 500), () {
        debugPrint('📤 Otomatik yükleme başlatılıyor...');
        _uploadImage();
      });
    } else {
      debugPrint('ℹ️ Otomatik yükleme kapalı, manuel yükleme bekleniyor');
    }
  }

  void _handleMobileFile(File file) {
    debugPrint('📁 Mobile dosyası seçildi: ${file.path}');
    
    setState(() {
      _selectedMobileFile = file;
      _selectedWebFile = null;
      _croppedImageBytes = null;
      _currentUploadedUrl = null; // Yeni resim seçildi, URL'i temizle
    });
    
    debugPrint('✅ Dosya state\'e eklendi. autoUpload: ${widget.autoUpload}');
    
    // Otomatik yükleme açıksa
    if (widget.autoUpload) {
      debugPrint('📤 Otomatik yükleme aktif, 500ms sonra yükleme başlatılacak...');
      Future.delayed(const Duration(milliseconds: 500), () {
        debugPrint('📤 Otomatik yükleme başlatılıyor...');
        _uploadImage();
      });
    } else {
      debugPrint('ℹ️ Otomatik yükleme kapalı, manuel yükleme bekleniyor');
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
      // Base64 yöntemi kullanılıyor (Firebase Storage olmadan)
      debugPrint('📤 Resim yükleme başlatılıyor (Base64 yöntemi)...');

      // Progress güncellemesi
      if (mounted) {
        setState(() {
          _uploadProgress = 0.2; // %20
        });
      }

      String imageUrl;
      
      // Direkt Base64 kullan (Firebase Storage yok)
      debugPrint('📤 Base64 yöntemi kullanılıyor (Firestore\'a direkt kayıt)...');
      
      if (mounted) {
        setState(() {
          _uploadProgress = 0.3; // Base64 için %30
        });
      }
      
      imageUrl = await _uploadAsBase64(widget.productId);
      if (imageUrl.isEmpty) {
        throw Exception('Resim yüklenemedi (Base64 başarısız)');
      }
      debugPrint('✅ Resim başarıyla Base64 olarak Firestore\'a kaydedildi');

      setState(() {
        _isUploading = false;
        _uploadProgress = 1.0;
        _currentUploadedUrl = imageUrl;
      });

      widget.onImageUploaded(imageUrl);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Resim başarıyla kaydedildi (Base64 - Firestore)'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Genel hata: $e');
      debugPrint('Hata tipi: ${e.runtimeType}');
      debugPrint('StackTrace: $stackTrace');
      
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
      
      String errorMessage = 'Yükleme hatası: ${e.toString()}';
      
      debugPrint('Hata mesajı: $errorMessage');
      _showError(errorMessage);
      widget.onError?.call(errorMessage);
    }
  }

  // Base64 yöntemi - Firebase Storage yoksa fallback olarak kullanılır
  // Basitleştirilmiş ve hızlandırılmış versiyon
  Future<String> _uploadAsBase64(String productId) async {
    try {
      debugPrint('📤 Base64 yükleme başlatılıyor (hızlı mod)...');
      
      // Progress: %30
      if (mounted) {
        setState(() {
          _uploadProgress = 0.3;
        });
      }
      
      Uint8List? imageBytes;
      
      // Resim verisini al
      if (kIsWeb) {
        if (_croppedImageBytes != null) {
          imageBytes = _croppedImageBytes;
        } else if (_selectedWebFile != null) {
          final reader = html.FileReader();
          reader.readAsArrayBuffer(_selectedWebFile!);
          await reader.onLoad.first;
          imageBytes = reader.result as Uint8List;
        }
      } else {
        if (_croppedImageBytes != null) {
          imageBytes = _croppedImageBytes;
        } else if (_selectedMobileFile != null) {
          imageBytes = await _selectedMobileFile!.readAsBytes();
        }
      }
      
      if (imageBytes == null) {
        throw Exception('Resim verisi bulunamadı');
      }
      
      debugPrint('📦 Orijinal resim boyutu: ${imageBytes.length} bytes');
      
      // Progress: %40
      if (mounted) {
        setState(() {
          _uploadProgress = 0.4;
        });
      }
      
      // Resmi decode et (timeout olmadan, direkt)
      img.Image? decodedImage;
      try {
        decodedImage = img.decodeImage(imageBytes);
      } catch (e) {
        debugPrint('❌ Resim decode hatası: $e');
        throw Exception('Resim işlenemedi. Lütfen farklı bir resim deneyin.');
      }
      
      if (decodedImage == null) {
        throw Exception('Resim decode edilemedi');
      }
      
      final image = decodedImage;
      debugPrint('📐 Orijinal boyutlar: ${image.width}x${image.height}');
      
      // Progress: %50
      if (mounted) {
        setState(() {
          _uploadProgress = 0.5;
        });
      }
      
      // Resmi küçült (max 500x500 - daha küçük Base64 string için)
      int maxSize = 500;
      img.Image finalImage = image;
      if (image.width > maxSize || image.height > maxSize) {
        double ratio = image.width > image.height
            ? maxSize / image.width
            : maxSize / image.height;
        
        final targetWidth = (image.width * ratio).toInt();
        final targetHeight = (image.height * ratio).toInt();
        
        try {
          finalImage = img.copyResize(
            image,
            width: targetWidth,
            height: targetHeight,
            interpolation: img.Interpolation.linear,
          );
          debugPrint('📐 Resim küçültüldü: ${finalImage.width}x${finalImage.height}');
        } catch (e) {
          debugPrint('⚠️ Resize hatası, orijinal boyut kullanılıyor: $e');
          finalImage = image;
        }
      }
      
      // Progress: %70
      if (mounted) {
        setState(() {
          _uploadProgress = 0.7;
        });
      }
      
      // JPEG olarak encode et (kalite 70% - daha küçük dosya)
      Uint8List optimizedBytes;
      try {
        optimizedBytes = Uint8List.fromList(img.encodeJpg(finalImage, quality: 70));
      } catch (e) {
        debugPrint('❌ JPEG encode hatası: $e');
        throw Exception('Resim optimize edilemedi');
      }
      
      debugPrint('📦 Optimize edilmiş boyut: ${optimizedBytes.length} bytes');
      
      // Progress: %85
      if (mounted) {
        setState(() {
          _uploadProgress = 0.85;
        });
      }
      
      // Base64 string'e çevir (direkt, timeout yok)
      final base64String = base64Encode(optimizedBytes);
      final dataUrl = 'data:image/jpeg;base64,$base64String';
      
      debugPrint('📝 Base64 string uzunluğu: ${base64String.length} karakter');
      debugPrint('📝 Data URL uzunluğu: ${dataUrl.length} karakter');
      
      // Firestore limit kontrolü (1MB = 1,048,576 bytes)
      if (dataUrl.length > 1000000) {
        debugPrint('⚠️ Base64 string çok büyük (${dataUrl.length} karakter), daha fazla küçültülüyor...');
        
        // Daha küçük boyut ve daha düşük kalite ile tekrar dene
        final smallerImage = img.copyResize(finalImage, width: 400, height: 400);
        final smallerBytes = Uint8List.fromList(img.encodeJpg(smallerImage, quality: 60));
        final smallerBase64 = base64Encode(smallerBytes);
        final smallerDataUrl = 'data:image/jpeg;base64,$smallerBase64';
        
        debugPrint('📝 Küçültülmüş Base64 string uzunluğu: ${smallerBase64.length} karakter');
        
        if (smallerDataUrl.length > 1000000) {
          throw Exception('Resim çok büyük. Lütfen daha küçük bir resim seçin.');
        }
        
        // Progress: %100
        if (mounted) {
          setState(() {
            _uploadProgress = 1.0;
          });
        }
        
        debugPrint('✅ Base64 URL oluşturuldu (küçültülmüş, ${smallerDataUrl.length} karakter)');
        return smallerDataUrl;
      }
      
      // Progress: %100
      if (mounted) {
        setState(() {
          _uploadProgress = 1.0;
        });
      }
      
      debugPrint('✅ Base64 URL oluşturuldu (${dataUrl.length} karakter)');
      return dataUrl;
      
    } catch (e, stackTrace) {
      debugPrint('❌ Base64 yükleme hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Firebase Storage kaldırıldı - artık kullanılmıyor
  // Aşağıdaki metodlar artık kullanılmıyor (Firebase Storage bağımlılığı nedeniyle)
  // ignore: unused_element
  /* Kaldırıldı - Firebase Storage artık kullanılmıyor
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
      SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000', // 1 yıl cache
        customMetadata: {
          'public': 'true', // Public erişim için işaret
        },
      ),
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
        
        debugPrint('📊 Upload snapshot: state=${snapshot.state}, bytesTransferred=${snapshot.bytesTransferred}, totalBytes=${snapshot.totalBytes}');
        
        // State kontrolü öncelikli
        if (snapshot.state == TaskState.success) {
          debugPrint('✅ Upload başarıyla tamamlandı');
          if (mounted) {
            setState(() {
              _uploadProgress = 1.0;
            });
          }
          return;
        } else if (snapshot.state == TaskState.error) {
          debugPrint('❌ Upload hatası: ${snapshot.state}');
          if (mounted) {
            setState(() {
              _uploadProgress = 0.0;
              _isUploading = false;
            });
            _showError('Yükleme hatası: Upload başarısız oldu');
          }
          return;
        } else if (snapshot.state == TaskState.canceled) {
          debugPrint('⚠️ Upload iptal edildi');
          if (mounted) {
            setState(() {
              _uploadProgress = 0.0;
              _isUploading = false;
            });
          }
          return;
        }
        
        // Progress hesaplama - totalBytes kontrolü
        if (snapshot.totalBytes > 0) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          // Gerçek progress'i göster, minimum %5, maksimum %95
          final clampedProgress = progress.clamp(0.05, 0.95);
          debugPrint('📈 Progress: ${(clampedProgress * 100).toStringAsFixed(1)}% (${snapshot.bytesTransferred}/${snapshot.totalBytes} bytes)');
          if (mounted) {
            setState(() {
              _uploadProgress = clampedProgress;
            });
          }
        } else if (snapshot.state == TaskState.running) {
          // Upload başladı ama totalBytes henüz bilinmiyor
          // Yavaş yavaş artır ama gerçek progress gelene kadar çok yüksek çıkarma
          if (mounted && _uploadProgress < 0.2) {
            setState(() {
              _uploadProgress = (_uploadProgress + 0.02).clamp(0.05, 0.2);
            });
          }
        } else if (snapshot.bytesTransferred > 0) {
          // Bytes transfer ediliyor ama totalBytes bilinmiyor
          if (mounted && _uploadProgress < 0.15) {
            setState(() {
              _uploadProgress = 0.1;
            });
          }
        }
      },
      onError: (error) {
        debugPrint('❌ Progress listener hatası: $error');
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
        const Duration(minutes: 10),
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
  */ // Yorum bloğu kapatıldı

  // Kullanılmıyor - Firebase Storage yerine Base64 kullanılıyor
  // ignore: unused_element
  /* Kaldırıldı - Firebase Storage artık kullanılmıyor
  Future<String> _uploadWebFile(html.File file, String productId) async {
    try {
      debugPrint('📤 Web dosya yükleme başlatılıyor...');
      debugPrint('Dosya adı: ${file.name}, Boyut: ${file.size} bytes, Tip: ${file.type}');

      // Firebase Storage instance kontrolü
      final storage = FirebaseStorage.instance;
      debugPrint('Storage bucket: ${storage.app.options.storageBucket}');

      // Firebase konfigürasyon kontrolü
      if (storage.app.options.storageBucket == null || storage.app.options.storageBucket!.isEmpty) {
        throw Exception('Firebase Storage bucket yapılandırılmamış. Firebase Console\'dan Storage ayarlarını kontrol edin.');
      }

      // Authentication kontrolü (Firebase Storage için gerekli olabilir)
      debugPrint('🔐 Authentication kontrolü...');
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;
      debugPrint('Current user: ${currentUser?.uid ?? 'null'}');

      if (currentUser == null) {
        debugPrint('⚠️ Kullanıcı giriş yapmamış, anonim giriş deneniyor...');
        try {
          await auth.signInAnonymously();
          debugPrint('✅ Anonim giriş başarılı');
        } catch (e) {
          debugPrint('❌ Anonim giriş başarısız: $e');
          throw Exception('Firebase Authentication gerekli. Lütfen giriş yapın.');
        }
      } else {
        debugPrint('✅ Kullanıcı giriş yapmış');
      }

      final fileName =
          'product_images/$productId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      debugPrint('Dosya yolu: $fileName');

      final ref = storage.ref().child(fileName);
      debugPrint('Reference oluşturuldu: ${ref.fullPath}');

      debugPrint('📂 HTML File\'dan Uint8List\'e çeviriliyor...');
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;
      final Uint8List imageBytes = reader.result as Uint8List;
      debugPrint('✅ Uint8List oluşturuldu, boyut: ${imageBytes.length} bytes');

      debugPrint('📤 Upload task başlatılıyor...');
      debugPrint('Upload parametreleri:');
      debugPrint('  - ContentType: image/jpeg');
      debugPrint('  - CacheControl: public, max-age=31536000');
      debugPrint('  - CustomMetadata: {public: true}');
      debugPrint('  - Data size: ${imageBytes.length} bytes');

      final uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          cacheControl: 'public, max-age=31536000', // 1 yıl cache
          customMetadata: {
            'public': 'true', // Public erişim için işaret
          },
        ),
      );
      debugPrint('✅ Upload task oluşturuldu');
      debugPrint('Task ID: ${uploadTask.hashCode}');

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

          debugPrint('📊 Upload snapshot: state=${snapshot.state}, bytesTransferred=${snapshot.bytesTransferred}, totalBytes=${snapshot.totalBytes}');

          // State kontrolü öncelikli
          if (snapshot.state == TaskState.success) {
            debugPrint('✅ Upload başarıyla tamamlandı');
            if (mounted) {
              setState(() {
                _uploadProgress = 1.0;
              });
            }
            return;
          } else if (snapshot.state == TaskState.error) {
            debugPrint('❌ Upload hatası: ${snapshot.state}');
            if (mounted) {
              setState(() {
                _uploadProgress = 0.0;
                _isUploading = false;
              });
              _showError('Yükleme hatası: Upload başarısız oldu');
            }
            return;
          } else if (snapshot.state == TaskState.canceled) {
            debugPrint('⚠️ Upload iptal edildi');
            if (mounted) {
              setState(() {
                _uploadProgress = 0.0;
                _isUploading = false;
              });
            }
            return;
          }

          // Progress hesaplama - totalBytes kontrolü
          if (snapshot.totalBytes > 0 && snapshot.totalBytes > 0) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            // Gerçek progress'i göster, minimum %5, maksimum %95
            final clampedProgress = progress.clamp(0.05, 0.95);
            debugPrint('📈 Progress: ${(clampedProgress * 100).toStringAsFixed(1)}% (${snapshot.bytesTransferred}/${snapshot.totalBytes} bytes)');
            if (mounted) {
              setState(() {
                _uploadProgress = clampedProgress;
              });
            }
          } else if (snapshot.state == TaskState.running) {
            // Upload başladı ama totalBytes henüz bilinmiyor
            // Yavaş yavaş artır ama gerçek progress gelene kadar çok yüksek çıkarma
            if (mounted && _uploadProgress < 0.2) {
              setState(() {
                _uploadProgress = (_uploadProgress + 0.02).clamp(0.05, 0.2);
              });
            }
            debugPrint('⏳ Upload çalışıyor, progress bekleniyor...');
          } else if (snapshot.bytesTransferred > 0) {
            // Bytes transfer ediliyor ama totalBytes bilinmiyor
            if (mounted && _uploadProgress < 0.15) {
              setState(() {
                _uploadProgress = 0.1;
              });
            }
            debugPrint('📤 Veri transferi başladı: ${snapshot.bytesTransferred} bytes');
          } else if (snapshot.state == TaskState.running && snapshot.bytesTransferred == 0) {
            debugPrint('⏳ Upload başladı ama henüz veri transfer edilmedi');
          }
        },
        onError: (error) {
          debugPrint('❌ Progress listener hatası: $error');
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

      // Upload task'ın başladığını kontrol et
      debugPrint('⏳ Upload task durumu kontrol ediliyor...');

      // Kısa bir süre bekle ve task durumunu kontrol et
      await Future.delayed(const Duration(milliseconds: 500));
      final initialSnapshot = uploadTask.snapshot;
      debugPrint('📊 İlk snapshot durumu (500ms sonra): state=${initialSnapshot.state}, bytesTransferred=${initialSnapshot.bytesTransferred}, totalBytes=${initialSnapshot.totalBytes}');

      if (initialSnapshot.state == TaskState.error) {
        debugPrint('❌ Upload başlatılamadı - Error state');
        throw Exception('Upload başlatılamadı. Firebase Storage ayarlarını kontrol edin.');
      }

      // Eğer hala paused durumda ise, devam ettir
      if (initialSnapshot.state == TaskState.paused) {
        debugPrint('⏸️ Upload paused durumda, devam ettiriliyor...');
        uploadTask.resume();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Tekrar kontrol et
      final secondSnapshot = uploadTask.snapshot;
      debugPrint('📊 İkinci snapshot durumu: state=${secondSnapshot.state}, bytesTransferred=${secondSnapshot.bytesTransferred}, totalBytes=${secondSnapshot.totalBytes}');

      // Eğer hala running durumda ama hiç byte transfer edilmediyse, uyarı ver
      if (secondSnapshot.state == TaskState.running && secondSnapshot.bytesTransferred == 0) {
        debugPrint('⚠️ Upload başladı ama henüz veri transfer edilmedi.');
        debugPrint('   - Dosya boyutu: ${imageBytes.length} bytes');
        debugPrint('   - Firebase Storage bucket: ${storage.app.options.storageBucket}');
        debugPrint('   - Ağ bağlantısını kontrol edin');

        // 5 saniye daha bekle ve tekrar kontrol et
        await Future.delayed(const Duration(seconds: 5));
        final thirdSnapshot = uploadTask.snapshot;
        debugPrint('📊 Üçüncü kontrol (5sn sonra): state=${thirdSnapshot.state}, bytesTransferred=${thirdSnapshot.bytesTransferred}');

        if (thirdSnapshot.state == TaskState.running && thirdSnapshot.bytesTransferred == 0) {
          debugPrint('🚨 KRİTİK: Upload hala başlamadı! Muhtemel sorunlar:');
          debugPrint('   - Ağ bağlantısı yok veya çok yavaş');
          debugPrint('   - Firebase Storage izinleri');
          debugPrint('   - Dosya boyutu çok büyük');
          debugPrint('   - Firebase Storage kota limiti');
        }
      }
      
      if (initialSnapshot.state == TaskState.error) {
        throw Exception('Upload başlatılamadı. Lütfen Firebase Storage ayarlarını kontrol edin.');
      }
      
      // Timeout ile beklemek (5 dakika)
      debugPrint('⏳ Upload tamamlanması bekleniyor...');
      final snapshot = await uploadTask.timeout(
        const Duration(minutes: 10),
        onTimeout: () {
          debugPrint('❌ Upload zaman aşımına uğradı (10 dakika)');
          uploadTask.cancel();
          throw Exception('Yükleme zaman aşımına uğradı. Ağ bağlantınızı kontrol edin ve tekrar deneyin.');
        },
      );
      
      debugPrint('✅ Upload tamamlandı, durum: ${snapshot.state}');
      
      await _uploadProgressSubscription?.cancel();
      _uploadProgressSubscription = null;
      
      if (snapshot.state != TaskState.success) {
        throw Exception('Upload başarısız oldu. Durum: ${snapshot.state}');
      }
      
      if (mounted) {
        setState(() {
          _uploadProgress = 1.0;
        });
      }
      
      // Public URL oluştur (daha güvenilir, süresi dolmaz)
      final bucket = snapshot.ref.storage.app.options.storageBucket;
      final publicUrl = 'https://storage.googleapis.com/$bucket/${snapshot.ref.fullPath}';
      
      debugPrint('🔗 Public URL oluşturuldu: $publicUrl');
      
      // Alternatif olarak download URL de al (fallback için)
      try {
        final downloadUrl = await snapshot.ref.getDownloadURL().timeout(
          const Duration(seconds: 10),
        );
        debugPrint('✅ Download URL de alındı (fallback): $downloadUrl');
        // Public URL'yi tercih et, ama download URL de çalışıyorsa onu kullan
        return publicUrl;
      } catch (e) {
        debugPrint('⚠️ Download URL alınamadı, public URL kullanılıyor: $e');
        return publicUrl;
      }
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
  */ // Yorum bloğu kapatıldı

  // Kullanılmıyor - Firebase Storage yerine Base64 kullanılıyor
  // ignore: unused_element
  /* Kaldırıldı - Firebase Storage artık kullanılmıyor
  Future<String> _uploadMobileFile(File file, String productId) async {
    // Use AdminService if available, otherwise direct upload
    final storage = FirebaseStorage.instance;
    final fileName =
        'product_images/$productId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = storage.ref().child(fileName);

    final uploadTask = ref.putFile(
      file,
      SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000', // 1 yıl cache
        customMetadata: {
          'public': 'true', // Public erişim için işaret
        },
      ),
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
        
        debugPrint('📊 Upload snapshot: state=${snapshot.state}, bytesTransferred=${snapshot.bytesTransferred}, totalBytes=${snapshot.totalBytes}');
        
        // State kontrolü öncelikli
        if (snapshot.state == TaskState.success) {
          debugPrint('✅ Upload başarıyla tamamlandı');
          if (mounted) {
            setState(() {
              _uploadProgress = 1.0;
            });
          }
          return;
        } else if (snapshot.state == TaskState.error) {
          debugPrint('❌ Upload hatası: ${snapshot.state}');
          if (mounted) {
            setState(() {
              _uploadProgress = 0.0;
              _isUploading = false;
            });
            _showError('Yükleme hatası: Upload başarısız oldu');
          }
          return;
        } else if (snapshot.state == TaskState.canceled) {
          debugPrint('⚠️ Upload iptal edildi');
          if (mounted) {
            setState(() {
              _uploadProgress = 0.0;
              _isUploading = false;
            });
          }
          return;
        }
        
        // Progress hesaplama - totalBytes kontrolü
        if (snapshot.totalBytes > 0) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          // Gerçek progress'i göster, minimum %5, maksimum %95
          final clampedProgress = progress.clamp(0.05, 0.95);
          debugPrint('📈 Progress: ${(clampedProgress * 100).toStringAsFixed(1)}% (${snapshot.bytesTransferred}/${snapshot.totalBytes} bytes)');
          if (mounted) {
            setState(() {
              _uploadProgress = clampedProgress;
            });
          }
        } else if (snapshot.state == TaskState.running) {
          // Upload başladı ama totalBytes henüz bilinmiyor
          // Yavaş yavaş artır ama gerçek progress gelene kadar çok yüksek çıkarma
          if (mounted && _uploadProgress < 0.2) {
            setState(() {
              _uploadProgress = (_uploadProgress + 0.02).clamp(0.05, 0.2);
            });
          }
        } else if (snapshot.bytesTransferred > 0) {
          // Bytes transfer ediliyor ama totalBytes bilinmiyor
          if (mounted && _uploadProgress < 0.15) {
            setState(() {
              _uploadProgress = 0.1;
            });
          }
        }
      },
      onError: (error) {
        debugPrint('❌ Progress listener hatası: $error');
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
      // Upload task'ın başladığını kontrol et
      debugPrint('⏳ Upload task durumu kontrol ediliyor...');

      // Daha uzun süre bekle ve task durumunu kontrol et (2 saniye)
      await Future.delayed(const Duration(seconds: 2));
      final initialSnapshot = uploadTask.snapshot;
      debugPrint('📊 İlk snapshot durumu: state=${initialSnapshot.state}, bytesTransferred=${initialSnapshot.bytesTransferred}');

      if (initialSnapshot.state == TaskState.error) {
        throw Exception('Upload başlatılamadı. Lütfen Firebase Storage ayarlarını kontrol edin.');
      }

      // Eğer hala running durumda ama hiç byte transfer edilmediyse, uyarı ver
      if (initialSnapshot.state == TaskState.running && initialSnapshot.bytesTransferred == 0) {
        debugPrint('⚠️ Upload başladı ama henüz veri transfer edilmedi. Ağ bağlantısını kontrol edin.');
      }
      
      // Timeout ile beklemek (5 dakika)
      debugPrint('⏳ Upload tamamlanması bekleniyor...');
      final snapshot = await uploadTask.timeout(
        const Duration(minutes: 10),
        onTimeout: () {
          debugPrint('❌ Upload zaman aşımına uğradı (10 dakika)');
          uploadTask.cancel();
          throw Exception('Yükleme zaman aşımına uğradı. Ağ bağlantınızı kontrol edin ve tekrar deneyin.');
        },
      );
      
      debugPrint('✅ Upload tamamlandı, durum: ${snapshot.state}');
      
      await _uploadProgressSubscription?.cancel();
      _uploadProgressSubscription = null;
      
      if (snapshot.state != TaskState.success) {
        throw Exception('Upload başarısız oldu. Durum: ${snapshot.state}');
      }
      
      if (mounted) {
        setState(() {
          _uploadProgress = 1.0;
        });
      }
      
      // Public URL oluştur (daha güvenilir, süresi dolmaz)
      final bucket = snapshot.ref.storage.app.options.storageBucket;
      final publicUrl = 'https://storage.googleapis.com/$bucket/${snapshot.ref.fullPath}';
      
      debugPrint('🔗 Public URL oluşturuldu: $publicUrl');
      
      // Alternatif olarak download URL de al (fallback için)
      try {
        final downloadUrl = await snapshot.ref.getDownloadURL().timeout(
          const Duration(seconds: 10),
        );
        debugPrint('✅ Download URL de alındı (fallback): $downloadUrl');
        // Public URL'yi tercih et, ama download URL de çalışıyorsa onu kullan
        return publicUrl;
      } catch (e) {
        debugPrint('⚠️ Download URL alınamadı, public URL kullanılıyor: $e');
        return publicUrl;
      }
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
  */ // Yorum bloğu kapatıldı

  // Mobile cropped image upload - Kaldırıldı
  /* Kaldırıldı - Firebase Storage artık kullanılmıyor
  Future<String> _uploadMobileCroppedImage(Uint8List imageBytes, String productId) async {
    debugPrint('📤 Mobile kırpılmış resim yükleme başlatılıyor...');
    debugPrint('Resim boyutu: ${imageBytes.length} bytes');

    final storage = FirebaseStorage.instance;
    debugPrint('Storage bucket: ${storage.app.options.storageBucket}');

    final fileName = 'product_images/$productId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    debugPrint('Dosya yolu: $fileName');

    final ref = storage.ref().child(fileName);
    debugPrint('Reference oluşturuldu: ${ref.fullPath}');

    debugPrint('Upload task başlatılıyor...');
    final uploadTask = ref.putData(
      imageBytes,
      SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000', // 1 yıl cache
        customMetadata: {
          'public': 'true', // Public erişim için işaret
        },
      ),
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

        debugPrint('📊 Upload snapshot: state=${snapshot.state}, bytesTransferred=${snapshot.bytesTransferred}, totalBytes=${snapshot.totalBytes}');

        // State kontrolü öncelikli
        if (snapshot.state == TaskState.success) {
          debugPrint('✅ Upload başarıyla tamamlandı');
          if (mounted) {
            setState(() {
              _uploadProgress = 1.0;
            });
          }
          return;
        } else if (snapshot.state == TaskState.error) {
          debugPrint('❌ Upload hatası: ${snapshot.state}');
          if (mounted) {
            setState(() {
              _uploadProgress = 0.0;
              _isUploading = false;
            });
            _showError('Yükleme hatası: Upload başarısız oldu');
          }
          return;
        } else if (snapshot.state == TaskState.canceled) {
          debugPrint('⚠️ Upload iptal edildi');
          if (mounted) {
            setState(() {
              _uploadProgress = 0.0;
              _isUploading = false;
            });
          }
          return;
        }

        // Progress hesaplama - totalBytes kontrolü
        if (snapshot.totalBytes > 0) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          // Gerçek progress'i göster, minimum %5, maksimum %95
          final clampedProgress = progress.clamp(0.05, 0.95);
          debugPrint('📈 Progress: ${(clampedProgress * 100).toStringAsFixed(1)}% (${snapshot.bytesTransferred}/${snapshot.totalBytes} bytes)');
          if (mounted) {
            setState(() {
              _uploadProgress = clampedProgress;
            });
          }
        } else if (snapshot.state == TaskState.running) {
          // Upload başladı ama totalBytes henüz bilinmiyor
          // Yavaş yavaş artır ama gerçek progress gelene kadar çok yüksek çıkarma
          if (mounted && _uploadProgress < 0.2) {
            setState(() {
              _uploadProgress = (_uploadProgress + 0.02).clamp(0.05, 0.2);
            });
          }
        } else if (snapshot.bytesTransferred > 0) {
          // Bytes transfer ediliyor ama totalBytes bilinmiyor
          if (mounted && _uploadProgress < 0.15) {
            setState(() {
              _uploadProgress = 0.1;
            });
          }
        }
      },
      onError: (error) {
        debugPrint('❌ Progress listener hatası: $error');
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
      // Upload task'ın başladığını kontrol et
      debugPrint('⏳ Upload task durumu kontrol ediliyor...');

    // Daha uzun süre bekle ve task durumunu kontrol et (2 saniye)
    await Future.delayed(const Duration(seconds: 2));
    final initialSnapshot = uploadTask.snapshot;
    debugPrint('📊 İlk snapshot durumu: state=${initialSnapshot.state}, bytesTransferred=${initialSnapshot.bytesTransferred}, totalBytes=${initialSnapshot.totalBytes}');

    // Eğer hala running durumda ama hiç byte transfer edilmediyse, uyarı ver
    if (initialSnapshot.state == TaskState.running && initialSnapshot.bytesTransferred == 0) {
      debugPrint('⚠️ Upload başladı ama henüz veri transfer edilmedi. Ağ bağlantısını kontrol edin.');
      debugPrint('   - Total bytes: ${initialSnapshot.totalBytes}');
      debugPrint('   - Firebase Storage bucket: ${storage.app.options.storageBucket}');
    }

      if (initialSnapshot.state == TaskState.error) {
        throw Exception('Upload başlatılamadı. Lütfen Firebase Storage ayarlarını kontrol edin.');
      }

      // Firebase Storage bucket kontrolü
      debugPrint('🔍 Firebase Storage bucket kontrolü...');
      try {
        // Bucket erişimi test et
        final testRef = storage.ref('test-connection.txt');
        await testRef.putString('test', metadata: SettableMetadata(contentType: 'text/plain'));
        await testRef.delete();
        debugPrint('✅ Firebase Storage bucket aktif ve erişilebilir');
      } catch (e) {
        debugPrint('❌ Firebase Storage bucket sorunu: $e');
        if (e.toString().contains('storage/unauthorized') || e.toString().contains('permission-denied')) {
          throw Exception('Firebase Storage erişim izni yok. Firebase Console\'dan Storage\'u aktifleştirin ve CORS ayarlarını yapın.');
        } else if (e.toString().contains('storage/invalid-argument')) {
          throw Exception('Firebase Storage bucket yapılandırılmamış. Firebase Console\'dan Storage\'u aktifleştirin.');
        } else {
          debugPrint('⚠️ Storage bağlantı testi başarısız, devam ediliyor: $e');
        }
      }

      // Timeout ile beklemek (10 dakika - daha uzun süre ver)
      debugPrint('⏳ Upload tamamlanması bekleniyor...');
      final snapshot = await uploadTask.timeout(
        const Duration(minutes: 10),
        onTimeout: () {
          debugPrint('❌ Upload zaman aşımına uğradı (10 dakika)');
          debugPrint('   - Son snapshot kontrolü...');
          final finalSnapshot = uploadTask.snapshot;
          debugPrint('   - Final state: ${finalSnapshot.state}');
          debugPrint('   - Final bytes: ${finalSnapshot.bytesTransferred}/${finalSnapshot.totalBytes}');
          uploadTask.cancel();
          throw Exception('Yükleme zaman aşımına uğradı. Ağ bağlantınızı kontrol edin ve tekrar deneyin.');
        },
      );

      debugPrint('✅ Upload tamamlandı, durum: ${snapshot.state}');

      await _uploadProgressSubscription?.cancel();
      _uploadProgressSubscription = null;

      if (snapshot.state != TaskState.success) {
        throw Exception('Upload başarısız oldu. Durum: ${snapshot.state}');
      }

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

      debugPrint('❌ FirebaseException: ${e.code} - ${e.message}');

      String errorMessage = 'Yükleme hatası: ';
      if (e.code == 'storage/retry-limit-exceeded') {
        errorMessage = 'Yükleme çok uzun sürdü. Lütfen daha küçük bir resim seçin veya internet bağlantınızı kontrol edin.';
      } else if (e.code == 'storage/unauthorized') {
        errorMessage = 'Yükleme izni yok. Lütfen giriş yapın.';
      } else if (e.code == 'storage/canceled') {
        errorMessage = 'Yükleme iptal edildi.';
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
  */ // Son yorum bloğu kapatıldı

  // Kullanılmıyor - Firebase Storage yerine Base64 kullanılıyor
  // ignore: unused_element
  /* Kaldırıldı - Firebase Storage artık kullanılmıyor
  Future<File> _saveCroppedBytesToFile(Uint8List bytes) async {
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(bytes);
    return tempFile;
  }
  */

  @override
  void dispose() {
    // Firebase Storage kaldırıldı - artık kullanılmıyor
    // _uploadProgressSubscription?.cancel();
    super.dispose();
  }

  void _removeImage() {
    // Firebase Storage kaldırıldı - artık kullanılmıyor
    // _uploadProgressSubscription?.cancel();
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
  Uint8List? _cachedImageBytes; // Cache resim bytes
  int _lastUpdateFrame = 0; // Frame-based throttle
  double _displayWidth = 0.0;
  double _displayHeight = 0.0;
  double _scaleX = 1.0;
  double _scaleY = 1.0;
  double? _cachedDisplayCropX;
  double? _cachedDisplayCropY;
  double? _cachedDisplayCropWidth;
  double? _cachedDisplayCropHeight;

  @override
  void initState() {
    super.initState();
    _imageWidth = widget.originalImage.width.toDouble();
    _imageHeight = widget.originalImage.height.toDouble();
    
    // Calculate initial crop size - resmin tamamını kapsayacak şekilde
    // Aspect ratio'ya göre en büyük alanı seç
    if (widget.aspectRatio >= 1.0) {
      // Yatay veya kare
      _cropWidth = _imageWidth * 0.98; // Neredeyse tam genişlik
      _cropHeight = _cropWidth / widget.aspectRatio;
      if (_cropHeight > _imageHeight * 0.98) {
        _cropHeight = _imageHeight * 0.98;
        _cropWidth = _cropHeight * widget.aspectRatio;
      }
    } else {
      // Dikey
      _cropHeight = _imageHeight * 0.98; // Neredeyse tam yükseklik
      _cropWidth = _cropHeight * widget.aspectRatio;
      if (_cropWidth > _imageWidth * 0.98) {
        _cropWidth = _imageWidth * 0.98;
        _cropHeight = _cropWidth / widget.aspectRatio;
      }
    }
    _cropX = (_imageWidth - _cropWidth) / 2;
    _cropY = (_imageHeight - _cropHeight) / 2;
    
    // Resmi cache'le (performans için)
    _cachedImageBytes = Uint8List.fromList(img.encodeJpg(widget.originalImage));
  }

  @override
  Widget build(BuildContext context) {
    // Cache'lenmiş resmi kullan (performans için)
    final imageBytes = _cachedImageBytes ?? Uint8List.fromList(img.encodeJpg(widget.originalImage));
    
    // Ekran boyutunu al
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = (screenSize.width * 0.9).clamp(800.0, 1200.0);
    final dialogHeight = (screenSize.height * 0.85).clamp(700.0, 1000.0);
    
    return Dialog(
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        padding: const EdgeInsets.all(20),
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
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Resim boyutlarını hesapla - tam sığacak şekilde
                    final imageAspectRatio = _imageWidth / _imageHeight;
                    final containerAspectRatio = constraints.maxWidth / constraints.maxHeight;
                    
                    double displayWidth, displayHeight;
                    if (imageAspectRatio > containerAspectRatio) {
                      displayWidth = constraints.maxWidth * 0.98; // %98 padding
                      displayHeight = displayWidth / imageAspectRatio;
                    } else {
                      displayHeight = constraints.maxHeight * 0.98;
                      displayWidth = displayHeight * imageAspectRatio;
                    }
                    
                    // Scale hesapla
                    final scaleX = displayWidth / _imageWidth;
                    final scaleY = displayHeight / _imageHeight;
                    
                    // State'i güncelle
                    if (_displayWidth != displayWidth || _displayHeight != displayHeight) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _displayWidth = displayWidth;
                            _displayHeight = displayHeight;
                            _scaleX = scaleX;
                            _scaleY = scaleY;
                            _cachedDisplayCropX = null; // Cache'i temizle
                          });
                        }
                      });
                    } else {
                      _displayWidth = displayWidth;
                      _displayHeight = displayHeight;
                      _scaleX = scaleX;
                      _scaleY = scaleY;
                    }
                    
                    return RepaintBoundary(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Resim - tam boyutta göster
                          Positioned(
                            left: (constraints.maxWidth - displayWidth) / 2,
                            top: (constraints.maxHeight - displayHeight) / 2,
                            child: RepaintBoundary(
                              child: Image.memory(
                                imageBytes,
                                width: displayWidth,
                                height: displayHeight,
                                fit: BoxFit.fill, // Tam sığdır
                                gaplessPlayback: true,
                                filterQuality: FilterQuality.medium, // Orta kalite (görünürlük için)
                                isAntiAlias: true, // Anti-aliasing açık (daha iyi görünüm)
                              ),
                            ),
                          ),
                          // Kırpma overlay
                          if (_displayWidth > 0 && _displayHeight > 0)
                            _buildCropOverlay(constraints),
                        ],
                      ),
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
    // Cache'lenmiş değerleri kullan (performans için)
    if (_cachedDisplayCropX == null) {
      _cachedDisplayCropX = _cropX * _scaleX;
      _cachedDisplayCropY = _cropY * _scaleY;
      _cachedDisplayCropWidth = _cropWidth * _scaleX;
      _cachedDisplayCropHeight = _cropHeight * _scaleY;
    }
    
    final displayCropX = _cachedDisplayCropX!;
    final displayCropY = _cachedDisplayCropY!;
    final displayCropWidth = _cachedDisplayCropWidth!;
    final displayCropHeight = _cachedDisplayCropHeight!;
    
    final imageLeft = (constraints.maxWidth - _displayWidth) / 2;
    final imageTop = (constraints.maxHeight - _displayHeight) / 2;
    final absoluteCropX = imageLeft + displayCropX;
    final absoluteCropY = imageTop + displayCropY;
    
    return Stack(
      children: [
        // Overlay mask - tüm ekranı kapla ama tıklamaları engelleme
        _buildOverlayMask(constraints, absoluteCropX, absoluteCropY, displayCropWidth, displayCropHeight),
        // Kırpma kutusu ve handle'lar - tıklanabilir
        Positioned(
          left: absoluteCropX,
          top: absoluteCropY,
          child: GestureDetector(
            onPanUpdate: (details) {
              // Minimum throttle - 8ms (120 FPS teorik, pratikte 60+ FPS)
              final now = DateTime.now().millisecondsSinceEpoch;
              if (now - _lastUpdateFrame < 8) {
                // Hızlı güncelleme - değişkenleri güncelle ama setState'i atla
                _cropX = (_cropX + details.delta.dx / _scaleX).clamp(0.0, _imageWidth - _cropWidth);
                _cropY = (_cropY + details.delta.dy / _scaleY).clamp(0.0, _imageHeight - _cropHeight);
                _cachedDisplayCropX = null; // Cache'i temizle
                return;
              }
              _lastUpdateFrame = now;
              
              // setState ile güncelle
              final newCropX = (_cropX + details.delta.dx / _scaleX).clamp(0.0, _imageWidth - _cropWidth);
              final newCropY = (_cropY + details.delta.dy / _scaleY).clamp(0.0, _imageHeight - _cropHeight);
              
              if (newCropX != _cropX || newCropY != _cropY) {
                _cropX = newCropX;
                _cropY = newCropY;
                _cachedDisplayCropX = null; // Cache'i temizle
                setState(() {}); // Minimal setState
              }
            },
            child: RepaintBoundary(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Kırpma kutusu border
                  Container(
                    width: displayCropWidth,
                    height: displayCropHeight,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.blue[700]!,
                        width: 2.5,
                      ),
                      color: Colors.transparent,
                    ),
                  ),
                  // Corner handles
                  ..._buildCornerHandles(0, 0, displayCropWidth, displayCropHeight),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverlayMask(BoxConstraints constraints, double absoluteCropX, double absoluteCropY, double cropWidth, double cropHeight) {
    return IgnorePointer(
      ignoring: true, // Overlay mask tıklamaları engellemez, sadece görsel
      child: Stack(
        children: [
          // Üst overlay
          if (absoluteCropY > 0)
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              height: absoluteCropY,
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
          // Alt overlay
          if (absoluteCropY + cropHeight < constraints.maxHeight)
            Positioned(
              left: 0,
              top: absoluteCropY + cropHeight,
              right: 0,
              bottom: 0,
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
          // Sol overlay
          if (absoluteCropX > 0)
            Positioned(
              left: 0,
              top: absoluteCropY,
              width: absoluteCropX,
              height: cropHeight,
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
          // Sağ overlay
          if (absoluteCropX + cropWidth < constraints.maxWidth)
            Positioned(
              left: absoluteCropX + cropWidth,
              top: absoluteCropY,
              right: 0,
              height: cropHeight,
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildCornerHandles(double cropX, double cropY, double cropWidth, double cropHeight) {
    return [
      // Top-left
      Positioned(
        left: cropX - 10,
        top: cropY - 10,
        child: GestureDetector(
          onPanUpdate: (details) {
            final now = DateTime.now().millisecondsSinceEpoch;
            if (now - _lastUpdateFrame < 8) {
              // Hızlı güncelleme
              final deltaX = details.delta.dx / _scaleX;
              final deltaY = details.delta.dy / _scaleY;
              _cropX = (_cropX + deltaX).clamp(0.0, _imageWidth - _cropWidth);
              _cropY = (_cropY + deltaY).clamp(0.0, _imageHeight - _cropHeight);
              _cropWidth = (_cropWidth - deltaX).clamp(50.0, _imageWidth - _cropX);
              _cropHeight = (_cropHeight - deltaY).clamp(50.0, _imageHeight - _cropY);
              _cachedDisplayCropX = null;
              return;
            }
            _lastUpdateFrame = now;
            
            final deltaX = details.delta.dx / _scaleX;
            final deltaY = details.delta.dy / _scaleY;
            _cropX = (_cropX + deltaX).clamp(0.0, _imageWidth - _cropWidth);
            _cropY = (_cropY + deltaY).clamp(0.0, _imageHeight - _cropHeight);
            _cropWidth = (_cropWidth - deltaX).clamp(50.0, _imageWidth - _cropX);
            _cropHeight = (_cropHeight - deltaY).clamp(50.0, _imageHeight - _cropY);
            _cachedDisplayCropX = null;
            setState(() {});
          },
          child: _buildHandle(),
        ),
      ),
      // Top-right
      Positioned(
        left: cropX + cropWidth - 10,
        top: cropY - 10,
        child: GestureDetector(
          onPanUpdate: (details) {
            final now = DateTime.now().millisecondsSinceEpoch;
            if (now - _lastUpdateFrame < 8) {
              final deltaX = details.delta.dx / _scaleX;
              final deltaY = details.delta.dy / _scaleY;
              _cropY = (_cropY + deltaY).clamp(0.0, _imageHeight - _cropHeight);
              _cropWidth = (_cropWidth + deltaX).clamp(50.0, _imageWidth - _cropX);
              _cropHeight = (_cropHeight - deltaY).clamp(50.0, _imageHeight - _cropY);
              _cachedDisplayCropX = null;
              return;
            }
            _lastUpdateFrame = now;
            
            final deltaX = details.delta.dx / _scaleX;
            final deltaY = details.delta.dy / _scaleY;
            _cropY = (_cropY + deltaY).clamp(0.0, _imageHeight - _cropHeight);
            _cropWidth = (_cropWidth + deltaX).clamp(50.0, _imageWidth - _cropX);
            _cropHeight = (_cropHeight - deltaY).clamp(50.0, _imageHeight - _cropY);
            _cachedDisplayCropX = null;
            setState(() {});
          },
          child: _buildHandle(),
        ),
      ),
      // Bottom-left
      Positioned(
        left: cropX - 10,
        top: cropY + cropHeight - 10,
        child: GestureDetector(
          onPanUpdate: (details) {
            final now = DateTime.now().millisecondsSinceEpoch;
            if (now - _lastUpdateFrame < 8) {
              final deltaX = details.delta.dx / _scaleX;
              final deltaY = details.delta.dy / _scaleY;
              _cropX = (_cropX + deltaX).clamp(0.0, _imageWidth - _cropWidth);
              _cropWidth = (_cropWidth - deltaX).clamp(50.0, _imageWidth - _cropX);
              _cropHeight = (_cropHeight + deltaY).clamp(50.0, _imageHeight - _cropY);
              _cachedDisplayCropX = null;
              return;
            }
            _lastUpdateFrame = now;
            
            final deltaX = details.delta.dx / _scaleX;
            final deltaY = details.delta.dy / _scaleY;
            _cropX = (_cropX + deltaX).clamp(0.0, _imageWidth - _cropWidth);
            _cropWidth = (_cropWidth - deltaX).clamp(50.0, _imageWidth - _cropX);
            _cropHeight = (_cropHeight + deltaY).clamp(50.0, _imageHeight - _cropY);
            _cachedDisplayCropX = null;
            setState(() {});
          },
          child: _buildHandle(),
        ),
      ),
      // Bottom-right
      Positioned(
        left: cropX + cropWidth - 10,
        top: cropY + cropHeight - 10,
        child: GestureDetector(
          onPanUpdate: (details) {
            final now = DateTime.now().millisecondsSinceEpoch;
            if (now - _lastUpdateFrame < 8) {
              final deltaX = details.delta.dx / _scaleX;
              final deltaY = details.delta.dy / _scaleY;
              _cropWidth = (_cropWidth + deltaX).clamp(50.0, _imageWidth - _cropX);
              _cropHeight = (_cropHeight + deltaY).clamp(50.0, _imageHeight - _cropY);
              _cachedDisplayCropX = null;
              return;
            }
            _lastUpdateFrame = now;
            
            final deltaX = details.delta.dx / _scaleX;
            final deltaY = details.delta.dy / _scaleY;
            _cropWidth = (_cropWidth + deltaX).clamp(50.0, _imageWidth - _cropX);
            _cropHeight = (_cropHeight + deltaY).clamp(50.0, _imageHeight - _cropY);
            _cachedDisplayCropX = null;
            setState(() {});
          },
          child: _buildHandle(),
        ),
      ),
    ];
  }

  Widget _buildHandle() {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue[700]!, width: 2.5),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
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

// Isolate fonksiyonları - Mobile için (UI thread'i bloklamaz)
// Web'de compute çalışmaz, bu fonksiyonlar sadece mobile'da kullanılır
// Şu an kullanılmıyor (Base64 yöntemi basitleştirildi) ama ileride gerekebilir
// ignore: unused_element
img.Image _decodeImageIsolate(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw Exception('Resim decode edilemedi');
  }
  return decoded;
}

// ignore: unused_element
img.Image _resizeImageIsolate(Map<String, dynamic> params) {
  final image = params['image'] as img.Image;
  final width = params['width'] as int;
  final height = params['height'] as int;
  return img.copyResize(
    image,
    width: width,
    height: height,
    interpolation: img.Interpolation.linear,
  );
}

// ignore: unused_element
Uint8List _encodeImageIsolate(Map<String, dynamic> params) {
  final image = params['image'] as img.Image;
  final quality = params['quality'] as int;
  return Uint8List.fromList(img.encodeJpg(image, quality: quality));
}


