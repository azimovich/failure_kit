// ignore_for_file: avoid_print
//
// Copy-paste integration example for Dio.
//
// `failure_kit` is HTTP-client agnostic and does NOT depend on `package:dio`.
// To use it with Dio, add Dio to your own pubspec and copy the mapper below
// into your project (e.g. `lib/core/dio_failure_mapper.dart`).
//
// To run this file locally:
//   1. Add `dio: ^5.0.0` to your project's `dev_dependencies`.
//   2. `dart run example/dio_integration.dart`

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:failure_kit/failure_kit.dart';

// =============================================================================
// 1. The mapper — copy this into your project.
// =============================================================================

/// Maps [DioException] and [SocketException] to typed [Failure]s.
///
/// Returns `null` for any error that is not Dio-related, allowing the next
/// mapper in the chain (or [BaseFailureMapper]) to handle it.
class DioFailureMapper {
  const DioFailureMapper._();

  /// Conforms to [FailureMapper]. Returns `null` for non-Dio errors.
  static Failure? handle(Object error, StackTrace st) {
    if (error is DioException) return _fromDio(error, st);
    if (error is SocketException) {
      return NoInternetFailure(cause: error, stackTrace: st);
    }
    return null;
  }

  static Failure _fromDio(DioException e, StackTrace st) {
    if (e.error is SocketException) {
      return NoInternetFailure(cause: e, stackTrace: st);
    }

    return switch (e.type) {
      DioExceptionType.connectionError =>
        NoInternetFailure(cause: e, stackTrace: st),
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        TimeoutFailure(
          message: 'Request timed out: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      DioExceptionType.cancel =>
        CancellationFailure(cause: e, stackTrace: st),
      DioExceptionType.badCertificate => UnknownFailure(
          message: 'Bad certificate: ${e.message ?? 'SSL error'}',
          cause: e,
          stackTrace: st,
        ),
      _ => _server(e, st),
    };
  }

  static Failure _server(DioException e, StackTrace st) {
    final response = e.response;
    final code = response?.statusCode;
    var message =
        code != null ? 'Server error ($code)' : 'Unexpected server error';

    if (response?.data is Map) {
      final data = response!.data as Map;
      message = data['message']?.toString() ??
          data['error']?.toString() ??
          data['msg']?.toString() ??
          message;
    }

    return ServerFailure(
      message: message,
      statusCode: code,
      data: response?.data,
      cause: e,
      stackTrace: st,
    );
  }
}

/// Convenience mixin — applies [DioFailureMapper] automatically.
///
/// Use alongside [FailureGuard]:
///
/// ```dart
/// class UserRepository with FailureGuard, DioFailureGuard {
///   ...
/// }
/// ```
mixin DioFailureGuard on FailureGuard {
  @override
  FailureMapperChain get failureChain =>
      FailureMapperChain.base.prepend(DioFailureMapper.handle);
}

// =============================================================================
// 2. Repository usage
// =============================================================================

class User {
  final int id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
      );
}

// Method 1: DioFailureGuard mixin (zero boilerplate).
class UserRepository with FailureGuard, DioFailureGuard {
  final Dio _dio;
  UserRepository(this._dio);

  Future<Either<Failure, User>> getUser(int id) => call(() async {
        final r = await _dio.get('/users/$id');
        return User.fromJson(r.data as Map<String, dynamic>);
      });
}

// Method 2: Manual chain — useful when you compose with other mappers.
class PostRepository with FailureGuard {
  final Dio _dio;
  PostRepository(this._dio);

  @override
  FailureMapperChain get failureChain =>
      FailureMapperChain.base.prepend(DioFailureMapper.handle);

  Future<Either<Failure, Map<String, dynamic>>> getPost(int id) => call(() async {
        final r = await _dio.get('/posts/$id');
        return r.data as Map<String, dynamic>;
      });
}

// =============================================================================
// 3. Demo
// =============================================================================

Future<void> main() async {
  final dio = Dio(BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com'));

  // Example 1: mixin usage.
  print('=== mixin ===');
  final userRepo = UserRepository(dio);
  (await userRepo.getUser(1)).fold(
    (f) => f.when(
      server: (f) => print('Server ${f.statusCode}: ${f.message}'),
      network: (_) => print('No internet'),
      timeout: (_) => print('Timed out'),
      cancellation: (_) => print('Cancelled'),
      parsing: (_) => print('Parse error'),
      unknown: (f) => print('Unknown: ${f.message}'),
      custom: (f) => print('Custom: ${f.message}'),
    ),
    (u) => print('User: ${u.name} (${u.email})'),
  );

  // Example 2: manual chain.
  print('\n=== manual chain ===');
  final postRepo = PostRepository(dio);
  final title = (await postRepo.getPost(1))
      .map((p) => p['title'] as String)
      .getOrElse('Unknown post');
  print('Post title: $title');

  // Example 3: stand-alone mapping outside FailureGuard.
  print('\n=== stand-alone ===');
  try {
    await dio.get('/nonexistent-endpoint-404');
  } catch (e, st) {
    final failure =
        DioFailureMapper.handle(e, st) ?? BaseFailureMapper.handle(e, st);
    print('Failure: $failure');
  }

  // Example 4: compose with a custom mapper (e.g. session expiry).
  print('\n=== custom chain ===');
  final chain = FailureMapperChain.base
      .prepend(DioFailureMapper.handle)
      .prepend((e, st) {
    if (e is DioException && e.response?.statusCode == 401) {
      return const ServerFailure(message: 'Session expired', statusCode: 401);
    }
    return null;
  });

  final e401 = DioException(
    type: DioExceptionType.badResponse,
    requestOptions: RequestOptions(path: '/secure'),
    response: Response(
      statusCode: 401,
      requestOptions: RequestOptions(path: '/secure'),
    ),
  );
  print('Auth: ${chain.handle(e401, StackTrace.current).message}');

  dio.close();
}
