import 'package:dartchess/dartchess.dart';

/// What is being dragged during setup: a new piece from the tray, or one
/// that is already on the board.
class SetupDrag {
  const SetupDrag.fromTray(Role this.role) : from = null;
  const SetupDrag.fromBoard(Square this.from) : role = null;

  final Role? role;
  final Square? from;
}
