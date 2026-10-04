import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart';

/// One player's private arrangement of pieces: square -> piece type.
///
/// This is the hidden information of the Special mode. It must never be put
/// in a public state object or sent over the network before the reveal.
@immutable
class ArmyPlacement {
  // ignore: prefer_const_constructors_in_immutables
  ArmyPlacement(this.side, Map<Square, Role> pieces)
    : pieces = Map.unmodifiable(pieces);

  const ArmyPlacement.empty(this.side) : pieces = const {};

  /// The classical starting arrangement for [side].
  factory ArmyPlacement.standard(Side side) {
    const backRank = [
      Role.rook,
      Role.knight,
      Role.bishop,
      Role.queen,
      Role.king,
      Role.bishop,
      Role.knight,
      Role.rook,
    ];
    final back = side == Side.white ? Rank.first : Rank.eighth;
    final pawns = side == Side.white ? Rank.second : Rank.seventh;
    return ArmyPlacement(side, {
      for (var f = 0; f < 8; f++) ...{
        Square.fromCoords(File(f), back): backRank[f],
        Square.fromCoords(File(f), pawns): Role.pawn,
      },
    });
  }

  /// Strict parser for untrusted input. Throws [FormatException].
  factory ArmyPlacement.fromJson(Side side, Object? json) {
    if (json is! Map) throw const FormatException('army: expected an object');
    if (json.length > 64) throw const FormatException('army: too many pieces');
    final pieces = <Square, Role>{};
    for (final entry in json.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String || value is! String || value.length != 1) {
        throw const FormatException('army: malformed entry');
      }
      final square = Square.parse(key);
      final role = Role.fromChar(value);
      if (square == null || role == null) {
        throw const FormatException('army: unknown square or piece');
      }
      pieces[square] = role;
    }
    return ArmyPlacement(side, pieces);
  }

  final Side side;
  final Map<Square, Role> pieces;

  int get total => pieces.length;
  bool get isEmpty => pieces.isEmpty;

  Role? roleAt(Square square) => pieces[square];

  int countOf(Role role) => pieces.values.where((r) => r == role).length;

  Square? get kingSquare {
    for (final entry in pieces.entries) {
      if (entry.value == Role.king) return entry.key;
    }
    return null;
  }

  ArmyPlacement place(Square square, Role role) =>
      ArmyPlacement(side, {...pieces, square: role});

  ArmyPlacement remove(Square square) =>
      ArmyPlacement(side, {...pieces}..remove(square));

  /// Moves the piece on [from] to [to]; swaps when [to] is occupied.
  ArmyPlacement move(Square from, Square to) {
    final moving = pieces[from];
    if (moving == null || from == to) return this;
    final next = {...pieces};
    final displaced = next[to];
    next[to] = moving;
    if (displaced != null) {
      next[from] = displaced;
    } else {
      next.remove(from);
    }
    return ArmyPlacement(side, next);
  }

  ArmyPlacement withKingAt(Square square) {
    final king = kingSquare;
    final next = {...pieces};
    if (king != null) next.remove(king);
    next[square] = Role.king;
    return ArmyPlacement(side, next);
  }

  /// Canonical, order independent text form (used for commitments).
  String encode() {
    final squares = pieces.keys.toList()..sort();
    return squares.map((s) => '${s.name}${pieces[s]!.letter}').join(',');
  }

  Map<String, String> toJson() => {
    for (final entry in pieces.entries) entry.key.name: entry.value.letter,
  };

  @override
  bool operator ==(Object other) =>
      other is ArmyPlacement &&
      other.side == side &&
      other.encode() == encode();

  @override
  int get hashCode => Object.hash(side, encode());

  @override
  String toString() => 'ArmyPlacement(${side.name}: ${encode()})';
}
