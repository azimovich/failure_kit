import 'dart:io';

import 'package:dart_failure_handler/dio.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  group('DioErrorHandler', () {
    test('handles SocketException as NoInternetFailure', () {
      final error = SocketException('Connection refused');
      final failure = DioErrorHandler.handle(error);
      expect(failure, isA<NoInternetFailure>());
    });

    test('delegates TimeoutException to base ErrorHandler', () {
      final failure = DioErrorHandler.handle(Exception('unknown'));
      expect(failure, isA<UnknownFailure>());
    });

    test('delegates FormatException to base ErrorHandler', () {
      final failure = DioErrorHandler.handle(const FormatException('bad'));
      expect(failure, isA<ParsingFailure>());
    });

    group('DioException handling', () {
      test('connectionError becomes NoInternetFailure', () {
        final error = DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(path: '/test'),
        );
        final failure = DioErrorHandler.handle(error);
        expect(failure, isA<NoInternetFailure>());
      });

      test('connectionTimeout becomes TimeoutFailure', () {
        final error = DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: '/test'),
        );
        final failure = DioErrorHandler.handle(error);
        expect(failure, isA<TimeoutFailure>());
      });

      test('sendTimeout becomes TimeoutFailure', () {
        final error = DioException(
          type: DioExceptionType.sendTimeout,
          requestOptions: RequestOptions(path: '/test'),
        );
        final failure = DioErrorHandler.handle(error);
        expect(failure, isA<TimeoutFailure>());
      });

      test('receiveTimeout becomes TimeoutFailure', () {
        final error = DioException(
          type: DioExceptionType.receiveTimeout,
          requestOptions: RequestOptions(path: '/test'),
        );
        final failure = DioErrorHandler.handle(error);
        expect(failure, isA<TimeoutFailure>());
      });

      test('cancel becomes CancellationFailure', () {
        final error = DioException(
          type: DioExceptionType.cancel,
          requestOptions: RequestOptions(path: '/test'),
        );
        final failure = DioErrorHandler.handle(error);
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
        final failure = DioErrorHandler.handle(error);
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
        final failure = DioErrorHandler.handle(error);
        expect(failure, isA<ServerFailure>());
        expect(failure.message, equals('Internal error'));
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
        final failure = DioErrorHandler.handle(error);
        expect(failure, isA<ServerFailure>());
        expect(failure.message, equals('Bad request'));
      });

      test('badResponse with non-Map data uses error message', () {
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
        final failure = DioErrorHandler.handle(error);
        expect(failure, isA<ServerFailure>());
        expect(failure.message, equals('Server error occurred'));
      });
    });
  });

  group('DioRepositoryHandler', () {
    test('uses DioErrorHandler for error mapping', () async {
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
}
