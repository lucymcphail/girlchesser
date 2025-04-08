// IMPORTS ---------------------------------------------------------------------

import girlchesser/board.{type Board, type Move}
import girlchesser/engine/search
import girlchesser/fen
import gleam/erlang/process.{type Pid, type Subject, type Timer}
import gleam/function
import gleam/option.{type Option, None, Some}
import gleam/otp/actor.{type StartError}

// MAIN ------------------------------------------------------------------------

pub type Engine =
  Subject(Message)

type State {
  Waiting(board: Board)
  Searching(
    board: Board,
    timer: Timer,
    best: Option(Move),
    reply: Subject(Move),
    searcher: Pid,
  )
}

pub type TimeControl {
  Fischer(wtime: Int, btime: Int, winc: Int, binc: Int)
  TimePerMove(time: Int)
}

pub type Message {
  MakeMove(
    board: Board,
    attempts: List(Move),
    time_control: TimeControl,
    reply: Subject(Move),
  )
  SaveBestMove(best: Move)
  StopSearching
}

pub fn start() -> Result(Engine, StartError) {
  let assert Ok(board) = fen.parse(fen.startpos)
  let init = Waiting(board:)

  use message, state <- actor.start(init)

  case state, message {
    Waiting(..), MakeMove(board:, attempts: _, time_control:, reply:) -> {
      let thinking_time = case time_control {
        Fischer(wtime, btime, winc, binc) ->
          case board.side_to_move {
            board.White -> wtime / 20 + winc / 2
            board.Black -> btime / 20 + binc / 2
          }
        // add a buffer so we have time to actually return our move
        TimePerMove(time) -> time - 250
      }

      let timer_subject = process.new_subject()
      let timer =
        process.send_after(timer_subject, thinking_time, StopSearching)

      let searcher_subject = process.new_subject()
      let searcher = search.start(board, searcher_subject)

      let state = Searching(board:, timer:, best: None, reply:, searcher:)
      let selector =
        process.new_selector()
        |> process.selecting(timer_subject, function.identity)
        |> process.selecting(searcher_subject, SaveBestMove)

      actor.Continue(state, Some(selector))
    }

    Waiting(..), SaveBestMove(..) -> {
      actor.continue(state)
    }

    Waiting(..), StopSearching -> {
      actor.continue(state)
    }

    Searching(
      timer:,
      searcher:,
      ..,
    ),
      MakeMove(board:, attempts: _, time_control:, reply:)
    -> {
      process.cancel_timer(timer)
      process.kill(searcher)

      let thinking_time = case time_control {
        Fischer(wtime, btime, winc, binc) ->
          case board.side_to_move {
            board.White -> wtime / 20 + winc / 2
            board.Black -> btime / 20 + binc / 2
          }
        // add a buffer so we have time to actually return our move
        TimePerMove(time) -> time - 250
      }

      let timer_subject = process.new_subject()
      let timer =
        process.send_after(timer_subject, thinking_time, StopSearching)

      let searcher_subject = process.new_subject()
      let searcher = search.start(board, searcher_subject)

      let state = Searching(board:, timer:, best: None, reply:, searcher:)
      let selector =
        process.new_selector()
        |> process.selecting(timer_subject, function.identity)
        |> process.selecting(searcher_subject, SaveBestMove)

      actor.Continue(state, Some(selector))
    }

    Searching(..), SaveBestMove(best:) -> {
      actor.continue(Searching(..state, best: Some(best)))
    }

    Searching(board:, best:, reply:, searcher:, ..), StopSearching ->
      case best {
        None -> panic as "no move found in time"
        Some(move) -> {
          process.kill(searcher)
          process.send(reply, move)

          actor.Continue(Waiting(board:), None)
        }
      }
  }
}
