import 'either.dart';
import 'failure.dart';
import 'error_handler.dart';

/// Mixin to be used in Repository implementations to safely execute API calls.
///
/// By default, uses [ErrorHandler.handle] for error mapping. Override [errorMapper]
/// to use a different error handling strategy.
///
/// **For Dio users**, either override [errorMapper] with [DioErrorHandler.handle]
/// or use [DioRepositoryHandler] from `package:dart_failure_handler/dio.dart`.
///
/// Example (generic, no Dio):
/// ```dart
/// class UserRepository with RepositoryHandler {
///   final HttpClient _client;
///   UserRepository(this._client);
///
///   Future<Either<Failure, User>> getUser() => call(() async {
///     final response = await _client.get('/users/1');
///     return User.fromJson(response.body);
///   });
/// }
/// ```
///
/// Example (with custom error mapper):
/// ```dart
/// class UserRepository with RepositoryHandler {
///   @override
///   ErrorMapper get errorMapper => DioErrorHandler.handle;
///
///   Future<Either<Failure, User>> getUser() => call(() async { ... });
/// }
/// ```
mixin RepositoryHandler {
  /// Override this getter to provide a custom error mapper.
  ///
  /// Defaults to [ErrorHandler.handle] which handles standard Dart exceptions.
  /// For Dio support, override with `DioErrorHandler.handle`.
  ErrorMapper get errorMapper => ErrorHandler.handle;

  /// Wraps a [Future] call in a try-catch block and returns an [Either].
  ///
  /// Returns [Right] with the result on success,
  /// or [Left] with a [Failure] mapped by [errorMapper] on exception.
  ///
  /// Example:
  /// ```dart
  /// Future<Either<Failure, User>> getUser() => call(() => api.fetchUser());
  /// ```
  Future<Either<Failure, T>> call<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } catch (e, st) {
      return Left(errorMapper(e, st));
    }
  }
}
