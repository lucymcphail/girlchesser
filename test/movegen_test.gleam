import girlchesser/board/board
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
      board.NormalMove(board.square(1, 2), board.square(1, 3)),
      board.NormalMove(board.square(1, 2), board.square(1, 4)),
      board.NormalMove(board.square(2, 2), board.square(2, 3)),
      board.NormalMove(board.square(2, 2), board.square(2, 4)),
      board.NormalMove(board.square(3, 2), board.square(3, 3)),
      board.NormalMove(board.square(3, 2), board.square(3, 4)),
      board.NormalMove(board.square(4, 2), board.square(4, 3)),
      board.NormalMove(board.square(4, 2), board.square(4, 4)),
      board.NormalMove(board.square(5, 2), board.square(5, 3)),
      board.NormalMove(board.square(5, 2), board.square(5, 4)),
      board.NormalMove(board.square(6, 2), board.square(6, 3)),
      board.NormalMove(board.square(6, 2), board.square(6, 4)),
      board.NormalMove(board.square(7, 2), board.square(7, 3)),
      board.NormalMove(board.square(7, 2), board.square(7, 4)),
      board.NormalMove(board.square(8, 2), board.square(8, 3)),
      board.NormalMove(board.square(8, 2), board.square(8, 4)),
    ]),
  )
  |> should.be_true
}
