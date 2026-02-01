import 'dart:io';
import 'dart:async';
import 'failure.dart';
import 'package:dio/dio.dart';

/// Helper class to transform [Object] errors into [Failure] objects.
class ErrorHandler {
  /// Maps various exception types (Dio, Socket, etc.) to a [Failure].
  static Failure handle(Object error, [StackTrace? stackTrace]) {
    if (error is DioException) {
      return _handleDioError(error, stackTrace);
    }

    if (error is SocketException || error is TimeoutException) {
      return NoInternetFailure(cause: error, stackTrace: stackTrace);
    }

    if (error is TypeError || error is FormatException) {
      return ParsingFailure(cause: error, stackTrace: stackTrace);
    }

    return UnknownFailure(message: error.toString(), cause: error, stackTrace: stackTrace);
  }

  static Failure _handleDioError(DioException error, StackTrace? st) {
    if (error.type == DioExceptionType.connectionError || error.type == DioExceptionType.connectionTimeout) {
      return NoInternetFailure(cause: error, stackTrace: st);
    }

    final response = error.response;
    String message = error.message ?? "Unexpected server error";

    if (response?.data is Map) {
      message = response?.data['message'] ?? response?.data['error'] ?? message;
    }

    return ServerFailure(message: message, statusCode: response?.statusCode, cause: error, stackTrace: st);
  }
}
