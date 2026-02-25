import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class TestHistoryList extends StatefulWidget {
  const TestHistoryList({super.key});

  @override
  State<TestHistoryList> createState() => _TestHistoryListState();
}

class _TestHistoryListState extends State<TestHistoryList> {
  final StorageService _storage = StorageService();
  List<TestHistoryEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final quiz = context.read<QuizProvider>();
    final entries = await quiz.getTestHistory();
    if (mounted) {
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).testHistory),
        actions: [
          if (_entries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _confirmClear,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(AppLocalizations.of(context).noTestHistory, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
                    return _buildHistoryCard(_entries[index]);
                  },
                ),
    );
  }

  Widget _buildHistoryCard(TestHistoryEntry entry) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPass = entry.accuracy >= 0.6;
    final passColor = AppTheme.success;
    final failColor = colorScheme.error;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date and Duration
            Row(
              children: [
                Text(
                  entry.formattedDate,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const Spacer(),
                Icon(
                  Icons.timer,
                  size: 14,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Text(
                  entry.formattedDuration,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Score
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPass
                        ? passColor.withValues(alpha: 0.1)
                        : failColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isPass ? passColor : failColor,
                    ),
                  ),
                  child: Text(
                    entry.accuracyPercent,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isPass ? passColor : failColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniStat(
                        AppLocalizations.of(context).totalShort,
                        entry.totalQuestions.toString(),
                        colorScheme.primary,
                      ),
                      _buildMiniStat(
                        AppLocalizations.of(context).correctShort,
                        entry.correctCount.toString(),
                        passColor,
                      ),
                      _buildMiniStat(
                        AppLocalizations.of(context).wrongShort,
                        entry.wrongCount.toString(),
                        failColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
        ),
      ],
    );
  }

  void _confirmClear() {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearHistory),
        content: Text(l10n.clearHistoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              await _storage.clearAllHistory();
              if (context.mounted) {
                Navigator.pop(context);
                _loadHistory();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: Text(l10n.clear),
          ),
        ],
      ),
    );
  }
}
