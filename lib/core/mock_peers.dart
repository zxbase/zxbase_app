import 'package:zxbase_app/providers/green_vault/peers_provider.dart';

/*
import 'package:cryptography/cryptography.dart';
import 'package:uuid/uuid.dart';
import 'package:core/crypto.dart';
import 'package:core/identity.dart';
*/

Future mockPeers(PeersNotifier peersNotifier) async {
  /* Uncomment to generate more Id
  Identity idnt;
  SimpleKeyPair identityKeyPair;
  String id;

  id = const Uuid().v4();
  identityKeyPair = await generateKeyPair();
  SimplePublicKey pubK = await identityKeyPair.extractPublicKey();
  idnt = Identity(deviceId: id, publicKey: pubK);

  print('Identity');
  print(idnt.toBase64Url());
*/

  await peersNotifier.addPeer(
    Peer.create(
      identityStr:
          'eyJrdHkiOiJPS1AiLCJjcnYiOiJFZDI1NTE5IiwieCI6IjlLRzVnclhKZ19teWg3cUVXTk1fenc2ZVhaV3JqUEF6dTNmUWNaV2J6T2c9Iiwia2lkIjoiYjFmMmE3MzItNTBhNy00ZDA3LWI5MjktOWZiMTA1ZmYxNGNiIiwidmVyIjoxfQ==',
      nickname: 'Jan Koum Mobile',
    ),
  );
  // device: 'Mobile',
  // firstName: 'Jan',
  // lastName: 'Koum'));

  await peersNotifier.addPeer(
    Peer.create(
      identityStr:
          'eyJrdHkiOiJPS1AiLCJjcnYiOiJFZDI1NTE5IiwieCI6Iml4UEJwODFvNEdRb3p5Z3E4YThoQUFSYUdLbGxxa2RoMl8yeWdNR0tBRmM9Iiwia2lkIjoiYzFmYjU5MTItYzg5MS00YmQyLThhY2EtNDUwM2VhZmU4YzYzIiwidmVyIjoxfQ==',
      nickname: 'Brian Action Laptop',
    ),
  );
  // device: 'Laptop',
  // firstName: 'Brian',
  // lastName: 'Acton'));

  await peersNotifier.addPeer(
    Peer.create(
      identityStr:
          'eyJrdHkiOiJPS1AiLCJjcnYiOiJFZDI1NTE5IiwieCI6Inpud3NLelczZlBfbWtobGN1Rkl3TTEzVlJqQ0hTUkZGLXN0QW9mLVJNWWM9Iiwia2lkIjoiYmY2YmQzNjctMmM5Zi00ZGMzLWE1OTMtNWRkMTMxODBhMDljIiwidmVyIjoxfQ==',
      nickname: 'Max Levchin',
    ),
  );
  // device: 'Mobile',
  // firstName: 'Max',
  // lastName: 'Levchin'));

  await peersNotifier.addPeer(
    Peer.create(
      identityStr:
          'eyJrdHkiOiJPS1AiLCJjcnYiOiJFZDI1NTE5IiwieCI6ImFoWGRfMlJsNHY2ajNNdDBWVlU5Z2xtX1ZfUEtpQ3ViVWpTMDhyNVZlT1k9Iiwia2lkIjoiNGE1OWVlMTgtNzRmZC00NTJjLWJjMzMtYTU3MGI0YjNkYzZmIiwidmVyIjoxfQ==',
      nickname: 'Bruce Schneier\'s Desktop',
    ),
  );
  // device: 'Desktop',
  // firstName: 'Bruce',
  // lastName: 'Schneier'));

  await peersNotifier.addPeer(
    Peer.create(
      identityStr:
          'eyJrdHkiOiJPS1AiLCJjcnYiOiJFZDI1NTE5IiwieCI6IkVfcG9DOUQ0bFc4ZWUzdnBXWVF2dUllRkpPM2U3dTNLREZXX01SeFFieUU9Iiwia2lkIjoiZDU4NmRlNjAtOWJhNy00NjNkLWEwODItZDk1MTVjNWJiZjJkIiwidmVyIjoxfQ==',
      nickname: 'Yair Goldfinger',
    ),
  );
  // device: 'Desktop',
  // firstName: 'Yair',
  // lastName: 'Goldfinger'));

  await peersNotifier.addPeer(
    Peer.create(
      identityStr:
          'eyJrdHkiOiJPS1AiLCJjcnYiOiJFZDI1NTE5IiwieCI6ImJwNGxKc1Zod2VqMGhkSzRWdG9DZFpKQ0FSUlk2ZXAwcF9DU05NVzhDaEU9Iiwia2lkIjoiMmVlYzI0ODctYmM2My00Yjc1LWE3YjctMjRkMGFmMjAyOGNkIiwidmVyIjoxfQ==',
      nickname: 'Robert Surcouf',
    ),
  );
  // device: 'Revenant',
  // firstName: 'Robert',
  // lastName: 'Surcouf'));
}
