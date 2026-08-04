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
  L get left => switch (this) {
        Left(:final value) => value,
        Right() => throw StateError('Called .left on a Right. Check isLeft before accessing.'),
      };

  /// Get [Right] value, may throw an exception when the value is [Left]
  R get right => switch (this) {
        Left() => throw StateError('Called .right on a Left. Check isRight before accessing.'),
        Right(:final value) => value,
      };

  /// Get [Right] value or return [defaultValue] if [Left]
  R getOrElse(R defaultValue) => fold((_) => defaultValue, (r) => r);

  /// Get [Right] value or compute from [defaultValue] function if [Left]
  R getOrElseCompute(R Function(L left) defaultValue) => fold(defaultValue, (r) => r);

  /// Get [Left] value or return [defaultValue] if [Right]
  L getLeftOrElse(L defaultValue) => fold((l) => l, (_) => defaultValue);

  /// Get [Right] value or null if [Left]
  R? get rightOrNull => fold((_) => null, (r) => r);

  /// Get [Left] value or null if [Right]
  L? get leftOrNull => fold((l) => l, (_) => null);

  /// Fold [Left] and [Right] into the value of one type
  T fold<T>(T Function(L left) fnL, T Function(R right) fnR) => switch (this) {
        Left(:final value) => fnL(value),
        Right(:final value) => fnR(value),
      };

  /// Transform values of [Left] and [Right]
  Either<TL, TR> either<TL, TR>(TL Function(L left) fnL, TR Function(R right) fnR) =>
      fold((l) => Left(fnL(l)), (r) => Right(fnR(r)));

  Either<L, TR> then<TR>(Either<L, TR> Function(R right) fnR) => fold(Left.new, fnR);

  Future<Either<L, TR>> thenAsync<TR>(FutureOr<Either<L, TR>> Function(R right) fnR) =>
      fold((l) => Future.value(Left(l)), (r) => Future.value(fnR(r)));

  Either<TL, R> thenLeft<TL>(Either<TL, R> Function(L left) fnL) => fold(fnL, Right.new);

  Future<Either<TL, R>> thenLeftAsync<TL>(FutureOr<Either<TL, R>> Function(L left) fnL) =>
      fold((l) => Future.value(fnL(l)), (r) => Future.value(Right(r)));

  /// Transform value of [Right]
  Either<L, TR> map<TR>(TR Function(R right) fnR) => fold(Left.new, (r) => Right(fnR(r)));

  /// Transform value of [Left]
  Either<TL, R> mapLeft<TL>(TL Function(L left) fnL) => fold((l) => Left(fnL(l)), Right.new);

  /// Transform value of [Right]
  Future<Either<L, TR>> mapAsync<TR>(FutureOr<TR> Function(R right) fnR) =>
      fold((l) => Future.value(Left(l)), (r) => Future.value(fnR(r)).then(Right.new));

  /// Transform value of [Left]
  Future<Either<TL, R>> mapLeftAsync<TL>(FutureOr<TL> Function(L left) fnL) =>
      fold((l) => Future.value(fnL(l)).then(Left.new), (r) => Future.value(Right(r)));

  /// Swap [Left] and [Right]
  Either<R, L> swap() => fold(Right.new, Left.new);

  /// Executes [fn] with the [Left] value if present, then returns this
  /// [Either] unchanged. Useful for side effects like logging.
  ///
  /// ```dart
  /// result.onLeft((f) => log.warning(f.message)).getOrElse(fallback);
  /// ```
  Either<L, R> onLeft(void Function(L left) fn) {
    if (this case Left(:final value)) fn(value);
    return this;
  }

  /// Executes [fn] with the [Right] value if present, then returns this
  /// [Either] unchanged. Useful for side effects like logging.
  Either<L, R> onRight(void Function(R right) fn) {
    if (this case Right(:final value)) fn(value);
    return this;
  }

  /// Constructs a new [Either] from a function that might throw
  static Either<L, R> tryCatch<L, R, Err extends Object>(L Function(Err err) onError, R Function() fnR) {
    try {
      return Right(fnR());
    } on Err catch (e) {
      return Left(onError(e));
    }
  }

  /// Async version of [Either.tryCatch] — awaits [fnR] and catches [Err]
  /// thrown either synchronously or from the returned future.
  static Future<Either<L, R>> tryCatchAsync<L, R, Err extends Object>(
      L Function(Err err) onError, FutureOr<R> Function() fnR) async {
    try {
      return Right(await fnR());
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
  bool operator ==(Object other) =>
      identical(this, other) || (other is Left<L, R> && other.value == value);

  @override
  int get hashCode => Object.hash('Left', value);

  @override
  String toString() => 'Left($value)';
}

/// Used for "success"
class Right<L, R> extends Either<L, R> {
  const Right(this.value);

  final R value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Right<L, R> && other.value == value);

  @override
  int get hashCode => Object.hash('Right', value);

  @override
  String toString() => 'Right($value)';
}

/// Chaining helpers for `Future<Either>` — lets you compose without the
/// `(await x).map(...)` dance:
///
/// ```dart
/// final name = await repo.getUser(1).mapRight((u) => u.name).getOrElse('Anonymous');
/// ```
///
/// Named `mapRight`/`thenRight` (not `map`/`then`) because [Future] already
/// declares `then`, which would shadow an extension member.
extension FutureEither<L, R> on Future<Either<L, R>> {
  /// Transform value of [Right] — see [Either.mapAsync].
  Future<Either<L, TR>> mapRight<TR>(FutureOr<TR> Function(R right) fnR) async =>
      (await this).mapAsync(fnR);

  /// Transform value of [Left] — see [Either.mapLeftAsync].
  Future<Either<TL, R>> mapLeft<TL>(FutureOr<TL> Function(L left) fnL) async =>
      (await this).mapLeftAsync(fnL);

  /// Chain another [Either]-producing function on [Right] — see [Either.thenAsync].
  Future<Either<L, TR>> thenRight<TR>(FutureOr<Either<L, TR>> Function(R right) fnR) async =>
      (await this).thenAsync(fnR);

  /// Chain another [Either]-producing function on [Left] — see [Either.thenLeftAsync].
  Future<Either<TL, R>> thenLeft<TL>(FutureOr<Either<TL, R>> Function(L left) fnL) async =>
      (await this).thenLeftAsync(fnL);

  /// Fold [Left] and [Right] into the value of one type — see [Either.fold].
  Future<T> fold<T>(T Function(L left) fnL, T Function(R right) fnR) async =>
      (await this).fold(fnL, fnR);

  /// Get [Right] value or return [defaultValue] if [Left]
  Future<R> getOrElse(R defaultValue) async => (await this).getOrElse(defaultValue);
}
