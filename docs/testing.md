# Mnema Testing Guide

> This guide is for developers, testers, and contributors, covering the complete workflow from environment setup to real-device testing on all supported platforms.

---

## 1. Quick Start: Run Existing Tests First

Before diving into testing, make sure all existing tests pass:

```bash
cd /path/to/mnema
flutter test
```

**Expected output:**
```
28 tests passed
```

> Note: The two integration tests in `ai_service_test.dart` require the environment variable `GEMINI_API_KEY` or `KIMI_API_KEY`. They will be automatically skipped if not set, which does not affect the overall result.

---

## 2. Environment Setup

### 2.1 Required Tools

| Tool | Version Requirement | Purpose |
|------|---------------------|---------|
| Flutter SDK | >= 3.10.4 | Build and run |
| Dart | Bundled with Flutter | Run tests |
| Android SDK | API 21+ | Android build |
| JDK | 17 | Android Gradle compilation |

Verify the environment:

```bash
flutter doctor -v
```

**Key check items:**
- [x] Flutter (Channel stable)
- [x] Android toolchain - develop for Android devices
- [x] Linux toolchain - develop for Linux desktop (debugging only; see Wayland caveat below)
- [x] Android Studio / IntelliJ (for emulator management)

### 2.2 Supported Platforms

| Platform | Status | Note |
|----------|--------|------|
| **Android** | ✅ Primary platform | Real device + emulator |
| **Linux Desktop** | ⚠️ Supported with caveats | See below for GTK/X11 dependency issues on Wayland-only systems |
| **iOS** | ❌ Not configured | No `ios/` directory, not supported yet |
| **Web** | ❌ Not verified | No `web/` directory configured |
| **Windows/macOS** | ❌ Not configured | No corresponding platform directories |

### 2.3 Clone the Project

```bash
git clone <repo-url>
cd mnema
flutter pub get
```

---

## 3. Desktop Testing (Linux)

The Linux desktop target can be used for quick UI debugging, but **Android is the primary development and release platform**. It starts fast and hot reloads fast, which is useful for layout adjustments. However, some features (haptics, audio, gestures) cannot be fully verified on desktop.

### 3.1 Run Desktop Version

```bash
# Make sure Linux desktop support is enabled
flutter config --enable-linux-desktop

# Run
flutter run -d linux
```

### 3.2 What to Test on Desktop

| Test Item | Method | Expected Result |
|-----------|--------|-----------------|
| Home quiz list | Observe directly after launch | Displays imported quiz cards with question count and SRS statistics |
| Question rendering | Enter practice mode | Markdown, LaTeX, and images display correctly |
| AI settings | Settings → AI Provider | Gemini / Kimi switch works, model list updates dynamically |
| Import Package | Home → Import button | Select `.zip` and import successfully, displayed in the list |
| Review mode | Tap the 🧠 button on a quiz card | Hide answer → Show answer → Rating button flow works |
| Keyboard shortcuts | Press keys in practice mode | A/B/C/D to select answers, arrow keys to switch questions, Enter to submit |
| Dark / Light theme | Toggle in settings | Global theme switches correctly |
| Multilingual | Toggle Chinese / English in settings | UI text switches correctly |

### 3.3 Desktop Build Caveats

> **GTK / Wayland Compatibility**
>
> The Linux build depends on GTK3. On distributions where GTK3 is compiled without X11 support (common on pure Wayland setups), the build will fail with linker errors related to missing X11 libraries. This is a system-level GTK dependency, not a project bug.
>
> **Workarounds:**
> - Use an Android emulator or real device for development.
> - Ensure XWayland is available if you must build for Linux.

### 3.4 Desktop Limitations

The following features **cannot be fully tested** on desktop and must be verified on an Android real device:

- File import dialog style (desktop uses system file picker, Android uses a third-party one)
- Haptic feedback (`vibration` plugin)
- Audio playback (`audioplayers` may behave differently on desktop)
- Font rendering and DPI adaptation
- Gesture operations (swipe to switch questions, pinch to zoom)

---

## 4. Android Testing

Android is the primary target platform for this project. Testing is divided into **emulator** and **real device** methods.

### 4.1 Using Emulator (AVD)

Suitable for quick verification when no physical device is available:

```bash
# List available emulators
flutter emulators

# Launch emulator (e.g., Pixel 6 API 34)
flutter emulators --launch Pixel_6_API_34

# Wait for the emulator to fully start, then run
flutter run
```

**Recommended emulator configuration:**
- Device: Pixel 6 or Pixel Tablet (to test different screen sizes)
- System image: Android 13/14 (API 33/34)
- Architecture: x86_64 (with Google APIs)

### 4.2 Using Real Device (USB / Wi-Fi)

Real device testing is mandatory; the emulator cannot fully replace it:

**USB connection:**
```bash
# 1. Enable Developer options + USB debugging on the phone
# 2. Connect to computer and authorize debugging
# 3. Verify connection
flutter devices

# 4. Run
flutter run
```

**Wi-Fi debugging (Android 11+):**
```bash
# 1. Enable Developer options → Wireless debugging on the phone
# 2. Pair
adb pair <IP>:<PORT>

# 3. Connect
adb connect <IP>:<PORT>

# 4. Run
flutter run
```

For detailed steps, refer to: `docs/android_device_testing.md`

### 4.3 Build Release APK for Distribution Testing

When distributing to testers or users, a Release APK needs to be built:

```bash
# Build Release APK
flutter build apk --release

# Output path
# build/app/outputs/flutter-apk/app-release.apk

# Install to a connected device
adb install build/app/outputs/flutter-apk/app-release.apk
```

> **Note:** The current `build.gradle.kts` uses Debug signing for Release builds. It must be replaced with an official signing configuration before formal distribution.

### 4.4 Debug vs Release Build Differences

| Feature | Debug (`flutter run`) | Release (`--release`) |
|---------|-----------------------|------------------------|
| App name | Mnema (test) | Mnema |
| Package name | `com.hihusky.mnema.debug` | `com.hihusky.mnema` |
| Performance | Slow (debuggable) | Fast (optimized) |
| Hot reload | ✅ Supported | ❌ Not supported |
| Side-by-side install | ✅ Debug and Release can be installed simultaneously | - |

---

## 5. Functional Testing Checklist

### 5.1 Core Features

#### Quiz Management
- [ ] Sample quizzes are automatically imported on first launch
- [ ] Home page displays all quiz cards (with question count and SRS statistics)
- [ ] Quiz cards can be dragged to reorder
- [ ] Swipe left to delete a quiz
- [ ] Import `.zip` / `.quizpkg` packages
- [ ] Import a package containing images, images display correctly
- [ ] Clear error message is shown when importing a corrupted package

#### Practice Mode
- [ ] After answering a multiple-choice question, correct answer and explanation are shown
- [ ] Auto-jump to next question (toggleable in settings)
- [ ] Favorite / unfavorite a question
- [ ] Keyboard shortcuts (A/B/C/D / arrow keys / Enter / Y / X)
- [ ] Chapter filter works correctly
- [ ] Overview grid shows answer status colors

#### Test Mode
- [ ] Enter test with 50 questions selected
- [ ] Answers are hidden during the test
- [ ] Score report is shown after completing the test
- [ ] Test history is viewable

#### Review Mode (SRS / Flashcards)
- [ ] Tap 🧠 to enter review
- [ ] Only show the question stem, hide options at first
- [ ] After tapping "Show Answer", display full content
- [ ] Bottom rating buttons (Again / Hard / Good / Easy)
- [ ] Proceed to next question after rating
- [ ] Show completion screen after all cards are reviewed
- [ ] SRS statistics badge on home page updates in real time

#### AI Features
- [ ] Works correctly after configuring Gemini API Key
- [ ] Works correctly after configuring Kimi API Key
- [ ] AI parses question context correctly
- [ ] Streaming response without lag
- [ ] Multi-turn conversation history is saved
- [ ] Model resets automatically when switching AI Provider

### 5.2 Data Persistence

- [ ] After killing the app and reopening, answer records are preserved
- [ ] After killing the app and reopening, favorite status is preserved
- [ ] After killing the app and reopening, SRS review status is preserved
- [ ] After switching quizzes and returning, last position is restored
- [ ] After resetting progress, answer records are cleared but favorites are preserved

### 5.3 Edge Cases

- [ ] Empty quiz import is handled gracefully
- [ ] Questions without options (reading comprehension passage) are filtered correctly
- [ ] Scroll performance for extra-long question stems and explanations
- [ ] Friendly error is shown when calling AI without network
- [ ] AI button is disabled or prompts when no API Key is configured

---

## 6. Integration Testing

### 6.1 AI Service Integration Test

Requires a real API Key:

```bash
# Gemini test
export GEMINI_API_KEY=your_key
flutter test test/ai_service_test.dart

# Kimi test
export KIMI_API_KEY=your_key
flutter test test/ai_service_test.dart
```

Test content:
- Stream returns non-empty response
- Response contains keywords (e.g., `collision`)
- Response contains Markdown bold markers

### 6.2 Package Format Test

```bash
flutter test test/package_test.dart
```

Test content:
- All `.zip` packages under `output/` have valid structure
- JSON in each package is parseable
- All questions contain valid options and answers
- Image references match actual files

### 6.3 SRS Algorithm Test

```bash
flutter test test/srs_service_test.dart
```

Test content:
- SM-2 algorithm interval calculation under various ratings
- Ease factor boundary clamp behavior
- Human-readable formatting of interval labels

---

## 7. Performance Testing

### 7.1 Startup Time

```bash
# Use --trace-startup to collect startup data
flutter run --trace-startup --profile
```

Focus points:
- Cold start to home page interactive < 3 seconds (Release mode)
- Sample package import on first launch does not block the UI

### 7.2 Large Quiz Loading

Use `output/navigation.zip` (3641 questions) for testing:

- [ ] Import 3000+ questions without crashing
- [ ] Home page scrolling is smooth, no stuttering
- [ ] Overview grid loads in < 1 second
- [ ] Switching chapters responds quickly

### 7.3 Memory Check

```bash
# After connecting the device, check memory
adb shell dumpsys meminfo com.hihusky.mnema.debug

# Or use Flutter DevTools
flutter run --observatory-port=9200
# Then open DevTools in the browser
```

Focus points:
- Memory growth < 50MB after browsing 100 questions continuously
- Stream resources are properly released after AI chat ends
- Old quiz data is properly unloaded after switching quizzes

---

## 8. Compatibility Testing

### 8.1 Android Version Compatibility

| API Level | Version | Priority | Test Items |
|-----------|---------|----------|------------|
| 34 | Android 14 | P0 | Primary development target |
| 33 | Android 13 | P0 | Mainstream devices |
| 31 | Android 12 | P1 | Newer devices |
| 28 | Android 9 | P1 | Low-end devices |
| 21 | Android 5 | P2 | minSdk, basic functional verification |

### 8.2 Screen Size Compatibility

- [ ] Small phones (under 5.5 inches, e.g., Pixel 4a)
- [ ] Standard phones (6-6.7 inches, e.g., Pixel 6/7)
- [ ] Tablets (10-11 inches, e.g., Pixel Tablet / Samsung Tab)
- [ ] Landscape / portrait switching

### 8.3 Dark Mode

- [ ] All pages display correctly in system dark mode
- [ ] Markdown code blocks and LaTeX formulas are readable in dark mode
- [ ] Images and charts are not glaring in dark mode

---

## 9. Test Automation Recommendations

### 9.1 CI/CD Pipeline (GitHub Actions Example)

```yaml
# .github/workflows/test.yml
name: Test
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
      - run: flutter build apk --release
```

### 9.2 Manual Test Regression Checklist

Before each release, manually verify according to the following checklist:

```
[ ] All `flutter test` tests pass
[ ] Linux desktop version launches normally (see README for Wayland caveats)
[ ] Android Debug version installs and runs normally
[ ] Android Release version installs and runs normally
[ ] Import 1 Package successfully
[ ] Practice mode answers 5 questions normally
[ ] Review mode completes 3 questions normally
[ ] AI parsing returns content normally
[ ] Data is preserved after killing and restarting the app
[ ] No display anomalies in dark mode
```

---

## 10. Common Issues Troubleshooting

### Q1: `flutter run` prompts "No supported devices connected"

```bash
# List available devices
flutter devices

# If no device, launch an emulator
flutter emulators --launch <id>

# Or check ADB
adb devices
```

### Q2: Images not showing on emulator

The emulator may lack certain image decoding libraries. This is usually normal on real devices. If it persists, check whether image format plugins in `pubspec.yaml` are complete.

### Q3: `sqflite`-related errors during testing

Linux desktop requires system sqlite3:
```bash
# Ubuntu/Debian
sudo apt-get install libsqlite3-dev

# Or configure to use bundled sqlite3 in pubspec.yaml
```

### Q4: AI tests in `flutter test` are always skipped

This is expected. Integration tests require a real API Key:
```bash
export GEMINI_API_KEY=sk-xxx
export KIMI_API_KEY=sk-xxx
flutter test test/ai_service_test.dart
```

### Q5: Release APK crashes after installation

Check whether the `INTERNET` permission is missing (AI features require network):
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.INTERNET" />
```

### Q6: Importing Package shows "Package validation failed"

Fix `data.json` according to the error message:
- `Answer "X" does not match any choice key` → Check whether the answer matches a key in choices
- `Missing or empty chapters array` → Ensure chapters is not empty
- `Missing or empty subject_name_zh` → Add a Chinese name

---

## 11. Testing Resources

### Test Packages

The project comes with a sample package. You can also use the official packages in the `output/` directory for testing:

```bash
# Use official packages to test import functionality
ls output/*.zip
# maritime-english.zip
# navigation.zip
# ship-management.zip
# ship-maneuvering-collision-avoidance.zip
# ship-structure-cargo.zip
```

### Minimal Test Data

If you need to quickly construct a test package, create the following structure:

```bash
mkdir -p /tmp/test-quiz/images
cat > /tmp/test-quiz/data.json << 'EOF'
{
  "protocol_version": "2.0",
  "subject_name_zh": "Test Quiz",
  "subject_name_en": "test-quiz",
  "chapters": [
    {
      "title": "Chapter 1",
      "sections": [
        {
          "title": "Section 1.1",
          "questions": [
            {
              "content": "1 + 1 = ?",
              "choices": [
                {"key": "A", "content": "1"},
                {"key": "B", "content": "2"},
                {"key": "C", "content": "3"}
              ],
              "answer": "B",
              "explanation": "Basic arithmetic.",
              "tags": ["math", "basics"],
              "difficulty": 1.0
            }
          ]
        }
      ]
    }
  ]
}
EOF
cd /tmp/test-quiz && zip -r test-quiz.zip data.json images/
```
