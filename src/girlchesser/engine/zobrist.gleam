////
////

// IMPORTS ---------------------------------------------------------------------

import girlchesser/board.{type Board}
import girlchesser/board/position
import gleam/int
import gleam/option
import iv

// CONSTANTS -------------------------------------------------------------------

// maximum value for a small integer in erlang, on 64-bit systems
const modulus = 576_460_752_303_423_488

// literally a keysmash
const a = 1_291_887_894

const c = 1

// another keysmash
const initial_seed = 4_561_689

// pieces: 2 colours * 6 pieces * 64 squares = 768 keys
// side to move: 1 key
// castling rights: 4 keys
// en passant files: 8 keys
const zobrist_keys_count = 781

// TODO: at some point we should check the linear independence of the
// Zobrist keys this generates. If it's poor, we can try changing `a`
// and `c`, or switch to a better PRNG algorithm like the Mersenne
// Twister.
fn random(seed: Int) -> Int {
  let assert Ok(val) = int.modulo(a * seed + c, modulus)
  val
}

pub fn generate_zobrist_keys() -> iv.Array(Int) {
  do_generate_zobrist_keys(
    iv.initialise(zobrist_keys_count, fn(_) { 0 }),
    initial_seed,
    zobrist_keys_count,
  )
}

fn do_generate_zobrist_keys(acc: iv.Array(Int), seed: Int, index: Int) {
  case index {
    0 -> acc
    _ -> {
      let key = random(seed)
      let acc = acc |> iv.try_set(at: index, to: key)
      do_generate_zobrist_keys(acc, key, index - 1)
    }
  }
}

pub fn zobrist(board: Board, keys: iv.Array(Int)) -> Int {
  do_zobrist_pieces(board, keys, 0, 63)
}

fn do_zobrist_pieces(
  board: Board,
  keys: iv.Array(Int),
  hash: Int,
  index: Int,
) -> Int {
  case index {
    0 -> do_zobrist_side_to_move(board, keys, hash)
    _ -> {
      case board.pieces |> iv.get(index) {
        Ok(board.Occupied(colour, piece)) -> {
          let assert Ok(piece_key) =
            keys |> iv.get(zobrist_piece_index(colour, piece, index))
          let hash = int.bitwise_exclusive_or(hash, piece_key)
          do_zobrist_pieces(board, keys, hash, index - 1)
        }
        _ -> do_zobrist_pieces(board, keys, hash, index - 1)
      }
    }
  }
}

fn do_zobrist_side_to_move(board: Board, keys: iv.Array(Int), hash: Int) -> Int {
  case board.side_to_move {
    board.White -> do_zobrist_castling_rights(board, keys, hash)
    board.Black -> {
      let assert Ok(side_to_move_key) =
        keys |> iv.get(zobrist_black_to_move_index())
      let hash = int.bitwise_exclusive_or(hash, side_to_move_key)
      do_zobrist_castling_rights(board, keys, hash)
    }
  }
}

fn do_zobrist_castling_rights(
  board: Board,
  keys: iv.Array(Int),
  hash: Int,
) -> Int {
  let hash = case board.white_castle_rights {
    board.Both -> {
      let assert Ok(kingside_castling_rights_key) =
        keys |> iv.get(zobrist_castling_rights_index(board.White, KingSide))

      let assert Ok(queenside_castling_rights_key) =
        keys |> iv.get(zobrist_castling_rights_index(board.White, QueenSide))

      let hash = int.bitwise_exclusive_or(hash, kingside_castling_rights_key)
      int.bitwise_exclusive_or(hash, queenside_castling_rights_key)
    }

    board.KingSide -> {
      let assert Ok(castling_rights_key) =
        keys |> iv.get(zobrist_castling_rights_index(board.White, KingSide))

      int.bitwise_exclusive_or(hash, castling_rights_key)
    }

    board.QueenSide -> {
      let assert Ok(castling_rights_key) =
        keys |> iv.get(zobrist_castling_rights_index(board.White, QueenSide))

      int.bitwise_exclusive_or(hash, castling_rights_key)
    }

    board.NoRights -> hash
  }

  case board.black_castle_rights {
    board.Both -> {
      let assert Ok(kingside_castling_rights_key) =
        keys |> iv.get(zobrist_castling_rights_index(board.Black, KingSide))

      let assert Ok(queenside_castling_rights_key) =
        keys |> iv.get(zobrist_castling_rights_index(board.Black, QueenSide))

      let hash = int.bitwise_exclusive_or(hash, kingside_castling_rights_key)
      int.bitwise_exclusive_or(hash, queenside_castling_rights_key)
    }

    board.KingSide -> {
      let assert Ok(castling_rights_key) =
        keys |> iv.get(zobrist_castling_rights_index(board.Black, KingSide))

      int.bitwise_exclusive_or(hash, castling_rights_key)
    }

    board.QueenSide -> {
      let assert Ok(castling_rights_key) =
        keys |> iv.get(zobrist_castling_rights_index(board.Black, QueenSide))

      int.bitwise_exclusive_or(hash, castling_rights_key)
    }

    board.NoRights -> hash
  }

  do_zobrist_en_passant(board, keys, hash)
}

fn do_zobrist_en_passant(board: Board, keys: iv.Array(Int), hash: Int) -> Int {
  case board.en_passant {
    option.None -> hash
    option.Some(square) -> {
      let file = position.file(square)
      let assert Ok(en_passant_file_key) =
        keys |> iv.get(zobrist_en_passant_file_index(file))

      int.bitwise_exclusive_or(hash, en_passant_file_key)
    }
  }
}

/// starting at offset 0:
///  - WHITE:
///    - 64 * PAWN
///    - 64 * BISHOP
///    - 64 * KNIGHT
///    - 64 * ROOK
///    - 64 * QUEEN
///    - 64 * KING
///  - BLACK:
///    - 64 * PAWN
///    - 64 * BISHOP
///    - 64 * KNIGHT
///    - 64 * ROOK
///    - 64 * QUEEN
///    - 64 * KING
fn zobrist_piece_index(
  colour: board.Colour,
  piece: board.Piece,
  position: Int,
) -> Int {
  let colour_offset = case colour {
    board.White -> 0
    board.Black -> 384
  }

  let piece_offset = case piece {
    board.Pawn -> 0
    board.Bishop -> 64
    board.Knight -> 128
    board.Rook -> 192
    board.Queen -> 256
    board.King -> 320
  }

  colour_offset + piece_offset + position
}

/// starting at offset 768:
///  - BLACK TO MOVE
fn zobrist_black_to_move_index() -> Int {
  768
}

type CastlingSide {
  KingSide
  QueenSide
}

/// starting at offset 769:
///  - WHITE:
///    - KINGSIDE
///    - QUEENSIDE
///  - BLACK:
///    - KINGSIDE
///    - QUEENSIDE
fn zobrist_castling_rights_index(
  colour: board.Colour,
  castling_side: CastlingSide,
) -> Int {
  let starting_offset = 769

  let colour_offset = case colour {
    board.White -> 0
    board.Black -> 2
  }

  let castling_side_offset = case castling_side {
    KingSide -> 0
    QueenSide -> 1
  }

  starting_offset + colour_offset + castling_side_offset
}

/// starting at offset 773:
///  - A
///  - B
///  - C
///  - D
///  - E
///  - F
///  - G
///  - H
fn zobrist_en_passant_file_index(file: Int) {
  let starting_offset = 773

  starting_offset + file - 1
}
