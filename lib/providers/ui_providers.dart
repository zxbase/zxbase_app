import 'package:flutter_riverpod/flutter_riverpod.dart';

// Applicable to desktop only. True if an entry was modified and not saved.
final isVaultModifiedProvider = StateProvider<bool>((ref) {
  return false;
});

// Search query string.
final searchQueryProvider = StateProvider<String>((ref) {
  return '';
});

// Selected tab index.
final selectedTabProvider = StateProvider<int>((ref) {
  return 0; // default tab
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
