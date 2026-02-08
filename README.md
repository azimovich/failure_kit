# dart_failure_handler

A professional, type-safe error handling package for Dart/Flutter applications using [Dio](https://pub.dev/packages/dio).

[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Features

- 🎯 **Type-safe error handling** with sealed `Failure` classes
- 🔄 **Either pattern** for functional error management (`Left` for failures, `Right` for success)
- 🌐 **Dio integration** - automatic conversion of Dio exceptions to typed failures
- 🎨 **Pattern matching** with `when()` and `maybeWhen()` methods
- ⚡ **Async support** with `mapAsync()`, `thenAsync()` and more
- 🧩 **Repository mixin** for clean repository implementations

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  dart_failure_handler:
    git:
      url: https://github.com/your-username/dart_failure_handler.git
```

Or if published to pub.dev:

```yaml
dependencies:
  dart_failure_handler: ^1.0.0
```

## Usage

### Basic Either Usage

```dart
import 'package:dart_failure_handler/dart_failure_handler.dart';

// Creating Either values
final success = Right<Failure, String>('Hello World');
final failure = Left<Failure, String>(ServerFailure(statusCode: 500));

// Using fold
final message = success.fold(
  (failure) => 'Error: ${failure.message}',
  (value) => 'Success: $value',
);

// Using getOrElse
final value = success.getOrElse('default value');

// Mapping values
final mapped = success.map((value) => value.toUpperCase());
```

### Repository Pattern with RepositoryHandler

```dart
import 'package:dio/dio.dart';
import 'package:dart_failure_handler/dart_failure_handler.dart';

class UserRepository with RepositoryHandler {
  final Dio _dio;

  UserRepository(this._dio);

  Future<Either<Failure, User>> getUser(int id) {
    return call(() async {
      final response = await _dio.get('/users/$id');
      return User.fromJson(response.data);
    });
  }

  Future<Either<Failure, List<User>>> getUsers() {
    return call(() async {
      final response = await _dio.get('/users');
      return (response.data as List)
          .map((json) => User.fromJson(json))
          .toList();
    });
  }
}
```

### Handling Failures with Pattern Matching

```dart
final result = await userRepository.getUser(1);

result.fold(
  (failure) => failure.when(
    server: (f) => showError('Server error: ${f.statusCode}'),
    network: (_) => showError('No internet connection'),
    timeout: (_) => showError('Request timed out'),
    cancellation: (_) => showError('Request was cancelled'),
    parsing: (_) => showError('Data parsing error'),
    unknown: (f) => showError(f.message),
  ),
  (user) => showUser(user),
);
```

### Using maybeWhen for Partial Handling

```dart
final message = failure.maybeWhen(
  server: (f) => 'Server error: ${f.statusCode}',
  network: (_) => 'Check your internet connection',
  orElse: (f) => f.message,
);
```

### Chaining Operations

```dart
final result = await userRepository.getUser(1);

// Chain multiple operations
final userName = result
    .map((user) => user.name)
    .map((name) => name.toUpperCase())
    .getOrElse('Anonymous');

// Async chaining
final profile = await result
    .thenAsync((user) => profileRepository.getProfile(user.id));
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

## Either API Reference

### Properties

| Property  | Type   | Description                       |
| --------- | ------ | --------------------------------- |
| `isLeft`  | `bool` | Returns true if this is a `Left`  |
| `isRight` | `bool` | Returns true if this is a `Right` |
| `left`    | `L`    | Gets left value (throws if Right) |
| `right`   | `R`    | Gets right value (throws if Left) |

### Methods

| Method                 | Return Type             | Description                 |
| ---------------------- | ----------------------- | --------------------------- |
| `fold(fnL, fnR)`       | `T`                     | Pattern match on Left/Right |
| `map(fn)`              | `Either<L, TR>`         | Transform Right value       |
| `mapLeft(fn)`          | `Either<TL, R>`         | Transform Left value        |
| `mapAsync(fn)`         | `Future<Either<L, TR>>` | Async transform Right       |
| `then(fn)`             | `Either<L, TR>`         | Chain another Either        |
| `thenAsync(fn)`        | `Future<Either<L, TR>>` | Async chain                 |
| `getOrElse(default)`   | `R`                     | Get Right or default        |
| `getOrElseCompute(fn)` | `R`                     | Get Right or compute        |
| `swap()`               | `Either<R, L>`          | Swap Left and Right         |

### Static Methods

| Method                               | Description                          |
| ------------------------------------ | ------------------------------------ |
| `Either.tryCatch(onError, fn)`       | Catch exceptions and convert to Left |
| `Either.tryExcept<E, R>(fn)`         | Simplified tryCatch                  |
| `Either.cond(test, left, right)`     | Create based on condition            |
| `Either.condLazy(test, left, right)` | Lazy version of cond                 |

## ErrorHandler

Manually convert exceptions to Failures:

```dart
try {
  await dio.get('/api/data');
} catch (e, st) {
  final failure = ErrorHandler.handle(e, st);
  // failure is now a typed Failure
}
```

## Best Practices

1. **Always use the Repository pattern** with `RepositoryHandler` mixin
2. **Use pattern matching** (`when`/`maybeWhen`) instead of type checks
3. **Chain operations** using `map`, `then`, `thenAsync` instead of nested folds
4. **Use `getOrElse`** for providing default values
5. **Include StackTrace** in error handling for debugging

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
