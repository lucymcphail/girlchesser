////
////

// IMPORTS ---------------------------------------------------------------------

import birl
import girlchesser/board.{type Board, type Move}
import girlchesser/engine/evaluation
import girlchesser/engine/movegen
import gleam/erlang/process
import gleam/float
import gleam/list
import gleam/order
import gleam/otp/actor

// CONSTANTS -------------------------------------------------------------------

// there's no FLT_MAX in gleam/float, so we'll just use a number
// that's bigger than any score difference you could ever see in a
// regular chess game
const big_float = 999_999_999_999_999_999.0

// likewise for FLT_MIN
const big_negative_float = -999_999_999_999_999_999.0

// the amount of time to leave on the clock if we're trying to use all
// of our time, so that we don't get timed out
// TODO: try reducing this
const buffer_time = 100

// SEARCH ----------------------------------------------------------------------

pub type ScoredMove {
  ScoredMove(move: Move, score: Float)
}

pub type TimeControl {
  Fischer(wtime: Int, btime: Int, winc: Int, binc: Int)
  TimePerMove(time: Int)
}

pub type Message {
  Shutdown
  StartSearching(board: Board, depth: Int, moves: List(Move))
  GetEvaluations(reply_with: process.Subject(Result(List(ScoredMove), Nil)))
}

pub fn search(board: Board, time_control: TimeControl) -> ScoredMove {
  let thinking_time = case time_control {
    Fischer(wtime, btime, winc, binc) ->
      case board.side_to_move {
        board.White -> wtime / 20 + winc / 2
        board.Black -> btime / 20 + binc / 2
      }
    TimePerMove(time) -> time - buffer_time
  }

  let start_time = birl.monotonic_now()
  let deadline = start_time + thinking_time

  let assert Ok(search_actor) = actor.start([], handle_message)

  let moves = movegen.legal(board)

  // this is janky, but this is how an iterative deepening search to
  // depth 2 should look
  process.send(search_actor, StartSearching(board, 1, moves))
  let assert Ok(scored_moves) = process.call(search_actor, GetEvaluations, 5000)

  let moves =
    list.sort(scored_moves, fn(left, right) {
      case left.score <. right.score {
        True -> order.Gt
        False -> order.Lt
      }
    })
    |> list.map(fn(scored_move) { scored_move.move })

  process.send(search_actor, StartSearching(board, 2, moves))
  let assert Ok(scored_moves) = process.call(search_actor, GetEvaluations, 5000)

  best_move(scored_moves)
}

fn best_move(scored_moves: List(ScoredMove)) -> ScoredMove {
  use left, right <- list.fold(scored_moves, ScoredMove(board.Move(0, 0), 0.0))
  case left.score >. right.score {
    True -> left
    False -> right
  }
}

fn handle_message(
  message: Message,
  stack: List(List(ScoredMove)),
) -> actor.Next(Message, List(List(ScoredMove))) {
  case message {
    Shutdown -> actor.Stop(process.Normal)

    StartSearching(board, depth, moves) -> {
      let scored_moves = search_to_depth(board, depth, moves)
      let new_state = [scored_moves, ..stack]
      actor.continue(new_state)
    }

    GetEvaluations(client) -> {
      case stack {
        [] -> {
          process.send(client, Error(Nil))
          actor.continue([])
        }

        [first, ..rest] -> {
          process.send(client, Ok(first))
          actor.continue(rest)
        }
      }
    }
  }
}

fn search_to_depth(
  board: Board,
  depth: Int,
  moves: List(Move),
) -> List(ScoredMove) {
  use move <- list.map(moves)

  let new_board = board |> board.move(move)
  let score =
    float.negate(minimax(new_board, depth, big_negative_float, big_float))

  ScoredMove(move, score)
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
