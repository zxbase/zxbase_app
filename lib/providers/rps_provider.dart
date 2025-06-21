// Registration and Pairing Service (RPS) Provider.
// Use it for anything related to registration,
// pairing, channels, peer data.
//
// This is singleton, single instance of API client to be used
// by the whole application. It handles single connection and re-uses
// connection token.
//
// API client is a repository, representing RPS REST endpoint.
// If new functionality is required, don't change this
// provider, ask for changes in API client package.
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
