import 'dart:io' show Directory, File;
import 'package:grinder/grinder.dart' show getFile;
import 'package:pub_semver/pub_semver.dart' show Version;
import 'package:yaml/yaml.dart' show loadYaml;
import 'package:path/path.dart' as path;

typedef String VersionFileTemplate(String version);

String versionFileTemplate(String version) =>
    'const String packageVersion  = \'$version\';';

/// Write the package version into a Dart source file
void writeVersionInfoFile(
    {String versionFilePath: 'lib/src/version_info.dart',
    VersionFileTemplate versionFileTemplate: versionFileTemplate}) {
  assert(versionFilePath != null && versionFilePath.endsWith('.dart'));
  // Read the version from the pubspec.
  final pubspecFile = getFile('pubspec.yaml');
  final pubspec = pubspecFile.readAsStringSync();
  final version = new Version.parse(loadYaml(pubspec)["version"] as String);
  new Directory(path.dirname(versionFilePath)).createSync(recursive: true);
  new File(versionFilePath).writeAsStringSync(versionFileTemplate('$version'));
}
