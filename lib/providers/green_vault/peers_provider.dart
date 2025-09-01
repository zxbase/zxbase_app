// Peers provider.
// Stored in green vault.
// Map of peers: peer Id -> Peer.

import 'dart:convert';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_app/core/rv.dart';
import 'package:zxbase_app/providers/green_vault/green_vault_provider.dart';
import 'package:zxbase_model/zxbase_model.dart';
import 'package:zxbase_vault/zxbase_vault.dart';

const _component = 'peersProvider'; // logging component

final peersProvider = StateNotifierProvider<PeersNotifier, Peers>(
  (ref) => PeersNotifier(ref),
);

class PeersNotifier extends StateNotifier<Peers> {
  PeersNotifier(this.ref) : super(Peers());
  final Ref ref;
  static const _docName = 'peers';

  // called only once during initialization
  Future init() async {
    log('Create doc.', name: _component);
    await ref
        .read(greenVaultProvider)
        .updateDoc(name: _docName, content: state.toJson(), annotation: {});
  }

  Future open() async {
    Doc? doc = await ref.read(greenVaultProvider).getDoc(name: _docName);
    state = Peers.fromJson(doc!.content, firstLoad: true);
    log('Loaded doc from the vault.', name: _component);
  }

  Future<bool> _updateDoc(Peers newState) async {
    Doc? doc = await ref
        .read(greenVaultProvider)
        .updateDoc(name: _docName, content: newState.toJson(), annotation: {});
    if (doc == null) {
      return false;
    }
    return true;
  }

  Future<RV> addPeer(Peer peer) async {
    if (state.peers.containsKey(peer.id)) {
      return RV.peerExists;
    }
    log('Adding peer ${peer.id}.', name: _component);
    Peers stateCopy = Peers.copy(state);
    stateCopy.peers[peer.id] = peer;
    state = stateCopy; // trigger notification
    return await _updateDoc(stateCopy) ? RV.ok : RV.io;
  }

  Future<RV> deletePeer({required String peerId}) async {
    if (!state.peers.containsKey(peerId)) {
      return RV.notFound;
    }
    log('Deleting peer $peerId.', name: _component);
    Peers stateCopy = Peers.copy(state);
    stateCopy.peers.remove(peerId);
    state = stateCopy; // trigger notification
    return await _updateDoc(stateCopy) ? RV.ok : RV.io;
  }

  Future<RV> updatePeer({required Peer peer}) async {
    if (!state.peers.containsKey(peer.id)) {
      return RV.notFound;
    }
    log('Updating peer ${peer.id}.', name: _component);
    Peers stateCopy = Peers.copy(state);
    stateCopy.peers[peer.id] = peer;
    state = stateCopy; // trigger notification
    return await _updateDoc(stateCopy) ? RV.ok : RV.io;
  }

  // Every updater needs to write the doc,
  // otherwise this update will be lost when other queued update resumes.
  Future<RV> setStatus({required String peerId, required String status}) async {
    if (!state.peers.containsKey(peerId)) {
      return RV.notFound;
    }
    log('Peer $peerId: set status $status.', name: _component);
    Peers stateCopy = Peers.copy(state);
    stateCopy.peers[peerId]!.status = status;
    state = stateCopy; // trigger notification
    return await _updateDoc(stateCopy) ? RV.ok : RV.io;
  }

  Future<RV> setLastSeen({
    required String peerId,
    required String status,
  }) async {
    if (!state.peers.containsKey(peerId)) {
      return RV.notFound;
    }
    log('Peer $peerId: set last seen, status $status.', name: _component);
    Peers stateCopy = Peers.copy(state);
    stateCopy.peers[peerId]!.status = status;
    stateCopy.peers[peerId]!.lastSeen = DateTime.now().toUtc();
    state = stateCopy; // trigger notification
    return await _updateDoc(stateCopy) ? RV.ok : RV.io;
  }
}

class Peers {
  Peers();

  // deep copy constructor
  Peers.copy(Peers copy) {
    json.decode(json.encode(copy.peers)).forEach((k, v) {
      peers[k] = Peer.fromJson(v);
    });
  }

  // deserialization
  Peers.fromJson(Map<String, dynamic> parsedJson, {bool firstLoad = false}) {
    Map parsedPeers = json.decode(parsedJson['peers']);
    parsedPeers.forEach((k, v) {
      peers[k] = Peer.fromJson(v, firstLoad: firstLoad);
    });
  }

  // peer Id -> Peer
  Map<String, Peer> peers = {};

  // List of peers sorted by last name.
  List get peersList =>
      peers.entries.map((e) => e.value).toList()
        ..sort((a, b) => a.compareByNickname(b));

  // serialization
  Map<String, dynamic> toJson() {
    return {'peers': json.encode(peers)};
  }
}

// created -> pairing -> staged -> online <-> offline
const String peerStatusCreated = 'created';
const String peerStatusPairing = 'pairing';
const String peerStatusStaged = 'staged'; // waiting for backend cache
const String peerStatusOnline = 'online';
const String peerStatusOffline = 'offline';

class Peer {
  Peer.create({required this.identityStr, required this.nickname}) {
    identity = Identity.fromBase64Url(identityStr);
    id = identity.deviceId;
    metadata = '';
    channel = '';
    vaultChannel = '';
  }

  Peer.copy(Peer copy) {
    id = copy.id;
    identityStr = copy.identityStr;
    identity = Identity.fromBase64Url(identityStr);
    nickname = copy.nickname;
    metadata = copy.metadata;
    channel = copy.channel;
    vaultChannel = copy.vaultChannel;
    status = copy.status;
    lastSeen = copy.lastSeen;
  }

  // deserialization
  Peer.fromJson(Map<String, dynamic> parsedJson, {bool firstLoad = false}) {
    id = parsedJson['id'];
    identityStr = parsedJson['identity'];
    identity = Identity.fromBase64Url(identityStr);
    nickname = parsedJson['nickname'] ?? '';
    metadata = parsedJson['metadata'];
    channel = parsedJson['channel'];
    vaultChannel = parsedJson['vaultChannel'] ?? '';
    if (firstLoad) {
      status = (channel == '') ? peerStatusPairing : peerStatusOffline;
    } else {
      status = parsedJson['status'];
    }
    lastSeen = DateTime.parse(parsedJson['lastSeen']);
  }

  late String id; // UUID
  late String identityStr;
  late Identity identity;
  late String nickname;
  late String metadata; // for future use, shared with a service

  // channels
  String channel = ''; // messages channel
  String vaultChannel = '';

  String status = peerStatusCreated;

  // -271821-04-20 UTC
  DateTime lastSeen = DateTime.utc(-271821, 04, 20);
  bool get everSeen => (lastSeen != DateTime.utc(-271821, 04, 20));

  // serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'identity': identityStr,
      'nickname': nickname,
      'metadata': metadata,
      'channel': channel,
      'vaultChannel': vaultChannel,
      'status': status,
      'lastSeen': lastSeen.toIso8601String(),
    };
  }

  // sorting
  int compareByNickname(Peer b) {
    try {
      // can be empty during migration
      return nickname[0].toLowerCase().compareTo(b.nickname[0].toLowerCase());
    } catch (e) {
      return 0;
    }
  }
}
