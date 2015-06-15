library bwu_grinder_tasks.tool.grind;

export 'package:bwu_grinder_tasks/bwu_grinder_tasks.dart' hide main;
import 'package:bwu_grinder_tasks/bwu_grinder_tasks.dart'
    show grind, analyzerIgnoreInfoMessages;

main(args) {
  // TODO(zoech) remove when deprecated `analyzer_task` and `dartformat_task` are removed
  analyzerIgnoreInfoMessages = true;
  grind(args);
}
