import 'dart:async';

import 'game_message.dart';

/// A two-way pipe of [GameMessage]s to the other player.
///
/// Sessions only know this interface, so the same protocol code runs over a
/// real WebSocket and over the in-memory pair used by tests.
abstract interface class MessageChannel {
  /// Decoded incoming messages. Malformed input is reported as a stream
  /// error (a [FormatException]) and never reaches the session as data.
  Stream<GameMessage> get incoming;

  void send(GameMessage message);

  /// Completes when the connection is gone, whoever closed it.
  Future<void> get done;

  Future<void> close();
}

/// Two connected in-memory channels. Used by the unit tests and useful for
/// any future transport-less mode (e.g. a spectator view).
class LoopbackChannelPair {
  LoopbackChannelPair() {
    final first = _LoopbackChannel();
    final second = _LoopbackChannel();
    first.peer = second;
    second.peer = first;
    a = first;
    b = second;
  }

  late final MessageChannel a;
  late final MessageChannel b;
}

class _LoopbackChannel implements MessageChannel {
  final StreamController<GameMessage> _controller = StreamController();
  final Completer<void> _done = Completer();
  late _LoopbackChannel peer;

  /// Raw wire log of everything sent through this end.
  final List<String> sentLog = [];

  @override
  Stream<GameMessage> get incoming => _controller.stream;

  @override
  Future<void> get done => _done.future;

  @override
  void send(GameMessage message) {
    if (_done.isCompleted) return;
    final wire = message.encode();
    sentLog.add(wire);
    // Go through encode/decode exactly like a real socket would.
    scheduleMicrotask(() {
      if (!peer._controller.isClosed) {
        peer._controller.add(GameMessage.decode(wire));
      }
    });
  }

  void _shutdown() {
    if (_done.isCompleted) return;
    _done.complete();
    _controller.close();
  }

  @override
  Future<void> close() async {
    _shutdown();
    scheduleMicrotask(peer._shutdown);
  }
}

/// Everything sent through a loopback channel end, as raw wire strings.
List<String> loopbackSentLog(MessageChannel channel) =>
    (channel as _LoopbackChannel).sentLog;
