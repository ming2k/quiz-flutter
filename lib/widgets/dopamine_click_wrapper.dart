import 'package:flutter/material.dart';

/// A wrapper that adds physical "Squish & Bounce" feedback to its child.
/// When pressed, the child scales down. When released, it bounces back.
/// Uses [Listener] to detect press/release without consuming tap gestures,
/// allowing it to work with [InkWell], [IconButton], etc.
class DopamineClickWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap; // Optional: If child doesn't handle taps itself
  final double scaleDown;
  final double scaleUp;
  final Duration pressDuration;
  final Duration releaseDuration;
  final Curve releaseCurve;
  final bool isCorrect; // Special trigger for "correct answer" bounce

  const DopamineClickWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.95,
    this.scaleUp = 1.08,
    this.pressDuration = const Duration(milliseconds: 100),
    this.releaseDuration = const Duration(milliseconds: 500),
    this.releaseCurve = Curves.elasticOut,
    this.isCorrect = false,
  });

  @override
  State<DopamineClickWrapper> createState() => _DopamineClickWrapperState();
}

class _DopamineClickWrapperState extends State<DopamineClickWrapper> {
  double _scale = 1.0;
  bool _isPressed = false;
  bool _isBouncing = false;

  @override
  void didUpdateWidget(DopamineClickWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If it just became correct, trigger a bounce
    if (widget.isCorrect && !oldWidget.isCorrect) {
      _triggerCorrectBounce();
    }
  }

  void _triggerCorrectBounce() {
    setState(() {
      _isBouncing = true;
      _scale = widget.scaleUp;
    });
    // Quick expansion duration
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isBouncing = false;
          _scale = 1.0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use fast duration for pressing down or expanding up
    final bool useFastDuration = _isPressed || _isBouncing;
    
    Widget result = AnimatedScale(
      scale: _scale,
      duration: useFastDuration ? widget.pressDuration : widget.releaseDuration,
      curve: useFastDuration ? Curves.easeOutCubic : widget.releaseCurve,
      child: widget.child,
    );

    if (widget.onTap != null) {
      result = GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: result,
      );
    }

    return Listener(
      onPointerDown: (_) => setState(() {
        _isPressed = true;
        _scale = widget.scaleDown;
      }),
      onPointerUp: (_) => setState(() {
        _isPressed = false;
        _scale = 1.0;
      }),
      onPointerCancel: (_) => setState(() {
        _isPressed = false;
        _scale = 1.0;
      }),
      child: result,
    );
  }
}