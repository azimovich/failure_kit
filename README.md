# failure_kit

HTTP-client agnostic error handling for Dart/Flutter — `Either` pattern, typed `Failure`s, and a pluggable mapper chain.

[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Why failure_kit

Plain `try/catch` is fine until your codebase grows, and at that point three problems show up:

1. **Errors are invisible in signatures.** `Future<User> getUser()` doesn't tell the caller anything can go wrong. The compiler won't remind you to handle failures.
2. **Exception types leak across layers.** `DioException`, `SocketException`, `FormatException`, `TimeoutException` — your UI ends up importing HTTP-client types just to render an error message.
3. **Every layer re-implements the same `try/catch`.** The same six lines that map exceptions to UI-friendly errors get copy-pasted into every repository.

Rolling your own `Either` solves the first two but not the third — and most hand-rolled versions miss async chaining, equality, exhaustive pattern matching, or proper stack-trace capture.

`failure_kit` gives you:

- **Errors in the type signature.** `Future<Either<Failure, User>>` — the caller can't ignore the failure case.
- **A typed `Failure` hierarchy.** `ServerFailure`, `NoInternetFailure`, `TimeoutFailure`, `CancellationFailure`, `ParsingFailure`, `UnknownFailure` — UI matches on these, not on raw exceptions.
- **One-line repository wrapping.** `FailureGuard.call(...)` does the `try/catch`, runs the mapper chain, and returns `Either`. You write the action, not the boilerplate.
- **Extensible mapping without forking the package.** A `FailureMapper` returns `Failure?` — return `null` to delegate. Compose Dio, Drift, GraphQL, auth, anything — order is yours.
- **Custom `Failure`s as first-class citizens.** Subclass `Failure` in your own project and they route through `when(custom:)` automatically.
- **A real `Either<L, R>`.** `map`, `mapAsync`, `then`, `thenAsync`, `fold`, `getOrElse`, `swap`, `tryCatch`, equality, `==`/`hashCode`, `Right(42) != Left(42)` — no surprises.

## Features

- 🎯 Type-safe error handling with extensible `Failure` classes
- 🔄 `Either` pattern (`Left` for failures, `Right` for success)
- 🔌 Works with any HTTP client — Dio, `http`, Chopper, GraphQL, Drift, Hive, anything
- 🎨 Pattern matching via `when()`, `maybeWhen()`, or native Dart 3 `switch`
- ⚡ Async support — `mapAsync`, `thenAsync`, and chaining directly on `Future<Either>`
- 🔁 Sync support — `callSync` for parsing, local computation, cache reads
- 🧩 Interceptor-style mapper chain — plug in your own mappers without touching the package
- 📦 Zero runtime dependencies beyond `meta`

## Installation

```yaml
dependencies:
  failure_kit: ^1.1.0
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

## Before / After

**Before — plain try/catch leaking exception types:**

```dart
Future<User> getUser(int id) async {
  try {
    final r = await _dio.get('/users/$id');
    return User.fromJson(r.data);
  } on DioException catch (e) {
    if (e.type == DioExceptionType.connectionError) throw NoInternetException();
    if (e.response?.statusCode != null) throw ServerException(e.response!.statusCode!);
    rethrow;
  } on FormatException {
    throw ParseException();
  }
}

// caller
try {
  final user = await repo.getUser(1);
  showUser(user);
} on NoInternetException {
  showError('No internet');
} on ServerException catch (e) {
  showError('Server ${e.code}');
} on ParseException {
  showError('Bad data');
} catch (_) {
  showError('Something went wrong');
}
```

**After — one-line wrapping, exhaustive matching, no exception leak:**

```dart
class UserRepository with FailureGuard {
  Future<Either<Failure, User>> getUser(int id) => call(() async {
        final r = await _dio.get('/users/$id');
        return User.fromJson(r.data);
      });
}

// caller
(await repo.getUser(1)).fold(
  (f) => f.when(
    server: (f) => showError('Server ${f.statusCode}'),
    network: (_) => showError('No internet'),
    timeout: (_) => showError('Timed out'),
    cancellation: (_) => showError('Cancelled'),
    parsing: (_) => showError('Bad data'),
    unknown: (f) => showError(f.message),
    custom: (f) => showError(f.message),
  ),
  showUser,
);
```

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

// Native Dart 3 pattern matching — Either is sealed, so switch is exhaustive
switch (result) {
  case Left(:final value):
    showError(value.message);
  case Right(:final value):
    showUser(value);
}

// onLeft / onRight — side effects (logging) without breaking the chain
final user = result
    .onLeft((f) => log.warning(f.message))
    .getOrElse(User.anonymous);
```

### Chaining on `Future<Either>`

The `FutureEither` extension lets you compose without intermediate `await`s:

```dart
// Instead of:
final name = (await repo.getUser(1)).map((u) => u.name).getOrElse('Anonymous');

// Write:
final name = await repo.getUser(1).mapRight((u) => u.name).getOrElse('Anonymous');

// Chains compose freely:
final posts = await repo
    .getUser(1)
    .thenRight((u) => repo.getPosts(u.id))
    .mapRight((posts) => posts.take(10).toList())
    .getOrElse(const []);
```

> `mapRight`/`thenRight` (not `map`/`then`) — `Future` already declares `then`,
> which would shadow the extension member.

### Synchronous actions

`callSync` wraps non-async actions with the same mapper chain:

```dart
class SettingsRepository with FailureGuard {
  Either<Failure, Settings> parse(String json) =>
      callSync(() => Settings.fromJson(jsonDecode(json)));
}
```

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
| `onLeft(fn)`             | `Either<L, R>`          | Side effect on Left, chainable |
| `onRight(fn)`            | `Either<L, R>`          | Side effect on Right, chainable|

### Static methods

| Method                                  | Description                          |
| --------------------------------------- | ------------------------------------ |
| `Either.tryCatch(onError, fn)`          | Catch exceptions, convert to Left    |
| `Either.tryCatchAsync(onError, fn)`     | Async version of `tryCatch`          |
| `Either.tryExcept<E, R>(fn)`            | Simplified `tryCatch`                |
| `Either.cond(test, left, right)`        | Build from a condition               |
| `Either.condLazy(test, left, right)`    | Lazy version of `cond`               |

### `FutureEither` extension (on `Future<Either<L, R>>`)

| Method               | Description                              |
| -------------------- | ---------------------------------------- |
| `mapRight(fn)`       | Transform Right without awaiting first   |
| `mapLeft(fn)`        | Transform Left without awaiting first    |
| `thenRight(fn)`      | Chain another `Either` on Right          |
| `thenLeft(fn)`       | Chain another `Either` on Left           |
| `fold(fnL, fnR)`     | Await and fold in one step               |
| `getOrElse(default)` | Await and unwrap with default            |

## License

MIT — see [LICENSE](LICENSE).

---

Developed with [Claude Code](https://claude.com/claude-code).
