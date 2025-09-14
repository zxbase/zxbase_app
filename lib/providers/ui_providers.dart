import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_api_client/zxbase_api_client.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';

class BoolNotifier extends Notifier<bool> {
  @override
  build() {
    return false;
  }

  void set(bool value) {
    state = value;
  }
}

// Applicable to desktop only. True if an entry was modified and not saved.
final isVaultModifiedProvider = NotifierProvider<BoolNotifier, bool>(
  BoolNotifier.new,
);

// Triggers rendering of the new vault entry widget.
final newVaultEntryProvider = NotifierProvider<BoolNotifier, bool>(
  BoolNotifier.new,
);

// Applicable to desktop only. True if the entry was changed.
final isVaultEntryDirtyProvider = NotifierProvider<BoolNotifier, bool>(
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

class IntNotifier extends Notifier<int> {
  @override
  int build() {
    return 0;
  }

  void set(int value) {
    state = value;
  }
}

// Selected bottom navigation bar item.
final selectedTabProvider = NotifierProvider<IntNotifier, int>(IntNotifier.new);

class JSONNotifier extends Notifier<Map<String, dynamic>> {
  @override
  Map<String, dynamic> build() {
    return {};
  }

  void set(Map<String, dynamic> value) {
    state = value;
  }
}

final vaultCandidateProvider =
    NotifierProvider<JSONNotifier, Map<String, dynamic>>(JSONNotifier.new);

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

class SettingNotifier extends Notifier<SettingItem> {
  @override
  SettingItem build() {
    if (UI.isDesktop) {
      return SettingItem.identity; // default page on desktop
    } else {
      return SettingItem.none;
    }
  }

  void set(SettingItem value) {
    state = value;
  }
}

final selectedSettingProvider = NotifierProvider<SettingNotifier, SettingItem>(
  SettingNotifier.new,
);

// Message of the day.
class MOTDNotifier extends Notifier<MOTD?> {
  @override
  MOTD? build() {
    return null;
  }

  void set(MOTD value) {
    state = value;
  }
}

final motdProvider = NotifierProvider<MOTDNotifier, MOTD?>(MOTDNotifier.new);
