import 'package:flutter/material.dart';

class ScrollColumnExpandableWidget extends StatelessWidget {
  const ScrollColumnExpandableWidget({super.key, required this.child});

  final Column child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraint) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraint.maxHeight),
            child: IntrinsicHeight(child: child),
          ),
        );
      },
    );
  }
}
