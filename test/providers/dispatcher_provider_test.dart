import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zxbase_app/core/mock_peers.dart';
import 'package:zxbase_app/providers/blue_vault/blue_vault_provider.dart';
import 'package:zxbase_app/providers/blue_vault/init_provider.dart';
import 'package:zxbase_app/providers/config_provider.dart';
import 'package:zxbase_app/providers/dispatcher_provider.dart';
import 'package:zxbase_app/providers/green_vault/device_provider.dart';
import 'package:zxbase_app/providers/green_vault/green_vault_provider.dart';
import 'package:zxbase_app/providers/green_vault/peer_group_provider.dart';
import 'package:zxbase_app/providers/green_vault/peers_provider.dart';
import 'package:zxbase_app/providers/green_vault/user_vault_provider.dart';
import 'package:zxbase_app/providers/rps_provider.dart';
import 'package:zxbase_app/providers/launch_provider.dart';
import 'package:zxbase_api_client/zxbase_api_client.dart';
import '../helpers.dart';

void main() {
  const pwd = '12345678cC%';

  CustomBindings();
  cleanupDb();
  mockPathProvider();

  var pluginName = 'flutter.baseflow.com/geolocator';

  setUpAll(() {
    // mock geolocator
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(MethodChannel(pluginName), (
          MethodCall methodCall,
        ) async {
          switch (methodCall.method) {
            case 'getCurrentPosition':
              return {'latitude': 52.561270, 'longitude': 5.639382};
            case 'checkPermission':
              return 3; // LocationPermission.always
            case 'isLocationServiceEnabled':
              return true;
            default:
              return true;
          }
        });
  });

  test('Start and stop dispatcher', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // startup sequence
    await container.read(configProvider).init();
    await container.read(blueVaultProvider.notifier).init();
    await container.read(initProvider.notifier).init();
    await container.read(greenVaultProvider.notifier).init(pwd);
    await container.read(deviceProvider.notifier).init();
    await container.read(peersProvider.notifier).init();
    await container.read(peerGroupsProvider.notifier).init();
    await container.read(userVaultProvider.notifier).init();

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

    // register device and obtain access token
    var wizardStageNotifier = container.read(launchProvider.notifier);
    await wizardStageNotifier.registerAnonymous();
    expect(
      container.read(launchProvider).stage,
      equals(LaunchStageEnum.acquiringRegularToken),
    );
    await wizardStageNotifier.accessAnonymous();
    expect(
      container.read(launchProvider).stage,
      equals(LaunchStageEnum.success),
    );

    await mockPeers(container.read(peersProvider.notifier));

    Dispatcher dispatcher = container.read(dispatcherProvider);
    await dispatcher.start();
    expect(dispatcher.state, equals(JobState.started));
    await Future.delayed(const Duration(seconds: 3), () {});

    dispatcher.stop();
    expect(dispatcher.state, equals(JobState.stopped));
    await Future.delayed(const Duration(seconds: 3), () {});
  });
}
