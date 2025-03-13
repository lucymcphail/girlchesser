import gleam/dict
import gleam/option

pub type BitBoard =
  BitArray

pub const empty_bitboard = <<0:64>>

pub const empty_piece_bitboards = PieceBitboards(
  kings: empty_bitboard,
  queens: empty_bitboard,
  rooks: empty_bitboard,
  bishops: empty_bitboard,
  knights: empty_bitboard,
  pawns: empty_bitboard,
)

pub const empty_board = Board(
  pieces: empty_piece_bitboards,
  white_combined: empty_bitboard,
  black_combined: empty_bitboard,
  all_combined: empty_bitboard,
  side_to_move: White,
  white_castle_rights: NoRights,
  black_castle_rights: NoRights,
  pinned: empty_bitboard,
  checkers: empty_bitboard,
  hash: <<0>>,
  en_passant: option.None,
)

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

pub type Board {
  Board(
    pieces: PieceBitboards,
    white_combined: BitBoard,
    black_combined: BitBoard,
    all_combined: BitBoard,
    side_to_move: Color,
    white_castle_rights: CastleRights,
    black_castle_rights: CastleRights,
    pinned: BitBoard,
    checkers: BitBoard,
    hash: BitArray,
    en_passant: option.Option(Int),
  )
}

pub type PieceBitboards {
  PieceBitboards(
    kings: BitBoard,
    queens: BitBoard,
    rooks: BitBoard,
    bishops: BitBoard,
    knights: BitBoard,
    pawns: BitBoard,
  )
}

pub type BoardStatus {
  Ongoing
  Stalemate
  Checkmate
}

pub type Move {
  Move(from: Int, to: Int)
}

pub fn new_default_board() -> Board {
  case from_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1") {
    Ok(board) -> board
    Error(_) -> panic
  }
}

pub fn from_fen(string: String) -> Result(Board, String) {
  todo
}

pub fn get_status(board: Board) -> BoardStatus {
  let moves: dict.Dict(Int, Move) = todo
  case dict.size(moves) {
    0 -> {
      case board.checkers == empty_bitboard {
        True -> Stalemate
        False -> Checkmate
      }
    }
    _ -> Ongoing
  }
}

pub fn get_hash(board: Board) -> BitArray {
  todo
}

pub fn make_move(board: Board, move: Move) -> Board {
  todo
}

pub fn to_string(board: Board) -> String {
  do_to_string(
    board.pieces,
    board.white_combined,
    board.black_combined,
    8,
    1,
    "",
  )
}

fn do_to_string(
  pieces: PieceBitboards,
  whites: BitArray,
  blacks: BitArray,
  rank: Int,
  file: Int,
  acc: String,
) -> String {
  case pieces {
    PieceBitboards(kings: <<1:size(1), _:bits>>, ..) ->
      do_king_to_string(drop_pieces(pieces), whites, blacks, rank, file, acc)

    PieceBitboards(queens: <<1:size(1), _:bits>>, ..) ->
      do_queen_to_string(drop_pieces(pieces), whites, blacks, rank, file, acc)

    PieceBitboards(rooks: <<1:size(1), _:bits>>, ..) ->
      do_rook_to_string(drop_pieces(pieces), whites, blacks, rank, file, acc)

    PieceBitboards(bishops: <<1:size(1), _:bits>>, ..) ->
      do_bishop_to_string(drop_pieces(pieces), whites, blacks, rank, file, acc)

    PieceBitboards(knights: <<1:size(1), _:bits>>, ..) ->
      do_knight_to_string(drop_pieces(pieces), whites, blacks, rank, file, acc)

    PieceBitboards(pawns: <<1:size(1), _:bits>>, ..) ->
      do_pawn_to_string(drop_pieces(pieces), whites, blacks, rank, file, acc)

    _ if rank == 1 && file == 8 -> acc <> " "

    _ -> {
      let pieces = drop_pieces(pieces)
      let whites = drop_piece(whites)
      let blacks = drop_piece(blacks)

      do_empty_to_string(pieces, whites, blacks, rank, file, acc)
    }
  }
}

fn drop_pieces(pieces: PieceBitboards) -> PieceBitboards {
  PieceBitboards(
    kings: drop_piece(pieces.kings),
    queens: drop_piece(pieces.queens),
    rooks: drop_piece(pieces.rooks),
    bishops: drop_piece(pieces.bishops),
    knights: drop_piece(pieces.knights),
    pawns: drop_piece(pieces.pawns),
  )
}

fn drop_piece(piece: BitArray) -> BitArray {
  case piece {
    <<_:size(1), rest:bits>> -> rest
    _ -> <<>>
  }
}

fn do_empty_to_string(
  pieces: PieceBitboards,
  whites: BitArray,
  blacks: BitArray,
  rank: Int,
  file: Int,
  acc: String,
) -> String {
  case file == 8 {
    True -> do_to_string(pieces, whites, blacks, rank - 1, 1, acc <> " \n")
    False -> do_to_string(pieces, whites, blacks, rank, file + 1, acc <> " ")
  }
}

fn do_king_to_string(
  pieces: PieceBitboards,
  whites: BitArray,
  blacks: BitArray,
  rank: Int,
  file: Int,
  acc: String,
) -> String {
  echo #("king", rank, file)
  case whites, blacks {
    <<1:size(1), whites:bits>>, <<_:size(1), blacks:bits>> ->
      do_advance_to_string(pieces, whites, blacks, rank, file, acc <> "♔")

    <<_:size(1), whites:bits>>, <<1:size(1), blacks:bits>> ->
      do_advance_to_string(pieces, whites, blacks, rank, file, acc <> "♚")

    _, _ -> panic
  }
}

fn do_queen_to_string(
  pieces: PieceBitboards,
  whites: BitArray,
  blacks: BitArray,
  rank: Int,
  file: Int,
  acc: String,
) -> String {
  echo #("queen", rank, file)
  case whites, blacks {
    <<1:size(1), whites:bits>>, <<_:size(1), blacks:bits>> ->
      do_advance_to_string(pieces, whites, blacks, rank, file, acc <> "♕")

    <<_:size(1), whites:bits>>, <<1:size(1), blacks:bits>> ->
      do_advance_to_string(pieces, whites, blacks, rank, file, acc <> "♛")

    _, _ -> panic
  }
}

fn do_rook_to_string(
  pieces: PieceBitboards,
  whites: BitArray,
  blacks: BitArray,
  rank: Int,
  file: Int,
  acc: String,
) -> String {
  echo #("rook", rank, file)
  case whites, blacks {
    <<1:size(1), whites:bits>>, <<_:size(1), blacks:bits>> ->
      do_advance_to_string(pieces, whites, blacks, rank, file, acc <> "♖")

    <<_:size(1), whites:bits>>, <<1:size(1), blacks:bits>> ->
      do_advance_to_string(pieces, whites, blacks, rank, file, acc <> "♜")

    _, _ -> panic
  }
}

fn do_bishop_to_string(
  pieces: PieceBitboards,
  whites: BitArray,
  blacks: BitArray,
  rank: Int,
  file: Int,
  acc: String,
) -> String {
  echo #("bishop", rank, file)
  case whites, blacks {
    <<1:size(1), whites:bits>>, <<_:size(1), blacks:bits>> ->
      do_advance_to_string(pieces, whites, blacks, rank, file, acc <> "♗")

    <<_:size(1), whites:bits>>, <<1:size(1), blacks:bits>> ->
      do_advance_to_string(pieces, whites, blacks, rank, file, acc <> "♝")

    _, _ -> panic
  }
}

fn do_knight_to_string(
  pieces: PieceBitboards,
  whites: BitArray,
  blacks: BitArray,
  rank: Int,
  file: Int,
  acc: String,
) -> String {
  echo #("knight", rank, file)
  case whites, blacks {
    <<1:size(1), whites:bits>>, <<_:size(1), blacks:bits>> ->
      do_advance_to_string(pieces, whites, blacks, rank, file, acc <> "♘")

    <<_:size(1), whites:bits>>, <<1:size(1), blacks:bits>> ->
      do_advance_to_string(pieces, whites, blacks, rank, file, acc <> "♞")

    _, _ -> panic
  }
}

fn do_pawn_to_string(
  pieces: PieceBitboards,
  whites: BitArray,
  blacks: BitArray,
  rank: Int,
  file: Int,
  acc: String,
) -> String {
  echo #("pawn", rank, file)

  case whites, blacks {
    <<1:size(1), whites:bits>>, <<_:size(1), blacks:bits>> ->
      do_advance_to_string(pieces, whites, blacks, rank, file, acc <> "♙")

    <<_:size(1), whites:bits>>, <<1:size(1), blacks:bits>> ->
      do_advance_to_string(pieces, whites, blacks, rank, file, acc <> "♟")

    _, _ -> panic
  }
}

fn do_advance_to_string(
  pieces: PieceBitboards,
  whites: BitArray,
  blacks: BitArray,
  rank: Int,
  file: Int,
  acc: String,
) -> String {
  case file == 8 {
    True if rank == 1 -> acc
    True -> do_to_string(pieces, whites, blacks, rank - 1, 1, acc <> "\n")
    False -> do_to_string(pieces, whites, blacks, rank, file + 1, acc)
  }
}
