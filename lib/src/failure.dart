import 'package:meta/meta.dart';

/// Base class for all application failures.
@immutable
sealed class Failure {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  const Failure({required this.message, this.cause, this.stackTrace});

  /// Pattern matching to handle different failure types explicitly.
  ///
  /// Example:
  /// ```dart
  /// failure.when(
  ///   server: (f) => print(f.statusCode),
  ///   network: (f) => print('No Internet'),
  ///   parsing: (f) => print('Data Error'),
  ///   unknown: (f) => print(f.message),
  /// );
  /// ```
  T when<T>({
    required T Function(ServerFailure f) server,
    required T Function(NoInternetFailure f) network,
    required T Function(ParsingFailure f) parsing,
    required T Function(Failure f) unknown,
  }) {
    return switch (this) {
      ServerFailure f => server(f),
      NoInternetFailure f => network(f),
      ParsingFailure f => parsing(f),
      _ => unknown(this),
    };
  }
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure({super.message = "Server error", this.statusCode, super.cause, super.stackTrace});
}

class NoInternetFailure extends Failure {
  const NoInternetFailure({super.message = "No internet connection", super.cause, super.stackTrace});
}

class ParsingFailure extends Failure {
  const ParsingFailure({super.message = "Parsing error", super.cause, super.stackTrace});
}

class UnknownFailure extends Failure {
  const UnknownFailure({required super.message, super.cause, super.stackTrace});
}
