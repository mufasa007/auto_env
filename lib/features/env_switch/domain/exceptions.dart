import 'entities/switch_progress.dart';

sealed class SwitchException implements Exception {
  const SwitchException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class PrivilegeDeniedException extends SwitchException {
  const PrivilegeDeniedException(super.message);
}

class AuthorizationRevokedException extends SwitchException {
  const AuthorizationRevokedException(super.message);
}

class HostsWriteFailedException extends SwitchException {
  const HostsWriteFailedException(super.message);
}

class EnvVarWriteFailedException extends SwitchException {
  const EnvVarWriteFailedException(super.message);
}

class DnsFlushFailedException extends SwitchException {
  const DnsFlushFailedException(super.message);
}

class PartialFailureException extends SwitchException {
  const PartialFailureException(
    super.message, {
    required this.failedStage,
    this.cause,
  });

  final SwitchStage failedStage;
  final Object? cause;
}
