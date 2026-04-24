import 'dart:async';

import 'package:failure_kit/failure_kit.dart';
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

      test('left getter throws StateError', () {
        const either = Right<String, int>(42);
        expect(() => either.left, throwsStateError);
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

      test('right getter throws StateError', () {
        const either = Left<String, int>('error');
        expect(() => either.right, throwsStateError);
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

      test('Left and Right are not equal even with same value', () {
        const left = Left<int, int>(42);
        const right = Right<int, int>(42);
        expect(left, isNot(equals(right)));
      });

      test('Left and Right have different hashCodes for same value', () {
        const left = Left<int, int>(42);
        const right = Right<int, int>(42);
        expect(left.hashCode, isNot(equals(right.hashCode)));
      });

      test('two Rights with different values are not equal', () {
        const right1 = Right<String, int>(42);
        const right2 = Right<String, int>(99);
        expect(right1, isNot(equals(right2)));
      });
    });

    group('Nullable accessors', () {
      test('rightOrNull returns value on Right', () {
        const either = Right<String, int>(42);
        expect(either.rightOrNull, equals(42));
      });

      test('rightOrNull returns null on Left', () {
        const either = Left<String, int>('error');
        expect(either.rightOrNull, isNull);
      });

      test('leftOrNull returns value on Left', () {
        const either = Left<String, int>('error');
        expect(either.leftOrNull, equals('error'));
      });

      test('leftOrNull returns null on Right', () {
        const either = Right<String, int>(42);
        expect(either.leftOrNull, isNull);
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
          custom: (_) => 'custom',
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
          custom: (_) => 'custom',
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
          custom: (_) => 'custom',
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
          custom: (_) => 'custom',
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
          custom: (_) => 'custom',
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
          custom: (_) => 'custom',
        );
        expect(result, equals('unknown: something went wrong'));
      });

      test('routes user-defined Failure subclass to custom:', () {
        final failure = _CustomFailure();
        final result = failure.when(
          server: (_) => 'server',
          network: (_) => 'network',
          timeout: (_) => 'timeout',
          cancellation: (_) => 'cancelled',
          parsing: (_) => 'parsing',
          unknown: (_) => 'unknown',
          custom: (f) => 'custom: ${f.message}',
        );
        expect(result, equals('custom: custom error'));
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

      test('user-defined Failure subclass falls through to orElse', () {
        final failure = _CustomFailure();
        final result = failure.maybeWhen(
          server: (_) => 'server',
          orElse: (f) => 'orElse: ${f.message}',
        );
        expect(result, equals('orElse: custom error'));
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

    group('Equality', () {
      test('same ServerFailure instances are equal', () {
        const f1 = ServerFailure(message: 'Not found', statusCode: 404);
        const f2 = ServerFailure(message: 'Not found', statusCode: 404);
        expect(f1, equals(f2));
      });

      test('ServerFailures with different statusCode are not equal', () {
        const f1 = ServerFailure(message: 'Error', statusCode: 404);
        const f2 = ServerFailure(message: 'Error', statusCode: 500);
        expect(f1, isNot(equals(f2)));
      });

      test('same NoInternetFailure instances are equal', () {
        const f1 = NoInternetFailure();
        const f2 = NoInternetFailure();
        expect(f1, equals(f2));
      });

      test('different Failure types are not equal even with same message', () {
        const f1 = TimeoutFailure(message: 'error');
        const f2 = ParsingFailure(message: 'error');
        expect(f1, isNot(equals(f2)));
      });

      test('equal Failures have same hashCode', () {
        const f1 = ServerFailure(message: 'err', statusCode: 500);
        const f2 = ServerFailure(message: 'err', statusCode: 500);
        expect(f1.hashCode, equals(f2.hashCode));
      });
    });
  });

  group('BaseFailureMapper', () {
    test('handles TimeoutException as TimeoutFailure', () {
      final error = TimeoutException('Timed out');
      final failure = BaseFailureMapper.handle(error, StackTrace.current);
      expect(failure, isA<TimeoutFailure>());
    });

    test('handles FormatException as ParsingFailure', () {
      final error = const FormatException('Invalid format');
      final failure = BaseFailureMapper.handle(error, StackTrace.current);
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
      final failure = BaseFailureMapper.handle(error, StackTrace.current);
      expect(failure, isA<ParsingFailure>());
    });

    test('handles unknown error as UnknownFailure', () {
      final error = Exception('Something went wrong');
      final failure = BaseFailureMapper.handle(error, StackTrace.current);
      expect(failure, isA<UnknownFailure>());
      expect(failure.message, contains('Something went wrong'));
    });

    test('preserves stack trace', () {
      final error = Exception('test');
      final st = StackTrace.current;
      final failure = BaseFailureMapper.handle(error, st);
      expect(failure.stackTrace, equals(st));
    });
  });

  group('FailureMapperChain', () {
    test('base chain falls through to BaseFailureMapper', () {
      final failure = FailureMapperChain.base.handle(
        const FormatException('bad'),
        StackTrace.current,
      );
      expect(failure, isA<ParsingFailure>());
    });

    test('prepend mapper runs first', () {
      final chain = FailureMapperChain.base.prepend(
        (e, st) => e is FormatException
            ? const ServerFailure(message: 'intercepted')
            : null,
      );
      final failure = chain.handle(
        const FormatException('bad'),
        StackTrace.current,
      );
      expect(failure, isA<ServerFailure>());
      expect(failure.message, equals('intercepted'));
    });

    test('null from mapper passes to next', () {
      final chain = FailureMapperChain.base
          .prepend((e, st) => null)
          .prepend((e, st) => null);
      final failure = chain.handle(
        const FormatException('bad'),
        StackTrace.current,
      );
      expect(failure, isA<ParsingFailure>());
    });

    test('prepend order: first prepended runs last', () {
      final calls = <String>[];
      final chain = FailureMapperChain.base
          .prepend((e, st) {
            calls.add('second');
            return null;
          })
          .prepend((e, st) {
            calls.add('first');
            return null;
          });
      chain.handle(Exception('x'), StackTrace.current);
      expect(calls, equals(['first', 'second']));
    });

    test('append adds mapper after existing ones', () {
      final calls = <String>[];
      final chain = FailureMapperChain.base
          .prepend((e, st) {
            calls.add('first');
            return null;
          })
          .append((e, st) {
            calls.add('appended');
            return null;
          });
      chain.handle(Exception('x'), StackTrace.current);
      expect(calls, equals(['first', 'appended']));
    });

    test('custom Failure from user mapper is returned', () {
      final chain = FailureMapperChain.base.prepend(
        (e, st) => e is Exception ? _CustomFailure() : null,
      );
      final failure = chain.handle(Exception('x'), StackTrace.current);
      expect(failure, isA<_CustomFailure>());
    });
  });

  group('FailureGuard', () {
    test('call returns Right on success', () async {
      final guard = _BaseGuard();
      final result = await guard.successCall();
      expect(result.isRight, isTrue);
      expect(result.right, equals(42));
    });

    test('call returns Left on exception', () async {
      final guard = _BaseGuard();
      final result = await guard.failingCall();
      expect(result.isLeft, isTrue);
      expect(result.left, isA<UnknownFailure>());
    });

    test('call captures stack trace', () async {
      final guard = _BaseGuard();
      final result = await guard.failingCall();
      expect(result.left.stackTrace, isNotNull);
    });

    test('uses BaseFailureMapper by default', () async {
      final guard = _BaseGuard();
      final result = await guard.timeoutCall();
      expect(result.left, isA<TimeoutFailure>());
    });

    test('custom failureChain intercepts errors', () async {
      final guard = _CustomChainGuard();
      final result = await guard.failingCall();
      expect(result.left, isA<ServerFailure>());
      expect(result.left.message, equals('Custom mapped'));
    });
  });
}

// ---------- Test helpers ----------

class _CustomFailure extends Failure {
  _CustomFailure() : super(message: 'custom error');
}

class _BaseGuard with FailureGuard {
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

class _CustomChainGuard with FailureGuard {
  @override
  FailureMapperChain get failureChain => FailureMapperChain.base.prepend(
        (error, st) => const ServerFailure(message: 'Custom mapped'),
      );

  Future<Either<Failure, int>> failingCall() {
    return call(() async => throw Exception('Test error'));
  }
}
