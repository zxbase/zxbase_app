// User vault provider.
// Keeps all local records: logins, notes e.t.c.
// All entries adressed by entries map: UUID -> UserVaultEntry
// Additionally, entries are addressed by ephemeral group maps:
//   Logins: UUID -> True
//   Notes: UUID -> True

import 'dart:convert';
import 'dart:developer';
import 'package:zxbase_app/core/rv.dart';
import 'package:zxbase_app/providers/config_provider.dart';
import 'package:zxbase_app/providers/green_vault/device_provider.dart';
import 'package:zxbase_app/providers/green_vault/green_vault_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_vault/zxbase_vault.dart';

const _comp = 'userVaultProvider'; // logging component

final userVaultProvider = StateNotifierProvider<UserVaultNotifier, UserVault>(
  (ref) => UserVaultNotifier(
    ref: ref,
    deviceId: ref.read(deviceProvider).id,
    version: ref.read(configProvider).version.text,
  ),
);

class UserVaultNotifier extends StateNotifier<UserVault> {
  UserVaultNotifier({
    required this.ref,
    required this.deviceId,
    required this.version,
    this.docName = 'vault',
  }) : super(UserVault());
  final Ref ref;
  final String docName;
  final String deviceId;
  final String version;
  DocMeta? meta;

  Future<void> init() async {
    log('Create doc.', name: _comp);
    Doc? doc = await ref
        .read(greenVaultProvider)
        .updateDoc(
          name: docName,
          content: state.toJson(),
          annotation: {'author': deviceId, 'authorVersion': version},
        );
    meta = doc!.meta;
  }

  Future<void> open() async {
    Doc? doc = await ref.read(greenVaultProvider).getDoc(name: docName);
    if (doc == null) {
      await init();
    } else {
      state = UserVault.fromJson(doc.content);
      meta = doc.meta;
      log('Loaded doc.', name: _comp);
    }
  }

  Future<bool> _updateDoc({
    required UserVault newState,
    Map<String, dynamic>? annotation,
  }) async {
    Doc? doc = await ref
        .read(greenVaultProvider)
        .updateDoc(
          name: docName,
          content: newState.toJson(),
          annotation:
              annotation ?? {'author': deviceId, 'authorVersion': version},
        );
    if (doc == null) {
      return false;
    }
    meta = doc.meta;
    return true;
  }

  // get save-to-update copy of vault entry
  UserVaultEntry? copyEntry({required String id}) {
    if (!state.entries.containsKey(id)) {
      return null;
    }

    return UserVaultEntry.fromJson(json.decode(json.encode(state.entries[id])));
  }

  Future<RV> createEntry(UserVaultEntry entry) async {
    for (UserVaultEntry val in state.entries.values) {
      if (entry.id == val.id) {
        return RV.entryExists;
      }

      if (entry.title == val.title && entry.type == val.type) {
        return RV.titleExists;
      }
    }

    log('Adding entry ${entry.title}.', name: _comp);
    entry.updatedAt = DateTime.now().toUtc();
    UserVault stateCopy = UserVault.copy(state);
    stateCopy.entries[entry.id] = entry;
    stateCopy.populateUsernames();
    state = stateCopy; // trigger notification
    return await _updateDoc(newState: stateCopy) ? RV.ok : RV.io;
  }

  Future<RV> updateEntry(UserVaultEntry entry) async {
    if (!state.entries.containsKey(entry.id)) {
      return RV.notFound;
    }

    for (UserVaultEntry val in state.entries.values) {
      if (entry.title == val.title &&
          entry.type == val.type &&
          entry.id != val.id) {
        return RV.titleExists;
      }
    }

    log('Updating entry ${entry.title}.', name: _comp);
    entry.updatedAt = DateTime.now().toUtc();
    UserVault stateCopy = UserVault.copy(state);
    stateCopy.entries[entry.id] = entry;
    stateCopy.populateUsernames();
    state = stateCopy; // trigger notification
    return await _updateDoc(newState: stateCopy) ? RV.ok : RV.io;
  }

  Future<RV> deleteEntry({required String id}) async {
    if (!state.entries.containsKey(id)) {
      return RV.notFound;
    }
    log('Delete entry $id.', name: _comp);
    UserVault stateCopy = UserVault.copy(state);
    stateCopy.entries.remove(id);
    stateCopy.populateUsernames();
    state = stateCopy; // trigger notification
    return await _updateDoc(newState: stateCopy) ? RV.ok : RV.io;
  }

  List<String> search({required String query}) {
    String q = query.toLowerCase();
    List<String> rv = [];

    for (UserVaultEntry entry in state.entries.values) {
      if (entry.title.toLowerCase().contains(q) ||
          entry.username.toLowerCase().contains(q) ||
          entry.notes.toLowerCase().contains(q)) {
        rv.add(entry.id);
        continue;
      }
      for (String uri in entry.uris) {
        if (uri.toLowerCase().contains(q)) {
          rv.add(entry.id);
        }
      }
    }
    return rv;
  }

  Map<String, dynamic> export() {
    return {'content': state.toJson(), 'rev': meta!.revs.export()};
  }

  bool worthUpdate(Revision rev) {
    // ignore initial revision
    if (rev.seq == 1) {
      return false;
    }

    // if our revision is an initial one, the other is preferrable
    if (meta!.revs.current.seq == 1) {
      return true;
    }

    if ((meta!.revs.current.hash == rev.hash) ||
        (meta!.revs.current.date >= rev.date)) {
      return false;
    }

    return true;
  }

  // Import snapshot received from another device.
  Future<bool> import(Map<String, dynamic> snapshot) async {
    Revisions revs = Revisions.import(snapshot['rev']);

    if (!worthUpdate(revs.current)) {
      return false;
    }

    log('Import doc ${revs.current.hash}.', name: _comp);
    UserVault content = UserVault.fromJson(snapshot['content']);
    state = content; // trigger notification
    return await _updateDoc(
      newState: content,
      annotation: {
        'date': revs.current.date,
        'author': revs.current.author,
        'authorHash': revs.current.authorHash,
        'authorVersion': revs.current.authorVersion,
      },
    );
  }

  Revision get currentRevision {
    return meta!.revs.current;
  }
}

class UserVault {
  UserVault();

  // deep copy constructor
  UserVault.copy(UserVault copy) {
    json.decode(json.encode(copy.entries)).forEach((k, v) {
      entries[k] = UserVaultEntry.fromJson(v);
    });
    populateUsernames();
  }

  // serialization constructor
  UserVault.fromJson(Map<String, dynamic> parsedJson) {
    Map parsedEntries = json.decode(parsedJson['entries']);
    parsedEntries.forEach((k, v) {
      entries[k] = UserVaultEntry.fromJson(v);
    });
    populateUsernames();
  }

  Map<String, UserVaultEntry> entries = {};

  // in-memory case-insensitively sorted list of usernames for autocomplete
  List<String> usernames = [];

  // serialization
  Map<String, dynamic> toJson() {
    return {'entries': json.encode(entries)};
  }

  void populateUsernames() {
    Set<String> userSet = {};

    entries.forEach((key, value) {
      if ((value.type == typeLogin) &&
          value.username.isNotEmpty &&
          !userSet.contains(value.username)) {
        userSet.add(value.username);
      }
    });

    usernames = userSet.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }
}

const String typeLogin = 'login';
const String typeNote = 'note';

class UserVaultEntry {
  UserVaultEntry({required this.id, required this.type});

  UserVaultEntry.fromJson(Map<String, dynamic> parsedJson) {
    id = parsedJson['id'];
    type = parsedJson['type'];

    title = parsedJson['title'];
    username = parsedJson['username'];
    password = parsedJson['password'];
    notes = parsedJson['notes'];

    parsedJson['uris'].forEach((v) {
      uris.add(v);
    });

    hidden = parsedJson['hidden'] ?? false;
    updatedAt = DateTime.parse(parsedJson['updatedAt']);
  }

  late String id;
  late String type;

  late String title;
  late String username;
  late String password;
  late String notes;
  List<String> uris = [];
  bool hidden = false;
  DateTime updatedAt = DateTime.now().toUtc();

  // serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'username': username,
      'password': password,
      'notes': notes,
      'uris': uris,
      'hidden': hidden,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
