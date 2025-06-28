import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zxbase_app/providers/config_provider.dart';
import 'package:zxbase_app/providers/green_vault/green_vault_provider.dart';
import 'package:zxbase_app/providers/green_vault/peer_group_provider.dart';
import '../../helpers.dart';

void main() {
  const pwd = '12345678cC%';

  cleanupDb();
  mockPathProvider();
  // Vault doc is added when application is already in production.
  // Test opening non-existing doc.
  test('Open doc after upgrade', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // green vault has been already initialized
    await container.read(configProvider).init();
    await container.read(greenVaultProvider.notifier).init(pwd);

    PeerGroupsNotifier peerGroupsNotifier = container.read(
      peerGroupsProvider.notifier,
    );
    await peerGroupsNotifier.open();

    // read the doc
    var userVault = container.read(peerGroupsProvider);
    expect(userVault.groups.length, equals(1));
  });

  test('Open doc again', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // startup sequence
    await container.read(configProvider).init();
    await container.read(greenVaultProvider.notifier).open(pwd);
    PeerGroupsNotifier userVaultNotifier = container.read(
      peerGroupsProvider.notifier,
    );
    await userVaultNotifier.open();

    // read the doc
    var userVault = container.read(peerGroupsProvider);
    expect(userVault.groups.length, equals(1));
  });
}
