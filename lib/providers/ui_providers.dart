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
