import 'package:flutter/material.dart';

enum ToastPosition { top, bottom }

class ToastUtils {
  static OverlayEntry? _currentEntry;

  static void showToast(
    BuildContext context,
    String message, {
    ToastPosition position = ToastPosition.bottom,
  }) {
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ToastWidget(
        message: message,
        position: position,
        onExpired: () {
          if (_currentEntry == entry) {
            entry.remove();
            _currentEntry = null;
          }
        },
      ),
    );
    _currentEntry = entry;
    overlay.insert(entry);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastPosition position;
  final VoidCallback onExpired;

  const _ToastWidget({
    required this.message,
    required this.position,
    required this.onExpired,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _exitController;
  late final Animation<double> _entryCurved;
  late final Animation<double> _exitCurved;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _entryCurved = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _exitCurved = CurvedAnimation(parent: _exitController, curve: Curves.easeIn);

    _entryController.forward().then((_) {
      if (_isDisposed) return;
      Future.delayed(const Duration(seconds: 2), _fadeOut);
    });
  }

  Future<void> _fadeOut() async {
    if (_isDisposed) return;
    try {
      await _exitController.forward();
    } catch (_) {
      return;
    }
    if (!_isDisposed) widget.onExpired();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _entryController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final padding = MediaQuery.of(context).padding;

    return AnimatedBuilder(
      animation: Listenable.merge([_entryCurved, _exitCurved]),
      builder: (context, child) {
        final opacity = _entryCurved.value * (1.0 - _exitCurved.value);
        // slideOffset: 12→0 as entry progresses.
        // Subtracted from the anchor so both positions slide toward center:
        //   bottom toast: starts 12px lower  → slides UP into position
        //   top toast:    starts 12px higher → slides DOWN into position
        final slideOffset = 12.0 * (1.0 - _entryCurved.value);

        return widget.position == ToastPosition.bottom
            ? Positioned(
                bottom: padding.bottom + 80 - slideOffset,
                left: 32,
                right: 32,
                child: Opacity(opacity: opacity.clamp(0.0, 1.0), child: child!),
              )
            : Positioned(
                top: padding.top + 64 - slideOffset,
                left: 32,
                right: 32,
                child: Opacity(opacity: opacity.clamp(0.0, 1.0), child: child!),
              );
      },
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              widget.message,
              style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
