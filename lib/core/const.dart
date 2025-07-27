// Re-usable constants.

class Const {
  static const peerMaxCount = 30;
  static const msgMaxLength = 512;
  static const passwordMinLength = 8;
  static const passwordMaxLength = 32;
  static const nicknameMaxLength = 32;
  static const identityMaxLength = 512;
  static const nicknameEmptyWarn = 'Nickname can not be empty';
  static const nicknameLongWarn = 'Nickname is too long';
  static const idntEmptyWarn = 'Identity can not be empty';
  static const passEmptyWant = 'Password can not be empty';
  static const connectionIdle = 20;
  static const msgMaxCount = 100;
  static const vaultEntriesMaxCount = 1024;
  static const vaultURIsMaxCount = 16;
  static const vaultTitleMaxLength = 64;
  static const vaultUsernameMaxLength = 128;
  static const vaultPasswordMaxLength = 128;
  static const vaultNotesMaxLength = 8192;
  static const vaultUrlMaxLength = 512;
  static const titleEmptyWarn = 'Title can not be empty';
  static const titleLongWarn = 'Title is too long';
  static const usernameLongWarn = 'Username is too long';
  static const passwordLongWarn = 'Password is too long';
  static const notesEmptyWarn = 'Notes can not be empty';
  static const notesLongWarn = 'Notes are too long';
  static const urlLongWarn = 'Url is too long';
  static final minDate = DateTime.utc(-271821, 04, 20);
  static const vaultGroupWarn = 'Add devices to sync the vault';
  static const vaultSyncWarn = 'Sync required';
  static const discardWarn = 'Are you sure you want to discard changes?';
  static const copyIdnt = 'Copy identity to clipboard';
  static const attentionWarn = 'Attention required';
  static const newVersionMsg = 'A newer version is available';
}
