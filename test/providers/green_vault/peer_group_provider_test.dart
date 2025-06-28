import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zxbase_vault/zxbase_vault.dart';
import 'package:zxbase_app/core/rv.dart';
import 'package:zxbase_app/providers/config_provider.dart';
import 'package:zxbase_app/providers/green_vault/green_vault_provider.dart';
import 'package:zxbase_app/providers/green_vault/peer_group_provider.dart';
import '../../helpers.dart';

void main() {
  const pwd = '12345678cC%';
  const groupId = '_vault';
  const peerId = '1';
  const name = '_vault';

  cleanupDb();
  mockPathProvider();
  test('Init doc', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // startup sequence
    await container.read(configProvider).init();
    await container.read(greenVaultProvider.notifier).init(pwd);
    PeerGroupsNotifier peerGroupsNotifier = container.read(
      peerGroupsProvider.notifier,
    );
    await peerGroupsNotifier.init();

    // read the doc
    var peerGroups = container.read(peerGroupsProvider);
    expect(peerGroups.groups.length, equals(1));

    expect(
      peerGroupsNotifier.meta!.revs.current.name,
      equals(
        '2-2c0ed1ebd8d2b65b2cd668de0f1e3b93a9e1ada281464210d47607c76d111088',
      ),
    );
    expect(peerGroupsNotifier.meta!.revs.current.date, isNot(equals(0)));
  });

  test('Update group', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // startup sequence
    await container.read(configProvider).init();
    await container.read(greenVaultProvider.notifier).open(pwd);
    PeerGroupsNotifier peerGroupsNotifier = container.read(
      peerGroupsProvider.notifier,
    );
    await peerGroupsNotifier.open();

    // read the doc
    var peerGroups = container.read(peerGroupsProvider);
    expect(peerGroups.groups.length, equals(1));

    // add vault group
    PeerGroup peerGroup = PeerGroup(id: groupId, type: typeVault);
    peerGroup.name = name;
    peerGroup.managed = 'false';
    peerGroup.policy = 'none';

    RemotePeer peer = RemotePeer(id: peerId);
    Revision revision = Revision(
      seq: -1,
      hash: '1-1',
      annotation: {'author': 'John', 'date': 8},
    );
    // peer.rev = '1-1';
    // peer.revDate = DateTime.now().toUtc().millisecondsSinceEpoch;
    peer.revision = revision;
    peer.updatedAt = DateTime.now();
    peerGroup.peers[peerId] = peer;

    RV rv = await peerGroupsNotifier.updateGroup(peerGroup);
    expect(rv, equals(RV.ok));

    // creating same entry should fail
    PeerGroup vaultGroup = peerGroupsNotifier.copyGroup(id: groupId)!;
    rv = await peerGroupsNotifier.createGroup(vaultGroup);
    expect(rv, equals(RV.entryExists));

    // using same name should fail
    vaultGroup.id = '2';
    rv = await peerGroupsNotifier.createGroup(vaultGroup);
    expect(rv, equals(RV.nameExists));
  });

  test('Update entry', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // startup sequence
    await container.read(configProvider).init();
    await container.read(greenVaultProvider.notifier).open(pwd);
    PeerGroupsNotifier peerGroupsNotifier = container.read(
      peerGroupsProvider.notifier,
    );
    await peerGroupsNotifier.open();

    // read the doc
    PeerGroups peerGroups = container.read(peerGroupsProvider);
    expect(peerGroups.groups.length, equals(1));
    PeerGroup group = peerGroups.groups[groupId]!;
    expect(group.policy, 'none');
    group.policy = 'xxx';

    expect(group.peers[peerId]!.revision.hash, equals('1-1'));
    expect(group.peers[peerId]!.revision.author, equals('John'));
    expect(group.peers[peerId]!.revision.date, equals(8));

    // update entry
    RV rv = await peerGroupsNotifier.updateGroup(group);
    expect(rv, equals(RV.ok));
  });

  test('Check group membership', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // startup sequence
    await container.read(configProvider).init();
    await container.read(greenVaultProvider.notifier).open(pwd);
    PeerGroupsNotifier peerGroupsNotifier = container.read(
      peerGroupsProvider.notifier,
    );
    await peerGroupsNotifier.open();

    // read the doc
    bool member = container
        .read(peerGroupsProvider)
        .memberOfVaultGroup(peerId: peerId);
    expect(member, equals(true));
  });

  test('Delete entry', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // startup sequence
    await container.read(configProvider).init();
    await container.read(greenVaultProvider.notifier).open(pwd);
    PeerGroupsNotifier peerGroupsNotifier = container.read(
      peerGroupsProvider.notifier,
    );
    await peerGroupsNotifier.open();

    // read the doc
    PeerGroups groups = container.read(peerGroupsProvider);
    expect(groups.groups.length, equals(1));

    PeerGroup group = groups.groups[groupId]!;
    expect(group.type, equals(typeVault));
    expect(group.policy, equals('xxx'));
    expect(group.managed, equals('false'));

    // delete entry
    RV rv = await peerGroupsNotifier.deleteGroup(id: groupId);
    expect(rv, equals(RV.ok));
  });

  test('Verify deletion', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // startup sequence
    await container.read(configProvider).init();
    await container.read(greenVaultProvider.notifier).open(pwd);
    PeerGroupsNotifier peerGroupsNotifier = container.read(
      peerGroupsProvider.notifier,
    );
    await peerGroupsNotifier.open();

    // read the doc
    PeerGroups groops = container.read(peerGroupsProvider);
    expect(groops.groups.length, equals(0));
  });

  test('Add peer to vault group', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // startup sequence
    await container.read(configProvider).init();
    await container.read(greenVaultProvider.notifier).open(pwd);
    PeerGroupsNotifier peerGroupsNotifier = container.read(
      peerGroupsProvider.notifier,
    );
    await peerGroupsNotifier.open();

    // read the doc
    RV rv = await peerGroupsNotifier.createVaultGroupPeer(peerId: '2');
    expect(rv, equals(RV.ok));

    expect(
      container.read(peerGroupsProvider).vaultGroup.peerIds,
      equals(['2']),
    );
  });

  test('Delete peer from vault group', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // startup sequence
    await container.read(configProvider).init();
    await container.read(greenVaultProvider.notifier).open(pwd);
    PeerGroupsNotifier peerGroupsNotifier = container.read(
      peerGroupsProvider.notifier,
    );
    await peerGroupsNotifier.open();

    // read the doc
    RV rv = await peerGroupsNotifier.deleteVaultGroupPeer(peerId: '2');
    expect(rv, equals(RV.ok));
  });
}
