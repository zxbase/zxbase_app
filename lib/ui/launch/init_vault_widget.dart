import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_app/core/const.dart';
import 'package:zxbase_app/providers/blue_vault/init_provider.dart';
import 'package:zxbase_app/providers/green_vault/device_provider.dart';
import 'package:zxbase_app/providers/green_vault/green_vault_provider.dart';
import 'package:zxbase_app/providers/green_vault/peers_provider.dart';
import 'package:zxbase_app/providers/green_vault/peer_group_provider.dart';
import 'package:zxbase_app/providers/green_vault/settings_provider.dart';
import 'package:zxbase_app/providers/green_vault/user_vault_provider.dart';
import 'package:zxbase_app/providers/launch_provider.dart';
import 'package:zxbase_app/ui/common/zero_trust_input.dart';
import 'package:zxbase_app/ui/launch/launch_widget.dart';
import 'package:zxbase_crypto/zxbase_crypto.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';
import 'package:zxcvbn/zxcvbn.dart';

const _header = 'Create your vault';
const _warning =
    'If you forget this password, you will not be able to access your data on this device.';
const int ppLength = 0;
const int ppUpLow = 1;
const int ppNumSpec = 2;

class InitVaultWidget extends ConsumerStatefulWidget {
  const InitVaultWidget({super.key});

  @override
  InitVaultWidgetState createState() => InitVaultWidgetState();
}

class InitVaultWidgetState extends ConsumerState<InitVaultWidget> {
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  String _password = '';
  String _passwordConfirmation = '';
  final List<bool> _passwordStructure = [false, false, false];
  bool _capsLockOn = false;

  final _zxcvbn = Zxcvbn();
  double _passwordScore = 0.0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  static const String _validationMessageMatch = 'Passwords do not match.';
  static const String _validationMessageShort = 'The password is too short.';
  static const String _validationMessageLong = 'The password is too long.';
  static const String _validationMessageReq =
      'Password does not match the requirements.';

  Future<bool> _initVault() async {
    // initialize green vault
    if (!await ref.read(greenVaultProvider.notifier).init(_password)) {
      return false;
    }

    await ref.read(settingsProvider.notifier).init();
    await ref.read(deviceProvider.notifier).init();
    await ref.read(userVaultProvider.notifier).init();
    await ref.read(peersProvider.notifier).init();
    await ref.read(peerGroupsProvider.notifier).init();

    await ref.read(initProvider.notifier).setWizardStage(Init.vaultInitialized);
    return true;
  }

  Color passIColor(bool val) => val ? Colors.green.shade600 : Colors.grey;

  TextStyle passIStyle(bool val) =>
      TextStyle(color: passIColor(val), fontSize: UI.fontSizeMedium);

  @override
  Widget build(BuildContext context) {
    if (_password.isNotEmpty) {
      _passwordScore = _zxcvbn.evaluate(_password).score!;
    }

    return LayoutBuilder(
      builder: (builder, constraints) {
        double inputWidth = constraints.maxWidth * (UI.isDesktop ? 0.5 : 0.8);
        return Scaffold(
          body: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (KeyEvent event) {
              bool newCapsLockOn = HardwareKeyboard.instance.lockModesEnabled
                  .contains(KeyboardLockMode.capsLock);
              if (newCapsLockOn != _capsLockOn) {
                setState(() {
                  _capsLockOn = newCapsLockOn;
                });
              }
            },
            child: SafeArea(
              child: Stack(
                children: [
                  Form(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    key: _formKey,
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            SizedBox(
                              width: inputWidth,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 5,
                                  right: 5,
                                  bottom: 10,
                                ),
                                child: Text(
                                  _header,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: UI.fontSizeLarge,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: inputWidth,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 5,
                                  top: 10,
                                  right: 5,
                                  bottom: 0,
                                ),
                                child: ZTTextFormField(
                                  key: const Key('passwordInput'),
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(
                                      Const.passwordMaxLength,
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _password = value;
                                      _passwordStructure[ppLength] =
                                          (value.length >=
                                          Const.passwordMinLength);
                                      _passwordStructure[ppUpLow] = Password
                                          .upperLowerCaseRE
                                          .hasMatch(value);
                                      _passwordStructure[ppNumSpec] = Password
                                          .numberSpecialRE
                                          .hasMatch(value);
                                    });
                                  },
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return Const.passEmptyWant;
                                    } else if (value != _passwordConfirmation) {
                                      return _validationMessageMatch;
                                    } else if (value.length <
                                        Const.passwordMinLength) {
                                      return _validationMessageShort;
                                    } else if (value.length >
                                        Const.passwordMaxLength) {
                                      return _validationMessageLong;
                                    } else if (!Password.okRE.hasMatch(value)) {
                                      return _validationMessageReq;
                                    } else {
                                      _password = value;
                                      return null;
                                    }
                                  },
                                  obscureText: _obscure,
                                  keyboardType: TextInputType.visiblePassword,
                                  decoration: InputDecoration(
                                    helperText: ' ',
                                    // prevent height change
                                    hintText: 'Password',
                                    prefixIcon: _capsLockOn
                                        ? const Icon(
                                            Icons.keyboard_capslock_rounded,
                                          )
                                        : null,
                                    suffixIcon: IconButton(
                                      key: const Key('passwordVisible'),
                                      icon: _obscure == true
                                          ? const Icon(Icons.visibility_rounded)
                                          : const Icon(
                                              Icons.visibility_off_rounded,
                                            ),
                                      onPressed: () {
                                        setState(() {
                                          _obscure = !_obscure;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: inputWidth,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 5,
                                  top: 0,
                                  right: 5,
                                  bottom: 5,
                                ),
                                child: ZTTextFormField(
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(
                                      Const.passwordMaxLength,
                                    ),
                                  ],
                                  key: const Key('passwordConfirmationInput'),
                                  onChanged: (value) {
                                    setState(() {
                                      _passwordConfirmation = value;
                                    });
                                  },
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return Const.passEmptyWant;
                                    } else if (value != _password) {
                                      return _validationMessageMatch;
                                    } else if (value.length <
                                        Const.passwordMinLength) {
                                      return _validationMessageShort;
                                    } else if (value.length >
                                        Const.passwordMaxLength) {
                                      return _validationMessageLong;
                                    } else if (!Password.okRE.hasMatch(value)) {
                                      return _validationMessageReq;
                                    } else {
                                      _passwordConfirmation = value;
                                      return null;
                                    }
                                  },
                                  obscureText: _obscure,
                                  keyboardType: TextInputType.visiblePassword,
                                  decoration: InputDecoration(
                                    helperText: ' ',
                                    // prevent height change
                                    hintText: 'Confirm password',
                                    prefixIcon: _capsLockOn
                                        ? const Icon(
                                            Icons.keyboard_capslock_rounded,
                                          )
                                        : null,
                                    suffixIcon: IconButton(
                                      key: const Key(
                                        'passwordVisibleConfirmation',
                                      ),
                                      icon: _obscure == true
                                          ? const Icon(Icons.visibility_rounded)
                                          : const Icon(
                                              Icons.visibility_off_rounded,
                                            ),
                                      onPressed: () {
                                        setState(() {
                                          _obscure = !_obscure;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: inputWidth,
                              child: Padding(
                                padding: const EdgeInsets.all(5),
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Your password must have:',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: UI.fontSizeMedium,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.check_circle_outline_rounded,
                                            color: passIColor(
                                              _passwordStructure[ppLength],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            '8 or more characters.',
                                            style: passIStyle(
                                              _passwordStructure[ppLength],
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.check_circle_outline_rounded,
                                            color: passIColor(
                                              _passwordStructure[ppUpLow],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Upper and lowercase letters.',
                                              style: passIStyle(
                                                _passwordStructure[ppUpLow],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.check_circle_outline_rounded,
                                            color: passIColor(
                                              _passwordStructure[ppNumSpec],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'At least one number and one special character.',
                                              style: passIStyle(
                                                _passwordStructure[ppNumSpec],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: inputWidth,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 5,
                                  top: 15,
                                  right: 5,
                                  bottom: 5,
                                ),
                                child: PasswordMeter.full(
                                  score: _passwordScore,
                                  isEmpty: _password.isEmpty,
                                  context: context,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: inputWidth,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 5,
                                  top: 15,
                                  right: 5,
                                  bottom: 15,
                                ),
                                child: Text(
                                  _warning,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: UI.fontSizeSmall),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: inputWidth,
                              child: Padding(
                                padding: const EdgeInsets.all(5),
                                child: SizedBox(
                                  height: 50, //height of button
                                  child: ElevatedButton(
                                    key: const Key('initVaultButton'),
                                    onPressed: () async {
                                      if (_formKey.currentState!.validate()) {
                                        if (await _initVault()) {
                                          ref
                                              .read(launchProvider.notifier)
                                              .launch();
                                          if (context.mounted) {
                                            await Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const LaunchWidget(),
                                                maintainState: false,
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    },
                                    child: Text(
                                      'Create',
                                      style: TextStyle(
                                        fontSize: UI.fontSizeLarge,
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
