/// Dio-specific extensions for dart_failure_handler.
///
/// Re-exports everything from the core library and adds Dio-specific
/// error handling support via [DioErrorMapper] and [DioRepositoryHandler].
///
/// Usage:
/// ```dart
/// // Instead of:
/// import 'package:dart_failure_handler/dart_failure_handler.dart';
///
/// // Use:
/// import 'package:dart_failure_handler/dio.dart';
/// ```
library;

export 'dart_failure_handler.dart';
export 'src/dio_error_mapper.dart';
export 'src/dio_repository_mixin.dart';
