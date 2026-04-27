import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:webview_flutter/webview_flutter.dart';

class DocumentPreviewScreen extends StatefulWidget {
  final String url;
  final String title;
  final bool isImage;

  const DocumentPreviewScreen({
    super.key,
    required this.url,
    required this.title,
    required this.isImage,
  });

  static bool urlIsImage(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('.png') ||
        lower.contains('.webp');
  }

  @override
  State<DocumentPreviewScreen> createState() => _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends State<DocumentPreviewScreen> {
  late final WebViewController _webController;
  bool _isWebLoading = true;

  @override
  void initState() {
    super.initState();
    if (!widget.isImage) {
      final encoded = Uri.encodeComponent(widget.url);
      final viewerUrl =
          'https://docs.google.com/gviewer?embedded=true&url=$encoded';
      _webController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _isWebLoading = false);
          },
        ))
        ..loadRequest(Uri.parse(viewerUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isImage ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: widget.isImage ? Colors.black : null,
        foregroundColor: widget.isImage ? Colors.white : null,
        elevation: widget.isImage ? 0 : null,
        title: Text(
          widget.title,
          style: TextStyle(
            color: widget.isImage ? Colors.white : null,
          ),
        ),
      ),
      body: widget.isImage ? _buildImageViewer() : _buildPdfViewer(),
    );
  }

  Widget _buildImageViewer() {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 5.0,
      child: Center(
        child: CachedNetworkImage(
          imageUrl: widget.url,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          errorWidget: (context, url, error) => const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, color: Colors.white54, size: 64),
              SizedBox(height: 12),
              Text('Could not load image',
                  style: TextStyle(color: Colors.white54)),
            ],
          ),
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildPdfViewer() {
    return Stack(
      children: [
        WebViewWidget(controller: _webController),
        if (_isWebLoading)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
