// App configuration provider.

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

enum ConfigState { none, ready }

final configProvider = Provider<Config>((ref) => Config());

class Config {
  ConfigState _state = ConfigState.none;

  final dbSuffix = 'Zxbase';
  final blueVaultSuffix = 'blue';
  final greenVaultSuffix = 'green';

  // environment
  late String rpsHost;
  late int rpsPort;

  late String signalingHost;
  late int signalingPort;

  late String stunHost;
  late int stunPort;

  // platform
  late String appPath;
  late String dbPath;
  late String blueVaultPath;
  late String greenVaultPath;

  Future<void> touchDir(String path) async {
    var dir = Directory(path);
    if (!(await dir.exists())) {
      await dir.create(recursive: true);
    }
  }

  // init to be called by startup sequence
  Future<void> init() async {
    // In tests, default values are not overriden.
    // Keep it alpha to prevent skewing user metrics by test suites.
    if (_state == ConfigState.ready) {
      // don't allow double init
      return;
    }

    rpsHost = const String.fromEnvironment('RPS_HOST');
    rpsPort = const int.fromEnvironment('RPS_PORT');

    signalingHost = const String.fromEnvironment('SIGNALING_HOST');
    signalingPort = const int.fromEnvironment('SIGNALING_PORT');

    stunHost = const String.fromEnvironment('STUN_HOST');
    stunPort = const int.fromEnvironment('STUN_PORT');

    if (Platform.isWindows) {
      appPath = Platform.environment['LOCALAPPDATA']!;
    } else {
      Directory appDir = await getApplicationDocumentsDirectory();
      appPath = appDir.path;
    }

    // create application folders if they don't exist
    dbPath = '$appPath/$dbSuffix';
    await touchDir(dbPath);

    blueVaultPath = '$dbPath/$blueVaultSuffix';
    await touchDir(blueVaultPath);

    greenVaultPath = '$dbPath/$greenVaultSuffix';
    await touchDir(greenVaultPath);

    _state = ConfigState.ready;
  }
}
