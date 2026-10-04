/// Network constants of LAN play.
abstract final class AppConstants {
  /// Prefix of the human readable room codes, e.g. `TN-7K92`.
  static const String roomCodePrefix = 'TN';

  /// First TCP port tried by the LAN host. Up to [lanPortSpan] consecutive
  /// ports are tried so a busy port never blocks hosting.
  static const int lanBasePort = 47821;
  static const int lanPortSpan = 16;

  /// UDP port used to discover games on the same network.
  static const int discoveryPort = 47820;

  static const int protocolVersion = 1;
}
