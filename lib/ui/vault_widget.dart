import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

Widget appBarSearchTextField(
  String hint,
  TextEditingController controller, {
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

//ignore: must_be_immutable
class AppBarDivider extends Divider implements PreferredSizeWidget {
  AppBarDivider({super.key, height = 0.0, super.indent = 0.0, super.color})
    : assert(height >= 0.0),
      super(height: height) {
    preferredSize = Size(double.infinity, height);
  }

  @override
  Size preferredSize = const Size(0, 0);
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
        'Search secrets',
        _searchController,
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
          actions: [IconButton(icon: const Icon(Icons.add), onPressed: () {})],
          title: _searchTextField(ref),
          bottom: AppBarDivider(height: 0.5), //AppBarDivider(height: 0.5),
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
          //),
        ),
      ),
    );
  }
}
