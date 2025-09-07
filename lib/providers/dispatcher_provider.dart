// Dispatcher functions:
//   - on startup:
//     - setup connections
//   - slow worker:
//     - update peers last seen
//   - fast worker:
//     - refresh token
//     - restore signaling connection
//     - obtain missing channels
//     - restore rt connections

import 'dart:async';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_app/core/channel/connection.dart';
import 'package:zxbase_app/core/channel/connection_helper.dart';
import 'package:zxbase_app/core/channel/signaling_message.dart';
import 'package:zxbase_app/core/const.dart';
import 'package:zxbase_app/core/version.dart';
import 'package:zxbase_app/providers/config_provider.dart';
import 'package:zxbase_app/providers/connections_provider.dart';
import 'package:zxbase_app/providers/green_vault/device_provider.dart';
import 'package:zxbase_app/providers/green_vault/peers_provider.dart';
import 'package:zxbase_app/providers/ui_providers.dart';
import 'package:zxbase_app/providers/rps_provider.dart';
import 'package:zxbase_app/providers/vault_sync_provider.dart';
import 'package:zxbase_app/providers/ws_provider.dart';
import 'package:zxbase_api_client/zxbase_api_client.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';
import 'package:zxbase_model/zxbase_model.dart';

const _comp = 'dispatcherProvider'; // logging _component
const _fastWorkerInterval = 20;
const _slowWorkerInterval = 60;

// start 3 minutes before expiration
const tokenRefreshThreshold = 3;
// start refreshing 17 minutes after receiving token
const tokenLocalRefreshThreshold = 17;

enum JobState { stopped, started }

final dispatcherProvider = Provider<Dispatcher>((ref) => Dispatcher(ref));

class Dispatcher {
  Dispatcher(this.ref);
  final Ref ref;

  Duration frequency = const Duration(seconds: 60);
  JobState state = JobState.stopped;

  // -271821-04-20 UTC
  DateTime lastRunTime = DateTime.utc(-271821, 04, 20);
  double lastRunDuration = 0.0;

  late Timer _fastWorkertimer;
  late Timer _slowWorkertimer;

  // obtain token, update websocket
  Future<void> _updateToken() async {
    log('Refreshing token', name: _comp);
    try {
      await ref.read(rpsProvider).obtainToken(topic: 'default');
    } catch (e) {
      log('Failed to refresh token $e.', name: _comp);
      return;
    }
    ref.read(wsProvider).updateToken(token: ref.read(rpsProvider).tokenStr);
  }

  Future<bool> _needsNewToken() async {
    RpsClient rps = ref.read(rpsProvider);
    if (rps.token == null) {
      return true; // network was not available on login
    }
    Token token = rps.token!;
    DateTime tokenRefreshTime = token.exp.subtract(
      const Duration(minutes: tokenRefreshThreshold),
    );
    // Check also rps time in case local time is behind (emulator case).
    DateTime localRefreshTime = rps.tokenDateTime.add(
      const Duration(minutes: tokenLocalRefreshThreshold),
    );
    DateTime currentUtc = DateTime.now().toUtc();

    if (ref.read(wsProvider).serverDisconnect) {
      // server disconnect hints there could be a problem with a token
      ref.read(wsProvider).serverDisconnect = false;
      return true;
    }
    if (currentUtc.isBefore(tokenRefreshTime) &&
        currentUtc.isBefore(localRefreshTime)) {
      return false;
    }
    return true;
  }

  Future<void> _checkSignal() async {
    WebSocket ws = ref.read(wsProvider);
    log(
      'Check signal: ${ws.socket.connected},${ref.read(wsProvider).state}.',
      name: _comp,
    );
    if (ws.socket.connected || ws.state == WsState.connecting) {
      if (ws.socket.connected && ws.state != WsState.on) {
        // It was observed we may not get notified on reconnect.
        log('We conclude we were reconnected.', name: _comp);
        ws.state = WsState.on;
        await startConnections(ref);
      }
      return;
    }
    log('Disconnected socket, starting recovery.', name: _comp);
    ws.reconnect();
  }

  Future<void> _updatePeerLastSeen() async {
    String offlinePeerId = '';
    bool rebuilt = false;

    for (Peer peer in ref.read(peersProvider).peers.values) {
      switch (peer.status) {
        case peerStatusOnline:
          await ref
              .read(peersProvider.notifier)
              .setLastSeen(peerId: peer.id, status: peerStatusOnline);
          rebuilt = true;
          break;
        case peerStatusOffline:
          offlinePeerId = peer.id;
          break;
      }
    }

    if (!rebuilt && offlinePeerId != '') {
      // If there is at least one peer offline, trigger rebuild of peer list.
      // It is cheap, will not write to the disk.
      await ref
          .read(peersProvider.notifier)
          .setStatus(peerId: offlinePeerId, status: peerStatusOffline);
    }
  }

  Future<void> pairPeer({required Peer peer}) async {
    RpsClient rps = ref.read(rpsProvider);
    String channelId = await rps.channel(peerId: peer.id, app: defaultApp);
    if (channelId == '') {
      // the peer is not paired yet
      return;
    }
    log('Peer ${peer.id} paired, $channelId.', name: _comp);

    Peer newPeer = Peer.copy(peer);
    newPeer.channel = channelId;
    newPeer.status = peerStatusStaged;
    await ref.read(peersProvider.notifier).updatePeer(peer: newPeer);
    await ref.read(connectionsProvider).startNegotiation(peerId: peer.id);
  }

  Future<void> _pairPeers() async {
    for (Peer peer in ref.read(peersProvider).peers.values) {
      if (peer.status != peerStatusPairing) {
        continue;
      }
      // Keep asking for channel till it is created.
      await pairPeer(peer: peer);
    }
  }

  Future<void> _updateMotd() async {
    RpsClient rps = ref.read(rpsProvider);
    var motd = await rps.getMotd();
    if (motd != null) {
      ref.read(motdProvider.notifier).state = motd;
      if (getRecentVersion(motdNotes: motd.notes).build >
          ref.read(configProvider).version.build) {
        ref.read(versionWarningProvider.notifier).state = Const.newVersionMsg;
      } else {
        ref.read(versionWarningProvider.notifier).state = '';
      }
    }
  }

  // Send heartbeat to all peers. Include status of the peer.
  Future<void> _sendHeartbeat() async {
    if (UI.testEnvironment) {
      // quick fix instead of mocking WebRTC stack
      return;
    }

    Connections connections = ref.read(connectionsProvider);
    DateTime currTime = DateTime.now().toUtc();

    for (Peer peer in ref.read(peersProvider).peers.values) {
      if (peer.channel == '') {
        continue;
      }

      Connection peerConnection = connections.getConnection(peer.id)!;
      SignalingMessage msg = SignalingMessage(
        type: sigHB,
        app: defaultApp,
        from: ref.read(deviceProvider).id,
        to: peer.id,
        channelId: peer.channel,
        data: {
          'status': peer.status,
          'state': peerConnection.state,
          'stateTime': currTime
              .difference(peerConnection.stateUpdated)
              .inSeconds,
        },
      );

      // send signal heartbeat
      ref.read(wsProvider).send(msg.str);
      // send channel heartbeat
      await connections.sendHeartbeat(peerId: peer.id);

      // piggy back closure of disconnected connection
      await peerConnection.closeIfDisconnected();
    }
  }

  // workers functionality -------------------------------------------
  Future<void> _fastWorker() async {
    if (await _needsNewToken()) {
      await _updateToken();
      await _updateMotd();
    } else {
      // Don't do token update and signal check at the same cycle,
      // it can cause multiple ws connections.
      await _checkSignal();
    }
    await _pairPeers();
    await _sendHeartbeat();
  }

  void _fastWorkerWithTimer(Timer timer) {
    _fastWorker();
  }

  Future<void> _slowWorker() async {
    log('Slow worker.', name: _comp);
    await _updatePeerLastSeen();
    ref.read(vaultSyncProvider).updateSyncWarning();
  }

  void _slowWorkerWithTimer(Timer timer) {
    _slowWorker();
  }

  // dispatcher interface
  Future<void> start() async {
    log('Starting.', name: _comp);

    Timer.run(_fastWorker); // run first job immediatelly
    _fastWorkertimer = Timer.periodic(
      const Duration(seconds: _fastWorkerInterval),
      _fastWorkerWithTimer,
    );

    Timer.run(_slowWorker); // run first job immediatelly
    _slowWorkertimer = Timer.periodic(
      const Duration(seconds: _slowWorkerInterval),
      _slowWorkerWithTimer,
    );

    // Get MOTD. Update it on every token refresh.
    await _updateMotd();

    state = JobState.started;
  }

  void stop() {
    log('Stopping.', name: _comp);
    _fastWorkertimer.cancel();
    _slowWorkertimer.cancel();
    state = JobState.stopped;
  }
}
