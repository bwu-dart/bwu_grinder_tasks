library bwu_grinder_tasks;

///
/// Examples
///
/// **default**
///
///     export 'package:bwu_grinder_tasks/bwu_grinder_tasks.dart';
///
/// **Run pub serve**
///
///     export 'package:bwu_grinder_tasks/bwu_grinder_tasks.dart' hide main, test;
///     import 'package:bwu_grinder_tasks/bwu_grinder_tasks.dart'
///         show testTask, testTaskImpl, grind;
///
///     ///
///     void main([List<String> args]) {
///       testTask = () =>
///           testTaskImpl('grinder', runPubServe: true, pubServeParameters: ['test']);
///       grind(args);
///     }
///

import 'dart:io' as io;
import 'package:grinder/grinder.dart'
    show
        Analyzer,
        DefaultTask,
        Depends,
        Pub,
        PubApp,
        RunOptions,
        Task,
        existingSourceDirs,
        grind,
        log,
        run;
export 'package:grinder/grinder.dart' show DefaultTask, Depends, grind, Task;
import 'src/dartformat_task.dart' show checkFormatTask;
import 'package:bwu_grinder_tasks/src/pub_serve.dart' show PubServe;

// TODO(zoechi) check if version was incremented
// TODO(zoechi) check if CHANGELOG.md contains version

//@Task('Delete build directory')
//void clean() => defaultClean(context);

/// Configure what sub-projects to check. By default [getSubProjects]` will be
/// run to discover sub-projects automatically.
final List<io.Directory> subProjects = getSubProjects();

///
dynamic main(List<String> args) => grind(args);

///
@Task('Run analyzer')
dynamic analyze() => analyzeTask();

///
@Task('Runn all tests')
dynamic test() => testTask('grinder' /*['vm', 'content-shell']*/);
// TODO(zoechi) fix to support other browsers
//'dartium', 'chrome', 'phantomjs', 'firefox'

///
@Task('Run all VM tests')
dynamic testVm() => testTask(['vm']);

///
@Task('Run all browser tests')
dynamic testWeb() => testTask(['content-shell']);

///
@DefaultTask('Check everything')
@Depends(analyze, checkFormat, test)
dynamic check() => checkTask();

///
@Task('Check source code format')
dynamic checkFormat() =>
    checkFormatTask(existingSourceDirs.map((dir) => dir.path));

///
@Task('Fix all source format issues')
dynamic format() => formatTask();

///
@Task('Run lint checks')
@Deprecated('Linter rules are checked in the analyze task already')
dynamic lint() => lintTask();

///
@Depends(travisPrepare, check, coverage)
@Task('Travis')
dynamic travis() => travisTask();

///
@Task('Gather and send coverage data.')
dynamic coverage() => coverageTask();

///
@Task('Set up Travis prerequisites')
dynamic travisPrepare() => travisPrepareTask();

/// Function to be run for the [analyze] task.
Function analyzeTask = analyzeTaskImpl;

/// Set to `true` to not fail the `analyze` task on info level analyzer messages.
bool analyzerIgnoreInfoMessages = false;

/// Default implementation for the [analyze] task.
void analyzeTaskImpl() {
  Analyzer.analyze(existingSourceDirs, fatalWarnings: false);
}

/// Function to be run for the [check] task.
Function checkTask = checkTaskImpl;

/// Default implementation for the [check] task.
void checkTaskImpl() {
  run('pub', arguments: ['publish', '-n']);
  checkSubProjects();
}

/// Function to be run for the [coverage] task.
Function coverageTask = coverageTaskImpl;

/// Default implementation for the [coverage] task.
void coverageTaskImpl() {
  final String coverageToken = io.Platform.environment['REPO_TOKEN'];

  if (coverageToken != null) {
    new PubApp.global('dart_coveralls').run(
        ['report', '--retry', '2', '--exclude-test-files', 'test/all.dart']);
  } else {
    log('Skipping coverage task: no environment variable `REPO_TOKEN` found.');
  }
}

/// Indirection that allows a custom function to be assigned for the `format`
/// task.
Function formatTask = formatTaskImpl;

/// Default implementation for the `format` task.
void formatTaskImpl() {
  new PubApp.global('dart_style').run(
      ['-w']..addAll(existingSourceDirs.map((dir) => dir.path)),
      script: 'format');
}

/// Indirection that allows a custom function to be assigned for the `lint` task.
@Deprecated('Linter rules are checked in the analyze task already')
// ignore: deprecated_member_use
Function lintTask = lintTaskImpl;

/// Default implementation for the `lint` task.
@Deprecated('Linter rules are checked in the analyze task already')
String lintTaskImpl() {
  return new PubApp.global('linter').run((['--stats', '-ctool/lintcfg.yaml']
    ..addAll(existingSourceDirs.map((dir) => dir.path))));
}

/// Indirection that allows a custom function to be assigned for the `test` task.
Function testTask = testTaskImpl;

/// Default implementation for the `test` task.
dynamic testTaskImpl(String preset,
    {bool runPubServe: false,
    List<String> pubServeParameters: const <String>[],
    bool runSelenium: false}) async {
//  final seleniumJar = io.Platform.environment['SELENIUM_JAR'];

  final environment = <String, String>{};
//  if (platforms.contains('content-shell')) {
  environment['PATH'] =
      '${io.Platform.environment['PATH']}:$downloadsInstallPath/content_shell';
//  }

//  SeleniumStandaloneServer selenium;
//  final servers = <Future<RunProcess>>[];

  PubServe pubServe;
  try {
    if (runPubServe) {
      pubServe = new PubServe();
      log('start pub serve');
      await pubServe.start(directories: const ['test']);
      // ignore: unawaited_futures
      io.stdout.addStream(pubServe.stdout);
      // ignore: unawaited_futures
      io.stderr.addStream(pubServe.stderr);
    }
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
    new PubApp.local('test').run(['--preset', preset],
        runOptions: new RunOptions(environment: environment));
  } finally {
    if (pubServe != null) {
      pubServe.stop();
    }
//    if (selenium != null) {
//      selenium.stop();
//    }
  }
}

//  final chromeBin = '-Dwebdriver.chrome.bin=/usr/bin/google-chrome';
//  final chromeDriverBin = '-Dwebdriver.chrome.driver=/usr/local/apps/webdriver/chromedriver/2.15/chromedriver_linux64/chromedriver';

/// Indirection that allows a custom function to be assigned for the `travis`
/// task.
// The default implementation does nothing.
Function travisTask = () {};

/// Indirection that allows a custom function to be assigned for the
/// `travisPrepare` task.
Function travisPrepareTask = travisPrepareTaskImpl;

/// Default implementation for the `travisPrepare` task.
dynamic travisPrepareTaskImpl() async {
  log('travisPrepareTaskImpl');
  if (doInstallContentShell) {
    log('contentShell');
    new PubApp.global('bwu_dart_archive_downloader').run([
      'down',
      '-fcontent_shell',
      '-dcontent_shell',
      '-o$downloadsInstallPath',
      '-adartium',
      '-e',
      '-t$downloadsInstallPath',
    ], script: 'darc');
//    await installContentShell();
    log('contentShell done');
  }
  final pubVar = io.Platform.environment['PUB'];
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

/// Configuration setting whether content-shell should be installed.
bool doInstallContentShell = true;

/// Configuration setting where to install additional tools.
String downloadsInstallPath = '_install';

/// Helper that returns the correct download channel from the Dart version.
String get channelFromTravisDartVersion {
  final travisVersion = io.Platform.environment['TRAVIS_DART_VERSION'];
  if (travisVersion == 'dev') return 'dev/release';
  return 'stable/release';
}

/// Typedef for the function that discovers sub-projects.
typedef List<io.Directory> GetSubProjects();

/// Configure the function used to discover sub-projects.
GetSubProjects getSubProjects = getSubProjectsImpl;

/// Default implementation for `getSubProjects`
List<io.Directory> getSubProjectsImpl() => io.Directory.current
    .listSync(recursive: true)
    .where((d) =>
        d.path.endsWith('pubspec.yaml') &&
        d.parent.absolute.path != io.Directory.current.absolute.path)
    .map((d) => d.parent)
    .toList();

/// Configure the function used to check sub-projects.
Function checkSubProjects = checkSubProjectsImpl;

/// Default implementation for `checkSubProjects.
void checkSubProjectsImpl() {
  subProjects.forEach((p) {
    log('=== check sub-project: ${p.path} ===');
    run('dart',
        arguments: ['-c', 'tool/grind.dart', 'check'],
        runOptions: new RunOptions(
            workingDirectory: p.path, includeParentEnvironment: true));
  });
}
