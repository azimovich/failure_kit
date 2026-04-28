# failure_kit

HTTP-client agnostic error handling for Dart/Flutter — `Either` pattern, typed `Failure`s, and a pluggable mapper chain.

[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Features

- 🎯 Type-safe error handling with extensible `Failure` classes
- 🔄 `Either` pattern (`Left` for failures, `Right` for success)
- 🔌 Works with any HTTP client — Dio, `http`, Chopper, GraphQL, Drift, Hive, anything
- 🎨 Pattern matching via `when()` and `maybeWhen()`
- ⚡ Async support — `mapAsync`, `thenAsync`, and friends
- 🧩 Interceptor-style mapper chain — plug in your own mappers without touching the package
- 📦 Zero runtime dependencies beyond `meta`

## Installation

```yaml
dependencies:
  failure_kit: ^1.0.0
```

## Quick start

```dart
import 'package:failure_kit/failure_kit.dart';

class UserRepository with FailureGuard {
  final MyHttpClient _client;
  UserRepository(this._client);

  Future<Either<Failure, User>> getUser(int id) {
    return call(() async {
      final response = await _client.get('/users/$id');
      return User.fromJson(response.body);
    });
  }
}
```

`call(...)` runs the action, catches any exception, and returns a `Left(Failure)` or `Right(value)`.

## Handling results

```dart
final result = await userRepository.getUser(1);

// fold
result.fold(
  (failure) => showError(failure.message),
  (user) => showUser(user),
);

// when() — exhaustive pattern matching
result.fold(
  (failure) => failure.when(
    server: (f) => showError('Server ${f.statusCode}'),
    network: (_) => showError('No internet'),
    timeout: (_) => showError('Timed out'),
    cancellation: (_) => showError('Cancelled'),
    parsing: (_) => showError('Bad data'),
    unknown: (f) => showError(f.message),
    custom: (f) => showError(f.message), // your subclasses land here
  ),
  (user) => showUser(user),
);

// maybeWhen() — handle only what you care about
final msg = failure.maybeWhen(
  server: (f) => 'Error ${f.statusCode}',
  network: (_) => 'Check your connection',
  orElse: (f) => f.message,
);

// getOrElse
final name = result.map((u) => u.name).getOrElse('Anonymous');
```

## Custom Failure types

Add your own `Failure` subclass — no package changes required:

```dart
class DatabaseFailure extends Failure {
  const DatabaseFailure({
    super.message = 'Database error',
    super.cause,
    super.stackTrace,
  });
}
```

It routes to `when(custom:)` automatically.

## Custom mapper chain

A `FailureMapper` returns `Failure?` — return `null` to pass to the next mapper:

```dart
class DriftFailureMapper {
  static Failure? handle(Object error, StackTrace st) {
    if (error is InvalidDataException) {
      return DatabaseFailure(message: error.message, cause: error, stackTrace: st);
    }
    return null;
  }
}

class UserLocalRepository with FailureGuard {
  @override
  FailureMapperChain get failureChain =>
      FailureMapperChain.base.prepend(DriftFailureMapper.handle);

  Future<Either<Failure, User>> getUser(int id) =>
      call(() async => _dao.userById(id));
}
```

Multiple mappers compose:

```dart
@override
FailureMapperChain get failureChain => FailureMapperChain.base
    .prepend(DriftFailureMapper.handle)
    .prepend(AuthFailureMapper.handle);
```

Chain runs top to bottom. First non-null result wins. Falls back to `BaseFailureMapper`.

## Dio integration

`failure_kit` does **not** ship with Dio support — keeping the core dependency-free lets you choose your own Dio version and avoids version conflicts.

A complete copy-paste mapper for Dio lives in [`example/dio_integration.dart`](example/dio_integration.dart). Drop it into your project under `lib/core/` (or wherever you keep cross-cutting code) and use it like this:

```dart
import 'package:failure_kit/failure_kit.dart';
import 'core/dio_failure_mapper.dart';

class UserRepository with FailureGuard {
  final Dio _dio;
  UserRepository(this._dio);

  @override
  FailureMapperChain get failureChain =>
      FailureMapperChain.base.prepend(DioFailureMapper.handle);

  Future<Either<Failure, User>> getUser(int id) => call(() async {
        final r = await _dio.get('/users/$id');
        return User.fromJson(r.data);
      });
}
```

The same pattern applies to any HTTP client — just write a mapper that handles its exception type.

## Failure types

| Failure               | Description                 | Common triggers                 |
| --------------------- | --------------------------- | ------------------------------- |
| `ServerFailure`       | Server/API errors           | HTTP 4xx/5xx responses          |
| `NoInternetFailure`   | Network connectivity issues | No connection, `SocketException`|
| `TimeoutFailure`      | Request timeout             | `TimeoutException`              |
| `CancellationFailure` | Cancelled requests          | User cancelled, cancel tokens   |
| `ParsingFailure`      | Data parsing errors         | JSON parse, `TypeError`         |
| `UnknownFailure`      | Unexpected errors           | Anything else                   |
| _Your subclass_       | Domain-specific             | DB, auth, GraphQL, etc.         |

`ServerFailure` carries a `data` field (`Object?`) with the raw response body for domain-specific extraction:

```dart
final data = serverFailure.data as Map?;
final errorKey = data?['error.key'] as String?;
```

## `Either` API reference

### Properties

| Property      | Type   | Description                       |
| ------------- | ------ | --------------------------------- |
| `isLeft`      | `bool` | True if this is a `Left`          |
| `isRight`     | `bool` | True if this is a `Right`         |
| `left`        | `L`    | Left value (throws if `Right`)    |
| `right`       | `R`    | Right value (throws if `Left`)    |
| `leftOrNull`  | `L?`   | Left value or `null`              |
| `rightOrNull` | `R?`   | Right value or `null`             |

### Methods

| Method                   | Return type             | Description                    |
| ------------------------ | ----------------------- | ------------------------------ |
| `fold(fnL, fnR)`         | `T`                     | Pattern match on Left/Right    |
| `map(fn)`                | `Either<L, TR>`         | Transform Right value          |
| `mapLeft(fn)`            | `Either<TL, R>`         | Transform Left value           |
| `mapAsync(fn)`           | `Future<Either<L, TR>>` | Async transform Right          |
| `then(fn)`               | `Either<L, TR>`         | Chain another `Either`         |
| `thenAsync(fn)`          | `Future<Either<L, TR>>` | Async chain                    |
| `getOrElse(default)`     | `R`                     | Get Right or default           |
| `getOrElseCompute(fn)`   | `R`                     | Get Right or compute from Left |
| `getLeftOrElse(default)` | `L`                     | Get Left or default            |
| `swap()`                 | `Either<R, L>`          | Swap Left and Right            |

### Static methods

| Method                               | Description                          |
| ------------------------------------ | ------------------------------------ |
| `Either.tryCatch(onError, fn)`       | Catch exceptions, convert to Left    |
| `Either.tryExcept<E, R>(fn)`         | Simplified `tryCatch`                |
| `Either.cond(test, left, right)`     | Build from a condition               |
| `Either.condLazy(test, left, right)` | Lazy version of `cond`               |

## License

MIT — see [LICENSE](LICENSE).
