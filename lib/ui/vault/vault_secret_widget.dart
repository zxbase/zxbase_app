import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:uuid/uuid.dart';
import 'package:zxbase_app/core/const.dart';
import 'package:zxbase_app/core/rv.dart';
import 'package:zxbase_app/ui/common/app_bar.dart';
import 'package:zxbase_app/ui/common/dialogs.dart';
import 'package:zxbase_app/ui/vault/password_generation_widget.dart';
import 'package:zxbase_app/ui/common/scroll_column_widget.dart';
import 'package:zxbase_app/providers/green_vault/user_vault_provider.dart';
import 'package:zxbase_app/providers/ui_providers.dart';
import 'package:zxbase_app/providers/vault_sync_provider.dart';
import 'package:zxbase_app/ui/common/zx_input.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';
import 'package:zxcvbn/zxcvbn.dart';

class VaultSecretWidget extends ConsumerStatefulWidget {
  const VaultSecretWidget({super.key});

  @override
  VaultSecretWidgetState createState() => VaultSecretWidgetState();
}

class VaultSecretWidgetState extends ConsumerState<VaultSecretWidget> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  UserVaultEntry? entry;

  bool editMode = false;
  bool isNewEntry = false;
  bool obscure = true;
  bool showPasswordGenerator = false;

  TextEditingController _titleController = TextEditingController();
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _notesController = TextEditingController();
  final List<TextEditingController> _urlControllers = [];

  String newEntryTitle = 'New Secret';

  final _zxcvbn = Zxcvbn();
  double _passwordScore = 0.0;

  /// Clears each controller's undo/redo history.
  void renewControllers() {
    _passwordScore = 0.0;
    _titleController = TextEditingController();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _notesController = TextEditingController();
  }

  void clearFields() {
    renewControllers();
    _urlControllers.clear();
  }

  void setFields(UserVaultEntry entry) {
    renewControllers();
    _titleController.text = entry.title;
    _usernameController.text = entry.username;
    _passwordController.text = entry.password;
    _notesController.text = entry.notes;

    _urlControllers.clear();
    for (var url in entry.uris) {
      _urlControllers.add(TextEditingController()..text = url);
    }
  }

  void _clearSelectedEntry(WidgetRef ref) {
    ref.read(selectedVaultEntryProvider.notifier).set('');
  }

  Future<void> _deleteVaultEntry({
    required WidgetRef ref,
    required String entryId,
  }) async {
    if (UI.isMobile) {
      _clearSelectedEntry(ref);
    }

    await ref.read(userVaultProvider.notifier).deleteEntry(id: entryId);

    await ref.read(vaultSyncProvider).broadcastVault();
    ref.read(vaultSyncProvider).updateSyncWarning();

    if (UI.isDesktop) {
      _clearSelectedEntry(ref);
    }
  }

  Future<void> _deleteEntry() async {
    if (UI.isMobile) {
      Navigator.of(context)
        ..pop()
        ..pop();
    } else {
      Navigator.pop(context);
    }

    await _deleteVaultEntry(ref: ref, entryId: entry!.id);
  }

  void _showDeleteDialog() {
    showCustomDialog(
      context,
      Container(),
      title: 'Delete secret?',
      leftButtonText: 'Yes',
      rightButtonText: 'No',
      onLeftTap: _deleteEntry,
    );
  }

  List<Widget> buildBody() {
    if (_passwordController.text.isNotEmpty) {
      _passwordScore = _zxcvbn.evaluate(_passwordController.text).score!;
    }

    Color secondaryColor = Theme.of(context).textTheme.bodySmall!.color!;

    return [
      Text(
        HumanTime.dateTime(entry!.updatedAt.toLocal()),
        style: TextStyle(fontSize: UI.fontSizeXSmall, color: secondaryColor),
      ),
      ZXTextFormField(
        controller: _titleController,
        inputFormatters: [
          LengthLimitingTextInputFormatter(Const.vaultTitleMaxLength),
        ],
        textAlign: TextAlign.start,
        maxLines: 1,
        readOnly: !editMode,
        decoration: const InputDecoration(
          labelText: 'Title',
          hintText: 'Title',
        ),
        validator: (value) {
          if (value!.trim().isEmpty) {
            return Const.titleEmptyWarn;
          } else if (value.length > Const.vaultTitleMaxLength) {
            return Const.titleLongWarn;
          } else {
            entry!.title = value;
            return null;
          }
        },
        onChanged: (text) {
          ref.read(isVaultEntryDirtyProvider.notifier).set(true);
        },
      ),
      editMode
          ? TypeAheadField(
              controller: _usernameController,
              builder: (context, controller, focusNode) {
                return ZXTextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(
                      Const.vaultUsernameMaxLength,
                    ),
                  ],
                  textAlign: TextAlign.start,
                  maxLines: 1,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    hintText: 'Username',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.copy_rounded),
                      tooltip: 'Copy',
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: _usernameController.text),
                        );
                        UI.showSnackbar(context, Const.copyClip);
                      },
                    ),
                  ),
                  onChanged: (text) {
                    ref.read(isVaultEntryDirtyProvider.notifier).set(true);
                  },
                  validator: (value) {
                    if (value!.length > Const.vaultUsernameMaxLength) {
                      return Const.usernameLongWarn;
                    } else {
                      entry!.username = value;
                      return null;
                    }
                  },
                );
              },
              hideOnEmpty: true,
              suggestionsCallback: (String pattern) {
                String lcPattern = pattern.toLowerCase();
                return ref
                    .read(userVaultProvider)
                    .usernames
                    .where((u) => u.toLowerCase().contains(lcPattern))
                    .toList();
              },
              itemBuilder: (context, String suggestion) {
                return ListTile(title: Text(suggestion));
              },
              onSelected: (String suggestion) {
                _usernameController.text = suggestion;
              },
              // no animation
              transitionBuilder: (context, animation, child) {
                return child;
              },
            )
          :
            // read only username
            ZXTextFormField(
              controller: _usernameController,
              inputFormatters: [
                LengthLimitingTextInputFormatter(Const.vaultUsernameMaxLength),
              ],
              textAlign: TextAlign.start,
              maxLines: 1,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Username',
                hintText: 'Username',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.copy_rounded),
                  tooltip: 'Copy',
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: _usernameController.text),
                    );
                    UI.showSnackbar(context, Const.copyClip);
                  },
                ),
              ),
            ),
      ZXTextFormField(
        controller: _passwordController,
        inputFormatters: [
          LengthLimitingTextInputFormatter(Const.vaultPasswordMaxLength),
        ],
        textAlign: TextAlign.start,
        maxLines: 1,
        readOnly: !editMode,
        obscureText: obscure,
        keyboardType: TextInputType.visiblePassword,
        decoration: InputDecoration(
          labelText: 'Password',
          hintText: 'Password',
          suffixIcon: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                icon: obscure
                    ? const Icon(Icons.visibility_rounded)
                    : const Icon(Icons.visibility_off_rounded),
                tooltip: obscure ? 'Show' : 'Hide',
                onPressed: () {
                  setState(() {
                    obscure = !obscure;
                  });
                },
              ),
              Visibility(
                visible: editMode,
                child: IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  tooltip: 'Generate',
                  onPressed: () {
                    setState(() {
                      showPasswordGenerator = !showPasswordGenerator;
                    });
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded),
                tooltip: 'Copy',
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: _passwordController.text),
                  );
                  UI.showSnackbar(context, Const.copyClip);
                },
              ),
            ],
          ),
        ),
        validator: (value) {
          if (value!.length > Const.vaultPasswordMaxLength) {
            return Const.passwordLongWarn;
          } else {
            entry!.password = value;
            return null;
          }
        },
        onChanged: (text) {
          ref.read(isVaultEntryDirtyProvider.notifier).set(true);
          setState(() {});
        },
      ),
      Visibility(
        visible: editMode,
        child: Padding(
          padding: const EdgeInsets.only(top: 15, bottom: 10),
          child: PasswordMeter.full(
            score: _passwordScore,
            isEmpty: _passwordController.text.isEmpty,
            context: context,
          ),
        ),
      ),
      Visibility(
        visible: showPasswordGenerator && editMode,
        child: Material(
          elevation: 1.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: PasswordGenerationWidget(
              onSetPassword: (password) {
                _passwordController.text = password;
                setState(() {});
              },
            ),
          ),
        ),
      ),
      _urlTextFields(),
      Focus(
        // helps to get focus for keyboard shortcut
        autofocus: true,
        child: ZXTextFormField(
          controller: _notesController,
          inputFormatters: [
            LengthLimitingTextInputFormatter(Const.vaultNotesMaxLength),
          ],
          textAlign: TextAlign.start,
          maxLines: null,
          readOnly: !editMode,
          decoration: const InputDecoration(
            labelText: 'Notes',
            hintText: 'Notes',
          ),
          validator: (value) {
            if (value!.length > Const.vaultNotesMaxLength) {
              return Const.notesLongWarn;
            } else {
              entry!.notes = value;
              return null;
            }
          },
          onChanged: (text) {
            ref.read(isVaultEntryDirtyProvider.notifier).set(true);
          },
        ),
      ),
    ];
  }

  Widget _urlTextFields() {
    List<Widget> widgets = [];
    for (int i = 0; i < _urlControllers.length; i++) {
      TextEditingController controller = _urlControllers[i];

      widgets.add(
        ZXTextFormField(
          controller: controller,
          inputFormatters: [
            LengthLimitingTextInputFormatter(Const.vaultUsernameMaxLength),
          ],
          textAlign: TextAlign.start,
          maxLines: 1,
          readOnly: !editMode,
          decoration: InputDecoration(
            labelText: 'URL',
            hintText: 'URL',
            suffixIcon: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Visibility(
                  visible: editMode,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Delete',
                    color: Theme.of(context).colorScheme.error,
                    onPressed: () {
                      _showDeleteUrlDialog(i);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded),
                  tooltip: 'Copy',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: controller.text));
                    UI.showSnackbar(context, Const.copyClip);
                  },
                ),
              ],
            ),
          ),
          validator: (value) {
            if (value!.length > Const.vaultUrlMaxLength) {
              return Const.urlLongWarn;
            } else {
              while (entry!.uris.length < i + 1) {
                entry!.uris.add('');
              }
              entry!.uris[i] = value;
              return null;
            }
          },
          onChanged: (text) {
            ref.read(isVaultEntryDirtyProvider.notifier).set(true);
          },
        ),
      );
    }
    if (editMode && _urlControllers.length < Const.vaultURIsMaxCount) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                ref.read(isVaultEntryDirtyProvider.notifier).set(true);
                setState(() {
                  _urlControllers.add(TextEditingController());
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  'Add URL',
                  style: TextStyle(fontSize: UI.fontSizeMedium),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Column(children: widgets);
  }

  void _showDeleteUrlDialog(int index) {
    showCustomDialog(
      context,
      Container(),
      title: 'Delete URL?',
      leftButtonText: 'Yes',
      rightButtonText: 'No',
      onLeftTap: () {
        ref.read(isVaultEntryDirtyProvider.notifier).set(true);
        _deleteUrl(index);
        Navigator.pop(context);
      },
    );
  }

  void _deleteUrl(int index) {
    setState(() {
      if (!isNewEntry) entry!.uris.removeAt(index);
      _urlControllers.removeAt(index);
    });
  }

  Future<void> _cancelConfirmed() async {
    if (UI.isDesktop) {
      if (isNewEntry) {
        ref.read(newVaultEntryProvider.notifier).set(false);
        ref.read(selectedVaultEntryProvider.notifier).set('');
      } else {
        setState(() {
          editMode = false;
          showPasswordGenerator = false;
        });
      }
    } else {
      setState(() {
        editMode = false;
        showPasswordGenerator = false;
      });
      if (isNewEntry) {
        Navigator.pop(context);
        ref.read(newVaultEntryProvider.notifier).set(false);
      }
    }
  }

  void _showCancelWarningDialog() {
    showCustomDialog(
      context,
      Container(),
      title: Const.discardWarn,
      leftButtonText: 'Yes',
      onLeftTap: () {
        if (!isNewEntry) {
          // load original values
          entry = ref.read(userVaultProvider.notifier).copyEntry(id: entry!.id);
          setFields(entry!);
        }
        ref.read(isVaultEntryDirtyProvider.notifier).set(false);
        Navigator.pop(context);
        _cancelConfirmed();
      },
      rightButtonText: 'No',
    );
  }

  Future<void> cancel() async {
    if (!editMode) {
      return;
    }

    if (ref.read(isVaultEntryDirtyProvider)) {
      _showCancelWarningDialog();
    } else {
      await _cancelConfirmed();
    }
  }

  Future<void> save() async {
    if (!editMode) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    RV err;
    if (isNewEntry) {
      err = await ref.read(userVaultProvider.notifier).createEntry(entry!);
    } else {
      err = await ref.read(userVaultProvider.notifier).updateEntry(entry!);
    }
    if (err != RV.ok) {
      if (!mounted) return;
      UI.showSnackbar(context, rvMsg[err]!);
      return;
    }

    await ref.read(vaultSyncProvider).broadcastVault();
    ref.read(vaultSyncProvider).updateSyncWarning();

    ref.read(isVaultEntryDirtyProvider.notifier).set(false);
    if (isNewEntry) {
      ref.read(newVaultEntryProvider.notifier).set(false);
    }
    setState(() {
      // set state to quit edit mode
      editMode = false;
      showPasswordGenerator = false;
    });
    ref.read(selectedVaultEntryProvider.notifier).set(entry!.id);
  }

  Future<void> edit() async {
    if (editMode) {
      return;
    }

    setState(() {
      editMode = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch only entry Id, no new flag, to avoid scope problems and unnecessary rebuild.
    String entryId = ref.watch(selectedVaultEntryProvider);
    isNewEntry = ref.read(newVaultEntryProvider);

    if (isNewEntry) {
      if (!ref.read(isVaultEntryDirtyProvider)) {
        editMode = true;
        obscure = true;

        String newEntryId;
        do {
          newEntryId = const Uuid().v4();
        } while (ref.read(userVaultProvider).entries.containsKey(newEntryId));
        entry = UserVaultEntry(id: newEntryId, type: typeLogin);

        clearFields();
      }
    } else {
      if (entryId == '') {
        return Container();
      }
      UserVaultEntry? vaultEntry = ref
          .read(userVaultProvider.notifier)
          .copyEntry(id: entryId);
      if (vaultEntry == null) {
        // The entry was deleted under our feet - by sync.
        if (UI.isMobile) {
          Navigator.pop(context);
        }
        // Don't update selected entry - it will cause scope issues.
        return Container();
      }
      if (entry == null || entry!.id != entryId) {
        // Load different entry.
        editMode = false;
        obscure = true;
        setFields(vaultEntry);
        ref.read(isVaultEntryDirtyProvider.notifier).set(false);
      } else if (!editMode) {
        // Same entry was changed by sync.
        setFields(vaultEntry);
        ref.read(isVaultEntryDirtyProvider.notifier).set(false);
      }
      entry = vaultEntry;
    }

    return CallbackShortcuts(
      bindings: {
        LogicalKeySet(LogicalKeyboardKey.escape): cancel,
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyS): save,
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyE): edit,
      },
      child: Focus(
        autofocus: true,
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              automaticallyImplyLeading: !editMode,
              titleSpacing: 8.0,
              bottom: preferredSizeDivider(height: 0.5),
              leading: editMode
                  ? IconButton(
                      icon: Icon(Icons.cancel_rounded),
                      tooltip: 'Cancel',
                      onPressed: cancel,
                    )
                  : null,
              leadingWidth: UI.appBarLeadWidth,
              title: Text(isNewEntry ? newEntryTitle : entry!.title),
              centerTitle: true,
              actions: [
                editMode
                    ? IconButton(
                        icon: Icon(Icons.save_rounded),
                        tooltip: 'Save',
                        onPressed: save,
                      )
                    : IconButton(
                        icon: Icon(Icons.edit_rounded),
                        tooltip: 'Edit',
                        onPressed: edit,
                      ),
              ],
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 16.0,
                ),
                child: ScrollColumnExpandableWidget(
                  // distinct key resets the scroll view position
                  key: (isNewEntry) ? const Key('_newEntry') : Key(entry!.id),
                  child: Column(
                    children: [
                      Form(
                        key: _formKey,
                        child: Column(children: buildBody()),
                      ),
                      const Spacer(),
                      Visibility(
                        visible: editMode && !isNewEntry,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _showDeleteDialog,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                ),
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
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
