// Sensitive user settings.

import 'dart:developer';
import 'package:zxbase_app/providers/green_vault/green_vault_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_vault/zxbase_vault.dart';

const _comp = 'settingsProvider'; // logging component

final settingsProvider = StateNotifierProvider<SettingsNotifier, Settings>(
  (ref) => SettingsNotifier(ref),
);

class SettingsNotifier extends StateNotifier<Settings> {
  SettingsNotifier(this.ref) : super(Settings());
  final Ref ref;
  static const _docName = 'settings';

  // called only during initialization
  Future init() async {
    log('Create doc.', name: _comp);
    await ref
        .read(greenVaultProvider)
        .updateDoc(name: _docName, content: state.toJson(), annotation: {});
  }

  Future open() async {
    Doc? doc = await ref.read(greenVaultProvider).getDoc(name: _docName);
    state = Settings.fromJson(doc!.content);
    log('Loaded doc.', name: _comp);
  }

  // For notification to happen, passed object should be different from state object.
  Future<bool> update(Settings newState) async {
    Doc? doc = await ref
        .read(greenVaultProvider)
        .updateDoc(name: _docName, content: newState.toJson(), annotation: {});
    if (doc == null) {
      return false;
    }
    state = newState;
    return true;
  }

  Future<bool> setVaultUpdatePolicy(String policy) async {
    Settings stateCopy = Settings.copy(state);
    stateCopy.vaultUpdatePolicy = policy;
    return await update(stateCopy);
  }
}

class Settings {
  Settings();

  // copy constructor
  Settings.copy(Settings copy) {
    vaultUpdatePolicy = copy.vaultUpdatePolicy;
  }

  // doc deserialization
  Settings.fromJson(Map<String, dynamic> json) {
    vaultUpdatePolicy = json['vaultUpdatePolicy'] ?? automatic;
  }

  // update policy
  static const automatic = 'automatic';
  static const manual = 'manual';
  static const ignore = 'ignore';
  String vaultUpdatePolicy = automatic;

  // doc serialization
  Map<String, dynamic> toJson() {
    return {'vaultUpdatePolicy': vaultUpdatePolicy};
  }
}
