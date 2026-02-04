import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:path/path.dart' as p;

class MarkdownContent extends StatelessWidget {
  final String content;
  final String? imageBasePath;
  final Color? textColor;
  final double fontSize;
  final bool selectable;

  const MarkdownContent({
    super.key,
    required this.content,
    this.imageBasePath,
    this.textColor,
    this.fontSize = 16.0,
    this.selectable = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseTextColor = textColor ?? theme.textTheme.bodyLarge?.color;
    
    final styleSheet = MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: TextStyle(
        color: baseTextColor,
        fontSize: fontSize,
      ),
    );

    return MarkdownBody(
      data: content,
      selectable: selectable,
      styleSheet: styleSheet,
      builders: {
        'latex': LatexElementBuilder(
          baseTextColor: baseTextColor,
          baseFontSize: fontSize,
        ),
      },
      extensionSet: md.ExtensionSet(
        [...md.ExtensionSet.gitHubFlavored.blockSyntaxes],
        [...md.ExtensionSet.gitHubFlavored.inlineSyntaxes, LatexInlineSyntax()],
      ),
      imageBuilder: (uri, title, alt) {
        if (imageBasePath != null && !uri.isAbsolute) {
          final filePath = p.join(imageBasePath!, uri.path);
          final file = File(filePath);
          if (file.existsSync()) {
            return Image.file(file);
          }
        }
        return Image.network(uri.toString(), errorBuilder: (ctx, err, stack) {
          return const Icon(Icons.broken_image, color: Colors.grey);
        });
      },
    );
  }
}

/// A syntax for matching inline and block LaTeX expressions.
/// Supports $...$ and $$...$$.
class LatexInlineSyntax extends md.InlineSyntax {
  LatexInlineSyntax() : super(r'(\$\$?)([\s\S]+?)\1');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final String delimiter = match.group(1)!;
    final String content = match.group(2)!;
    
    final element = md.Element.text('latex', content);
    element.attributes['displayMode'] = delimiter == '\u0024\u0024' ? 'true' : 'false';
    
    parser.addNode(element);
    return true;
  }
}

/// A builder for rendering 'latex' elements using flutter_math_fork.
class LatexElementBuilder extends MarkdownElementBuilder {
  final Color? baseTextColor;
  final double baseFontSize;

  LatexElementBuilder({
    this.baseTextColor,
    required this.baseFontSize,
  });

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final String text = element.textContent;
    final bool displayMode = element.attributes['displayMode'] == 'true';

    return Math.tex(
      text,
      mathStyle: displayMode ? MathStyle.display : MathStyle.text,
      textStyle: preferredStyle ?? TextStyle(
        color: baseTextColor,
        fontSize: baseFontSize,
      ),
      onErrorFallback: (err) => Text(
        displayMode ? '\u0024\u0024\n$text\n\u0024\u0024' : '\u0024$text\u0024',
        style: TextStyle(color: Colors.red, fontSize: baseFontSize),
      ),
    );
  }
}