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

// --- Example: Custom error mapper ---
class CustomService with RepositoryHandler {
  @override
  ErrorMapper get errorMapper => _customMapper;

  static Failure _customMapper(Object error, StackTrace st) {
    // Map your custom exceptions here
    if (error is FormatException) {
      return ParsingFailure(message: 'Custom: ${error.message}', cause: error, stackTrace: st);
    }
    // Fallback to base handler
    return ErrorHandler.handle(error, st);
  }

  Future<Either<Failure, int>> calculate() {
    return call(() async {
      throw FormatException('bad data');
    });
  }
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
  // Example 7: Custom error mapper
  // -----------------------------------------------------------------------
  print('\n=== Example 7: Custom ErrorMapper ===');
  final customService = CustomService();
  final customResult = await customService.calculate();
  print('Custom failure: ${customResult.left.message}');
}
