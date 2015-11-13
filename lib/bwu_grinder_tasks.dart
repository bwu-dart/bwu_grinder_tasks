library bwu_grinder_tasks;

import 'dart:io' as io;
import 'package:grinder/grinder.dart';
export 'package:grinder/grinder.dart' show DefaultTask, Depends, Task, grind;
import 'src/dartformat_task.dart';

// TODO(zoechi) check if version was incremented
// TODO(zoechi) check if CHANGELOG.md contains version

//@Task('Delete build directory')
//void clean() => defaultClean(context);

const sourceDirs = const ['bin', 'example', 'lib', 'test', 'tool', 'web'];
final existingSourceDirs = sourceDirs
    .where((d) => new io.Directory(d).existsSync())
    .toList() as List<String>;
final subProjects = getSubProjects();

main(List<String> args) => grind(args);

@Task('Run analyzer')
analyze() => analyzeTask();

@Task('Runn all tests')
test() => testTask(['vm', 'content-shell']);
// TODO(zoechi) fix to support other browsers
//'dartium', 'chrome', 'phantomjs', 'firefox'

@Task('Run all VM tests')
testVm() => testTask(['vm']);

@Task('Run all browser tests')
testWeb() => testTask(['content-shell']);

@DefaultTask('Check everything')
@Depends(analyze, checkFormat, lint, test)
check() => checkTask();

@Task('Check source code format')
checkFormat() => checkFormatTask(existingSourceDirs);

/// format-all - fix all formatting issues
@Task('Fix all source format issues')
format() => formatTask();

@Task('Run lint checks')
lint() => lintTask();

@Depends(travisPrepare, check, coverage)
@Task('Travis')
travis() => travisTask();

@Task('Gather and send coverage data.')
coverage() => coverageTask();

@Task('Set up Travis prerequisites')
travisPrepare() => travisPrepareTask();

Function analyzeTask = analyzeTaskImpl;

/// Set to `true` to not fail the `analyze` task on info level analyzer messages.
bool analyzerIgnoreInfoMessages = false;

analyzeTaskImpl() {
  final args = <String>['check'];
  if (analyzerIgnoreInfoMessages) {
    args.add('--ignore-infos');
  }
  new PubApp.global('tuneup').run(args);
}

Function checkTask = checkTaskImpl;

checkTaskImpl() {
  run('pub', arguments: ['publish', '-n']);
  checkSubProjects();
}

Function coverageTask = coverageTaskImpl;

coverageTaskImpl() {
  final String coverageToken = io.Platform.environment['REPO_TOKEN'];

  if (coverageToken != null) {
    new PubApp.global('dart_coveralls').run(
        ['report', '--retry', '2', '--exclude-test-files', 'test/all.dart']);
  } else {
    log('Skipping coverage task: no environment variable `REPO_TOKEN` found.');
  }
}

Function formatTask = formatTaskImpl;

formatTaskImpl() => new PubApp.global('dart_style').run(
    (['-w']..addAll(existingSourceDirs)) as List<String>,
    script: 'format');

Function lintTask = lintTaskImpl;

lintTaskImpl() => new PubApp.global('linter').run(([
      '--stats',
      '-ctool/lintcfg.yaml'
    ]..addAll(existingSourceDirs)) as List<String>);

Function testTask = testTaskImpl;

testTaskImpl(List<String> platforms,
    {bool runPubServe: false, bool runSelenium: false}) async {
//  final seleniumJar = io.Platform.environment['SELENIUM_JAR'];

  final environment = <String, String>{};
  if (platforms.contains('content-shell')) {
    environment['PATH'] =
        '${io.Platform.environment['PATH']}:${downloadsInstallPath}/content_shell';
  }

//  PubServe pubServe;
//  SeleniumStandaloneServer selenium;
//  final servers = <Future<RunProcess>>[];

  try {
//    if (runPubServe) {
//      pubServe = new PubServe();
//      log('start pub serve');
//      servers.add(pubServe.start(directories: const ['test']).then((_) {
//        pubServe.stdout.listen((e) => io.stdout.add(e));
//        pubServe.stderr.listen((e) => io.stderr.add(e));
//      }));
//    }
//    if (runSelenium) {
//      selenium = new SeleniumStandaloneServer();
//      log('start Selenium standalone server');
//      servers.add(selenium.start(seleniumJar, args: []).then((_) {
//        selenium.stdout.listen((e) => io.stdout.add(e));
//        selenium.stderr.listen((e) => io.stderr.add(e));
//      }));
//    }

//    await Future.wait(servers);

//    final args = [];
//    if (runPubServe) {
//      args.add('--pub-serve=${pubServe.directoryPorts['test']}');
//    }
    new PubApp.local('test').run(
        ([]..addAll(platforms.map((p) => '-p${p}'))) as List<String>,
        runOptions: new RunOptions(environment: environment));
  } finally {
//    if (pubServe != null) {
//      pubServe.stop();
//    }
//    if (selenium != null) {
//      selenium.stop();
//    }
  }
}

//  final chromeBin = '-Dwebdriver.chrome.bin=/usr/bin/google-chrome';
//  final chromeDriverBin = '-Dwebdriver.chrome.driver=/usr/local/apps/webdriver/chromedriver/2.15/chromedriver_linux64/chromedriver';

Function travisTask = () {};

Function travisPrepareTask = travisPrepareTaskImpl;

travisPrepareTaskImpl() async {
  log('travisPrepareTaskImpl');
  if (doInstallContentShell) {
    log('contentShell');
    new PubApp.global('bwu_dart_archive_downloader').run([
      'down',
      '-fcontent_shell',
      '-dcontent_shell',
      '-o${downloadsInstallPath}',
      '-adartium',
      '-e',
      '-t${downloadsInstallPath}',
    ], script: 'darc');
//    await installContentShell();
    log('contentShell done');
  }
  String pubVar = io.Platform.environment['PUB'];
  if (pubVar == 'DOWNGRADE') {
    log('downgrade');
    Pub.downgrade();
    log('downgrade done');
  } else if (pubVar == 'UPGRADE') {
    log('upgrade');
    Pub.upgrade();
    log('upgrade done');
  } else {
    // Travis by default runs `pub get`
  }
}

bool doInstallContentShell = true;
String downloadsInstallPath = '_install';
String get channelFromTravisDartVersion {
  final travisVersion = io.Platform.environment['TRAVIS_DART_VERSION'];
  if (travisVersion == 'dev') return 'dev/release';
  return 'stable/release';
}

typedef List<io.Directory> GetSubProjects();

GetSubProjects getSubProjects = getSubProjectsImpl;

List<io.Directory> getSubProjectsImpl() => io.Directory.current
    .listSync(recursive: true)
    .where((d) => d.path.endsWith('pubspec.yaml') &&
        d.parent.absolute.path != io.Directory.current.absolute.path)
    .map((d) => d.parent)
    .toList() as List<io.Directory>;

Function checkSubProjects = checkSubProjectsImpl;

void checkSubProjectsImpl() {
  subProjects.forEach((p) {
    log('=== check sub-project: ${p.path} ===');
    run('dart',
        arguments: ['-c', 'tool/grind.dart', 'check'],
        runOptions: new RunOptions(
            workingDirectory: p.path, includeParentEnvironment: true));
  });
}
