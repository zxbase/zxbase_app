import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_app/core/const.dart';
import 'package:zxbase_app/core/rv.dart';
import 'package:zxbase_app/ui/dialogs.dart';
import 'package:zxbase_app/ui/vault/vault_secret_widget.dart';
import 'package:zxbase_app/providers/green_vault/user_vault_provider.dart';
import 'package:zxbase_app/providers/ui_providers.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';

Future<void> deleteVaultEntry({
  required WidgetRef ref,
  required String entryId,
}) async {
  if (UI.isMobile) {
    _clearSelectedPeer(ref);
  }

  await ref.read(userVaultProvider.notifier).deleteEntry(id: entryId);

  if (UI.isDesktop) {
    _clearSelectedPeer(ref);
  }
}

void _clearSelectedPeer(WidgetRef ref) {
  ref.read(selectedVaultEntryProvider.notifier).state = '';
}

class VaultEntryWidget extends ConsumerWidget {
  const VaultEntryWidget({
    super.key,
    required this.entry,
    required this.isSelected,
  });

  final UserVaultEntry entry;
  final bool isSelected;

  void _switchOnDesktop(BuildContext context, WidgetRef ref, String entryId) {
    if (ref.read(isVaultEntryDirtyProvider) &&
        entry.id != ref.read(selectedVaultEntryProvider)) {
      showCustomDialog(
        context,
        Container(),
        title: Const.discardWarn,
        leftButtonText: 'Yes',
        rightButtonText: 'No',
        onLeftTap: () {
          ref.read(selectedVaultEntryProvider.notifier).state = entryId;
          ref.read(newVaultEntryProvider.notifier).state = false;
          ref.read(isVaultEntryDirtyProvider.notifier).state = false;
          Navigator.pop(context);
        },
      );
    } else {
      ref.read(selectedVaultEntryProvider.notifier).state = entryId;
      ref.read(newVaultEntryProvider.notifier).state = false;
    }
  }

  Widget entryLead(String type) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[const Icon(Icons.password_rounded)],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String subtitle = '';
    if (entry.type == typeLogin) {
      subtitle = entry.username;
    } else if (entry.type == typeNote) {
      subtitle = HumanTime.shortDate(entry.updatedAt.toLocal());
    }

    return Row(
      children: <Widget>[
        Expanded(
          flex: 10,
          child: Column(
            children: [
              ListTile(
                horizontalTitleGap: 0.0,
                leading: entryLead(entry.type),
                title: Text(
                  entry.title,
                  style: TextStyle(fontSize: UI.listTitleFontSize(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: subtitle.isNotEmpty
                    ? Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: UI.listSubtitleFontSize(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                selected: UI.isDesktop && isSelected,
                onTap: () async {
                  if (UI.isDesktop) {
                    _switchOnDesktop(context, ref, entry.id);
                  } else {
                    ref.read(selectedVaultEntryProvider.notifier).state =
                        entry.id;
                    var result = await Navigator.push(
                      context,
                      (MaterialPageRoute(
                        builder: (context) => VaultSecretWidget(),
                      )),
                    );
                    if (result == RV.delete) {
                      await deleteVaultEntry(ref: ref, entryId: entry.id);
                    }
                  }
                },
                onLongPress: () {
                  if (UI.isDesktop) {
                    // mobile only
                    return;
                  }
                },
              ),
              const Divider(height: 1),
            ],
          ),
        ),
      ],
    );
  }
}
