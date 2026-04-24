# Mnema

Mnema is a general, extensible learning framework built with Flutter. Supports multiple study modes, AI-powered explanations, Markdown/LaTeX rendering, and a custom quiz package format.

## Features

- **Multiple study modes** — Practice, Review (SRS), and timed Test
- **AI explanations** — Streaming chat powered by Gemini, Kimi, or any OpenAI-compatible endpoint
- **Rich content** — Markdown and LaTeX (via `flutter_math_fork`) in questions and explanations
- **Study packages** — Import `.zip` / `.mnemapkg` files; a sample package is bundled at first launch
- **Progress tracking** — SQLite-backed per-question history, test results, and streaks
- **SRS / Spaced Repetition** — SM-2 algorithm with four rating levels
- **i18n** — English and Chinese (Simplified); follows system locale by default
- **Theming** — Light / Dark / System, Material 3 color roles throughout
- **Feedback** — Modular sound & haptic system with streak escalation

📖 See [`docs/features.md`](docs/features.md) for a detailed feature overview and roadmap.

---

## Documentation

| Document | Audience | Content |
|----------|----------|---------|
| [`docs/features.md`](docs/features.md) | Users & Developers | Feature overview, roadmap |
| [`docs/design/`](docs/design/README.md) | Developers & Designers | Learning-mode, question-type, question-structure, and collection design |
| [`docs/design_system.md`](docs/design_system.md) | Developers & Designers | Colors, typography, spacing, icons, empty states |
| [`docs/ui_guidelines.md`](docs/ui_guidelines.md) | Developers | Coding standards for UI/UX |
| [`docs/srs_algorithm.md`](docs/srs_algorithm.md) | Users & Developers | SM-2 spaced repetition explanation |
| [`docs/architecture.md`](docs/architecture.md) | Developers | Technical architecture |
| [`docs/package_creator_guide.md`](docs/package_creator_guide.md) | Content Creators | Step-by-step guide to creating and sharing packages |
| [`docs/package_protocol.md`](docs/package_protocol.md) | Content Creators & Tool Developers | Technical package format specification |
| [`docs/package_schema.json`](docs/package_schema.json) | Tool Developers | JSON Schema for automated validation |
| [`docs/ai_integration.md`](docs/ai_integration.md) | Developers | AI provider integration |
| [`docs/testing.md`](docs/testing.md) | Developers | Testing guide |

## Getting Started

### Prerequisites

| Tool | Version |
|------|---------|
| Flutter | ≥ 3.10 |
| Dart | ≥ 3.10 |
| Android SDK | API 21+ (minSdk) |

Install Flutter: https://docs.flutter.dev/get-started/install

### Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| **Android** | ✅ Primary target | All features are designed and tested for Android |
| **Linux Desktop** | ⚠️ Available for debugging only | See warning below |
| **iOS / Web / Windows / macOS** | ❌ Not supported | No platform directories configured |

> **Linux Desktop Warning**
>
> The Linux desktop target is retained for local debugging convenience, but **Android is the primary development focus**.
>
> Building for Linux requires GTK3, which on some distributions is compiled with an **X11 dependency**. If you are on a **pure Wayland** environment (no XWayland, or a GTK build without X11 support), the build will fail during the linking phase with errors related to missing X11 libraries. This is a system-level GTK limitation, not a project bug.
>
> If you encounter this, either run under XWayland or switch to an Android emulator / real device for development.

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
| Debug | `com.hihusky.mnema.debug` | Mnema (test) |
| Release | `com.hihusky.mnema` | Mnema |

This is set in `android/app/build.gradle.kts`:

```kotlin
buildTypes {
    debug {
        applicationIdSuffix = ".debug"
        resValue("string", "app_name", "Mnema (test)")
    }
    release {
        resValue("string", "app_name", "Mnema")
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
  providers/                 # SettingsProvider, StudyProvider
  screens/                   # HomeScreen, StudyScreen, SettingsScreen, TestResultScreen
  services/                  # DatabaseService, PackageService, AiService, …
  theme/                     # AppTheme (light/dark, Material 3)
  utils/                     # ToastUtils, …
  widgets/                   # Reusable widgets (AiChatPanel, OverviewSheet, …)
  l10n/                      # ARB files + generated localizations
assets/
  sounds/                    # Streak / wrong-answer audio
  packages/                  # sample-package.zip (bundled, auto-imported on first launch)
```

---

## Package Format

A package is a `.zip` (or `.mnemapkg`) archive that contains a `data.json` file at its root (or one directory level deep — the app flattens the structure automatically).

### Quick authoring workflow

```bash
# 1. Create a folder with data.json and optional images/
mkdir my-quiz && cd my-quiz
# ... edit data.json ...

# 2. Validate
python tools/validate_package.py data.json

# 3. Build the distributable ZIP
python tools/build_package.py . ../output

# 4. Re-validate the final package
python tools/validate_package.py ../output/my-quiz.zip
```

See [`docs/package_creator_guide.md`](docs/package_creator_guide.md) for the full tutorial, and [`examples/minimal-package/`](examples/minimal-package/) for a working example covering all question types.

### `data.json` schema (minimal example)

```jsonc
{
  "protocol_version": "2.0",
  "subject_name_zh": "示例题库",
  "subject_name_en": "sample-package",
  "chapters": [
    {
      "title": "Chapter 1",
      "sections": [
        {
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

Choice text supports **Markdown** and **LaTeX** (`$...$` inline, `$$...$$` block). Images are referenced with standard Markdown syntax and placed in an `images/` folder inside the ZIP.

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
| Provider | `gemini` or `vertex` |
| API Key | Your API key |
| Base URL | Optional; override for OpenAI-compatible proxies |
| Model | Model ID (e.g. `gemini-3.1-flash-lite-preview`) |

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
