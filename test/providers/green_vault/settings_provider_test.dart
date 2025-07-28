import 'package:zxbase_app/providers/config_provider.dart';
import 'package:zxbase_app/providers/green_vault/green_vault_provider.dart';
import 'package:zxbase_app/providers/green_vault/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers.dart';

void main() {
  const pwd = '12345678cC%';

  cleanupDb();
  mockPathProvider();

  test('Init doc', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // startup sequence
    await container.read(configProvider).init();
    await container.read(greenVaultProvider.notifier).init(pwd);
    await container.read(settingsProvider.notifier).init();

    // read the doc
    var settings = container.read(settingsProvider);
    expect(settings.vaultUpdatePolicy, equals(Settings.manual));

    // update the policy
    await container
        .read(settingsProvider.notifier)
        .setVaultUpdatePolicy(Settings.automatic);
    settings = container.read(settingsProvider);
    expect(settings.vaultUpdatePolicy, equals(Settings.automatic));

    // update the doc
    Settings settingsCopy = Settings.copy(settings);
    settingsCopy.vaultUpdatePolicy = Settings.ignore;
    await container.read(settingsProvider.notifier).update(settingsCopy);
  });

  test('Open doc', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // startup sequence
    await container.read(configProvider).init();
    await container.read(greenVaultProvider.notifier).open(pwd);
    await container.read(settingsProvider.notifier).open();

    // read the doc
    var settings = container.read(settingsProvider);
    expect(settings.vaultUpdatePolicy, equals(Settings.ignore));
  });
}
