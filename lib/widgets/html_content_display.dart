import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:webview_flutter/webview_flutter.dart';
// Import for Android-specific features
import 'package:webview_flutter_android/webview_flutter_android.dart';
// Import for iOS-specific features
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class HtmlContentDisplay extends StatefulWidget {
  final String content;
  final String? imageBasePath;
  final double defaultHeight;
  final Color? textColor;
  final double fontSize;

  const HtmlContentDisplay({
    super.key,
    required this.content,
    this.imageBasePath,
    this.defaultHeight = 40,
    this.textColor,
    this.fontSize = 16.0,
  });

  @override
  State<HtmlContentDisplay> createState() => _HtmlContentDisplayState();
}

class _HtmlContentDisplayState extends State<HtmlContentDisplay> {
  late final WebViewController _controller;
  double _height = 1;
  bool _isLoading = true;
  String? _loadedContent;
  String? _tempFilePath;

  @override
  void initState() {
    super.initState();
    _height = widget.defaultHeight;

    // Platform-specific initialization
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000)) // Transparent background
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            _updateHeight();
            // Add a small delay to ensure rendering is complete
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..addJavaScriptChannel(
        'HeightHandler',
        onMessageReceived: (JavaScriptMessage message) {
          final double? newHeight = double.tryParse(message.message);
          if (newHeight != null && (newHeight - _height).abs() > 1) {
            setState(() {
              _height = newHeight;
            });
          }
        },
      )
      ..addJavaScriptChannel(
        'ConsoleHandler',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint('WebView Console: ${message.message}');
        },
      );

    // Android-specific configuration for local file access
    if (controller.platform is AndroidWebViewController) {
      // Enable debugging for development builds
      AndroidWebViewController.enableDebugging(true);
      
      final androidController = controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = controller;
    _loadContent();
  }

  @override
  void didUpdateWidget(HtmlContentDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content ||
        oldWidget.imageBasePath != widget.imageBasePath ||
        oldWidget.textColor != widget.textColor ||
        oldWidget.fontSize != widget.fontSize) {
      _loadContent();
    }
  }

  @override
  void dispose() {
    _deleteTempFile();
    super.dispose();
  }

  Future<void> _deleteTempFile() async {
    if (_tempFilePath != null) {
      try {
        final file = File(_tempFilePath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
  }

  Future<void> _loadContent() async {
    if (_loadedContent == widget.content) return;
    
    // Start loading state for fade-in effect
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final html = _buildHtml(widget.content);
    _loadedContent = widget.content;

    try {
      if (widget.imageBasePath != null) {
        // Method 1: Write to file in the package directory (if possible) to allow relative paths
        // We use a unique name to prevent collisions
        final fileName = 'view_${DateTime.now().microsecondsSinceEpoch}.html';
        final filePath = p.join(widget.imageBasePath!, fileName);
        
        final file = File(filePath);
        await file.writeAsString(html);
        _tempFilePath = filePath; // Save for cleanup
        
        // Load the file using file:// URI
        // Using loadFile() is robust against ERR_ACCESS_DENIED for local content
        // as it establishes the origin correctly.
        await _controller.loadFile(filePath);
      } else {
        // Fallback: use loadHtmlString if no base path
        await _controller.loadHtmlString(html);
      }
    } catch (e) {
      debugPrint('Error loading content: $e');
      // Fallback
      _controller.loadHtmlString(html);
    }
  }

  Future<void> _updateHeight() async {
    try {
      final Object? result = await _controller.runJavaScriptReturningResult(
          'document.body.scrollHeight');
      if (result is num) {
        setState(() {
          _height = result.toDouble();
        });
      } else if (result is String) {
        final double? val = double.tryParse(result);
        if (val != null) {
          setState(() {
            _height = val;
          });
        }
      }
    } catch (e) {
      // debugPrint('Error getting height: $e');
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2)}';
  }

  String _buildHtml(String content) {
    final textColorHex = widget.textColor != null 
        ? _colorToHex(widget.textColor!) 
        : 'inherit';
    
    final fontSizePx = '${widget.fontSize.toInt()}px';

    const css = '''
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
          margin: 0;
          padding: 0;
          background-color: transparent !important;
          overflow: hidden;
          width: 100vw;
          word-wrap: break-word;
        }
        img {
          max-width: 100%;
          height: auto;
          display: block;
          margin: 4px 0;
        }
        p {
          margin: 0 0 8px 0;
        }
        /* MathML styling */
        math {
          font-family: "Latin Modern Math", "Cambria Math", serif;
        }
      </style>
    ''';

    // Script to notify height changes
    const js = '''
      <script>
        function sendHeight() {
          if (window.HeightHandler) {
            // Add a small buffer to prevent cutting off descenders
            var height = document.body.scrollHeight + 2;
            window.HeightHandler.postMessage(height.toString());
          }
        }
        
        function log(msg) {
          if (window.ConsoleHandler) {
            window.ConsoleHandler.postMessage(msg);
          }
        }
        
        // Listen for image loads to update height
        document.addEventListener('load', function(event){
            if(event.target.tagName.toLowerCase() == 'img'){
                sendHeight();
            }
        }, true);
        
        // Capture image load errors
        document.addEventListener('error', function(event){
            if(event.target.tagName.toLowerCase() == 'img'){
                log('Image failed to load: ' + event.target.src);
            }
        }, true);

        window.addEventListener('load', sendHeight);
        window.addEventListener('resize', sendHeight);
        
        const observer = new MutationObserver(sendHeight);
        observer.observe(document.body, { attributes: true, childList: true, subtree: true });
        
        // Periodic check for mathjax or other dynamic content
        setTimeout(sendHeight, 100);
        setTimeout(sendHeight, 500);
        setTimeout(sendHeight, 1000);
      </script>
    ''';

    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        $css
        <style>
          body {
            color: $textColorHex;
            font-size: $fontSizePx;
          }
        </style>
      </head>
      <body>
        $content
        $js
      </body>
      </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: AnimatedOpacity(
        opacity: _isLoading ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: WebViewWidget(
          controller: _controller,
        ),
      ),
    );
  }
}