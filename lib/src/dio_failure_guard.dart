import 'failure_mapper.dart';
import 'failure_guard.dart';
import 'dio_failure_mapper.dart';

/// Convenience mixin that automatically prepends [DioFailureMapper] to
/// the [FailureGuard.failureChain].
///
/// Apply alongside [FailureGuard] to handle Dio-specific errors without
/// any manual chain setup.
///
/// To add further custom mappers, override [failureChain] and compose
/// on top of `super.failureChain`:
///
/// ```dart
/// class UserRepository with FailureGuard, DioFailureGuard {
///   @override
///   FailureMapperChain get failureChain =>
///       super.failureChain.prepend(DriftFailureMapper.handle);
/// }
/// ```
mixin DioFailureGuard on FailureGuard {
  @override
  FailureMapperChain get failureChain =>
      FailureMapperChain.base.prepend(DioFailureMapper.handle);
}
