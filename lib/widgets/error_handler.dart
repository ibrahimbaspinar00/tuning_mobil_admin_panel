import 'package:flutter/material.dart';

class ErrorHandler {
  static String? _lastMessage;
  static DateTime? _lastMessageTime;
  static const Duration _cooldownDuration = Duration(seconds: 2);

  // Aynı mesajın tekrarını önle
  static bool _shouldShowMessage(String message) {
    final now = DateTime.now();
    
    if (_lastMessage == message && 
        _lastMessageTime != null && 
        now.difference(_lastMessageTime!) < _cooldownDuration) {
      return false;
    }
    
    return true;
  }

  // Akıllı hata mesajı
  static void showError(BuildContext context, String message) {
    try {
      if (!context.mounted) return;
      
      if (_shouldShowMessage(message)) {
        _lastMessage = message;
        _lastMessageTime = DateTime.now();
        
        _showSnackBar(
          context: context,
          message: message,
          backgroundColor: Colors.red[600]!,
          icon: Icons.error,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      debugPrint('Error in showError: $e');
    }
  }

  // Akıllı başarı mesajı
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    
    if (_shouldShowMessage(message)) {
      _lastMessage = message;
      _lastMessageTime = DateTime.now();
      
      _showSnackBar(
        context: context,
        message: message,
        backgroundColor: Colors.green[600]!,
        icon: Icons.check_circle,
        duration: const Duration(seconds: 2),
      );
    }
  }

  // Akıllı bilgi mesajı
  static void showInfo(BuildContext context, String message) {
    if (!context.mounted) return;
    
    if (_shouldShowMessage(message)) {
      _lastMessage = message;
      _lastMessageTime = DateTime.now();
      
      _showSnackBar(
        context: context,
        message: message,
        backgroundColor: Colors.blue[600]!,
        icon: Icons.info,
        duration: const Duration(seconds: 2),
      );
    }
  }

  // Sessiz başarı (sadece görsel feedback)
  static void showSilentSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    
    // Sadece kısa bir animasyon göster
    _showQuickFeedback(context, message, Colors.green, Icons.check);
  }

  // Sepet için özel bildirim
  static void showCartSuccess(BuildContext context, String message, {VoidCallback? onViewCart}) {
    if (!context.mounted) return;
    
    if (_shouldShowMessage(message)) {
      _lastMessage = message;
      _lastMessageTime = DateTime.now();
      
      _showSnackBar(
        context: context,
        message: message,
        backgroundColor: Colors.green[600]!,
        icon: Icons.shopping_cart,
        duration: const Duration(seconds: 2),
        actionLabel: 'Görüntüle',
        onActionPressed: onViewCart,
      );
    }
  }

  // Sessiz bilgi
  static void showSilentInfo(BuildContext context, String message) {
    if (!context.mounted) return;
    
    _showQuickFeedback(context, message, Colors.blue, Icons.info);
  }

  // Hızlı görsel feedback
  static void _showQuickFeedback(BuildContext context, String message, Color color, IconData icon) {
    if (!context.mounted) return;
    
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 60,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity( 0.9),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity( 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    overlay.insert(overlayEntry);
    
    // 1.5 saniye sonra kaldır
    Future.delayed(const Duration(milliseconds: 1500), () {
      overlayEntry.remove();
    });
  }

  // Ana SnackBar gösterici
  static void _showSnackBar({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required IconData icon,
    required Duration duration,
    String actionLabel = 'Tamam',
    VoidCallback? onActionPressed,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: duration,
        action: SnackBarAction(
          label: actionLabel,
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            onActionPressed?.call();
          },
        ),
      ),
    );
  }

  // Tüm mesajları temizle
  static void clear() {
    _lastMessage = null;
    _lastMessageTime = null;
  }
}
