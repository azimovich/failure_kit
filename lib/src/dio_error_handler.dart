import 'dart:io';
import 'failure.dart';
import 'error_handler.dart';
import 'package:dio/dio.dart';

/// Dio-specific error handler that extends [ErrorHandler] with Dio support.
///
/// Handles all [DioException] types and [SocketException] in addition
/// to the base Dart exceptions handled by [ErrorHandler].
///
/// Import via:
/// ```dart
/// import 'package:dart_failure_handler/dio.dart';
/// ```
///
/// Handles the following exception types:
/// - [DioException] → [ServerFailure], [NoInternetFailure], [TimeoutFailure], or [CancellationFailure]
/// - [SocketException] → [NoInternetFailure]
/// - All other exceptions → delegated to [ErrorHandler.handle]
///
/// Example:
/// ```dart
/// try {
///   await dio.get('/api/data');
/// } catch (e, st) {
///   final failure = DioErrorHandler.handle(e, st);
/// }
/// ```
class DioErrorHandler {
  const DioErrorHandler._();

  /// Maps Dio and socket exceptions to typed [Failure] objects.
  ///
  /// Falls back to [ErrorHandler.handle] for non-Dio exceptions.
  static Failure handle(Object error, [StackTrace? stackTrace]) {
    if (error is DioException) {
      return _handleDioError(error, stackTrace);
    }

    if (error is SocketException) {
      return NoInternetFailure(cause: error, stackTrace: stackTrace);
    }

    // Delegate to base ErrorHandler for other exceptions
    return ErrorHandler.handle(error, stackTrace);
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
