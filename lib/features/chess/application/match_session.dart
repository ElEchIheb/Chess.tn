import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart';

import '../domain/chess_game.dart';
import '../domain/game_phase.dart';
import '../domain/game_state.dart';
import '../domain/match_authority.dart';
import 'game_session.dart';

/// Base for every session: drives a [MatchAuthority] and turns it into
/// [GameState] snapshots. Subclasses add what is specific to their opponent
/// (AI thinking, network messages).
abstract class MatchSession extends GameSession {
  MatchSession({
    required this.config,
    required this.orientation,
    required this.localSides,
    this.timings = const SessionTimings(),
    DateTime Function()? clock,
  }) : now = clock ?? DateTime.now,
       authority = MatchAuthority(variant: config.variant, rules: config.rules),
       super(
         GameState(
           config: config,
           phase: GamePhase.lobby,
           orientation: orientation,
           localSides: localSides,
           game: ChessGame.standard(),
         ),
       );

  final GameConfig config;
  final SessionTimings timings;
  final DateTime Function() now;

  @protected
  MatchAuthority authority;

  @protected
  Side orientation;

  @protected
  Set<Side> localSides;

  @protected
  SetupView? setupView;

  @protected
  bool aiThinking = false;

  @protected
  Side? drawOfferFrom;

  @protected
  bool localReady = false;

  @protected
  bool opponentReady = false;

  @protected
  bool opponentConnected = true;

  DateTime? _startedAt;
  DateTime? _endedAt;
  int _revealCount = 0;
  int _setupRound = 0;
  bool _revealFinishPending = false;
  final List<Timer> _timers = [];

  // ------------------------------------------------------------- helpers

  /// Runs [action] after [delay]; cancelled automatically on dispose.
  @protected
  Timer schedule(Duration delay, void Function() action) {
    late final Timer timer;
    timer = Timer(delay, () {
      _timers.remove(timer);
      if (!isDisposed) action();
    });
    _timers.add(timer);
    return timer;
  }

  @protected
  void replaceAuthority() {
    authority = MatchAuthority(variant: config.variant, rules: config.rules);
  }

  GamePhase _view(GamePhase phase) {
    final view = setupView;
    if (!phase.isSetup || view == null) return phase;
    if (view.localReady) return GamePhase.waitingForPlayer;
    return view.side == Side.white
        ? GamePhase.setupWhite
        : GamePhase.setupBlack;
  }

  bool get _inSetup =>
      authority.phase.isSetup || (authority.pausedFrom?.isSetup ?? false);

  /// Publishes a fresh [GameState] built from the authority.
  @protected
  void publish() {
    final paused = authority.pausedFrom;
    update(
      GameState(
        config: config,
        phase: _view(authority.phase),
        pausedFrom: paused == null ? null : _view(paused),
        orientation: orientation,
        localSides: localSides,
        game: authority.game,
        setup: _inSetup ? setupView : null,
        whiteArmy: authority.revealedArmy(Side.white),
        blackArmy: authority.revealedArmy(Side.black),
        rescueSide: authority.rescueSide,
        rescueSquares: authority.rescueSquares,
        outcome: authority.outcome,
        aiThinking: aiThinking,
        drawOfferFrom: drawOfferFrom,
        localReady: localReady,
        opponentReady: opponentReady,
        opponentConnected: opponentConnected,
        startedAt: _startedAt,
        endedAt: _endedAt,
        revealCount: _revealCount,
      ),
    );
  }

  // ---------------------------------------------------------------- setup

  /// Opens a fresh private setup round for [side] on this device.
  @protected
  void openSetup(Side side) {
    setupView = SetupView(
      side: side,
      deadline: now().add(config.rules.setupTime),
      round: ++_setupRound,
    );
    orientation = side;
    publish();
  }

  /// Called when a new setup round must begin (start or redo).
  @protected
  void beginSetup();

  // --------------------------------------------------------------- reveal

  /// Both armies are in the authority: open the curtain.
  @protected
  void beginReveal({bool autoFinish = true}) {
    authority.reveal();
    _revealCount++;
    setupView = null;
    publish();
    emit(GameEventType.revealStart);
    schedule(timings.curtainAt, () => emit(GameEventType.curtainOpen));
    if (autoFinish) schedule(timings.revealDuration, finishReveal);
  }

  @protected
  void finishReveal() {
    if (authority.phase == GamePhase.paused &&
        authority.pausedFrom == GamePhase.reveal) {
      _revealFinishPending = true;
      return;
    }
    if (authority.phase != GamePhase.reveal) return;
    _handleStart(authority.completeReveal());
  }

  /// Applies a king relocation and moves on.
  @protected
  bool applyRescue(Side side, Square square) {
    try {
      authority.relocateKing(side, square);
    } on MatchRuleException {
      return false;
    }
    _handleStart(switch (authority.phase) {
      GamePhase.playing => RevealResult.battle,
      GamePhase.kingRescue => RevealResult.kingRescue,
      _ => RevealResult.redoSetup,
    });
    return true;
  }

  void _handleStart(RevealResult result) {
    switch (result) {
      case RevealResult.battle:
        beginBattle();
      case RevealResult.kingRescue:
        publish();
        emit(GameEventType.kingRescue);
        onKingRescue();
      case RevealResult.redoSetup:
        emit(GameEventType.setupRedo);
        beginSetup();
    }
    onStartResolved();
  }

  /// Hook: the authority left the reveal / rescue step (host notifies peer).
  @protected
  void onStartResolved() {}

  /// Hook: a king needs rescuing (the AI answers for its own king).
  @protected
  void onKingRescue() {}

  // --------------------------------------------------------------- battle

  @protected
  void beginBattle() {
    _startedAt = now();
    _endedAt = null;
    drawOfferFrom = null;
    orientation = localSides.length == 1 ? localSides.first : Side.white;
    publish();
    emit(
      config.isSpecial ? GameEventType.battleStart : GameEventType.gameStart,
    );
    onBattleStarted();
  }

  @protected
  void onBattleStarted() {}

  /// Plays [move] for [side] through the authority. Returns `null` when the
  /// authority refuses it.
  @protected
  MoveRecord? applyMove(Side side, NormalMove move) {
    final MoveRecord record;
    try {
      record = authority.play(side, move);
    } on MatchRuleException {
      return null;
    }
    drawOfferFrom = null;
    final over = authority.outcome != null;
    if (over) {
      _endedAt = now();
      localReady = false;
      opponentReady = false;
    }
    publish();
    emit(
      record.isCastle
          ? GameEventType.castle
          : record.isPromotion
          ? GameEventType.promotion
          : record.isCapture
          ? GameEventType.capture
          : GameEventType.move,
    );
    if (over) {
      emit(GameEventType.gameOver);
    } else if (record.givesCheck) {
      emit(GameEventType.check);
    }
    return record;
  }

  /// Runs an authority action that may end the game (resign, draw...).
  @protected
  bool endWith(void Function() action) {
    try {
      action();
    } on MatchRuleException {
      return false;
    }
    markEnded();
    return true;
  }

  /// Publishes the end of the game once the authority has an outcome.
  @protected
  void markEnded() {
    _endedAt ??= now();
    drawOfferFrom = null;
    aiThinking = false;
    localReady = false;
    opponentReady = false;
    publish();
    emit(GameEventType.gameOver);
  }

  // ----------------------------------------------------------- connection

  @protected
  void pauseMatch() {
    authority.pause();
    publish();
  }

  @protected
  void resumeMatch() {
    authority.resume();
    publish();
    if (_revealFinishPending) {
      _revealFinishPending = false;
      finishReveal();
    }
  }

  @override
  Future<void> dispose() async {
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
    await super.dispose();
  }
}
