# Changelog

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
