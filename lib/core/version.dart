const privacyPolicyUrl = 'https://zxbase.com/pages/privacy_policy/';
const termsOfServicesUrl = 'https://zxbase.com/pages/terms_of_service/';
const appStoreUrls = {
  'ios': 'https://apps.apple.com/us/app/zxbase/id1608405737',
  'macos': 'https://apps.apple.com/us/app/zxbase/id1608405737',
  'android': 'https://play.google.com/store/apps/details?id=com.zxbase.base',
  'windows': 'https://www.microsoft.com/en-us/p/zxbase/9nsd9m2c2mxk',
  'linux': 'https://snapcraft.io/zxbase',
  'fuchsia': '',
};

// Class containing version and build derived from a string
// of format '3.1.14 (90)'.
class Version {
  Version({required this.text}) {
    List<String> arr = text.split(' (');
    version = arr[0];
    build = int.parse(arr[1].substring(0, arr[1].length - 1));
  }

  final String text;
  late String version;
  late int build;
}
