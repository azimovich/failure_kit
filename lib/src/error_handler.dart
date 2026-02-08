import 'dart:io';
import 'dart:async';
import 'failure.dart';
import 'package:dio/dio.dart';

/// Helper class to transform [Object] errors into [Failure] objects.
///
/// This class provides a centralized way to convert various exception types
/// into typed [Failure] objects for consistent error handling.
///
/// Example:
/// ```dart
/// try {
///   await dio.get('/api/data');
/// } catch (e, st) {
///   final failure = ErrorHandler.handle(e, st);
///   // Handle the failure...
/// }
/// ```
class ErrorHandler {
  const ErrorHandler._();

  /// Maps various exception types (Dio, Socket, etc.) to a [Failure].
  ///
  /// Handles the following exception types:
  /// - [DioException] → [ServerFailure], [NoInternetFailure], [TimeoutFailure], or [CancellationFailure]
  /// - [SocketException] → [NoInternetFailure]
  /// - [TimeoutException] → [TimeoutFailure]
  /// - [TypeError], [FormatException] → [ParsingFailure]
  /// - Other exceptions → [UnknownFailure]
  static Failure handle(Object error, [StackTrace? stackTrace]) {
    if (error is DioException) {
      return _handleDioError(error, stackTrace);
    }

    if (error is SocketException) {
      return NoInternetFailure(cause: error, stackTrace: stackTrace);
    }

    if (error is TimeoutException) {
      return TimeoutFailure(cause: error, stackTrace: stackTrace);
    }

    if (error is TypeError || error is FormatException) {
      return ParsingFailure(cause: error, stackTrace: stackTrace);
    }

    return UnknownFailure(
      message: error.toString(),
      cause: error,
      stackTrace: stackTrace,
    );
  }

  static Failure _handleDioError(DioException error, StackTrace? st) {
    return switch (error.type) {
      DioExceptionType.connectionError => NoInternetFailure(
          cause: error,
          stackTrace: st,
        ),
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        TimeoutFailure(
          message: 'Request timed out: ${error.message}',
          cause: error,
          stackTrace: st,
        ),
      DioExceptionType.cancel => CancellationFailure(
          cause: error,
          stackTrace: st,
        ),
      _ => _handleServerError(error, st),
    };
  }

  static Failure _handleServerError(DioException error, StackTrace? st) {
    final response = error.response;
    String message = error.message ?? 'Unexpected server error';

    if (response?.data is Map) {
      final data = response!.data as Map;
      message = data['message']?.toString() ?? data['error']?.toString() ?? data['msg']?.toString() ?? message;
    }

    return ServerFailure(
      message: message,
      statusCode: response?.statusCode,
      cause: error,
      stackTrace: st,
    );
  }
}
