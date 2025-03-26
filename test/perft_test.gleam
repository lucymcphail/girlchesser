import girlchesser/board.{type Board}
import girlchesser/engine/movegen
import girlchesser/fen
import gleam/list
import gleeunit/should

fn enumerate_moves(board: Board, depth: Int) -> Int {
  case depth {
    0 -> 1
    _ -> {
      let legal_moves = movegen.legal(board)
      list.fold(legal_moves, 0, fn(acc, move) {
	let new_board = board.move(board, move)
	acc + enumerate_moves(new_board, depth - 1)
      })
    }
  }
}

pub fn startpos_perft_test() {
  let board = fen.startpos |> fen.parse |> should.be_ok
  enumerate_moves(board, 1) |> should.equal(20)
  enumerate_moves(board, 2) |> should.equal(400)
  enumerate_moves(board, 3) |> should.equal(8902)
  enumerate_moves(board, 4) |> should.equal(197_281)
  // still too slow:
  // enumerate_moves(board, 5) |> should.equal(4_865_609)
  // enumearte_moves(board, 6) |> should.equal(119_060_324)
}

pub fn kiwipete_perft_test() {
  let board =
    "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq -"
    |> fen.parse
    |> should.be_ok

  enumerate_moves(board, 1) |> should.equal(48)
  enumerate_moves(board, 2) |> should.equal(2039)
  enumerate_moves(board, 3) |> should.equal(97_862)
  // still too slow:
  // enumerate_moves(board, 4) |> should.equal(4_085_603)
  // enumerate_moves(board, 5) |> should.equal(193_690_690)
  // enumerate_moves(board, 6) |> should.equal(8_031_647_685)
}
