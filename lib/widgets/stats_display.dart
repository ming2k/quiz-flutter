import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatsDisplay extends StatefulWidget {
  final int currentIndex;
  final int totalQuestions;
  final int correctCount;
  final int wrongCount;
  final int markedCount;
  final double accuracy;
  final bool isTestMode;
  final int testStartTime;

  const StatsDisplay({
    super.key,
    required this.currentIndex,
    required this.totalQuestions,
    required this.correctCount,
    required this.wrongCount,
    required this.markedCount,
    required this.accuracy,
    this.isTestMode = false,
    this.testStartTime = 0,
  });

  @override
  State<StatsDisplay> createState() => _StatsDisplayState();
}

class _StatsDisplayState extends State<StatsDisplay> {
  Timer? _timer;
  String _elapsedTime = '00:00';

  @override
  void initState() {
    super.initState();
    if (widget.isTestMode) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(StatsDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTestMode && !oldWidget.isTestMode) {
      _startTimer();
    } else if (!widget.isTestMode && oldWidget.isTestMode) {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          final elapsed =
              DateTime.now().millisecondsSinceEpoch - widget.testStartTime;
          final minutes = (elapsed ~/ 60000).toString().padLeft(2, '0');
          final seconds =
              ((elapsed % 60000) ~/ 1000).toString().padLeft(2, '0');
          _elapsedTime = '$minutes:$seconds';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.totalQuestions > 0
        ? (widget.currentIndex + 1) / widget.totalQuestions
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Stats Row
          Row(
            children: [
              // Question Counter
              Text(
                '${widget.currentIndex + 1} / ${widget.totalQuestions}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),

              // Correct
              _buildStatChip(
                icon: Icons.check_circle,
                label: '${widget.correctCount}',
                color: AppTheme.success,
              ),
              const SizedBox(width: 12),

              // Wrong
              _buildStatChip(
                icon: Icons.cancel,
                label: '${widget.wrongCount}',
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 12),

              // Marked
              _buildStatChip(
                icon: Icons.bookmark,
                label: '${widget.markedCount}',
                color: AppTheme.warning,
              ),

              // Timer (test mode)
              if (widget.isTestMode) ...[
                const SizedBox(width: 12),
                _buildStatChip(
                  icon: Icons.timer,
                  label: _elapsedTime,
                  color: Colors.orange,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
