import 'dart:async';
import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/sound_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/board_theme.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/widgets/game_button.dart';
import '../../chess/application/game_session.dart';
import '../../chess/domain/game_state.dart';
import '../../chess/presentation/widgets/board_painter.dart';
import '../../chess/presentation/widgets/chess_piece.dart';
import '../../settings/application/settings_controller.dart';
import '../domain/army_placement.dart';
import '../domain/special_position_validator.dart';
import '../domain/special_rules.dart';
import 'widgets/curtain.dart';
import 'widgets/piece_tray.dart';
import 'widgets/setup_drag.dart';

/// The private army-building screen of the Special mode.
///
/// The draft army lives only in this widget's state until the player taps
/// "Done". The opponent's half of the board is behind the curtain and this
/// widget is never given the opponent's pieces — only their status.
class SetupStage extends ConsumerStatefulWidget {
  const SetupStage({super.key, required this.state, required this.session});

  final GameState state;
  final GameSession session;

  @override
  ConsumerState<SetupStage> createState() => _SetupStageState();
}

class _SetupStageState extends ConsumerState<SetupStage> {
  late ArmyPlacement _draft;
  Role? _trayRole;
  Square? _selected;
  Square? _flash;
  String? _message;
  Timer? _ticker;
  Timer? _flashTimer;
  bool _timedOut = false;
  final Random _random = Random();

  SetupView get _view => widget.state.setup!;
  SpecialRules get _rules => widget.state.config.rules;
  SpecialPositionValidator get _validator => SpecialPositionValidator(_rules);
  Side get _side => _view.side;
  bool get _editable => !_view.localReady && !_view.locked;

  @override
  void initState() {
    super.initState();
    _draft = ArmyPlacement.empty(_side);
    _trayRole = _nextTrayRole();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _flashTimer?.cancel();
    super.dispose();
  }

  Duration get _remaining {
    final left = _view.deadline.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  void _onTick() {
    if (!mounted) return;
    if (_remaining == Duration.zero && _editable && !_timedOut) {
      _timedOut = true;
      _autoPlace();
      _message = context.l10n.timeUp;
      widget.session.submitSetup(_draft);
    }
    setState(() {});
  }

  Role? _nextTrayRole() {
    for (final role in SpecialRules.trayOrder) {
      if (_validator.remaining(_draft, role) > 0) return role;
    }
    return null;
  }

  void _changed(ArmyPlacement next, {bool sound = true}) {
    setState(() {
      _draft = next;
      _selected = null;
      _message = null;
      final role = _trayRole;
      if (role == null || _validator.remaining(next, role) <= 0) {
        _trayRole = _nextTrayRole();
      }
    });
    if (sound) {
      ref.read(soundServiceProvider)
        ..play(Sfx.place)
        ..haptic();
    }
    widget.session.reportSetupProgress(next.total);
  }

  void _reject(Square square, String message) {
    ref.read(soundServiceProvider)
      ..play(Sfx.illegal)
      ..haptic(strong: true);
    _flashTimer?.cancel();
    setState(() {
      _flash = square;
      _message = message;
    });
    _flashTimer = Timer(const Duration(milliseconds: 450), () {
      if (mounted) setState(() => _flash = null);
    });
  }

  String _whyNot(Role role, Square square) =>
      _rules.inZone(_side, square) && role == Role.pawn
      ? context.l10n.pawnBackRank
      : context.l10n.outsideZone;

  void _placeFromTray(Role role, Square square) {
    if (!_editable || _validator.remaining(_draft, role) <= 0) return;
    if (!_validator.canPlace(_draft, role, square)) {
      _reject(square, _whyNot(role, square));
      return;
    }
    _changed(_draft.place(square, role));
  }

  void _moveOnBoard(Square from, Square to) {
    if (!_editable || from == to) return;
    final moving = _draft.roleAt(from);
    if (moving == null) return;
    if (!_validator.canPlace(_draft, moving, to)) {
      _reject(to, _whyNot(moving, to));
      return;
    }
    final displaced = _draft.roleAt(to);
    if (displaced != null && !_validator.canPlace(_draft, displaced, from)) {
      _reject(from, _whyNot(displaced, from));
      return;
    }
    _changed(_draft.move(from, to));
  }

  void _remove(Square square) {
    if (!_editable || _draft.roleAt(square) == null) return;
    _changed(_draft.remove(square));
  }

  void _onSquareTap(Square square) {
    if (!_editable) return;
    final selected = _selected;
    if (selected != null) {
      if (selected == square) {
        setState(() => _selected = null);
      } else {
        _moveOnBoard(selected, square);
      }
      return;
    }
    if (_draft.roleAt(square) != null) {
      setState(() => _selected = square);
      return;
    }
    final role = _trayRole;
    if (role != null) _placeFromTray(role, square);
  }

  void _onDrop(SetupDrag drag, Square square) {
    final role = drag.role;
    final from = drag.from;
    if (role != null) {
      _placeFromTray(role, square);
    } else if (from != null) {
      _moveOnBoard(from, square);
    }
  }

  void _reset() {
    if (!_editable) return;
    _changed(ArmyPlacement.empty(_side), sound: false);
    setState(() => _trayRole = _nextTrayRole());
  }

  /// Puts every remaining piece on a random allowed square.
  void _autoPlace() {
    if (!_editable) return;
    var next = _draft;
    for (final role in SpecialRules.trayOrder) {
      while (_validator.remaining(next, role) > 0) {
        final free = [
          for (final square in _rules.zoneSquares(_side))
            if (next.roleAt(square) == null &&
                _rules.allows(_side, role, square))
              square,
        ];
        if (free.isEmpty) break;
        next = next.place(free[_random.nextInt(free.length)], role);
      }
    }
    _changed(next);
  }

  void _submit() {
    final issues = _validator.validateArmy(_draft);
    if (issues.isNotEmpty) {
      setState(
        () => _message = context.l10n.setupIssue(
          issues,
          missing: _rules.armySize - _draft.total,
        ),
      );
      return;
    }
    widget.session.submitSetup(_draft);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider);
    final view = _view;
    final complete = _validator.isComplete(_draft);
    final remaining = _remaining;
    final urgent = remaining.inSeconds <= 15 && _editable;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.buildYourArmy,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      l10n.buildYourArmyHint,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              _TimerChip(text: formatClock(remaining), urgent: urgent),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: BoardFrame(
                  colors: settings.boardTheme.colors,
                  child: LayoutBuilder(
                    builder: (context, constraints) => _buildBoard(
                      constraints.biggest.shortestSide,
                      settings.animations,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (_editable) ...[
          PieceTray(
            army: _draft,
            validator: _validator,
            side: _side,
            pieceTheme: settings.pieceTheme,
            selected: _trayRole,
            onSelect: (role) => setState(() {
              _trayRole = role;
              _selected = null;
            }),
            onRemove: _remove,
          ),
          _MessageLine(
            text:
                _message ??
                (complete
                    ? l10n.allPlaced
                    : _draft.isEmpty
                    ? l10n.dragHint
                    : l10n.missingPieces(_rules.armySize - _draft.total)),
            isError: _flash != null,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                if (_selected != null)
                  _SmallAction(
                    icon: Icons.backspace_outlined,
                    label: l10n.removePiece,
                    onTap: () => _remove(_selected!),
                  )
                else
                  _SmallAction(
                    icon: Icons.restart_alt_rounded,
                    label: l10n.reset,
                    onTap: _draft.isEmpty ? null : _reset,
                  ),
                const SizedBox(width: 8),
                _SmallAction(
                  icon: Icons.auto_awesome_rounded,
                  label: l10n.autoPlace,
                  onTap: complete ? null : _autoPlace,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GameButton(
                    label: l10n.done,
                    icon: Icons.check_rounded,
                    onPressed: complete ? _submit : null,
                  ),
                ),
              ],
            ),
          ),
        ] else
          _WaitingPanel(
            message: view.locked ? l10n.lockedIn : l10n.waitingOpponentArmy,
            canEdit: !view.locked,
            onEdit: widget.session.editSetup,
            editLabel: l10n.editArmy,
          ),
      ],
    );
  }

  Widget _buildBoard(double size, bool animateCurtain) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider);
    final geometry = BoardGeometry(size, _side);
    final square = geometry.square;
    final view = _view;
    final showStatus = widget.state.config.opponent != OpponentType.passAndPlay;

    return Stack(
      children: [
        CustomPaint(
          size: Size.square(size),
          painter: BoardPainter(
            fontFamily: DefaultTextStyle.of(context).style.fontFamily,
            colors: settings.boardTheme.colors,
            orientation: _side,
            selected: _selected,
            check: _flash,
          ),
        ),
        for (final zoneSquare in _rules.zoneSquares(_side))
          Positioned.fromRect(
            rect: geometry.rectOf(zoneSquare),
            child: _SetupSquare(
              square: zoneSquare,
              role: _draft.roleAt(zoneSquare),
              side: _side,
              size: square,
              pieceTheme: settings.pieceTheme,
              enabled: _editable,
              onTap: () => _onSquareTap(zoneSquare),
              onDrop: (drag) => _onDrop(drag, zoneSquare),
            ),
          ),
        // The opponent's half: nothing is drawn under the curtain.
        Positioned(
          left: 0,
          top: 0,
          width: size,
          height: size / 2,
          child: Curtain(
            open: 0,
            animateIdle: animateCurtain,
            child: CurtainLabel(
              title: l10n.opponentHidden,
              status: !showStatus
                  ? null
                  : view.opponentReady
                  ? l10n.opponentArmyReady
                  : l10n.opponentPlacing(view.opponentPlaced, _rules.armySize),
              ready: view.opponentReady,
            ),
          ),
        ),
      ],
    );
  }
}

class _SetupSquare extends StatelessWidget {
  const _SetupSquare({
    required this.square,
    required this.role,
    required this.side,
    required this.size,
    required this.pieceTheme,
    required this.enabled,
    required this.onTap,
    required this.onDrop,
  });

  final Square square;
  final Role? role;
  final Side side;
  final double size;
  final PieceTheme pieceTheme;
  final bool enabled;
  final VoidCallback onTap;
  final void Function(SetupDrag drag) onDrop;

  @override
  Widget build(BuildContext context) {
    final role = this.role;
    final piece = role == null
        ? null
        : ChessPiece(
            piece: Piece(color: side, role: role),
            theme: pieceTheme,
            size: size,
          );

    return DragTarget<SetupDrag>(
      onWillAcceptWithDetails: (details) => enabled,
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidates, rejected) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? onTap : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: candidates.isNotEmpty
                  ? AppColors.gold.withValues(alpha: 0.45)
                  : null,
            ),
            child: piece == null || !enabled
                ? piece ?? const SizedBox.expand()
                : Draggable<SetupDrag>(
                    data: SetupDrag.fromBoard(square),
                    dragAnchorStrategy: pointerDragAnchorStrategy,
                    feedback: DragFeedback(
                      piece: Piece(color: side, role: role!),
                      pieceTheme: pieceTheme,
                      size: size * 1.3,
                    ),
                    childWhenDragging: Opacity(opacity: 0.25, child: piece),
                    child: piece,
                  ),
          ),
        );
      },
    );
  }
}

class _TimerChip extends StatelessWidget {
  const _TimerChip({required this.text, required this.urgent});

  final String text;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: urgent ? AppColors.redDark : AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 18,
            color: urgent ? AppColors.white : AppColors.gold,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageLine extends StatelessWidget {
  const _MessageLine({required this.text, required this.isError});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
      child: SizedBox(
        height: 36,
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: isError ? AppColors.danger : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  const _SmallAction({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GameIconButton(
      icon: icon,
      tooltip: label,
      size: 54,
      onPressed: onTap,
    );
  }
}

class _WaitingPanel extends StatelessWidget {
  const _WaitingPanel({
    required this.message,
    required this.canEdit,
    required this.onEdit,
    required this.editLabel,
  });

  final String message;
  final bool canEdit;
  final VoidCallback onEdit;
  final String editLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outline),
        ),
        child: Column(
          children: [
            Row(
              children: [
                canEdit
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          color: AppColors.gold,
                        ),
                      )
                    : const Icon(Icons.lock_rounded, color: AppColors.gold),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (canEdit) ...[
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: Text(editLabel),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
