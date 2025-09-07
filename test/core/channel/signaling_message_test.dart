import 'package:flutter_test/flutter_test.dart';
import 'package:zxbase_app/core/channel/connection_helper.dart';
import 'package:zxbase_app/core/channel/signaling_message.dart';

void main() {
  test('construct signaling message', () {
    SignalingMessage msg = SignalingMessage(
      type: sigHelloMsg,
      app: defaultApp,
      from: 'A',
      to: 'B',
      channelId: '1',
      data: 'xxx',
    );
    String str = msg.str;
    expect(
      str,
      equals(
        '{"type":"hello","app":"messenger","from":"A","to":"B","channelId":"1","data":"xxx"}',
      ),
    );
  });

  test('construct signaling message from map', () {
    var message = {
      'type': 'hello',
      'app': 'messenger',
      'from': 'A',
      'to': 'B',
      'channelId': '1',
      'data': 'xxx',
    };
    SignalingMessage msg = SignalingMessage.fromMap(message);
    String str = msg.str;
    expect(
      str,
      equals(
        '{"type":"hello","app":"messenger","from":"A","to":"B","channelId":"1","data":"xxx"}',
      ),
    );
  });
}
