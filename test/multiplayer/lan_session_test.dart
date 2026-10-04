import 'dart:convert';

import 'package:chess_tn/features/chess/application/game_session.dart';
import 'package:chess_tn/features/chess/domain/chess_game.dart';
import 'package:chess_tn/features/chess/domain/game_phase.dart';
import 'package:chess_tn/features/chess/domain/game_state.dart';
import 'package:chess_tn/features/chess/domain/match_authority.dart';
import 'package:chess_tn/features/multiplayer/application/lan_client_session.dart';
import 'package:chess_tn/features/multiplayer/application/lan_host_session.dart';
import 'package:chess_tn/features/multiplayer/domain/game_message.dart';
import 'package:chess_tn/features/multiplayer/domain/message_channel.dart';
import 'package:chess_tn/features/special_mode/domain/setup_commitment.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/armies.dart';
import '../support/fakes.dart';

class Table {
  Table(GameVariant variant) {
    final config = GameConfig(variant: variant, opponent: OpponentType.lan);
    host = LanHostSession(
      config: config,
      channel: pair.a,
      timings: SessionTimings.fast,
    )..start();
    client = LanClientSession(
      config: config,
      channel: pair.b,
      timings: SessionTimings.fast,
    )..start();
  }

  final LoopbackChannelPair pair = LoopbackChannelPair();
  late final LanHostSession host;
  late final LanClientSession client;

  List<String> get hostWire => loopbackSentLog(pair.a);
  List<String> get clientWire => loopbackSentLog(pair.b);

  Future<void> readyUp() async {
    host.setReady();
    client.setReady();
    await settle();
  }

  Future<void> dispose() async {
    await host.dispose();
    await client.dispose();
  }
}

NormalMove uci(String text) => Move.parse(text)! as NormalMove;

/// True when [wire] mentions where any piece of an army stands.
bool leaksCoordinates(String wire) {
  final json = jsonDecode(wire) as Map<String, dynamic>;
  bool looksLikeArmy(Object? value) =>
      value is Map &&
      value.keys.any((k) => k is String && Square.parse(k) != null);
  return json.values.any(looksLikeArmy);
}

void main() {
  group('LAN normal chess', () {
    late Table table;
    setUp(() => table = Table(GameVariant.normal));
    tearDown(() => table.dispose());

    test(
      'both players ready up, then play from the standard position',
      () async {
        expect(table.host.current.phase, GamePhase.lobby);
        expect(table.client.current.phase, GamePhase.lobby);

        table.host.setReady();
        await settle();
        expect(table.client.current.opponentReady, isTrue);
        expect(table.host.current.phase, GamePhase.lobby);

        table.client.setReady();
        await settle();
        expect(table.host.current.phase, GamePhase.playing);
        expect(table.client.current.phase, GamePhase.playing);
        expect(table.host.current.localSides, {Side.white});
        expect(table.client.current.localSides, {Side.black});
        expect(table.client.current.orientation, Side.black);
        expect(table.client.current.game.fen, ChessGame.standard().fen);
      },
    );

    test('moves travel both ways and stay in sync', () async {
      await table.readyUp();
      table.host.playMove(uci('e2e4'));
      await settle();
      expect(table.client.current.game.ply, 1);
      expect(table.client.current.canMove, isTrue);
      expect(table.host.current.canMove, isFalse);

      table.client.playMove(uci('e7e5'));
      await settle();
      expect(table.host.current.game.ply, 2);
      expect(table.host.current.game.fen, table.client.current.game.fen);
    });

    test('a player cannot move out of turn', () async {
      await table.readyUp();
      table.client.playMove(uci('e7e5'));
      await settle();
      expect(table.host.current.game.ply, 0);
      expect(table.client.current.game.ply, 0);
    });

    test('the host rejects an illegal move sent on the wire', () async {
      await table.readyUp();
      table.host.playMove(uci('e2e4'));
      await settle();
      // A tampered client bypasses its own checks and sends garbage.
      table.pair.b.send(const MoveMessage(uci: 'e7e2', ply: 1));
      await settle();
      expect(table.host.current.game.ply, 1);
      expect(table.hostWire.last, contains('STATE_SYNC'));
      expect(table.client.current.game.fen, table.host.current.game.fen);
    });

    test('the host rejects a move for the wrong turn or a stale ply', () async {
      await table.readyUp();
      // Black tries to move first.
      table.pair.b.send(const MoveMessage(uci: 'e7e5', ply: 0));
      await settle();
      expect(table.host.current.game.ply, 0);
      // Moving a white piece on black's behalf.
      table.host.playMove(uci('e2e4'));
      await settle();
      table.pair.b.send(const MoveMessage(uci: 'd2d4', ply: 1));
      table.pair.b.send(const MoveMessage(uci: 'e7e5', ply: 7));
      await settle();
      expect(table.host.current.game.ply, 1);
    });

    test('the client rejects an illegal move from the host', () async {
      await table.readyUp();
      final events = <GameEventType>[];
      table.client.events.listen((e) => events.add(e.type));
      table.pair.a.send(const MoveMessage(uci: 'e2e5', ply: 0));
      await settle();
      expect(table.client.current.game.ply, 0);
      expect(table.client.current.phase, GamePhase.abandoned);
      expect(events, contains(GameEventType.protocolError));
    });

    test('checkmate is announced to both players', () async {
      await table.readyUp();
      table.host.playMove(uci('f2f3'));
      await settle();
      table.client.playMove(uci('e7e5'));
      await settle();
      table.host.playMove(uci('g2g4'));
      await settle();
      table.client.playMove(uci('d8h4'));
      await settle();
      for (final session in [table.host, table.client]) {
        expect(session.current.phase, GamePhase.gameOver);
        expect(session.current.outcome?.reason, GameEndReason.checkmate);
      }
      expect(table.host.current.localWon, isFalse);
      expect(table.client.current.localWon, isTrue);
    });

    test('resigning and draw offers work across the network', () async {
      await table.readyUp();
      table.client.offerDraw();
      await settle();
      expect(table.host.current.drawOfferFrom, Side.black);
      table.host.respondToDraw(accept: false);
      await settle();
      expect(table.client.current.drawOfferFrom, isNull);
      expect(table.client.current.phase, GamePhase.playing);

      table.host.offerDraw();
      await settle();
      table.client.respondToDraw(accept: true);
      await settle();
      expect(table.host.current.outcome?.reason, GameEndReason.drawAgreement);
      expect(table.client.current.outcome?.reason, GameEndReason.drawAgreement);
    });

    test('the client refuses a made-up result', () async {
      await table.readyUp();
      table.pair.a.send(
        const GameOverMessage(
          outcome: GameOutcome(
            winner: Side.white,
            reason: GameEndReason.resignation,
          ),
        ),
      );
      await settle();
      expect(table.client.current.outcome?.winner, isNot(Side.white));
      expect(table.client.current.phase, GamePhase.abandoned);
    });

    test('a rematch swaps colours', () async {
      await table.readyUp();
      table.client.resign();
      await settle();
      expect(table.host.current.outcome?.winner, Side.white);
      table.host.rematch();
      table.client.rematch();
      await settle();
      expect(table.host.current.phase, GamePhase.playing);
      expect(table.host.current.localSides, {Side.black});
      expect(table.client.current.localSides, {Side.white});
      expect(table.client.current.canMove, isTrue);
    });

    test('leaving tells the other player', () async {
      await table.readyUp();
      await table.client.dispose();
      await settle();
      expect(table.host.current.phase, GamePhase.abandoned);
      expect(table.host.current.opponentConnected, isFalse);
      expect(table.host.current.outcome?.reason, GameEndReason.abandonment);
    });

    test('a dropped connection pauses the game, then abandons it', () async {
      await table.readyUp();
      await table.pair.b.close(); // socket dies without a goodbye
      await settle();
      expect(table.host.current.phase, GamePhase.paused);
      expect(table.host.current.pausedFrom, GamePhase.playing);
      final state = await waitForPhase(table.host, GamePhase.abandoned);
      expect(state.outcome?.winner, Side.white);
    });
  });

  group('LAN special chess — hidden armies', () {
    late Table table;
    setUp(() async {
      table = Table(GameVariant.special);
      await table.readyUp();
    });
    tearDown(() => table.dispose());

    test('both players enter their own private setup', () {
      expect(table.host.current.phase, GamePhase.setupWhite);
      expect(table.client.current.phase, GamePhase.setupBlack);
      expect(table.host.current.setup!.side, Side.white);
      expect(table.client.current.setup!.side, Side.black);
    });

    test('progress shares a count, never positions', () async {
      table.host.reportSetupProgress(7);
      await settle();
      expect(table.client.current.setup!.opponentPlaced, 7);
      expect(table.client.current.whiteArmy, isNull);
      expect(table.hostWire.any(leaksCoordinates), isFalse);
    });

    test('B cannot access A\'s setup, and A cannot access B\'s', () async {
      table.host.submitSetup(customWhite());
      await settle();

      // A is done: B knows that, and nothing else.
      final b = table.client.current;
      expect(b.setup!.opponentReady, isTrue);
      expect(b.whiteArmy, isNull);
      expect(b.blackArmy, isNull);
      expect(b.game.fen, ChessGame.standard().fen);
      expect(table.host.current.phase, GamePhase.waitingForPlayer);

      // Not a single coordinate has left either phone so far.
      expect(table.hostWire.any(leaksCoordinates), isFalse);
      expect(table.clientWire.any(leaksCoordinates), isFalse);
      final ready = table.hostWire
          .map((w) => jsonDecode(w) as Map<String, dynamic>)
          .firstWhere((m) => m['t'] == 'SETUP_READY');
      expect(ready.keys, unorderedEquals(['t', 'commitment']));
      expect(ready['commitment'], matches(RegExp(r'^[0-9a-f]{64}$')));

      // While B is still building, A sees nothing of B either.
      table.client.reportSetupProgress(11);
      await settle();
      final a = table.host.current;
      expect(a.setup!.opponentPlaced, 11);
      expect(a.blackArmy, isNull);
      expect(a.whiteArmy, isNull);
    });

    test('armies cross the network only after both are locked', () async {
      table.host.submitSetup(customWhite());
      await settle();
      final hostWireBefore = List.of(table.hostWire);
      final clientWireBefore = List.of(table.clientWire);

      table.client.submitSetup(customBlack());
      await settle();

      // Everything sent before the client committed is coordinate-free.
      expect(hostWireBefore.any(leaksCoordinates), isFalse);
      expect(clientWireBefore.any(leaksCoordinates), isFalse);

      // Order on the wire: the client reveals only after SETUP_LOCKED, the
      // host reveals only after it holds the client's reveal.
      final clientTypes = [
        for (final w in table.clientWire) jsonDecode(w)['t'] as String,
      ];
      final hostTypes = [
        for (final w in table.hostWire) jsonDecode(w)['t'] as String,
      ];
      expect(
        clientTypes.indexOf('SETUP_REVEAL'),
        greaterThan(clientTypes.indexOf('SETUP_READY')),
      );
      expect(
        hostTypes.indexOf('REVEAL_GAME'),
        greaterThan(hostTypes.indexOf('SETUP_LOCKED')),
      );
      expect(hostTypes.where((t) => t == 'REVEAL_GAME').length, 1);
    });

    test(
      'after the reveal both setups are available to both players',
      () async {
        table.client.submitSetup(customBlack());
        await settle();
        table.host.submitSetup(customWhite());
        await settle();

        for (final session in [table.host, table.client]) {
          final state = session.current;
          expect(state.phase, GamePhase.reveal);
          expect(state.revealCount, 1);
          expect(state.whiteArmy, customWhite());
          expect(state.blackArmy, customBlack());
        }
      },
    );

    test('the battle starts from both custom positions on both phones', () async {
      table.host.submitSetup(customWhite());
      table.client.submitSetup(customBlack());
      final host = await waitForPhase(table.host, GamePhase.playing);
      final client = await waitForPhase(table.client, GamePhase.playing);
      const fen =
          '1k1r1r2/pppqbb2/2nn1ppp/4pp2/3PP3/PPP1NN2/2BBQPPP/2R1R1K1 w - - 0 1';
      expect(host.game.initialFen, fen);
      expect(client.game.initialFen, fen);

      table.host.playMove(uci('d4e5'));
      await settle();
      expect(table.client.current.game.ply, 1);
      expect(table.client.current.game.lastMove!.isCapture, isTrue);
    });

    test('a player can go back to editing until both are locked', () async {
      table.host.submitSetup(customWhite());
      await settle();
      expect(table.client.current.setup!.opponentReady, isTrue);
      table.host.editSetup();
      await settle();
      expect(table.host.current.phase, GamePhase.setupWhite);
      expect(table.client.current.setup!.opponentReady, isFalse);

      table.client.submitSetup(customBlack());
      await settle();
      expect(table.client.current.phase, GamePhase.waitingForPlayer);
      table.client.editSetup();
      await settle();
      expect(table.client.current.phase, GamePhase.setupBlack);
      expect(table.host.current.setup!.opponentReady, isFalse);

      // Once both are in, editing is refused.
      table.host.submitSetup(customWhite());
      table.client.submitSetup(customBlack());
      await settle();
      table.host.editSetup();
      table.client.editSetup();
      await settle();
      expect(table.host.current.phase, isNot(GamePhase.setupWhite));
      expect(table.client.current.phase, isNot(GamePhase.setupBlack));
    });

    test('an invalid army never leaves the phone', () async {
      final events = <GameEvent>[];
      table.client.events.listen(events.add);
      table.client.submitSetup(customBlack().remove(Square.e5));
      await settle();
      expect(table.client.current.phase, GamePhase.setupBlack);
      expect(events.single.type, GameEventType.setupInvalid);
      expect(table.clientWire.any((w) => w.contains('SETUP_READY')), isFalse);
    });

    test(
      'revealing a different army than the committed one is caught',
      () async {
        table.host.submitSetup(customWhite());
        await settle();
        // A cheating client commits to one army...
        final salt = SetupCommitment.generateSalt();
        table.pair.b.send(
          SetupReadyMessage(
            commitment: SetupCommitment.commit(customBlack(), salt),
          ),
        );
        await settle();
        expect(table.hostWire.last, contains('SETUP_LOCKED'));
        // ...and reveals another one after seeing it is locked.
        final other = customBlack().move(Square.b8, Square.h8);
        table.pair.b.send(SetupRevealMessage(army: other.toJson(), salt: salt));
        await settle();
        expect(table.host.current.phase, GamePhase.abandoned);
        expect(table.host.current.blackArmy, isNull);
        expect(table.hostWire.any((w) => w.contains('REVEAL_GAME')), isFalse);
      },
    );

    test('the host cannot swap its army after the lock either', () async {
      table.host.submitSetup(customWhite());
      table.client.submitSetup(customBlack());
      await settle();
      // The genuine reveal already happened; replay the scenario by hand on
      // a fresh table with a host that lies in REVEAL_GAME.
      final rogue = LoopbackChannelPair();
      final client = LanClientSession(
        config: const GameConfig(
          variant: GameVariant.special,
          opponent: OpponentType.lan,
        ),
        channel: rogue.b,
        timings: SessionTimings.fast,
      )..start();
      addTearDown(client.dispose);
      rogue.a.send(
        const CreateGameMessage(
          variant: GameVariant.special,
          clientSide: Side.black,
          setupSeconds: 120,
          gameNumber: 1,
        ),
      );
      const salt = 'host-salt';
      rogue.a.send(
        SetupReadyMessage(
          commitment: SetupCommitment.commit(customWhite(), salt),
        ),
      );
      await settle();
      client.submitSetup(customBlack());
      await settle();
      rogue.a.send(const SetupLockedMessage());
      await settle();
      // The host now knows black's army and tries to adapt its own.
      final adapted = customWhite().move(Square.g1, Square.a1);
      rogue.a.send(
        RevealGameMessage(white: adapted, black: customBlack(), hostSalt: salt),
      );
      await settle();
      expect(client.current.phase, GamePhase.abandoned);
      expect(client.current.whiteArmy, isNull);
    });

    test('a client that reveals without being locked is ignored', () async {
      table.pair.b.send(
        SetupRevealMessage(army: customBlack().toJson(), salt: 'x'),
      );
      await settle();
      expect(table.host.current.phase, GamePhase.setupWhite);
      expect(table.host.current.blackArmy, isNull);
    });
  });
}
