import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';

Widget deviceIdWidget(BuildContext context, String deviceId) {
  return GestureDetector(
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text('Device ID:', style: TextStyle(fontSize: UI.fontSizeMedium)),
          Padding(
            padding: const EdgeInsets.all(5),
            child: Text(
              deviceId,
              style: TextStyle(fontSize: UI.fontSizeSmall),
              textAlign: TextAlign.center,
            ),
          ),
          Text(
            '(hold to copy to clipboard)',
            style: TextStyle(fontSize: UI.fontSizeSmall),
          ),
        ],
      ),
    ),
    onLongPress: () {
      Clipboard.setData(ClipboardData(text: deviceId));
      UI.showSnackbar(context, 'Copied!');
    },
  );
}
