// Direct channel to the peer.

// References:
//   - https://developer.mozilla.org/en-US/docs/Web/API/WebRTC_API/Perfect_negotiation
//   - https://developer.mozilla.org/en-US/docs/Web/API/RTCPeerConnection/iceConnectionState
//   - https://developer.mozilla.org/en-US/docs/Web/API/RTCPeerConnection/signalingState
//   - https://stackoverflow.com/questions/60229785/when-can-i-consider-a-rtcpeerconnection-to-be-disconnected
//   - https://github.com/flutter-webrtc/flutter-webrtc/blob/master/example/lib/src/data_channel_sample.dart
//   - https://stackoverflow.com/questions/38867763/why-i-have-to-open-data-channel-before-send-peer-connection-offer
//   - https://github.com/flutter-webrtc/flutter-webrtc-demo/blob/master/lib/src/call_sample/signaling.dart

import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:zxbase_app/core/channel/channel_message.dart';
import 'package:zxbase_app/core/channel/connection_helper.dart';
import 'package:zxbase_app/core/channel/handshake.dart';
import 'package:zxbase_app/core/channel/signaling_message.dart';
import 'package:zxbase_app/core/log.dart';
import 'package:zxbase_app/providers/config_provider.dart';
import 'package:zxbase_app/providers/green_vault/device_provider.dart';
import 'package:zxbase_app/providers/green_vault/peers_provider.dart';

const _comp = 'connection'; // logging component

class Connection {
  Connection(this.ref, this.peerId) {
    peerA = (ref.read(deviceProvider).id.compareTo(peerId) <= 0);
    state = csOff;
  }
  final Ref ref;
  final String peerId;
  late bool peerA;

  late RTCPeerConnection connection;
  late ChannelMessage _issuedChallenge;

  String _connectionState = csOff;
  DateTime _connectionStateUpdated = DateTime.now().toUtc();
  String get state => _connectionState;
  DateTime get stateUpdated => _connectionStateUpdated;
  set state(String val) {
    _connectionState = val;
    _connectionStateUpdated = DateTime.now().toUtc();
  }

  bool get stateIdle {
    return isIdleSince(stateUpdated);
  }

  DateTime iceStateUpdated = DateTime.utc(-271821, 04, 20);
  bool get iceIdle {
    return isIdleSince(iceStateUpdated);
  }

  DateTime hbReceived = DateTime.utc(-271821, 04, 20);

  // Direct messages channel.
  bool dmChannelInitialized = false;
  late RTCDataChannel dmChannel;

  // Vault channel. Not enabled by default.
  bool vaultEnabled = false;
  bool vaultChannelInitialized = false;
  late RTCDataChannel vaultChannel;

  String get sdpSemantics =>
      WebRTC.platformIsWindows ? 'plan-b' : 'unified-plan';

  List<RTCIceCandidate> remoteCandidates = [];

  // callbacks
  Future<void> Function(String peerId, ChannelMessage msg)? onDirectMessage;
  Future<void> Function(String peerId, ChannelMessage msg)? onReceipt;
  Future<void> Function(String peerId, ChannelMessage msg)? onHeartbeat;
  Future<void> Function(String peerId, ChannelMessage msg)? onVaultMessage;
  Future<void> Function(String peerId)? onHandshakeCompletion;
  Future<void> Function(String peerId)? onConnectionClose;
  Function(SignalingMessage msg)? sendSignalingMessage;
  Function(String peerId)? getPeer;

  // connection housekeeping message
  SignalingMessage buildSignalingMessage({
    required String type,
    required Map<String, dynamic> data,
  }) {
    return SignalingMessage(
      type: type,
      app: messageApp,
      from: ref.read(deviceProvider).id,
      to: peerId,
      // message channel is used for the connection setup
      channelId: getPeer?.call(peerId).channel,
      data: data,
    );
  }

  Future<void> _sendOffer() async {
    RTCSessionDescription sdp = await connection.createOffer(
      offerSdpConstraints,
    );
    try {
      await connection.setLocalDescription(sdp);
    } catch (e) {
      log(
        '${logPeer(peerId)}: exception setting local description $e.',
        name: _comp,
      );
    }
    // Send offer here rather than on signaling state change.
    SignalingMessage msg = buildSignalingMessage(
      type: sigOfferMsg,
      data: {
        'description': {'sdp': sdp.sdp, 'type': sdp.type},
      },
    );
    sendSignalingMessage?.call(msg);
  }

  void _setupDataChannel(RTCDataChannel channel) {
    log('${logPeer(peerId)}: setup channel ${channel.label}.', name: _comp);

    channel.onDataChannelState = (s) async {
      log(
        '${logPeer(peerId)}:${channel.label!.split(':')[0]}: channel state is $s.',
        name: _comp,
      );
      if (s == RTCDataChannelState.RTCDataChannelOpen) {
        if (channel == dmChannel) {
          // Be sure to wait for 'open' before starting handshake.
          log(
            '${logPeer(peerId)}: DM channel is open, starting handshake.',
            name: _comp,
          );
          await _sendChallenge();
        }
      }
    };

    channel.onMessage = (RTCDataChannelMessage data) async {
      ChannelMessage msg = ChannelMessage.fromString(data.text);
      switch (msg.type) {
        case cmHsChallenge:
          log('${logPeer(peerId)}: received handshake challenge.', name: _comp);
          if (state == csNegotiating) {
            log('Sending challenge.', name: _comp);
            await _sendChallenge();
          }
          await _sendResponse(msg);
          break;
        case cmHsResponse:
          log('${logPeer(peerId)}: received handshake response.', name: _comp);
          await _handleResponse(msg);
          break;
        case cmDirectMessage:
          log('${logPeer(peerId)}: received direct message.', name: _comp);
          await onDirectMessage?.call(peerId, msg);
          break;
        case cmDirectReceipt:
          log('${logPeer(peerId)}: received receipt.', name: _comp);
          await onReceipt?.call(peerId, msg);
          break;
        case cmHeartbeat:
          log('${logPeer(peerId)}: received channel heartbeat.', name: _comp);
          hbReceived = DateTime.now().toUtc();
          if (state == csVerifying && stateIdle) {
            log('${logPeer(peerId)}: kickstart stuck handshake.', name: _comp);
            await _sendChallenge();
          }
          await onHeartbeat?.call(peerId, msg);
          break;
        case cmVault:
          log('${logPeer(peerId)}: received vault message.', name: _comp);
          await onVaultMessage?.call(peerId, msg);
          break;
        default:
          log(
            '${logPeer(peerId)}:WARN:unknown message ${msg.type}',
            name: _comp,
          );
          break;
      }
    };
  }

  Future<void> _createDataChannel({
    required String app,
    required String channelId,
  }) async {
    // delivery is guaranteed: ordered = true by default
    RTCDataChannelInit dataChannelDict = RTCDataChannelInit()
      ..maxRetransmits = 30;
    String label = '$app:$channelId';
    switch (app) {
      case messageApp:
        log(
          '${logPeer(peerId)}: creating DM data channel $label.',
          name: _comp,
        );
        dmChannel = await connection.createDataChannel(label, dataChannelDict);
        dmChannelInitialized = true;
        log('${logPeer(peerId)}: created DM channel.', name: _comp);
        _setupDataChannel(dmChannel);
        break;
    }
  }

  Future<void> _closePeerConnection() async {
    log('${logPeer(peerId)}: close peer connection.', name: _comp);
    await onConnectionClose?.call(peerId);
    await startNegotiation();
  }

  Future<void> closeIfDisconnected() async {
    if ((connection.iceConnectionState ==
            RTCIceConnectionState.RTCIceConnectionStateDisconnected) &&
        iceIdle) {
      log('${logPeer(peerId)}: idle in ICE disconnected state.', name: _comp);
      await _closePeerConnection();
    }
  }

  // async initialization
  Future<void> init() async {
    log('${logPeer(peerId)}: init connection.', name: _comp);
    state = csInitializing;

    final Map<String, dynamic> constraints = {
      'mandatory': {},
      'optional': [
        {'DtlsSrtpKeyAgreement': true},
      ],
    };

    Config config = ref.read(configProvider);
    String stunUrl = 'stun:${config.stunHost}:${config.stunPort}';
    connection = await createPeerConnection({
      'iceServers': [
        {'url': stunUrl},
        // No TURN servers to assure the relay is not used.
      ],
      'sdpSemantics': sdpSemantics,
    }, constraints);

    // Initialize callbacks.
    connection.onIceCandidate = onIceCandidate;

    connection.onRenegotiationNeeded = () {
      log('${logPeer(peerId)}: renegotiation needed.', name: _comp);
    };

    connection.onIceGatheringState = (state) {
      log('${logPeer(peerId)}: ICE gathering state $state.', name: _comp);
    };

    // https://github.com/flutter-webrtc/flutter-webrtc/issues/539
    connection.onSignalingState = (state) async {
      log('${logPeer(peerId)}: new sig state $state.', name: _comp);
      switch (state) {
        case RTCSignalingState.RTCSignalingStateHaveRemoteOffer:
          // answer here
          RTCSessionDescription session = await connection.createAnswer(
            offerSdpConstraints,
          );
          await connection.setLocalDescription(session);
          SignalingMessage msg = buildSignalingMessage(
            type: sigAnswerMsg,
            data: {
              'description': {'sdp': session.sdp, 'type': session.type},
            },
          );
          sendSignalingMessage?.call(msg);
          // add remote candidates
          if (remoteCandidates.isNotEmpty) {
            for (RTCIceCandidate candidate in remoteCandidates) {
              await connection.addCandidate(candidate);
            }
            remoteCandidates.clear();
          }
          break;
        default:
          break;
      }
    };

    connection.onConnectionState = (state) async {
      log('${logPeer(peerId)}: new RTC state $state', name: _comp);
    };

    connection.onIceConnectionState = (state) async {
      log('${logPeer(peerId)}: new ICE state is $state.', name: _comp);
      iceStateUpdated = DateTime.now().toUtc();
      switch (state) {
        case RTCIceConnectionState.RTCIceConnectionStateFailed:
          await _closePeerConnection();
          break;
        default:
          break;
      }
    };

    connection.onDataChannel = (channel) {
      List<String> label = channel.label!.split(':');
      log('${logPeer(peerId)} created channel ${label[0]}.', name: _comp);
      Peer peer = getPeer?.call(peerId);

      switch (label[0]) {
        case messageApp:
          if (peer.channel != label[1]) {
            log(
              'Error: channel is ${peer.channel}, got ${label[1]}.',
              name: _comp,
            );
            return;
          }
          dmChannel = channel;
          _setupDataChannel(dmChannel);
          dmChannelInitialized = true;
          break;
        case vaultApp:
          if (peer.vaultChannel != label[1]) {
            log(
              'Error: vault channel is ${peer.vaultChannel}, got ${label[1]}.',
              name: _comp,
            );
            return;
          }
          vaultChannel = channel;
          _setupDataChannel(vaultChannel);
          vaultChannelInitialized = true;
          break;
      }
    };

    state = csInitialized;
  }

  // Signaling handlers.

  Future<void> onOffer({required Map<String, dynamic> description}) async {
    log('${logPeer(peerId)}: received an offer, state $state.', name: _comp);
    await reset();
    state = csNegotiating;
    await connection.setRemoteDescription(
      RTCSessionDescription(description['sdp'], description['type']),
    );
  }

  Future<void> onIceCandidate(RTCIceCandidate? candidate) async {
    if (candidate == null) {
      log('${logPeer(peerId)}: completed ICE.', name: _comp);
      return;
    }

    log(
      '${logPeer(peerId)}: send ICE candidate ${candidate.candidate}.',
      name: _comp,
    );
    SignalingMessage msg = buildSignalingMessage(
      type: sigCandidateMsg,
      data: {'candidate': candidate.toMap()},
    );
    // This delay is needed to allow enough time to try an ICE candidate
    // before skipping to the next one. 1 second is just an heuristic value
    // and should be thoroughly tested in your own environment.
    Future.delayed(
      const Duration(milliseconds: 500),
      () => sendSignalingMessage?.call(msg),
    );
  }

  Future<void> onRemoteCandidate({
    required Map<String, dynamic> candidate,
  }) async {
    log(
      '${logPeer(peerId)}: received remote candidate $candidate.',
      name: _comp,
    );
    RTCIceCandidate iceCandidate = RTCIceCandidate(
      candidate['candidate'],
      candidate['sdpMid'],
      candidate['sdpMLineIndex'],
    );
    if ({csOff, csInitializing}.contains(state)) {
      log('${logPeer(peerId)}: buffer candidate.');
      remoteCandidates.add(iceCandidate);
    } else {
      await connection.addCandidate(iceCandidate);
    }
  }

  Future<void> onAnswer({required Map<String, dynamic> description}) async {
    log('${logPeer(peerId)}: received an answer.', name: _comp);
    await connection.setRemoteDescription(
      RTCSessionDescription(description['sdp'], description['type']),
    );
  }

  // channel handshake methods
  Future<void> _sendChallenge() async {
    state = csVerifying;
    _issuedChallenge = await ref.read(handshakeProvider).buildChallenge(peerId);
    await dmChannel.send(RTCDataChannelMessage(_issuedChallenge.str));
    log('${logPeer(peerId)}: challenge sent.', name: _comp);
  }

  Future<void> _sendResponse(ChannelMessage msg) async {
    ChannelMessage? responseMsg = await ref
        .read(handshakeProvider)
        .buildResponse(peerId, msg);
    if (responseMsg == null) {
      return;
    }
    await dmChannel.send(RTCDataChannelMessage(responseMsg.str));
    log('${logPeer(peerId)}: challenge response sent.', name: _comp);
  }

  Future<void> _handleResponse(ChannelMessage msg) async {
    if (!(await ref
        .read(handshakeProvider)
        .validResponse(peerId, _issuedChallenge, msg))) {
      return;
    }

    state = csOn;
    await onHandshakeCompletion?.call(peerId);
  }

  Future<bool> sendDirectMessage(ChannelMessage msg) async {
    // to send a message, handshake has to be completed
    if ((state == csOn) && dmChannelInitialized) {
      log(
        '${logPeer(peerId)}: send direct message, state: ${dmChannel.state}.',
        name: _comp,
      );
      await dmChannel.send(RTCDataChannelMessage(msg.str));
      return true;
    } else {
      return false;
    }
  }

  Future<void> _closeDataChannel({required String app}) async {
    switch (app) {
      case messageApp:
        if (!dmChannelInitialized) {
          return;
        }
        log('closing DM channel', name: _comp);
        await dmChannel.close();
        dmChannelInitialized = false;
        break;
    }
  }

  Future<void> close() async {
    log('${logPeer(peerId)}: close connection.', name: _comp);
    await _closeDataChannel(app: messageApp);
    await connection.close();
    state = csOff;
  }

  // To prepare for next negotiation, we have to close the connection.
  // After connection is closed, it has to be initialized again.
  // Otherwise WebRTC can't find it and throws an exception.
  Future<void> reset() async {
    if ({csInitialized, csReady}.contains(state)) {
      log('${logPeer(peerId)}: no need to reset $state.', name: _comp);
      return;
    }

    log('${logPeer(peerId)}: reset connection.', name: _comp);
    await close();
    await init();
  }

  Future<void> _createDMChannel() async {
    await _createDataChannel(
      app: messageApp,
      channelId: getPeer?.call(peerId).channel,
    );
  }

  Future<void> _createVaultChannel() async {
    await _createDataChannel(
      app: vaultApp,
      channelId: getPeer?.call(peerId).vaultChannel,
    );
  }

  void _sendHello() {
    SignalingMessage msg = buildSignalingMessage(type: sigHelloMsg, data: {});
    sendSignalingMessage?.call(msg);
  }

  // Peer A sends an offer.
  // Peer B sends hello message, asking to start negotiation.
  Future<void> startNegotiation() async {
    await reset();

    if (!peerA) {
      log('${logPeer(peerId)}: send hello.', name: _comp);
      _sendHello();
      state = csReady;
      return;
    }

    log('ICE restart. DM:$dmChannelInitialized', name: _comp);
    state = csNegotiating;
    if (!dmChannelInitialized) {
      log('${logPeer(peerId)}: create DM channel', name: _comp);
      await _createDMChannel();
    }
    if (vaultEnabled && !vaultChannelInitialized) {
      log('${logPeer(peerId)}: create vault channel', name: _comp);
      await _createVaultChannel();
    }
    await _sendOffer();
  }

  Future<void> onSignalHeartbeat(Map<String, dynamic> hb) async {
    log('${logPeer(peerId)}: received signal heartbeat $hb', name: _comp);
    if (!(isIdle(hb['stateTime']) && stateIdle)) {
      return;
    }

    // If either peer is offline for too long - restart the negotiation.
    Set offlineStates = {peerStatusOffline, peerStatusStaged};

    if (offlineStates.contains(hb['status'])) {
      log('${logPeer(peerId)}: I\'m offline for too long', name: _comp);
      await startNegotiation();
      return;
    }

    if (offlineStates.contains(getPeer?.call(peerId).status)) {
      log('${logPeer(peerId)}: offline for too long', name: _comp);
      await startNegotiation();
      return;
    }
  }

  Future<void> sendChannelHeartbeat(Map<String, dynamic> hbData) async {
    Set allowedStates = {
      RTCIceConnectionState.RTCIceConnectionStateConnected,
      RTCIceConnectionState.RTCIceConnectionStateCompleted,
    };
    if (!allowedStates.contains(connection.iceConnectionState)) {
      return;
    }
    ChannelMessage cMsg = ChannelMessage(type: cmHeartbeat, data: hbData);
    await dmChannel.send(RTCDataChannelMessage(cMsg.str));
  }
}
