import 'dart:convert';

const String sigAnswerMsg = 'answer';
const String sigCandidateMsg = 'candidate';
const String sigOfferMsg = 'offer';
const String sigHelloMsg = 'hello';
const String sigHB = 'heartbeat';

class SignalingMessage {
  SignalingMessage({
    required this.type,
    required this.app,
    required this.from,
    required this.to,
    required this.channelId,
    required this.data,
  });

  SignalingMessage.fromMap(Map<String, dynamic> map) {
    type = map['type'];
    app = map['app'];
    from = map['from'];
    to = map['to'];
    channelId = map['channelId'];
    data = map['data'];
  }

  late String type;
  late String app;
  late String from;
  late String to;
  late String channelId;
  dynamic data;

  String get str {
    return jsonEncode({
      'type': type,
      'app': app,
      'from': from,
      'to': to,
      'channelId': channelId,
      'data': data,
    });
  }
}
