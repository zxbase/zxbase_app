// Handshake

import 'dart:developer';
import 'package:zxbase_app/core/channel/channel_message.dart';
import 'package:zxbase_app/core/log.dart';
import 'package:zxbase_app/providers/green_vault/device_provider.dart';
import 'package:zxbase_app/providers/green_vault/peers_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_crypto/zxbase_crypto.dart';

const _comp = 'handshake'; // logging component

final handshakeProvider = Provider<Handshake>((ref) => Handshake(ref));

class Handshake {
  Handshake(this.ref);
  final Ref ref;
  // channel handshake methods
  Future<ChannelMessage> buildChallenge(String peerId) async {
    var challenge = Hashcash.createChallenge(
      ref.read(deviceProvider).identity.toBase64Url(),
      ref.read(peersProvider).peers[peerId]!.identityStr,
      0,
    );

    var sig = await PKCrypto.sign(
      challenge,
      ref.read(deviceProvider).identityKeyPair,
    );

    return ChannelMessage(
      type: cmHsChallenge,
      data: {'msg': challenge, 'sig': sig},
    );
  }

  Future<ChannelMessage?> buildResponse(
    String peerId,
    ChannelMessage chl,
  ) async {
    var result = await ref
        .read(peersProvider)
        .peers[peerId]!
        .identity
        .verifySignature(chl.data['msg'], chl.data['sig']);

    if (!result) {
      log('${logPeer(peerId)}: wrong challenge signature: .', name: _comp);
      return null;
    }

    var response = Hashcash.solveChallenge(chl.data['msg']);
    var sig = await PKCrypto.sign(
      response,
      ref.read(deviceProvider).identityKeyPair,
    );
    return ChannelMessage(
      type: cmHsResponse,
      data: {
        'challenge': {'msg': chl.data['msg'], 'sig': chl.data['sig']},
        'response': {'msg': response, 'sig': sig},
      },
    );
  }

  Future<bool> validResponse(
    String peerId,
    ChannelMessage chl,
    ChannelMessage res,
  ) async {
    var result = await ref
        .read(peersProvider)
        .peers[peerId]!
        .identity
        .verifySignature(
          res.data['response']['msg'],
          res.data['response']['sig'],
        );
    if (!result) {
      log('${logPeer(peerId)}: wrong response signature.');
      return false;
    }

    // check the response is timely and solves an original challenge
    if (!Hashcash.check(chl.data['msg'], res.data['response']['msg'])) {
      log('Wrong response: peer $peerId.');
      return false;
    }

    log('${logPeer(peerId)}: response verified.', name: _comp);
    return true;
  }
}
