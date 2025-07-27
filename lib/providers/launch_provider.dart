// Launch provider executes launch sequence.
// Doesn't persist any data.

import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_api_client/zxbase_api_client.dart';
import 'package:zxbase_app/core/mock_peers.dart';
import 'package:zxbase_app/providers/config_provider.dart';
import 'package:zxbase_app/providers/connections_provider.dart';
import 'package:zxbase_app/providers/dispatcher_provider.dart';
import 'package:zxbase_app/providers/blue_vault/init_provider.dart';
import 'package:zxbase_app/providers/green_vault/device_provider.dart';
import 'package:zxbase_app/providers/green_vault/peers_provider.dart';
import 'package:zxbase_app/providers/green_vault/peer_group_provider.dart';
import 'package:zxbase_app/providers/rps_provider.dart';
import 'package:zxbase_app/providers/ws_provider.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';

const _component = 'launchProvider'; // logging component

enum LaunchStageEnum {
  initializing,
  success,
  fail,
  registeringDevice,
  acquiringRegistrationToken,
  acquiringRegularToken,
}

class LaunchStage {
  LaunchStage({required this.stage, required this.msg, this.err = ''});
  final LaunchStageEnum stage;
  final String msg;
  final String err;
}

final launchProvider = StateNotifierProvider<LaunchNotifier, LaunchStage>(
  (ref) => LaunchNotifier(ref),
);

class LaunchNotifier extends StateNotifier<LaunchStage> {
  LaunchNotifier(this.ref)
    : super(LaunchStage(stage: LaunchStageEnum.initializing, msg: ''));
  final Ref ref;
  static const retryInterval = 5;

  Future<void> logAndWait(String msg) async {
    log(msg, name: _component);
    await Future.delayed(const Duration(seconds: retryInterval));
  }

  Future<void> registerAnonymous() async {
    // Register anonymous device, obtain regular token.
    // Retry each stage till the launch is completed.
    log('Started registration.', name: _component);
    // trigger notification
    state = LaunchStage(
      stage: LaunchStageEnum.acquiringRegistrationToken,
      msg: 'Preparing...',
    );

    bool rv = false;
    while (!rv) {
      try {
        // exceptions can come when the network is not available
        rv = await ref.read(rpsProvider).obtainToken(topic: registrationTopic);
      } catch (e) {
        log('Registration token exception: $e.', name: _component);
        // trigger notification
        state = LaunchStage(
          stage: LaunchStageEnum.acquiringRegistrationToken,
          msg: 'Preparing...',
          err: 'Initial connectivity failed. Retrying.',
        );
      }
      if (!rv) {
        await logAndWait('Retrying registration token.');
      }
    }

    // trigger notification
    state = LaunchStage(
      stage: LaunchStageEnum.registeringDevice,
      msg: 'Registering device...',
    );

    rv = false;
    while (!rv) {
      try {
        // exceptions can come when the network is not available
        rv = await ref.read(rpsProvider).register(metadata: '');
      } catch (e) {
        log('Device registration exception: $e.', name: _component);
        // trigger notification
        state = LaunchStage(
          stage: LaunchStageEnum.registeringDevice,
          msg: 'Registering device...',
          err: 'Registration failed. Retrying.',
        );
      }
      if (!rv) {
        await logAndWait('Retrying device registration.');
      }
    }
    await ref.read(initProvider.notifier).setWizardStage(Init.deviceRegistered);

    // trigger notification
    state = LaunchStage(
      stage: LaunchStageEnum.acquiringRegularToken,
      msg: 'Connecting...',
    );
    log('Registration completed.', name: _component);
  }

  Future<void> accessAnonymous() async {
    // Obtain token for anonymous access, open websocket.
    log('Obtaining access.', name: _component);
    // trigger notification
    state = LaunchStage(
      stage: LaunchStageEnum.acquiringRegularToken,
      msg: 'Preparing...',
    );

    try {
      // exceptions can come when the network is not available
      await ref.read(rpsProvider).obtainToken(topic: defaultTopic);
    } catch (e) {
      log('Default token exception: $e.', name: _component);
      // trigger notification
      state = LaunchStage(
        stage: LaunchStageEnum.acquiringRegularToken,
        msg: 'Preparing...',
        err: 'Connectivity failed.',
      );
    }

    try {
      // exceptions can come when the network is not available
      ref.read(wsProvider).init(token: ref.read(rpsProvider).tokenStr);
    } catch (e) {
      log('Websocket: exception: $e.', name: _component);
      // trigger notification
      state = LaunchStage(
        stage: LaunchStageEnum.acquiringRegularToken,
        msg: 'Preparing...',
        err: 'Discovery failed.',
      );
    }

    // trigger notification
    state = LaunchStage(stage: LaunchStageEnum.success, msg: 'All set!');
    log('Access obtained.', name: _component);
  }

  Future<void> launch() async {
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

    Init init = ref.read(initProvider);
    switch (init.wizardStage) {
      case Init.vaultInitialized:
        // execute registration workflow
        await registerAnonymous();
        await accessAnonymous();
        // development only - populate the vault with mock data
        if (UI.testEnvironment) {
          await mockPeers(ref.read(peersProvider.notifier));
        }
        break;
      case Init.deviceRegistered:
      case Init.completed:
        // execute access workflow
        await accessAnonymous();
        break;
      default:
        throw Exception('Incorrect init stage ${init.wizardStage}.');
    }

    // start periodic jobs
    await ref.read(dispatcherProvider).start();
  }
}
