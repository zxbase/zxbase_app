import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_app/core/channel/channel_message.dart';
import 'package:zxbase_app/core/channel/connection.dart';
import 'package:zxbase_app/core/const.dart';
import 'package:zxbase_app/core/log.dart';
import 'package:zxbase_app/providers/connections_provider.dart';
import 'package:zxbase_app/providers/green_vault/peer_group_provider.dart';
import 'package:zxbase_app/providers/green_vault/peers_provider.dart';
import 'package:zxbase_app/providers/green_vault/settings_provider.dart';
import 'package:zxbase_app/providers/green_vault/user_vault_provider.dart';
import 'package:zxbase_app/providers/ui_providers.dart';
import 'package:zxbase_vault/zxbase_vault.dart';

const _comp = 'vaultSync'; // logging component

const String queryMsg = 'query';
const String docMsg = 'docMsg';
const String ackMsg = 'ackMsg';

final vaultSyncProvider = Provider<VaultSync>((ref) => VaultSync(ref));

class VaultSync {
  VaultSync(this.ref);
  final Ref ref;

  void _updateWarningProvider(String val) {
    String currentVal = ref.read(vaultSyncWarningProvider);
    if (currentVal != val) {
      ref.read(vaultSyncWarningProvider.notifier).state = val;
    }
  }

  void updateSyncWarning() {
    final vaultGroup = ref.read(peerGroupsProvider).vaultGroup;
    Revision revision = ref.read(userVaultProvider.notifier).meta!.revs.current;

    if (vaultGroup.isEmpty) {
      return;
    }

    bool allOffline = true;
    for (RemotePeer remotePeer in vaultGroup.peers.values) {
      Peer? peer = ref.read(peersProvider).peers[remotePeer.id];
      if (peer == null) {
        continue;
      }

      if (remotePeer.revision.hash == revision.hash ||
          remotePeer.revision.date == revision.date) {
        _updateWarningProvider('');
        return;
      }

      if (allOffline && peer.status == peerStatusOnline) {
        allOffline = false;
      }
    }

    DateTime date = DateTime.fromMillisecondsSinceEpoch(revision.date);
    if (allOffline || DateTime.now().difference(date).inSeconds > 30) {
      _updateWarningProvider(Const.vaultSyncWarn);
    }
  }

  Future<bool> updateVaultGroup(String peerId, Revision peerRev) async {
    if (peerRev.hash ==
        ref.read(peerGroupsProvider).vaultGroup.peers[peerId]!.revision.hash) {
      return false;
    }

    log('${logPeer(peerId)}: update remote peer.', name: _comp);
    PeerGroup vaultGroup = ref
        .read(peerGroupsProvider.notifier)
        .copyVaultGroup();
    vaultGroup.peers[peerId]!.revision = peerRev;
    vaultGroup.peers[peerId]!.updatedAt = DateTime.now().toUtc();

    await ref.read(peerGroupsProvider.notifier).updateGroup(vaultGroup);
    return true;
  }

  // broadcast vault doc to peers in the sync group
  Future<void> broadcastVault() async {
    Connections connections = ref.read(connectionsProvider);

    for (String peerId in ref.read(peerGroupsProvider).vaultGroup.peerIds) {
      Connection? peerConnection = connections.getConnection(peerId);
      if (peerConnection == null) {
        return;
      }

      log('${logPeer(peerId)}: send vault doc.', name: _comp);
      ChannelMessage doc = ChannelMessage(
        type: cmVault,
        data: {
          'type': docMsg,
          'data': ref.read(userVaultProvider.notifier).export(),
        },
      );
      await peerConnection.sendMessage(doc);
    }
  }

  // Return false if import is blocked, not completed yet or not applicable.
  Future<bool> importVault(Map<String, dynamic> snapshot, String peerId) async {
    String updatePolicy = ref.read(settingsProvider).vaultUpdatePolicy;
    switch (updatePolicy) {
      case Settings.automatic:
        return await ref.read(userVaultProvider.notifier).import(snapshot);
      case Settings.manual:
        Revisions revs = Revisions.import(snapshot['rev']);
        if (!ref.read(userVaultProvider.notifier).worthUpdate(revs.current)) {
          return false;
        }
        snapshot['_rev'] = revs.current;
        snapshot['_peerId'] = peerId;
        ref.read(vaultCandidateProvider.notifier).state = snapshot;
        _updateWarningProvider(Const.vaultSyncWarn);
        return false;
      case Settings.ignore:
        return false;
      default:
        return false;
    }
  }

  Future<void> importCandidateVault(Map<String, dynamic> candidateVault) async {
    bool rv = await ref.read(userVaultProvider.notifier).import(candidateVault);
    if (!rv) {
      return;
    }
    String peerId = candidateVault['_peerId'];

    Revision rev = candidateVault['_rev'];
    await updateVaultGroup(peerId, rev);
    updateSyncWarning();

    // acknowledge version update
    ChannelMessage ack = ChannelMessage(
      type: cmVault,
      data: {
        'type': ackMsg,
        'data': ref.read(userVaultProvider.notifier).currentRevision.export(),
      },
    );
    await ref.read(connectionsProvider).getConnection(peerId)!.sendMessage(ack);
    ref.read(vaultCandidateProvider.notifier).state = {};
  }
}
