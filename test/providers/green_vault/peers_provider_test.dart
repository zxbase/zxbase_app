import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zxbase_model/zxbase_model.dart';
import 'package:zxbase_app/core/rv.dart';
import 'package:zxbase_app/core/mock_peers.dart';
import 'package:zxbase_app/providers/config_provider.dart';
import 'package:zxbase_app/providers/green_vault/green_vault_provider.dart';
import 'package:zxbase_app/providers/green_vault/peers_provider.dart';
import '../../helpers.dart';

void main() {
  const pwd = '12345678cC%';
  String peerId = 'dae38e13-a625-412c-bec5-6583ebb13e9a';
  String peerId2 = 'd586de60-9ba7-463d-a082-d9515c5bbf2d';
  var idntMsg =
      'eyJrdHkiOiJPS1AiLCJjcnYiOiJFZDI1NTE5IiwieCI6Imhaa3JyZ3JBWmpqdVhqZmU4X2tfQXV5RVl0OUl0elhLdE9WUUxFOEdScUU9Iiwia2lkIjoiZGFlMzhlMTMtYTYyNS00MTJjLWJlYzUtNjU4M2ViYjEzZTlhIn0=';
  var idnt = Identity.fromBase64Url(idntMsg);
  var nickname = 'John Doe';

  cleanupDb();
  mockPathProvider();

  test('Initialize doc', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // startup sequence
    await container.read(configProvider).init();
    await container.read(greenVaultProvider.notifier).init(pwd);
    await container.read(peersProvider.notifier).init();

    // read the doc
    var peers = container.read(peersProvider);
    expect(peers.peers.length, equals(0));

    // add peer
    Peer peer = Peer.create(identityStr: idntMsg, nickname: nickname);
    var peersNotifier = container.read(peersProvider.notifier);
    RV rv = await peersNotifier.addPeer(peer);
    expect(rv, equals(RV.ok));

    // check peer was added
    peers = container.read(peersProvider);
    expect(peers.peers[idnt.deviceId]!.nickname, equals(nickname));
  });

  test('Open doc', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // startup sequence
    await container.read(configProvider).init();
    await container.read(greenVaultProvider.notifier).open(pwd);
    await container.read(peersProvider.notifier).open();

    // read the doc
    var peers = container.read(peersProvider);
    expect(peers.peers.length, equals(1));
    expect(peers.peers[idnt.deviceId]!.nickname, equals(nickname));
    expect(peers.peers[idnt.deviceId]!.everSeen, equals(false));
  });

  test('Read and delete', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // startup sequence
    await container.read(configProvider).init();
    await container.read(greenVaultProvider.notifier).open(pwd);
    await container.read(peersProvider.notifier).open();

    // add another peer
    Peer peer = Peer.create(
      identityStr:
          'eyJrdHkiOiJPS1AiLCJjcnYiOiJFZDI1NTE5IiwieCI6IkVfcG9DOUQ0bFc4ZWUzdnBXWVF2dUllRkpPM2U3dTNLREZXX01SeFFieUU9Iiwia2lkIjoiZDU4NmRlNjAtOWJhNy00NjNkLWEwODItZDk1MTVjNWJiZjJkIiwidmVyIjoxfQ==',
      nickname: 'abc',
    );
    await container.read(peersProvider.notifier).addPeer(peer);

    // read the doc
    var peers = container.read(peersProvider).peersList;
    expect(peers.length, equals(2));

    // delete peer
    RV rv = await container
        .read(peersProvider.notifier)
        .deletePeer(peerId: peerId2);
    expect(rv, equals(RV.ok));
  });

  test('Update peer', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // startup sequence
    await container.read(configProvider).init();
    await container.read(greenVaultProvider.notifier).open(pwd);
    PeersNotifier peersNotifier = container.read(peersProvider.notifier);
    await peersNotifier.open();

    Peer newPeer = Peer.copy(container.read(peersProvider).peers[peerId]!);
    newPeer.channel = 'x';

    RV rv = await peersNotifier.updatePeer(peer: newPeer);
    expect(rv, equals(RV.ok));
  });

  test('Set status and last seen', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // startup sequence
    await container.read(configProvider).init();
    await container.read(greenVaultProvider.notifier).open(pwd);
    PeersNotifier peersNotifier = container.read(peersProvider.notifier);
    await peersNotifier.open();

    expect(
      container.read(peersProvider).peers[peerId]!.lastSeen,
      DateTime.utc(-271821, 04, 20),
    );
    await peersNotifier.setStatus(peerId: peerId, status: peerStatusOnline);
    RV rv = await peersNotifier.setLastSeen(
      peerId: peerId,
      status: peerStatusOnline,
    );
    expect(rv, equals(RV.ok));
  });

  test('Load mock peers', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // startup sequence
    await container.read(configProvider).init();
    await container.read(greenVaultProvider.notifier).open(pwd);
    PeersNotifier peersNotifier = container.read(peersProvider.notifier);
    await peersNotifier.open();

    // check status and last seen
    expect(
      container.read(peersProvider).peers[peerId]!.status,
      peerStatusOffline,
    );
    expect(
      container.read(peersProvider).peers[peerId]!.lastSeen,
      isNot(DateTime.utc(-271821, 04, 20)),
    );

    await mockPeers(peersNotifier);
  });

  test('Check mock peers', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // startup sequence
    await container.read(configProvider).init();
    await container.read(greenVaultProvider.notifier).open(pwd);
    PeersNotifier peersNotifier = container.read(peersProvider.notifier);
    await peersNotifier.open();

    expect(container.read(peersProvider).peers.length, equals(7));
  });
}
