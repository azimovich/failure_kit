import 'either.dart';
import 'failure.dart';
import 'error_handler.dart';

/// Mixin to be used in Repository implementations to safely execute API calls.
mixin RepositoryHandler {
  /// Wraps a [Future] call in a try-catch block and returns an [Either].
  ///
  /// Example:
  /// ```dart
  /// Future<Either<Failure, User>> getUser() => call(() => api.fetchUser());
  /// ```
  Future<Either<Failure, T>> call<T>(Future<T> Function() action) async {
    try {
      final result = await action();
      return Right(result);
    } catch (e, st) {
      return Left(ErrorHandler.handle(e, st));
    }
  }
}
