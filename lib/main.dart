import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_app/providers/blue_vault/init_provider.dart';
import 'package:zxbase_app/ui/launch/init_vault_widget.dart';
import 'package:zxbase_app/ui/launch/open_vault_widget.dart';
import 'package:zxbase_app/ui/launch/splash_widget.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';

const _component = 'main'; // logging component

class ZxbaseApp extends ConsumerWidget {
  const ZxbaseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var init = ref.read(initProvider);

    log('Build Zxbase app.', name: _component);

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

void startApp() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: ZxbaseApp()));
}

void main() {
  runApp(
    ProviderScope(
      child: SplashWidget(onInitializationComplete: () => startApp()),
    ),
  );
}
