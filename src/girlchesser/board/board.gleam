import gleam/int
import gleam/option
import gleam/result
import iv

pub type Board {
  Board(
    pieces: iv.Array(Square),
    side_to_move: Color,
    white_castle_rights: CastleRights,
    black_castle_rights: CastleRights,
    en_passant: option.Option(Int),
  )
}

pub type Square {
  Empty
  Occupied(color: Color, piece: Piece)
}

pub type Piece {
  King
  Queen
  Rook
  Bishop
  Knight
  Pawn
}

pub type Color {
  White
  Black
}

pub type CastleRights {
  NoRights
  KingSide
  QueenSide
  Both
}

pub type BoardStatus {
  Ongoing
  Stalemate
  Checkmate
}

pub type Move {
  Move(from: Int, to: Int)
}

pub fn to_string(board: Board) -> String {
  do_to_string(board.pieces, 0, "")
}

fn do_to_string(pieces: iv.Array(Square), index: Int, acc: String) -> String {
  let result = case iv.get(pieces, index) {
    Ok(square) -> {
      case square {
        Occupied(color, piece) ->
          case piece {
            King ->
              case color {
                White -> acc <> "♔"
                Black -> acc <> "♚"
              }
            Queen ->
              case color {
                White -> acc <> "♕"
                Black -> acc <> "♛"
              }
            Rook ->
              case color {
                White -> acc <> "♖"
                Black -> acc <> "♜"
              }
            Bishop ->
              case color {
                White -> acc <> "♗"
                Black -> acc <> "♝"
              }
            Knight ->
              case color {
                White -> acc <> "♘"
                Black -> acc <> "♞"
              }
            Pawn ->
              case color {
                White -> acc <> "♙"
                Black -> acc <> "♟"
              }
          }
        Empty -> acc <> " "
      }
    }

    // reached the end, we're done
    _ -> acc
  }

  // if we're at the last square of a file, add a newline
  let with_newlines = case index % 8 == 7 && index < 62 {
    True -> result <> "\n"
    False -> result
  }

  case index < 64 {
    True -> do_to_string(pieces, index + 1, with_newlines)
    False -> with_newlines
  }
}

pub fn make_move(board: Board, move: Move) -> Result(Board, String) {
  use from_square <- result.try(result.replace_error(
    iv.get(board.pieces, move.from),
    "Invalid move",
  ))

  // PIECE MOVEMENT ------------------------------------------------------------

  let pieces =
    board.pieces
    |> iv.try_set(at: move.to, to: from_square)
    |> iv.try_set(at: move.from, to: Empty)

  // TURN SWAPPING -------------------------------------------------------------

  let side_to_move = other_color(board.side_to_move)

  // CASTLING RIGHTS -----------------------------------------------------------

  let white_castle_rights = case side_to_move {
    // White to move; white castle rights --------------------------------------
    White ->
      case piece_at(board, move.from) {
        // king moved: remove castling rights on both sides
        option.Some(King) -> NoRights

        option.Some(Rook) ->
          case rank(move.from) == 1 && file(move.from) == 1 {
            // queenside rook moved
            True -> remove_castle_rights(board.white_castle_rights, QueenSide)
            False ->
              case rank(move.from) == 1 && file(move.from) == 8 {
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
      case rank(move.to) == 1 && file(move.to) == 1 {
        // queenside rook taken
        True -> remove_castle_rights(board.white_castle_rights, QueenSide)
        False ->
          case rank(move.to) == 1 && file(move.to) == 8 {
            // kingside rook captured
            True -> remove_castle_rights(board.white_castle_rights, KingSide)
            False -> board.white_castle_rights
          }
      }
  }

  let black_castle_rights = case side_to_move {
    // Black to move; black castle rights --------------------------------------
    Black ->
      case piece_at(board, move.from) {
        // king moved: remove castling rights on both sides
        option.Some(King) -> NoRights

        option.Some(Rook) ->
          case rank(move.from) == 8 && file(move.from) == 1 {
            // queenside rook moved
            True -> remove_castle_rights(board.black_castle_rights, QueenSide)
            False ->
              case rank(move.from) == 8 && file(move.from) == 8 {
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
      case rank(move.to) == 8 && file(move.to) == 1 {
        // queenside rook taken
        True -> remove_castle_rights(board.black_castle_rights, QueenSide)
        False ->
          case rank(move.to) == 8 && file(move.to) == 8 {
            // kingside rook captured
            True -> remove_castle_rights(board.black_castle_rights, KingSide)
            False -> board.black_castle_rights
          }
      }
  }

  // EN PASSANT ----------------------------------------------------------------

  let en_passant = case
    piece_at(board, move.from) == option.Some(Pawn)
    && file(move.from) == file(move.to)
    && int.absolute_value(rank(move.to) - rank(move.from)) == 2
  {
    True ->
      option.Some(square(file(move.to), { rank(move.to) + rank(move.to) } / 2))
    False -> option.None
  }

  Ok(Board(
    pieces:,
    side_to_move:,
    white_castle_rights:,
    black_castle_rights:,
    en_passant:,
  ))
}

fn remove_castle_rights(
  rights: CastleRights,
  to_remove: CastleRights,
) -> CastleRights {
  case rights {
    Both ->
      case to_remove {
        Both -> NoRights
        QueenSide -> KingSide
        KingSide -> QueenSide
        NoRights -> Both
      }
    QueenSide ->
      case to_remove {
        Both -> NoRights
        QueenSide -> NoRights
        KingSide -> QueenSide
        NoRights -> Both
      }
    KingSide ->
      case to_remove {
        Both -> NoRights
        QueenSide -> KingSide
        KingSide -> NoRights
        NoRights -> Both
      }
    NoRights -> NoRights
  }
}

fn square(file: Int, rank: Int) {
  { { 8 - rank } * 8 } + { file - 1 }
}

fn file(square: Int) -> Int {
  { square % 8 } + 1
}

fn rank(square: Int) -> Int {
  8 - { square / 8 }
}

fn piece_at(board: Board, square: Int) -> option.Option(Piece) {
  case iv.get(board.pieces, square) {
    Ok(target) ->
      case target {
        Occupied(_, square) -> option.Some(square)
        Empty -> option.None
      }
    _ -> option.None
  }
}

fn other_color(color: Color) -> Color {
  case color {
    Black -> White
    White -> Black
  }
}
