import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';

Widget appBarSearchTextField({
  String? hint,
  TextEditingController? controller,
  Function(String)? onChanged,
}) {
  return Row(
    children: [
      Expanded(
        child: TextField(
          textAlignVertical: TextAlignVertical.center,
          controller: controller,
          textAlign: TextAlign.start,
          maxLines: 1,
          decoration: InputDecoration(hintText: hint, border: InputBorder.none),
          onChanged: onChanged,
          autofocus: true,
        ),
      ),
    ],
  );
}

PreferredSizeWidget preferredSizeDivider({double height = 1.0}) {
  return PreferredSize(
    preferredSize: Size(double.infinity, height),
    child: Divider(indent: 0.0, height: 0.0),
  );
}

class VaultWidget extends ConsumerStatefulWidget {
  const VaultWidget({super.key});

  @override
  ConsumerState createState() => _VaultWidgetState();
}

class _VaultWidgetState extends ConsumerState<VaultWidget> {
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
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Scaffold(
        appBar: AppBar(
          actions: [
            Container(
              padding: EdgeInsets.only(top: UI.isDesktop ? 12.0 : 4.0),
              child: IconButton(icon: const Icon(Icons.add), onPressed: () {}),
            ),
          ],
          title: _searchTextField(ref),
          bottom: preferredSizeDivider(height: 0.5),
        ),
        body: Padding(
          padding: const EdgeInsets.only(right: 0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(),
            child: ListView.builder(
              controller: ScrollController(),
              itemCount: 1,
              itemBuilder: (BuildContext context, int index) {
                return Container();
              },
              shrinkWrap: true,
            ),
          ),
        ),
      ),
    );
  }
}
