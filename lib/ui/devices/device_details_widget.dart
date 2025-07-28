import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_app/core/const.dart';
import 'package:zxbase_app/providers/green_vault/peers_provider.dart';
import 'package:zxbase_app/ui/common/app_bar.dart';
import 'package:zxbase_app/ui/common/avatar.dart';
import 'package:zxbase_app/ui/common/dialogs.dart';
import 'package:zxbase_app/ui/devices/delete_device_dialog.dart';
import 'package:zxbase_app/ui/common/device_id_widget.dart';
import 'package:zxbase_app/ui/common/scroll_column_widget.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';

class DeviceDetailsWidget extends ConsumerStatefulWidget {
  const DeviceDetailsWidget({super.key, required this.peerId});

  final String peerId;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      DeviceDetailsWidgetState();
}

class DeviceDetailsWidgetState extends ConsumerState<DeviceDetailsWidget> {
  final _formKey = GlobalKey<FormState>();
  late Peer? peer;
  bool editMode = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late String _nickname;

  @override
  Widget build(BuildContext context) {
    peer = ref.watch(peersProvider).peers[widget.peerId];
    if (peer == null) {
      return Container();
    }
    _nickname = peer!.nickname;

    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          automaticallyImplyLeading: !editMode,
          titleSpacing: 8.0,
          bottom: preferredSizeDivider(height: 0.5),
          leading: editMode
              ? appBarTextButton(context, 'Cancel', _quitEditMode)
              : UI.isMobile
              ? appBarTextButton(context, 'Back', _back)
              : Container(),
          leadingWidth: UI.appBarLeadWidth,
          title: Text(_nickname),
          centerTitle: true,
          actions: [
            !editMode
                ? appBarTextButton(
                    context,
                    'Edit',
                    () async => setState(() => editMode = true),
                  )
                : appBarTextButton(context, 'Save', _updatePeer),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 16.0,
            ),
            child: Center(
              child: ScrollColumnExpandableWidget(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Avatar.peer(
                        name: _nickname,
                        status: avatarStatus(peer!.status),
                        size: 100,
                        fontSize: 26,
                        statusSize: 26,
                      ),
                    ),
                    Form(
                      key: _formKey,
                      child: TextFormField(
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(
                            Const.nicknameMaxLength,
                          ),
                        ],
                        textAlign: TextAlign.center,
                        initialValue: _nickname,
                        maxLines: 1,
                        enabled: editMode,
                        decoration: const InputDecoration(
                          label: Center(child: Text('Nickname')),
                          hintText: 'Nickname',
                        ),
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
                    ),
                    const Spacer(),
                    deviceIdWidget(context, widget.peerId),
                    Visibility(
                      visible: !editMode,
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: peer!.identityStr),
                            );
                            UI.showSnackbar(context, 'Copied!');
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(Const.copyIdnt),
                          ),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: editMode,
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _showDeleteDialog,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              'Delete',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    showCustomDialog(
      context,
      Container(),
      title: 'Delete device?',
      leftButtonText: 'Yes',
      rightButtonText: 'No',
      onLeftTap: _deletePeer,
    );
  }

  Future<void> _updatePeer() async {
    if (!_formKey.currentState!.validate() || peer == null) {
      return;
    }

    var newPeer = Peer.copy(peer!);
    newPeer.nickname = _nickname;
    await ref.read(peersProvider.notifier).updatePeer(peer: newPeer);

    await _quitEditMode();
  }

  Future<void> _deletePeer() async {
    if (UI.isMobile) {
      Navigator.of(context)
        ..pop()
        ..pop();
    } else {
      Navigator.pop(context);
    }

    await deletePeer(ref: ref, peerId: widget.peerId);
  }

  Future<void> _quitEditMode() async {
    setState(() {
      editMode = false;
    });
  }

  Future<void> _back() async {
    if (UI.isMobile) {
      Navigator.pop(context);
    }
  }
}
