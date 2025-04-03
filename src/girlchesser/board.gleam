// IMPORTS ---------------------------------------------------------------------

import girlchesser/board/position.{type Position}
import gleam/int
import gleam/option.{type Option, None, Some}
import iv

// TYPES -----------------------------------------------------------------------

///
///
pub type Board {
  Board(
    pieces: Pieces,
    side_to_move: Colour,
    white_castle_rights: CastleRights,
    black_castle_rights: CastleRights,
    en_passant: Option(Position),
  )
}

///
///
pub type Pieces =
  iv.Array(Square)

///
///
pub type Square {
  Empty
  OutsideBoard
  Occupied(colour: Colour, piece: Piece)
}

///
///
pub type Piece {
  King
  Queen
  Rook
  Bishop
  Knight
  Pawn
}

///
///
pub type Colour {
  White
  Black
}

///
///
pub type CastleRights {
  NoRights
  KingSide
  QueenSide
  Both
}

///
///
pub type BoardStatus {
  Ongoing
  Stalemate
  Checkmate
}

///
///
pub type Move {
  Move(from: Int, to: Int)
  Castle(from: Int, to: Int)
  EnPassant(from: Int, to: Int)
  Promote(from: Int, to: Int, piece: Piece)
}

// CONSTRUCTORS ----------------------------------------------------------------

// QUERIES ---------------------------------------------------------------------

/// The internal representation of the board is actually a 14x16 grid *not* an
/// 8x8 one. This function lets you look up a piece on the board by its logical
/// position.
///
pub fn get(board: Board, position: Position) -> Result(Piece, Nil) {
  case iv.get(board.pieces, position) {
    Ok(Occupied(_, piece)) -> Ok(piece)
    _ -> Error(Nil)
  }
}

// MANIPULATIONS ---------------------------------------------------------------

/// Apply a move to a board position. Note that this function does not
/// check a move for legality, so illegal moves or positions are
/// considered undefined behaviour.
pub fn move(board: Board, move: Move) -> Board {
  board
  |> check_en_passant(move)
  |> check_castle_rights(move)
  |> make_move(move)
  |> swap_sides
}

/// Check if making this move would apply en passant next turn. It's important to
/// check this *before* the move is made so we can inspect the state of the board
/// first.
///
fn check_en_passant(board: Board, move: Move) -> Board {
  let from = position.split(move.from)
  let to = position.split(move.to)
  let vertical_distance = int.absolute_value(to.1 - from.1)

  Board(..board, en_passant: case get(board, move.from) {
    Ok(Pawn) if from.0 == to.0 && vertical_distance == 2 ->
      Some(position.from(
        file: position.file(move.to),
        rank: { position.rank(move.from) + position.rank(move.to) } / 2,
      ))

    _ -> None
  })
}

/// Check if making this move would remove castle rights from the board. It's
/// important to check this *before* the move is made so we can inspect the state
/// of the board first.
///
fn check_castle_rights(board: Board, move: Move) -> Board {
  let white_castle_rights = case board.side_to_move {
    // White to move; white castle rights --------------------------------------
    White ->
      case get(board, move.from) {
        // king moved: remove castling rights on both sides
        Ok(King) -> NoRights

        Ok(Rook) ->
          case position.rank(move.from) == 1 && position.file(move.from) == 1 {
            // queenside rook moved
            True -> remove_castle_rights(board.white_castle_rights, QueenSide)
            False ->
              case
                position.rank(move.from) == 1 && position.file(move.from) == 8
              {
                // kingside rook moved
                True ->
                  remove_castle_rights(board.white_castle_rights, KingSide)
                False -> board.white_castle_rights
              }
          }

        _ -> board.white_castle_rights
      }

    // Black to move; white castle rights --------------------------------------
    Black ->
      case position.rank(move.to) == 1 && position.file(move.to) == 1 {
        // queenside rook taken
        True -> remove_castle_rights(board.white_castle_rights, QueenSide)
        False ->
          case position.rank(move.to) == 1 && position.file(move.to) == 8 {
            // kingside rook captured
            True -> remove_castle_rights(board.white_castle_rights, KingSide)
            False -> board.white_castle_rights
          }
      }
  }

  let black_castle_rights = case board.side_to_move {
    // Black to move; black castle rights --------------------------------------
    Black ->
      case get(board, move.from) {
        // king moved: remove castling rights on both sides
        Ok(King) -> NoRights

        Ok(Rook) ->
          case position.rank(move.from) == 8 && position.file(move.from) == 1 {
            // queenside rook moved
            True -> remove_castle_rights(board.black_castle_rights, QueenSide)
            False ->
              case
                position.rank(move.from) == 8 && position.file(move.from) == 8
              {
                // kingside rook moved
                True ->
                  remove_castle_rights(board.black_castle_rights, KingSide)
                False -> board.black_castle_rights
              }
          }

        _ -> board.black_castle_rights
      }

    // White to move; black castle rights --------------------------------------
    White ->
      case position.rank(move.to) == 8 && position.file(move.to) == 1 {
        // queenside rook taken
        True -> remove_castle_rights(board.black_castle_rights, QueenSide)
        False ->
          case position.rank(move.to) == 8 && position.file(move.to) == 8 {
            // kingside rook captured
            True -> remove_castle_rights(board.black_castle_rights, KingSide)
            False -> board.black_castle_rights
          }
      }
  }

  Board(..board, white_castle_rights:, black_castle_rights:)
}

fn remove_castle_rights(
  rights: CastleRights,
  to_remove: CastleRights,
) -> CastleRights {
  case rights, to_remove {
    Both, Both -> NoRights
    Both, QueenSide -> KingSide
    Both, KingSide -> QueenSide
    Both, NoRights -> Both
    QueenSide, Both -> NoRights
    QueenSide, QueenSide -> NoRights
    QueenSide, KingSide -> QueenSide
    QueenSide, NoRights -> Both
    KingSide, Both -> NoRights
    KingSide, QueenSide -> KingSide
    KingSide, KingSide -> NoRights
    KingSide, NoRights -> Both
    NoRights, _ -> NoRights
  }
}

///
///
fn make_move(board: Board, move: Move) -> Board {
  let assert Ok(from_square) = iv.get(board.pieces, move.from)
    as "Don't make out of bounds moves you numpty"

  let pieces =
    board.pieces
    |> iv.try_set(at: move.to, to: from_square)
    |> iv.try_set(at: move.from, to: Empty)
    |> apply_move_rules(move, board.side_to_move)

  Board(..board, pieces:)
}

/// Apply special move rules for castling and en passant. When moves are generated,
/// they already encode whether the move should have special rules applied to it
/// which means this function doesn't check if the move is valid, it just applies
/// the rule outright.
///
/// These rules are applied *after* the move has been made, so the board is up
/// to date.
///
fn apply_move_rules(pieces: Pieces, move: Move, side: Colour) -> Pieces {
  case move, position.split(move.to) {
    Castle(_, _), #(3, to_rank) ->
      pieces
      |> iv.try_set(at: position.from(file: 1, rank: to_rank), to: Empty)
      |> iv.try_set(
        at: position.from(file: 4, rank: to_rank),
        to: Occupied(side, Rook),
      )

    Castle(_, _), #(7, to_rank) ->
      pieces
      |> iv.try_set(at: position.from(file: 8, rank: to_rank), to: Empty)
      |> iv.try_set(
        at: position.from(file: 6, rank: to_rank),
        to: Occupied(side, Rook),
      )

    EnPassant(_, _), #(to_file, 3) ->
      iv.try_set(pieces, at: position.from(file: to_file, rank: 4), to: Empty)

    EnPassant(_, _), #(to_file, 6) ->
      iv.try_set(pieces, at: position.from(file: to_file, rank: 5), to: Empty)

    Promote(_, to_square, promotion_piece), _ ->
      iv.try_set(pieces, at: to_square, to: Occupied(side, promotion_piece))

    _, _ -> pieces
  }
}

pub fn other_colour(colour: Colour) -> Colour {
  case colour {
    Black -> White
    White -> Black
  }
}

pub fn swap_sides(board: Board) -> Board {
  Board(..board, side_to_move: other_colour(board.side_to_move))
}

// CONVERSIONS -----------------------------------------------------------------

pub fn to_string(board: Board) -> String {
  do_to_string(board.pieces, 0, "")
}

fn do_to_string(pieces: iv.Array(Square), index: Int, acc: String) -> String {
  let result = case iv.get(pieces, index) {
    Ok(Occupied(colour, piece)) -> acc <> piece_to_string(piece, colour)
    Ok(OutsideBoard) -> acc
    Ok(Empty) -> acc <> " "
    _ -> acc
  }

  // if we're at the last square of a file, add a newline
  let with_newlines = case index % 16 == 15 && index > 32 && index < 159 {
    True -> result <> "\n"
    False -> result
  }

  case index < 192 {
    True -> do_to_string(pieces, index + 1, with_newlines)
    False -> with_newlines
  }
}

fn piece_to_string(piece: Piece, colour: Colour) -> String {
  case colour, piece {
    White, King -> "♔"
    Black, King -> "♚"
    White, Queen -> "♕"
    Black, Queen -> "♛"
    White, Rook -> "♖"
    Black, Rook -> "♜"
    White, Bishop -> "♗"
    Black, Bishop -> "♝"
    White, Knight -> "♘"
    Black, Knight -> "♞"
    White, Pawn -> "♙"
    Black, Pawn -> "♟"
  }
}
