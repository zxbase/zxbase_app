import 'package:zxbase_app/providers/config_provider.dart';
import 'package:zxbase_app/providers/green_vault/device_provider.dart';
import 'package:zxbase_app/providers/green_vault/green_vault_provider.dart';
import 'package:zxbase_app/providers/rps_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zxbase_api_client/zxbase_api_client.dart';
import '../helpers.dart';

// This is to allow real network calls
// https://github.com/flutter/flutter/issues/77245
class CustomBindings extends AutomatedTestWidgetsFlutterBinding {
  @override
  bool get overrideHttpClient => false;
}

void main() {
  CustomBindings();
  final container = ProviderContainer();
  const pwd = '12345678cC%';

  cleanupDb();
  mockPathProvider();

  test('Validate RPS provider is a singleton', () async {
    var rps = container.read(rpsProvider);
    var rps2 = container.read(rpsProvider);
    expect(identityHashCode(rps2), equals(identityHashCode(rps)));
  });

  test('Check rps works with startup sequence', () async {
    // startup sequence
    await container.read(configProvider).init();
    await container.read(greenVaultProvider.notifier).init(pwd);
    await container.read(deviceProvider.notifier).init();
    Device device = container.read(deviceProvider);

    RpsClient rpsClient = container.read(rpsProvider);
    rpsClient.init(
      host: container.read(configProvider).rpsHost,
      port: container.read(configProvider).rpsPort,
      identity: device.identity,
      keyPair: device.identityKeyPair,
    );

    await rpsClient.obtainToken(topic: 'registration');
    expect(rpsClient.token, isNot(equals(null)));
  });
}
