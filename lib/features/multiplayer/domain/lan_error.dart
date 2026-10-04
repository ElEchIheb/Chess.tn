/// User-facing LAN failures. Each one maps to a localized message.
enum LanError {
  /// The phone has no Wi-Fi / local network address.
  noNetwork,

  /// The room code is not well formed.
  invalidCode,

  /// Nobody answered at the address the code points to.
  hostNotFound,

  /// The room already has two players.
  roomFull,

  /// The host has a different code (stale code or wrong network).
  wrongCode,

  /// The two phones run incompatible versions of the game.
  versionMismatch,

  /// The local server could not be started.
  cannotHost,

  unknown,
}

class LanException implements Exception {
  const LanException(this.error, [this.details]);

  final LanError error;
  final Object? details;

  @override
  String toString() => 'LanException(${error.name}, $details)';
}
