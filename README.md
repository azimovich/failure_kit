# dart_failure_handler

A professional, HTTP-client agnostic error handling package for Dart/Flutter applications with optional [Dio](https://pub.dev/packages/dio) support.

[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Features

- 🎯 **Type-safe error handling** with extensible `Failure` classes
- 🔄 **Either pattern** for functional error management (`Left` for failures, `Right` for success)
- 🔌 **HTTP-client agnostic** — works with Dio, http, Chopper, or any HTTP client
- 🌐 **Optional Dio support** via `package:dart_failure_handler/dio.dart`
- 🎨 **Pattern matching** with `when()` and `maybeWhen()` methods
- ⚡ **Async support** with `mapAsync()`, `thenAsync()` and more
- 🧩 **Interceptor-style error chain** — add your own mappers without touching the package

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  dart_failure_handler:
    git:
      url: https://github.com/azimovich/my_dart_failure_handler.git
      ref: version/2.0.0
```

## Quick Start

### Import

```dart
// Core (any HTTP client) — no Dio dependency in your code
import 'package:dart_failure_handler/dart_failure_handler.dart';

// OR with Dio support — includes everything from core + Dio handlers
import 'package:dart_failure_handler/dio.dart';
```

### Basic Repository (any HTTP client)

```dart
import 'package:dart_failure_handler/dart_failure_handler.dart';

class UserRepository with RepositoryHandler {
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

### Dio Repository (with Dio support)

**Method 1: Using `DioRepositoryHandler` mixin**

```dart
import 'package:dart_failure_handler/dio.dart';

class UserRepository with RepositoryHandler, DioRepositoryHandler {
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

**Method 2: Override `errorMapperChain`**

```dart
import 'package:dart_failure_handler/dio.dart';

class UserRepository with RepositoryHandler {
  final Dio _dio;
  UserRepository(this._dio);

  @override
  ErrorMapperChain get errorMapperChain =>
      ErrorMapperChain.base.prepend(DioErrorMapper.handle);

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
  orElse: (f) => f.message, // catches all unhandled types including custom
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
class DriftErrorMapper {
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
class UserLocalRepository with RepositoryHandler {
  @override
  ErrorMapperChain get errorMapperChain =>
      ErrorMapperChain.base.prepend(DriftErrorMapper.handle);

  Future<Either<Failure, User>> getUser(int id) =>
      call(() async => _dao.userById(id));
}
```

### Combining multiple mappers (Dio + Drift + custom)

```dart
class UserRepository with RepositoryHandler, DioRepositoryHandler {
  @override
  ErrorMapperChain get errorMapperChain => super.errorMapperChain
      .prepend(DriftErrorMapper.handle)   // local DB — checked first
      .prepend(AuthErrorMapper.handle);   // auth — checked before DB
}
```

Chain runs top to bottom. First non-null result wins. Falls back to `BaseErrorMapper` if all return null.

## Architecture

```text
┌─────────────────────────────────────────────────┐
│   dart_failure_handler.dart  (Core - no Dio)     │
│                                                   │
│   Either<L, R>    Failure (abstract)              │
│   Left / Right    ServerFailure                   │
│                   NoInternetFailure               │
│   BaseErrorMapper TimeoutFailure                  │
│   ErrorMapper     CancellationFailure             │
│   ErrorMapperChain ParsingFailure                 │
│                   UnknownFailure                  │
│   RepositoryHandler                               │
│   (pluggable errorMapperChain)                    │
└─────────────────────────────────────────────────┘
                       │
                       │ extends
                       ▼
┌─────────────────────────────────────────────────┐
│          dio.dart  (Dio support)                  │
│                                                   │
│   DioErrorMapper      DioRepositoryHandler        │
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
