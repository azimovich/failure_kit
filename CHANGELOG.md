## 1.1.0

### Fixed

- `Either` equality now correctly distinguishes `Left` and `Right` with the same value (`Left(42) != Right(42)`)
- `Either.==` uses typed generic check — cross-type comparison no longer gives false positives
- `DioErrorHandler` now correctly maps `DioException(error: SocketException)` to `NoInternetFailure`
- `DioExceptionType.badCertificate` no longer falls through to `ServerFailure`

### Changed

- `Either.left`/`Either.right` now throw `StateError` instead of `Exception` on illegal access

### Added

- `Either.rightOrNull` — returns right value or null if Left
- `Either.leftOrNull` — returns left value or null if Right
- `Failure` base class now implements `==` and `hashCode`
- `ServerFailure` overrides `==` and `hashCode` including `statusCode`

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
