import girlchesser/board
import girlchesser/board/position
import girlchesser/engine/movegen
import girlchesser/fen
import gleam/dict
import gleam/list
import gleeunit/should

fn orderless_equal(a: List(board.Move), b: List(board.Move)) -> Bool {
  let dict_a = a |> list.map(fn(x) { #(x, True) }) |> dict.from_list
  let dict_b = b |> list.map(fn(x) { #(x, True) }) |> dict.from_list
  dict_a == dict_b
}

pub fn test_generate_pawn_moves_1_test() {
  let pos =
    fen.startpos
    |> fen.parse
    |> should.be_ok

  movegen.pawn(pos)
  |> orderless_equal([
    board.Move(position.from(1, 2), position.from(1, 3)),
    board.Move(position.from(1, 2), position.from(1, 4)),
    board.Move(position.from(2, 2), position.from(2, 3)),
    board.Move(position.from(2, 2), position.from(2, 4)),
    board.Move(position.from(3, 2), position.from(3, 3)),
    board.Move(position.from(3, 2), position.from(3, 4)),
    board.Move(position.from(4, 2), position.from(4, 3)),
    board.Move(position.from(4, 2), position.from(4, 4)),
    board.Move(position.from(5, 2), position.from(5, 3)),
    board.Move(position.from(5, 2), position.from(5, 4)),
    board.Move(position.from(6, 2), position.from(6, 3)),
    board.Move(position.from(6, 2), position.from(6, 4)),
    board.Move(position.from(7, 2), position.from(7, 3)),
    board.Move(position.from(7, 2), position.from(7, 4)),
    board.Move(position.from(8, 2), position.from(8, 3)),
    board.Move(position.from(8, 2), position.from(8, 4)),
  ])
  |> should.be_true
}

pub fn generate_en_passant_test() {
  let pos =
    "7k/8/8/3pP3/8/8/8/7K w - d6 0 1"
    |> fen.parse
    |> should.be_ok

  movegen.pawn(pos)
  |> orderless_equal([
    board.Move(position.from(5, 5), position.from(5, 6)),
    board.EnPassant(position.from(5, 5), position.from(4, 6)),
  ])
}

pub fn generate_promotion_test() {
  let pos =
    "7k/3P4/8/8/8/8/8/7K w - - 0 1"
    |> fen.parse
    |> should.be_ok

  movegen.pawn(pos)
  |> orderless_equal([
    board.Promote(position.from(4, 7), position.from(4, 8), board.Knight),
    board.Promote(position.from(4, 7), position.from(4, 8), board.Bishop),
    board.Promote(position.from(4, 7), position.from(4, 8), board.Rook),
    board.Promote(position.from(4, 7), position.from(4, 8), board.Queen),
  ])
}

pub fn generate_king_moves_test() {
  let pos =
    "8/8/1r6/k7/8/8/6K1/8 b - - 0 1"
    |> fen.parse
    |> should.be_ok

  movegen.king(pos)
  |> orderless_equal([
    board.Move(position.from(1, 5), position.from(1, 6)),
    board.Move(position.from(1, 5), position.from(2, 5)),
    board.Move(position.from(1, 5), position.from(2, 4)),
    board.Move(position.from(1, 5), position.from(1, 4)),
  ])
}

pub fn generate_castle_test() {
  let pos =
    "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQK2R w K - 0 1"
    |> fen.parse
    |> should.be_ok

  movegen.king(pos)
  |> orderless_equal([
    board.Move(position.from(5, 1), position.from(6, 1)),
    board.Castle(position.from(5, 1), position.from(7, 1)),
  ])
}

pub fn castle_through_pieces_test() {
  let pos =
    fen.startpos
    |> fen.parse
    |> should.be_ok

  movegen.king(pos)
  |> list.contains(board.Castle(position.from(5, 1), position.from(7, 1)))
  |> should.be_false
}

pub fn castle_through_check_test() {
  let pos =
    "rn1qkbnr/pppppppp/8/8/2b5/4P3/PPPP1PPP/RNBQK2R w KQkq - 0 1"
    |> fen.parse
    |> should.be_ok

  movegen.king(pos)
  |> list.contains(board.Castle(position.from(5, 1), position.from(7, 1)))
  |> should.be_false
}

pub fn generate_knight_moves_1_test() {
  let pos =
    "8/5k2/8/8/N7/8/5K2/8 w - - 0 1"
    |> fen.parse
    |> should.be_ok

  movegen.knight(pos)
  |> orderless_equal([
    board.Move(position.from(1, 4), position.from(2, 6)),
    board.Move(position.from(1, 4), position.from(3, 5)),
    board.Move(position.from(1, 4), position.from(3, 3)),
    board.Move(position.from(1, 4), position.from(2, 2)),
  ])
  |> should.be_true
}

pub fn generate_bishop_moves_test() {
  let pos =
    "8/5k2/8/1b6/8/8/5K2/8 b - - 0 1"
    |> fen.parse
    |> should.be_ok

  movegen.bishop(pos)
  |> orderless_equal([
    board.Move(position.from(2, 5), position.from(1, 6)),
    board.Move(position.from(2, 5), position.from(3, 6)),
    board.Move(position.from(2, 5), position.from(4, 7)),
    board.Move(position.from(2, 5), position.from(5, 8)),
    board.Move(position.from(2, 5), position.from(3, 4)),
    board.Move(position.from(2, 5), position.from(4, 3)),
    board.Move(position.from(2, 5), position.from(5, 2)),
    board.Move(position.from(2, 5), position.from(6, 1)),
    board.Move(position.from(2, 5), position.from(1, 4)),
  ])
  |> should.be_true
}
