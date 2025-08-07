import 'package:flutter/material.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';

PreferredSizeWidget preferredSizeDivider({double height = 1.0}) {
  return PreferredSize(
    preferredSize: Size(double.infinity, height),
    child: Divider(indent: 0.0, height: 0.0),
  );
}

Widget appBarSearchTextField({
  String? hint,
  TextEditingController? controller,
  Function(String)? onChanged,
}) {
  return Row(
    children: [
      Expanded(
        child: TextField(
          controller: controller,
          textAlign: TextAlign.start,
          maxLines: 1,
          decoration: InputDecoration(hintText: hint, border: InputBorder.none),
          onChanged: onChanged,
          autofocus: UI.isMobile
              ? false
              : true, // otherwise keyboard pops up immediately
        ),
      ),
    ],
  );
}

TextButton appBarTextButton(
  BuildContext context,
  String text,
  VoidCallback onPressed,
) {
  return TextButton(
    onPressed: onPressed,
    child: Text(
      text,
      textAlign: TextAlign.center,
      // textScaleFactor: UI.appBarTextFactor,
      style: TextStyle(
        fontSize: UI.fontSizeSmall,
        color: Theme.of(context).appBarTheme.foregroundColor,
      ),
    ),
  );
}
