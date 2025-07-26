import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_app/providers/green_vault/device_provider.dart';
import 'package:zxbase_app/providers/green_vault/peers_provider.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';
import 'package:zxbase_vault/zxbase_vault.dart';

String humanRevisionAuthor(Revision revision, WidgetRef ref) {
  String author;
  if (revision.author == '') {
    author = '';
  } else if (revision.author == ref.read(deviceProvider).id) {
    author = 'by me';
  } else {
    if (ref.read(peersProvider).peers.containsKey(revision.author)) {
      author = 'by ${ref.read(peersProvider).peers[revision.author]!.nickname}';
    } else {
      author = '';
    }
  }
  return author;
}

String humanRevisionDate(Revision revision) {
  if (revision.hash.isNotEmpty) {
    return HumanTime.shortDateTimeFromTS(revision.date);
  } else {
    return '';
  }
}

String humanRevision(Revision revision) {
  if (revision.hash.isNotEmpty) {
    return 'revision ${revision.hash.substring(0, 8)},';
  } else {
    return '';
  }
}

String shortHumanRevision(Revision revision, WidgetRef ref) {
  return '${humanRevisionDate(revision)} ${humanRevisionAuthor(revision, ref)}';
}

String fullHumanRevision(Revision revision, WidgetRef ref) {
  return '${humanRevision(revision)} ${humanRevisionDate(revision)} ${humanRevisionAuthor(revision, ref)}';
}
