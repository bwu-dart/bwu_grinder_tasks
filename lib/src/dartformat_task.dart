library bwu_grinder_tasks.src.dartformat_task;

import 'package:grinder/grinder.dart';

/// Check whether all *.dart files in the given directories and their sub-
/// directories are properly formatted.
void checkFormatTask(Iterable<String> directories) {
  final output = new PubApp.global('dart_style')
      .run((['--dry-run']..addAll(directories)), script: 'format');
  if (output.split('\n').where((l) => l.isNotEmpty).length > 0) {
    context.fail('Some files are not properly formatted.');
  }
}
