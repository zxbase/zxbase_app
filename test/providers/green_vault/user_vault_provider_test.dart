import 'package:zxbase_app/core/rv.dart';
import 'package:zxbase_app/providers/config_provider.dart';
import 'package:zxbase_app/providers/green_vault/device_provider.dart';
import 'package:zxbase_app/providers/green_vault/green_vault_provider.dart';
import 'package:zxbase_app/providers/green_vault/user_vault_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zxbase_vault/zxbase_vault.dart';
import '../../helpers.dart';

void main() {
  const pwd = '12345678cC%';
  const entryId = '1';
  const title = 'Amazon';
  const username = 'my@gmail.com';
  const notes = '';
  const uris = ['https://amazon.com', 'https://google.com'];
  Map<String, dynamic> snapshot = {};
  String hash = '';

  cleanupDb();
  mockPathProvider();
  test('Init doc', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // startup sequence
    await container.read(configProvider).init();
    await container.read(greenVaultProvider.notifier).init(pwd);
    await container.read(deviceProvider.notifier).init();
    UserVaultNotifier userVaultNotifier = container.read(
      userVaultProvider.notifier,
    );
    // test the path of opening non existing doc for upgrade scenario
    // of old versions where user vault didn't exist
    await userVaultNotifier.open();

    // read the doc
    var userVault = container.read(userVaultProvider);
    expect(userVault.entries.length, equals(0));

    expect(
      userVaultNotifier.currentRevision.name,
      equals(
        '1-1125b265e677c4d95f38ab4c1962dab60147b70db0ed62e02d2863bdd0c1f5fc',
      ),
    );
    expect(userVaultNotifier.meta!.revs.current.date, isNot(equals(0)));
  });

  test('Search', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // startup sequence
    await container.read(configProvider).init();
    await container.read(greenVaultProvider.notifier).open(pwd);
    await container.read(deviceProvider.notifier).init();
    UserVaultNotifier userVaultNotifier = container.read(
      userVaultProvider.notifier,
    );
    await userVaultNotifier.open();

    // read the doc
    var userVault = container.read(userVaultProvider);
    expect(userVault.entries.length, equals(0));

    // add login
    UserVaultEntry entry = UserVaultEntry(id: entryId, type: typeLogin);
    entry.title = title;
    entry.username = username;
    entry.password = pwd;
    entry.notes = notes;
    entry.uris = uris;

    RV rv = await userVaultNotifier.createEntry(entry);
    expect(rv, equals(RV.ok));

    // creating same entry should fail
    UserVaultEntry entryCopy = userVaultNotifier.copyEntry(id: entryId)!;
    rv = await userVaultNotifier.createEntry(entryCopy);
    expect(rv, equals(RV.entryExists));

    // using same title should fail
    entryCopy.id = '2';
    rv = await userVaultNotifier.createEntry(entryCopy);
    expect(rv, equals(RV.titleExists));

    snapshot = userVaultNotifier.export();
    Revisions rev = Revisions.import(snapshot['rev']);
    expect(rev.current.seq, equals(2));
    hash = rev.current.hash;

    // check entry
    userVault = container.read(userVaultProvider);
    UserVaultEntry createdEntry = userVault.entries[entryId]!;
    expect(createdEntry.hidden, equals(false));
  });

  test('Update entry', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // startup sequence
    await container.read(configProvider).init();
    await container.read(greenVaultProvider.notifier).open(pwd);
    await container.read(deviceProvider.notifier).init();
    UserVaultNotifier userVaultNotifier = container.read(
      userVaultProvider.notifier,
    );
    await userVaultNotifier.open();

    // read the doc
    UserVault userVault = container.read(userVaultProvider);
    expect(userVault.entries.length, equals(1));
    UserVaultEntry entry = userVault.entries[entryId]!;
    expect(entry.notes, equals(notes));

    UserVaultEntry entryCopy = userVaultNotifier.copyEntry(id: entryId)!;
    entryCopy.notes = 'xxx';
    entryCopy.hidden = true;

    // update entry
    RV rv = await userVaultNotifier.updateEntry(entryCopy);
    expect(rv, equals(RV.ok));

    // check entry
    entry = userVault.entries[entryId]!;
    expect(entry.hidden, equals(false));
  });

  test('Create second entry', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // startup sequence
    await container.read(configProvider).init();
    await container.read(greenVaultProvider.notifier).open(pwd);
    await container.read(deviceProvider.notifier).init();
    UserVaultNotifier userVaultNotifier = container.read(
      userVaultProvider.notifier,
    );
    await userVaultNotifier.open();

    // add login
    UserVaultEntry entry = UserVaultEntry(id: '2', type: typeLogin);
    entry.title = 'Second title';
    entry.username = 'second@gmail.com';
    entry.password = pwd;
    entry.notes = 'second notes';
    entry.uris = ['https://second.com'];
    entry.hidden = true;

    RV rv = await userVaultNotifier.createEntry(entry);
    expect(rv, equals(RV.ok));

    List<String> entryIds = userVaultNotifier.search(query: 'second');
    expect(entryIds, equals(['2']));

    entryIds = userVaultNotifier.search(query: 'third');
    expect(entryIds, equals([]));

    // case insensitive search
    entryIds = userVaultNotifier.search(query: 'GOOGLE');
    expect(entryIds, equals(['1']));
  });

  test('Delete entry', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // startup sequence
    await container.read(configProvider).init();
    await container.read(greenVaultProvider.notifier).open(pwd);
    await container.read(deviceProvider.notifier).init();
    UserVaultNotifier userVaultNotifier = container.read(
      userVaultProvider.notifier,
    );
    await userVaultNotifier.open();

    // read the doc
    UserVault userVault = container.read(userVaultProvider);
    expect(userVault.entries.length, equals(2));

    UserVaultEntry entry = userVault.entries[entryId]!;
    expect(entry.type, equals(typeLogin));
    expect(entry.title, equals(title));
    expect(entry.username, equals(username));
    expect(entry.password, equals(pwd));
    expect(entry.notes, equals('xxx'));
    expect(entry.uris, equals(uris));

    // delete entry
    RV rv = await userVaultNotifier.deleteEntry(id: entryId);
    expect(rv, equals(RV.ok));
  });

  test('Verify deletion', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // startup sequence
    await container.read(configProvider).init();
    await container.read(greenVaultProvider.notifier).open(pwd);
    await container.read(deviceProvider.notifier).init();
    UserVaultNotifier userVaultNotifier = container.read(
      userVaultProvider.notifier,
    );
    await userVaultNotifier.open();

    // read the doc
    UserVault userVault = container.read(userVaultProvider);
    expect(userVault.entries.length, equals(1));
    expect(container.read(userVaultProvider).entries[entryId], equals(null));
  });

  test('Import vault', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // startup sequence
    await container.read(configProvider).init();
    await container.read(greenVaultProvider.notifier).open(pwd);
    await container.read(deviceProvider.notifier).init();
    UserVaultNotifier userVaultNotifier = container.read(
      userVaultProvider.notifier,
    );
    await userVaultNotifier.open();

    // import of the same version is not allowed
    bool rv = await userVaultNotifier.import(userVaultNotifier.export());
    expect(rv, equals(false));

    // import of older version is not allowed
    rv = await userVaultNotifier.import(snapshot);
    expect(rv, equals(false));

    // manually update snapshot date
    Revisions rev = Revisions.import(snapshot['rev']);
    rev.current.date = DateTime.now().toUtc().millisecondsSinceEpoch;
    snapshot['rev'] = rev.export();
    rv = await userVaultNotifier.import(snapshot);
    expect(rv, equals(true));
    expect(userVaultNotifier.meta!.revs.current.seq, equals(6));
    expect(userVaultNotifier.meta!.revs.current.hash, equals(hash));
    expect(container.read(userVaultProvider).entries.length, equals(1));
    expect(
      container.read(userVaultProvider).entries[entryId]!.title,
      equals(title),
    );
  });

  test('Uniqueness', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // startup sequence
    await container.read(configProvider).init();
    await container.read(greenVaultProvider.notifier).open(pwd);
    await container.read(deviceProvider.notifier).init();
    UserVaultNotifier userVaultNotifier = container.read(
      userVaultProvider.notifier,
    );
    await userVaultNotifier.open();

    // add login
    UserVaultEntry entry = UserVaultEntry(id: '10', type: typeLogin);
    entry.title = 'Unique title';
    entry.username = 'second@gmail.com';
    entry.password = pwd;
    entry.notes = 'second notes';
    entry.uris = ['https://second.com'];
    RV rv = await userVaultNotifier.createEntry(entry);
    expect(rv, equals(RV.ok));

    UserVaultEntry entry2 = UserVaultEntry(id: '11', type: typeLogin);
    entry2.title = 'Unique title';
    entry2.username = 'second@gmail.com';
    entry2.password = pwd;
    entry2.notes = 'second notes';
    entry2.uris = ['https://second.com'];
    rv = await userVaultNotifier.createEntry(entry2);
    expect(rv, equals(RV.titleExists));

    UserVaultEntry entry3 = UserVaultEntry(id: '10', type: typeNote);
    entry3.title = 'Unique title';
    entry3.username = 'second@gmail.com';
    entry3.password = pwd;
    entry3.notes = 'second notes';
    entry3.uris = ['https://second.com'];
    rv = await userVaultNotifier.createEntry(entry3);
    expect(rv, equals(RV.entryExists));

    UserVaultEntry entry4 = UserVaultEntry(id: '12', type: typeNote);
    entry4.title = 'Unique title';
    entry4.username = 'second@gmail.com';
    entry4.password = pwd;
    entry4.notes = 'second notes';
    entry4.uris = ['https://second.com'];
    rv = await userVaultNotifier.createEntry(entry4);
    expect(rv, equals(RV.ok));

    UserVaultEntry entry5 = UserVaultEntry(id: '12', type: typeNote);
    entry5.title = 'Unique title';
    entry5.username = 'second@gmail.com';
    entry5.password = pwd;
    entry5.notes = 'second notes';
    entry5.uris = ['https://second.com'];
    rv = await userVaultNotifier.createEntry(entry5);
    expect(rv, equals(RV.entryExists));

    UserVaultEntry entry6 = UserVaultEntry(id: '13', type: typeNote);
    entry6.title = 'Unique title';
    entry6.username = 'second@gmail.com';
    entry6.password = pwd;
    entry6.notes = 'second notes';
    entry6.uris = ['https://second.com'];
    rv = await userVaultNotifier.createEntry(entry6);
    expect(rv, equals(RV.titleExists));

    entry6.type = typeLogin;
    rv = await userVaultNotifier.updateEntry(entry6);
    expect(rv, equals(RV.notFound));
  });
}
