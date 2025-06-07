// Green vault is protected by user's password.
// Stores sensitive data.

import 'dart:developer';
import 'package:zxbase_app/providers/config_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_vault/zxbase_vault.dart';

const component = 'greenVaultProvider'; // logging component

final greenVaultProvider = StateNotifierProvider<GreenVaultNotifier, Vault>(
  (ref) => GreenVaultNotifier(ref),
);

class GreenVaultNotifier extends StateNotifier<Vault> {
  GreenVaultNotifier(this.ref)
    : super(Vault(path: ref.read(configProvider).greenVaultPath));
  final Ref ref;

  // called only once during initialization
  Future<bool> init(String pwd) async {
    log('Initializing green vault.', name: component);
    VaultStateEnum rv = await state.init();
    log('Current state is $rv.', name: component);

    if (rv == VaultStateEnum.empty) {
      // setup new vault
      await state.setup(pwd: pwd, id: 'green');
      return true;
    }

    return false;
  }

  Future<bool> open(String pwd) async {
    log('Opening green vault.', name: component);
    VaultStateEnum rv = await state.init();
    log('Current state is $rv.', name: component);

    if (!(await state.open(pwd: pwd))) {
      return false;
    }

    log('Vault is open, state ${state.state}.', name: component);
    return true;
  }
}
