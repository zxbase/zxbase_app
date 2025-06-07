import 'package:zxbase_app/providers/config_provider.dart';
import 'package:zxbase_app/providers/green_vault/green_vault_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zxbase_vault/zxbase_vault.dart';
import '../../helpers.dart';

void main() {
  cleanupDb();
  mockPathProvider();

  const pwd = '12345678cC%';

  test('Init vault', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(configProvider).init();
    await container.read(greenVaultProvider.notifier).init(pwd);
    var greenVault = container.read(greenVaultProvider);
    expect(greenVault.state, equals(VaultStateEnum.ready));
  });

  test('Open vault', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(configProvider).init();
    await container.read(greenVaultProvider.notifier).open(pwd);
    var greenVault = container.read(greenVaultProvider);
    expect(greenVault.state, equals(VaultStateEnum.ready));
  });
}
