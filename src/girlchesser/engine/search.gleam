////
////

// IMPORTS ---------------------------------------------------------------------

import girlchesser/board.{type Board, type Move}
import girlchesser/engine/evaluation
import girlchesser/engine/movegen
import gleam/float
import gleam/list

// there's no FLT_MAX in gleam/float, so we'll just use a number
// that's bigger than any score difference you could ever see in a
// regular chess game
const big_float = 999_999_999_999_999_999.0

// SEARCH ----------------------------------------------------------------------

pub type ScoredMove {
  ScoredMove(move: Move, score: Float)
}

pub fn search(board: Board) -> ScoredMove {
  let depth = 2

  let moves = movegen.legal(board)

  use acc, move <- list.fold(
    moves,
    ScoredMove(board.Move(0, 0), float.negate(big_float)),
  )

  let new_board = board |> board.move(move)
  let score = float.negate(minimax(new_board, depth))

  case score >=. acc.score {
    True -> ScoredMove(move, score)
    False -> acc
  }
}

fn minimax(board: Board, depth: Int) -> Float {
  case depth {
    0 -> evaluation.evaluate(board)
    _ -> {
      let moves = movegen.legal(board)

      case list.length(moves) {
        // no moves found, the game is over
        0 ->
          case movegen.is_in_check(board) {
            // checkmate
            True -> float.negate(big_float)

            // stalemate
            False -> 0.0
          }

        // game is ongoing, keep searching
        _ -> do_minimax(board, depth, moves)
      }
    }
  }
}

fn do_minimax(board: Board, depth: Int, moves: List(Move)) -> Float {
  use acc, move <- list.fold(moves, float.negate(big_float))

  let new_board = board |> board.move(move)
  let score = float.negate(minimax(new_board, depth - 1))

  float.max(acc, score)
}
