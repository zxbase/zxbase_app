import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_app/ui/explorer_widget.dart';
import 'package:zxbase_app/ui/vault/vault_secret_widget.dart';
import 'package:zxbase_app/providers/ui_providers.dart';

class DesktopWidget extends ConsumerWidget {
  const DesktopWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isNewVaultEntry = ref.watch(newVaultEntryProvider);
    var selectedVaultEntryId = ref.watch(selectedVaultEntryProvider);

    return Scaffold(
      body: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.38,
            child: const ExplorerWidget(),
          ),
          const VerticalDivider(width: 0),
          Expanded(
            child: (isNewVaultEntry || selectedVaultEntryId != '')
                ? VaultSecretWidget()
                : Container(),
          ),
        ],
      ),
    );
  }
}
