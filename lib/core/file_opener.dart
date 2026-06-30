import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

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
}
