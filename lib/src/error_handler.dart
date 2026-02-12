import 'dart:async';
import 'failure.dart';

/// Type definition for custom error mapping functions.
///
/// Used by [RepositoryHandler] to allow plugging in different
/// error handling strategies (e.g., Dio, http, Chopper, etc.).
///
/// Example:
/// ```dart
/// final ErrorMapper myMapper = (error, st) {
///   if (error is MyCustomException) {
///     return ServerFailure(message: error.message);
///   }
///   return ErrorHandler.handle(error, st);
/// };
/// ```
typedef ErrorMapper = Failure Function(Object error, StackTrace stackTrace);

/// Base error handler for pure Dart exceptions.
///
/// This handler is HTTP-client agnostic and only handles standard
/// Dart/Flutter exceptions. For Dio-specific handling, use [DioErrorHandler]
/// from `package:dart_failure_handler/dio.dart`.
///
/// Handles the following exception types:
/// - [TimeoutException] → [TimeoutFailure]
/// - [TypeError], [FormatException] → [ParsingFailure]
/// - Other exceptions → [UnknownFailure]
///
/// Example:
/// ```dart
/// try {
///   await someAsyncOperation();
/// } catch (e, st) {
///   final failure = ErrorHandler.handle(e, st);
/// }
/// ```
class ErrorHandler {
  const ErrorHandler._();

  /// Maps common Dart exception types to typed [Failure] objects.
  static Failure handle(Object error, [StackTrace? stackTrace]) {
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
}
