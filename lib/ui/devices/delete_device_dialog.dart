import 'package:zxbase_app/providers/connections_provider.dart';
import 'package:zxbase_app/providers/green_vault/peer_group_provider.dart';
import 'package:zxbase_app/providers/green_vault/peers_provider.dart';
import 'package:zxbase_app/providers/ui_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';

Future<void> deletePeer({
  required WidgetRef ref,
  required String peerId,
}) async {
  if (UI.isMobile) {
    _clearSelectedPeer(ref);
  }

  // delete connection, peer, vault group
  await ref.read(connectionsProvider).deleteConnection(peerId: peerId);
  await ref.read(peersProvider.notifier).deletePeer(peerId: peerId);
  await ref
      .read(peerGroupsProvider.notifier)
      .deleteVaultGroupPeer(peerId: peerId);

  if (UI.isDesktop) {
    _clearSelectedPeer(ref);
  }
}

void _clearSelectedPeer(WidgetRef ref) {
  ref.read(selectedDeviceProvider.notifier).set('');
}
