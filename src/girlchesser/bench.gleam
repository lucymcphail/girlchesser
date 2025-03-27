import birl
import girlchesser/board.{type Board}
import girlchesser/engine/movegen
import girlchesser/fen
import gleam/int
import gleam/io
import gleam/list

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

pub fn bench() {
  let assert Ok(board) =
    fen.startpos
    |> fen.parse

  let start_time = birl.monotonic_now()
  let nodes_searched =
    enumerate_moves(board, 4)
    + enumerate_moves(board, 4)
    + enumerate_moves(board, 4)
  let end_time = birl.monotonic_now()

  let nodes_per_second = 1_000_000 * nodes_searched / { end_time - start_time }

  io.println(
    int.to_string(nodes_searched)
    <> " nodes "
    <> int.to_string(nodes_per_second)
    <> " nps",
  )
}
