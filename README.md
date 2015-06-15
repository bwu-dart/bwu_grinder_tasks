# BWU Grinder Tasks


[![Star this Repo](https://img.shields.io/github/stars/bwu-dart/bwu_grinder_tasks.svg?style=flat)](https://github.com/bwu-dart/bwu_grinder_tasks)
[![Pub Package](https://img.shields.io/pub/v/bwu_grinder_tasks.svg?style=flat)](https://pub.dartlang.org/packages/bwu_grinder_tasks)
[![Build Status](https://travis-ci.org/bwu-dart/bwu_grinder_tasks.svg?branch=master)](https://travis-ci.org/bwu-dart/bwu_grinder_tasks)
[![Coverage Status](https://coveralls.io/repos/bwu-dart/bwu_grinder_tasks/badge.svg?branch=master)](https://coveralls.io/r/bwu-dart/bwu_grinder_tasks)

A set of common reusable Grinder tasks.

## Usage

### Simplest case

Add a dependency to the packages `grinder` and `bwu_grinder_tasks` to your
dependencies in `pubspec.yaml` and add the file `tool/grind.dart` with the 
following content to your project:

```Dart
export 'package:bwu_grinder_tasks/bwu_grinder_tasks.dart';
```

Then you can run it from your project root directory with
```sh
grind
# or
grind check
# or
grind format
# ...
```

### Customize (hide tasks)

If you just want to use a few of the tasks but not all you can hide tasks
you don't want to use and also add your own tasks. The following example 
suppresses browser tests. 
If you want to customize the tasks, you always need to implement your own 
`main()` method (and hide the provided `main()`).   

```Dart
library bwu_dart_archive_downloader.tool.grind;

export 'package:bwu_utils_dev/grinder/default_tasks.dart' hide main, lint, check, 
    travis;
import 'package:bwu_utils_dev/grinder/default_tasks.dart' show grind;

main(List<String> args) {
  grind(args);
}

@Task('some task')
some() => print('did something');

```

What doesn't work is to hide a task which is a dependency for another task. You 
also need to hide the task which depends on the task you want to hide.
In the example above we hide the `lint` task and also need to hide `check` and
`travis` which depend on `lint`.

### Customize (provide custom implementation)
 
Instead of hiding and reimplementing a task you can just assign a custom 
implementation to a task.

The provided tasks are split in three parts.
- The delaration with the `@Task()`, `@DefaultTask` and `@Depends()` annotation,
- A variable which is referenced by a task and itself references the 
implementation of the task.
- The implementation of a task 

```
@Task('Run lint checks')
lint() => lintTask();
Function lintTask = lintTaskImpl;
lintTaskImpl() => new PubApp.global('linter')
    .run(['--stats', '-ctool/lintcfg.yaml']..addAll(existingSourceDirs));
```

If you want to change or extend the behavior of the lint task you can do this 
like:

```Dart
library bwu_dart_archive_downloader.tool.grind;

export 'package:bwu_utils_dev/grinder/default_tasks.dart' hide main;
import 'package:bwu_utils_dev/grinder/default_tasks.dart'
    show grind, lintTask, lintTaskImpl;

main(List<String> args) {
  lintTask = () {
    print('before linting');
    testTaskImpl(['vm']);
    print('after linting');
  grind(args);
}

```
