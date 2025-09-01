import 'dart:convert';

const String cmHsChallenge = 'hsChallenge';
const String cmHsResponse = 'hsResponse';
const String cmMessage = 'directMessage';
const String cmReceipt = 'directReceipt';
const String cmHeartbeat = 'hb';
const String cmVault = 'vault';

class ChannelMessage {
  ChannelMessage({required this.type, required this.data});
  ChannelMessage.fromString(String s) {
    Map<String, dynamic> map = jsonDecode(s);
    type = map['type'];
    data = map['data'];
  }

  late String type;
  dynamic data;

  String get str {
    return jsonEncode({'type': type, 'data': data});
  }
}
