library bwu_grinder_tasks.src.pub_serve;

import 'dart:async' show Future, Stream, StreamController;
import 'dart:io' as io;

/// An interface for managing shell processes.
abstract class RunProcess {
  /// The stdout stream of the running process.
  Stream<List<int>> get stdout;

  /// The stderr stream of the running process.
  Stream<List<int>> get stderr;

  /// End the process if it is still running and return the exit code.
  bool stop();

  /// Get the exit code the process ended with.
  Future<int> get exitCode;
}

/// Start and end a new `pub serve` instance.
// TODO(zoechi) see also bwu_utils_dev which has a similar implementation
class PubServe implements RunProcess {
  final StreamController<List<int>> _stdout = StreamController<List<int>>();
  final StreamController<List<int>> _stderr = StreamController<List<int>>();

  @override
  Stream<List<int>> get stdout => _stdout.stream;
  @override
  Stream<List<int>> get stderr => _stderr.stream;

  io.Process _process;

  /// Create and run a `pub serve` instance.
  Future<Null> start({List<String> directories}) async {
    _process = await io.Process.start('pub', ['serve']..addAll(directories));
    // ignore: unawaited_futures
    _stdout.addStream(_process.stdout);
    // ignore: unawaited_futures
    _stderr.addStream(_process.stderr);
  }

  /// End the `pub serve` instance.
  @override
  bool stop([io.ProcessSignal signal = io.ProcessSignal.sigterm]) {
    if (_process != null) {
      return _process.kill(signal ?? io.ProcessSignal.sigterm);
    }

    return false;
  }

  /// Get the exit code the `pub serve` instance ended with.
  @override
  Future<int> get exitCode => _process.exitCode;
}
