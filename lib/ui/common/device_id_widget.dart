import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zxbase_app/core/const.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';

Widget deviceIdWidget({
  required BuildContext context,
  required String deviceId,
}) {
  return GestureDetector(
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text('Device ID', style: TextStyle(fontSize: UI.fontSizeMedium)),
          Padding(
            padding: const EdgeInsets.all(5),
            child: Text(
              deviceId,
              style: TextStyle(fontSize: UI.fontSizeSmall),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ),
    onLongPress: () {
      Clipboard.setData(ClipboardData(text: deviceId));
      UI.showSnackbar(context, Const.copyClip);
    },
  );
}
