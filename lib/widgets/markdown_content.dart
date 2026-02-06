import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/quiz_provider.dart';

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
    final settings = Provider.of<SettingsProvider>(context);
    final baseTextColor = textColor ?? theme.textTheme.bodyLarge?.color;
    
    final styleSheet = MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: TextStyle(
        color: baseTextColor,
        fontSize: fontSize,
      ),
      blockquote: TextStyle(
        color: baseTextColor?.withValues(alpha: 0.85),
        fontSize: fontSize,
      ),
      blockquoteDecoration: BoxDecoration(
        color: baseTextColor?.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(
            color: baseTextColor?.withValues(alpha: 0.3) ?? theme.colorScheme.primary,
            width: 4,
          ),
        ),
      ),
      blockquotePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      code: TextStyle(
        color: theme.colorScheme.secondary,
        fontSize: fontSize * 0.9,
        backgroundColor: Colors.transparent, // Handled by decoration or parent
      ),
      codeblockDecoration: BoxDecoration(
        color: baseTextColor?.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: baseTextColor?.withValues(alpha: 0.1) ?? Colors.transparent),
      ),
      codeblockPadding: const EdgeInsets.all(12),
    );

    final markdownBody = MarkdownBody(
      data: content,
      selectable: false, // Must be false when using SelectionArea, and we don't want the default SelectableText if selectable is true
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

    if (!selectable) {
      return markdownBody;
    }

    return SelectionArea(
      contextMenuBuilder: (context, selectableRegionState) {
        final List<ContextMenuButtonItem> items = 
            selectableRegionState.contextMenuButtonItems;
        
        // 1. Identify and extract Eudic item
        final eudicItem = items.where((item) => 
            item.label?.toLowerCase().contains('eudic') ?? false).firstOrNull;
        if (eudicItem != null) items.remove(eudicItem);

        // 2. Build the initial list based on user preference (Copy, Select All)
        final List<ContextMenuButtonItem> result = [];
        for (final label in settings.selectionMenuItems) {
          final standardItem = items.where((i) {
            if (label == 'Copy' && i.type == ContextMenuButtonType.copy) return true;
            if (label == 'Select All' && i.type == ContextMenuButtonType.selectAll) return true;
            return false;
          }).firstOrNull;

          if (standardItem != null) {
            result.add(standardItem);
            items.remove(standardItem);
          }
        }

        // 3. Add remaining items and handle Eudic position
        if (eudicItem != null) {
          // Find 'Share' item index in the remaining items or the result so far
          final shareIndex = items.indexWhere((item) => 
              item.type == ContextMenuButtonType.share || 
              (item.label?.toLowerCase().contains('share') ?? false));

          if (shareIndex != -1) {
            // Insert after Share
            items.insert(shareIndex + 1, eudicItem);
          } else {
            // If Share not found, put it at the end of remaining items
            items.add(eudicItem);
          }
        }

        // Add the rest
        result.addAll(items);

        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: selectableRegionState.contextMenuAnchors,
          buttonItems: result,
        );
      },
      child: markdownBody,
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