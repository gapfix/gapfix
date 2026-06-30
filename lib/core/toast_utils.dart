import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ToastUtils {
  static void show(BuildContext context, String message, {bool isError = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError 
            ? Colors.redAccent 
            : (isDark ? const Color(0xFF323232) : const Color(0xFF1A1C1B)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: isIOS 
          ? EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height - 160,
              left: 20,
              right: 20,
            )
          : const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
        elevation: 8,
      ),
    );
  }

  static void showNotification(BuildContext context, String title, String message) {
    // Top-aligned floating snackbar to mimic a notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            Text(message, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 120,
          left: 16,
          right: 16,
        ),
        dismissDirection: DismissDirection.up,
        backgroundColor: Theme.of(context).primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
