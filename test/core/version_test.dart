import 'package:zxbase_app/core/version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Check version', () async {
    Version version = Version(text: '3.1.14 (90)');
    expect(version.build, equals(90));
    expect(version.version, equals('3.1.14'));
  });
}
