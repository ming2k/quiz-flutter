import 'package:flutter/material.dart';
import 'dart:math' as math;

class DopamineProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double height;
  final Color? color;
  final Color? backgroundColor;

  const DopamineProgressBar({
    super.key,
    required this.progress,
    this.height = 4.0,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barColor = color ?? theme.colorScheme.primary;
    final bgColor = backgroundColor ?? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2);

    return Container(
      key: const Key('dopamine_progress_bar_container'),
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
      ),
      child: LayoutBuilder(
        key: const Key('dopamine_progress_bar_layout'),
        builder: (context, constraints) {
          return TweenAnimationBuilder<double>(
            key: const Key('dopamine_progress_bar_animation'),
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 1000),
            curve: const GentleBackCurve(),
            builder: (context, value, child) {
              final visualValue = value.clamp(0.0, 1.05);
              final width = constraints.maxWidth * visualValue.clamp(0.0, 1.0);
              
              // Calculate how much it's currently "over" or "moving"
              // When stationary at a target, value == progress.
              // During overshoot, (value - progress).abs() is high.
              final diff = (value - progress).abs();
              // Glow intensity based on movement/overshoot (0.0 to 1.0)
              final animationIntensity = (diff * 20.0).clamp(0.0, 1.0);

              return Stack(
                key: const Key('dopamine_progress_bar_stack'),
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  // Main Bar Fill
                  Container(
                    key: const Key('dopamine_progress_bar_fill'),
                    width: width,
                    height: height,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(height / 2),
                      ),
                    ),
                  ),
                  
                  // Dynamic Leading Glow - Only visible during animation/overshoot
                  if (width > 0 && animationIntensity > 0.01)
                    Positioned(
                      key: const Key('dopamine_progress_bar_glow_positioned'),
                      left: width - 20,
                      child: Opacity(
                        opacity: animationIntensity,
                        child: Container(
                          key: const Key('dopamine_progress_bar_glow_container'),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.9),
                                barColor.withValues(alpha: 0.6),
                                barColor.withValues(alpha: 0.2),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.2, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Leading Spark - Subtle when stationary, bright when moving
                  if (width > 0)
                    Positioned(
                      key: const Key('dopamine_progress_bar_spark_positioned'),
                      left: width - (2 + animationIntensity * 2),
                      child: Container(
                        key: const Key('dopamine_progress_bar_spark_container'),
                        // Size grows slightly during animation
                        width: 4 + animationIntensity * 4,
                        height: 4 + animationIntensity * 4,
                        decoration: BoxDecoration(
                          color: Color.lerp(barColor, Colors.white, 0.3 + (animationIntensity * 0.7)),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: barColor.withValues(alpha: 0.5 + (animationIntensity * 0.5)),
                              blurRadius: 4 + animationIntensity * 6,
                              spreadRadius: animationIntensity * 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class GentleBackCurve extends Curve {
  const GentleBackCurve();
  @override
  double transformInternal(double t) {
    const double s = 0.8; 
    t = t - 1.0;
    return t * t * ((s + 1) * t + s) + 1.0;
  }
}