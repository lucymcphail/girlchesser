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

const big_negative_float = -999_999_999_999_999_999.0

// SEARCH ----------------------------------------------------------------------

pub type ScoredMove {
  ScoredMove(move: Move, score: Float)
}

pub fn search(board: Board) -> ScoredMove {
  let depth = 2

  let moves = movegen.legal(board)

  use acc, move <- list.fold(
    moves,
    ScoredMove(board.Move(0, 0), big_negative_float),
  )

  let new_board = board |> board.move(move)
  let score =
    float.negate(minimax(new_board, depth, big_negative_float, big_float))

  case score >=. acc.score {
    True -> ScoredMove(move, score)
    False -> acc
  }
}

fn minimax(board: Board, depth: Int, alpha: Float, beta: Float) -> Float {
  case depth {
    0 -> evaluation.evaluate(board)
    _ -> {
      let moves = movegen.legal(board)

      case list.is_empty(moves) {
        // no moves found, the game is over
        True ->
          case movegen.is_in_check(board) {
            // checkmate
            True -> big_negative_float

            // stalemate
            False -> 0.0
          }

        // game is ongoing, keep searching
        _ -> {
          do_minimax(board, depth, moves, alpha, beta, big_negative_float)
        }
      }
    }
  }
}

fn do_minimax(
  board: Board,
  depth: Int,
  moves: List(Move),
  alpha: Float,
  beta: Float,
  acc: Float,
) -> Float {
  case moves {
    [move, ..rest] -> {
      let new_board = board |> board.move(move)
      let score =
        float.negate(minimax(
          new_board,
          depth - 1,
          float.negate(beta),
          float.negate(alpha),
        ))

      let acc = float.max(acc, score)
      let alpha = float.max(alpha, score)

      case score >=. beta {
        True -> acc
        False ->
          do_minimax(board, depth, rest, alpha, beta, float.max(score, acc))
      }
    }
    _ -> acc
  }
}
