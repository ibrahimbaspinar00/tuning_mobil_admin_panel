import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;

import '../config/external_image_storage_config.dart';

class ExternalImageUploadService {
  static bool get isConfigured =>
      ExternalImageStorageConfig.enabled &&
      ExternalImageStorageConfig.cloudinaryCloudName != 'YOUR_CLOUD_NAME' &&
      ExternalImageStorageConfig.cloudinaryUnsignedUploadPreset !=
          'YOUR_UPLOAD_PRESET';

  /// Uploads JPEG/PNG bytes to Cloudinary (unsigned) and returns the secure URL.
  static Future<String> uploadImageBytes({
    required Uint8List bytes,
    required String fileName,
    required String productId,
  }) async {
    if (!ExternalImageStorageConfig.enabled) {
      throw Exception(
        'External image uploads are disabled. Enable it in ExternalImageStorageConfig.',
      );
    }

    if (!isConfigured) {
      throw Exception(
        'Cloudinary is not configured.\n'
        'Set ExternalImageStorageConfig.cloudinaryCloudName and '
        'ExternalImageStorageConfig.cloudinaryUnsignedUploadPreset.',
      );
    }

    final cloudName = ExternalImageStorageConfig.cloudinaryCloudName;
    final preset = ExternalImageStorageConfig.cloudinaryUnsignedUploadPreset;
    final folder = ExternalImageStorageConfig.cloudinaryFolder;

    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final req = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = preset
      ..fields['folder'] = folder
      // public_id is optional; using it can overwrite if same id is reused.
      ..fields['public_id'] = '${productId}_${DateTime.now().millisecondsSinceEpoch}'
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        ),
      );

    debugPrint('☁️ Uploading image to Cloudinary: $fileName (${bytes.length} bytes)');

    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      debugPrint('❌ Cloudinary upload failed: ${streamed.statusCode} $body');
      throw Exception('Image upload failed (${streamed.statusCode}).');
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    final secureUrl = (json['secure_url'] as String?) ?? '';

    if (secureUrl.isEmpty) {
      throw Exception('Cloudinary upload succeeded but secure_url is missing.');
    }

    return secureUrl;
  }
}


