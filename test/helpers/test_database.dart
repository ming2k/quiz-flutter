import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Initializes the test environment for any test that touches [DatabaseService].
///
/// - Mocks the path_provider platform channel so `getApplicationDocumentsDirectory()`
///   returns a temp directory (avoids MissingPluginException in unit tests).
/// - Switches sqflite to the FFI implementation so tests run on desktop without
///   an Android/iOS emulator.
void initTestDatabase() {
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall call) async {
    if (call.method == 'getApplicationDocumentsDirectory') {
      return Directory.systemTemp.path;
    }
    return null;
  });

  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    sqfliteFfiInit();
  }
  databaseFactory = databaseFactoryFfi;
}
