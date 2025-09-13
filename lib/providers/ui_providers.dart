import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_api_client/zxbase_api_client.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';

// Applicable to desktop only. True if an entry was modified and not saved.
class BoolNotifier extends Notifier<bool> {
  @override
  build() {
    return false;
  }
}

final isVaultModifiedProvider = NotifierProvider<BoolNotifier, bool>(
  BoolNotifier.new,
);

class StringNotifier extends Notifier<String> {
  @override
  build() {
    return '';
  }

  void set(String value) {
    state = value;
  }
}

// Search query string.
final searchQueryProvider = NotifierProvider<StringNotifier, String>(
  StringNotifier.new,
);

// Sync warning.
final vaultSyncWarningProvider = NotifierProvider<StringNotifier, String>(
  StringNotifier.new,
);

// Vault Entry Id.
final selectedVaultEntryProvider = NotifierProvider<StringNotifier, String>(
  StringNotifier.new,
);

// Version warning.
final versionWarningProvider = NotifierProvider<StringNotifier, String>(
  StringNotifier.new,
);

// Selected device Id.
final selectedDeviceProvider = NotifierProvider<StringNotifier, String>(
  StringNotifier.new,
);

// Selected bottom navigation bar item.
final selectedTabProvider = StateProvider<int>((ref) {
  return 0; // default tab
});

// vault providers
final vaultCandidateProvider = StateProvider<Map<String, dynamic>>((ref) {
  return {};
});

// Triggers rendering of the new vault entry widget.
final newVaultEntryProvider = StateProvider<bool>((ref) {
  return false;
});

// Applicable to desktop only. True if the entry was changed.
final isVaultEntryDirtyProvider = StateProvider<bool>((ref) {
  return false;
});

// Selected setting.
enum SettingItem {
  identity(0, 'Identity'),
  appearance(1, 'Appearance'),
  about(2, 'About'),
  none(3, '');

  const SettingItem(this.ind, this.title);
  final int ind;
  final String title;
}

final selectedSettingProvider = StateProvider<SettingItem>((ref) {
  if (UI.isDesktop) {
    return SettingItem.identity; // default page on desktop
  } else {
    return SettingItem.none;
  }
});

// Message of the day
final motdProvider = StateProvider<MOTD?>((ref) {
  return null;
});
