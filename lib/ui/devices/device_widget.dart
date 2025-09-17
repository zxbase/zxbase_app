import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_app/core/const.dart';
import 'package:zxbase_app/providers/green_vault/peer_group_provider.dart';
import 'package:zxbase_app/providers/green_vault/peers_provider.dart';
import 'package:zxbase_app/providers/ui_providers.dart';
import 'package:zxbase_app/ui/common/avatar.dart';
import 'package:zxbase_app/ui/devices/device_details_widget.dart';
import 'package:zxbase_app/ui/devices/revision.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';
import 'package:zxbase_vault/zxbase_vault.dart';

enum SyncPeerState {
  synced,
  syncedOffline,
  supposedlySynced,
  unknown,
  different,
}

Map stateIcon = {
  SyncPeerState.synced: Icon(
    Icons.check_rounded,
    color: Colors.green.shade600,
    size: 16,
  ),
  SyncPeerState.syncedOffline: const Icon(
    Icons.check_rounded,
    color: Colors.grey,
    size: 16,
  ),
  SyncPeerState.supposedlySynced: const Icon(
    Icons.check_rounded,
    color: Colors.orange,
    size: 16,
  ),
  SyncPeerState.unknown: const Icon(
    Icons.question_mark_rounded,
    color: Colors.grey,
    size: 16,
  ),
  SyncPeerState.different: const Icon(
    Icons.error_rounded,
    color: Colors.red,
    size: 16,
  ),
};

Map<SyncPeerState, String> stateTooltip = {
  SyncPeerState.synced: 'Up to date',
  SyncPeerState.syncedOffline: 'Last known revision is up to date',
  SyncPeerState.unknown: 'Unknown',
  SyncPeerState.different: Const.vaultSyncWarn,
};

class DeviceWidget extends ConsumerWidget {
  const DeviceWidget({
    super.key,
    required this.peer,
    required this.remotePeer,
    required this.myRevision,
  });

  final Peer peer;
  final RemotePeer remotePeer;
  final Revision myRevision;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color secondaryColor = Theme.of(context).textTheme.bodySmall!.color!;
    double dividerIndent = UI.isDesktop ? 57 : 62;

    String subtitle = '';
    SyncPeerState syncState = SyncPeerState.unknown;

    if (remotePeer.revision.hash == myRevision.hash) {
      subtitle = fullHumanRevision(remotePeer.revision, ref);
      syncState = (peer.status == peerStatusOnline)
          ? SyncPeerState.synced
          : SyncPeerState.syncedOffline;
    } else {
      if (remotePeer.revision.date == myRevision.date) {
        // most likely same revision, devices of different versions
        subtitle = shortHumanRevision(remotePeer.revision, ref);
        syncState = SyncPeerState.supposedlySynced;
      } else {
        subtitle = fullHumanRevision(remotePeer.revision, ref);
        syncState = (remotePeer.revision.hash == '')
            ? SyncPeerState.unknown
            : SyncPeerState.different;
      }
    }

    return Row(
      children: <Widget>[
        Expanded(
          flex: 10,
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.only(left: 10),
                title: Text(
                  peer.nickname,
                  style: TextStyle(fontSize: UI.listTitleFontSize(context)),
                ),
                subtitle: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: UI.fontSizeSmall,
                    color: secondaryColor,
                  ),
                ),
                leading: Avatar.peer(
                  name: peer.nickname,
                  status: avatarStatus(peer.status),
                ),
                trailing: IconButton(
                  icon: stateIcon[syncState],
                  tooltip: stateTooltip[syncState],
                  onPressed: () {},
                ),
                onTap: () async {
                  if (UI.isDesktop) {
                    ref.read(selectedDeviceProvider.notifier).set(peer.id);
                  } else {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DeviceDetailsWidget(peerId: peer.id),
                      ),
                    );
                  }
                },
              ),
              Divider(indent: dividerIndent, height: 1),
            ],
          ),
        ),
      ],
    );
  }
}
