# Design System

> For **developers** and **designers**. Defines the visual language and component standards.

---

## 1. Design Principles

1. **Focus on learning**: minimize visual noise; content comes first.
2. **Instant feedback**: every action should have a clear visual or tactile response.
3. **Consistent & inclusive**: Material 3 design language, fully adapted for light/dark modes.
4. **Extensible**: themes, sounds, and haptic strategies are abstracted as interfaces for easy future expansion.

---

## 2. Color System

Generated from Material 3 `ColorScheme.fromSeed(seedColor: Color(0xFF1976D2))`.

### Semantic Colors

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `success` | `#4CAF50` | `#4CAF50` | Correct answers, pass states, positive feedback |
| `warning` | `#FFC107` | `#FFC107` | Warnings, attention |
| `error` | `colorScheme.error` | `colorScheme.error` | Wrong answers, delete actions, errors |

### Usage Rules

- **Never** use bare color values such as `Colors.grey` or `Colors.orange`.
- Prefer `colorScheme.onSurface` and `onSurfaceVariant` for text.
- Use `colorScheme.surfaceContainerHighest` or `surface` for card backgrounds.
- Use `onSurface.withValues(alpha: 0.38)` for disabled states.

---

## 3. Typography

Uses the default Material 3 type scale. Key styles:

| Context | Style | Size |
|---------|-------|------|
| AppBar title | `titleLarge` | default |
| AppBar subtitle | `titleSmall` | 12 |
| Card title | `titleMedium` | default |
| Body / question text | `bodyLarge` | default |
| Analysis / description | `bodyMedium` | default |
| Large stat numbers | `displayLarge` | default |
| Badge / label | `labelSmall` | default |

---

## 4. Spacing & Radius

### Corner Radius

| Component | Radius |
|-----------|--------|
| Card | `12` |
| ElevatedButton | `8` |
| TextField | `8` |
| Chip / Badge | `4` |
| Dialog | `28` (Material 3 default) |
| SnackBar | `8` |

### Spacing Tokens

| Token | Value | Usage |
|-------|-------|-------|
| `xs` | `4` | Icon-to-text gap |
| `sm` | `8` | Compact internal padding |
| `md` | `16` | Standard page margin |
| `lg` | `24` | Card padding, dialogs |
| `xl` | `32` | Large module spacing |

---

## 5. Elevation & Shadows

- **Card elevation**: `1`, no heavy shadows.
- **Bottom action bar shadow**:
  ```dart
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.08),
    blurRadius: 8,
    offset: const Offset(0, -2),
  )
  ```
- **Dialogs / bottom sheets**: no shadow; rely on the scrim for depth separation.

---

## 6. Iconography

### Selection Principles

- Prefer **Material Symbols** (Outlined / Rounded).
- Icons must have a clear semantic link to their function.
- Avoid using visually similar icons in the same screen.

### Core Icon Map

| Function | Icon | Alternative |
|----------|------|-------------|
| Practice mode | `edit_note` | `school` |
| Test mode | `timer` | `assignment` |
| Memory review | `psychology` | `memory` |
| Import package | `upload_file` | `drive_folder_upload` |
| Settings | `settings` | `tune` |
| Previous question | `arrow_back` | `chevron_left` |
| Next question | `arrow_forward` | `chevron_right` |
| AI explain | `auto_awesome` | `smart_toy` |
| Bookmark | `bookmark` / `bookmark_border` | `star` |
| Reset answer | `undo` | `replay` |
| Finish test | `check_circle` | `flag` |
| Total questions | `format_list_numbered` | `quiz` |
| Unanswered | `radio_button_unchecked` | `remove` |
| History | `history` | `restore` |

---

## 7. Empty States

Every list or data-driven screen must implement a professional empty state:

```dart
Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Icon(Icons.inbox_outlined, size: 64, color: onSurface.withAlpha(60)),
    const SizedBox(height: 16),
    Text('No data', style: bodyLarge.copyWith(color: onSurfaceVariant)),
    const SizedBox(height: 8),
    Text('Tap import to add a package', style: bodySmall.copyWith(color: onSurfaceVariant)),
  ],
)
```

Rules:
- Use soft outlined icons (not filled).
- Provide a clear next-action hint.

---

## 8. Motion & Transitions

| Context | Animation | Duration |
|---------|-----------|----------|
| Page transition | Material default | default |
| Option selection | Scale + color tween | 200 ms |
| Progress update | Elastic overshoot | 600 ms |
| Correct feedback | Border glow fade | 800 ms |
| Button press | Scale to 0.95 | 100 ms |
| Bottom sheet | Slide from bottom | default |

---

## 9. Dark Mode Adaptation

- All colors must come from `ColorScheme`; no hard-coded values.
- Image / formula render backgrounds should follow `Theme.of(context).colorScheme.surface`.
- In dark mode, use `Colors.white.withValues(alpha: 0.06)` instead of black shadows.
