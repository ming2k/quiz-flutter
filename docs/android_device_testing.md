# Android Device Connect & Test

Guide for connecting an Android device and running the Mnema app during development.

## Prerequisites

- Flutter SDK installed and on your `PATH`
- Android SDK with platform tools (includes `adb`)
- USB cable or Wi-Fi connection to the device

## 1. Enable Developer Options on the Device

1. Open **Settings > About phone**
2. Tap **Build number** 7 times until "You are now a developer!" appears
3. Go back to **Settings > System > Developer options**
4. Enable **USB debugging**

## 2. Connect via USB

Plug the device in, then verify it is detected:

```bash
flutter devices
```

You should see your device listed. If it shows as "unauthorized", check the device screen and tap **Allow** on the USB debugging prompt.

If the device is not listed:

```bash
adb devices          # check raw ADB connection
adb kill-server && adb start-server   # restart ADB if stuck
```

### Common USB issues

| Symptom | Fix |
|---------|-----|
| Device not listed | Try a different USB cable/port; ensure the cable supports data transfer |
| "unauthorized" | Accept the RSA key prompt on the device; revoke & re-authorize in Developer options if needed |
| `adb: device offline` | Reconnect USB; toggle USB debugging off/on |

## 3. Connect via Wi-Fi (wireless debugging)

Requires Android 11+ for native wireless debugging:

1. In **Developer options**, enable **Wireless debugging**
2. Tap **Pair device with pairing code**
3. On your machine:

```bash
adb pair <ip>:<pairing-port>    # enter the pairing code when prompted
adb connect <ip>:<connect-port>
```

Then verify with `flutter devices`.

## 4. Run the App

```bash
# Debug build (installs as "Mnema (test)" with ID com.hihusky.mnema.debug)
flutter run

# Release build (installs as "Mnema" with ID com.hihusky.mnema)
flutter run --release
```

Both builds can be installed side-by-side on the same device thanks to the `applicationIdSuffix` in `android/app/build.gradle.kts`.

### Hot reload & restart

While the debug runner is active:

| Key | Action |
|-----|--------|
| `r` | Hot reload (preserves state) |
| `R` | Hot restart (resets state) |
| `v` | Open DevTools in browser |
| `p` | Toggle widget inspector overlay |
| `q` | Quit |

## 5. Run Tests

### Unit & widget tests

```bash
flutter test
```

### Integration tests (on-device)

If integration tests exist under `integration_test/`:

```bash
flutter test integration_test/
```

This runs the tests on the connected device or emulator.

### Run a specific test file

```bash
flutter test test/some_test.dart
```

## 6. Inspect & Debug

```bash
# View device logs filtered to the app
adb logcat -s flutter

# Take a screenshot
adb exec-out screencap -p > screenshot.png

# Install a pre-built APK manually
adb install build/app/outputs/flutter-apk/app-debug.apk

# Uninstall debug build
adb uninstall com.hihusky.mnema.debug

# Uninstall release build
adb uninstall com.hihusky.mnema
```

## 7. Using an Emulator

If you don't have a physical device:

```bash
# List available emulator images
flutter emulators

# Launch an emulator
flutter emulators --launch <emulator_id>

# Then run as usual
flutter run
```

To create an emulator, use Android Studio's **AVD Manager** or:

```bash
avdmanager create avd -n pixel_6 -k "system-images;android-34;google_apis;x86_64"
```
