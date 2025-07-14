import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_app/core/const.dart';
import 'package:zxbase_app/providers/ui_providers.dart';
import 'package:zxbase_app/ui/dialogs.dart';
import 'package:zxbase_app/ui/vault/vault_entry_list_widget.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';

enum AppTab { convos, peers, locations, settings }

class ExplorerWidget extends ConsumerStatefulWidget {
  const ExplorerWidget({super.key});

  @override
  ConsumerState createState() => ExplorerWidgetState();
}

class ExplorerWidgetState extends ConsumerState<ExplorerWidget> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  void _barItemTapped(int index) {
    if (ref.read(isVaultEntryDirtyProvider) && index != AppTab.convos.index) {
      showCustomDialog(
        context,
        Container(),
        title: Const.discardWarn,
        leftButtonText: 'Yes',
        rightButtonText: 'No',
        onLeftTap: () {
          ref.read(isVaultEntryDirtyProvider.notifier).state = false;
          Navigator.pop(context);

          setState(() {
            ref.read(selectedTabProvider.notifier).state = index;
            _selectedIndex = index;
          });
        },
      );
    } else {
      setState(() {
        ref.read(selectedTabProvider.notifier).state = index;
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _selectedIndex = ref.watch(selectedTabProvider);

    return Scaffold(
      body: Center(child: VaultEntryListWidget()),
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
            currentIndex: _selectedIndex,
            onTap: _barItemTapped,
          ),
        ],
      ),
    );
  }
}
