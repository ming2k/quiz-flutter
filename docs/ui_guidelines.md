# UI Development Guidelines

> For **Flutter developers**. Ensures new screens and components follow the design system.

---

## 1. Mandatory Rules

### 1.1 Colors

```dart
// ❌ Forbidden
Colors.grey
Colors.orange
Colors.green

// ✅ Correct
Theme.of(context).colorScheme.onSurfaceVariant
Theme.of(context).colorScheme.primary
AppTheme.success
AppTheme.warning
```

### 1.2 Text

```dart
// ❌ Forbidden
Text('Show Answer')
Text('Complete')

// ✅ Correct
final l10n = AppLocalizations.of(context);
Text(l10n.showAnswer)
```

### 1.3 Icons

```dart
// ❌ Forbidden
Icon(Icons.refresh)   // Semantically ambiguous; easily confused with "reload"

// ✅ Correct
Icon(Icons.undo)      // Clearly means "undo / reset"
```

See `docs/design_system.md` → "Iconography" for the full mapping table.

### 1.4 Empty States

Every data-dependent list or screen must implement an empty state. Blank screens are not allowed:

```dart
if (items.isEmpty) {
  return _buildEmptyState(context);
}
```

---

## 2. Page Structure Template

```dart
class ExampleScreen extends StatelessWidget {
  const ExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.exampleTitle),
      ),
      body: Consumer<SomeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return _buildErrorState(context, provider.error!);
          }

          if (provider.items.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.items.length,
            itemBuilder: (context, index) => _buildItemCard(context, provider.items[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: colorScheme.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).noData,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(error, style: TextStyle(color: colorScheme.error)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<SomeProvider>().load(),
            child: Text(AppLocalizations.of(context).retry),
          ),
        ],
      ),
    );
  }
}
```

---

## 3. Adding a New Setting

1. **Add storage field** → `SettingsProvider`
2. **Add UI control** → `SettingsScreen`
3. **Add localized strings** → `app_en.arb` + `app_zh.arb`
4. **Regenerate l10n** → `flutter gen-l10n`
5. **Read in relevant pages** → via `context.read<SettingsProvider>()`

---

## 4. Adding a New Feedback Theme

1. Implement the `SoundTheme` or `HapticStrategy` interface.
2. Register it in `availableThemes` / `availableStrategies`.
3. Switch via `FeedbackService.configure(soundTheme: ...)`.

---

## 5. Common Anti-patterns

| Anti-pattern | Problem | Fix |
|--------------|---------|-----|
| `Colors.grey` | Invisible in dark mode | `colorScheme.onSurfaceVariant` |
| Missing empty state | User confusion | Add an empty-state illustration |
| Hard-coded Chinese strings | Breaks internationalization | Extract to ARB |
| `MainAxisAlignment.spaceAround` + 2 items | Unbalanced spacing on wide screens | Use `Wrap` or fixed spacing |
| Oversized `displayLarge` without adaptation | Overflow on small screens | Wrap in `FittedBox` or `AutoSizeText` |
| Calling async inside `dispose()` without awaiting | Memory leaks | Use `unawaited()` or synchronous cleanup |
