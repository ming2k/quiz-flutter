import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              // Appearance Section
              _buildSectionHeader(context, l10n.get('appearance')),
              _buildThemeTile(context, settings, l10n),
              _buildLanguageTile(context, settings, l10n),
              const Divider(),

              // Quiz Experience Section
              _buildSectionHeader(context, l10n.get('quizExperience')),
              SwitchListTile(
                title: Text(l10n.get('autoAdvance')),
                subtitle: Text(l10n.get('autoAdvanceDesc')),
                value: settings.autoAdvance,
                onChanged: (value) => settings.setAutoAdvance(value),
              ),
              SwitchListTile(
                title: Text(l10n.get('showAnalysisOption')),
                subtitle: Text(l10n.get('showAnalysisOptionDesc')),
                value: settings.showAnalysis,
                onChanged: (value) => settings.setShowAnalysis(value),
              ),
              SwitchListTile(
                title: Text(l10n.get('soundEffects')),
                subtitle: Text(l10n.get('soundEffectsDesc')),
                value: settings.soundEffects,
                onChanged: (value) => settings.setSoundEffects(value),
              ),
              SwitchListTile(
                title: Text(l10n.get('hapticFeedback')),
                subtitle: Text(l10n.get('hapticFeedbackDesc')),
                value: settings.hapticFeedback,
                onChanged: (value) => settings.setHapticFeedback(value),
              ),
              SwitchListTile(
                title: Text(l10n.get('confettiEffect')),
                subtitle: Text(l10n.get('confettiEffectDesc')),
                value: settings.confettiEffect,
                onChanged: (value) => settings.setConfettiEffect(value),
              ),
              ListTile(
                title: Text(l10n.get('testQuestionCount')),
                subtitle: Text('${settings.testQuestionCount} ${l10n.get('questions')}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showTestQuestionCountDialog(context, settings, l10n),
              ),
              const Divider(),

              // AI Settings Section
              _buildSectionHeader(context, l10n.get('aiSettings')),
              ListTile(
                title: Text(l10n.get('aiProvider')),
                subtitle: Text(settings.aiProvider),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showAiProviderDialog(context, settings),
              ),
              ListTile(
                title: Text(l10n.get('aiApiKey')),
                subtitle: Text(
                  settings.aiApiKey.isEmpty
                      ? '未设置'
                      : '••••••${settings.aiApiKey.length > 8 ? settings.aiApiKey.substring(settings.aiApiKey.length - 4) : ''}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showApiKeyDialog(context, settings),
              ),
              ListTile(
                title: const Text('AI Base URL'),
                subtitle: Text(
                  settings.aiBaseUrl.isEmpty ? 'Default' : settings.aiBaseUrl,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showAiBaseUrlDialog(context, settings),
              ),
              ListTile(
                title: Text(l10n.get('aiModel')),
                subtitle: Text(settings.aiModel),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showModelDialog(context, settings),
              ),
              const Divider(),

              // Text Selection Section
              _buildSectionHeader(context, '文本选择菜单'),
              ListTile(
                title: const Text('菜单项排序'),
                subtitle: Text(settings.selectionMenuItems.join(', ')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showSelectionMenuOrderDialog(context, settings),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSelectionMenuOrderDialog(BuildContext context, SettingsProvider settings) {
    List<String> items = List.from(settings.selectionMenuItems);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('调整菜单顺序'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ReorderableListView(
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final String item = items.removeAt(oldIndex);
                  items.insert(newIndex, item);
                });
              },
              children: items
                  .map((item) => ListTile(
                        key: ValueKey(item),
                        title: Text(item),
                        trailing: const Icon(Icons.drag_handle),
                      ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                settings.setSelectionMenuItems(items);
                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildThemeTile(
    BuildContext context,
    SettingsProvider settings,
    AppLocalizations l10n,
  ) {
    return ListTile(
      title: Text(l10n.get('theme')),
      subtitle: Text(_getThemeLabel(settings.themeMode, l10n)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => SimpleDialog(
            title: Text(l10n.get('theme')),
            children: [
              RadioListTile<ThemeMode>(
                title: Text(l10n.get('themeSystem')),
                value: ThemeMode.system,
                groupValue: settings.themeMode,
                onChanged: (value) {
                  settings.setThemeMode(value!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text(l10n.get('themeLight')),
                value: ThemeMode.light,
                groupValue: settings.themeMode,
                onChanged: (value) {
                  settings.setThemeMode(value!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text(l10n.get('themeDark')),
                value: ThemeMode.dark,
                groupValue: settings.themeMode,
                onChanged: (value) {
                  settings.setThemeMode(value!);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _getThemeLabel(ThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case ThemeMode.system:
        return l10n.get('themeSystem');
      case ThemeMode.light:
        return l10n.get('themeLight');
      case ThemeMode.dark:
        return l10n.get('themeDark');
    }
  }

  Widget _buildLanguageTile(
    BuildContext context,
    SettingsProvider settings,
    AppLocalizations l10n,
  ) {
    return ListTile(
      title: Text(l10n.get('language')),
      subtitle: Text(settings.locale == 'zh-CN' ? '中文' : 'English'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => SimpleDialog(
            title: Text(l10n.get('language')),
            children: [
              RadioListTile<String>(
                title: const Text('中文'),
                value: 'zh-CN',
                groupValue: settings.locale,
                onChanged: (value) {
                  settings.setLocale(value!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('English'),
                value: 'en-US',
                groupValue: settings.locale,
                onChanged: (value) {
                  settings.setLocale(value!);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAiProviderDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('AI Provider'),
        children: [
          RadioListTile<String>(
            title: const Text('Google Gemini'),
            value: 'gemini',
            groupValue: settings.aiProvider,
            onChanged: (value) {
              settings.setAiProvider(value!);
              Navigator.pop(context);
            },
          ),
          RadioListTile<String>(
            title: const Text('Anthropic Claude'),
            value: 'claude',
            groupValue: settings.aiProvider,
            onChanged: (value) {
              settings.setAiProvider(value!);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController(text: settings.aiApiKey);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Key'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter your API key',
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              settings.setAiApiKey(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showModelDialog(BuildContext context, SettingsProvider settings) {
    final models = settings.aiProvider == 'gemini'
        ? [
            'gemini-2.0-flash',
            'gemini-1.5-flash',
            'gemini-1.5-pro',
            'gemini-3-pro-preview',
            'gemini-3-flash-preview'
          ]
        : [
            'claude-3-5-sonnet-20240620',
            'claude-3-haiku-20240307',
            'claude-3-sonnet-20240229',
            'claude-3-opus-20240229'
          ];

    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Model'),
        children: models
            .map(
              (model) => RadioListTile<String>(
                title: Text(model),
                value: model,
                groupValue: settings.aiModel,
                onChanged: (value) {
                  settings.setAiModel(value!);
                  Navigator.pop(context);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  void _showTestQuestionCountDialog(BuildContext context, SettingsProvider settings, AppLocalizations l10n) {
    final counts = [10, 20, 30, 50, 100];

    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.get('testQuestionCount')),
        children: counts
            .map(
              (count) => RadioListTile<int>(
                title: Text('$count'),
                value: count,
                groupValue: settings.testQuestionCount,
                onChanged: (value) {
                  settings.setTestQuestionCount(value!);
                  Navigator.pop(context);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  void _showAiBaseUrlDialog(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController(text: settings.aiBaseUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Base URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'https://generativelanguage.googleapis.com',
                helperText: 'Leave empty for default',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              settings.setAiBaseUrl(controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
