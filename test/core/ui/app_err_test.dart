import 'package:zxbase_app/core/ui/app_err.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('basic definition', () {
    var m = appErrMsg;
    expect(m[AppErr.ok], equals('OK'));
  });
}
