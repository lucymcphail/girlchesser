// IMPORTS ---------------------------------------------------------------------

import girlchesser/board.{type Board, type Move}
import girlchesser/engine/movegen
import girlchesser/fen
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/otp/actor.{type StartError}
import iv

// MAIN ------------------------------------------------------------------------

pub type Engine =
  Subject(Message)

type State {
  State(board: Board)
}

pub type Message {
  Move(board: Board, attempts: List(Move), reply: Subject(Move))
}

pub fn start() -> Result(Engine, StartError) {
  let assert Ok(board) = fen.parse(fen.startpos)
  let init = State(board:)

  use message, _ <- actor.start(init)

  case message {
    Move(board, attempts, reply) -> {
      let board = handle_move(board, attempts, reply)
      let state = State(board:)

      actor.continue(state)
    }
  }
}

// HANDLERS --------------------------------------------------------------------

fn handle_move(board: Board, _: List(Move), reply: Subject(Move)) -> Board {
  let moves = movegen.legal(board)
  let index = int.random(iv.length(moves))
  let assert Ok(move) = iv.get(moves, index)

  process.send(reply, move)

  board.move(board, move)
}
