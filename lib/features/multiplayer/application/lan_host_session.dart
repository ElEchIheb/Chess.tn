import 'dart:async';

import 'package:dartchess/dartchess.dart';

import '../../chess/domain/game_phase.dart';
import '../../chess/domain/game_state.dart';
import '../../chess/domain/match_authority.dart';
import '../../special_mode/domain/army_placement.dart';
import '../../special_mode/domain/setup_commitment.dart';
import '../domain/game_message.dart';
import '../domain/message_channel.dart';
import 'lan_session.dart';

/// The host phone: referee of the match.
///
/// Everything the client sends is treated as untrusted. Moves are checked
/// for phase, turn, ownership and legality by the [MatchAuthority]; a
/// rejected move is answered with a full [StateSyncMessage].
///
/// Special mode privacy: the host learns the client's army only from
/// [SetupRevealMessage], which the client sends after [SetupLockedMessage],
/// i.e. once the host itself is committed and can no longer change.
class LanHostSession extends LanSession {
  LanHostSession({
    required super.config,
    required super.channel,
    super.timings,
    super.clock,
  }) : super(orientation: Side.white, localSides: {Side.white});

  int _gameNumber = 0;
  ArmyPlacement? _ownArmy;
  String? _ownSalt;
  String? _ownCommitment;
  String? _peerCommitment;
  bool _locked = false;
  Timer? _reconnectTimer;

  /// Whether a dropped client may still come back to this match.
  bool get acceptsRejoin => !isDisposed && !authority.phase.isTerminal;

  bool get _canReadyUp =>
      authority.phase == GamePhase.lobby ||
      authority.phase == GamePhase.gameOver;

  // ---------------------------------------------------------------- lobby

  @override
  void setReady() {
    if (!_canReadyUp || localReady) return;
    localReady = true;
    send(const PlayerReadyMessage());
    publish();
    _maybeStart();
  }

  @override
  void rematch() => setReady();

  void _maybeStart() {
    if (!localReady || !opponentReady || !_canReadyUp) return;
    // Colours swap on every rematch.
    if (authority.phase == GamePhase.gameOver) localSides = {peerSide};
    localReady = false;
    opponentReady = false;
    _gameNumber++;
    authority.start();
    send(
      CreateGameMessage(
        variant: config.variant,
        clientSide: peerSide,
        setupSeconds: config.rules.setupTime.inSeconds,
        gameNumber: _gameNumber,
      ),
    );
    if (config.isSpecial) {
      beginSetup();
    } else {
      beginBattle();
    }
  }

  // ---------------------------------------------------------------- setup

  @override
  void beginSetup() {
    _ownArmy = null;
    _ownSalt = null;
    _ownCommitment = null;
    _peerCommitment = null;
    _locked = false;
    openSetup(localSide);
  }

  @override
  void reportSetupProgress(int placed) {
    if (authority.phase.isSetup) send(SetupUpdateMessage(placed: placed));
  }

  @override
  void submitSetup(ArmyPlacement army) {
    final view = setupView;
    if (view == null ||
        !authority.phase.isSetup ||
        view.localReady ||
        army.side != localSide) {
      return;
    }
    final issues = authority.validator.validateArmy(army);
    if (issues.isNotEmpty) {
      emitEvent(GameEvent(GameEventType.setupInvalid, issues: issues));
      return;
    }
    final salt = SetupCommitment.generateSalt();
    _ownArmy = army;
    _ownSalt = salt;
    _ownCommitment = SetupCommitment.commit(army, salt);
    send(SetupReadyMessage(commitment: _ownCommitment!));
    setupView = view.copyWith(localReady: true);
    publish();
    emit(GameEventType.setupReady);
    _maybeLock();
  }

  @override
  void editSetup() {
    final view = setupView;
    if (view == null || !view.localReady || _locked) return;
    _ownArmy = null;
    _ownSalt = null;
    _ownCommitment = null;
    send(const SetupUnreadyMessage());
    setupView = view.copyWith(localReady: false);
    publish();
  }

  void _maybeLock() {
    if (_locked || _ownCommitment == null || _peerCommitment == null) return;
    _locked = true;
    setupView = setupView?.copyWith(locked: true);
    publish();
    send(const SetupLockedMessage());
  }

  void _onClientReveal(SetupRevealMessage message) {
    if (!_locked || !authority.phase.isSetup) return;
    final ArmyPlacement army;
    try {
      army = ArmyPlacement.fromJson(peerSide, message.army);
    } on FormatException {
      fail(DisconnectReason.protocolError);
      return;
    }
    if (!SetupCommitment.verify(army, message.salt, _peerCommitment!)) {
      fail(DisconnectReason.cheatDetected);
      return;
    }
    final own = _ownArmy!;
    try {
      authority
        ..submitArmy(army)
        ..submitArmy(own);
    } on MatchRuleException {
      fail(DisconnectReason.cheatDetected);
      return;
    }
    beginReveal();
    _sendReveal();
  }

  void _sendReveal() {
    final white = authority.revealedArmy(Side.white);
    final black = authority.revealedArmy(Side.black);
    final salt = _ownSalt;
    if (white == null || black == null || salt == null) return;
    send(RevealGameMessage(white: white, black: black, hostSalt: salt));
  }

  @override
  void onStartResolved() => send(PhaseMessage(phase: authority.phase));

  @override
  void relocateKing(Square square) {
    if (authority.phase != GamePhase.kingRescue ||
        authority.rescueSide != localSide ||
        !authority.rescueSquares.contains(square)) {
      return;
    }
    send(KingRelocateMessage(side: localSide, square: square));
    applyRescue(localSide, square);
  }

  // --------------------------------------------------------------- battle

  @override
  void playMove(NormalMove move) {
    if (!current.canMove) return;
    final ply = authority.game.ply;
    final record = applyMove(localSide, move);
    if (record == null) {
      emit(GameEventType.illegalMove);
      return;
    }
    send(MoveMessage(uci: record.uci, ply: ply));
    _announceIfOver();
  }

  void _onClientMove(MoveMessage message) {
    final move = message.uci.length >= 4 ? Move.parse(message.uci) : null;
    final record = message.ply != authority.game.ply || move is! NormalMove
        ? null
        : applyMove(peerSide, move);
    if (record == null) {
      // Refused: put the client back on the real position.
      _sendSync();
      return;
    }
    // Acknowledge, so a client that was resynchronised meanwhile catches up.
    send(MoveMessage(uci: record.uci, ply: message.ply));
    _announceIfOver();
  }

  void _announceIfOver() {
    final outcome = authority.outcome;
    if (outcome != null) {
      localReady = false;
      opponentReady = false;
      send(GameOverMessage(outcome: outcome));
    }
  }

  void _sendSync() {
    final game = authority.game;
    send(
      StateSyncMessage(
        initialFen: game.initialFen,
        moves: game.uciMoves,
        white: authority.revealedArmy(Side.white),
        black: authority.revealedArmy(Side.black),
      ),
    );
  }

  @override
  void resign() {
    if (endWith(() => authority.resign(localSide))) _announceIfOver();
  }

  @override
  void offerDraw() {
    if (authority.phase != GamePhase.playing || drawOfferFrom != null) return;
    drawOfferFrom = localSide;
    publish();
    send(const DrawRequestMessage());
  }

  @override
  void respondToDraw({required bool accept}) {
    if (drawOfferFrom != peerSide) return;
    if (accept) {
      if (endWith(authority.agreeDraw)) _announceIfOver();
    } else {
      drawOfferFrom = null;
      publish();
      send(const DrawResponseMessage(accepted: false));
    }
  }

  // ------------------------------------------------------------- messages

  @override
  void handle(GameMessage message) {
    final view = setupView;
    final inSetup = authority.phase.isSetup && view != null;
    switch (message) {
      case PlayerReadyMessage():
        if (!_canReadyUp) return;
        opponentReady = true;
        publish();
        emit(GameEventType.opponentReady);
        _maybeStart();

      case SetupUpdateMessage(:final placed):
        if (!inSetup || _locked) return;
        setupView = view.copyWith(
          opponentPlaced: placed.clamp(0, config.rules.armySize),
        );
        publish();

      case SetupReadyMessage(:final commitment):
        if (!inSetup || _locked) return;
        _peerCommitment = commitment;
        setupView = view.copyWith(
          opponentReady: true,
          opponentPlaced: config.rules.armySize,
        );
        publish();
        emit(GameEventType.opponentReady);
        _maybeLock();

      case SetupUnreadyMessage():
        if (!inSetup || _locked) return;
        _peerCommitment = null;
        setupView = view.copyWith(opponentReady: false);
        publish();
        send(const SetupUnreadyMessage()); // acknowledgement

      case SetupRevealMessage():
        _onClientReveal(message);

      case KingRelocateMessage(:final side, :final square):
        if (side != peerSide || !applyRescue(peerSide, square)) {
          fail(DisconnectReason.protocolError);
        }

      case MoveMessage():
        _onClientMove(message);

      case ResignMessage():
        if (endWith(() => authority.resign(peerSide))) _announceIfOver();

      case DrawRequestMessage():
        if (authority.phase != GamePhase.playing) return;
        drawOfferFrom = peerSide;
        publish();
        emit(GameEventType.drawOffered);

      case DrawResponseMessage(:final accepted):
        if (drawOfferFrom != localSide) return;
        if (accepted) {
          if (endWith(authority.agreeDraw)) _announceIfOver();
        } else {
          drawOfferFrom = null;
          publish();
          emit(GameEventType.drawDeclined);
        }

      // Host-only messages: a client has no business sending them.
      case CreateGameMessage() ||
          JoinGameMessage() ||
          JoinAcceptedMessage() ||
          SetupLockedMessage() ||
          RevealGameMessage() ||
          PhaseMessage() ||
          GameOverMessage() ||
          StateSyncMessage() ||
          PingMessage() ||
          PongMessage() ||
          DisconnectMessage():
        break;
    }
  }

  // ----------------------------------------------------------- connection

  @override
  void onPeerLeft(DisconnectReason reason) {
    _reconnectTimer?.cancel();
    super.onPeerLeft(reason);
  }

  @override
  void onConnectionLost() {
    opponentConnected = false;
    if (authority.phase.isTerminal) {
      publish();
      emit(GameEventType.opponentLeft);
      return;
    }
    pauseMatch();
    emit(GameEventType.opponentDisconnected);
    _reconnectTimer = schedule(timings.reconnectWindow, () {
      authority.abandon(peerSide);
      publish();
      emit(GameEventType.opponentLeft);
    });
  }

  /// The same client came back on a new connection.
  void reattach(MessageChannel channel) {
    _reconnectTimer?.cancel();
    attach(channel);
    opponentConnected = true;
    resumeMatch();
    emit(GameEventType.opponentReconnected);
    _resync();
  }

  void _resync() {
    switch (authority.phase) {
      case GamePhase.lobby:
        if (localReady) send(const PlayerReadyMessage());
      case GamePhase.gameOver:
        send(GameOverMessage(outcome: authority.outcome!));
        if (localReady) send(const PlayerReadyMessage());
      case GamePhase.setupWhite || GamePhase.setupBlack:
        final commitment = _ownCommitment;
        if (commitment != null) {
          send(SetupReadyMessage(commitment: commitment));
        }
        if (_locked) send(const SetupLockedMessage());
      case GamePhase.reveal || GamePhase.kingRescue:
        _sendReveal();
        if (authority.phase == GamePhase.kingRescue) {
          send(PhaseMessage(phase: authority.phase));
        }
      case GamePhase.playing:
        _sendSync();
      case GamePhase.waitingForPlayer ||
          GamePhase.paused ||
          GamePhase.abandoned:
        break;
    }
  }
}
