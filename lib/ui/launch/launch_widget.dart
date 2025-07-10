// Widget displaying a spinning wheel and statuses.
// Watching launch provider.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_app/ui/desktop_widget.dart';
import 'package:zxbase_app/ui/explorer_widget.dart';
import 'package:zxbase_app/ui/launch/spin_widget.dart';
import 'package:zxbase_app/providers/launch_provider.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';

class LaunchWidget extends ConsumerStatefulWidget {
  const LaunchWidget({super.key});
  @override
  WorkflowPageState createState() => WorkflowPageState();
}

class WorkflowPageState extends ConsumerState<LaunchWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    LaunchStage stage = ref.watch(launchProvider);
    if (stage.stage == LaunchStageEnum.success) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                UI.isDesktop ? DesktopWidget() : ExplorerWidget(),
            maintainState: false,
          ),
        );
      });
    }

    return Builder(
      builder: (context) {
        return spinScaffold(stage.err);
      },
    );
  }
}
