// ignore_for_file: avoid_print

import 'package:dart_failure_handler/dart_failure_handler.dart';

// =============================================================================
// This example shows usage WITHOUT Dio (any HTTP client works)
//
// For Dio-specific usage, see: example/dio_example.dart
// =============================================================================

// --- Example: Simple data service ---
class DataService with RepositoryHandler {
  /// Simulates fetching data that could fail
  Future<Either<Failure, String>> fetchData() {
    return call(() async {
      // Replace with your HTTP client call (http, chopper, etc.)
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return 'Hello from API!';
    });
  }

  /// Simulates a failing call
  Future<Either<Failure, String>> fetchBadData() {
    return call(() async {
      throw FormatException('Invalid JSON received');
    });
  }
}

// --- Example: Custom error mapper chain ---
class CustomService with RepositoryHandler {
  @override
  ErrorMapperChain get errorMapperChain =>
      ErrorMapperChain.base.prepend(_customMapper);

  static Failure? _customMapper(Object error, StackTrace st) {
    if (error is FormatException) {
      return ParsingFailure(
        message: 'Custom: ${error.message}',
        cause: error,
        stackTrace: st,
      );
    }
    return null; // pass to BaseErrorMapper
  }

  Future<Either<Failure, int>> calculate() {
    return call(() async {
      throw FormatException('bad data');
    });
  }
}

// --- Example: User-defined Failure subclass ---
class DatabaseFailure extends Failure {
  const DatabaseFailure({
    super.message = 'Database error',
    super.cause,
    super.stackTrace,
  });
}

void main() async {
  final dataService = DataService();

  // -----------------------------------------------------------------------
  // Example 1: Basic usage with fold
  // -----------------------------------------------------------------------
  print('=== Example 1: Basic fold ===');
  final result = await dataService.fetchData();
  result.fold(
    (failure) => print('Error: ${failure.message}'),
    (data) => print('Data: $data'),
  );

  // -----------------------------------------------------------------------
  // Example 2: Pattern matching with when()
  // -----------------------------------------------------------------------
  print('\n=== Example 2: when() pattern matching ===');
  final badResult = await dataService.fetchBadData();
  badResult.fold(
    (failure) => failure.when(
      server: (f) => print('Server error: ${f.statusCode}'),
      network: (_) => print('No internet'),
      timeout: (_) => print('Request timed out'),
      cancellation: (_) => print('Cancelled'),
      parsing: (f) => print('Parsing error: ${f.message}'),
      unknown: (f) => print('Unknown: ${f.message}'),
      custom: (f) => print('Custom: ${f.message}'),
    ),
    (data) => print('Data: $data'),
  );

  // -----------------------------------------------------------------------
  // Example 3: maybeWhen() - handle only what you need
  // -----------------------------------------------------------------------
  print('\n=== Example 3: maybeWhen() ===');
  final msg = badResult.fold(
    (failure) => failure.maybeWhen(
      parsing: (_) => 'Data format issue',
      orElse: (f) => f.message,
    ),
    (data) => data,
  );
  print('Message: $msg');

  // -----------------------------------------------------------------------
  // Example 4: getOrElse
  // -----------------------------------------------------------------------
  print('\n=== Example 4: getOrElse ===');
  final value = badResult.getOrElse('default value');
  print('Value: $value');

  // -----------------------------------------------------------------------
  // Example 5: Chaining with map
  // -----------------------------------------------------------------------
  print('\n=== Example 5: map chaining ===');
  final upperResult = result.map((s) => s.toUpperCase());
  print('Mapped: ${upperResult.getOrElse("N/A")}');

  // -----------------------------------------------------------------------
  // Example 6: Either.tryCatch
  // -----------------------------------------------------------------------
  print('\n=== Example 6: Either.tryCatch ===');
  final parseResult = Either.tryCatch<ParsingFailure, int, FormatException>(
    (e) => ParsingFailure(message: 'Invalid number: ${e.message}'),
    () => int.parse('not-a-number'),
  );
  print(parseResult.fold(
    (f) => 'Failed: ${f.message}',
    (n) => 'Parsed: $n',
  ));

  // -----------------------------------------------------------------------
  // Example 7: rightOrNull / leftOrNull
  // -----------------------------------------------------------------------
  print('\n=== Example 7: rightOrNull / leftOrNull ===');
  final successEither = await dataService.fetchData();
  final failureEither = await dataService.fetchBadData();

  print('rightOrNull on success: ${successEither.rightOrNull}');
  print('rightOrNull on failure: ${failureEither.rightOrNull}');
  print('leftOrNull on success: ${successEither.leftOrNull}');
  print('leftOrNull on failure: ${failureEither.leftOrNull?.message}');

  // -----------------------------------------------------------------------
  // Example 8: Custom ErrorMapper chain
  // -----------------------------------------------------------------------
  print('\n=== Example 8: Custom ErrorMapperChain ===');
  final customService = CustomService();
  final customResult = await customService.calculate();
  print('Custom failure: ${customResult.left.message}');

  // -----------------------------------------------------------------------
  // Example 9: User-defined Failure subclass + when(custom:)
  // -----------------------------------------------------------------------
  print('\n=== Example 9: User-defined Failure with when(custom:) ===');
  final dbChain = ErrorMapperChain.base.prepend((e, st) {
    if (e is FormatException) {
      return DatabaseFailure(
        message: 'DB parse error: ${e.message}',
        cause: e,
        stackTrace: st,
      );
    }
    return null;
  });

  final dbFailure = dbChain.handle(
    const FormatException('schema mismatch'),
    StackTrace.current,
  );
  final dbMsg = dbFailure.when(
    server: (_) => 'server',
    network: (_) => 'network',
    timeout: (_) => 'timeout',
    cancellation: (_) => 'cancelled',
    parsing: (_) => 'parsing',
    unknown: (_) => 'unknown',
    custom: (f) => f is DatabaseFailure ? 'DB: ${f.message}' : f.message,
  );
  print('DB failure: $dbMsg');
}
