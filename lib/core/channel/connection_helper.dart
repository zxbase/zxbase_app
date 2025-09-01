import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_app/core/const.dart';
import 'package:zxbase_app/providers/connections_provider.dart';
import 'package:zxbase_app/providers/green_vault/peers_provider.dart';

const String messageApp = 'messenger';
const String vaultApp = 'vault';

const String csOff = 'off'; // connection is not created yet
const String csInitializing = 'initializing'; // started to execute init method
const String csInitialized = 'initialized'; // init finished
const String csReady = 'ready'; // peer B sent hello message
const String csNegotiating = 'negotiating'; // sent or received offer
const String csVerifying = 'verifying'; // send challenge
const String csOn = 'on'; // verified response to challenge

final Map<String, dynamic> offerSdpConstraints = {
  'mandatory': {
    'OfferToReceiveAudio': false,
    'OfferToReceiveVideo': false,
    'IceRestart': true,
  },
  'optional': [],
};

bool isIdle(int seconds) {
  return seconds > Const.connectionIdle;
}

bool isIdleSince(DateTime date) {
  DateTime currTime = DateTime.now().toUtc();
  return isIdle(currTime.difference(date).inSeconds);
}

// Start negotiation with offline peers.
Future<void> startConnections(Ref ref) async {
  Connections connections = ref.read(connectionsProvider);
  for (Peer peer in ref.read(peersProvider).peers.values) {
    if (peer.status == peerStatusOffline) {
      await connections.startNegotiation(peerId: peer.id);
    }
  }
}
