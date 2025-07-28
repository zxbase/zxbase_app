import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_app/providers/blue_vault/init_provider.dart';
import 'package:zxbase_app/ui/common/app_bar.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';

class SettingsAppearanceWidget extends ConsumerWidget {
  const SettingsAppearanceWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String theme = ref.watch(initProvider).theme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Appearance'),
        bottom: preferredSizeDivider(height: 0.5),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              fit: FlexFit.tight,
              child: Padding(
                padding: const EdgeInsets.only(top: 0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      RadioListTile<String>(
                        title: Text(
                          'Light theme',
                          style: TextStyle(fontSize: UI.fontSizeMedium),
                        ),
                        value: 'light',
                        groupValue: theme,
                        onChanged: (String? value) async {
                          await ref
                              .read(initProvider.notifier)
                              .setTheme(value!);
                        },
                      ),
                      RadioListTile<String>(
                        title: Text(
                          'Dark theme',
                          style: TextStyle(fontSize: UI.fontSizeMedium),
                        ),
                        value: 'dark',
                        groupValue: theme,
                        onChanged: (String? value) async {
                          await ref
                              .read(initProvider.notifier)
                              .setTheme(value!);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
