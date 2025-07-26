import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_app/core/const.dart';
import 'package:zxbase_app/providers/green_vault/peer_group_provider.dart';
import 'package:zxbase_app/providers/green_vault/settings_provider.dart';
import 'package:zxbase_app/providers/green_vault/user_vault_provider.dart';
import 'package:zxbase_app/providers/ui_providers.dart';
import 'package:zxbase_app/providers/vault_sync_provider.dart';
import 'package:zxbase_app/ui/app_bar.dart';
import 'package:zxbase_app/ui/devices/devices_list_widget.dart';
import 'package:zxbase_app/ui/devices/revision.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';
import 'package:zxbase_vault/zxbase_vault.dart';

final policyCaption = {
  Settings.automatic: 'apply automatically',
  Settings.manual: 'approve manually',
  Settings.ignore: 'ignore',
};

final policyIndex = {
  Settings.automatic: 1,
  Settings.manual: 2,
  Settings.ignore: 3,
};

final policyCodes = [Settings.automatic, Settings.manual, Settings.ignore];

class DevicesWidget extends ConsumerWidget {
  const DevicesWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color secondaryColor = Theme.of(context).textTheme.bodySmall!.color!;
    ref.watch(userVaultProvider);
    Revision revision = ref.read(userVaultProvider.notifier).meta!.revs.current;

    PeerGroup vaultGroup = ref.watch(peerGroupsProvider).vaultGroup;
    String syncWarn = ref.watch(vaultSyncWarningProvider);
    String warn = vaultGroup.isEmpty ? Const.vaultGroupWarn : '';

    // policy
    String updatePolicy = ref.watch(settingsProvider).vaultUpdatePolicy;
    int sliderValue = policyIndex[updatePolicy]!;

    // import vault
    Map<String, dynamic> vaultCandidate = {};
    if (updatePolicy == Settings.manual) {
      vaultCandidate = ref.watch(vaultCandidateProvider);
    }
    bool showImport =
        vaultCandidate.isNotEmpty && (updatePolicy == Settings.manual);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Devices'),
        bottom: preferredSizeDivider(height: 0.5),
      ),
      body: SafeArea(
        //child: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  children: [
                    Text(
                      'Local vault',
                      style: TextStyle(fontSize: UI.fontSizeLarge),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: 8.0,
                  left: 10.0,
                  right: 10.0,
                ),
                child: Column(
                  children: [
                    Text(
                      fullHumanRevision(revision, ref),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: UI.fontSizeSmall,
                        color: secondaryColor,
                      ),
                    ),
                    syncWarn == ''
                        ? Container()
                        : Text(
                            Const.vaultSyncWarn,
                            style: TextStyle(
                              fontSize: UI.fontSizeMedium,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: 16.0,
                  left: 10.0,
                  right: 10.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Incoming updates:'),
                    Text(policyCaption[updatePolicy]!),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Slider(
                          value: sliderValue.toDouble(),
                          min: 1,
                          max: 3,
                          onChanged: (value) {
                            if (value.toInt() != sliderValue) {
                              sliderValue = value.toInt();
                              ref
                                  .read(settingsProvider.notifier)
                                  .setVaultUpdatePolicy(
                                    policyCodes[value.toInt() - 1],
                                  );
                            }
                          },
                        ),
                      ],
                    ),
                    showImport
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                fullHumanRevision(vaultCandidate['_rev'], ref),
                                style: TextStyle(
                                  fontSize: UI.fontSizeSmall,
                                  color: secondaryColor,
                                ),
                              ),
                            ],
                          )
                        : Container(),
                    showImport
                        ? Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: ElevatedButton(
                              onPressed: () async {
                                await ref
                                    .read(vaultSyncProvider)
                                    .importCandidateVault(vaultCandidate);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                ),
                                child: Text(
                                  'Approve',
                                  style: TextStyle(fontSize: UI.fontSizeLarge),
                                ),
                              ),
                            ),
                          )
                        : Container(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Column(
                  children: [
                    Text(
                      'Devices',
                      style: TextStyle(fontSize: UI.fontSizeLarge),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(5.0),
                child: DevicesListWidget(),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: vaultGroup.isEmpty
                    ? Text(
                        warn,
                        style: TextStyle(
                          fontSize: UI.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      )
                    : Container(),
              ),
            ],
          ),
        ),
      ),
      // ),
    );
  }
}
