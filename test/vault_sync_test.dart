import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'helpers.dart';
import 'package:zxbase_app/core/rv.dart';
import 'package:zxbase_app/providers/config_provider.dart';
import 'package:zxbase_app/providers/green_vault/device_provider.dart';
import 'package:zxbase_app/providers/green_vault/green_vault_provider.dart';
import 'package:zxbase_app/providers/green_vault/user_vault_provider.dart';
import 'package:zxbase_vault/zxbase_vault.dart';

final userVaultBProvider = NotifierProvider<UserVaultNotifier, UserVault>(
  UserVaultNotifier.new,
);

void main() {
  const pwd = '12345678cC%';
  const entryId = '1';
  const title = 'Amazon';
  const username = 'my@gmail.com';
  const notes = '';
  const uris = ['https://amazon.com', 'https://google.com'];
  Map<String, dynamic> snapshot = {};

  cleanupDb();
  mockPathProvider();
  test('Setup 2 vaults', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // startup sequence
    await container.read(configProvider).init();
    await container.read(greenVaultProvider.notifier).init(pwd);
    await container.read(deviceProvider.notifier).init();
    // init first vault
    UserVaultNotifier userVaultANotifier = container.read(
      userVaultProvider.notifier,
    );
    await userVaultANotifier.init();
    // init second vault
    UserVaultNotifier userVaultBNotifier = container.read(
      userVaultBProvider.notifier,
    );
    userVaultBNotifier.setupForTesting(
      docName: 'vaultB',
      deviceId: 'B',
      version: 'old',
    );
    await userVaultBNotifier.init();

    // read first vault
    var userVaultA = container.read(userVaultProvider);
    expect(userVaultA.entries.length, equals(0));

    // read second vault
    var userVaultB = container.read(userVaultBProvider);
    expect(userVaultB.entries.length, equals(0));

    var versionA = container.read(configProvider).version.text;
    var deviceAId = container.read(deviceProvider).id;
    var firstRevision =
        '1125b265e677c4d95f38ab4c1962dab60147b70db0ed62e02d2863bdd0c1f5fc';
    // check empty vaults
    expect(userVaultANotifier.currentRevision.name, equals('1-$firstRevision'));
    expect(userVaultANotifier.currentRevision.date, isNot(equals(0)));
    expect(userVaultANotifier.currentRevision.author, equals(deviceAId));
    expect(
      userVaultANotifier.currentRevision.authorHash,
      equals(firstRevision),
    );
    expect(userVaultANotifier.currentRevision.authorVersion, equals(versionA));

    expect(userVaultBNotifier.currentRevision.name, equals('1-$firstRevision'));
    expect(userVaultANotifier.currentRevision.date, isNot(equals(0)));

    // create entry
    UserVaultEntry entry = UserVaultEntry(id: entryId, type: typeLogin);
    entry.title = title;
    entry.username = username;
    entry.password = pwd;
    entry.notes = notes;
    entry.uris = uris;
    RV rv = await userVaultANotifier.createEntry(entry);
    expect(rv, equals(RV.ok));

    // export from A, import to B
    snapshot = userVaultANotifier.export();
    Revisions rev = Revisions.import(snapshot['rev']);
    expect(rev.current.seq, equals(2));
    expect(rev.current.author, equals(deviceAId));
    var authorHash = rev.current.authorHash;
    expect(authorHash.isNotEmpty, equals(true));
    expect(rev.current.authorVersion, equals(versionA));

    bool importResult = await userVaultBNotifier.import(snapshot);
    expect(importResult, equals(true));
    UserVaultEntry replicatedEntry = container
        .read(userVaultBProvider)
        .entries[entryId]!;
    expect(replicatedEntry.id, equals(entryId));
    expect(replicatedEntry.hidden, equals(false));

    // B should have author data of A
    expect(userVaultBNotifier.currentRevision.author, equals(deviceAId));
    expect(userVaultBNotifier.currentRevision.authorHash, equals(authorHash));
    expect(userVaultBNotifier.currentRevision.authorVersion, equals(versionA));

    // update B entry, author data of B is expected
    entry.title = 'titleB';
    rv = await userVaultBNotifier.updateEntry(entry);
    expect(rv, equals(RV.ok));
    expect(userVaultBNotifier.currentRevision.author, equals('B'));
    authorHash = userVaultBNotifier.currentRevision.authorHash;
    expect(authorHash.isNotEmpty, equals(true));
    expect(userVaultBNotifier.currentRevision.authorVersion, equals('old'));

    // export B to A
    snapshot = userVaultBNotifier.export();
    rev = Revisions.import(snapshot['rev']);
    importResult = await userVaultANotifier.import(snapshot);
    expect(importResult, equals(true));
    expect(userVaultANotifier.currentRevision.author, equals('B'));
    expect(userVaultANotifier.currentRevision.authorHash, equals(authorHash));
    expect(userVaultANotifier.currentRevision.authorVersion, equals('old'));
  });
}
