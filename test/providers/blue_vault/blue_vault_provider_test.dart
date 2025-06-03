import 'package:zxbase_app/providers/blue_vault/blue_vault_provider.dart';
import 'package:zxbase_app/providers/config_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zxbase_vault/zxbase_vault.dart';
import '../../helpers.dart';

void main() {
  cleanupDb();
  mockPathProvider();

  test('Initialize fresh vault', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(configProvider).init();
    await container.read(blueVaultProvider.notifier).init();
    var blueVault = container.read(blueVaultProvider);
    expect(blueVault.state, equals(VaultStateEnum.ready));
  });

  test('Open existing vault - new startup sequence', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(configProvider).init();
    await container.read(blueVaultProvider.notifier).init();
    var blueVault = container.read(blueVaultProvider);
    expect(blueVault.state, equals(VaultStateEnum.ready));
  });
}
