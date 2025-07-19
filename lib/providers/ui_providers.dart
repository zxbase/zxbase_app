import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_api_client/zxbase_api_client.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';

// Applicable to desktop only. True if an entry was modified and not saved.
final isVaultModifiedProvider = StateProvider<bool>((ref) {
  return false;
});

// Search query string.
final searchQueryProvider = StateProvider<String>((ref) {
  return '';
});

// Selected bottom navigation bar item.
enum BarItem {
  vault(0),
  devices(1),
  settings(2);

  const BarItem(this.ind);
  final int ind;
}

final selectedTabProvider = StateProvider<BarItem>((ref) {
  return BarItem.vault; // default tab
});

// vault providers
final vaultCandidateProvider = StateProvider<Map<String, dynamic>>((ref) {
  return {};
});

final vaultSyncWarningProvider = StateProvider<String>((ref) {
  return '';
});

// Triggers rendering of the new vault entry widget.
final newVaultEntryProvider = StateProvider<bool>((ref) {
  return false;
});

// Vault Entry Id.
final selectedVaultEntryProvider = StateProvider<String>((ref) {
  return '';
});

// Applicable to desktop only. True if the entry was changed.
final isVaultEntryDirtyProvider = StateProvider<bool>((ref) {
  return false;
});

// Search vault query string.
final vaultSearchQueryProvider = StateProvider<String>((ref) {
  return '';
});

// TODO: reconsider if it is required
// If true - show vault search.
final showVaultSearchProvider = StateProvider<bool>((ref) {
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

final versionWarningProvider = StateProvider<String>((ref) {
  return '';
});

// Message of the day
final motdProvider = StateProvider<MOTD?>((ref) {
  return null;
});
