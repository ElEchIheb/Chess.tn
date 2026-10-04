import '../../../core/constants/app_constants.dart';

/// Where a room code points to on the local network.
class RoomEndpoint {
  const RoomEndpoint({
    required this.thirdOctet,
    required this.fourthOctet,
    required this.portOffset,
  });

  final int thirdOctet;
  final int fourthOctet;
  final int portOffset;

  int get port => AppConstants.lanBasePort + portOffset;

  /// Host addresses to try, given the joining phone's own IPv4 addresses:
  /// both phones share the first two octets on an ordinary Wi-Fi network.
  List<String> candidateHosts(Iterable<String> localAddresses) {
    final hosts = <String>{};
    for (final address in localAddresses) {
      final parts = address.split('.');
      if (parts.length != 4) continue;
      hosts.add('${parts[0]}.${parts[1]}.$thirdOctet.$fourthOctet');
    }
    return hosts.toList();
  }
}

/// Short codes such as `TN-7K92`.
///
/// The four characters carry 20 bits: the last two octets of the host's
/// IPv4 address and a port offset. A friend on the same Wi-Fi can therefore
/// connect with the code alone — no server and no discovery needed.
abstract final class RoomCode {
  static const String _alphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
  static const int _mask = 0xFFFFF;

  // Odd multiplier => invertible modulo 2^20. Only there so that codes do
  // not look like consecutive numbers.
  static const int _mul = 0x9E375;
  static const int _add = 0x5A5A5;
  static final int _inverse = _modInverse(_mul);

  static String encode({required String hostAddress, required int port}) {
    final parts = hostAddress.split('.').map(int.tryParse).toList();
    if (parts.length != 4 || parts.any((p) => p == null || p < 0 || p > 255)) {
      throw ArgumentError.value(hostAddress, 'hostAddress', 'not IPv4');
    }
    final offset = port - AppConstants.lanBasePort;
    if (offset < 0 || offset >= AppConstants.lanPortSpan) {
      throw ArgumentError.value(port, 'port', 'outside the LAN port range');
    }
    final raw = (parts[2]! << 12) | (parts[3]! << 4) | offset;
    var value = (raw * _mul + _add) & _mask;
    final chars = List<String>.filled(4, '');
    for (var i = 3; i >= 0; i--) {
      chars[i] = _alphabet[value & 31];
      value >>= 5;
    }
    return '${AppConstants.roomCodePrefix}-${chars.join()}';
  }

  /// Returns `null` when [input] is not a well formed code.
  static RoomEndpoint? decode(String input) {
    final body = normalize(input);
    if (body == null) return null;
    var value = 0;
    for (final char in body.split('')) {
      value = (value << 5) | _alphabet.indexOf(char);
    }
    final raw = ((value - _add) * _inverse) & _mask;
    return RoomEndpoint(
      thirdOctet: (raw >> 12) & 0xFF,
      fourthOctet: (raw >> 4) & 0xFF,
      portOffset: raw & 0xF,
    );
  }

  /// The four significant characters, or `null` when invalid. Accepts lower
  /// case, spaces and an optional `TN-` prefix.
  static String? normalize(String input) {
    var text = input.toUpperCase().replaceAll(RegExp(r'[\s\-_]'), '');
    if (text.length == 4 + AppConstants.roomCodePrefix.length &&
        text.startsWith(AppConstants.roomCodePrefix)) {
      text = text.substring(AppConstants.roomCodePrefix.length);
    }
    if (text.length != 4) return null;
    for (final char in text.split('')) {
      if (!_alphabet.contains(char)) return null;
    }
    return text;
  }

  /// Canonical display form, e.g. `TN-7K92`.
  static String? format(String input) {
    final body = normalize(input);
    return body == null ? null : '${AppConstants.roomCodePrefix}-$body';
  }

  static bool sameCode(String a, String b) {
    final x = normalize(a);
    return x != null && x == normalize(b);
  }

  static int _modInverse(int a) {
    // Newton iteration for the inverse modulo a power of two.
    var x = a;
    for (var i = 0; i < 5; i++) {
      x = (x * (2 - a * x)) & _mask;
    }
    return x & _mask;
  }
}
