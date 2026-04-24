import 'error_mapper.dart';
import 'repository_mixin.dart';
import 'dio_error_mapper.dart';

/// Convenience mixin that prepends [DioErrorMapper] to the [errorMapperChain].
///
/// Apply alongside [RepositoryHandler] in any Dio-backed repository.
///
/// Example — Dio only:
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
///
/// Example — Dio + custom mapper:
/// ```dart
/// class UserRepository with RepositoryHandler, DioRepositoryHandler {
///   @override
///   ErrorMapperChain get errorMapperChain =>
///       super.errorMapperChain.prepend(MyAuthErrorMapper.handle);
/// }
/// ```
mixin DioRepositoryHandler on RepositoryHandler {
  @override
  ErrorMapperChain get errorMapperChain =>
      ErrorMapperChain.base.prepend(DioErrorMapper.handle);
}
