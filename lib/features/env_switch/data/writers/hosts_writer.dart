/// Platform-specific contract for applying the hosts managed block.
///
/// Implementations are responsible for any privilege escalation needed by
/// their platform. Reading the existing block does NOT need elevation
/// (hosts is world-readable).
abstract class HostsWriter {
  /// Reads the currently active managed block content (including markers),
  /// or null if no block is present.
  Future<String?> readExistingManagedBlock();

  /// Writes [newBlock] into the hosts file, preserving everything outside
  /// the managed markers. May prompt for elevation and may flush DNS as
  /// part of the same elevation step (platform-dependent).
  ///
  /// Throws:
  ///   - [PrivilegeDeniedException] when the user denies elevation
  ///   - [HostsWriteFailedException] for any other failure
  Future<void> applyManagedBlock(String newBlock);
}
