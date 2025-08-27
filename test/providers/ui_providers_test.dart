import 'package:zxbase_app/providers/ui_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers.dart';

void main() {
  final container = ProviderContainer();

  cleanupDb();
  mockPathProvider();

  test('Modified vault provider', () async {
    var isVaultModified = container.read(isVaultModifiedProvider);

    expect(isVaultModified == false, true);
  });

  test('Search query provider', () async {
    container.read(searchQueryProvider.notifier).state = 'search';
    var searchQuery = container.read(searchQueryProvider);

    expect(searchQuery == 'search', true);
  });

  test('Selected tab provider', () async {
    container.read(selectedTabProvider.notifier).state = 1;
    var selectedTab = container.read(selectedTabProvider);

    expect(selectedTab == 1, true);
  });
}
