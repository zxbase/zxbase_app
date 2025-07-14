// Log helpers.

String logUuid(String uuid) {
  return uuid.substring(0, 8);
}

String logPeer(String peerId) {
  return 'Peer ${logUuid(peerId)}';
}
