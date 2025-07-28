import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_app/providers/ui_providers.dart';
import 'package:zxbase_app/ui/common/app_bar.dart';
import 'package:zxbase_app/ui/settings/settings_list_item_widget.dart';

class SettingsWidget extends ConsumerWidget {
  const SettingsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(selectedSettingProvider);
    ref.watch(versionWarningProvider);

    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Scaffold(
        appBar: AppBar(
          actions: const [],
          title: const Text('Settings'),
          centerTitle: true,
          bottom: preferredSizeDivider(height: 0.5),
        ),
        body: Padding(
          padding: const EdgeInsets.only(right: 0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(),
            child: ListView.builder(
              controller: ScrollController(),
              itemCount: SettingItem.values.length - 1,
              itemBuilder: (BuildContext context, int index) {
                bool isSelected =
                    (index == ref.read(selectedSettingProvider).ind);
                String warn = '';
                if (index == SettingItem.about.ind) {
                  warn = ref.read(versionWarningProvider);
                }
                return SettingsListItemWidget(
                  item: SettingItem.values[index],
                  isSelected: isSelected,
                  warn: warn,
                );
              },
              shrinkWrap: true,
            ),
          ),
          //),
        ),
      ),
    );
  }
}
