import 'dart:io';

import 'package:chess_tn/features/chess/application/game_session.dart';
import 'package:chess_tn/features/chess/domain/game_phase.dart';
import 'package:chess_tn/features/chess/domain/game_state.dart';
import 'package:chess_tn/features/chess/domain/match_authority.dart';
import 'package:chess_tn/features/multiplayer/application/lan_client_session.dart';
import 'package:chess_tn/features/multiplayer/application/lan_host_session.dart';
import 'package:chess_tn/features/multiplayer/data/lan_client_connector.dart';
import 'package:chess_tn/features/multiplayer/data/lan_host_server.dart';
import 'package:chess_tn/features/multiplayer/domain/lan_error.dart';
import 'package:chess_tn/features/multiplayer/domain/room_code.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/armies.dart';
import '../support/fakes.dart';

/// Real `dart:io` sockets on the loopback interface: an actual WebSocket
/// server, an actual client, the actual wire format.
void main() {
  const loopback = '127.0.0.1';

  // flutter_test blocks real HTTP by default; these tests need real sockets.
  setUpAll(() => HttpOverrides.global = null);

  Future<(LanHostServer, LanHostSession, LanClientSession, LanClientConnector)>
  connect(GameVariant variant) async {
    final server = await LanHostServer.start(
      variant: variant,
      addressOverride: loopback,
    );
    final connector = LanClientConnector();
    final hostSessionFuture = server.joins.first.then((peer) {
      final session = LanHostSession(
        config: GameConfig(variant: variant, opponent: OpponentType.lan),
        channel: peer.channel,
        timings: SessionTimings.fast,
      )..start();
      return session;
    });
    final joined = await connector.joinWithCode(
      server.roomCode,
      manualHost: loopback,
    );
    final client = LanClientSession(
      config: GameConfig(variant: joined.variant, opponent: OpponentType.lan),
      channel: joined.channel,
      timings: SessionTimings.fast,
    )..start();
    final host = await hostSessionFuture;
    addTearDown(() async {
      await client.dispose();
      await host.dispose();
      await server.close();
    });
    return (server, host, client, connector);
  }

  test('the room code points back at the host', () async {
    final server = await LanHostServer.start(
      variant: GameVariant.normal,
      addressOverride: '192.168.1.23',
    );
    addTearDown(server.close);
    final endpoint = RoomCode.decode(server.roomCode)!;
    expect(endpoint.port, server.port);
    expect(endpoint.candidateHosts(['192.168.1.50']), ['192.168.1.23']);
  });

  test('host and client play a normal game over a real WebSocket', () async {
    final (_, host, client, _) = await connect(GameVariant.normal);
    expect(client.current.config.variant, GameVariant.normal);

    host.setReady();
    client.setReady();
    await waitForPhase(host, GamePhase.playing);
    await waitForPhase(client, GamePhase.playing);

    host.playMove(const NormalMove(from: Square.e2, to: Square.e4));
    await waitForState(client, (s) => s.game.ply == 1);
    client.playMove(const NormalMove(from: Square.c7, to: Square.c5));
    final state = await waitForState(host, (s) => s.game.ply == 2);
    expect(state.game.fen, client.current.game.fen);
    expect(state.game.lastMove!.san, 'c5');
  });

  test(
    'special mode: private setup, synchronised reveal, custom battle',
    () async {
      final (_, host, client, _) = await connect(GameVariant.special);
      expect(client.current.config.variant, GameVariant.special);

      host.setReady();
      client.setReady();
      await waitForPhase(host, GamePhase.setupWhite);
      await waitForPhase(client, GamePhase.setupBlack);

      host.submitSetup(customWhite());
      final waiting = await waitForState(
        client,
        (s) => s.setup?.opponentReady ?? false,
      );
      expect(waiting.whiteArmy, isNull);

      client.submitSetup(customBlack());
      final hostReveal = await waitForPhase(host, GamePhase.reveal);
      final clientReveal = await waitForPhase(client, GamePhase.reveal);
      expect(hostReveal.blackArmy, customBlack());
      expect(clientReveal.whiteArmy, customWhite());

      final hostPlaying = await waitForPhase(host, GamePhase.playing);
      final clientPlaying = await waitForPhase(client, GamePhase.playing);
      expect(hostPlaying.game.initialFen, clientPlaying.game.initialFen);
      expect(
        hostPlaying.game.initialFen,
        '1k1r1r2/pppqbb2/2nn1ppp/4pp2/3PP3/PPP1NN2/2BBQPPP/2R1R1K1 w - - 0 1',
      );
    },
  );

  test('a third phone is told the room is full', () async {
    final (server, _, _, _) = await connect(GameVariant.normal);
    final intruder = LanClientConnector();
    await expectLater(
      intruder.joinWithCode(server.roomCode, manualHost: loopback),
      throwsA(
        isA<LanException>().having((e) => e.error, 'error', LanError.roomFull),
      ),
    );
  });

  test('a wrong code is refused', () async {
    final server = await LanHostServer.start(
      variant: GameVariant.normal,
      addressOverride: loopback,
    );
    addTearDown(server.close);
    await expectLater(
      LanClientConnector().connect(
        host: loopback,
        port: server.port,
        roomCode: 'TN-2222',
      ),
      throwsA(
        isA<LanException>().having((e) => e.error, 'error', LanError.wrongCode),
      ),
    );
  });

  test('joining when nobody is hosting reports hostNotFound', () async {
    final probe = await ServerSocket.bind(loopback, 0);
    final freePort = probe.port;
    await probe.close();
    await expectLater(
      LanClientConnector().connect(
        host: loopback,
        port: freePort,
        roomCode: 'TN-2222',
      ),
      throwsA(
        isA<LanException>().having(
          (e) => e.error,
          'error',
          LanError.hostNotFound,
        ),
      ),
    );
  });

  test('an invalid code is refused before any network access', () async {
    await expectLater(
      LanClientConnector().joinWithCode('hello'),
      throwsA(
        isA<LanException>().having(
          (e) => e.error,
          'error',
          LanError.invalidCode,
        ),
      ),
    );
  });

  test('a dropped client can rejoin and the game resumes in sync', () async {
    final server = await LanHostServer.start(
      variant: GameVariant.normal,
      addressOverride: loopback,
    );
    final connector = LanClientConnector();
    LanHostSession? host;
    server.allowRejoin = () => host?.acceptsRejoin ?? false;
    server.joins.listen((peer) {
      if (peer.isRejoin) {
        host!.reattach(peer.channel);
      } else {
        host = LanHostSession(
          config: const GameConfig(
            variant: GameVariant.normal,
            opponent: OpponentType.lan,
          ),
          channel: peer.channel,
          timings: SessionTimings.fast,
        )..start();
      }
    });

    var joined = await connector.joinWithCode(
      server.roomCode,
      manualHost: loopback,
    );
    final client = LanClientSession(
      config: const GameConfig(
        variant: GameVariant.normal,
        opponent: OpponentType.lan,
      ),
      channel: joined.channel,
      reconnect: () async {
        try {
          joined = await connector.connect(
            host: loopback,
            port: server.port,
            roomCode: server.roomCode,
          );
          return joined.channel;
        } on LanException {
          return null;
        }
      },
      timings: SessionTimings.fast,
    )..start();
    addTearDown(() async {
      await client.dispose();
      await host?.dispose();
      await server.close();
    });

    await settle(20);
    host!.setReady();
    client.setReady();
    await waitForPhase(client, GamePhase.playing);
    host!.playMove(const NormalMove(from: Square.d2, to: Square.d4));
    await waitForState(client, (s) => s.game.ply == 1);

    // Kill the socket under the client's feet.
    await joined.channel.close();
    await waitForState(host!, (s) => s.phase == GamePhase.paused);
    final resumed = await waitForState(
      host!,
      (s) => s.phase == GamePhase.playing && s.opponentConnected,
    );
    expect(resumed.game.ply, 1);
    await waitForState(
      client,
      (s) => s.phase == GamePhase.playing && s.opponentConnected,
    );

    client.playMove(const NormalMove(from: Square.d7, to: Square.d5));
    final after = await waitForState(host!, (s) => s.game.ply == 2);
    expect(after.game.fen, client.current.game.fen);
  });
}
