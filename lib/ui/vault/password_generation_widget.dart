import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zxbase_crypto/zxbase_crypto.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';
import 'package:zxcvbn/zxcvbn.dart';

class PasswordGenerationWidget extends StatefulWidget {
  const PasswordGenerationWidget({super.key, required this.onSetPassword});

  final Function(String) onSetPassword;

  @override
  State<StatefulWidget> createState() => PasswordGenerationWidgetState();
}

class PasswordGenerationWidgetState extends State<PasswordGenerationWidget> {
  static const _minLength = 10;
  static const _maxLength = 32;
  static const _defaultLength = 12;

  int _length = _defaultLength;
  bool _lowerCase = true;
  bool _upperCase = true;
  bool _numbers = true;
  bool _special = true;

  final _zxcvbn = Zxcvbn();
  late double _passwordScore;
  late String _password;

  void _updatePassword() {
    _password = _generatePassword();
    _passwordScore = _zxcvbn.evaluate(_password).score!;
  }

  @override
  void initState() {
    setState(() {
      _updatePassword();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SelectableText(_password, textAlign: TextAlign.center),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_upward_rounded),
              tooltip: 'Set',
              onPressed: () {
                widget.onSetPassword(_password);
              },
            ),
            IconButton(
              icon: const Icon(Icons.sync_rounded),
              tooltip: 'Regenerate',
              onPressed: () {
                setState(() {
                  _updatePassword();
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.copy_rounded),
              tooltip: 'Copy',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _password));
                UI.showSnackbar(context, 'Copied!');
              },
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: PasswordMeter.full(
            score: _passwordScore,
            isEmpty: _password.isEmpty,
            context: context,
          ),
        ),
        Row(
          children: [
            const Text('Length'),
            const Spacer(),
            Text('$_length'),
            Slider(
              value: _length.toDouble(),
              min: _minLength.toDouble(),
              max: _maxLength.toDouble(),
              onChanged: (value) {
                setState(() {
                  _length = value.toInt();
                  _updatePassword();
                });
              },
            ),
          ],
        ),
        Row(
          children: [
            const Text('a-z'),
            const Spacer(),
            Switch(
              value: _lowerCase,
              onChanged: (value) {
                if (!(_upperCase || _numbers || _special)) {
                  return;
                }
                setState(() {
                  _lowerCase = value;
                  _updatePassword();
                });
              },
            ),
          ],
        ),
        Row(
          children: [
            const Text('A-Z'),
            const Spacer(),
            Switch(
              value: _upperCase,
              onChanged: (value) {
                if (!(_lowerCase || _numbers || _special)) {
                  return;
                }

                setState(() {
                  _upperCase = value;
                  _updatePassword();
                });
              },
            ),
          ],
        ),
        Row(
          children: [
            const Text('0-9'),
            const Spacer(),
            Switch(
              value: _numbers,
              onChanged: (value) {
                if (!(_lowerCase || _upperCase || _special)) {
                  return;
                }

                setState(() {
                  _numbers = value;
                  _updatePassword();
                });
              },
            ),
          ],
        ),
        Row(
          children: [
            const Text(Password.specialChars),
            const Spacer(),
            Switch(
              value: _special,
              onChanged: (value) {
                if (!(_lowerCase || _upperCase || _numbers)) {
                  return;
                }

                setState(() {
                  _special = value;
                  _updatePassword();
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  String _generatePassword() {
    return Password.generatePassword(
      lowerCase: _lowerCase,
      upperCase: _upperCase,
      numbers: _numbers,
      special: _special,
      length: _length,
    );
  }
}
