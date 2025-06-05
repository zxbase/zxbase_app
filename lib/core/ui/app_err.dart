// Error constants.
// Use it to pass error messages to UI.

enum AppErr {
  ok,
  io,
  invalidIdentity,
  ownIdentity,
  notFound,
  peerExists,
  entryExists,
  titleExists,
  nameExists,
}

Map<AppErr, String> appErrMsg = {
  AppErr.ok: 'OK',
  AppErr.io: 'I/O error.',
  AppErr.invalidIdentity: 'Invalid identity.',
  AppErr.ownIdentity: 'My own identity.',
  AppErr.notFound: 'Not found',
  AppErr.peerExists: 'Peer already exists.',
  AppErr.entryExists: 'Entry already exists.',
  AppErr.titleExists: 'The title is taken.',
  AppErr.nameExists: 'The name is taken.',
};
