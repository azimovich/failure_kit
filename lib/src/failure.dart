import 'package:meta/meta.dart';

/// Base class for all application failures.
///
/// This sealed class provides a type-safe way to handle errors in your application.
/// All failure types extend this class and can be pattern matched using [when] or [maybeWhen].
@immutable
sealed class Failure {
  /// Human-readable error message
  final String message;

  /// The original error/exception that caused this failure
  final Object? cause;

  /// Stack trace from when the error occurred
  final StackTrace? stackTrace;

  const Failure({required this.message, this.cause, this.stackTrace});

  /// Pattern matching to handle different failure types explicitly.
  /// All cases must be handled.
  ///
  /// Example:
  /// ```dart
  /// failure.when(
  ///   server: (f) => print(f.statusCode),
  ///   network: (f) => print('No Internet'),
  ///   timeout: (f) => print('Request timed out'),
  ///   cancellation: (f) => print('Request cancelled'),
  ///   parsing: (f) => print('Data Error'),
  ///   unknown: (f) => print(f.message),
  /// );
  /// ```
  T when<T>({
    required T Function(ServerFailure f) server,
    required T Function(NoInternetFailure f) network,
    required T Function(TimeoutFailure f) timeout,
    required T Function(CancellationFailure f) cancellation,
    required T Function(ParsingFailure f) parsing,
    required T Function(UnknownFailure f) unknown,
  }) {
    return switch (this) {
      ServerFailure f => server(f),
      NoInternetFailure f => network(f),
      TimeoutFailure f => timeout(f),
      CancellationFailure f => cancellation(f),
      ParsingFailure f => parsing(f),
      UnknownFailure f => unknown(f),
    };
  }

  /// Optional pattern matching - only handle the cases you care about.
  /// Returns [orElse] for unhandled cases.
  ///
  /// Example:
  /// ```dart
  /// final message = failure.maybeWhen(
  ///   server: (f) => 'Server error: ${f.statusCode}',
  ///   network: (_) => 'Check your connection',
  ///   orElse: (f) => f.message,
  /// );
  /// ```
  T maybeWhen<T>({
    T Function(ServerFailure f)? server,
    T Function(NoInternetFailure f)? network,
    T Function(TimeoutFailure f)? timeout,
    T Function(CancellationFailure f)? cancellation,
    T Function(ParsingFailure f)? parsing,
    T Function(UnknownFailure f)? unknown,
    required T Function(Failure f) orElse,
  }) {
    return switch (this) {
      ServerFailure f => server?.call(f) ?? orElse(f),
      NoInternetFailure f => network?.call(f) ?? orElse(f),
      TimeoutFailure f => timeout?.call(f) ?? orElse(f),
      CancellationFailure f => cancellation?.call(f) ?? orElse(f),
      ParsingFailure f => parsing?.call(f) ?? orElse(f),
      UnknownFailure f => unknown?.call(f) ?? orElse(f),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other.runtimeType == runtimeType && other is Failure && other.message == message);

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() => '$runtimeType(message: $message)';
}

/// Failure representing server/API errors with HTTP status codes.
class ServerFailure extends Failure {
  /// HTTP status code (e.g., 400, 401, 500)
  final int? statusCode;

  const ServerFailure({
    super.message = 'Server error',
    this.statusCode,
    super.cause,
    super.stackTrace,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ServerFailure && other.message == message && other.statusCode == statusCode);

  @override
  int get hashCode => Object.hash(runtimeType, message, statusCode);

  @override
  String toString() => 'ServerFailure(message: $message, statusCode: $statusCode)';
}

/// Failure representing network connectivity issues.
class NoInternetFailure extends Failure {
  const NoInternetFailure({
    super.message = 'No internet connection',
    super.cause,
    super.stackTrace,
  });
}

/// Failure representing request timeout.
class TimeoutFailure extends Failure {
  const TimeoutFailure({
    super.message = 'Request timed out',
    super.cause,
    super.stackTrace,
  });
}

/// Failure representing cancelled requests.
class CancellationFailure extends Failure {
  const CancellationFailure({
    super.message = 'Request was cancelled',
    super.cause,
    super.stackTrace,
  });
}

/// Failure representing data parsing/serialization errors.
class ParsingFailure extends Failure {
  const ParsingFailure({
    super.message = 'Parsing error',
    super.cause,
    super.stackTrace,
  });
}

/// Failure for unexpected/unknown errors.
class UnknownFailure extends Failure {
  const UnknownFailure({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}
