import 'error_handler.dart';
import 'repository_mixin.dart';
import 'dio_error_handler.dart';

/// Convenience mixin for repositories that use Dio.
///
/// This is a shorthand for overriding [errorMapper] with [DioErrorHandler.handle]
/// in [RepositoryHandler].
///
/// Example:
/// ```dart
/// class UserRepository with RepositoryHandler, DioRepositoryHandler {
///   final Dio _dio;
///   UserRepository(this._dio);
///
///   Future<Either<Failure, User>> getUser(int id) {
///     return call(() async {
///       final response = await _dio.get('/users/$id');
///       return User.fromJson(response.data);
///     });
///   }
/// }
/// ```
mixin DioRepositoryHandler on RepositoryHandler {
  /// Overrides [RepositoryHandler.errorMapper] to use [DioErrorHandler.handle].
  @override
  ErrorMapper get errorMapper => DioErrorHandler.handle;
}
