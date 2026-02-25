# Quiz App

A general, extensible quiz framework built with Flutter. Supports multiple study modes, AI-powered explanations, Markdown/LaTeX rendering, and a custom quiz package format.

## Features

- **Multiple study modes** — Practice, Review, Memorize, and timed Test
- **AI explanations** — Streaming chat powered by Gemini, Claude, or any OpenAI-compatible endpoint
- **Rich content** — Markdown and LaTeX (via `flutter_math_fork`) in questions and explanations
- **Quiz packages** — Import `.zip` / `.quizpkg` files; a sample package is bundled at first launch
- **Progress tracking** — SQLite-backed per-question history, test results, and streaks
- **i18n** — English and Chinese (Simplified); follows system locale by default
- **Theming** — Light / Dark / System, Material 3 color roles throughout
- **Feedback** — Optional haptic feedback, sound effects, and confetti on streaks

---

## Getting Started

### Prerequisites

| Tool | Version |
|------|---------|
| Flutter | ≥ 3.10 |
| Dart | ≥ 3.10 |
| Android SDK | API 21+ (minSdk) |

Install Flutter: https://docs.flutter.dev/get-started/install

---

## Development

### Run in debug mode

```bash
flutter run
```

When the debug runner is active in the terminal, press **`v`** to open the app in your **browser** (Flutter Web DevTools / widget inspector). This is useful for layout debugging without needing a physical device.

Other useful key shortcuts in the runner:

| Key | Action |
|-----|--------|
| `r` | Hot reload |
| `R` | Hot restart |
| `v` | Open in browser |
| `p` | Toggle widget inspector overlay |
| `q` | Quit |

### Debug vs Release — different package names

The Android build is configured so that **debug and release builds can be installed side-by-side** on the same device:

| Build type | Application ID | App name |
|-----------|----------------|----------|
| Debug | `com.hihusky.quiz.debug` | Quiz (test) |
| Release | `com.hihusky.quiz` | Quiz |

This is set in `android/app/build.gradle.kts`:

```kotlin
buildTypes {
    debug {
        applicationIdSuffix = ".debug"
        resValue("string", "app_name", "Quiz (test)")
    }
    release {
        resValue("string", "app_name", "Quiz")
    }
}
```

### Localization (i18n)

String resources live in `lib/l10n/`:

```
lib/l10n/
  app_en.arb   ← English strings
  app_zh.arb   ← Chinese strings
```

After editing an ARB file, regenerate the Dart bindings:

```bash
flutter gen-l10n
```

Generated files (`app_localizations.dart`, `_en.dart`, `_zh.dart`) are committed to the repo so the project builds without running the generator first.

**Do not use `"of"` as an ARB key** — it conflicts with the static `AppLocalizations.of(context)` method. Use descriptive names like `"questionOf"` instead.

### Project structure

```
lib/
  main.dart                  # App entry point, providers, MaterialApp
  models/                    # Data classes (Question, Book, Section, …)
  providers/                 # SettingsProvider, QuizProvider
  screens/                   # HomeScreen, QuizScreen, SettingsScreen, TestResultScreen
  services/                  # DatabaseService, PackageService, AiService, …
  theme/                     # AppTheme (light/dark, Material 3)
  utils/                     # ToastUtils, …
  widgets/                   # Reusable widgets (AiChatPanel, OverviewSheet, …)
  l10n/                      # ARB files + generated localizations
assets/
  sounds/                    # Streak / wrong-answer audio
  packages/                  # sample-quiz.zip (bundled, auto-imported on first launch)
```

---

## Quiz Package Format

A quiz package is a `.zip` (or `.quizpkg`) archive that contains a `data.json` file at its root (or one directory level deep — the app flattens the structure automatically).

### `data.json` schema

```jsonc
{
  "subject_name_zh": "示例题库",
  "subject_name_en": "Sample Quiz",
  "chapters": [
    {
      "id": "ch1",
      "title": "Chapter 1",
      "sections": [
        {
          "id": "sec1",
          "title": "Section 1.1",
          "questions": [
            {
              "content": "What is 1 + 1?",
              "choices": [
                { "key": "A", "content": "1" },
                { "key": "B", "content": "2" },
                { "key": "C", "content": "3" }
              ],
              "answer": "B",
              "explanation": "Basic arithmetic."
            }
          ]
        }
      ]
    }
  ]
}
```

Choice content supports **Markdown** and **LaTeX** (`$...$` inline, `$$...$$` block).

Images can be included in the archive alongside `data.json` and referenced with relative paths in `content` or `explanation`.

---

## Building for Release

### Android APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (recommended for Play Store)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

> **Signing**: The current `build.gradle.kts` uses the debug keystore for release builds as a placeholder. Before publishing, configure a proper signing key:
>
> 1. Generate a keystore: `keytool -genkey -v -keystore release.jks -alias quiz -keyalg RSA -keysize 2048 -validity 10000`
> 2. Add signing config to `android/app/build.gradle.kts`
> 3. Keep the keystore and passwords out of version control

### Web

```bash
flutter build web --release
```

Output: `build/web/`

### Versioning

Version is managed in `pubspec.yaml`:

```yaml
version: 1.2.0   # format: major.minor.patch+buildNumber
```

`versionCode` and `versionName` on Android are derived automatically from this value by the Flutter Gradle plugin.

When releasing:
1. Bump `version` in `pubspec.yaml`
2. Add an entry to `CHANGELOG.md`
3. Commit and tag: `git tag -a vX.Y.Z -m "Release version X.Y.Z"`

---

## AI Configuration

AI features are opt-in. Configure in **Settings → AI**:

| Field | Description |
|-------|-------------|
| Provider | `gemini`, `claude`, or `vertex` |
| API Key | Your API key |
| Base URL | Optional; override for OpenAI-compatible proxies |
| Model | Model ID (e.g. `gemini-2.0-flash`, `claude-opus-4-6`) |

The AI service streams responses. No data is stored server-side — the question stem, choices, and correct answer are sent as a one-shot prompt per request.

---

## Contributing

1. Fork the repository and create a feature branch
2. Follow the existing code style (lint rules in `analysis_options.yaml`)
3. Run `flutter gen-l10n` if you modify any ARB file
4. Test on at least one Android device/emulator before opening a PR
5. Update `CHANGELOG.md` under an `[Unreleased]` heading

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md).
