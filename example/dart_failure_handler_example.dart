// ignore_for_file: avoid_print

import 'package:dart_failure_handler/dart_failure_handler.dart';
import 'package:dio/dio.dart';

// =============================================================================
// Example: User model
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

// =============================================================================
// Example: Repository using RepositoryHandler mixin
// =============================================================================

class UserRepository with RepositoryHandler {
  final Dio _dio;

  UserRepository(this._dio);

  /// Fetches a user by ID
  Future<Either<Failure, User>> getUser(int id) {
    return call(() async {
      final response = await _dio.get('/users/$id');
      return User.fromJson(response.data);
    });
  }

  /// Fetches all users
  Future<Either<Failure, List<User>>> getUsers() {
    return call(() async {
      final response = await _dio.get('/users');
      return (response.data as List).map((json) => User.fromJson(json)).toList();
    });
  }

  /// Creates a new user
  Future<Either<Failure, User>> createUser({
    required String name,
    required String email,
  }) {
    return call(() async {
      final response = await _dio.post('/users', data: {
        'name': name,
        'email': email,
      });
      return User.fromJson(response.data);
    });
  }
}

// =============================================================================
// Example: Usage in application
// =============================================================================

void main() async {
  final dio = Dio(BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com'));
  final userRepository = UserRepository(dio);

  // ---------------------------------------------------------------------------
  // Example 1: Basic usage with fold
  // ---------------------------------------------------------------------------
  print('=== Example 1: Basic usage with fold ===');

  final result = await userRepository.getUser(1);

  result.fold(
    (failure) => print('Error: ${failure.message}'),
    (user) => print('User: ${user.name} (${user.email})'),
  );

  // ---------------------------------------------------------------------------
  // Example 2: Pattern matching with when()
  // ---------------------------------------------------------------------------
  print('\n=== Example 2: Pattern matching with when() ===');

  final result2 = await userRepository.getUser(999); // Non-existent user

  result2.fold(
    (failure) => failure.when(
      server: (f) => print('Server error: ${f.statusCode} - ${f.message}'),
      network: (_) => print('No internet connection. Please check your network.'),
      timeout: (_) => print('Request timed out. Please try again.'),
      cancellation: (_) => print('Request was cancelled.'),
      parsing: (_) => print('Failed to parse response data.'),
      unknown: (f) => print('Unknown error: ${f.message}'),
    ),
    (user) => print('User: ${user.name}'),
  );

  // ---------------------------------------------------------------------------
  // Example 3: Using maybeWhen() for partial handling
  // ---------------------------------------------------------------------------
  print('\n=== Example 3: Using maybeWhen() ===');

  final result3 = await userRepository.getUsers();

  final message = result3.fold(
    (failure) => failure.maybeWhen(
      network: (_) => 'Check your connection',
      timeout: (_) => 'Slow connection, try again',
      orElse: (f) => f.message,
    ),
    (users) => 'Found ${users.length} users',
  );
  print(message);

  // ---------------------------------------------------------------------------
  // Example 4: Chaining with map and getOrElse
  // ---------------------------------------------------------------------------
  print('\n=== Example 4: Chaining with map and getOrElse ===');

  final result4 = await userRepository.getUser(1);

  final userName = result4.map((user) => user.name).map((name) => name.toUpperCase()).getOrElse('Anonymous');

  print('User name: $userName');

  // ---------------------------------------------------------------------------
  // Example 5: Creating Either values directly
  // ---------------------------------------------------------------------------
  print('\n=== Example 5: Creating Either values ===');

  // Success case
  final Either<Failure, int> success = const Right(42);
  print('Is right: ${success.isRight}');
  print('Value: ${success.right}');

  // Failure case
  final Either<Failure, int> failure = const Left(
    ServerFailure(message: 'Not found', statusCode: 404),
  );
  print('Is left: ${failure.isLeft}');
  print('Failure: ${failure.left}');

  // ---------------------------------------------------------------------------
  // Example 6: Using Either.tryCatch
  // ---------------------------------------------------------------------------
  print('\n=== Example 6: Using Either.tryCatch ===');

  final parseResult = Either.tryCatch<ParsingFailure, int, FormatException>(
    (e) => ParsingFailure(message: 'Invalid number: ${e.message}'),
    () => int.parse('not-a-number'),
  );

  print(parseResult.fold(
    (f) => 'Parse failed: ${f.message}',
    (n) => 'Parsed: $n',
  ));

  // ---------------------------------------------------------------------------
  // Example 7: Using Either.cond
  // ---------------------------------------------------------------------------
  print('\n=== Example 7: Using Either.cond ===');

  const age = 20;
  final ageCheck = Either.cond<String, String>(
    test: age >= 18,
    leftValue: 'Too young',
    rightValue: 'Access granted',
  );

  print(ageCheck.getOrElse('Unknown'));
}
