import 'package:zxbase_app/providers/green_vault/peers_provider.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';

Map<String, AvatarStatus> _avatarStatus = {
  peerStatusCreated: AvatarStatus.unknown,
  peerStatusPairing: AvatarStatus.unknown,
  peerStatusStaged: AvatarStatus.offline,
  peerStatusOffline: AvatarStatus.offline,
  peerStatusOnline: AvatarStatus.online,
};

AvatarStatus avatarStatus(String peerStatus) {
  return _avatarStatus[peerStatus]!;
}
