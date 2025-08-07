import 'package:zxbase_app/providers/config_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers.dart';

void main() {
  final container = ProviderContainer();

  cleanupDb();
  mockPathProvider();

  test('Validate config fields', () async {
    var configProv = container.read(configProvider);
    await configProv.init();

    expect(configProv.stunPort == 19302, true);
    expect(['.', '/root'].contains(configProv.appPath), true);
    expect(['./Zxbase', '/root/Zxbase'].contains(configProv.dbPath), true);
  });
}
