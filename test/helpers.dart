import 'dart:io';
import 'package:zxbase_app/providers/config_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// This is to allow real network calls
// https://github.com/flutter/flutter/issues/77245
class CustomBindings extends AutomatedTestWidgetsFlutterBinding {
  @override
  bool get overrideHttpClient => false;
}

void cleanupDb() {
  Config config = Config();
  // macOS cleanup
  try {
    Directory('./${config.dbSuffix}').deleteSync(recursive: true);
  } catch (_) {}

  // CI cleanup
  try {
    Directory('/root/${config.dbSuffix}').deleteSync(recursive: true); // CI
  } catch (_) {}
}

void mockPathProvider() {
  // mock app doc path for tests
  TestWidgetsFlutterBinding.ensureInitialized();

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall methodCall) async {
          return '.';
        },
      );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider_macos'),
        (MethodCall methodCall) async {
          return '.';
        },
      );
}
