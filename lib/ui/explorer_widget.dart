import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_app/providers/ui_providers.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';

class ExplorerWidget extends ConsumerStatefulWidget {
  const ExplorerWidget({super.key});

  @override
  ConsumerState createState() => _StartPageState();
}

class _StartPageState extends ConsumerState<ExplorerWidget> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _selectedIndex = ref.watch(selectedTabProvider);

    return Scaffold(
      body: Center(child: Container()),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 0.5),
          BottomNavigationBar(
            key: const Key('bottomBar'),
            elevation: 0,
            selectedFontSize: UI.fontSizeXSmall, // 0,
            unselectedFontSize: UI.fontSizeXSmall, // 0,
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
          ),
        ],
      ),
    );
  }
}
