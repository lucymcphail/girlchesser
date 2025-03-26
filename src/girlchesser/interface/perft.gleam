import girlchesser/board.{type Board}
import girlchesser/board/move
import girlchesser/engine/movegen
import gleam/int
import gleam/io
import gleam/list
import gleam/string

pub fn perft(board: Board, depth: Int) {
  let legal_moves =
    movegen.legal(board)
    |> list.sort(fn(left, right) {
      string.compare(move.to_string(left), move.to_string(right))
    })

  let total_moves =
    list.fold(legal_moves, 0, fn(acc, move) {
      let new_board = board.move(board, move)

      let move_str = move.to_string(move)
      let num_moves = enumerate_moves(new_board, depth - 1)
      io.println(move_str <> ": " <> int.to_string(num_moves))
      acc + num_moves
    })

  io.println("")
  io.println("Nodes searched: " <> int.to_string(total_moves))
}

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
