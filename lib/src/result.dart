import 'package:mason_logger/mason_logger.dart';

/// Result
class Result<T> {
  /// Result.value
  Result.value(this.value) : exitCode = null;

  /// Result.error
  Result.error(this.exitCode) : value = null;

  /// Value
  final T? value;

  /// ExitCode
  final ExitCode? exitCode;

  /// hasError
  bool get hasError => exitCode != null && value == null;
}
