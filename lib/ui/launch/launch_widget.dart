// Show spinning wheel while executing workflows.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_api_client/zxbase_api_client.dart';
import 'package:zxbase_app/core/mock_peers.dart';
import 'package:zxbase_app/ui/desktop_widget.dart';
import 'package:zxbase_app/ui/explorer_widget.dart';
import 'package:zxbase_app/providers/launch_provider.dart';
import 'package:zxbase_app/providers/config_provider.dart';
import 'package:zxbase_app/providers/connections_provider.dart';
import 'package:zxbase_app/providers/blue_vault/init_provider.dart';
import 'package:zxbase_app/providers/green_vault/device_provider.dart';
import 'package:zxbase_app/providers/green_vault/peers_provider.dart';
import 'package:zxbase_app/providers/green_vault/peer_group_provider.dart';
import 'package:zxbase_app/providers/rps_provider.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';

class LaunchWidget extends ConsumerStatefulWidget {
  const LaunchWidget({super.key});
  @override
  WorkflowPageState createState() => WorkflowPageState();
}

class WorkflowPageState extends ConsumerState<LaunchWidget> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _load(ref);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    LaunchStage stage = ref.watch(launchProvider);

    return Builder(
      builder: (context) {
        return Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                Form(
                  key: _formKey,
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 150,
                            width: 150,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          Text(stage.err),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _load(WidgetRef ref) async {
    Config conf = ref.read(configProvider);
    Device device = ref.read(deviceProvider);

    // initialize RPS (API) client
    RpsClient rps = ref.read(rpsProvider);
    rps.init(
      host: conf.rpsHost,
      port: conf.rpsPort,
      identity: device.identity,
      keyPair: device.identityKeyPair,
    );

    // Initialize conections before ws connects, there are
    // could be signaling messages coming immediately.
    if (!UI.testEnvironment) {
      Connections connections = ref.read(connectionsProvider);
      for (Peer peer in ref.read(peersProvider).peers.values) {
        await connections.initConnection(
          peerId: peer.id,
          vaultEnabled: ref
              .read(peerGroupsProvider)
              .memberOfVaultGroup(peerId: peer.id),
        );
      }
    }

    LaunchNotifier launchNotifier = ref.read(launchProvider.notifier);
    if (!mounted) return;
    launchNotifier.setContext(context);

    Init init = ref.read(initProvider);
    switch (init.wizardStage) {
      case Init.vaultInitialized:
        // execute registration workflow
        await launchNotifier.registerAnonymous();
        await launchNotifier.accessAnonymous();
        // development only - populate the vault with mock data
        if (UI.testEnvironment) {
          await mockPeers(ref.read(peersProvider.notifier));
        }
        break;
      case Init.deviceRegistered:
      case Init.completed:
        // execute access workflow
        await launchNotifier.accessAnonymous();
        break;
      default:
        throw Exception('Incorrect init stage ${init.wizardStage}.');
    }

    // start periodic jobs
    // TODO: re-enable dispatcher
    // await ref.read(dispatcherProvider).start();

    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => UI.isDesktop ? DesktopWidget() : ExplorerWidget(),
        maintainState: false,
      ),
    );
  }
}
