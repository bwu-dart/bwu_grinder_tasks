# Changelog

## 0.1.1
- add `writeVersionInfoFile` task to create a `lib/src/version_info.dart` file providing the package version as constant.
- add `runPubServe` option to the `test` task implementation that runs a `pub serve` instance when `true` is passed.
- the `analyze` task now uses Grinders `Analyzer.analyze()` instead of running `tuneup`.
- the `test` task doesn't use `vm` and `content-shell` as default anymore. Use `dart_test.yaml` instead to configure
  which tests to run. See https://github.com/dart-lang/test/blob/master/doc/configuration.md for details.
- update to Grinder 0.8.0
- fix strong-mode warnings

## 0.1.0

- move Grinder tasks from bwu_utils_dev
- remove direct dependency on bwu_archive_downloader and use `pub global run`
instead.
