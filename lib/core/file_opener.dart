import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Platform-aware file opener.
class FileOpener {
  static Future<void> openFile(BuildContext context, String url, {String? title}) async {
    final lowerUrl = url.toLowerCase();
    
    // If it's a PDF, open with our internal viewer
    if (lowerUrl.contains('.pdf')) {
      context.push('/pdf-viewer', extra: {
        'url': url,
        'title': title ?? 'PDF Viewer',
      });
      return;
    }

    // If it's an image, open with internal image viewer
    if (lowerUrl.contains('.jpg') || 
        lowerUrl.contains('.jpeg') || 
        lowerUrl.contains('.png') || 
        lowerUrl.contains('.webp') || 
        lowerUrl.contains('.gif')) {
      _showImageViewer(context, url, title ?? 'Image Viewer');
      return;
    }

    final uri = Uri.parse(url);
    if (kIsWeb) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } else {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open file.')),
          );
        }
      }
    }
  }

  static void _showImageViewer(BuildContext context, String url, String title) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withValues(alpha: 0.9),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30), 
              onPressed: () => Navigator.pop(context)
            ),
            title: Text(title, style: const TextStyle(color: Colors.white)),
          ),
          body: InteractiveViewer(
            clipBehavior: Clip.none,
            minScale: 0.5,
            maxScale: 10.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                placeholder: (context, url) => const CircularProgressIndicator.adaptive(),
                errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
              ),
            ),
          ),
        );
      },
    );
  }
}
