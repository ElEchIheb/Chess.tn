import 'package:chess_tn/core/constants/app_constants.dart';
import 'package:chess_tn/features/chess/domain/chess_game.dart';
import 'package:chess_tn/features/chess/domain/game_phase.dart';
import 'package:chess_tn/features/chess/domain/match_authority.dart';
import 'package:chess_tn/features/multiplayer/domain/game_message.dart';
import 'package:chess_tn/features/multiplayer/domain/room_code.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/armies.dart';

void main() {
  group('RoomCode', () {
    test('round-trips the host address and port', () {
      for (final (address, offset) in [
        ('192.168.1.23', 0),
        ('192.168.0.1', 3),
        ('10.0.255.254', 15),
        ('172.16.42.7', 9),
      ]) {
        final code = RoomCode.encode(
          hostAddress: address,
          port: AppConstants.lanBasePort + offset,
        );
        expect(code, matches(RegExp(r'^TN-[2-9A-HJ-NP-Z]{4}$')));
        final endpoint = RoomCode.decode(code)!;
        final parts = address.split('.');
        expect(endpoint.thirdOctet, int.parse(parts[2]));
        expect(endpoint.fourthOctet, int.parse(parts[3]));
        expect(endpoint.port, AppConstants.lanBasePort + offset);
      }
    });

    test('every 20-bit value survives encode/decode', () {
      for (var third = 0; third < 256; third += 5) {
        for (var fourth = 0; fourth < 256; fourth += 7) {
          final code = RoomCode.encode(
            hostAddress: '192.168.$third.$fourth',
            port: AppConstants.lanBasePort + (third + fourth) % 16,
          );
          final endpoint = RoomCode.decode(code)!;
          expect(endpoint.thirdOctet, third);
          expect(endpoint.fourthOctet, fourth);
          expect(endpoint.portOffset, (third + fourth) % 16);
        }
      }
    });

    test('neighbouring addresses do not give look-alike codes', () {
      final a = RoomCode.encode(
        hostAddress: '192.168.1.10',
        port: AppConstants.lanBasePort,
      );
      final b = RoomCode.encode(
        hostAddress: '192.168.1.11',
        port: AppConstants.lanBasePort,
      );
      expect(a, isNot(b));
    });

    test('accepts sloppy input and rejects garbage', () {
      final code = RoomCode.encode(
        hostAddress: '192.168.1.23',
        port: AppConstants.lanBasePort,
      );
      final body = code.substring(3);
      expect(RoomCode.format(' tn ${body.toLowerCase()} '), code);
      expect(RoomCode.format(body), code);
      expect(RoomCode.sameCode(code, body.toLowerCase()), isTrue);
      expect(RoomCode.decode('TN-12'), isNull);
      expect(RoomCode.decode('TN-IO01'), isNull);
      expect(RoomCode.decode(''), isNull);
    });

    test('builds host candidates from the joiner\'s own addresses', () {
      final code = RoomCode.encode(
        hostAddress: '192.168.1.23',
        port: AppConstants.lanBasePort,
      );
      final endpoint = RoomCode.decode(code)!;
      expect(endpoint.candidateHosts(['192.168.1.77', '10.0.0.5']), [
        '192.168.1.23',
        '10.0.1.23',
      ]);
    });
  });

  group('GameMessage codec', () {
    test('every message type round-trips', () {
      final messages = <GameMessage>[
        const CreateGameMessage(
          variant: GameVariant.special,
          clientSide: Side.black,
          setupSeconds: 120,
          gameNumber: 1,
        ),
        const JoinGameMessage(
          roomCode: 'TN-7K92',
          playerToken: 'abc',
          protocolVersion: 1,
        ),
        const JoinAcceptedMessage(variant: GameVariant.normal),
        const PlayerReadyMessage(),
        const SetupUpdateMessage(placed: 9),
        const SetupReadyMessage(commitment: 'deadbeef'),
        const SetupUnreadyMessage(),
        const SetupLockedMessage(),
        SetupRevealMessage(army: customBlack().toJson(), salt: 'salt'),
        RevealGameMessage(
          white: customWhite(),
          black: customBlack(),
          hostSalt: 'salt',
        ),
        const PhaseMessage(phase: GamePhase.playing),
        const KingRelocateMessage(side: Side.black, square: Square.e8),
        const MoveMessage(uci: 'e7e8q', ply: 12),
        const ResignMessage(),
        const DrawRequestMessage(),
        const DrawResponseMessage(accepted: true),
        const GameOverMessage(
          outcome: GameOutcome(
            winner: Side.white,
            reason: GameEndReason.checkmate,
          ),
        ),
        const GameOverMessage(
          outcome: GameOutcome(winner: null, reason: GameEndReason.stalemate),
        ),
        StateSyncMessage(
          initialFen: ChessGame.standard().fen,
          moves: const ['e2e4', 'e7e5'],
          white: customWhite(),
          black: customBlack(),
        ),
        const PingMessage(),
        const PongMessage(),
        const DisconnectMessage(reason: DisconnectReason.left),
      ];
      for (final message in messages) {
        final decoded = GameMessage.decode(message.encode());
        expect(decoded.runtimeType, message.runtimeType);
        expect(decoded.encode(), message.encode());
      }
    });

    test('only reveal and sync messages may carry an army', () {
      expect(const SetupReadyMessage(commitment: 'x').carriesArmy, isFalse);
      expect(const SetupUpdateMessage(placed: 3).carriesArmy, isFalse);
      expect(const PlayerReadyMessage().carriesArmy, isFalse);
      expect(
        SetupRevealMessage(army: customBlack().toJson(), salt: 's').carriesArmy,
        isTrue,
      );
    });

    test('malformed input is rejected', () {
      const bad = [
        'not json',
        '[]',
        '{}',
        '{"t":"UNKNOWN"}',
        '{"t":"MOVE"}',
        '{"t":"MOVE","uci":"e2e4"}',
        '{"t":"MOVE","uci":"e2e4e2e4e2e4","ply":0}',
        '{"t":"MOVE","uci":"e2e4","ply":-1}',
        '{"t":"MOVE","uci":"e2e4","ply":"0"}',
        '{"t":"SETUP_UPDATE","placed":999}',
        '{"t":"PHASE","phase":"nope"}',
        '{"t":"KING_RELOCATE","side":"white","square":"z9"}',
        '{"t":"REVEAL_GAME","white":{"a1":"k"},"black":"x","salt":"s"}',
        '{"t":"DRAW_RESPONSE","accepted":"yes"}',
        '{"t":"GAME_OVER","reason":"because"}',
      ];
      for (final raw in bad) {
        expect(
          () => GameMessage.decode(raw),
          throwsFormatException,
          reason: raw,
        );
      }
      expect(
        () => GameMessage.decode('{"t":"PING","x":"${'a' * 20000}"}'),
        throwsFormatException,
      );
    });
  });
}
