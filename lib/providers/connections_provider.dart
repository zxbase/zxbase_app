// Connections:
//   Peer Id -> Connection

import 'dart:developer';
import 'package:zxbase_app/core/channel/channel_message.dart';
import 'package:zxbase_app/core/channel/connection.dart';
import 'package:zxbase_app/core/channel/signaling_message.dart';
import 'package:zxbase_app/core/channel/connection_helper.dart';
import 'package:zxbase_app/core/log.dart';
import 'package:zxbase_app/providers/green_vault/peer_group_provider.dart';
import 'package:zxbase_app/providers/green_vault/peers_provider.dart';
import 'package:zxbase_app/providers/green_vault/user_vault_provider.dart';
import 'package:zxbase_app/providers/vault_sync_provider.dart';
import 'package:zxbase_app/providers/ws_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_vault/zxbase_vault.dart';

const _comp = 'connectionsProvider'; // logging component

final connectionsProvider = Provider<Connections>((ref) => Connections(ref));

class Connections {
  Connections(this.ref) {
    ref.read(wsProvider).startConnections = startConnections;
    ref.read(wsProvider).onMessage = _onSignalingMessage;
  }
  final Ref ref;
  Map<String, Connection> connections = {};
  Map<String, Map<String, ChannelMessage>> dmEgressQueue = {};

  Connection? getConnection(String peerId) {
    return connections[peerId];
  }

  Future<void> _onHeartbeat(String peerId, ChannelMessage msg) async {
    if (!msg.data.containsKey('vault')) {
      return;
    }

    if (!ref.read(peerGroupsProvider).memberOfVaultGroup(peerId: peerId)) {
      return;
    }

    Revision peerRev = Revision.fromJson(msg.data['vault']);
    await ref.read(vaultSyncProvider).updateVaultGroup(peerId, peerRev);
    ref.read(vaultSyncProvider).updateSyncWarning();

    Revision rev = ref.read(userVaultProvider.notifier).currentRevision;
    // don't query for the same hash or older version
    if (rev.hash == msg.data['vault']['hash']) {
      return;
    }

    // don't query for initial doc
    if (msg.data['vault']['seq'] == 1) {
      return;
    }

    // don't query if local date is newer
    if ((rev.seq != 1) && (rev.date > msg.data['vault']['date'])) {
      return;
    }

    log('${logPeer(peerId)}: send vault query.', name: _comp);
    ChannelMessage query = ChannelMessage(
      type: cmVault,
      data: {'type': queryMsg},
    );
    await getConnection(peerId)!.sendMessage(query);
  }

  Future<void> _onVaultMessage(String peerId, ChannelMessage msg) async {
    if (!ref.read(peerGroupsProvider).memberOfVaultGroup(peerId: peerId)) {
      return;
    }

    switch (msg.data['type']) {
      case queryMsg:
        if (ref.read(userVaultProvider.notifier).currentRevision.seq == 1) {
          return; // don't send initial doc
        }

        log('${logPeer(peerId)}: send vault doc.', name: _comp);
        ChannelMessage doc = ChannelMessage(
          type: cmVault,
          data: {
            'type': docMsg,
            'data': ref.read(userVaultProvider.notifier).export(),
          },
        );
        await getConnection(peerId)!.sendMessage(doc);
        break;
      case docMsg:
        if (!await ref
            .read(vaultSyncProvider)
            .importVault(msg.data['data'], peerId)) {
          return;
        }

        Revisions importRevs = Revisions.import(msg.data['data']['rev']);
        await ref
            .read(vaultSyncProvider)
            .updateVaultGroup(peerId, importRevs.current);
        ref.read(vaultSyncProvider).updateSyncWarning();

        // acknowledge version update
        ChannelMessage ack = ChannelMessage(
          type: cmVault,
          data: {
            'type': ackMsg,
            'data': ref
                .read(userVaultProvider.notifier)
                .currentRevision
                .export(),
          },
        );
        await getConnection(peerId)!.sendMessage(ack);
        break;
      case ackMsg:
        Revision peerRev = Revision.fromJson(msg.data['data']);
        await ref.read(vaultSyncProvider).updateVaultGroup(peerId, peerRev);
        ref.read(vaultSyncProvider).updateSyncWarning();
        break;
      default:
        break;
    }
  }

  Future<void> flushEgressQueue(String peerId) async {
    if (dmEgressQueue[peerId] == null) {
      return;
    }
    log('${logPeer(peerId)}: flushing egress queue.', name: _comp);
    for (ChannelMessage msg in [...dmEgressQueue[peerId]!.values]) {
      await getConnection(peerId)!.sendMessage(msg);
    }
  }

  Future<void> sendHeartbeat({required String peerId}) async {
    Map<String, dynamic> vaultData = {
      'vault': ref.read(userVaultProvider.notifier).currentRevision.export(),
    };

    if (ref.read(peerGroupsProvider).memberOfVaultGroup(peerId: peerId)) {
      await getConnection(peerId)!.sendChannelHeartbeat(vaultData);
    } else {
      await getConnection(peerId)!.sendChannelHeartbeat({});
    }
  }

  Future<void> _onHandshakeCompletion(String peerId) async {
    await flushEgressQueue(peerId);
    await sendHeartbeat(peerId: peerId);

    // update peer status
    await ref
        .read(peersProvider.notifier)
        .setLastSeen(peerId: peerId, status: peerStatusOnline);
  }

  void _sendSignalingMessage(SignalingMessage msg) {
    ref.read(wsProvider).send(msg.str);
  }

  Peer getPeer(String peerId) {
    return ref.read(peersProvider).peers[peerId]!;
  }

  Future<void> _onConnectionClose(String peerId) async {
    if (getPeer(peerId).everSeen) {
      // update last seen only if the peer was ever seen
      await ref
          .read(peersProvider.notifier)
          .setLastSeen(peerId: peerId, status: peerStatusOffline);
    }
  }

  Future<void> initConnection({
    required String peerId,
    bool vaultEnabled = false,
  }) async {
    log('${logPeer(peerId)}: init connection.', name: _comp);
    connections[peerId] = Connection(ref, peerId);
    connections[peerId]!.onHeartbeat = _onHeartbeat;
    connections[peerId]!.onVaultMessage = _onVaultMessage;
    connections[peerId]!.onHandshakeCompletion = _onHandshakeCompletion;
    connections[peerId]!.onConnectionClose = _onConnectionClose;
    connections[peerId]!.sendSignalingMessage = _sendSignalingMessage;
    connections[peerId]!.getPeer = getPeer;
    connections[peerId]!.vaultEnabled = vaultEnabled;
    await connections[peerId]!.init();
  }

  Future<void> startNegotiation({required String peerId}) async {
    log(
      '${logPeer(peerId)}: start negotiation, connected: ${ref.read(wsProvider).socket.connected}.',
      name: _comp,
    );
    await connections[peerId]!.startNegotiation();
  }

  Future<void> deleteConnection({required String peerId}) async {
    dmEgressQueue.remove(peerId);
    if (!connections.containsKey(peerId)) {
      return;
    }
    await connections[peerId]!.close();
    connections.remove(peerId);
  }

  Future<void> _onSignalingMessage(dynamic message) async {
    SignalingMessage msg = SignalingMessage.fromMap(message);
    String peerId = msg.from;

    if (ref.read(peersProvider).peers[peerId] == null) {
      // it can happen in debug environment when swapping vaults
      log('WARN: ${logPeer(peerId)}: unknown peer.', name: _comp);
      return;
    }

    String channelId = ref.read(peersProvider).peers[peerId]!.channel;
    if (channelId != msg.channelId) {
      log(
        '${logPeer(peerId)}: wrong channel ${msg.channelId} ${msg.type}, should be $channelId.',
        name: _comp,
      );
      return;
    }

    Connection connection = getConnection(peerId)!;
    try {
      switch (msg.type) {
        case sigOfferMsg:
          await connection.onOffer(description: msg.data['description']);
          break;
        case sigHelloMsg:
          await connection.startNegotiation();
          break;
        case sigHB:
          await connection.onSignalHeartbeat(msg.data);
          break;
        case sigAnswerMsg:
          await connection.onAnswer(description: msg.data['description']);
          break;
        case sigCandidateMsg:
          await connection.onRemoteCandidate(candidate: msg.data['candidate']);
          break;
        default:
          break;
      }
    } catch (e) {
      log('${logPeer(peerId)}: connection exception: $e.', name: _comp);
    }
  }
}
