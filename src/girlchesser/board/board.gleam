import gleam/option
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
