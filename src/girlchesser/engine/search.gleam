// IMPORTS ---------------------------------------------------------------------

import girlchesser/board.{type Board, type Move}
import girlchesser/engine/evaluation
import girlchesser/engine/movegen
import gleam/erlang/process.{type Pid, type Subject}
import gleam/float
import gleam/list
import gleam/order

// CONSTANTS -------------------------------------------------------------------

// there's no FLT_MAX in gleam/float, so we'll just use a number
// that's bigger than any score difference you could ever see in a
// regular chess game
const big_float = 999_999_999_999_999_999.0

// likewise for FLT_MIN
const big_negative_float = -999_999_999_999_999_999.0

//

type ScoredMove {
  ScoredMove(move: Move, score: Float)
}

//

pub fn start(board: Board, save_best_move: Subject(Move)) -> Pid {
  use <- process.start(linked: False)

  movegen.legal(board)
  // TODO: this is super wasteful but it's less wasteful than mapping the scored
  // moves to remove the score portion before recursing...
  |> list.map(ScoredMove(_, big_negative_float))
  |> loop(board, _, 1, save_best_move)
}

fn loop(
  board: Board,
  moves: List(ScoredMove),
  depth: Int,
  save_best_move: Subject(Move),
) -> forever {
  let scored_moves = search_to_depth(board, depth, moves)
  let sorted_moves =
    list.sort(scored_moves, fn(a, b) {
      case a.score <. b.score {
        True -> order.Gt
        False -> order.Lt
      }
    })

  case sorted_moves {
    [] -> panic
    [ScoredMove(move: best, ..), ..] -> process.send(save_best_move, best)
  }

  loop(board, sorted_moves, depth + 1, save_best_move)
}

fn search_to_depth(
  board: Board,
  depth: Int,
  moves: List(ScoredMove),
) -> List(ScoredMove) {
  do_search_to_depth(board, depth, moves, [])
}

fn do_search_to_depth(
  board: Board,
  depth: Int,
  moves: List(ScoredMove),
  scored_moves: List(ScoredMove),
) -> List(ScoredMove) {
  case moves {
    [] -> scored_moves
    [ScoredMove(move:, ..), ..rest] -> {
      let new_board = board.move(board, move)
      let score = minimax(new_board, depth, big_negative_float, big_float)
      let scored_move = ScoredMove(move, score *. -1.0)

      do_search_to_depth(board, depth, rest, [scored_move, ..scored_moves])
    }
  }
}

fn minimax(board: Board, depth: Int, alpha: Float, beta: Float) -> Float {
  case depth {
    0 -> evaluation.evaluate(board)
    _ ->
      case movegen.legal(board) {
        [_, ..] as moves ->
          do_minimax(board, depth, moves, alpha, beta, big_negative_float)

        [] ->
          case movegen.is_in_check(board) {
            True -> big_negative_float
            False -> 0.0
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
  best: Float,
) -> Float {
  case moves {
    [] -> best
    [move, ..rest] -> {
      let new_board = board.move(board, move)
      let score =
        minimax(new_board, depth - 1, beta *. -1.0, alpha *. -1.0) *. -1.0

      let best = float.max(best, score)
      let alpha = float.max(alpha, score)

      case score >=. beta {
        True -> best
        False ->
          do_minimax(board, depth, rest, alpha, beta, float.max(score, best))
      }
    }
  }
}
