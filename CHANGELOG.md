# Changelog

## 1.1.0

### Features

- `FutureEither` extension on `Future<Either<L, R>>` — chain without intermediate `await`s: `mapRight`, `mapLeft`, `thenRight`, `thenLeft`, `fold`, `getOrElse`.
- `Either.onLeft` / `Either.onRight` — side-effect taps (e.g. logging) that return the same `Either`, keeping the chain intact.
- `Either.tryCatchAsync` — async version of `Either.tryCatch`.
- `FailureGuard.callSync` — synchronous counterpart of `call(...)` for parsing, local computation, and cache reads. Uses the same `failureChain`.
- `Left` / `Right` now implement `toString` (`Right(42)`, `Left(error)`) for readable logs and test output.

### Internal

- `Either` methods are now implemented once in the sealed base class via Dart 3 switch expressions instead of per-subclass overrides. No public API changes.
- Documented that `ServerFailure` equality intentionally ignores `data`, `cause`, and `stackTrace`.

## 1.0.0

Initial pub.dev release.

### Features

- `Either<L, R>` — sealed `Left` / `Right` with `map`, `mapAsync`, `then`, `thenAsync`, `fold`, `getOrElse`, `swap`, `tryCatch`, `tryExcept`, `cond`, `condLazy`.
- `Failure` — abstract base class. User-defined subclasses are first-class citizens (route to `when(custom:)`).
- Built-in failure types: `ServerFailure` (with `statusCode` and raw `data`), `NoInternetFailure`, `TimeoutFailure`, `CancellationFailure`, `ParsingFailure`, `UnknownFailure`.
- `FailureMapper` typedef — `Failure? Function(Object, StackTrace)`. Return `null` to delegate to the next mapper in the chain.
- `FailureMapperChain` — interceptor-style chain. First non-null result wins. Falls back to `BaseFailureMapper`.
- `FailureGuard` mixin — wraps async actions in `Either<Failure, T>` via `call(...)`.

### Notes

- Package is HTTP-client agnostic and has no `dio` dependency. See `example/dio_integration.dart` for a copy-paste Dio mapper.
