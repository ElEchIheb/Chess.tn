import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'army_placement.dart';

/// Commit–reveal scheme that keeps armies secret on the network.
///
/// When a player is ready they only publish `sha256(salt | army)`. The army
/// itself is sent once both players are locked in, and the receiver checks
/// it against the commitment. Neither device can learn the other army early
/// nor change its own after seeing the opponent's.
abstract final class SetupCommitment {
  static String generateSalt([Random? random]) {
    final rng = random ?? Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String commit(ArmyPlacement army, String salt) {
    final input = '$salt|${army.side.name}|${army.encode()}';
    return sha256.convert(utf8.encode(input)).toString();
  }

  static bool verify(ArmyPlacement army, String salt, String commitment) =>
      commit(army, salt) == commitment;
}
