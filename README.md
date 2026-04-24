# failure_kit

HTTP-client agnostic error handling for Dart/Flutter — Either pattern, typed Failures, pluggable mapper chain, and optional [Dio](https://pub.dev/packages/dio) support.

[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Features

- 🎯 **Type-safe error handling** with extensible `Failure` classes
- 🔄 **Either pattern** for functional error management (`Left` for failures, `Right` for success)
- 🔌 **HTTP-client agnostic** — works with Dio, http, Chopper, or any HTTP client
- 🌐 **Optional Dio support** via `package:failure_kit/dio.dart`
- 🎨 **Pattern matching** with `when()` and `maybeWhen()` methods
- ⚡ **Async support** with `mapAsync()`, `thenAsync()` and more
- 🧩 **Interceptor-style mapper chain** — add your own mappers without touching the package

## Installation

```yaml
dependencies:
  failure_kit:
    git:
      url: https://github.com/azimovich/failure_kit.git
      ref: version/3.0.0
```

## Quick Start

### Import

```dart
// Core (any HTTP client) — no Dio dependency in your code
import 'package:failure_kit/failure_kit.dart';

// OR with Dio support — includes everything from core + Dio handlers
import 'package:failure_kit/dio.dart';
```

### Basic usage (any HTTP client)

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

### Dio usage

**Method 1: `DioFailureGuard` mixin**

```dart
import 'package:failure_kit/dio.dart';

class UserRepository with FailureGuard, DioFailureGuard {
  final Dio _dio;
  UserRepository(this._dio);

  Future<Either<Failure, User>> getUser(int id) {
    return call(() async {
      final response = await _dio.get('/users/$id');
      return User.fromJson(response.data);
    });
  }
}
```

**Method 2: Override `failureChain`**

```dart
import 'package:failure_kit/dio.dart';

class UserRepository with FailureGuard {
  final Dio _dio;
  UserRepository(this._dio);

  @override
  FailureMapperChain get failureChain =>
      FailureMapperChain.base.prepend(DioFailureMapper.handle);

  Future<Either<Failure, User>> getUser(int id) {
    return call(() async {
      final response = await _dio.get('/users/$id');
      return User.fromJson(response.data);
    });
  }
}
```

### Handling Results

```dart
final result = await userRepository.getUser(1);

// Option 1: fold
result.fold(
  (failure) => showError(failure.message),
  (user) => showUser(user),
);

// Option 2: Pattern matching with when()
result.fold(
  (failure) => failure.when(
    server: (f) => showError('Server error: ${f.statusCode}'),
    network: (_) => showError('No internet'),
    timeout: (_) => showError('Request timed out'),
    cancellation: (_) => showError('Cancelled'),
    parsing: (_) => showError('Data error'),
    unknown: (f) => showError(f.message),
    custom: (f) => showError(f.message), // user-defined Failure subclasses
  ),
  (user) => showUser(user),
);

// Option 3: maybeWhen (only handle what you need)
final message = failure.maybeWhen(
  server: (f) => 'Error ${f.statusCode}',
  network: (_) => 'Check your connection',
  orElse: (f) => f.message,
);

// Option 4: getOrElse
final userName = result
    .map((user) => user.name)
    .getOrElse('Anonymous');
```

## Custom Error Mapping

### Adding your own Failure type

```dart
// In your project — no changes to the package needed
class DatabaseFailure extends Failure {
  const DatabaseFailure({
    super.message = 'Database error',
    super.cause,
    super.stackTrace,
  });
}
```

### Writing a custom mapper

A mapper returns `Failure?` — return `null` to pass the error to the next mapper in the chain:

```dart
class DriftFailureMapper {
  static Failure? handle(Object error, StackTrace st) {
    if (error is InvalidDataException) {
      return DatabaseFailure(message: error.message, cause: error, stackTrace: st);
    }
    if (error is SqliteException) {
      return DatabaseFailure(message: error.message, cause: error, stackTrace: st);
    }
    return null; // not mine — pass to next mapper
  }
}
```

### Registering the mapper via chain

```dart
class UserLocalRepository with FailureGuard {
  @override
  FailureMapperChain get failureChain =>
      FailureMapperChain.base.prepend(DriftFailureMapper.handle);

  Future<Either<Failure, User>> getUser(int id) =>
      call(() async => _dao.userById(id));
}
```

### Combining multiple mappers (Dio + Drift + custom)

```dart
class UserRepository with FailureGuard, DioFailureGuard {
  @override
  FailureMapperChain get failureChain => super.failureChain
      .prepend(DriftFailureMapper.handle)   // local DB — checked first
      .prepend(AuthFailureMapper.handle);   // auth — checked before DB
}
```

Chain runs top to bottom. First non-null result wins. Falls back to `BaseFailureMapper` if all return null.

## Architecture

```text
┌─────────────────────────────────────────────────┐
│   failure_kit.dart  (Core - no Dio)              │
│                                                   │
│   Either<L, R>    Failure (abstract)              │
│   Left / Right    ServerFailure                   │
│                   NoInternetFailure               │
│   BaseFailureMapper  TimeoutFailure               │
│   FailureMapper      CancellationFailure          │
│   FailureMapperChain ParsingFailure               │
│                   UnknownFailure                  │
│   FailureGuard                                    │
│   (pluggable failureChain)                        │
└─────────────────────────────────────────────────┘
                       │
                       │ extends
                       ▼
┌─────────────────────────────────────────────────┐
│          dio.dart  (Dio support)                  │
│                                                   │
│   DioFailureMapper    DioFailureGuard             │
│   (returns null for non-Dio errors)               │
│   (delegates to chain for everything else)        │
└─────────────────────────────────────────────────┘
```

## Failure Types

| Failure               | Description                 | Common Triggers                 |
| --------------------- | --------------------------- | ------------------------------- |
| `ServerFailure`       | Server/API errors           | HTTP 4xx/5xx responses          |
| `NoInternetFailure`   | Network connectivity issues | No connection, SocketException  |
| `TimeoutFailure`      | Request timeout             | Connection/Send/Receive timeout |
| `CancellationFailure` | Cancelled requests          | User cancelled, CancelToken     |
| `ParsingFailure`      | Data parsing errors         | JSON parse errors, TypeError    |
| `UnknownFailure`      | Unexpected errors           | Any other exception             |
| Your custom type      | Any domain-specific error   | Drift, Hive, GraphQL, etc.      |

`ServerFailure` also carries a `data` field (`Object?`) with the raw response body for domain-specific field extraction:

```dart
final data = serverFailure.data as Map?;
final errorKey = data?['error.key'] as String?;
```

## Either API Reference

### Properties

| Property      | Type   | Description                       |
| ------------- | ------ | --------------------------------- |
| `isLeft`      | `bool` | Returns true if this is a `Left`  |
| `isRight`     | `bool` | Returns true if this is a `Right` |
| `left`        | `L`    | Gets left value (throws if Right) |
| `right`       | `R`    | Gets right value (throws if Left) |
| `leftOrNull`  | `L?`   | Left value or null                |
| `rightOrNull` | `R?`   | Right value or null               |

### Methods

| Method                   | Return Type             | Description                    |
| ------------------------ | ----------------------- | ------------------------------ |
| `fold(fnL, fnR)`         | `T`                     | Pattern match on Left/Right    |
| `map(fn)`                | `Either<L, TR>`         | Transform Right value          |
| `mapLeft(fn)`            | `Either<TL, R>`         | Transform Left value           |
| `mapAsync(fn)`           | `Future<Either<L, TR>>` | Async transform Right          |
| `then(fn)`               | `Either<L, TR>`         | Chain another Either           |
| `thenAsync(fn)`          | `Future<Either<L, TR>>` | Async chain                    |
| `getOrElse(default)`     | `R`                     | Get Right or default           |
| `getOrElseCompute(fn)`   | `R`                     | Get Right or compute from Left |
| `getLeftOrElse(default)` | `L`                     | Get Left or default            |
| `swap()`                 | `Either<R, L>`          | Swap Left and Right            |

### Static Methods

| Method                               | Description                          |
| ------------------------------------ | ------------------------------------ |
| `Either.tryCatch(onError, fn)`       | Catch exceptions and convert to Left |
| `Either.tryExcept<E, R>(fn)`         | Simplified tryCatch                  |
| `Either.cond(test, left, right)`     | Create based on condition            |
| `Either.condLazy(test, left, right)` | Lazy version of cond                 |

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
