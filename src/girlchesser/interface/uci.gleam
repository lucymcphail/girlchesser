////
////

// IMPORTS ---------------------------------------------------------------------

import girlchesser/board.{type Board}
import girlchesser/engine.{type Engine}
import girlchesser/fen
import gleam/erlang
import gleam/erlang/process.{type Pid, type Subject}
import gleam/function
import gleam/option
import gleam/otp/actor.{type StartError}
import gleam/string
import uci/request
import uci/response

type State {
  State(board: Board, debug: Bool, engine: Engine)
}

pub fn start_server(engine: Engine) -> Result(Subject(String), StartError) {
  let assert Ok(board) = fen.parse(fen.startpos)
  let state = State(board:, debug: False, engine:)

  let init = fn() {
    let self = process.new_subject()
    let selector =
      process.selecting(process.new_selector(), self, function.identity)

    // Spawn a process that will poll stdin for input
    let _ = listen_for_input(self)

    actor.Ready(state, selector)
  }

  actor.start_spec({
    use message, state <- actor.Spec(init:, init_timeout: 1000)
    let command = request.parse(message)

    case command {
      Ok(request.Uci) -> {
	response.id()
	response.uci_ok()
	actor.continue(state)
      }

      Ok(request.Isready) -> {
        response.ready_ok()
        actor.continue(state)
      }

      Ok(request.Debug(on: True)) -> actor.continue(State(..state, debug: True))

      Ok(request.Debug(on: False)) ->
        actor.continue(State(..state, debug: False))

      Ok(request.Position(board:)) -> {
        actor.continue(State(..state, board:))
      }

      Ok(request.Go) -> {
        process.call(state.engine, engine.Move(state.board, [], _), 5000)
        |> response.best_move(option.None)

        actor.continue(state)
      }

      Ok(request.PrintBoard) -> {
	response.print_board(state.board)
	actor.continue(state)
      }

      _ -> actor.continue(state)
    }
  })
}

fn listen_for_input(server: Subject(String)) -> Pid {
  use <- process.start(_, True)

  do_listen_for_input(server)
}

fn do_listen_for_input(server: Subject(String)) {
  case erlang.get_line("") {
    Error(_) -> do_listen_for_input(server)
    Ok(line) -> {
      process.send(server, string.trim(line))
      do_listen_for_input(server)
    }
  }
}
