import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Performans optimizasyonlu image widget'ı
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool useCache;
  final int? maxWidth;
  final int? maxHeight;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.useCache = true,
    this.maxWidth,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return _buildImage();
  }

  Widget _buildImage() {
    final trimmedUrl = imageUrl.trim();

    if (trimmedUrl.isEmpty) {
      return _buildErrorWidget();
    }

    // Asset image kontrolü
    if (trimmedUrl.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Image.asset(
          trimmedUrl,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorWidget();
          },
        ),
      );
    }

    // HTTP/HTTPS URL kontrolü (Firebase Storage URL'leri dahil)
    if (trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://')) {
      // Firebase Storage URL'leri için resize parametresi ekle
      String optimizedUrl = trimmedUrl;
      if ((maxWidth != null || maxHeight != null) && 
          trimmedUrl.contains('firebasestorage.googleapis.com')) {
        final uri = Uri.parse(trimmedUrl);
        final queryParams = Map<String, String>.from(uri.queryParameters);
        
        if (maxWidth != null) queryParams['w'] = maxWidth.toString();
        if (maxHeight != null) queryParams['h'] = maxHeight.toString();
        queryParams['q'] = '80'; // Quality
        
        optimizedUrl = uri.replace(queryParameters: queryParams).toString();
      }
      
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: useCache
            ? CachedNetworkImage(
                imageUrl: optimizedUrl,
                width: width,
                height: height,
                fit: fit,
                // Memoization için key
                cacheKey: trimmedUrl,
                // Fade in animasyonu
                fadeInDuration: const Duration(milliseconds: 200),
                fadeOutDuration: const Duration(milliseconds: 100),
                // Placeholder
                placeholder: (context, url) {
                  return placeholder ??
                      Container(
                        width: width,
                        height: height,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                },
                // Error widget
                errorWidget: (context, url, error) {
                  debugPrint('Image load error for URL: $url, Error: $error');
                  return errorWidget ?? _buildErrorWidget();
                },
                // Memory cache
                memCacheWidth: maxWidth,
                memCacheHeight: maxHeight,
              )
            : Image.network(
                optimizedUrl,
                width: width,
                height: height,
                fit: fit,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return placeholder ??
                      Container(
                        width: width,
                        height: height,
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                },
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Image load error: $error');
                  return errorWidget ?? _buildErrorWidget();
                },
              ),
      );
    }

    // Data URL (Base64) kontrolü
    if (trimmedUrl.startsWith('data:')) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Image.network(
          trimmedUrl,
          width: width,
          height: height,
          fit: fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return placeholder ??
                Container(
                  width: width,
                  height: height,
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Base64 image load error: $error');
            return errorWidget ?? _buildErrorWidget();
          },
        ),
      );
    }

    // Geçersiz format
    debugPrint('Invalid image URL format: $trimmedUrl');
    return _buildErrorWidget();
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height ?? 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: const Center(
        child: Icon(
          Icons.image_not_supported,
          size: 48,
          color: Colors.grey,
        ),
      ),
    );
  }
}
