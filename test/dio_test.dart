import 'dart:io';

import 'package:dart_failure_handler/dio.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  group('DioErrorMapper', () {
    test('handles SocketException as NoInternetFailure', () {
      final error = SocketException('Connection refused');
      final failure = DioErrorMapper.handle(error, StackTrace.current);
      expect(failure, isA<NoInternetFailure>());
    });

    test('returns null for non-Dio Exception', () {
      final result = DioErrorMapper.handle(Exception('unknown'), StackTrace.current);
      expect(result, isNull);
    });

    test('returns null for FormatException', () {
      final result = DioErrorMapper.handle(const FormatException('bad'), StackTrace.current);
      expect(result, isNull);
    });

    group('DioException handling', () {
      test('connectionError becomes NoInternetFailure', () {
        final error = DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(path: '/test'),
        );
        final failure = DioErrorMapper.handle(error, StackTrace.current);
        expect(failure, isA<NoInternetFailure>());
      });

      test('connectionTimeout becomes TimeoutFailure', () {
        final error = DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: '/test'),
        );
        final failure = DioErrorMapper.handle(error, StackTrace.current);
        expect(failure, isA<TimeoutFailure>());
      });

      test('sendTimeout becomes TimeoutFailure', () {
        final error = DioException(
          type: DioExceptionType.sendTimeout,
          requestOptions: RequestOptions(path: '/test'),
        );
        final failure = DioErrorMapper.handle(error, StackTrace.current);
        expect(failure, isA<TimeoutFailure>());
      });

      test('receiveTimeout becomes TimeoutFailure', () {
        final error = DioException(
          type: DioExceptionType.receiveTimeout,
          requestOptions: RequestOptions(path: '/test'),
        );
        final failure = DioErrorMapper.handle(error, StackTrace.current);
        expect(failure, isA<TimeoutFailure>());
      });

      test('cancel becomes CancellationFailure', () {
        final error = DioException(
          type: DioExceptionType.cancel,
          requestOptions: RequestOptions(path: '/test'),
        );
        final failure = DioErrorMapper.handle(error, StackTrace.current);
        expect(failure, isA<CancellationFailure>());
      });

      test('badResponse becomes ServerFailure with statusCode', () {
        final error = DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            statusCode: 404,
            requestOptions: RequestOptions(path: '/test'),
            data: {'message': 'User not found'},
          ),
        );
        final failure = DioErrorMapper.handle(error, StackTrace.current);
        expect(failure, isA<ServerFailure>());
        expect((failure as ServerFailure).statusCode, equals(404));
        expect(failure.message, equals('User not found'));
      });

      test('badResponse extracts error field', () {
        final error = DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(path: '/test'),
            data: {'error': 'Internal error'},
          ),
        );
        final failure = DioErrorMapper.handle(error, StackTrace.current);
        expect(failure, isA<ServerFailure>());
        expect(failure!.message, equals('Internal error'));
      });

      test('badResponse extracts msg field', () {
        final error = DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            statusCode: 400,
            requestOptions: RequestOptions(path: '/test'),
            data: {'msg': 'Bad request'},
          ),
        );
        final failure = DioErrorMapper.handle(error, StackTrace.current);
        expect(failure, isA<ServerFailure>());
        expect(failure!.message, equals('Bad request'));
      });

      test('badResponse with non-Map data uses status code message', () {
        final error = DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: '/test'),
          message: 'Server error occurred',
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(path: '/test'),
            data: 'Not a map',
          ),
        );
        final failure = DioErrorMapper.handle(error, StackTrace.current);
        expect(failure, isA<ServerFailure>());
        expect(failure!.message, equals('Server error (500)'));
      });

      test('DioException with SocketException inner error becomes NoInternetFailure', () {
        final error = DioException(
          type: DioExceptionType.unknown,
          requestOptions: RequestOptions(path: '/test'),
          error: const SocketException('Network unreachable'),
        );
        final failure = DioErrorMapper.handle(error, StackTrace.current);
        expect(failure, isA<NoInternetFailure>());
      });

      test('badCertificate becomes UnknownFailure', () {
        final error = DioException(
          type: DioExceptionType.badCertificate,
          requestOptions: RequestOptions(path: '/test'),
          message: 'SSL handshake failed',
        );
        final failure = DioErrorMapper.handle(error, StackTrace.current);
        expect(failure, isA<UnknownFailure>());
        expect(failure!.message, contains('Bad certificate'));
      });

      test('non-Dio error in chain falls through to BaseErrorMapper', () {
        final chain = ErrorMapperChain.base.prepend(DioErrorMapper.handle);
        final failure = chain.handle(
          const FormatException('bad json'),
          StackTrace.current,
        );
        expect(failure, isA<ParsingFailure>());
      });
    });
  });

  group('DioRepositoryHandler', () {
    test('uses DioErrorMapper for error mapping', () async {
      final repository = _DioTestRepository();
      final result = await repository.connectionErrorCall();
      expect(result.left, isA<NoInternetFailure>());
    });

    test('call returns Right on success', () async {
      final repository = _DioTestRepository();
      final result = await repository.successCall();
      expect(result.isRight, isTrue);
      expect(result.right, equals('success'));
    });

    test('handles DioException timeout', () async {
      final repository = _DioTestRepository();
      final result = await repository.timeoutCall();
      expect(result.left, isA<TimeoutFailure>());
    });

    test('handles DioException cancel', () async {
      final repository = _DioTestRepository();
      final result = await repository.cancelCall();
      expect(result.left, isA<CancellationFailure>());
    });

    test('non-Dio error falls through to BaseErrorMapper', () async {
      final repository = _DioTestRepository();
      final result = await repository.formatExceptionCall();
      expect(result.left, isA<ParsingFailure>());
    });
  });
}

// Test helper: Dio repository
class _DioTestRepository with RepositoryHandler, DioRepositoryHandler {
  Future<Either<Failure, String>> successCall() {
    return call(() async => 'success');
  }

  Future<Either<Failure, String>> connectionErrorCall() {
    return call(() async => throw DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(path: '/test'),
        ));
  }

  Future<Either<Failure, String>> timeoutCall() {
    return call(() async => throw DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: '/test'),
        ));
  }

  Future<Either<Failure, String>> cancelCall() {
    return call(() async => throw DioException(
          type: DioExceptionType.cancel,
          requestOptions: RequestOptions(path: '/test'),
        ));
  }

  Future<Either<Failure, String>> formatExceptionCall() {
    return call(() async => throw const FormatException('bad json'));
  }
}
