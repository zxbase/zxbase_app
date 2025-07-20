import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_app/core/const.dart';
import 'package:zxbase_app/providers/green_vault/device_provider.dart';
import 'package:zxbase_app/ui/app_bar.dart';
import 'package:zxbase_app/ui//device_id_widget.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';

class SettingsIdentityWidget extends ConsumerWidget {
  const SettingsIdentityWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String identity = ref.read(deviceProvider).identity.toBase64Url();
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
                      // TODO: re-consider if camera permissions worth the QR code scanning machinery
                      child: Container() /*QrCodeWidget(
                        qrString: identity,
                        maxWidth:
                            constraints.maxWidth *
                            (UI.isDesktop ? 0.8 : double.infinity),
                        maxHeight:
                            constraints.maxHeight *
                            (UI.isDesktop ? 0.3 : double.infinity),
                      ),*/,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: deviceIdWidget(context, deviceId),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: identity));
                          UI.showSnackbar(context, 'Copied!');
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
