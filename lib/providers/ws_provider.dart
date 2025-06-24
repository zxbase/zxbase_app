// WebSocket Provider.
//
// This is singleton, single instance of ws client to be used
// by the whole application. It handles single connection.
// It uses RPS token.
//
// Initialization is tested by launch provider test.

import 'dart:developer';
import 'package:zxbase_app/providers/config_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

const component = 'wsProvider'; // logging component

// Currently we use WsState to prevent disruption by dispatcher
// while connecting.
enum WsState { off, connecting, on }

final wsProvider = Provider<WebSocket>((ref) => WebSocket(ref));

class WebSocket {
  WebSocket(this.ref) {
    String wsHost = ref.read(configProvider).signalingHost;
    int wsPort = ref.read(configProvider).signalingPort;
    _url = 'wss://$wsHost:$wsPort';
    log('Initialzing provider with url $_url.', name: component);
  }
  final Ref ref;

  // Stats.
  DateTime lastErrorTime = DateTime.utc(-271821, 04, 20);
  String lastError = '';

  // Callbacks
  Function(dynamic msg)? onMessage;
  Future<void> Function(Ref ref)? startConnections;

  late String _url;
  late io.Socket socket;
  WsState state = WsState.off;
  bool serverDisconnect = false;

  int hbLatency = -1;
  DateTime hbReceived = DateTime.utc(-271821, 04, 20);
  DateTime msgReceived = DateTime.utc(-271821, 04, 20);

  bool init({required String? token}) {
    log('Initialzing websocket.', name: component);

    socket = io.io(
      _url,
      // this is mandatory for dart VM, works for web as well
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setExtraHeaders({'Authorization': token})
          .build(),
    );

    socket.onConnect((_) {
      log('Connected.', name: component);
      state = WsState.on;
      socket.emit('chat', 'hello from device');
      startConnections?.call(ref);
    });

    /*
    socket.onConnectTimeout((_) {
      log('Connect timeout.', name: component);
    });
    */

    socket.onPing((_) {
      log('Sending ping.', name: component);
    });

    socket.onPong((data) {
      log('Received pong: $data.', name: component);
      hbLatency = data;
      hbReceived = DateTime.now().toUtc();
    });

    socket.onConnectError((data) {
      log('Connection error $data.', name: component);
      lastErrorTime = DateTime.now().toUtc();
      lastError = 'Connection: $data';
    });

    socket.onError((data) {
      log('Error $data.', name: component);
      lastErrorTime = DateTime.now().toUtc();
      lastError = 'Data: $data';
    });

    // currently reconnect is disabled
    socket.onReconnect((_) {
      log(
        'Reconnected, connected state: ${socket.connected}.',
        name: component,
      );
      state = WsState.on;
      startConnections?.call(ref);
    });

    socket.onReconnectAttempt((_) {
      log('Reconnect attempt.', name: component);
    });

    socket.onReconnectError((_) {
      log('Reconnect error.', name: component);
    });

    socket.onReconnectFailed((_) {
      log('Reconnect failed.', name: component);
    });

    // chat - no processing of this data
    socket.on('chat', (data) {
      log('Got chat $data.', name: component);
    });

    socket.on('message', (msg) {
      log('Got message $msg.', name: component);
      msgReceived = DateTime.now().toUtc();
      onMessage?.call(msg);
    });

    // Reasons and events:
    //   io client disconnect: resync
    //   transport close: ping timeout
    //   forced close: token refreshment
    socket.onDisconnect((reason) {
      log('Disconnected: $reason.', name: component);
      state = WsState.off;
      if (reason == 'io server disconnect') {
        serverDisconnect = true;
      }
    });

    log('Connecting.', name: component);
    state = WsState.connecting;
    socket.connect();
    log('Socket initialized, connected: ${socket.connected}.', name: component);
    return true;
  }

  void send(String msg) {
    socket.emit('message', msg);
    log('Send message $msg.', name: component);
  }

  void close() {
    log('Closing socket.', name: component);
    // dispose is recommended: https://pub.dev/packages/socket_io_client
    socket.dispose(); // will trigger disconnect
  }

  void reconnect() {
    log('Starting reconnect.', name: component);
    state = WsState.connecting;
    if (socket.connected) {
      log('Socket connected, reconnect.', name: component);
      // that's a recommended way to update extra headers
      // https://pub.dev/packages/socket_io_client
      socket.io
        ..disconnect()
        ..connect();
    } else {
      log('Socket already disconnected, connect.', name: component);
      // disconnecting helps to kick stale socket
      socket.disconnect();
      socket.connect();
    }
  }

  void updateToken({required String? token}) {
    socket.io.options?['extraHeaders'] = {'Authorization': token};
    reconnect();
  }
}
