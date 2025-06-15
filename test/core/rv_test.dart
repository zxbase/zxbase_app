import 'package:zxbase_app/core/rv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('basic definition', () {
    var m = rvMsg;
    expect(m[RV.ok], equals('OK'));
  });
}
