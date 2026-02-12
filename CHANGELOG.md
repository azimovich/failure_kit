## 1.0.2

- Made package HTTP-client agnostic - core works without Dio
- Separated Dio-specific handling into `package:dart_failure_handler/dio.dart`
- Core `ErrorHandler` now handles only standard Dart exceptions
- Added `DioErrorHandler` for Dio-specific error mapping
- Added `DioRepositoryHandler` convenience mixin
- Made `RepositoryHandler` configurable via `errorMapper` getter
- Added `ErrorMapper` typedef for custom error mapping functions
- Updated documentation and examples

## 1.0.1

- Added `TimeoutFailure` and `CancellationFailure` failure types
- Added `maybeWhen()` for optional pattern matching
- Added `getOrElse()`, `getOrElseCompute()`, `getLeftOrElse()` to Either
- Added `toString()` override for Failure classes
- Added comprehensive unit tests
- Added LICENSE file
- Fixed `unnecessary_this` lint warnings
- Updated documentation

## 1.0.0

- Initial version.
