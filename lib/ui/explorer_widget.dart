import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_app/core/const.dart';
import 'package:zxbase_app/providers/green_vault/peer_group_provider.dart';
import 'package:zxbase_app/providers/ui_providers.dart';
import 'package:zxbase_app/ui/devices/devices_widget.dart';
import 'package:zxbase_app/ui/common/dialogs.dart';
import 'package:zxbase_app/ui/common/red_badge.dart';
import 'package:zxbase_app/ui/settings/settings_widget.dart';
import 'package:zxbase_app/ui/vault/vault_widget.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';

List<Widget> buildSettingsBarItem(String warning) {
  List<Widget> rv = <Widget>[const Icon(Icons.settings_rounded)];

  if (warning.isNotEmpty) {
    rv.add(const Positioned(top: 0.0, right: 0.0, child: RedBadge()));
  }

  return rv;
}

List<Widget> buildVaultBarItem(PeerGroup vaultGroup, String warning) {
  List<Widget> rv = <Widget>[const Icon(Icons.devices_rounded)];

  if (vaultGroup.isEmpty || warning != '') {
    rv.add(const Positioned(top: 0.0, right: 0.0, child: RedBadge()));
  }

  return rv;
}

class ExplorerWidget extends ConsumerWidget {
  const ExplorerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    BarItem selectedTab = ref.watch(selectedTabProvider);
    String syncWarn = ref.watch(vaultSyncWarningProvider);
    PeerGroup vaultGroup = ref.watch(peerGroupsProvider).vaultGroup;
    String versionWarn = ref.watch(versionWarningProvider);

    Widget explorerWidget;
    switch (selectedTab) {
      case BarItem.vault:
        explorerWidget = const VaultWidget();
      case BarItem.devices:
        explorerWidget = const DevicesWidget();
      case BarItem.settings:
        explorerWidget = const SettingsWidget();
    }

    List<Widget> devicesBarItem = buildVaultBarItem(vaultGroup, syncWarn);
    List<Widget> settingsBarItem = buildSettingsBarItem(versionWarn);

    return Scaffold(
      body: Center(child: explorerWidget),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 0.5),
          BottomNavigationBar(
            key: const Key('bottomBar'),
            elevation: 0,
            selectedFontSize: UI.fontSizeXSmall,
            unselectedFontSize: UI.fontSizeXSmall,
            type: BottomNavigationBarType.fixed,
            unselectedItemColor: Colors.grey,
            iconSize: UI.isMobile ? 30 : IconTheme.of(context).size ?? 24,
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                label: 'Vault',
                icon: Icon(Icons.lock_rounded),
              ),
              BottomNavigationBarItem(
                label: 'Devices',
                icon: Stack(children: devicesBarItem),
              ),
              BottomNavigationBarItem(
                label: 'Settings',
                icon: Stack(children: settingsBarItem),
              ),
            ],
            currentIndex: selectedTab.ind,
            onTap: (int index) {
              if (ref.read(isVaultEntryDirtyProvider) &&
                  index != BarItem.vault.ind) {
                showCustomDialog(
                  context,
                  Container(),
                  title: Const.discardWarn,
                  leftButtonText: 'Yes',
                  rightButtonText: 'No',
                  onLeftTap: () {
                    ref.read(isVaultEntryDirtyProvider.notifier).state = false;
                    Navigator.pop(context);
                    ref.read(selectedTabProvider.notifier).state =
                        BarItem.values[index];
                  },
                );
              } else {
                ref.read(selectedTabProvider.notifier).state =
                    BarItem.values[index];
              }
            },
          ),
        ],
      ),
    );
  }
}
