import 'package:flutter_test/flutter_test.dart';
import 'package:zxbase_app/core/channel/connection_helper.dart';

void main() {
  test('def', () {
    var m = offerSdpConstraints;
    expect(m, isNot(equals(null)));

    expect(isIdle(60), equals(true));

    expect(isIdleSince(DateTime.now()), equals(false));
  });
}
