import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerScreen extends StatefulWidget {
  final String url;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  bool _isLoading = true;

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), // Minimalist light gray background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        actions: [
          // Zoom actions
          IconButton(
            icon: const Icon(Icons.zoom_out, color: Colors.black54),
            onPressed: () {
              if (_pdfViewerController.zoomLevel > 0.33) {
                _pdfViewerController.zoomLevel = _pdfViewerController.zoomLevel - 0.25;
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in, color: Colors.black54),
            onPressed: () {
              _pdfViewerController.zoomLevel = _pdfViewerController.zoomLevel + 0.25;
            },
          ),
          // Quick navigation actions
          IconButton(
            icon: const Icon(Icons.navigate_before, color: Colors.black54),
            onPressed: () => _pdfViewerController.previousPage(),
          ),
          IconButton(
            icon: const Icon(Icons.navigate_next, color: Colors.black54),
            onPressed: () => _pdfViewerController.nextPage(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Core Interactive Document Canvas Renderer
          SfPdfViewer.network(
            widget.url.trim(),
            controller: _pdfViewerController,
            canShowScrollHead: true,
            canShowScrollStatus: true,
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              setState(() {
                _isLoading = false;
              });
            },
            onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
              setState(() {
                _isLoading = false;
              });
              // Graceful error display if Cloudinary link breaks
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to load document: ${details.description}'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
          ),

          // Modern, clean loading indicator overlay overlay
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                strokeWidth: 2,
              ),
            ),
        ],
      ),
    );
  }
}