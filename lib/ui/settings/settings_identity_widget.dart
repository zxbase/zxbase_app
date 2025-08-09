import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_app/core/const.dart';
import 'package:zxbase_app/providers/green_vault/device_provider.dart';
import 'package:zxbase_app/ui/common/app_bar.dart';
import 'package:zxbase_app/ui/common/device_id_widget.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';

class SettingsIdentityWidget extends ConsumerWidget {
  const SettingsIdentityWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String identityKey = ref.read(deviceProvider).identity.toBase64Url();
    String deviceId = ref.read(deviceProvider).id;

    return LayoutBuilder(
      builder: (builder, constraints) {
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text('Identity'),
            bottom: preferredSizeDivider(height: 0.5),
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: deviceIdWidget(
                        context: context,
                        deviceId: deviceId,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: identityKey));
                          UI.showSnackbar(context, Const.copyClip);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            Const.copyIdnt,
                            style: TextStyle(fontSize: UI.fontSizeLarge),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
