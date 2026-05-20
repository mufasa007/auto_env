/// Platform-specific contract for applying user-scope environment variables.
///
/// Implementations are responsible for:
///   - Setting each key in [next] to its target value
///   - Unsetting any key present in [previous] but absent from [next]
///   - Making the change visible to new processes (broadcast on Windows,
///     launchctl on macOS for GUI apps; shell users need to re-source)
abstract class EnvVarWriter {
  /// Apply environment variables for the current user.
  ///
  /// [previous] captures keys that were applied by a prior switch so they
  /// can be unset when no longer needed. Values in [previous] are the
  /// pre-auto_env originals (or null if the key was unset before).
  ///
  /// Throws [EnvVarWriteFailedException] on any failure.
  Future<void> apply(
    Map<String, String> next,
    Map<String, String?> previous,
  );
}
