## 2.0.0

### Breaking Changes

- `Failure` is no longer `sealed` — it is now `abstract`. User-defined subclasses are now supported outside the package.
- `when()` requires a new `custom:` parameter — handles any user-defined `Failure` subclass. Update all existing `when()` calls.
- `ErrorMapper` typedef now returns `Failure?` (was `Failure`). Return `null` to pass the error to the next mapper in the chain.
- `RepositoryHandler.errorMapper` getter removed — replaced by `errorMapperChain` (`ErrorMapperChain`).
- `ErrorHandler` class renamed to `BaseErrorMapper`. Update all direct usages.
- `DioErrorHandler` class renamed to `DioErrorMapper`. Update all direct usages.
- File `lib/src/error_handler.dart` replaced by `lib/src/error_mapper.dart`.
- File `lib/src/dio_error_handler.dart` replaced by `lib/src/dio_error_mapper.dart`.

### Migration Guide

```dart
// Before
ErrorMapper get errorMapper => DioErrorHandler.handle;

// After
ErrorMapperChain get errorMapperChain =>
    ErrorMapperChain.base.prepend(DioErrorMapper.handle);

// Before
ErrorHandler.handle(error, st)

// After
BaseErrorMapper.handle(error, st)

// Before
failure.when(server: ..., network: ..., unknown: ...)

// After — add custom: case
failure.when(server: ..., network: ..., unknown: ..., custom: (f) => ...)
```

### Added

- `ErrorMapperChain` — interceptor-style chain of `ErrorMapper`s. First non-null result wins; falls back to `BaseErrorMapper`.
- `ErrorMapperChain.prepend(mapper)` — add mapper at the front of the chain.
- `ErrorMapperChain.append(mapper)` — add mapper at the end of the chain.
- `ErrorMapperChain.base` — empty chain using only `BaseErrorMapper`.
- `ErrorMapperChain.of(mapper)` — single-mapper chain.
- `Failure.when(custom:)` — handles any user-defined `Failure` subclass via wildcard case.
- `DioErrorMapper` — Dio-specific mapper conforming to nullable `ErrorMapper` signature.
- `BaseErrorMapper` — renamed from `ErrorHandler`; handles standard Dart exceptions as final fallback.

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
