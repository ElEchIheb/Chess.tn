import 'dart:async';
import 'dart:io';

import '../domain/game_message.dart';
import '../domain/message_channel.dart';

/// [MessageChannel] over a `dart:io` WebSocket.
class WebSocketMessageChannel implements MessageChannel {
  WebSocketMessageChannel(this._socket) {
    _socket.pingInterval = const Duration(seconds: 4);
    _socket.listen(
      _onData,
      onError: (Object _) => _finish(),
      onDone: _finish,
      cancelOnError: true,
    );
  }

  final WebSocket _socket;
  final StreamController<GameMessage> _controller = StreamController();
  final Completer<void> _done = Completer();
  Completer<GameMessage>? _handshake;

  @override
  Stream<GameMessage> get incoming => _controller.stream;

  @override
  Future<void> get done => _done.future;

  /// Waits for the next message outside of the [incoming] stream. Used for
  /// the join handshake, before a session takes over the channel.
  Future<GameMessage> receiveOne(Duration timeout) {
    final waiter = _handshake = Completer<GameMessage>();
    return waiter.future.timeout(
      timeout,
      onTimeout: () {
        _handshake = null;
        throw TimeoutException('no handshake message');
      },
    );
  }

  void _onData(dynamic data) {
    if (_done.isCompleted) return;
    final waiter = _handshake;
    _handshake = null;
    try {
      if (data is! String) throw const FormatException('binary frame');
      final message = GameMessage.decode(data);
      if (waiter != null) {
        waiter.complete(message);
      } else {
        _controller.add(message);
      }
    } on FormatException catch (error) {
      if (waiter != null) {
        waiter.completeError(error);
      } else {
        _controller.addError(error);
      }
    }
  }

  void _finish() {
    if (_done.isCompleted) return;
    _done.complete();
    final waiter = _handshake;
    _handshake = null;
    if (waiter != null && !waiter.isCompleted) {
      waiter.completeError(const SocketException('connection closed'));
    }
    unawaited(_controller.close());
  }

  @override
  void send(GameMessage message) {
    if (_done.isCompleted || _socket.readyState != WebSocket.open) return;
    _socket.add(message.encode());
  }

  @override
  Future<void> close() async {
    try {
      await _socket.close().timeout(const Duration(seconds: 2));
    } catch (_) {
      // The peer is already gone; nothing left to close politely.
    }
    _finish();
  }
}
