import 'package:flutter_riverpod/flutter_riverpod.dart';

// Applicable to desktop only. True if an entry was modified and not saved.
final isVaultModifiedProvider = StateProvider<bool>((ref) {
  return false;
});

// Search query string.
final searchQueryProvider = StateProvider<String>((ref) {
  return '';
});
