import 'dart:io';
import 'failure.dart';
import 'failure_mapper.dart';
import 'package:dio/dio.dart';

/// Dio-specific [FailureMapper] — maps [DioException] and [SocketException]
/// to typed [Failure] objects.
///
/// Returns `null` for any error that is not Dio-related, allowing the next
/// mapper in the chain (or [BaseFailureMapper]) to handle it.
///
/// Import via:
/// ```dart
/// import 'package:failure_kit/dio.dart';
/// ```
///
/// Handles:
/// - [DioException] → [ServerFailure], [NoInternetFailure], [TimeoutFailure],
///   or [CancellationFailure]
/// - [SocketException] → [NoInternetFailure]
/// - Anything else → `null` (not handled — passed to next mapper)
///
/// Example — manual use:
/// ```dart
/// final failure = DioFailureMapper.handle(e, st) ?? BaseFailureMapper.handle(e, st);
/// ```
///
/// Example — via chain:
/// ```dart
/// FailureMapperChain.base.prepend(DioFailureMapper.handle)
/// ```
class DioFailureMapper {
  const DioFailureMapper._();

  /// Conforms to [FailureMapper]. Returns `null` for non-Dio errors.
  static Failure? handle(Object error, StackTrace stackTrace) {
    if (error is DioException) {
      return _handleDioError(error, stackTrace);
    }
    if (error is SocketException) {
      return NoInternetFailure(cause: error, stackTrace: stackTrace);
    }
    return null;
  }

  static Failure _handleDioError(DioException error, StackTrace st) {
    if (error.error is SocketException) {
      return NoInternetFailure(cause: error, stackTrace: st);
    }

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
      DioExceptionType.badCertificate => UnknownFailure(
          message: 'Bad certificate: ${error.message ?? 'SSL error'}',
          cause: error,
          stackTrace: st,
        ),
      _ => _handleServerError(error, st),
    };
  }

  static Failure _handleServerError(DioException error, StackTrace st) {
    final response = error.response;
    final statusCode = response?.statusCode;
    String message =
        statusCode != null ? 'Server error ($statusCode)' : 'Unexpected server error';

    if (response?.data is Map) {
      final data = response!.data as Map;
      message = data['message']?.toString() ??
          data['error']?.toString() ??
          data['msg']?.toString() ??
          message;
    }

    return ServerFailure(
      message: message,
      statusCode: statusCode,
      data: response?.data,
      cause: error,
      stackTrace: st,
    );
  }
}
