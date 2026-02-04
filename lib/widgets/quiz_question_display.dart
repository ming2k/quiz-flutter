import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class QuizQuestionDisplay extends StatefulWidget {
  final Question question;
  final String? selectedOption;
  final bool showAnswer;
  final bool showAnalysis;
  final String? imageBasePath;
  final void Function(String)? onOptionSelected;
  final Color primaryColor;
  final Color errorColor;
  final Color successColor;
  final Color surfaceColor;
  final Color textColor;

  const QuizQuestionDisplay({
    super.key,
    required this.question,
    this.selectedOption,
    this.showAnswer = false,
    this.showAnalysis = true,
    this.imageBasePath,
    this.onOptionSelected,
    required this.primaryColor,
    required this.errorColor,
    required this.successColor,
    required this.surfaceColor,
    required this.textColor,
  });

  @override
  State<QuizQuestionDisplay> createState() => _QuizQuestionDisplayState();
}

class _QuizQuestionDisplayState extends State<QuizQuestionDisplay> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _tempFilePath;
  // Track loaded question ID to avoid unnecessary reloads
  int? _loadedQuestionId;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
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
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            // Restore state after load
            _updateJsState();
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            });
          },
        ),
      )
      ..addJavaScriptChannel(
        'QuizHandler',
        onMessageReceived: (JavaScriptMessage message) {
          if (widget.onOptionSelected != null) {
            widget.onOptionSelected!(message.message);
          }
        },
      )
      ..addJavaScriptChannel(
        'ConsoleHandler',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint('WebView Console: ${message.message}');
        },
      );

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = controller;
    _loadContent();
  }

  @override
  void didUpdateWidget(QuizQuestionDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.question.id != widget.question.id ||
        oldWidget.imageBasePath != widget.imageBasePath) {
      // New question, full reload
      _loadContent();
    } else {
      // Same question, just update state (selection, answer)
      _updateJsState();
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
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    _loadedQuestionId = widget.question.id;
    final html = _buildHtml();

    try {
      if (widget.imageBasePath != null) {
        final fileName = 'q_${widget.question.id}_${DateTime.now().microsecondsSinceEpoch}.html';
        final filePath = p.join(widget.imageBasePath!, fileName);
        
        final file = File(filePath);
        await file.writeAsString(html);
        
        // Clean up old file
        _deleteTempFile();
        _tempFilePath = filePath;
        
        await _controller.loadFile(filePath);
      } else {
        await _controller.loadHtmlString(html);
      }
    } catch (e) {
      debugPrint('Error loading quiz content: $e');
      _controller.loadHtmlString(html);
    }
  }

  void _updateJsState() {
    final state = {
      'selectedOption': widget.selectedOption,
      'showAnswer': widget.showAnswer,
      'correctAnswer': widget.question.answer,
      'isCorrect': widget.selectedOption != null && 
                   widget.selectedOption!.toUpperCase() == widget.question.answer.toUpperCase(),
    };
    
    _controller.runJavaScript('updateState(${jsonEncode(state)})');
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2)}';
  }

  String _buildHtml() {
    final primaryColor = _colorToHex(widget.primaryColor);
    final errorColor = _colorToHex(widget.errorColor);
    final successColor = _colorToHex(widget.successColor);
    final textColor = _colorToHex(widget.textColor);
    final cardBg = _colorToHex(widget.surfaceColor);
    
    // Create a light variant of primary color for selected background
    final primaryLight = _colorToHex(widget.primaryColor.withOpacity(0.1));
    final errorLight = _colorToHex(widget.errorColor.withOpacity(0.1));
    final successLight = _colorToHex(widget.successColor.withOpacity(0.1));

    // Dynamic border color based on text color (e.g., 12% opacity)
    final borderColor = _colorToHex(widget.textColor.withOpacity(0.12));
    
    // Better option label colors
    final isDark = widget.surfaceColor.computeLuminance() < 0.5;
    final labelBg = isDark ? '#424242' : '#eeeeee';
    final labelText = _colorToHex(widget.textColor);

    final optionsHtml = widget.question.choiceEntries.map((entry) {
      return '''
        <div class="option-card" id="option-${entry.key}" onclick="selectOption('${entry.key}')">
          <div class="option-label">${entry.key}</div>
          <div class="option-content">${entry.value}</div>
          <div class="option-icon"></div>
        </div>
      ''';
    }).join('');

    final fullExplanationHtml = widget.question.explanation.isNotEmpty 
        ? '''
          <div class="explanation-card" id="explanation">
            <div class="explanation-header">
              <span class="bulb-icon">💡</span> 
              <strong>解析</strong>
            </div>
            <div class="explanation-content">${widget.question.explanation}</div>
          </div>
        ''' 
        : '';

    const css = '''
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
          margin: 0;
          padding: 0;
          background-color: transparent;
          color: var(--text-color);
          line-height: 1.6;
        }
        img { max-width: 100%; height: auto; display: block; margin: 8px 0; }
        p { margin: 0 0 10px 0; }
        
        .stem-card {
          background: var(--card-bg);
          border-radius: 12px;
          padding: 16px;
          box-shadow: 0 1px 3px rgba(0,0,0,0.12);
          margin-bottom: 12px;
        }

        .option-card {
          background: var(--card-bg);
          border-radius: 12px;
          padding: 14px;
          margin-bottom: 8px;
          display: flex;
          align-items: flex-start;
          cursor: pointer;
          transition: all 0.2s;
        }

        .option-label {
          width: 32px;
          height: 32px;
          background: var(--label-bg);
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          font-weight: bold;
          margin-right: 12px;
          flex-shrink: 0;
          color: var(--label-text);
        }

        .option-content {
          flex: 1;
          padding-top: 4px;
        }

        .option-icon {
          width: 24px;
          height: 24px;
          margin-left: 8px;
          display: none;
          align-items: center;
          justify-content: center;
          font-size: 20px;
        }

        /* States */
        .option-card.selected {
          border-color: var(--primary-color);
          background-color: var(--primary-light);
        }
        .option-card.selected .option-label {
          background-color: var(--primary-color);
          color: white;
        }

        /* Result States (Show Answer) */
        .show-answer .option-card.correct-answer {
          border-color: var(--success-color);
          background-color: var(--success-light);
        }
        .show-answer .option-card.correct-answer .option-label {
          background-color: var(--success-color);
          color: white;
        }
        .show-answer .option-card.correct-answer .option-icon::after {
          content: '✓';
          color: var(--success-color);
        }
        .show-answer .option-card.correct-answer .option-icon {
          display: flex;
        }

        .show-answer .option-card.wrong-selection {
          border-color: var(--error-color);
          background-color: var(--error-light);
        }
        .show-answer .option-card.wrong-selection .option-label {
          background-color: var(--error-color);
          color: white;
        }
        .show-answer .option-card.wrong-selection .option-icon::after {
          content: '✕';
          color: var(--error-color);
        }
        .show-answer .option-card.wrong-selection .option-icon {
          display: flex;
        }

        /* Explanation */
        .explanation-card {
          background: var(--card-bg);
          border-radius: 12px;
          padding: 16px;
          margin-top: 12px;
          box-shadow: 0 1px 3px rgba(0,0,0,0.12);
          display: none; /* Hidden by default */
        }
        .show-answer .explanation-card {
          display: block;
        }
        .explanation-header {
          display: flex;
          align-items: center;
          color: var(--primary-color);
          margin-bottom: 8px;
        }
        .bulb-icon { margin-right: 8px; }

      </style>
    ''';

    const js = '''
      <script>
        let currentState = {
          selectedOption: null,
          showAnswer: false,
          correctAnswer: '',
          isCorrect: false
        };

        function selectOption(key) {
          if (currentState.showAnswer) return; // Locked
          // Notify Flutter
          window.QuizHandler.postMessage(key);
        }

        function updateState(newState) {
          currentState = newState;
          render();
        }

        function render() {
          const { selectedOption, showAnswer, correctAnswer } = currentState;
          const body = document.body;
          
          if (showAnswer) {
            body.classList.add('show-answer');
          } else {
            body.classList.remove('show-answer');
          }

          // Reset all options
          document.querySelectorAll('.option-card').forEach(el => {
            el.className = 'option-card';
          });

          // Apply classes
          if (selectedOption) {
            const el = document.getElementById('option-' + selectedOption);
            if (el) el.classList.add('selected');
            
            if (showAnswer) {
               if (selectedOption.toUpperCase() !== correctAnswer.toUpperCase()) {
                 if (el) el.classList.add('wrong-selection');
               }
            }
          }

          if (showAnswer) {
            const correctEl = document.getElementById('option-' + correctAnswer);
            if (correctEl) correctEl.classList.add('correct-answer');
            
            // Show explanation
            const exp = document.getElementById('explanation');
            if (exp) {
                exp.style.display = 'block';
            }
          } else {
            const exp = document.getElementById('explanation');
            if (exp) exp.style.display = 'none';
          }
        }
        
        // Error logging
        document.addEventListener('error', function(event){
            if(event.target.tagName.toLowerCase() == 'img'){
                if (window.ConsoleHandler) {
                   window.ConsoleHandler.postMessage('Image failed: ' + event.target.src);
                }
            }
        }, true);
      </script>
    ''';

    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
          :root {
            --primary-color: $primaryColor;
            --primary-light: $primaryLight;
            --error-color: $errorColor;
            --error-light: $errorLight;
            --success-color: $successColor;
            --success-light: $successLight;
            --card-bg: $cardBg;
            --border-color: $borderColor;
            --label-bg: $labelBg;
            --label-text: $labelText;
            --text-color: $textColor;
          }
        </style>
        $css
      </head>
      <body>
        <div class="stem-card">
          ${widget.question.content}
        </div>
        
        <div class="options-container">
          $optionsHtml
        </div>

        $fullExplanationHtml
        
        $js
      </body>
      </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isLoading ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: WebViewWidget(
        controller: _controller,
      ),
    );
  }
}
