import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_app/core/const.dart';
import 'package:zxbase_app/core/rv.dart';
import 'package:zxbase_app/ui/common/dialogs.dart';
import 'package:zxbase_app/providers/connections_provider.dart';
import 'package:zxbase_app/providers/dispatcher_provider.dart';
import 'package:zxbase_app/providers/green_vault/device_provider.dart';
import 'package:zxbase_app/providers/green_vault/peers_provider.dart';
import 'package:zxbase_app/providers/green_vault/peer_group_provider.dart';
import 'package:zxbase_app/providers/rps_provider.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';
import 'package:zxbase_model/zxbase_model.dart';

const _component = 'addDeviceDialog'; // logging component
const _delayMessage =
    'Zxbase is verifying devices\' identities and consent to connect - both devices have to ask for it. It can take several minutes before devices can connect.';

class AddDeviceWidget extends ConsumerStatefulWidget {
  const AddDeviceWidget({super.key});

  @override
  ConsumerState createState() => _AddDeviceWidgetState();
}

class _AddDeviceWidgetState extends ConsumerState<AddDeviceWidget> {
  final _formKey = GlobalKey<FormState>();
  String _nickname = '';
  late Identity _identity;
  final TextEditingController _identityController = TextEditingController();

  Future<bool> createAndPair() async {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    // create a peer
    PeersNotifier peersNotifier = ref.read(peersProvider.notifier);
    Peer newPeer = Peer.create(
      identityStr: _identity.toBase64Url(),
      nickname: _nickname,
    );

    RV rv = await peersNotifier.addPeer(newPeer);
    if (rv != RV.ok) {
      log('Failed to create a peer: ${newPeer.id}.', name: _component);
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(rvMsg[rv]!)));
      return false;
    }

    await ref.read(connectionsProvider).initConnection(peerId: newPeer.id);
    await ref.read(rpsProvider).pair(peerIdentity: _identity.toBase64Url());
    await peersNotifier.setStatus(
      peerId: newPeer.id,
      status: peerStatusPairing,
    );
    await ref.read(dispatcherProvider).pairPeer(peer: newPeer);
    // automatically add the peer to the vault group
    ref
        .read(peerGroupsProvider.notifier)
        .createVaultGroupPeer(peerId: newPeer.id);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    var ownIdentity = ref.read(deviceProvider).identity.toBase64Url();

    return Form(
      key: _formKey,
      child: Center(
        child: Column(
          children: [
            TextFormField(
              controller: _identityController,
              inputFormatters: [
                LengthLimitingTextInputFormatter(Const.identityMaxLength),
              ],
              decoration: InputDecoration(
                labelText: 'Identity',
                hintText: 'Paste device\'s Identity.',
                helperText: ' ', // prevent height change
              ),
              onSaved: (String? value) {
                // This optional block of code can be used to run
                // code when the user saves the form.
              },
              validator: (value) {
                if (value!.trim().isEmpty) {
                  return Const.idntEmptyWarn;
                } else {
                  try {
                    _identity = Identity.fromBase64Url(value);
                  } catch (e) {
                    return rvMsg[RV.invalidIdentity];
                  }
                  if (value == ownIdentity) {
                    return rvMsg[RV.ownIdentity];
                  }
                  return null;
                }
              },
            ),
            TextFormField(
              inputFormatters: [
                LengthLimitingTextInputFormatter(Const.nicknameMaxLength),
              ],
              decoration: const InputDecoration(
                labelText: 'Nickname',
                hintText: 'E.g. My Phone.',
                helperText: ' ', // prevent height change
              ),
              onSaved: (String? value) {
                // This optional block of code can be used to run
                // code when the user saves the form.
              },
              validator: (value) {
                if (value!.trim().isEmpty) {
                  return Const.nicknameEmptyWarn;
                } else if (value.length > Const.nicknameMaxLength) {
                  return Const.nicknameLongWarn;
                } else {
                  _nickname = value;
                  return null;
                }
              },
            ),
            SizedBox(
              height: 40,
              child: TextButton(
                onPressed: () async {
                  if (await createAndPair()) {
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      showInfoDialog(context, _delayMessage, buttonText: 'OK');
                    }
                  }
                },
                child: Text('OK', style: TextStyle(fontSize: UI.fontSizeLarge)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showAddDeviceDialog({
  required BuildContext context,
  required String title,
}) {
  showContentDialog(
    context,
    title,
    const AddDeviceWidget(),
    showActionButton: false,
  );
}
