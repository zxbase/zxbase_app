// Registration and Pairing Service (RPS) Provider.
// Use it for anything related to registration,
// pairing, channels, peer data.
//
// This is singleton, single instance of API client to be used
// by the whole application. It handles single connection and re-uses
// connection token.
//
// Refrain from wrapping the client or provider.
// Check rps_provider_test for usage example.

import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zxbase_api_client/zxbase_api_client.dart';

const component = 'rpsProvider'; // logging component

final rpsProvider = Provider<RpsClient>((ref) {
  log('Initializing.', name: component);
  return RpsClient();
});
