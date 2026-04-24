import 'dart:async';
import 'package:meta/meta.dart';

typedef Lazy<T> = T Function();

/// Represents a value of one of two possible types.
/// Instances of [Either] are either an instance of [Left] or [Right].
///
/// [Left] is used for "failure".
/// [Right] is used for "success".
@immutable
sealed class Either<L, R> {
  const Either();

  /// Represents the left side of [Either] class which
  /// by convention is a "Failure".
  bool get isLeft => this is Left<L, R>;

  /// Represents the right side of [Either] class which
  /// by convention is a "Success"
  bool get isRight => this is Right<L, R>;

  /// Get [Left] value, may throw an exception when the value is [Right]
  L get left => fold<L>(
        (L value) => value,
        (R right) => throw StateError('Called .left on a Right. Check isLeft before accessing.'),
      );

  /// Get [Right] value or return [defaultValue] if [Left]
  R getOrElse(R defaultValue) => fold((_) => defaultValue, (r) => r);

  /// Get [Right] value or compute from [defaultValue] function if [Left]
  R getOrElseCompute(R Function(L left) defaultValue) => fold(defaultValue, (r) => r);

  /// Get [Left] value or return [defaultValue] if [Right]
  L getLeftOrElse(L defaultValue) => fold((l) => l, (_) => defaultValue);

  /// Get [Right] value, may throw an exception when the value is [Left]
  R get right => fold<R>(
        (L left) => throw StateError('Called .right on a Left. Check isRight before accessing.'),
        (R value) => value,
      );

  /// Get [Right] value or null if [Left]
  R? get rightOrNull => fold((_) => null, (r) => r);

  /// Get [Left] value or null if [Right]
  L? get leftOrNull => fold((l) => l, (_) => null);

  /// Transform values of [Left] and [Right]
  Either<TL, TR> either<TL, TR>(TL Function(L left) fnL, TR Function(R right) fnR);

  Either<L, TR> then<TR>(Either<L, TR> Function(R right) fnR);

  Future<Either<L, TR>> thenAsync<TR>(FutureOr<Either<L, TR>> Function(R right) fnR);

  Either<TL, R> thenLeft<TL>(Either<TL, R> Function(L left) fnL);

  Future<Either<TL, R>> thenLeftAsync<TL>(FutureOr<Either<TL, R>> Function(L left) fnL);

  /// Transform value of [Right]
  Either<L, TR> map<TR>(TR Function(R right) fnR);

  /// Transform value of [Left]
  Either<TL, R> mapLeft<TL>(TL Function(L left) fnL);

  /// Transform value of [Right]
  Future<Either<L, TR>> mapAsync<TR>(FutureOr<TR> Function(R right) fnR);

  /// Transform value of [Left]
  Future<Either<TL, R>> mapLeftAsync<TL>(FutureOr<TL> Function(L left) fnL);

  /// Fold [Left] and [Right] into the value of one type
  T fold<T>(T Function(L left) fnL, T Function(R right) fnR);

  /// Swap [Left] and [Right]
  Either<R, L> swap() => fold(Right.new, Left.new);

  /// Constructs a new [Either] from a function that might throw
  static Either<L, R> tryCatch<L, R, Err extends Object>(L Function(Err err) onError, R Function() fnR) {
    try {
      return Right(fnR());
    } on Err catch (e) {
      return Left(onError(e));
    }
  }

  /// Constructs a new [Either] from a function that might throw
  ///
  /// simplified version of [Either.tryCatch]
  ///
  /// ```dart
  /// final fileOrError = Either.tryExcept<FileError>(() => /* maybe throw */);
  /// ```
  static Either<Err, R> tryExcept<Err extends Object, R>(R Function() fnR) {
    try {
      return Right(fnR());
    } on Err catch (e) {
      return Left(e);
    }
  }

  static Either<L, R> cond<L, R>({required bool test, required L leftValue, required R rightValue}) =>
      test ? Right(rightValue) : Left(leftValue);

  static Either<L, R> condLazy<L, R>({required bool test, required Lazy<L> leftValue, required Lazy<R> rightValue}) =>
      test ? Right(rightValue()) : Left(leftValue());

}

/// Used for "failure"
class Left<L, R> extends Either<L, R> {
  const Left(this.value);

  final L value;

  @override
  Either<TL, TR> either<TL, TR>(TL Function(L left) fnL, TR Function(R right) fnR) => Left<TL, TR>(fnL(value));

  @override
  Either<L, TR> then<TR>(Either<L, TR> Function(R right) fnR) => Left<L, TR>(value);

  @override
  Future<Either<L, TR>> thenAsync<TR>(FutureOr<Either<L, TR>> Function(R right) fnR) =>
      Future.value(Left<L, TR>(value));

  @override
  Either<TL, R> thenLeft<TL>(Either<TL, R> Function(L left) fnL) => fnL(value);

  @override
  Future<Either<TL, R>> thenLeftAsync<TL>(FutureOr<Either<TL, R>> Function(L left) fnL) => Future.value(fnL(value));

  @override
  Either<L, TR> map<TR>(TR Function(R right) fnR) => Left<L, TR>(value);

  @override
  Either<TL, R> mapLeft<TL>(TL Function(L left) fnL) => Left<TL, R>(fnL(value));

  @override
  Future<Either<L, TR>> mapAsync<TR>(FutureOr<TR> Function(R right) fnR) =>
      Future<Either<L, TR>>.value(Left<L, TR>(value));

  @override
  Future<Either<TL, R>> mapLeftAsync<TL>(FutureOr<TL> Function(L left) fnL) =>
      Future.value(fnL(value)).then(Left<TL, R>.new);

  @override
  T fold<T>(T Function(L left) fnL, T Function(R right) fnR) => fnL(value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Left<L, R> && other.value == value);

  @override
  int get hashCode => Object.hash('Left', value);
}

/// Used for "success"
class Right<L, R> extends Either<L, R> {
  const Right(this.value);

  final R value;

  @override
  Either<TL, TR> either<TL, TR>(TL Function(L left) fnL, TR Function(R right) fnR) => Right<TL, TR>(fnR(value));

  @override
  Either<L, TR> then<TR>(Either<L, TR> Function(R right) fnR) => fnR(value);

  @override
  Future<Either<L, TR>> thenAsync<TR>(FutureOr<Either<L, TR>> Function(R right) fnR) => Future.value(fnR(value));

  @override
  Either<TL, R> thenLeft<TL>(Either<TL, R> Function(L left) fnL) => Right<TL, R>(value);

  @override
  Future<Either<TL, R>> thenLeftAsync<TL>(FutureOr<Either<TL, R>> Function(L left) fnL) =>
      Future.value(Right<TL, R>(value));

  @override
  Either<L, TR> map<TR>(TR Function(R right) fnR) => Right<L, TR>(fnR(value));

  @override
  Either<TL, R> mapLeft<TL>(TL Function(L left) fnL) => Right<TL, R>(value);

  @override
  Future<Either<L, TR>> mapAsync<TR>(FutureOr<TR> Function(R right) fnR) =>
      Future.value(fnR(value)).then(Right<L, TR>.new);

  @override
  Future<Either<TL, R>> mapLeftAsync<TL>(FutureOr<TL> Function(L left) fnL) => Future.value(Right<TL, R>(value));

  @override
  T fold<T>(T Function(L left) fnL, T Function(R right) fnR) => fnR(value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Right<L, R> && other.value == value);

  @override
  int get hashCode => Object.hash('Right', value);
}
