import 'package:zxbase_app/core/channel/connection.dart';
import 'package:zxbase_app/providers/blue_vault/blue_vault_provider.dart';
import 'package:zxbase_app/providers/blue_vault/init_provider.dart';
import 'package:zxbase_app/providers/config_provider.dart';
import 'package:zxbase_app/providers/connections_provider.dart';
import 'package:zxbase_app/providers/green_vault/device_provider.dart';
import 'package:zxbase_app/providers/green_vault/green_vault_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers.dart';

void main() {
  const pwd = '12345678cC%';
  const peerId = '123e4567-e89b-12d3-a456-426614174000';

  cleanupDb();
  mockPathProvider();

  test('construct connection', () async {
    // scope container to a single test
    final container = ProviderContainer();
    addTearDown(container.dispose);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('FlutterWebRTC.Method'), (
          MethodCall methodCall,
        ) async {
          switch (methodCall.method) {
            case 'createPeerConnection':
              return {'peerConnectionId': 'peerConnectionId'};
            default:
              return true;
          }
        });

    // init sequence
    await container.read(configProvider).init();
    await container.read(blueVaultProvider.notifier).init();
    await container.read(initProvider.notifier).init();
    await container.read(greenVaultProvider.notifier).init(pwd);
    await container.read(deviceProvider.notifier).init();

    Connections connections = container.read(connectionsProvider);
    await container.read(connectionsProvider).initConnection(peerId: peerId);

    Connection conn = connections.connections[peerId]!;
    expect(conn.peerId, equals(peerId));
  });
}
