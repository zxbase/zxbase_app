// Init provider implements startup stages.

import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_app/providers/blue_vault/blue_vault_provider.dart';
import 'package:zxbase_app/ui/common/theme.dart';
import 'package:zxbase_vault/zxbase_vault.dart';

const _component = 'initProvider'; // logging component

final initProvider = StateNotifierProvider<InitNotifier, Init>(
  (ref) => InitNotifier(ref),
);

class InitNotifier extends StateNotifier<Init> {
  InitNotifier(this.ref) : super(Init());
  final Ref ref;
  static const _docName = 'init';

  // init has to be called by startup sequence
  Future<void> init() async {
    Doc? doc = await ref.read(blueVaultProvider).getDoc(name: _docName);
    if (doc == null) {
      log('Create new doc.', name: _component);
      await ref
          .read(blueVaultProvider)
          .updateDoc(name: _docName, content: state.toJson(), annotation: {});
    } else {
      log('Load existing doc.', name: _component);
      state = Init.fromJson(doc.content);
    }
  }

  Future<bool> updateDoc(Init newState) async {
    Doc? doc = await ref
        .read(blueVaultProvider)
        .updateDoc(name: _docName, content: newState.toJson(), annotation: {});
    if (doc == null) {
      return false;
    }
    state = newState; // trigger notification
    return true;
  }

  Future<bool> setWizardStage(String val) async {
    Init stateCopy = Init.copy(state);
    stateCopy.wizardStage = val;
    return await updateDoc(stateCopy);
  }

  Future<bool> setTheme(String val) async {
    Init stateCopy = Init.copy(state);
    stateCopy.theme = val;
    return await updateDoc(stateCopy);
  }

  Future<bool> setAttempts(int val) async {
    Init stateCopy = Init.copy(state);
    stateCopy.attempts = val;
    stateCopy.attemptDate = DateTime.now().millisecondsSinceEpoch;
    return await updateDoc(stateCopy);
  }

  Future<bool> setCameraPermissionInfoShowed() async {
    Init stateCopy = Init.copy(state);
    stateCopy.cameraPermissionInfoShowed = true;
    return await updateDoc(stateCopy);
  }
}

// pure data model, nothing provider-related
class Init {
  Init();

  Init.copy(Init copy) {
    wizardStage = copy.wizardStage;
    theme = copy.theme;
    attempts = copy.attempts;
    cameraPermissionInfoShowed = copy.cameraPermissionInfoShowed;
  }

  // doc deserialization
  Init.fromJson(Map<String, dynamic> parsedJson) {
    wizardStage = parsedJson['wizardStage'];
    theme = parsedJson['theme'];
    cameraPermissionInfoShowed =
        parsedJson['cameraPermissionInfoShowed'] ?? false;
    attempts = parsedJson['attempts'] ?? 0;
    attemptDate = parsedJson['attemptDate'] ?? 0;
  }

  // use constants, avoid enums, they are not easy serializable

  // wizard progress stages
  static const none = 'none';
  static const vaultInitialized = 'vaultInitialized';
  static const deviceRegistered = 'deviceRegistered';
  static const completed = 'completed';

  String wizardStage = none;
  String theme = LocalTheme.light;
  int attempts = 0;
  int attemptDate = 0;
  bool cameraPermissionInfoShowed = false;

  // doc serialization
  Map<String, dynamic> toJson() {
    return {
      'wizardStage': wizardStage,
      'theme': theme,
      'attempts': attempts,
      'attemptDate': attemptDate,
      'cameraPermissionInfoShowed': cameraPermissionInfoShowed,
    };
  }
}
