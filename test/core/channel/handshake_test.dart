import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zxbase_app/core/channel/channel_message.dart';
import 'package:zxbase_app/core/channel/handshake.dart';
import 'package:zxbase_app/core/rv.dart';
import 'package:zxbase_app/providers/blue_vault/blue_vault_provider.dart';
import 'package:zxbase_app/providers/blue_vault/init_provider.dart';
import 'package:zxbase_app/providers/config_provider.dart';
import 'package:zxbase_app/providers/green_vault/device_provider.dart';
import 'package:zxbase_app/providers/green_vault/green_vault_provider.dart';
import 'package:zxbase_app/providers/green_vault/peers_provider.dart';
import 'package:zxbase_model/zxbase_model.dart';
import '../../helpers.dart';

void main() {
  const pwd = '12345678cC%';
  var idntMsg =
      'eyJrdHkiOiJPS1AiLCJjcnYiOiJFZDI1NTE5IiwieCI6Imhaa3JyZ3JBWmpqdVhqZmU4X2tfQXV5RVl0OUl0elhLdE9WUUxFOEdScUU9Iiwia2lkIjoiZGFlMzhlMTMtYTYyNS00MTJjLWJlYzUtNjU4M2ViYjEzZTlhIn0=';
  var idnt = Identity.fromBase64Url(idntMsg);
  var nickname = 'John Doe';

  cleanupDb();
  mockPathProvider();

  test('handshake', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // init sequence
    await container.read(configProvider).init();
    await container.read(blueVaultProvider.notifier).init();
    await container.read(initProvider.notifier).init();
    await container.read(greenVaultProvider.notifier).init(pwd);
    await container.read(deviceProvider.notifier).init();
    await container.read(peersProvider.notifier).init();

    // for testing only - add myself as a peer
    Peer peer = Peer.create(
      // identityStr: idntMsg,
      identityStr: container.read(deviceProvider).identity.toBase64Url(),
      nickname: 'me',
    );
    var peersNotifier = container.read(peersProvider.notifier);
    RV rv = await peersNotifier.addPeer(peer);
    expect(rv, equals(RV.ok));

    Peer peer2 = Peer.create(identityStr: idntMsg, nickname: nickname);
    rv = await peersNotifier.addPeer(peer2);
    expect(rv, equals(RV.ok));

    // create challenge
    ChannelMessage chl = await container
        .read(handshakeProvider)
        .buildChallenge(container.read(deviceProvider).id);
    expect(chl.type, equals(cmHsChallenge));
    expect(chl.str, isNot(equals('')));
    ChannelMessage copy = ChannelMessage.fromString(chl.str);
    expect(copy.type, equals(cmHsChallenge));
    expect(copy.str, isNot(equals('')));

    // create response
    ChannelMessage? res = await container
        .read(handshakeProvider)
        .buildResponse(container.read(deviceProvider).id, chl);
    expect(res!.type, equals(cmHsResponse));

    // create response with wrong peer
    ChannelMessage? res2 = await container
        .read(handshakeProvider)
        .buildResponse(idnt.deviceId, chl);
    expect(res2, equals(null));

    // verify response
    expect(
      await container
          .read(handshakeProvider)
          .validResponse(container.read(deviceProvider).id, chl, res),
      equals(true),
    );

    // verify response with wrong peer
    expect(
      await container
          .read(handshakeProvider)
          .validResponse(idnt.deviceId, chl, res),
      equals(false),
    );
  });
}
