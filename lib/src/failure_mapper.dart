import 'dart:async';
import 'failure.dart';

/// Maps an error to a [Failure], or returns `null` if this mapper
/// does not handle the given error (passes it to the next in the chain).
typedef FailureMapper = Failure? Function(Object error, StackTrace stackTrace);

/// Built-in base mapper — handles standard Dart exceptions.
///
/// Always returns a non-null [Failure]. Use as the final fallback in a chain.
///
/// Handles:
/// - [TimeoutException] → [TimeoutFailure]
/// - [TypeError], [FormatException] → [ParsingFailure]
/// - Anything else → [UnknownFailure]
class BaseFailureMapper {
  const BaseFailureMapper._();

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

/// An ordered chain of [FailureMapper]s.
///
/// Each mapper is tried in order. The first non-null result wins.
/// If every mapper returns `null`, falls back to [BaseFailureMapper.handle].
///
/// Example — Dio + Drift + base:
/// ```dart
/// FailureMapperChain.base
///     .prepend(DioFailureMapper.handle)
///     .prepend(DriftFailureMapper.handle)
/// ```
class FailureMapperChain {
  final List<FailureMapper> _mappers;

  const FailureMapperChain(this._mappers);

  /// Chain containing only the built-in base fallback.
  static const FailureMapperChain base = FailureMapperChain([]);

  /// Convenience constructor for a single custom mapper.
  factory FailureMapperChain.of(FailureMapper mapper) => FailureMapperChain([mapper]);

  /// Returns a new chain with [mapper] inserted at the front (runs first).
  FailureMapperChain prepend(FailureMapper mapper) =>
      FailureMapperChain([mapper, ..._mappers]);

  /// Returns a new chain with [mapper] appended at the end (runs last before base).
  FailureMapperChain append(FailureMapper mapper) =>
      FailureMapperChain([..._mappers, mapper]);

  /// Runs mappers in order. Returns the first non-null result.
  /// Falls back to [BaseFailureMapper.handle] if all return null.
  Failure handle(Object error, StackTrace stackTrace) {
    for (final mapper in _mappers) {
      final result = mapper(error, stackTrace);
      if (result != null) return result;
    }
    return BaseFailureMapper.handle(error, stackTrace);
  }
}
