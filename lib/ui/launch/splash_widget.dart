import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:zxbase_app/providers/config_provider.dart';
import 'package:zxbase_app/providers/blue_vault/blue_vault_provider.dart';
import 'package:zxbase_app/providers/blue_vault/init_provider.dart';
import 'package:zxbase_app/ui/launch/spin_widget.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';

const component = 'splashWidget'; // logging component

// Splash widget is used to initialize async resources before main application starts.
class SplashWidget extends ConsumerStatefulWidget {
  const SplashWidget({super.key, required this.onInitializationComplete});

  final VoidCallback onInitializationComplete;

  @override
  ConsumerState createState() => _SplashWidgetState();
}

class _SplashWidgetState extends ConsumerState<SplashWidget> {
  late Config confProvider;

  void _startup() async {
    log('Executing startup sequence.', name: component);

    await confProvider.init();
    log('Configuration initialized.', name: component);

    await ref.read(blueVaultProvider.notifier).init();
    log('Blue vault initialized.', name: component);

    await ref.read(initProvider.notifier).init();
    log('Init doc initialized.', name: component);

    widget.onInitializationComplete();
  }

  @override
  void initState() {
    super.initState();
    confProvider = ref.read(configProvider);
    _startup();
  }

  @override
  Widget build(BuildContext context) {
    log('Build splash widget.', name: component);

    return MaterialApp(
      title: 'Zxbase',
      theme: AppTheme.build(AppTheme.light),
      home: SpinWidget(),
      debugShowCheckedModeBanner: false,
    );
  }
}
