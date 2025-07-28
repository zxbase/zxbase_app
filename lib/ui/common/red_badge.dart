import 'package:flutter/material.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';

class RedBadge extends StatelessWidget {
  const RedBadge({
    super.key,
    this.color = Colors.red,
    this.size = UI.badgeSize,
    this.text = '',
  });
  final Color color;
  final double size;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 0.5),
      ),
    );
  }
}
