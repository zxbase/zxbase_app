// Return values and their interpretation.

enum RV {
  ok,
  io,
  invalidIdentity,
  ownIdentity,
  notFound,
  peerExists,
  entryExists,
  titleExists,
  nameExists,
  delete,
}

Map<RV, String> rvMsg = {
  RV.ok: 'OK',
  RV.io: 'I/O error.',
  RV.invalidIdentity: 'Invalid Identity Key.',
  RV.ownIdentity: 'Devices\' own Identity Key.',
  RV.notFound: 'Not found',
  RV.peerExists: 'Peer already exists.',
  RV.entryExists: 'Entry already exists.',
  RV.titleExists: 'The title is taken.',
  RV.nameExists: 'The name is taken.',
  RV.delete: 'Delete the item.',
};
