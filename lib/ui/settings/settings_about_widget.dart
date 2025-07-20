import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:zxbase_app/core/channel/connection.dart';
import 'package:zxbase_app/core/const.dart';
import 'package:zxbase_app/ui/app_bar.dart';
import 'package:zxbase_app/ui/assets.dart';
import 'package:zxbase_app/ui/dialogs.dart';
import 'package:zxbase_app/core/version.dart';
import 'package:zxbase_app/providers/config_provider.dart';
import 'package:zxbase_app/providers/connections_provider.dart';
import 'package:zxbase_app/providers/green_vault/device_provider.dart';
import 'package:zxbase_app/providers/green_vault/peers_provider.dart';
import 'package:zxbase_app/providers/rps_provider.dart';
import 'package:zxbase_app/providers/ui_providers.dart';
import 'package:zxbase_app/providers/ws_provider.dart';
import 'package:zxbase_api_client/zxbase_api_client.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';

String _appStoreUrl = appStoreUrls[Platform.operatingSystem]!;

class SettingsAboutWidget extends ConsumerStatefulWidget {
  const SettingsAboutWidget({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      SettingsAboutWidgetState();
}

class SettingsAboutWidgetState extends ConsumerState<SettingsAboutWidget> {
  int _versionTapCounter = 0;
  int _logoTapCounter = 0;
  late Version _version;

  @override
  Widget build(BuildContext context) {
    MOTD? motd = ref.watch(motdProvider);
    String message = motd?.message ?? '';
    _version = ref.read(configProvider).version;

    return LayoutBuilder(
      builder: (builder, constraints) {
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text('About'),
            bottom: preferredSizeDivider(height: 0.5),
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  fit: FlexFit.tight,
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth:
                                  constraints.maxWidth *
                                  (UI.isDesktop ? 0.25 : 0.4),
                            ),
                            child: _buildLogo(),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: _buildAppVersion(),
                          ),
                          ref.read(versionWarningProvider).isEmpty
                              ? Container()
                              : Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: Const.newVersionMsg,
                                          style: TextStyle(
                                            fontSize: UI.fontSizeMedium,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () async {
                                              if (await canLaunchUrlString(
                                                _appStoreUrl,
                                              )) {
                                                await launchUrlString(
                                                  _appStoreUrl,
                                                );
                                              }
                                            },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          Visibility(
                            visible: message.isNotEmpty,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Linkify(
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: UI.fontSizeMedium),
                                onOpen: (link) async {
                                  if (await canLaunchUrlString(link.url)) {
                                    await launchUrlString(link.url);
                                  }
                                },
                                text: message,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Terms of Service:',
                              style: TextStyle(fontSize: UI.fontSizeMedium),
                            ),
                          ),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: termsOfServicesUrl,
                                  style: UI.urlStyle,
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () async {
                                      if (await canLaunchUrlString(
                                        termsOfServicesUrl,
                                      )) {
                                        await launchUrlString(
                                          termsOfServicesUrl,
                                        );
                                      }
                                    },
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Privacy Policy:',
                              style: TextStyle(fontSize: UI.fontSizeMedium),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: privacyPolicyUrl,
                                    style: UI.urlStyle,
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () async {
                                        if (await canLaunchUrlString(
                                          privacyPolicyUrl,
                                        )) {
                                          await launchUrlString(
                                            privacyPolicyUrl,
                                          );
                                        }
                                      },
                                  ),
                                ],
                              ),
                            ),
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
      },
    );
  }

  Widget _buildLogo() {
    return GestureDetector(
      child: const Image(image: AssetImage(Assets.logo)),
      onTap: () {
        _logoTapCounter++;
        if (_logoTapCounter >= 5) {
          _logoTapCounter = 0;
          _showStats(context: context);
        }
      },
    );
  }

  Widget _buildAppVersion() {
    return GestureDetector(
      child: Column(
        children: [
          Text(
            'You are running version:',
            style: TextStyle(fontSize: UI.fontSizeMedium),
          ),
          Text(_version.text, style: TextStyle(fontSize: UI.fontSizeMedium)),
        ],
      ),
      onTap: () {
        _versionTapCounter++;
        if (_versionTapCounter >= 5) {
          _versionTapCounter = 0;
          _resync();
        }
      },
    );
  }

  void _resync() {
    WebSocket ws = ref.read(wsProvider);
    ws.close();
    UI.showSnackbar(context, 'Resynced!');
  }

  void _showStats({required BuildContext context}) {
    String dump = 'Device ID: ${ref.read(deviceProvider).id}\n';
    dump +=
        'OS: ${Platform.operatingSystem}-${Platform.operatingSystemVersion}\n';
    dump += 'RPS: ${_version.text} ${ref.read(configProvider).rpsHost}\n';
    dump += 'Time zone: ${HumanTime.tz(DateTime.now())}\n\n';

    // token
    RpsClient rps = ref.read(rpsProvider);
    String tokenRcv = (rps.token == null)
        ? ''
        : HumanTime.preciseTime(rps.tokenDateTime.toLocal());
    String tokenExp = (rps.token == null)
        ? ''
        : HumanTime.preciseTime(rps.token!.exp.toLocal());
    dump += 'Token received:\t$tokenRcv\nToken expires:\t$tokenExp\n';

    // websocket
    WebSocket ws = ref.read(wsProvider);
    dump +=
        '\nWS connected:\t${ws.socket.connected}\nWS ID:\t${ws.socket.id}\n';
    if (ws.lastError != '') {
      dump += 'Last error:\t${ws.lastError}:${ws.lastErrorTime}\n';
    }

    String hbTime = HumanTime.preciseTime(ws.hbReceived.toLocal());
    dump += 'HB received: $hbTime\nHB latency: ${ws.hbLatency}\n';
    String msgTime = HumanTime.preciseTime(ws.msgReceived.toLocal());

    dump += 'Last message received: $msgTime\n';

    // peers
    List items = ref.read(peersProvider).peersList;
    dump += '\nPeers';
    for (Peer peer in items) {
      dump += '\n${peer.nickname}: ${peer.id}\n';
      dump += 'Status: ${peer.status}\n';
      dump += 'Last seen: ${HumanTime.preciseTime(peer.lastSeen.toLocal())}\n';
      Connection connection = ref
          .read(connectionsProvider)
          .getConnection(peer.id)!;
      dump += 'Connection state: ${connection.state}\n';
      dump +=
          'State updated: ${HumanTime.preciseTime(connection.stateUpdated.toLocal())}\n';
      dump += 'ICE state: ${connection.connection.iceConnectionState}\n';
      dump +=
          'ICE state updated: ${HumanTime.preciseTime(connection.iceStateUpdated.toLocal())}\n';
      dump +=
          'HB received: ${HumanTime.preciseTime(connection.hbReceived.toLocal())}\n';
    }

    showCustomDialog(
      context,
      SelectableText(dump),
      title: 'Stats',
      rightButtonText: 'Copy',
      onRightTap: () {
        Navigator.pop(context);
        Clipboard.setData(ClipboardData(text: dump));
        UI.showSnackbar(context, 'Copied!');
      },
    );
  }
}
