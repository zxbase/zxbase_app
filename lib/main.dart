import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_app/ui/launch/init_vault_widget.dart';
import 'package:zxbase_app/ui/launch/open_vault_widget.dart';
import 'package:zxbase_app/providers/blue_vault/init_provider.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';

void main() {
  runApp(ProviderScope(child: const ZxbaseApp()));
}

class ZxbaseApp extends ConsumerWidget {
  const ZxbaseApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var init = ref.read(initProvider);

    // theme reloads from here
    final initProv = ref.watch(initProvider);
    AppTheme.setOverlayStyle(initProv.theme);
    var theme = AppTheme.build(initProv.theme);

    return MaterialApp(
      title: 'Zxbase',
      theme: theme,
      home: (init.wizardStage == Init.none)
          ? InitVaultWidget()
          : OpenVaultWidget(),
      debugShowCheckedModeBanner: false,
    );
  }
}
