// ignore_for_file: avoid_print

import 'package:dart_failure_handler/dio.dart';
import 'package:dio/dio.dart';

// =============================================================================
// This example shows usage WITH Dio
//
// Import 'package:dart_failure_handler/dio.dart' instead of
// 'package:dart_failure_handler/dart_failure_handler.dart'
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

// --- Method 1: Using DioRepositoryHandler mixin ---
class UserRepository with RepositoryHandler, DioRepositoryHandler {
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

// --- Method 2: Using errorMapper override (alternative approach) ---
class PostRepository with RepositoryHandler {
  final Dio _dio;

  PostRepository(this._dio);

  /// Override errorMapper to use DioErrorHandler
  @override
  ErrorMapper get errorMapper => DioErrorHandler.handle;

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
  // Example 1: DioRepositoryHandler mixin usage
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
    ),
    (user) => print('User: ${user.name} (${user.email})'),
  );

  // -----------------------------------------------------------------------
  // Example 2: errorMapper override usage
  // -----------------------------------------------------------------------
  print('\n=== Example 2: errorMapper override ===');
  final postRepo = PostRepository(dio);
  final postResult = await postRepo.getPost(1);

  final title = postResult.map((post) => post['title'] as String).getOrElse('Unknown post');
  print('Post title: $title');

  // -----------------------------------------------------------------------
  // Example 3: Manual DioErrorHandler usage
  // -----------------------------------------------------------------------
  print('\n=== Example 3: Manual DioErrorHandler ===');
  try {
    await dio.get('/nonexistent-endpoint-404');
  } catch (e, st) {
    final failure = DioErrorHandler.handle(e, st);
    print('Failure: $failure');
  }

  dio.close();
}
