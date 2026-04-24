import 'dart:async';
import 'failure.dart';

/// Maps an error to a [Failure], or returns `null` if this mapper
/// does not handle the given error (passes it to the next in the chain).
typedef ErrorMapper = Failure? Function(Object error, StackTrace stackTrace);

/// Built-in base mapper — handles standard Dart exceptions.
///
/// Always returns a non-null [Failure]. Use as the final fallback in a chain.
///
/// Handles:
/// - [TimeoutException] → [TimeoutFailure]
/// - [TypeError], [FormatException] → [ParsingFailure]
/// - Anything else → [UnknownFailure]
class BaseErrorMapper {
  const BaseErrorMapper._();

  static Failure handle(Object error, StackTrace stackTrace) {
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

/// An ordered chain of [ErrorMapper]s.
///
/// Each mapper is tried in order. The first non-null result wins.
/// If every mapper returns `null`, falls back to [BaseErrorMapper.handle].
///
/// Example — Dio + Drift + base:
/// ```dart
/// ErrorMapperChain.base
///     .prepend(DioErrorMapper.handle)
///     .prepend(DriftErrorMapper.handle)
/// ```
class ErrorMapperChain {
  final List<ErrorMapper> _mappers;

  const ErrorMapperChain(this._mappers);

  /// Chain containing only the built-in base fallback.
  static const ErrorMapperChain base = ErrorMapperChain([]);

  /// Convenience constructor for a single custom mapper.
  factory ErrorMapperChain.of(ErrorMapper mapper) => ErrorMapperChain([mapper]);

  /// Returns a new chain with [mapper] inserted at the front (runs first).
  ErrorMapperChain prepend(ErrorMapper mapper) =>
      ErrorMapperChain([mapper, ..._mappers]);

  /// Returns a new chain with [mapper] appended at the end (runs last before base).
  ErrorMapperChain append(ErrorMapper mapper) =>
      ErrorMapperChain([..._mappers, mapper]);

  /// Runs mappers in order. Returns the first non-null result.
  /// Falls back to [BaseErrorMapper.handle] if all return null.
  Failure handle(Object error, StackTrace stackTrace) {
    for (final mapper in _mappers) {
      final result = mapper(error, stackTrace);
      if (result != null) return result;
    }
    return BaseErrorMapper.handle(error, stackTrace);
  }
}
