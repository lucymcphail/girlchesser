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

pub type Message {
  MakeMove(board: Board, attempts: List(Move), reply: Subject(Move))
  SaveBestMove(best: Move)
  StopSearching
}

pub fn start() -> Result(Engine, StartError) {
  let assert Ok(board) = fen.parse(fen.startpos)
  let init = Waiting(board:)

  use message, state <- actor.start(init)

  case state, message {
    Waiting(..), MakeMove(board:, attempts: _, reply:) -> {
      let timer_subject = process.new_subject()
      let timer = process.send_after(timer_subject, 4900, StopSearching)

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

    Searching(timer:, searcher:, ..), MakeMove(board:, attempts: _, reply:) -> {
      process.cancel_timer(timer)
      process.kill(searcher)

      let timer_subject = process.new_subject()
      let timer = process.send_after(timer_subject, 4900, StopSearching)

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
