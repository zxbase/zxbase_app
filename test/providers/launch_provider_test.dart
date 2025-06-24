import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zxbase_api_client/zxbase_api_client.dart';
import 'package:zxbase_app/providers/blue_vault/blue_vault_provider.dart';
import 'package:zxbase_app/providers/blue_vault/init_provider.dart';
import 'package:zxbase_app/providers/config_provider.dart';
import 'package:zxbase_app/providers/green_vault/device_provider.dart';
import 'package:zxbase_app/providers/green_vault/green_vault_provider.dart';
import 'package:zxbase_app/providers/rps_provider.dart';
import 'package:zxbase_app/providers/launch_provider.dart';
import '../helpers.dart';

// Allow real network calls
// https://github.com/flutter/flutter/issues/77245
class CustomBindings extends AutomatedTestWidgetsFlutterBinding {
  @override
  bool get overrideHttpClient => false;
}

void main() {
  const pwd = '12345678cC%';

  CustomBindings();

  cleanupDb();
  mockPathProvider();

  test('Execute workflows', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // startup sequence
    await container.read(configProvider).init();
    await container.read(blueVaultProvider.notifier).init();
    await container.read(initProvider.notifier).init();
    await container.read(greenVaultProvider.notifier).init(pwd);
    await container.read(deviceProvider.notifier).init();

    Config conf = container.read(configProvider);
    Device device = container.read(deviceProvider);

    // initialize RPS (API) client
    RpsClient rps = container.read(rpsProvider);
    rps.init(
      host: conf.rpsHost,
      port: conf.rpsPort,
      identity: device.identity,
      keyPair: device.identityKeyPair,
    );

    // execute registration workflow
    var wizardStageNotifier = container.read(launchProvider.notifier);
    await wizardStageNotifier.registerAnonymous();
    expect(
      container.read(launchProvider).stage,
      equals(LaunchStageEnum.acquiringRegularToken),
    );

    // execute access workflow
    await wizardStageNotifier.accessAnonymous();
    expect(
      container.read(launchProvider).stage,
      equals(LaunchStageEnum.success),
    );
  });
}
