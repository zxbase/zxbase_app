import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';
import 'package:zxbase_app/core/const.dart';
import 'package:zxbase_app/providers/blue_vault/init_provider.dart';
import 'package:zxbase_app/providers/green_vault/device_provider.dart';
import 'package:zxbase_app/providers/green_vault/green_vault_provider.dart';
import 'package:zxbase_app/providers/green_vault/settings_provider.dart';
import 'package:zxbase_app/providers/green_vault/user_vault_provider.dart';
import 'package:zxbase_app/providers/launch_provider.dart';
import 'package:zxbase_app/ui/launch/launch_widget.dart';

const _component = 'openVaultWidget'; // logging component
const _header = 'Welcome back';

class OpenVaultWidget extends ConsumerStatefulWidget {
  const OpenVaultWidget({super.key});
  @override
  OpenVaultWidgetState createState() => OpenVaultWidgetState();
}

class OpenVaultWidgetState extends ConsumerState<OpenVaultWidget> {
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  String _password = '';

  late int _loginAttempts;
  List<int> delay = [0, 10, 30, 60];

  bool _wrongPassword = false;
  bool _buttonEnabled = true;
  bool _capsLockOn = false;

  void scheduleToEnableLogin() {
    Future.delayed(Duration(seconds: delay[_loginAttempts]), () {
      setState(() {
        _buttonEnabled = true;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _loginAttempts = ref.read(initProvider).attempts;
    DateTime attemptDate = DateTime.fromMillisecondsSinceEpoch(
      ref.read(initProvider).attemptDate,
    );
    int diffInSeconds = DateTime.now().difference(attemptDate).inSeconds;
    if (diffInSeconds < delay[_loginAttempts]) {
      // application was restarted to speed up brute force
      _wrongPassword = true;
      _buttonEnabled = false;
      scheduleToEnableLogin();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                                  bottom: 5,
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
                                  bottom: 5,
                                ),
                                child: TextFormField(
                                  key: const Key('passwordInput'),
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(
                                      Const.passwordMaxLength,
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (_wrongPassword) {
                                      // remove error message
                                      _wrongPassword = false;
                                      _formKey.currentState!.validate();
                                    }
                                  },
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return Const.passEmptyWant;
                                    }

                                    if (_wrongPassword) {
                                      return 'Wrong password, try again in ${delay[_loginAttempts]} seconds.';
                                    }

                                    _password = value;
                                    return null;
                                  },
                                  obscureText: _obscure,
                                  keyboardType: TextInputType.visiblePassword,
                                  decoration: InputDecoration(
                                    helperText: ' ', // prevent height change
                                    hintText: 'Password',
                                    prefixIcon: _capsLockOn
                                        ? const Icon(
                                            Icons.keyboard_capslock_rounded,
                                            color: Colors.grey,
                                          )
                                        : null,
                                    suffixIcon: IconButton(
                                      icon: _obscure == true
                                          ? const Icon(Icons.visibility_rounded)
                                          : const Icon(
                                              Icons.visibility_off_rounded,
                                            ),
                                      color: Colors.grey,
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
                                child: SizedBox(
                                  height: 50, //height of button
                                  child: ElevatedButton(
                                    key: const Key('openVaultButton'),
                                    onPressed: _buttonEnabled
                                        ? () async {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              if (await openVault()) {
                                                ref
                                                    .read(
                                                      launchProvider.notifier,
                                                    )
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
                                          }
                                        : null,
                                    child: Text(
                                      'Open vault',
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

  Future<bool> openVault() async {
    if (!(await ref.read(greenVaultProvider.notifier).open(_password))) {
      log('Wrong vault password.', name: _component);
      _loginAttempts = (_loginAttempts + 1) >= delay.length
          ? delay.length - 1
          : _loginAttempts + 1;
      _wrongPassword = true;
      _formKey.currentState!.validate();

      setState(() {
        // rebuild widget in order to disable the button
        _buttonEnabled = false;
      });
      await ref.read(initProvider.notifier).setAttempts(_loginAttempts);
      scheduleToEnableLogin();
      return false;
    }

    _loginAttempts = 0;
    await ref.read(initProvider.notifier).setAttempts(_loginAttempts);

    log('Green vault has been opened.', name: _component);
    await ref.read(settingsProvider.notifier).open();
    await ref.read(deviceProvider.notifier).open();
    await ref.read(userVaultProvider.notifier).open();

    return true;
  }
}
