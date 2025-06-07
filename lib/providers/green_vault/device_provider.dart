// Device data, including identity and keys.

import 'dart:convert';
import 'dart:developer';
import 'package:zxbase_app/providers/green_vault/green_vault_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:zxbase_crypto/zxbase_crypto.dart';
import 'package:zxbase_model/zxbase_model.dart';
import 'package:zxbase_vault/zxbase_vault.dart';

const _component = 'deviceProvider'; // logging component

final deviceProvider = StateNotifierProvider<DeviceNotifier, Device>(
  (ref) => DeviceNotifier(ref),
);

class DeviceNotifier extends StateNotifier<Device> {
  DeviceNotifier(this.ref) : super(Device(owner: '', name: ''));
  final Ref ref;
  static const _docName = 'device';

  // called only during vault initialization
  Future<void> init() async {
    log('Create doc.', name: _component);
    await state.init();
    await ref
        .read(greenVaultProvider)
        .updateDoc(
          name: _docName,
          content: await state.toJson(),
          annotation: {},
        );
  }

  Future open() async {
    Doc? doc = await ref.read(greenVaultProvider).getDoc(name: _docName);
    await state.fromJson(doc!.content);
    log('Loaded doc.', name: _component);
  }

  // For notification to happen, passed object should be different from state object.
  Future<bool> update(Device newState) async {
    Doc? doc = await ref
        .read(greenVaultProvider)
        .updateDoc(
          name: _docName,
          content: await newState.toJson(),
          annotation: {},
        );
    if (doc == null) {
      return false;
    }
    state = newState;
    return true;
  }
}

class Device {
  Device({required this.owner, required this.name});
  Device.copy(Device copy) {
    owner = copy.owner;
    name = copy.name;
    id = copy.id;
    identityKeyPair = copy.identityKeyPair;
    identity = copy.identity;
    metadata = copy.metadata;
  }

  late String owner;
  late String name;
  late String id;
  late SimpleKeyPair identityKeyPair;
  late Identity identity;
  late String metadata; // for future use

  Future<void> init() async {
    id = const Uuid().v4();
    identityKeyPair = await PKCrypto.generateKeyPair();
    SimplePublicKey pubK = await identityKeyPair.extractPublicKey();
    identity = Identity(deviceId: id, publicKey: pubK);
    metadata = '';
  }

  // model serialization
  Future<Map<String, dynamic>> toJson() async {
    return {
      'owner': owner,
      'name': name,
      'id': id,
      'identityKeyPair': jsonEncode(
        await PKCrypto.keyPairToJwk(identityKeyPair),
      ),
      'identity': identity.toBase64Url(),
      'metadata': metadata,
    };
  }

  // model deserialization
  Future<void> fromJson(Map<String, dynamic> parsedJson) async {
    owner = parsedJson['owner'];
    name = parsedJson['name'];
    id = parsedJson['id'];
    identityKeyPair = await PKCrypto.jwkToKeyPair(
      jsonDecode(parsedJson['identityKeyPair']),
    );
    identity = Identity.fromBase64Url(parsedJson['identity']);
    metadata = parsedJson['metadata'];
  }
}
