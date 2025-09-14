import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_app/ui/settings/settings_about_widget.dart';
import 'package:zxbase_app/ui/settings/settings_appearance_widget.dart';
import 'package:zxbase_app/ui/settings/settings_identity_widget.dart';
import 'package:zxbase_app/providers/ui_providers.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';

class SettingsListItemWidget extends ConsumerWidget {
  const SettingsListItemWidget({
    super.key,
    required this.item,
    required this.isSelected,
    required this.warn,
  });

  final SettingItem item;
  final bool isSelected;
  final String warn;

  void _onTap(BuildContext context, WidgetRef ref) {
    if (UI.isDesktop) {
      ref.read(selectedSettingProvider.notifier).set(item);
    } else {
      switch (item) {
        case (SettingItem.identity):
          Navigator.push(
            context,
            (MaterialPageRoute(
              builder: (context) => const SettingsIdentityWidget(),
            )),
          );
          break;
        case (SettingItem.appearance):
          Navigator.push(
            context,
            (MaterialPageRoute(
              builder: (context) => const SettingsAppearanceWidget(),
            )),
          );
          break;
        case (SettingItem.about):
          Navigator.push(
            context,
            (MaterialPageRoute(
              builder: (context) => const SettingsAboutWidget(),
            )),
          );
          break;
        default:
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget lead;
    switch (item) {
      case SettingItem.identity:
        lead = const Icon(Icons.account_circle_rounded);
        break;
      case SettingItem.appearance:
        lead = const Icon(Icons.brush_rounded);
        break;
      default:
        lead = const Icon(Icons.info_outline_rounded);
        break;
    }
    Widget centeredLead = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[lead],
    );

    return Row(
      children: <Widget>[
        Expanded(
          flex: 10,
          child: Column(
            children: [
              ListTile(
                horizontalTitleGap: 0.0,
                key: Key(item.title),
                leading: centeredLead,
                title: Text(
                  item.title,
                  style: TextStyle(fontSize: UI.listTitleFontSize(context)),
                ),
                selected: isSelected,
                trailing: warn.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.error_rounded,
                          color: Colors.red,
                          size: 16,
                        ),
                        tooltip: warn,
                        onPressed: () {
                          _onTap(context, ref);
                        },
                      )
                    : null,
                onTap: () {
                  _onTap(context, ref);
                },
                onLongPress: () {
                  if (UI.isDesktop) {
                    // mobile only
                    return;
                  }
                },
              ),
              const Divider(height: 1),
            ],
          ),
        ),
      ],
    );
  }
}
