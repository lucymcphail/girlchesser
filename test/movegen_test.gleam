import girlchesser/board/board.{square}
import girlchesser/board/movegen
import girlchesser/fen
import gleam/dict
import gleam/list
import gleeunit/should
import iv

fn orderless_equal(a: iv.Array(board.Move), b: iv.Array(board.Move)) -> Bool {
  let dict_a =
    a |> iv.to_list |> list.map(fn(x) { #(x, True) }) |> dict.from_list
  let dict_b =
    b |> iv.to_list |> list.map(fn(x) { #(x, True) }) |> dict.from_list
  dict_a == dict_b
}

pub fn test_generate_pawn_moves_1_test() {
  let pos =
    fen.startpos
    |> fen.parse
    |> should.be_ok

  movegen.generate_pawn_moves(pos)
  |> orderless_equal(
    iv.from_list([
      board.NormalMove(square(1, 2), square(1, 3)),
      board.NormalMove(square(1, 2), square(1, 4)),
      board.NormalMove(square(2, 2), square(2, 3)),
      board.NormalMove(square(2, 2), square(2, 4)),
      board.NormalMove(square(3, 2), square(3, 3)),
      board.NormalMove(square(3, 2), square(3, 4)),
      board.NormalMove(square(4, 2), square(4, 3)),
      board.NormalMove(square(4, 2), square(4, 4)),
      board.NormalMove(square(5, 2), square(5, 3)),
      board.NormalMove(square(5, 2), square(5, 4)),
      board.NormalMove(square(6, 2), square(6, 3)),
      board.NormalMove(square(6, 2), square(6, 4)),
      board.NormalMove(square(7, 2), square(7, 3)),
      board.NormalMove(square(7, 2), square(7, 4)),
      board.NormalMove(square(8, 2), square(8, 3)),
      board.NormalMove(square(8, 2), square(8, 4)),
    ]),
  )
  |> should.be_true
}

pub fn generate_en_passant_test() {
  let pos =
    "7k/8/8/3pP3/8/8/8/7K w - d6 0 1"
    |> fen.parse
    |> should.be_ok

  movegen.generate_pawn_moves(pos)
  |> orderless_equal(
    iv.from_list([
      board.NormalMove(square(5, 5), square(5, 6)),
      board.EnPassantMove(square(5, 5), square(4, 6)),
    ]),
  )
}

pub fn generate_promotion_test() {
  let pos =
    "7k/3P4/8/8/8/8/8/7K w - - 0 1"
    |> fen.parse
    |> should.be_ok

  movegen.generate_pawn_moves(pos)
  |> orderless_equal(
    iv.from_list([
      board.PromotionMove(square(4, 7), square(4, 8), board.Knight),
      board.PromotionMove(square(4, 7), square(4, 8), board.Bishop),
      board.PromotionMove(square(4, 7), square(4, 8), board.Rook),
      board.PromotionMove(square(4, 7), square(4, 8), board.Queen),
    ]),
  )
}

pub fn generate_king_moves_test() {
  let pos =
    "8/8/1r6/k7/8/8/6K1/8 b - - 0 1"
    |> fen.parse
    |> should.be_ok

  movegen.generate_king_moves(pos)
  |> orderless_equal(
    iv.from_list([
      board.NormalMove(square(1, 5), square(1, 6)),
      board.NormalMove(square(1, 5), square(2, 5)),
      board.NormalMove(square(1, 5), square(2, 4)),
      board.NormalMove(square(1, 5), square(1, 4)),
    ]),
  )
}

pub fn generate_castle_test() {
  let pos =
    "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQK2R w K - 0 1"
    |> fen.parse
    |> should.be_ok

  movegen.generate_king_moves(pos)
  |> orderless_equal(
    iv.from_list([
      board.NormalMove(square(5, 1), square(6, 1)),
      board.CastlingMove(square(5, 1), square(7, 1)),
    ]),
  )
}

pub fn castle_through_pieces_test() {
  let pos =
    fen.startpos
    |> fen.parse
    |> should.be_ok

  movegen.generate_king_moves(pos)
  |> iv.contains(board.CastlingMove(square(5, 1), square(7, 1)))
  |> should.be_false
}

pub fn castle_through_check_test() {
  let pos =
    "rn1qkbnr/pppppppp/8/8/2b5/4P3/PPPP1PPP/RNBQK2R w KQkq - 0 1"
    |> fen.parse
    |> should.be_ok

  movegen.generate_king_moves(pos)
  |> iv.contains(board.CastlingMove(square(5, 1), square(7, 1)))
  |> should.be_false
}

pub fn generate_knight_moves_1_test() {
  let pos =
    "8/5k2/8/8/N7/8/5K2/8 w - - 0 1"
    |> fen.parse
    |> should.be_ok

  movegen.generate_knight_moves(pos)
  |> orderless_equal(
    iv.from_list([
      board.NormalMove(square(1, 4), square(2, 6)),
      board.NormalMove(square(1, 4), square(3, 5)),
      board.NormalMove(square(1, 4), square(3, 3)),
      board.NormalMove(square(1, 4), square(2, 2)),
    ]),
  )
  |> should.be_true
}

pub fn generate_bishop_moves_test() {
  let pos =
    "8/5k2/8/1b6/8/8/5K2/8 b - - 0 1"
    |> fen.parse
    |> should.be_ok

  movegen.generate_bishop_moves(pos)
  |> orderless_equal(
    iv.from_list([
      board.NormalMove(square(2, 5), square(1, 6)),
      board.NormalMove(square(2, 5), square(3, 6)),
      board.NormalMove(square(2, 5), square(4, 7)),
      board.NormalMove(square(2, 5), square(5, 8)),
      board.NormalMove(square(2, 5), square(3, 4)),
      board.NormalMove(square(2, 5), square(4, 3)),
      board.NormalMove(square(2, 5), square(5, 2)),
      board.NormalMove(square(2, 5), square(6, 1)),
      board.NormalMove(square(2, 5), square(1, 4)),
    ]),
  )
  |> should.be_true
}
