import 'dart:io';
import 'dart:math';
import 'dart:convert';

/// Facts about this device's place on the local network.
abstract final class LocalNetwork {
  /// Private IPv4 addresses of this device, most likely Wi-Fi first.
  static Future<List<String>> addresses() async {
    final List<NetworkInterface> interfaces;
    try {
      interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
    } on SocketException {
      return const [];
    }
    final scored = <(int, String)>[];
    for (final interface in interfaces) {
      final name = interface.name.toLowerCase();
      for (final address in interface.addresses) {
        final ip = address.address;
        if (!isPrivate(ip)) continue;
        var score = 0;
        if (name.contains('wlan') || name.contains('wi-fi') || name == 'en0') {
          score += 10;
        }
        if (name.startsWith('ap') || name.contains('swlan')) score += 8;
        if (ip.startsWith('192.168.')) score += 3;
        scored.add((score, ip));
      }
    }
    scored.sort((a, b) => b.$1.compareTo(a.$1));
    return [for (final entry in scored) entry.$2];
  }

  static bool isPrivate(String ip) {
    final parts = ip.split('.').map(int.tryParse).toList();
    if (parts.length != 4 || parts.contains(null)) return false;
    final a = parts[0]!;
    final b = parts[1]!;
    return a == 10 ||
        (a == 172 && b >= 16 && b <= 31) ||
        (a == 192 && b == 168);
  }

  static bool isValidIpv4(String ip) {
    final parts = ip.trim().split('.');
    return parts.length == 4 &&
        parts.every((p) {
          final n = int.tryParse(p);
          return n != null && n >= 0 && n <= 255;
        });
  }

  /// Random id identifying this phone for the length of one match.
  static String newPlayerToken() {
    final random = Random.secure();
    return base64UrlEncode(List<int>.generate(12, (_) => random.nextInt(256)));
  }
}
