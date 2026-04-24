import 'either.dart';
import 'failure.dart';
import 'error_mapper.dart';

/// Mixin for repository implementations that wraps async calls in [Either].
///
/// Override [errorMapperChain] to add custom error mappers (Drift, Hive,
/// GraphQL, etc.). The chain tries each mapper in order — the first non-null
/// result wins. Falls back to [BaseErrorMapper] for unhandled errors.
///
/// **For Dio users**, apply [DioRepositoryHandler] from
/// `package:dart_failure_handler/dio.dart` — it prepends [DioErrorMapper]
/// to the chain automatically.
///
/// Example — base usage (any HTTP client):
/// ```dart
/// class UserRepository with RepositoryHandler {
///   Future<Either<Failure, User>> getUser() => call(() async {
///     final response = await _client.get('/users/1');
///     return User.fromJson(response.body);
///   });
/// }
/// ```
///
/// Example — custom chain:
/// ```dart
/// class UserLocalRepository with RepositoryHandler {
///   @override
///   ErrorMapperChain get errorMapperChain =>
///       ErrorMapperChain.base.prepend(DriftErrorMapper.handle);
///
///   Future<Either<Failure, User>> getUser(int id) =>
///       call(() async => _dao.userById(id));
/// }
/// ```
mixin RepositoryHandler {
  /// The error mapper chain used to convert exceptions to [Failure].
  ///
  /// Defaults to [ErrorMapperChain.base] which uses only [BaseErrorMapper].
  /// Override to inject custom or additional mappers.
  ErrorMapperChain get errorMapperChain => ErrorMapperChain.base;

  /// Executes [action] and wraps the result in [Either].
  ///
  /// Returns [Right] on success, [Left] with a [Failure] on any exception.
  Future<Either<Failure, T>> call<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } catch (e, st) {
      return Left(errorMapperChain.handle(e, st));
    }
  }
}
