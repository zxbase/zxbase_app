import 'package:zxbase_app/providers/blue_vault/blue_vault_provider.dart';
import 'package:zxbase_app/providers/blue_vault/init_provider.dart';
import 'package:zxbase_app/providers/config_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';
import '../../helpers.dart';

void main() {
  cleanupDb();
  mockPathProvider();

  test('Get the doc from a new vault', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // startup sequence
    await container.read(configProvider).init();
    await container.read(blueVaultProvider.notifier).init();
    await container.read(initProvider.notifier).init();

    // read the doc
    var init = container.read(initProvider);
    expect(init.wizardStage, equals(Init.none));

    // set run state
    bool rv = await container
        .read(initProvider.notifier)
        .setWizardStage(Init.vaultInitialized);
    expect(rv, equals(true));

    // set the theme
    rv = await container.read(initProvider.notifier).setTheme(AppTheme.dark);
    expect(rv, equals(true));

    // read attempts
    int attempts = container.read(initProvider).attempts;
    expect(attempts, equals(0));

    // set attempts
    rv = await container.read(initProvider.notifier).setAttempts(1);
    expect(rv, equals(true));

    // read camera permission
    rv = await container
        .read(initProvider.notifier)
        .setCameraPermissionInfoShowed();
    expect(rv, equals(true));
  });

  test('Get existing doc', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // startup sequence
    await container.read(configProvider).init();
    await container.read(blueVaultProvider.notifier).init();
    await container.read(initProvider.notifier).init();

    // read the doc
    var init = container.read(initProvider);
    expect(init.wizardStage, equals(Init.vaultInitialized));
    expect(init.theme, equals(AppTheme.dark));

    // get state
    var state = container.read(initProvider);
    expect(state.theme, equals(AppTheme.dark));

    // read attempts
    int attempts = container.read(initProvider).attempts;
    expect(attempts, equals(1));
  });
}
