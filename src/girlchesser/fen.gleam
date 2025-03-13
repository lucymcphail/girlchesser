// IMPORTS ---------------------------------------------------------------------

import girlchesser/board/board.{type Board, Board, PieceBitboards}
import gleam/int
import gleam/option

//

/// <FEN> ::= <Piece Placement>
///       ' ' <Side to move>
///       ' ' <Castling ability>
///       ' ' <En passant target square>
///       ' ' <Halfmove clock>
///       ' ' <Fullmove counter>
///
pub fn parse(input: String) -> Result(_, String) {
  let init =
    Board(
      pieces: PieceBitboards(
        kings: <<>>,
        queens: <<>>,
        rooks: <<>>,
        bishops: <<>>,
        knights: <<>>,
        pawns: <<>>,
      ),
      white_combined: <<>>,
      black_combined: <<>>,
      all_combined: <<>>,
      side_to_move: board.White,
      white_castle_rights: board.NoRights,
      black_castle_rights: board.NoRights,
      pinned: <<>>,
      checkers: <<>>,
      hash: <<0>>,
      en_passant: option.None,
    )
  parse_piece_placement(input, init)
}

// PIECE PLACEMENT -------------------------------------------------------------

/// <Piece Placement> ::= <rank8>'/'<rank7>'/.../'<rank2>'/'<rank1>
/// <ranki>           ::= [<digit17>]<piece> {[<digit17>]<piece>} [<digit17>] | '8'
/// <piece>           ::= <white Piece> | <black Piece>
/// <digit17>         ::= '1' | '2' | '3' | '4' | '5' | '6' | '7'
/// <white Piece>     ::= 'P' | 'N' | 'B' | 'R' | 'Q' | 'K'
/// <black Piece>     ::= 'p' | 'n' | 'b' | 'r' | 'q' | 'k'
///
fn parse_piece_placement(input: String, acc: Board) -> Result(Board, String) {
  parse_rank(input, 8, acc)
}

fn parse_rank(input: String, rank: Int, acc: Board) -> Result(Board, String) {
  case input {
    // Blank spaces ------------------------------------------------------------
    "8" as size <> rest
    | "7" as size <> rest
    | "6" as size <> rest
    | "5" as size <> rest
    | "4" as size <> rest
    | "3" as size <> rest
    | "2" as size <> rest
    | "1" as size <> rest -> {
      let assert Ok(size) = int.parse(size)

      let kings = <<acc.pieces.kings:bits, 0:size(size)>>
      let queens = <<acc.pieces.queens:bits, 0:size(size)>>
      let rooks = <<acc.pieces.rooks:bits, 0:size(size)>>
      let bishops = <<acc.pieces.bishops:bits, 0:size(size)>>
      let knights = <<acc.pieces.knights:bits, 0:size(size)>>
      let pawns = <<acc.pieces.pawns:bits, 0:size(size)>>
      let pieces =
        PieceBitboards(kings:, queens:, rooks:, bishops:, knights:, pawns:)

      let white_combined = <<acc.white_combined:bits, 0:size(size)>>
      let black_combined = <<acc.black_combined:bits, 0:size(size)>>
      let all_combined = <<acc.all_combined:bits, 0:size(size)>>
      let board =
        Board(..acc, pieces:, white_combined:, black_combined:, all_combined:)

      parse_rank(rest, rank, board)
    }

    // White pieces ------------------------------------------------------------
    "P" <> rest -> {
      let kings = <<acc.pieces.kings:bits, 0:size(1)>>
      let queens = <<acc.pieces.queens:bits, 0:size(1)>>
      let rooks = <<acc.pieces.rooks:bits, 0:size(1)>>
      let bishops = <<acc.pieces.bishops:bits, 0:size(1)>>
      let knights = <<acc.pieces.knights:bits, 0:size(1)>>
      let pawns = <<acc.pieces.pawns:bits, 1:size(1)>>
      let pieces =
        PieceBitboards(kings:, queens:, rooks:, bishops:, knights:, pawns:)

      let white_combined = <<acc.white_combined:bits, 1:size(1)>>
      let black_combined = <<acc.black_combined:bits, 0:size(1)>>
      let all_combined = <<acc.all_combined:bits, 1:size(1)>>
      let board =
        Board(..acc, pieces:, white_combined:, black_combined:, all_combined:)

      parse_rank(rest, rank, board)
    }

    "N" <> rest -> {
      let kings = <<acc.pieces.kings:bits, 0:size(1)>>
      let queens = <<acc.pieces.queens:bits, 0:size(1)>>
      let rooks = <<acc.pieces.rooks:bits, 0:size(1)>>
      let bishops = <<acc.pieces.bishops:bits, 0:size(1)>>
      let knights = <<acc.pieces.knights:bits, 1:size(1)>>
      let pawns = <<acc.pieces.pawns:bits, 0:size(1)>>
      let pieces =
        PieceBitboards(kings:, queens:, rooks:, bishops:, knights:, pawns:)

      let white_combined = <<acc.white_combined:bits, 1:size(1)>>
      let black_combined = <<acc.black_combined:bits, 0:size(1)>>
      let all_combined = <<acc.all_combined:bits, 1:size(1)>>
      let board =
        Board(..acc, pieces:, white_combined:, black_combined:, all_combined:)
      parse_rank(rest, rank, board)
    }

    "B" <> rest -> {
      let kings = <<acc.pieces.kings:bits, 0:size(1)>>
      let queens = <<acc.pieces.queens:bits, 0:size(1)>>
      let rooks = <<acc.pieces.rooks:bits, 0:size(1)>>
      let bishops = <<acc.pieces.bishops:bits, 1:size(1)>>
      let knights = <<acc.pieces.knights:bits, 0:size(1)>>
      let pawns = <<acc.pieces.pawns:bits, 0:size(1)>>
      let pieces =
        PieceBitboards(kings:, queens:, rooks:, bishops:, knights:, pawns:)

      let white_combined = <<acc.white_combined:bits, 1:size(1)>>
      let black_combined = <<acc.black_combined:bits, 0:size(1)>>
      let all_combined = <<acc.all_combined:bits, 1:size(1)>>
      let board =
        Board(..acc, pieces:, white_combined:, black_combined:, all_combined:)

      parse_rank(rest, rank, board)
    }

    "R" <> rest -> {
      let kings = <<acc.pieces.kings:bits, 0:size(1)>>
      let queens = <<acc.pieces.queens:bits, 0:size(1)>>
      let rooks = <<acc.pieces.rooks:bits, 1:size(1)>>
      let bishops = <<acc.pieces.bishops:bits, 0:size(1)>>
      let knights = <<acc.pieces.knights:bits, 0:size(1)>>
      let pawns = <<acc.pieces.pawns:bits, 0:size(1)>>
      let pieces =
        PieceBitboards(kings:, queens:, rooks:, bishops:, knights:, pawns:)

      let white_combined = <<acc.white_combined:bits, 1:size(1)>>
      let black_combined = <<acc.black_combined:bits, 0:size(1)>>
      let all_combined = <<acc.all_combined:bits, 1:size(1)>>
      let board =
        Board(..acc, pieces:, white_combined:, black_combined:, all_combined:)

      parse_rank(rest, rank, board)
    }

    "Q" <> rest -> {
      let kings = <<acc.pieces.kings:bits, 0:size(1)>>
      let queens = <<acc.pieces.queens:bits, 1:size(1)>>
      let rooks = <<acc.pieces.rooks:bits, 0:size(1)>>
      let bishops = <<acc.pieces.bishops:bits, 0:size(1)>>
      let knights = <<acc.pieces.knights:bits, 0:size(1)>>
      let pawns = <<acc.pieces.pawns:bits, 0:size(1)>>
      let pieces =
        PieceBitboards(kings:, queens:, rooks:, bishops:, knights:, pawns:)

      let white_combined = <<acc.white_combined:bits, 1:size(1)>>
      let black_combined = <<acc.black_combined:bits, 0:size(1)>>
      let all_combined = <<acc.all_combined:bits, 1:size(1)>>
      let board =
        Board(..acc, pieces:, white_combined:, black_combined:, all_combined:)

      parse_rank(rest, rank, board)
    }

    "K" <> rest -> {
      let kings = <<acc.pieces.kings:bits, 1:size(1)>>
      let queens = <<acc.pieces.queens:bits, 0:size(1)>>
      let rooks = <<acc.pieces.rooks:bits, 0:size(1)>>
      let bishops = <<acc.pieces.bishops:bits, 0:size(1)>>
      let knights = <<acc.pieces.knights:bits, 0:size(1)>>
      let pawns = <<acc.pieces.pawns:bits, 0:size(1)>>
      let pieces =
        PieceBitboards(kings:, queens:, rooks:, bishops:, knights:, pawns:)

      let white_combined = <<acc.white_combined:bits, 1:size(1)>>
      let black_combined = <<acc.black_combined:bits, 0:size(1)>>
      let all_combined = <<acc.all_combined:bits, 1:size(1)>>
      let board =
        Board(..acc, pieces:, white_combined:, black_combined:, all_combined:)

      parse_rank(rest, rank, board)
    }

    // Black pieces ------------------------------------------------------------
    "p" <> rest -> {
      let kings = <<acc.pieces.kings:bits, 0:size(1)>>
      let queens = <<acc.pieces.queens:bits, 0:size(1)>>
      let rooks = <<acc.pieces.rooks:bits, 0:size(1)>>
      let bishops = <<acc.pieces.bishops:bits, 0:size(1)>>
      let knights = <<acc.pieces.knights:bits, 0:size(1)>>
      let pawns = <<acc.pieces.pawns:bits, 1:size(1)>>
      let pieces =
        PieceBitboards(kings:, queens:, rooks:, bishops:, knights:, pawns:)

      let white_combined = <<acc.white_combined:bits, 0:size(1)>>
      let black_combined = <<acc.black_combined:bits, 1:size(1)>>
      let all_combined = <<acc.all_combined:bits, 1:size(1)>>
      let board =
        Board(..acc, pieces:, white_combined:, black_combined:, all_combined:)

      parse_rank(rest, rank, board)
    }

    "n" <> rest -> {
      let kings = <<acc.pieces.kings:bits, 0:size(1)>>
      let queens = <<acc.pieces.queens:bits, 0:size(1)>>
      let rooks = <<acc.pieces.rooks:bits, 0:size(1)>>
      let bishops = <<acc.pieces.bishops:bits, 0:size(1)>>
      let knights = <<acc.pieces.knights:bits, 1:size(1)>>
      let pawns = <<acc.pieces.pawns:bits, 0:size(1)>>
      let pieces =
        PieceBitboards(kings:, queens:, rooks:, bishops:, knights:, pawns:)

      let white_combined = <<acc.white_combined:bits, 0:size(1)>>
      let black_combined = <<acc.black_combined:bits, 1:size(1)>>
      let all_combined = <<acc.all_combined:bits, 1:size(1)>>
      let board =
        Board(..acc, pieces:, white_combined:, black_combined:, all_combined:)

      parse_rank(rest, rank, board)
    }

    "b" <> rest -> {
      let kings = <<acc.pieces.kings:bits, 0:size(1)>>
      let queens = <<acc.pieces.queens:bits, 0:size(1)>>
      let rooks = <<acc.pieces.rooks:bits, 0:size(1)>>
      let bishops = <<acc.pieces.bishops:bits, 1:size(1)>>
      let knights = <<acc.pieces.knights:bits, 0:size(1)>>
      let pawns = <<acc.pieces.pawns:bits, 0:size(1)>>
      let pieces =
        PieceBitboards(kings:, queens:, rooks:, bishops:, knights:, pawns:)

      let white_combined = <<acc.white_combined:bits, 0:size(1)>>
      let black_combined = <<acc.black_combined:bits, 1:size(1)>>
      let all_combined = <<acc.all_combined:bits, 1:size(1)>>
      let board =
        Board(..acc, pieces:, white_combined:, black_combined:, all_combined:)

      parse_rank(rest, rank, board)
    }

    "r" <> rest -> {
      let kings = <<acc.pieces.kings:bits, 0:size(1)>>
      let queens = <<acc.pieces.queens:bits, 0:size(1)>>
      let rooks = <<acc.pieces.rooks:bits, 1:size(1)>>
      let bishops = <<acc.pieces.bishops:bits, 0:size(1)>>
      let knights = <<acc.pieces.knights:bits, 0:size(1)>>
      let pawns = <<acc.pieces.pawns:bits, 0:size(1)>>
      let pieces =
        PieceBitboards(kings:, queens:, rooks:, bishops:, knights:, pawns:)

      let white_combined = <<acc.white_combined:bits, 0:size(1)>>
      let black_combined = <<acc.black_combined:bits, 1:size(1)>>
      let all_combined = <<acc.all_combined:bits, 1:size(1)>>
      let board =
        Board(..acc, pieces:, white_combined:, black_combined:, all_combined:)

      parse_rank(rest, rank, board)
    }

    "q" <> rest -> {
      let kings = <<acc.pieces.kings:bits, 0:size(1)>>
      let queens = <<acc.pieces.queens:bits, 1:size(1)>>
      let rooks = <<acc.pieces.rooks:bits, 0:size(1)>>
      let bishops = <<acc.pieces.bishops:bits, 0:size(1)>>
      let knights = <<acc.pieces.knights:bits, 0:size(1)>>
      let pawns = <<acc.pieces.pawns:bits, 0:size(1)>>
      let pieces =
        PieceBitboards(kings:, queens:, rooks:, bishops:, knights:, pawns:)

      let white_combined = <<acc.white_combined:bits, 0:size(1)>>
      let black_combined = <<acc.black_combined:bits, 1:size(1)>>
      let all_combined = <<acc.all_combined:bits, 1:size(1)>>
      let board =
        Board(..acc, pieces:, white_combined:, black_combined:, all_combined:)

      parse_rank(rest, rank, board)
    }

    "k" <> rest -> {
      let kings = <<acc.pieces.kings:bits, 1:size(1)>>
      let queens = <<acc.pieces.queens:bits, 0:size(1)>>
      let rooks = <<acc.pieces.rooks:bits, 0:size(1)>>
      let bishops = <<acc.pieces.bishops:bits, 0:size(1)>>
      let knights = <<acc.pieces.knights:bits, 0:size(1)>>
      let pawns = <<acc.pieces.pawns:bits, 0:size(1)>>
      let pieces =
        PieceBitboards(kings:, queens:, rooks:, bishops:, knights:, pawns:)

      let white_combined = <<acc.white_combined:bits, 0:size(1)>>
      let black_combined = <<acc.black_combined:bits, 1:size(1)>>
      let all_combined = <<acc.all_combined:bits, 1:size(1)>>
      let board =
        Board(..acc, pieces:, white_combined:, black_combined:, all_combined:)

      parse_rank(rest, rank, board)
    }

    // Advancement ------------------------------------------------------------
    "/" <> rest if rank > 1 -> parse_rank(rest, rank - 1, acc)

    " " <> rest if rank == 1 -> parse_side_to_move(rest, acc)

    _ -> Error(input)
  }
}

// SIDE TO MOVE ----------------------------------------------------------------

/// <Side to move> ::= {'w' | 'b'}
///
fn parse_side_to_move(input: String, acc: Board) -> Result(Board, String) {
  case input {
    "w " <> rest ->
      parse_castling_ability(rest, Board(..acc, side_to_move: board.White))

    "b " <> rest ->
      parse_castling_ability(rest, Board(..acc, side_to_move: board.Black))

    _ -> Error(input)
  }
}

// CASTLING ABILITY ------------------------------------------------------------

/// <Castling ability> ::= '-' | ['K'] ['Q'] ['k'] ['q'] (1..4)
///
fn parse_castling_ability(input: String, acc: Board) -> Result(Board, String) {
  case input {
    "- " <> rest -> parse_en_passant_target_square(rest, acc)

    "K" <> rest -> {
      let board =
        Board(..acc, white_castle_rights: case acc.white_castle_rights {
          board.QueenSide -> board.Both
          _ -> board.KingSide
        })

      parse_castling_ability(rest, board)
    }

    "Q" <> rest -> {
      let board =
        Board(..acc, white_castle_rights: case acc.white_castle_rights {
          board.KingSide -> board.Both
          _ -> board.QueenSide
        })

      parse_castling_ability(rest, board)
    }

    "k" <> rest -> {
      let board =
        Board(..acc, black_castle_rights: case acc.black_castle_rights {
          board.QueenSide -> board.Both
          _ -> board.KingSide
        })

      parse_castling_ability(rest, board)
    }

    "q" <> rest -> {
      let board =
        Board(..acc, black_castle_rights: case acc.black_castle_rights {
          board.KingSide -> board.Both
          _ -> board.QueenSide
        })

      parse_castling_ability(rest, board)
    }

    " " <> rest -> parse_en_passant_target_square(rest, acc)

    _ -> Error(input)
  }
}

// EN PASSANT TARGET SQUARE ----------------------------------------------------

/// <En passant target square> ::= '-' | <epsquare>
/// <epsquare>                 ::= <fileLetter> <eprank>
/// <fileLetter>               ::= 'a' | 'b' | 'c' | 'd' | 'e' | 'f' | 'g' | 'h'
/// <eprank>                   ::= '3' | '6'
///
fn parse_en_passant_target_square(
  input: String,
  acc: Board,
) -> Result(Board, String) {
  case input {
    "- " <> rest -> parse_halfmove_clock(rest, acc)
    "a" <> rest -> parse_en_passant_file(rest, 1, acc)
    "b" <> rest -> parse_en_passant_file(rest, 2, acc)
    "c" <> rest -> parse_en_passant_file(rest, 3, acc)
    "d" <> rest -> parse_en_passant_file(rest, 4, acc)
    "e" <> rest -> parse_en_passant_file(rest, 5, acc)
    "f" <> rest -> parse_en_passant_file(rest, 6, acc)
    "g" <> rest -> parse_en_passant_file(rest, 7, acc)
    "h" <> rest -> parse_en_passant_file(rest, 8, acc)
    _ -> Error(input)
  }
}

fn parse_en_passant_file(
  input: String,
  rank: Int,
  acc: Board,
) -> Result(Board, String) {
  case input {
    "3 " ->
      parse_halfmove_clock(
        input,
        Board(..acc, en_passant: option.Some(rank + 8 * 2)),
      )

    "6 " ->
      parse_halfmove_clock(
        input,
        Board(..acc, en_passant: option.Some(rank + 8 * 5)),
      )

    _ -> Error(input)
  }
}

// HALFMOVE CLOCK --------------------------------------------------------------

/// <Halfmove Clock> ::= <digit> {<digit>}
/// <digit>          ::= '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9'
///
fn parse_halfmove_clock(input: String, acc: Board) -> Result(Board, String) {
  case input {
    "0" <> rest
    | "1" <> rest
    | "2" <> rest
    | "3" <> rest
    | "4" <> rest
    | "5" <> rest
    | "6" <> rest
    | "7" <> rest
    | "8" <> rest
    | "9" <> rest -> parse_halfmove_clock(rest, acc)

    " " <> rest -> parse_fullmove_counter(rest, acc)

    _ -> Error(input)
  }
}

// FULLMOVE COUNTER ------------------------------------------------------------

/// <Fullmove counter> ::= <digit19> {<digit>}
/// <digit19>          ::= '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9'
/// <digit>            ::= '0' | <digit19>
///
fn parse_fullmove_counter(input: String, acc: Board) -> Result(Board, String) {
  case input {
    "1" as first <> rest
    | "2" as first <> rest
    | "3" as first <> rest
    | "4" as first <> rest
    | "5" as first <> rest
    | "6" as first <> rest
    | "7" as first <> rest
    | "8" as first <> rest
    | "9" as first <> rest -> parse_fullmove_counter_digits(rest, first, acc)

    _ -> Error(input)
  }
}

fn parse_fullmove_counter_digits(
  input: String,
  counter: String,
  acc: Board,
) -> Result(Board, String) {
  case input {
    "0" as digit <> rest
    | "1" as digit <> rest
    | "2" as digit <> rest
    | "3" as digit <> rest
    | "4" as digit <> rest
    | "5" as digit <> rest
    | "6" as digit <> rest
    | "7" as digit <> rest
    | "8" as digit <> rest
    | "9" as digit <> rest ->
      parse_fullmove_counter_digits(rest, counter <> digit, acc)

    "" -> Ok(acc)

    _ -> Error(input)
  }
}
