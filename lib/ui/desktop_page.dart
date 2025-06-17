import 'package:flutter/material.dart';

import 'package:zxbase_app/ui/explorer_widget.dart';

class DesktopPage extends StatelessWidget {
  const DesktopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.25,
            child: const ExplorerWidget(),
          ),
          const VerticalDivider(width: 0),
        ],
      ),
    );
  }
}
