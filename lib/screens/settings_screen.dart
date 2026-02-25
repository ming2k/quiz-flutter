import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
              _buildSectionHeader(context, l10n.appearance),
              _buildThemeTile(context, settings, l10n),
              _buildLanguageTile(context, settings, l10n),
              const Divider(),

              // Quiz Experience Section
              _buildSectionHeader(context, l10n.quizExperience),
              SwitchListTile(
                title: Text(l10n.memorizeMode),
                subtitle: Text(l10n.memorizeModeDesc),
                value: settings.memorizeMode,
                onChanged: (value) => settings.setMemorizeMode(value),
              ),
              SwitchListTile(
                title: Text(l10n.autoAdvance),
                subtitle: Text(l10n.autoAdvanceDesc),
                value: settings.autoAdvance,
                onChanged: (value) => settings.setAutoAdvance(value),
              ),
              SwitchListTile(
                title: Text(l10n.showAnalysisOption),
                subtitle: Text(l10n.showAnalysisOptionDesc),
                value: settings.showAnalysis,
                onChanged: (value) => settings.setShowAnalysis(value),
              ),
              SwitchListTile(
                title: Text(l10n.soundEffects),
                subtitle: Text(l10n.soundEffectsDesc),
                value: settings.soundEffects,
                onChanged: (value) => settings.setSoundEffects(value),
              ),
              SwitchListTile(
                title: Text(l10n.hapticFeedback),
                subtitle: Text(l10n.hapticFeedbackDesc),
                value: settings.hapticFeedback,
                onChanged: (value) => settings.setHapticFeedback(value),
              ),
              SwitchListTile(
                title: Text(l10n.confettiEffect),
                subtitle: Text(l10n.confettiEffectDesc),
                value: settings.confettiEffect,
                onChanged: (value) => settings.setConfettiEffect(value),
              ),
              ListTile(
                title: Text(l10n.testQuestionCount),
                subtitle: Text('${settings.testQuestionCount} ${l10n.questions}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showTestQuestionCountDialog(context, settings, l10n),
              ),
              const Divider(),

              // AI Settings Section
              _buildSectionHeader(context, l10n.aiSettings),
              SwitchListTile(
                title: Text(l10n.aiChatScrollToBottom),
                subtitle: Text(l10n.aiChatScrollToBottomDesc),
                value: settings.aiChatScrollToBottom,
                onChanged: (value) => settings.setAiChatScrollToBottom(value),
              ),
              ListTile(
                title: Text(l10n.aiProvider),
                subtitle: Text(settings.aiProvider),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showAiProviderDialog(context, settings),
              ),
              ListTile(
                title: Text(l10n.aiApiKey),
                subtitle: Text(
                  settings.aiApiKey.isEmpty
                      ? l10n.aiKeyNotSet
                      : '••••••${settings.aiApiKey.length > 8 ? settings.aiApiKey.substring(settings.aiApiKey.length - 4) : ''}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showApiKeyDialog(context, settings),
              ),
              ListTile(
                title: Text(l10n.aiBaseUrl),
                subtitle: Text(
                  settings.aiBaseUrl.isEmpty ? l10n.aiBaseUrlDefault : settings.aiBaseUrl,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showAiBaseUrlDialog(context, settings),
              ),
              ListTile(
                title: Text(l10n.aiModel),
                subtitle: Text(settings.aiModel),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showModelDialog(context, settings),
              ),
              const Divider(),

              // Text Selection Section
              _buildSectionHeader(context, l10n.textSelectionMenu),
              ListTile(
                title: Text(l10n.menuItemOrder),
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
    final l10n = AppLocalizations.of(context);
    List<String> items = List.from(settings.selectionMenuItems);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.reorderMenuItems),
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
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                settings.setSelectionMenuItems(items);
                Navigator.pop(context);
              },
              child: Text(l10n.save),
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
      title: Text(l10n.theme),
      subtitle: Text(_getThemeLabel(settings.themeMode, l10n)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => SimpleDialog(
            title: Text(l10n.theme),
            children: [
              RadioListTile<ThemeMode>(
                title: Text(l10n.themeSystem),
                value: ThemeMode.system,
                groupValue: settings.themeMode,
                onChanged: (value) {
                  settings.setThemeMode(value!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text(l10n.themeLight),
                value: ThemeMode.light,
                groupValue: settings.themeMode,
                onChanged: (value) {
                  settings.setThemeMode(value!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text(l10n.themeDark),
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
        return l10n.themeSystem;
      case ThemeMode.light:
        return l10n.themeLight;
      case ThemeMode.dark:
        return l10n.themeDark;
    }
  }

  Widget _buildLanguageTile(
    BuildContext context,
    SettingsProvider settings,
    AppLocalizations l10n,
  ) {
    return ListTile(
      title: Text(l10n.language),
      subtitle: Text(settings.locale == 'zh-CN' ? '中文' : 'English'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => SimpleDialog(
            title: Text(l10n.language),
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
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.aiProvider),
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
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: settings.aiApiKey);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.aiApiKey),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: l10n.enterApiKey,
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              settings.setAiApiKey(controller.text);
              Navigator.pop(context);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showModelDialog(BuildContext context, SettingsProvider settings) {
    final l10n = AppLocalizations.of(context);
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
        title: Text(l10n.aiModel),
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
    int selectedCount = settings.testQuestionCount;
    const int minCount = 5;
    const int maxCount = 200;
    const int step = 5;

    final List<int> options = List.generate(
      (maxCount - minCount) ~/ step + 1,
      (index) => minCount + (index * step)
    );

    int initialIndex = options.indexOf(selectedCount);
    if (initialIndex == -1) {
      initialIndex = options.indexWhere((val) => val >= selectedCount);
      if (initialIndex == -1) initialIndex = options.length - 1;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.testQuestionCount),
        content: SizedBox(
          height: 150,
          width: double.maxFinite,
          child: CupertinoPicker(
            scrollController: FixedExtentScrollController(initialItem: initialIndex),
            itemExtent: 32,
            onSelectedItemChanged: (index) {
              selectedCount = options[index];
            },
            children: options.map((count) => Center(
              child: Text(
                '$count',
                style: const TextStyle(fontSize: 20),
              ),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              settings.setTestQuestionCount(selectedCount);
              Navigator.pop(context);
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  void _showAiBaseUrlDialog(BuildContext context, SettingsProvider settings) {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: settings.aiBaseUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.aiBaseUrl),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: l10n.aiBaseUrlHint,
                helperText: l10n.aiBaseUrlHelper,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              settings.setAiBaseUrl(controller.text.trim());
              Navigator.pop(context);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
