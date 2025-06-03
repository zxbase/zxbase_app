// Blue vault is used for bookkeeping only.
// No sensitive data to be stored here.

import 'dart:developer';
import 'package:zxbase_app/providers/config_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_vault/zxbase_vault.dart';

const _component = 'blueVaultProvider'; // logging component

final blueVaultProvider = StateNotifierProvider<BlueVaultNotifier, Vault>(
  (ref) => BlueVaultNotifier(ref),
);

class BlueVaultNotifier extends StateNotifier<Vault> {
  BlueVaultNotifier(this.ref)
    : super(Vault(path: ref.read(configProvider).blueVaultPath));
  final Ref ref;

  Future<void> init() async {
    log('Initializing blue vault.', name: _component);
    VaultStateEnum rv = await state.init();

    log('Current state is $rv.', name: _component);
    if (rv == VaultStateEnum.empty) {
      await state.setup(pwd: ref.read(configProvider).blueVaultPwd, id: 'blue');
    } else {
      await state.open(pwd: ref.read(configProvider).blueVaultPwd);
    }

    log('Initialized, state ${state.state}.', name: _component);
  }
}
