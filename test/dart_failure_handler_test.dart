import 'dart:async';

import 'package:dart_failure_handler/dart_failure_handler.dart';
import 'package:test/test.dart';

void main() {
  group('Either', () {
    group('Right', () {
      test('isRight returns true', () {
        const either = Right<String, int>(42);
        expect(either.isRight, isTrue);
        expect(either.isLeft, isFalse);
      });

      test('right getter returns value', () {
        const either = Right<String, int>(42);
        expect(either.right, equals(42));
      });

      test('left getter throws', () {
        const either = Right<String, int>(42);
        expect(() => either.left, throwsException);
      });

      test('fold returns right function result', () {
        const either = Right<String, int>(42);
        final result = either.fold((l) => 'left', (r) => 'right: $r');
        expect(result, equals('right: 42'));
      });

      test('map transforms right value', () {
        const either = Right<String, int>(42);
        final mapped = either.map((r) => r * 2);
        expect(mapped.right, equals(84));
      });

      test('mapLeft does nothing', () {
        const either = Right<String, int>(42);
        final mapped = either.mapLeft((l) => 'transformed');
        expect(mapped.right, equals(42));
      });

      test('getOrElse returns right value', () {
        const either = Right<String, int>(42);
        expect(either.getOrElse(0), equals(42));
      });

      test('then chains to next Either', () {
        const either = Right<String, int>(42);
        final chained = either.then((r) => Right<String, String>('value: $r'));
        expect(chained.right, equals('value: 42'));
      });

      test('swap converts to Left', () {
        const either = Right<String, int>(42);
        final swapped = either.swap();
        expect(swapped.isLeft, isTrue);
        expect(swapped.left, equals(42));
      });
    });

    group('Left', () {
      test('isLeft returns true', () {
        const either = Left<String, int>('error');
        expect(either.isLeft, isTrue);
        expect(either.isRight, isFalse);
      });

      test('left getter returns value', () {
        const either = Left<String, int>('error');
        expect(either.left, equals('error'));
      });

      test('right getter throws', () {
        const either = Left<String, int>('error');
        expect(() => either.right, throwsException);
      });

      test('fold returns left function result', () {
        const either = Left<String, int>('error');
        final result = either.fold((l) => 'left: $l', (r) => 'right');
        expect(result, equals('left: error'));
      });

      test('map does nothing', () {
        const either = Left<String, int>('error');
        final mapped = either.map((r) => r * 2);
        expect(mapped.left, equals('error'));
      });

      test('mapLeft transforms left value', () {
        const either = Left<String, int>('error');
        final mapped = either.mapLeft((l) => l.toUpperCase());
        expect(mapped.left, equals('ERROR'));
      });

      test('getOrElse returns default value', () {
        const either = Left<String, int>('error');
        expect(either.getOrElse(99), equals(99));
      });

      test('getOrElseCompute computes default from left', () {
        const either = Left<String, int>('error');
        expect(either.getOrElseCompute((l) => l.length), equals(5));
      });

      test('then does not chain', () {
        const either = Left<String, int>('error');
        final chained = either.then((r) => Right<String, String>('value: $r'));
        expect(chained.left, equals('error'));
      });

      test('thenLeft chains on left', () {
        const either = Left<String, int>('error');
        final chained = either.thenLeft((l) => Left<int, int>(l.length));
        expect(chained.left, equals(5));
      });
    });

    group('Static methods', () {
      test('tryCatch returns Right on success', () {
        final result = Either.tryCatch<String, int, Exception>(
          (e) => e.toString(),
          () => 42,
        );
        expect(result.isRight, isTrue);
        expect(result.right, equals(42));
      });

      test('tryCatch returns Left on exception', () {
        final result = Either.tryCatch<String, int, FormatException>(
          (e) => 'parse error',
          () => int.parse('not-a-number'),
        );
        expect(result.isLeft, isTrue);
        expect(result.left, equals('parse error'));
      });

      test('cond returns Right when test is true', () {
        final result = Either.cond<String, int>(
          test: true,
          leftValue: 'error',
          rightValue: 42,
        );
        expect(result.isRight, isTrue);
        expect(result.right, equals(42));
      });

      test('cond returns Left when test is false', () {
        final result = Either.cond<String, int>(
          test: false,
          leftValue: 'error',
          rightValue: 42,
        );
        expect(result.isLeft, isTrue);
        expect(result.left, equals('error'));
      });
    });

    group('Equality', () {
      test('two Rights with same value are equal', () {
        const right1 = Right<String, int>(42);
        const right2 = Right<String, int>(42);
        expect(right1, equals(right2));
      });

      test('two Lefts with same value are equal', () {
        const left1 = Left<String, int>('error');
        const left2 = Left<String, int>('error');
        expect(left1, equals(left2));
      });

      test('Left and Right are not equal', () {
        const left = Left<int, int>(42);
        const right = Right<int, int>(42);
        expect(left, isNot(equals(right)));
      });
    });

    group('Async operations', () {
      test('mapAsync transforms value asynchronously', () async {
        const either = Right<String, int>(42);
        final result = await either.mapAsync((r) async => r * 2);
        expect(result.right, equals(84));
      });

      test('thenAsync chains asynchronously', () async {
        const either = Right<String, int>(42);
        final result = await either.thenAsync(
          (r) async => Right<String, String>('value: $r'),
        );
        expect(result.right, equals('value: 42'));
      });
    });
  });

  group('Failure', () {
    group('when', () {
      test('matches ServerFailure', () {
        const failure = ServerFailure(statusCode: 500);
        final result = failure.when(
          server: (f) => 'server: ${f.statusCode}',
          network: (_) => 'network',
          timeout: (_) => 'timeout',
          cancellation: (_) => 'cancelled',
          parsing: (_) => 'parsing',
          unknown: (_) => 'unknown',
        );
        expect(result, equals('server: 500'));
      });

      test('matches NoInternetFailure', () {
        const failure = NoInternetFailure();
        final result = failure.when(
          server: (_) => 'server',
          network: (_) => 'network',
          timeout: (_) => 'timeout',
          cancellation: (_) => 'cancelled',
          parsing: (_) => 'parsing',
          unknown: (_) => 'unknown',
        );
        expect(result, equals('network'));
      });

      test('matches TimeoutFailure', () {
        const failure = TimeoutFailure();
        final result = failure.when(
          server: (_) => 'server',
          network: (_) => 'network',
          timeout: (_) => 'timeout',
          cancellation: (_) => 'cancelled',
          parsing: (_) => 'parsing',
          unknown: (_) => 'unknown',
        );
        expect(result, equals('timeout'));
      });

      test('matches CancellationFailure', () {
        const failure = CancellationFailure();
        final result = failure.when(
          server: (_) => 'server',
          network: (_) => 'network',
          timeout: (_) => 'timeout',
          cancellation: (_) => 'cancelled',
          parsing: (_) => 'parsing',
          unknown: (_) => 'unknown',
        );
        expect(result, equals('cancelled'));
      });

      test('matches ParsingFailure', () {
        const failure = ParsingFailure();
        final result = failure.when(
          server: (_) => 'server',
          network: (_) => 'network',
          timeout: (_) => 'timeout',
          cancellation: (_) => 'cancelled',
          parsing: (_) => 'parsing',
          unknown: (_) => 'unknown',
        );
        expect(result, equals('parsing'));
      });

      test('matches UnknownFailure', () {
        const failure = UnknownFailure(message: 'something went wrong');
        final result = failure.when(
          server: (_) => 'server',
          network: (_) => 'network',
          timeout: (_) => 'timeout',
          cancellation: (_) => 'cancelled',
          parsing: (_) => 'parsing',
          unknown: (f) => 'unknown: ${f.message}',
        );
        expect(result, equals('unknown: something went wrong'));
      });
    });

    group('maybeWhen', () {
      test('uses handler when matched', () {
        const failure = ServerFailure(statusCode: 404);
        final result = failure.maybeWhen(
          server: (f) => 'handled: ${f.statusCode}',
          orElse: (_) => 'fallback',
        );
        expect(result, equals('handled: 404'));
      });

      test('uses orElse when not matched', () {
        const failure = ServerFailure(statusCode: 500);
        final result = failure.maybeWhen(
          network: (_) => 'network',
          orElse: (f) => 'fallback: ${f.message}',
        );
        expect(result, equals('fallback: Server error'));
      });
    });

    group('toString', () {
      test('ServerFailure includes statusCode', () {
        const failure = ServerFailure(message: 'Not found', statusCode: 404);
        expect(failure.toString(), contains('404'));
        expect(failure.toString(), contains('Not found'));
      });

      test('Failure includes message', () {
        const failure = NoInternetFailure();
        expect(failure.toString(), contains('NoInternetFailure'));
      });
    });
  });

  group('ErrorHandler (base)', () {
    test('handles TimeoutException as TimeoutFailure', () {
      final error = TimeoutException('Timed out');
      final failure = ErrorHandler.handle(error);
      expect(failure, isA<TimeoutFailure>());
    });

    test('handles FormatException as ParsingFailure', () {
      final error = const FormatException('Invalid format');
      final failure = ErrorHandler.handle(error);
      expect(failure, isA<ParsingFailure>());
    });

    test('handles TypeError as ParsingFailure', () {
      Object error;
      try {
        final dynamic value = 'not an int';
        // ignore: unnecessary_statements
        (value as List).length;
        error = Exception('Should not reach here');
      } on TypeError catch (e) {
        error = e;
      }
      final failure = ErrorHandler.handle(error);
      expect(failure, isA<ParsingFailure>());
    });

    test('handles unknown error as UnknownFailure', () {
      final error = Exception('Something went wrong');
      final failure = ErrorHandler.handle(error);
      expect(failure, isA<UnknownFailure>());
      expect(failure.message, contains('Something went wrong'));
    });

    test('preserves stack trace', () {
      final error = Exception('test');
      final st = StackTrace.current;
      final failure = ErrorHandler.handle(error, st);
      expect(failure.stackTrace, equals(st));
    });
  });

  group('RepositoryHandler', () {
    test('call returns Right on success', () async {
      final repository = _BaseRepository();
      final result = await repository.successCall();
      expect(result.isRight, isTrue);
      expect(result.right, equals(42));
    });

    test('call returns Left on exception', () async {
      final repository = _BaseRepository();
      final result = await repository.failingCall();
      expect(result.isLeft, isTrue);
      expect(result.left, isA<UnknownFailure>());
    });

    test('call captures stack trace', () async {
      final repository = _BaseRepository();
      final result = await repository.failingCall();
      expect(result.left.stackTrace, isNotNull);
    });

    test('uses default ErrorHandler.handle', () async {
      final repository = _BaseRepository();
      final result = await repository.timeoutCall();
      expect(result.left, isA<TimeoutFailure>());
    });

    test('supports custom errorMapper', () async {
      final repository = _CustomMapperRepository();
      final result = await repository.failingCall();
      expect(result.left, isA<ServerFailure>());
      expect(result.left.message, equals('Custom mapped'));
    });
  });
}

// Test helper: base repository with default error mapper
class _BaseRepository with RepositoryHandler {
  Future<Either<Failure, int>> successCall() {
    return call(() async => 42);
  }

  Future<Either<Failure, int>> failingCall() {
    return call(() async => throw Exception('Test error'));
  }

  Future<Either<Failure, int>> timeoutCall() {
    return call(() async => throw TimeoutException('Timed out'));
  }
}

// Test helper: repository with custom error mapper
class _CustomMapperRepository with RepositoryHandler {
  @override
  ErrorMapper get errorMapper => (error, st) => const ServerFailure(message: 'Custom mapped');

  Future<Either<Failure, int>> failingCall() {
    return call(() async => throw Exception('Test error'));
  }
}
