// ignore_for_file: avoid_print

import 'package:failure_kit/dio.dart';
import 'package:dio/dio.dart';

// =============================================================================
// This example shows usage WITH Dio
//
// Import 'package:failure_kit/dio.dart' instead of
// 'package:failure_kit/failure_kit.dart'
// =============================================================================

class User {
  final int id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }
}

// --- Method 1: Using DioFailureGuard mixin ---
class UserRepository with FailureGuard, DioFailureGuard {
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
      return (response.data as List).map((json) => User.fromJson(json)).toList();
    });
  }
}

// --- Method 2: Manual chain via failureChain override ---
class PostRepository with FailureGuard {
  final Dio _dio;

  PostRepository(this._dio);

  @override
  FailureMapperChain get failureChain =>
      FailureMapperChain.base.prepend(DioFailureMapper.handle);

  Future<Either<Failure, Map<String, dynamic>>> getPost(int id) {
    return call(() async {
      final response = await _dio.get('/posts/$id');
      return response.data as Map<String, dynamic>;
    });
  }
}

void main() async {
  final dio = Dio(BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com'));

  // -----------------------------------------------------------------------
  // Example 1: DioFailureGuard mixin usage
  // -----------------------------------------------------------------------
  print('=== Example 1: Dio Repository with mixin ===');
  final userRepo = UserRepository(dio);
  final userResult = await userRepo.getUser(1);

  userResult.fold(
    (failure) => failure.when(
      server: (f) => print('Server error ${f.statusCode}: ${f.message}'),
      network: (_) => print('No internet connection'),
      timeout: (_) => print('Request timed out, try again'),
      cancellation: (_) => print('Request was cancelled'),
      parsing: (_) => print('Failed to parse response'),
      unknown: (f) => print('Unknown error: ${f.message}'),
      custom: (f) => print('Custom error: ${f.message}'),
    ),
    (user) => print('User: ${user.name} (${user.email})'),
  );

  // -----------------------------------------------------------------------
  // Example 2: failureChain override usage
  // -----------------------------------------------------------------------
  print('\n=== Example 2: failureChain override ===');
  final postRepo = PostRepository(dio);
  final postResult = await postRepo.getPost(1);

  final title = postResult.map((post) => post['title'] as String).getOrElse('Unknown post');
  print('Post title: $title');

  // -----------------------------------------------------------------------
  // Example 3: Manual DioFailureMapper usage
  // -----------------------------------------------------------------------
  print('\n=== Example 3: Manual DioFailureMapper ===');
  try {
    await dio.get('/nonexistent-endpoint-404');
  } catch (e, st) {
    final failure = DioFailureMapper.handle(e, st) ?? BaseFailureMapper.handle(e, st);
    print('Failure: $failure');
  }

  // -----------------------------------------------------------------------
  // Example 4: Dio + custom mapper chain
  // -----------------------------------------------------------------------
  print('\n=== Example 4: Dio + custom chain ===');
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
  final authFailure = chain.handle(e401, StackTrace.current);
  print('Auth failure: ${authFailure.message}');

  dio.close();
}
