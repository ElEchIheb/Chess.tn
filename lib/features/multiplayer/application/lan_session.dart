import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart';

import '../../chess/application/match_session.dart';
import '../../chess/domain/game_state.dart';
import '../domain/game_message.dart';
import '../domain/message_channel.dart';

/// What host and client sessions share: the channel to the other phone, the
/// heartbeat, and the handling of malformed or hostile input.
abstract class LanSession extends MatchSession {
  LanSession({
    required super.config,
    required super.orientation,
    required super.localSides,
    required MessageChannel channel,
    super.timings,
    super.clock,
  }) : _initialChannel = channel;

  static const int _maxMalformed = 3;

  final MessageChannel _initialChannel;
  MessageChannel? _channel;
  StreamSubscription<GameMessage>? _subscription;
  Timer? _heartbeat;
  final Stopwatch _sinceLastMessage = Stopwatch();
  int _malformed = 0;

  Side get localSide => localSides.first;
  Side get peerSide => localSide.opposite;
  bool get isConnected => _channel != null;

  @override
  void start() {
    attach(_initialChannel);
    publish();
  }

  /// Starts using [channel] for all traffic (first connection or rejoin).
  @protected
  void attach(MessageChannel channel) {
    _detach();
    _channel = channel;
    _malformed = 0;
    _sinceLastMessage
      ..reset()
      ..start();
    _subscription = channel.incoming.listen(
      _onIncoming,
      onError: (Object error) => _onMalformed(),
    );
    unawaited(
      channel.done.then((_) {
        if (identical(_channel, channel)) _lost();
      }),
    );
    _heartbeat = Timer.periodic(timings.heartbeatInterval, (_) {
      if (_sinceLastMessage.elapsed > timings.peerTimeout) {
        _lost();
      } else {
        send(const PingMessage());
      }
    });
  }

  void _detach() {
    _heartbeat?.cancel();
    _heartbeat = null;
    unawaited(_subscription?.cancel());
    _subscription = null;
    final channel = _channel;
    _channel = null;
    if (channel != null) unawaited(channel.close());
  }

  @protected
  void send(GameMessage message) => _channel?.send(message);

  void _onIncoming(GameMessage message) {
    if (isDisposed) return;
    _sinceLastMessage.reset();
    switch (message) {
      case PingMessage():
        send(const PongMessage());
      case PongMessage():
        break;
      case DisconnectMessage(:final reason):
        _detach();
        onPeerLeft(reason);
      default:
        handle(message);
    }
  }

  void _onMalformed() {
    if (++_malformed >= _maxMalformed) fail(DisconnectReason.protocolError);
  }

  void _lost() {
    if (isDisposed || _channel == null) return;
    _detach();
    onConnectionLost();
  }

  /// Ends the match because the peer broke the protocol or the rules.
  @protected
  void fail(DisconnectReason reason) {
    send(DisconnectMessage(reason: reason));
    _detach();
    opponentConnected = false;
    authority.abandon(peerSide);
    publish();
    emit(GameEventType.protocolError);
  }

  /// A game message arrived (heartbeat and disconnect are handled here).
  @protected
  void handle(GameMessage message);

  /// The peer said goodbye: no point waiting for them.
  @protected
  void onPeerLeft(DisconnectReason reason) {
    opponentConnected = false;
    authority.abandon(peerSide);
    publish();
    emit(GameEventType.opponentLeft);
  }

  /// The connection dropped without a goodbye.
  @protected
  void onConnectionLost();

  @override
  Future<void> dispose() async {
    send(const DisconnectMessage(reason: DisconnectReason.left));
    _detach();
    await super.dispose();
  }
}
