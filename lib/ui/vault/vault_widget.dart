import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zxbase_app/core/const.dart';
import 'package:zxbase_app/providers/green_vault/user_vault_provider.dart';
import 'package:zxbase_app/providers/ui_providers.dart';
import 'package:zxbase_app/ui/app_bar.dart';
import 'package:zxbase_app/ui/vault/vault_entry_widget.dart';
import 'package:zxbase_app/ui/vault/vault_secret_widget.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';

class VaultWidget extends ConsumerStatefulWidget {
  const VaultWidget({super.key});

  @override
  ConsumerState createState() => VaultEntryListState();
}

class VaultEntryListState extends ConsumerState<VaultWidget> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  void clearSearch() {
    _searchController.text = '';
  }

  Widget _searchTextField(WidgetRef ref) {
    return CallbackShortcuts(
      bindings: {LogicalKeySet(LogicalKeyboardKey.escape): clearSearch},
      child: appBarSearchTextField(
        hint: 'Search secrets',
        controller: _searchController,
        onChanged: (value) {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String selectedEntry = ref.watch(selectedVaultEntryProvider);
    String searchQuery = ref.watch(vaultSearchQueryProvider);
    List<UserVaultEntry> entriesAll = ref
        .watch(userVaultProvider)
        .entries
        .values
        .toList();

    List<UserVaultEntry> entries = [];
    var entryIds = ref
        .read(userVaultProvider.notifier)
        .search(query: searchQuery);
    entries = entriesAll
        .where((element) => entryIds.contains(element.id))
        .toList();
    entries.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );

    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Scaffold(
        appBar: AppBar(
          actions: [
            Container(
              padding: EdgeInsets.only(top: UI.isDesktop ? 12.0 : 4.0),
              child: IconButton(
                color: Theme.of(context).textTheme.bodySmall!.color,
                icon: const Icon(Icons.add),
                tooltip: 'Add secret',
                onPressed: () async {
                  if (entriesAll.length >= Const.vaultEntriesMaxCount) {
                    UI.showSnackbar(context, 'Entries limit reached.');
                    return;
                  }

                  ref.read(newVaultEntryProvider.notifier).state = true;
                  ref.read(selectedVaultEntryProvider.notifier).state = '';

                  if (UI.isMobile) {
                    await Navigator.push(
                      context,
                      (MaterialPageRoute(
                        builder: (context) => VaultSecretWidget(),
                      )),
                    );
                  }
                },
              ),
            ),
          ],
          title: _searchTextField(ref),
          bottom: preferredSizeDivider(height: 0.5),
        ),
        body: Padding(
          padding: const EdgeInsets.only(right: 1.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(),
            child: ListView.builder(
              controller: ScrollController(),
              itemCount: entries.length,
              itemBuilder: (BuildContext context, int index) {
                String entryId = entries[index].id;
                bool isSelected = (entryId == selectedEntry);
                return VaultEntryWidget(
                  entry: entries[index],
                  isSelected: isSelected,
                );
              },
              shrinkWrap: true,
            ),
          ),
        ),
      ),
    );
  }
}
