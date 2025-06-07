import 'package:zxbase_app/providers/config_provider.dart';
import 'package:zxbase_app/providers/green_vault/device_provider.dart';
import 'package:zxbase_app/providers/green_vault/green_vault_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers.dart';

void main() {
  cleanupDb();
  mockPathProvider();

  const pwd = '12345678cC%';
  String? id;

  test('Init doc', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // startup sequence
    await container.read(configProvider).init();
    await container.read(greenVaultProvider.notifier).init(pwd);
    await container.read(deviceProvider.notifier).init();

    // read the doc
    var device = container.read(deviceProvider);
    expect(device.id, isNot(equals('')));

    // update device
    Device deviceUpdate = Device.copy(device);
    deviceUpdate.metadata = 'meta';
    await container.read(deviceProvider.notifier).update(deviceUpdate);
    id = device.id;

    device = container.read(deviceProvider);
    expect(device.metadata, equals('meta'));
  });

  test('Open doc', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // startup sequence
    await container.read(configProvider).init();
    await container.read(greenVaultProvider.notifier).open(pwd);
    await container.read(deviceProvider.notifier).open();

    // read the doc
    var device = container.read(deviceProvider);
    expect(device.id, equals(id));
    expect(device.metadata, equals('meta'));
  });
}
