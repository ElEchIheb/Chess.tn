import 'dart:async';

import 'package:dartchess/dartchess.dart';

import '../../chess/domain/chess_game.dart';
import '../../chess/domain/game_phase.dart';
import '../../chess/domain/game_state.dart';
import '../../chess/domain/match_authority.dart';
import '../../special_mode/domain/army_placement.dart';
import '../../special_mode/domain/setup_commitment.dart';
import '../domain/game_message.dart';
import '../domain/message_channel.dart';
import 'lan_session.dart';

/// Opens a new connection to the same host, or returns `null` on failure.
typedef ChannelConnector = Future<MessageChannel?> Function();

/// The joining phone.
///
/// It keeps its own replica of the match and re-validates everything the
/// host sends (moves, armies, results): the host is not trusted blindly
/// either. In Special mode the client's army leaves this object only as a
/// commitment until the host confirms that both players are locked in.
class LanClientSession extends LanSession {
  LanClientSession({
    required super.config,
    required super.channel,
    ChannelConnector? reconnect,
    super.timings,
    super.clock,
    // ignore: prefer_initializing_formals
  }) : _reconnect = reconnect,
       super(orientation: Side.black, localSides: {Side.black});

  final ChannelConnector? _reconnect;

  ArmyPlacement? _ownArmy;
  String? _ownSalt;
  String? _peerCommitment;
  bool _locked = false;
  bool _unreadyPending = false;
  bool _resignSent = false;
  bool _drawAccepted = false;
  bool _reconnecting = false;

  /// Last move sent to the host, until it is acknowledged.
  int? _sentPly;
  String? _sentUci;

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
  }

  @override
  void rematch() => setReady();

  void _onCreateGame(CreateGameMessage message) {
    if (message.variant != config.variant) {
      fail(DisconnectReason.protocolError);
      return;
    }
    replaceAuthority();
    localSides = {message.clientSide};
    localReady = false;
    opponentReady = false;
    _resignSent = false;
    _drawAccepted = false;
    _sentPly = null;
    _sentUci = null;
    authority.start();
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
    _peerCommitment = null;
    _locked = false;
    _unreadyPending = false;
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
    // Only the hash leaves the phone here.
    send(SetupReadyMessage(commitment: SetupCommitment.commit(army, salt)));
    setupView = view.copyWith(localReady: true);
    publish();
    emit(GameEventType.setupReady);
  }

  /// Asks the host to release the commitment. The army stays committed
  /// until the host acknowledges, because the host may lock at any moment.
  @override
  void editSetup() {
    final view = setupView;
    if (view == null || !view.localReady || _locked || _unreadyPending) return;
    _unreadyPending = true;
    send(const SetupUnreadyMessage());
  }

  void _onLocked() {
    final army = _ownArmy;
    final salt = _ownSalt;
    if (!authority.phase.isSetup || army == null || salt == null) {
      fail(DisconnectReason.protocolError);
      return;
    }
    _locked = true;
    _unreadyPending = false;
    setupView = setupView?.copyWith(localReady: true, locked: true);
    publish();
    send(SetupRevealMessage(army: army.toJson(), salt: salt));
  }

  void _onRevealGame(RevealGameMessage message) {
    if (!authority.phase.isSetup) return; // duplicate after a reconnection
    final commitment = _peerCommitment;
    if (!_locked || commitment == null) {
      fail(DisconnectReason.protocolError);
      return;
    }
    final mine = localSide == Side.white ? message.white : message.black;
    final theirs = localSide == Side.white ? message.black : message.white;
    if (mine != _ownArmy ||
        !SetupCommitment.verify(theirs, message.hostSalt, commitment)) {
      fail(DisconnectReason.cheatDetected);
      return;
    }
    try {
      authority
        ..submitArmy(message.white)
        ..submitArmy(message.black);
    } on MatchRuleException {
      fail(DisconnectReason.cheatDetected);
      return;
    }
    beginReveal(autoFinish: false);
  }

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
    _sentPly = ply;
    _sentUci = record.uci;
    send(MoveMessage(uci: record.uci, ply: ply));
  }

  /// A move from the host: either the host's own move, or the echo that
  /// acknowledges ours.
  void _onHostMove(MoveMessage message) {
    final game = authority.game;
    final isOurs = message.ply == _sentPly && message.uci == _sentUci;
    if (isOurs &&
        message.ply == game.ply - 1 &&
        game.lastMove?.uci == message.uci) {
      return; // already applied optimistically
    }
    final move = message.uci.length >= 4 ? Move.parse(message.uci) : null;
    final side = game.turn;
    // The host may never move our pieces, except by echoing our own move
    // (needed when a resync rolled the optimistic move back).
    if (message.ply != game.ply ||
        move is! NormalMove ||
        (side == localSide && !isOurs) ||
        applyMove(side, move) == null) {
      fail(DisconnectReason.protocolError);
    }
  }

  void _onGameOver(GameOutcome outcome) {
    if (authority.phase == GamePhase.gameOver) return;
    if (!_isPlausible(outcome)) {
      fail(DisconnectReason.cheatDetected);
      return;
    }
    authority.forceOutcome(outcome);
    if (authority.outcome != null) markEnded();
  }

  /// A result announced by the host must be explainable by what this phone
  /// did or saw; rule-based endings are detected by the local replica.
  bool _isPlausible(GameOutcome outcome) => switch (outcome.reason) {
    GameEndReason.resignation => outcome.winner == localSide || _resignSent,
    GameEndReason.drawAgreement => _drawAccepted || drawOfferFrom == localSide,
    GameEndReason.abandonment => outcome.winner == localSide,
    _ => authority.game.outcome == outcome,
  };

  @override
  void resign() {
    if (authority.phase != GamePhase.playing) return;
    _resignSent = true;
    send(const ResignMessage());
    endWith(() => authority.resign(localSide));
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
    _drawAccepted = accept;
    drawOfferFrom = null;
    publish();
    send(DrawResponseMessage(accepted: accept));
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

      case CreateGameMessage():
        _onCreateGame(message);

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

      case SetupUnreadyMessage():
        if (!inSetup || _locked) return;
        if (_unreadyPending) {
          // The host released our commitment: back to editing.
          _unreadyPending = false;
          _ownArmy = null;
          _ownSalt = null;
          setupView = view.copyWith(localReady: false);
        } else {
          _peerCommitment = null;
          setupView = view.copyWith(opponentReady: false);
        }
        publish();

      case SetupLockedMessage():
        _onLocked();

      case RevealGameMessage():
        _onRevealGame(message);

      case PhaseMessage():
        if (authority.phase == GamePhase.reveal) finishReveal();

      case KingRelocateMessage(:final side, :final square):
        if (side != peerSide || !applyRescue(peerSide, square)) {
          fail(DisconnectReason.protocolError);
        }

      case MoveMessage():
        _onHostMove(message);

      case StateSyncMessage():
        final restored = authority.restoreBattle(
          initialFen: message.initialFen,
          uciMoves: message.moves,
          white: message.white,
          black: message.black,
        );
        if (!restored) {
          fail(DisconnectReason.protocolError);
          return;
        }
        publish();

      case GameOverMessage(:final outcome):
        _onGameOver(outcome);

      case DrawRequestMessage():
        if (authority.phase != GamePhase.playing) return;
        drawOfferFrom = peerSide;
        publish();
        emit(GameEventType.drawOffered);

      case DrawResponseMessage(:final accepted):
        if (drawOfferFrom != localSide || accepted) return;
        drawOfferFrom = null;
        publish();
        emit(GameEventType.drawDeclined);

      // Client-only or transport messages: nothing to do.
      case JoinGameMessage() ||
          JoinAcceptedMessage() ||
          SetupRevealMessage() ||
          ResignMessage() ||
          PingMessage() ||
          PongMessage() ||
          DisconnectMessage():
        break;
    }
  }

  // ----------------------------------------------------------- connection

  @override
  void onConnectionLost() {
    opponentConnected = false;
    if (authority.phase.isTerminal) {
      publish();
      emit(GameEventType.opponentLeft);
      return;
    }
    pauseMatch();
    emit(GameEventType.connectionLost);
    unawaited(_reconnectLoop());
  }

  Future<void> _reconnectLoop() async {
    final connector = _reconnect;
    if (_reconnecting) return;
    _reconnecting = true;
    final clock = Stopwatch()..start();
    try {
      while (connector != null &&
          !isDisposed &&
          clock.elapsed < timings.reconnectWindow) {
        await Future<void>.delayed(timings.reconnectRetry);
        if (isDisposed) return;
        final channel = await connector();
        if (isDisposed) {
          await channel?.close();
          return;
        }
        if (channel != null) {
          attach(channel);
          opponentConnected = true;
          resumeMatch();
          emit(GameEventType.opponentReconnected);
          _resendOwnState();
          return;
        }
      }
    } finally {
      _reconnecting = false;
    }
    if (isDisposed) return;
    authority.abandon(peerSide);
    publish();
    emit(GameEventType.opponentLeft);
  }

  void _resendOwnState() {
    if (_canReadyUp) {
      if (localReady) send(const PlayerReadyMessage());
      return;
    }
    final army = _ownArmy;
    final salt = _ownSalt;
    if (authority.phase.isSetup &&
        (setupView?.localReady ?? false) &&
        !_locked &&
        army != null &&
        salt != null) {
      send(SetupReadyMessage(commitment: SetupCommitment.commit(army, salt)));
    }
  }
}
