library bwu_grinder_tasks.src.analyzer_task;

import 'dart:io' as io;
import 'package:grinder/grinder.dart';

/// Run the analyzer on all `*.dart` files
@Deprecated('should be provided by the Grinder package itself soon.')
void analyzerTask(
    {List<String> files = const [], List<String> directories = const []}) {
  final _files = files.toList();
  for (final dir in directories) {
    _files.addAll(
        FileSet.fromDir(io.Directory(dir), pattern: '*.dart', recurse: true)
            .files
            .map((f) => f.absolute.path));
  }

  Analyzer.analyze(_files, fatalWarnings: true);
}
