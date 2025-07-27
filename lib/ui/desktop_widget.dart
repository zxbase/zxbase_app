import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_app/ui/explorer_widget.dart';
import 'package:zxbase_app/ui/devices/device_details_widget.dart';
import 'package:zxbase_app/ui/settings/settings_about_widget.dart';
import 'package:zxbase_app/ui/settings/settings_appearance_widget.dart';
import 'package:zxbase_app/ui/settings/settings_identity_widget.dart';
import 'package:zxbase_app/ui/vault/vault_secret_widget.dart';
import 'package:zxbase_app/providers/ui_providers.dart';

class DesktopWidget extends ConsumerWidget {
  const DesktopWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    BarItem selectedTab = ref.watch(selectedTabProvider);
    bool isNewVaultEntry = ref.watch(newVaultEntryProvider);
    var selectedVaultEntryId = ref.watch(selectedVaultEntryProvider);
    SettingItem selectedSetting = ref.watch(selectedSettingProvider);
    String selectedDeviceId = ref.watch(selectedDeviceProvider);
    Widget widget;

    switch (selectedTab) {
      case BarItem.vault:
        widget = (isNewVaultEntry || selectedVaultEntryId != '')
            ? VaultSecretWidget()
            : Container();
      case BarItem.devices:
        if (selectedDeviceId == '') {
          widget = Container();
        } else {
          widget = DeviceDetailsWidget(peerId: selectedDeviceId);
        }
      case BarItem.settings:
        switch (selectedSetting) {
          case SettingItem.identity:
            widget = const SettingsIdentityWidget();
          case SettingItem.appearance:
            widget = const SettingsAppearanceWidget();
          case SettingItem.about:
            widget = const SettingsAboutWidget();
          case SettingItem.none:
            widget = Container();
        }
    }

    return Scaffold(
      body: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.38,
            child: const ExplorerWidget(),
          ),
          const VerticalDivider(width: 0),
          Expanded(child: widget),
        ],
      ),
    );
  }
}
