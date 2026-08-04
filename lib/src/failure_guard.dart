import 'either.dart';
import 'failure.dart';
import 'failure_mapper.dart';

/// Mixin that wraps async calls in [Either], converting exceptions to [Failure].
///
/// Apply to any class — not limited to repository pattern.
/// Override [failureChain] to add custom mappers (Drift, Hive, GraphQL, etc.).
/// The chain tries each mapper in order — the first non-null result wins.
/// Falls back to [BaseFailureMapper] for unhandled errors.
///
/// **For Dio users**, apply [DioFailureGuard] from
/// `package:failure_kit/dio.dart` — it prepends [DioFailureMapper]
/// to the chain automatically.
///
/// Example — base usage (any HTTP client):
/// ```dart
/// class UserRepository with FailureGuard {
///   Future<Either<Failure, User>> getUser() => call(() async {
///     final response = await _client.get('/users/1');
///     return User.fromJson(response.body);
///   });
/// }
/// ```
///
/// Example — custom chain:
/// ```dart
/// class UserLocalRepository with FailureGuard {
///   @override
///   FailureMapperChain get failureChain =>
///       FailureMapperChain.base.prepend(DriftFailureMapper.handle);
///
///   Future<Either<Failure, User>> getUser(int id) =>
///       call(() async => _dao.userById(id));
/// }
/// ```
mixin FailureGuard {
  /// The mapper chain used to convert exceptions to [Failure].
  ///
  /// Defaults to [FailureMapperChain.base] which uses only [BaseFailureMapper].
  /// Override to inject custom or additional mappers.
  FailureMapperChain get failureChain => FailureMapperChain.base;

  /// Executes [action] and wraps the result in [Either].
  ///
  /// Returns [Right] on success, [Left] with a [Failure] on any exception.
  Future<Either<Failure, T>> call<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } catch (e, st) {
      return Left(failureChain.handle(e, st));
    }
  }

  /// Synchronous version of [call] — for actions that don't return a future
  /// (e.g. parsing, local computation, in-memory cache reads).
  Either<Failure, T> callSync<T>(T Function() action) {
    try {
      return Right(action());
    } catch (e, st) {
      return Left(failureChain.handle(e, st));
    }
  }
}
