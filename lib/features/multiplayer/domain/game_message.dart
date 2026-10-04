import 'dart:convert';

import 'package:dartchess/dartchess.dart';

import '../../chess/domain/chess_game.dart';
import '../../chess/domain/game_phase.dart';
import '../../chess/domain/match_authority.dart';
import '../../special_mode/domain/army_placement.dart';

/// Why a join request was refused or a connection closed.
enum DisconnectReason {
  left,
  roomFull,
  wrongCode,
  versionMismatch,
  protocolError,
  cheatDetected,
  hostClosed,
}

/// Strongly typed LAN protocol.
///
/// Every message that arrives from the network is parsed by
/// [GameMessage.decode], which rejects anything malformed with a
/// [FormatException]. Sessions then validate the *meaning* of the message
/// (phase, turn, legality) before acting on it.
///
/// Privacy: the only messages that may contain piece coordinates of an army
/// are [SetupRevealMessage], [RevealGameMessage] and [StateSyncMessage], and
/// sessions send those only once both players are locked in.
sealed class GameMessage {
  const GameMessage();

  String get type;
  Map<String, Object?> get payload => const {};

  String encode() => jsonEncode({'t': type, ...payload});

  /// Whether this message type is allowed to carry army coordinates.
  bool get carriesArmy => false;

  static const int maxLength = 16 * 1024;

  static GameMessage decode(String raw) {
    if (raw.length > maxLength) throw const FormatException('message too big');
    final Object? json;
    try {
      json = jsonDecode(raw);
    } on FormatException {
      throw const FormatException('not JSON');
    }
    if (json is! Map<String, dynamic>) {
      throw const FormatException('expected an object');
    }
    final m = _Reader(json);
    return switch (m.string('t')) {
      'CREATE_GAME' => CreateGameMessage(
        variant: m.enumValue('variant', GameVariant.values),
        clientSide: m.enumValue('side', Side.values),
        setupSeconds: m.integer('setupSeconds', min: 10, max: 3600),
        gameNumber: m.integer('game', min: 0, max: 1 << 20),
      ),
      'JOIN_GAME' => JoinGameMessage(
        roomCode: m.string('code', maxLength: 16),
        playerToken: m.string('token', maxLength: 64),
        protocolVersion: m.integer('v', min: 0, max: 1000),
      ),
      'JOIN_ACCEPTED' => JoinAcceptedMessage(
        variant: m.enumValue('variant', GameVariant.values),
      ),
      'PLAYER_READY' => const PlayerReadyMessage(),
      'SETUP_UPDATE' => SetupUpdateMessage(
        placed: m.integer('placed', min: 0, max: 64),
      ),
      'SETUP_READY' => SetupReadyMessage(
        commitment: m.string('commitment', maxLength: 128),
      ),
      'SETUP_UNREADY' => const SetupUnreadyMessage(),
      'SETUP_LOCKED' => const SetupLockedMessage(),
      'SETUP_REVEAL' => SetupRevealMessage(
        army: m.raw('army'),
        salt: m.string('salt', maxLength: 64),
      ),
      'REVEAL_GAME' => RevealGameMessage(
        white: ArmyPlacement.fromJson(Side.white, m.raw('white')),
        black: ArmyPlacement.fromJson(Side.black, m.raw('black')),
        hostSalt: m.string('salt', maxLength: 64),
      ),
      'PHASE' => PhaseMessage(phase: m.enumValue('phase', GamePhase.values)),
      'KING_RELOCATE' => KingRelocateMessage(
        side: m.enumValue('side', Side.values),
        square: m.square('square'),
      ),
      'MOVE' => MoveMessage(
        uci: m.string('uci', maxLength: 5),
        ply: m.integer('ply', min: 0, max: 100000),
      ),
      'RESIGN' => const ResignMessage(),
      'DRAW_REQUEST' => const DrawRequestMessage(),
      'DRAW_RESPONSE' => DrawResponseMessage(accepted: m.boolean('accepted')),
      'GAME_OVER' => GameOverMessage(
        outcome: GameOutcome(
          winner: m.optionalEnum('winner', Side.values),
          reason: m.enumValue('reason', GameEndReason.values),
        ),
      ),
      'STATE_SYNC' => StateSyncMessage(
        initialFen: m.string('fen', maxLength: 128),
        moves: m.stringList('moves', maxItems: 2000, maxLength: 5),
        white: m.has('white')
            ? ArmyPlacement.fromJson(Side.white, m.raw('white'))
            : null,
        black: m.has('black')
            ? ArmyPlacement.fromJson(Side.black, m.raw('black'))
            : null,
      ),
      'PING' => const PingMessage(),
      'PONG' => const PongMessage(),
      'DISCONNECT' => DisconnectMessage(
        reason: m.enumValue('reason', DisconnectReason.values),
      ),
      final other => throw FormatException('unknown message type $other'),
    };
  }
}

/// Host -> client: a (new) game starts with these parameters.
class CreateGameMessage extends GameMessage {
  const CreateGameMessage({
    required this.variant,
    required this.clientSide,
    required this.setupSeconds,
    required this.gameNumber,
  });

  final GameVariant variant;
  final Side clientSide;
  final int setupSeconds;
  final int gameNumber;

  @override
  String get type => 'CREATE_GAME';
  @override
  Map<String, Object?> get payload => {
    'variant': variant.name,
    'side': clientSide.name,
    'setupSeconds': setupSeconds,
    'game': gameNumber,
  };
}

/// Client -> host: first message on a connection.
class JoinGameMessage extends GameMessage {
  const JoinGameMessage({
    required this.roomCode,
    required this.playerToken,
    required this.protocolVersion,
  });

  final String roomCode;

  /// Random id that lets the same phone rejoin after a network drop.
  final String playerToken;
  final int protocolVersion;

  @override
  String get type => 'JOIN_GAME';
  @override
  Map<String, Object?> get payload => {
    'code': roomCode,
    'token': playerToken,
    'v': protocolVersion,
  };
}

/// Host -> client: welcome to the room.
class JoinAcceptedMessage extends GameMessage {
  const JoinAcceptedMessage({required this.variant});

  final GameVariant variant;

  @override
  String get type => 'JOIN_ACCEPTED';
  @override
  Map<String, Object?> get payload => {'variant': variant.name};
}

/// Either way: "I'm ready to start" (lobby and rematch).
class PlayerReadyMessage extends GameMessage {
  const PlayerReadyMessage();
  @override
  String get type => 'PLAYER_READY';
}

/// Either way: public setup progress — a piece *count*, never positions.
class SetupUpdateMessage extends GameMessage {
  const SetupUpdateMessage({required this.placed});

  final int placed;

  @override
  String get type => 'SETUP_UPDATE';
  @override
  Map<String, Object?> get payload => {'placed': placed};
}

/// Either way: "my army is ready", with its SHA-256 commitment only.
class SetupReadyMessage extends GameMessage {
  const SetupReadyMessage({required this.commitment});

  final String commitment;

  @override
  String get type => 'SETUP_READY';
  @override
  Map<String, Object?> get payload => {'commitment': commitment};
}

/// Either way: "I'm changing my army again".
class SetupUnreadyMessage extends GameMessage {
  const SetupUnreadyMessage();
  @override
  String get type => 'SETUP_UNREADY';
}

/// Host -> client: both commitments are in, nobody can change anymore.
class SetupLockedMessage extends GameMessage {
  const SetupLockedMessage();
  @override
  String get type => 'SETUP_LOCKED';
}

/// Client -> host, only after [SetupLockedMessage]: the actual army.
class SetupRevealMessage extends GameMessage {
  const SetupRevealMessage({required this.army, required this.salt});

  /// Raw JSON; the receiver parses it for the side it expects.
  final Object? army;
  final String salt;

  @override
  String get type => 'SETUP_REVEAL';
  @override
  bool get carriesArmy => true;
  @override
  Map<String, Object?> get payload => {'army': army, 'salt': salt};
}

/// Host -> client: open the curtain. Carries both armies and the salt that
/// lets the client check the host's commitment.
class RevealGameMessage extends GameMessage {
  const RevealGameMessage({
    required this.white,
    required this.black,
    required this.hostSalt,
  });

  final ArmyPlacement white;
  final ArmyPlacement black;
  final String hostSalt;

  @override
  String get type => 'REVEAL_GAME';
  @override
  bool get carriesArmy => true;
  @override
  Map<String, Object?> get payload => {
    'white': white.toJson(),
    'black': black.toJson(),
    'salt': hostSalt,
  };
}

/// Host -> client: the authoritative phase changed.
class PhaseMessage extends GameMessage {
  const PhaseMessage({required this.phase});

  final GamePhase phase;

  @override
  String get type => 'PHASE';
  @override
  Map<String, Object?> get payload => {'phase': phase.name};
}

/// Either way: a king under fire at reveal is moved to a safe square.
class KingRelocateMessage extends GameMessage {
  const KingRelocateMessage({required this.side, required this.square});

  final Side side;
  final Square square;

  @override
  String get type => 'KING_RELOCATE';
  @override
  Map<String, Object?> get payload => {
    'side': side.name,
    'square': square.name,
  };
}

/// Either way: a move, with the ply it is meant for.
class MoveMessage extends GameMessage {
  const MoveMessage({required this.uci, required this.ply});

  final String uci;
  final int ply;

  @override
  String get type => 'MOVE';
  @override
  Map<String, Object?> get payload => {'uci': uci, 'ply': ply};
}

class ResignMessage extends GameMessage {
  const ResignMessage();
  @override
  String get type => 'RESIGN';
}

class DrawRequestMessage extends GameMessage {
  const DrawRequestMessage();
  @override
  String get type => 'DRAW_REQUEST';
}

class DrawResponseMessage extends GameMessage {
  const DrawResponseMessage({required this.accepted});

  final bool accepted;

  @override
  String get type => 'DRAW_RESPONSE';
  @override
  Map<String, Object?> get payload => {'accepted': accepted};
}

/// Host -> client: the game ended this way.
class GameOverMessage extends GameMessage {
  const GameOverMessage({required this.outcome});

  final GameOutcome outcome;

  @override
  String get type => 'GAME_OVER';
  @override
  Map<String, Object?> get payload => {
    if (outcome.winner != null) 'winner': outcome.winner!.name,
    'reason': outcome.reason.name,
  };
}

/// Host -> client: full public state of a running battle (after a rejected
/// move or a reconnection).
class StateSyncMessage extends GameMessage {
  const StateSyncMessage({
    required this.initialFen,
    required this.moves,
    this.white,
    this.black,
  });

  final String initialFen;
  final List<String> moves;
  final ArmyPlacement? white;
  final ArmyPlacement? black;

  @override
  String get type => 'STATE_SYNC';
  @override
  bool get carriesArmy => true;
  @override
  Map<String, Object?> get payload => {
    'fen': initialFen,
    'moves': moves,
    if (white != null) 'white': white!.toJson(),
    if (black != null) 'black': black!.toJson(),
  };
}

class PingMessage extends GameMessage {
  const PingMessage();
  @override
  String get type => 'PING';
}

class PongMessage extends GameMessage {
  const PongMessage();
  @override
  String get type => 'PONG';
}

class DisconnectMessage extends GameMessage {
  const DisconnectMessage({required this.reason});

  final DisconnectReason reason;

  @override
  String get type => 'DISCONNECT';
  @override
  Map<String, Object?> get payload => {'reason': reason.name};
}

/// Strict field access on untrusted JSON.
class _Reader {
  const _Reader(this._json);

  final Map<String, dynamic> _json;

  bool has(String key) => _json[key] != null;

  Object? raw(String key) => _json[key];

  String string(String key, {int maxLength = 64}) {
    final value = _json[key];
    if (value is! String || value.length > maxLength) {
      throw FormatException('bad string field "$key"');
    }
    return value;
  }

  int integer(String key, {required int min, required int max}) {
    final value = _json[key];
    if (value is! int || value < min || value > max) {
      throw FormatException('bad integer field "$key"');
    }
    return value;
  }

  bool boolean(String key) {
    final value = _json[key];
    if (value is! bool) throw FormatException('bad boolean field "$key"');
    return value;
  }

  T enumValue<T extends Enum>(String key, List<T> values) {
    final name = string(key);
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw FormatException('bad enum field "$key"');
  }

  T? optionalEnum<T extends Enum>(String key, List<T> values) =>
      has(key) ? enumValue(key, values) : null;

  Square square(String key) {
    final square = Square.parse(string(key, maxLength: 2));
    if (square == null) throw FormatException('bad square field "$key"');
    return square;
  }

  List<String> stringList(
    String key, {
    required int maxItems,
    required int maxLength,
  }) {
    final value = _json[key];
    if (value is! List || value.length > maxItems) {
      throw FormatException('bad list field "$key"');
    }
    return [
      for (final item in value)
        if (item is String && item.length <= maxLength)
          item
        else
          throw FormatException('bad list item in "$key"'),
    ];
  }
}
