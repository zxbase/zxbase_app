import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_app/core/const.dart';
import 'package:zxbase_app/providers/ui_providers.dart';
import 'package:zxbase_app/ui/devices/devices_widget.dart';
import 'package:zxbase_app/ui/dialogs.dart';
import 'package:zxbase_app/ui/settings/settings_widget.dart';
import 'package:zxbase_app/ui/vault/vault_widget.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';

class ExplorerWidget extends ConsumerWidget {
  const ExplorerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    BarItem selectedTab = ref.watch(selectedTabProvider);
    Widget explorerWidget;

    switch (selectedTab) {
      case BarItem.vault:
        explorerWidget = const VaultWidget();
      case BarItem.devices:
        explorerWidget = const DevicesWidget();
      case BarItem.settings:
        explorerWidget = const SettingsWidget();
    }

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
                icon: Icon(Icons.devices_rounded),
              ),
              BottomNavigationBarItem(
                label: 'Settings',
                icon: Icon(Icons.settings_rounded),
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
