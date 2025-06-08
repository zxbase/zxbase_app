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
