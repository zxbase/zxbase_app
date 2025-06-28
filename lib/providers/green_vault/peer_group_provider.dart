// Peer groups provider.
// Id -> PeerGroup
//   - name (unique)
//   - type
//   - policy
//   - managed
//   - peers
//     - Id, revision, date, updatedAt

import 'dart:convert';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zxbase_app/core/const.dart';
import 'package:zxbase_app/core/rv.dart';
import 'package:zxbase_app/providers/green_vault/green_vault_provider.dart';
import 'package:zxbase_vault/zxbase_vault.dart';

const _comp = 'peerGroupsProvider'; // logging component
const vaultGroupId = '_vault'; // internal names start with _

final peerGroupsProvider =
    StateNotifierProvider<PeerGroupsNotifier, PeerGroups>(
      (ref) => PeerGroupsNotifier(ref),
    );

class PeerGroupsNotifier extends StateNotifier<PeerGroups> {
  PeerGroupsNotifier(this.ref) : super(PeerGroups());
  final Ref ref;
  DocMeta? meta;
  static const _docName = 'peerGroups';

  Future<void> init() async {
    log('Create doc.', name: _comp);
    await createVaultGroup();
    Doc? doc = await ref
        .read(greenVaultProvider)
        .updateDoc(name: _docName, content: state.toJson(), annotation: {});
    meta = doc!.meta;
  }

  Future<void> open() async {
    Doc? doc = await ref.read(greenVaultProvider).getDoc(name: _docName);
    if (doc == null) {
      await init();
    } else {
      state = PeerGroups.fromJson(doc.content);
      meta = doc.meta;
      log('Loaded doc.', name: _comp);
    }
  }

  Future<bool> _updateDoc(PeerGroups newState) async {
    Doc? doc = await ref
        .read(greenVaultProvider)
        .updateDoc(name: _docName, content: newState.toJson(), annotation: {});
    if (doc == null) {
      log('Failed to update vault doc.', name: _comp);
      return false;
    }
    meta = doc.meta;
    return true;
  }

  // get save-to-update copy of group
  PeerGroup? copyGroup({required String id}) {
    if (!state.groups.containsKey(id)) {
      return null;
    }

    return PeerGroup.fromJson(json.decode(json.encode(state.groups[id])));
  }

  PeerGroup copyVaultGroup() {
    return copyGroup(id: vaultGroupId)!;
  }

  Future<RV> createGroup(PeerGroup group) async {
    for (PeerGroup val in state.groups.values) {
      if (group.id == val.id) {
        return RV.entryExists;
      }

      if (group.name == val.name) {
        return RV.nameExists;
      }
    }

    log('Adding entry ${group.id}.', name: _comp);
    PeerGroups stateCopy = PeerGroups.copy(state);
    stateCopy.groups[group.id] = group;
    state = stateCopy; // trigger notification
    return await _updateDoc(stateCopy) ? RV.ok : RV.io;
  }

  Future<RV> createVaultGroup() async {
    PeerGroup group = PeerGroup(id: vaultGroupId, type: typeVault);
    return await createGroup(group);
  }

  Future<RV> updateGroup(PeerGroup entry) async {
    if (!state.groups.containsKey(entry.id)) {
      return RV.notFound;
    }
    log('Updating entry ${entry.name}.', name: _comp);
    PeerGroups stateCopy = PeerGroups.copy(state);
    stateCopy.groups[entry.id] = entry;
    state = stateCopy; // trigger notification
    return await _updateDoc(stateCopy) ? RV.ok : RV.io;
  }

  Future<RV> deleteGroup({required String id}) async {
    if (!state.groups.containsKey(id)) {
      return RV.notFound;
    }
    log('Deleting entry $id.', name: _comp);
    PeerGroups stateCopy = PeerGroups.copy(state);
    stateCopy.groups.remove(id);
    state = stateCopy; // trigger notification
    return await _updateDoc(stateCopy) ? RV.ok : RV.io;
  }

  Future<RV> createPeer({
    required String groupId,
    required String peerId,
  }) async {
    PeerGroup group = copyGroup(id: groupId)!;
    if (group.peers.containsKey(peerId)) {
      return RV.peerExists;
    }
    group.peers[peerId] = RemotePeer(id: peerId);
    return await updateGroup(group);
  }

  Future<RV> deletePeer({
    required String groupId,
    required String peerId,
  }) async {
    PeerGroup group = copyGroup(id: groupId)!;
    if (!group.peers.containsKey(peerId)) {
      return RV.notFound;
    }
    group.peers.remove(peerId);
    return await updateGroup(group);
  }

  Future<RV> createVaultGroupPeer({required String peerId}) async {
    if (!state.groups.containsKey(vaultGroupId)) {
      await createVaultGroup();
    }
    return await createPeer(groupId: vaultGroupId, peerId: peerId);
  }

  Future<RV> deleteVaultGroupPeer({required String peerId}) async {
    return await deletePeer(groupId: vaultGroupId, peerId: peerId);
  }
}

class PeerGroups {
  PeerGroups();

  // deep copy constructor
  PeerGroups.copy(PeerGroups copy) {
    json.decode(json.encode(copy.groups)).forEach((k, v) {
      groups[k] = PeerGroup.fromJson(v);
    });
  }

  // deser constructor
  PeerGroups.fromJson(Map<String, dynamic> parsedJson) {
    Map parsedgroups = json.decode(parsedJson['groups']);
    parsedgroups.forEach((k, v) {
      PeerGroup entry = PeerGroup.fromJson(v);
      groups[k] = entry;
    });
  }

  Map<String, PeerGroup> groups = {};

  // serialization
  Map<String, dynamic> toJson() {
    return {'groups': json.encode(groups)};
  }

  PeerGroup get vaultGroup {
    return groups[vaultGroupId]!; // created during init
  }

  bool memberOf({required String peerId, required String groupId}) {
    PeerGroup? g = groups[groupId];
    if (g == null) {
      return false;
    }

    if (g.peers.containsKey(peerId)) {
      return true;
    }

    return false;
  }

  bool memberOfVaultGroup({required String peerId}) {
    return memberOf(peerId: peerId, groupId: vaultGroupId);
  }
}

const String typeVault = 'vault';
const String typeMsg = 'msg';

class PeerGroup {
  PeerGroup({required this.id, required this.type});

  PeerGroup.fromJson(Map<String, dynamic> parsedJson) {
    id = parsedJson['id'];
    type = parsedJson['type'];

    name = parsedJson['name'];
    policy = parsedJson['policy'];
    managed = parsedJson['managed'];

    parsedJson['peers'].forEach((k, v) {
      peers[k] = RemotePeer.fromJson(v);
    });

    updatedAt = DateTime.parse(parsedJson['updatedAt']);
  }

  late String id;
  late String type;

  String name = '';
  String policy = '';
  String managed = '';
  Map<String, RemotePeer> peers = {};
  DateTime updatedAt = Const.minDate;

  List<String> get peerIds {
    return peers.keys.toList();
  }

  bool get isEmpty => peers.isEmpty;

  // serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'policy': policy,
      'managed': managed,
      'peers': peers,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class RemotePeer {
  RemotePeer({required this.id});

  RemotePeer.fromJson(Map<String, dynamic> parsedJson) {
    id = parsedJson['id'];
    revision = Revision.fromJson(parsedJson['revision']);
    updatedAt = DateTime.parse(parsedJson['updatedAt']);
  }

  late String id;
  DateTime updatedAt = Const.minDate;
  Revision revision = Revision(seq: 1, hash: '', annotation: {});

  // serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'updatedAt': updatedAt.toIso8601String(),
      'revision': revision,
    };
  }
}
