import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_app/ui/devices/device_widget.dart';
import 'package:zxbase_app/providers/green_vault/peer_group_provider.dart';
import 'package:zxbase_app/providers/green_vault/peers_provider.dart';
import 'package:zxbase_app/providers/green_vault/user_vault_provider.dart';
import 'package:zxbase_vault/zxbase_vault.dart';

class DevicesListWidget extends ConsumerWidget {
  const DevicesListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Peers peers = ref.watch(peersProvider);
    PeerGroup vaultGroup = ref.watch(peerGroupsProvider).vaultGroup;
    ref.watch(userVaultProvider);
    Revision myRevision = ref.read(userVaultProvider.notifier).currentRevision;

    return Padding(
      padding: const EdgeInsets.only(right: 1.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(),
        child: ListView.builder(
          controller: ScrollController(),
          itemCount: vaultGroup.peerIds.length,
          itemBuilder: (BuildContext context, int index) {
            String peerId = vaultGroup.peerIds[index];
            Peer? peer = peers.peers[peerId];
            if (peer == null) {
              return Container();
            }

            RemotePeer remotePeer = vaultGroup.peers[peerId]!;
            return DeviceWidget(
              peer: peer,
              remotePeer: remotePeer,
              myRevision: myRevision,
            );
          },
          shrinkWrap: true,
        ),
      ),
      //),
    );
  }
}
