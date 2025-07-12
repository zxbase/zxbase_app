import 'package:flutter/material.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';

void showInfoDialog(
  BuildContext context,
  String text, {
  String? title,
  String buttonText = 'OK',
  Function? onTap,
  bool barrierDismissible = true,
}) {
  showCustomDialog(
    context,
    Text(text, textAlign: TextAlign.justify),
    title: title,
    leftButtonText: buttonText,
    onLeftTap: onTap,
    barrierDismissible: barrierDismissible,
  );
}

void showCustomDialog(
  BuildContext context,
  Widget content, {
  String? title,
  String leftButtonText = 'OK',
  Function? onLeftTap,
  String? rightButtonText,
  Function? onRightTap,
  bool barrierDismissible = true,
}) {
  showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) {
      return AlertDialog(
        scrollable: true,
        title: title != null ? Text(title, textAlign: TextAlign.center) : null,
        content: Center(
          child: Column(
            children: [
              content,
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          if (onLeftTap != null) {
                            onLeftTap();
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        child: Text(
                          leftButtonText,
                          style: TextStyle(fontSize: UI.fontSizeLarge),
                        ),
                      ),
                      Visibility(
                        visible: rightButtonText != null,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: TextButton(
                            onPressed: () {
                              if (onRightTap != null) {
                                onRightTap();
                              } else {
                                Navigator.pop(context);
                              }
                            },
                            child: Text(
                              rightButtonText ?? '',
                              style: TextStyle(fontSize: UI.fontSizeLarge),
                            ),
                          ),
                        ),
                      ),
                    ],
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

void showContentDialog(
  BuildContext context,
  String title,
  Widget content, {
  bool showActionButton = true,
  String buttonText = 'OK',
  Function? onTap,
  bool barrierDismissible = true,
}) {
  showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) {
      return AlertDialog(
        scrollable: true,
        title: Text(title, textAlign: TextAlign.center),
        content: Column(
          children: [
            content,
            Visibility(
              visible: showActionButton,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (onTap != null) onTap();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Text(
                      buttonText,
                      style: TextStyle(fontSize: UI.fontSizeLarge),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
