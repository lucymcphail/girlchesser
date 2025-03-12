import gleam/dict
import gleam/option

pub type BitBoard {
  BitBoard(bitboard: BitArray)
}

pub const empty_bitboard = BitBoard(<<0:64>>)

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

pub type Square {
  Square(square: Int)
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
    en_passant: option.Option(Square),
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
  Move(from: Square, to: Square)
}

pub fn new_default_board() -> Board {
  case
    from_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
  {
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
