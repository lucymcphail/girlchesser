////
////

// IMPORTS ---------------------------------------------------------------------

import girlchesser/board.{type Move, Castle, EnPassant, Move, Promote}
import girlchesser/board/position.{type Position}
import gleam/int
import gleam/option.{Some}
import gleam/result

// CONSTRUCTORS ----------------------------------------------------------------

/// Parse a move represented in UCI-compatible long algebraic notation.
///
pub fn parse(request: String) -> Result(Move, Nil) {
  use #(from, request) <- result.try(parse_position(request))
  use #(to, request) <- result.try(parse_position(request))

  let move = case parse_move_promotion(request) {
    Ok(piece) -> Ok(board.Promote(from, to, piece))
    Error(_) -> Ok(board.Move(from, to))
  }

  move
}

///
///
fn parse_position(request: String) -> Result(#(Position, String), Nil) {
  case parse_file(request) {
    Ok(#(file, rest)) -> parse_rank(file, rest)
    Error(_) -> Error(Nil)
  }
}

///
///
fn parse_file(request: String) -> Result(#(Int, String), Nil) {
  case request {
    "a" <> rest -> Ok(#(1, rest))
    "b" <> rest -> Ok(#(2, rest))
    "c" <> rest -> Ok(#(3, rest))
    "d" <> rest -> Ok(#(4, rest))
    "e" <> rest -> Ok(#(5, rest))
    "f" <> rest -> Ok(#(6, rest))
    "g" <> rest -> Ok(#(7, rest))
    "h" <> rest -> Ok(#(8, rest))
    _ -> Error(Nil)
  }
}

///
///
fn parse_rank(file: Int, request: String) -> Result(#(Int, String), Nil) {
  case request {
    "1" <> rest -> Ok(#(position.from(file:, rank: 1), rest))
    "2" <> rest -> Ok(#(position.from(file:, rank: 2), rest))
    "3" <> rest -> Ok(#(position.from(file:, rank: 3), rest))
    "4" <> rest -> Ok(#(position.from(file:, rank: 4), rest))
    "5" <> rest -> Ok(#(position.from(file:, rank: 5), rest))
    "6" <> rest -> Ok(#(position.from(file:, rank: 6), rest))
    "7" <> rest -> Ok(#(position.from(file:, rank: 7), rest))
    "8" <> rest -> Ok(#(position.from(file:, rank: 8), rest))
    _ -> Error(Nil)
  }
}

///
///
fn parse_move_promotion(request: String) -> Result(board.Piece, Nil) {
  case request {
    "b" -> Ok(board.Bishop)
    "k" -> Ok(board.Knight)
    "q" -> Ok(board.Queen)
    "r" -> Ok(board.Rook)
    _ -> Error(Nil)
  }
}

// MANIPULATIONS ---------------------------------------------------------------

/// Specialise a normal move based on the board state. This is used to determine
/// if a move is compatible with either castling or en passant rules.
///
pub fn specialise(board: board.Board, move: Move) -> Move {
  case move {
    Castle(..) | EnPassant(..) | Promote(..) -> move
    Move(from:, to:) -> {
      let horizontal_distance =
        int.absolute_value(position.file(from) - position.file(to))

      case board.get(board, from) {
        Ok(board.King) if horizontal_distance == 2 -> Castle(from:, to:)
        Ok(board.Pawn) if board.en_passant == Some(to) -> EnPassant(from:, to:)
        _ -> move
      }
    }
  }
}

// CONVERSIONS -----------------------------------------------------------------

/// Convert a move to UCI-compatible long algebraic notation.
///
pub fn to_string(move: Move) -> String {
  case move {
    Move(from, to) | Castle(from, to) | EnPassant(from, to) ->
      do_move_to_string(from, to)

    Promote(from, to, promote_to) ->
      do_move_to_string(from, to)
      <> case promote_to {
        board.Bishop -> "b"
        board.Knight -> "n"
        board.Queen -> "q"
        board.Rook -> "r"
        _ -> ""
      }
  }
}

fn do_move_to_string(from: Int, to: Int) -> String {
  let #(from_file, from_rank) = position.split(from)
  let #(to_file, to_rank) = position.split(to)

  file_to_string(from_file)
  <> rank_to_string(from_rank)
  <> file_to_string(to_file)
  <> rank_to_string(to_rank)
}

fn file_to_string(file: Int) -> String {
  case file {
    1 -> "a"
    2 -> "b"
    3 -> "c"
    4 -> "d"
    5 -> "e"
    6 -> "f"
    7 -> "g"
    8 -> "h"
    _ -> ""
  }
}

fn rank_to_string(rank: Int) -> String {
  int.to_string(rank)
}
