// IMPORTS ---------------------------------------------------------------------

import girlchesser/board.{type Move}
import girlchesser/board/move
import gleam/io
import gleam/option.{type Option, None, Some}

// TYPES -----------------------------------------------------------------------

pub type Response {
  Id(name: String)
  Options
  UciOk
  ReadyOk
  BestMove(move: Move, ponder: Option(Move))

  // nonstandard extensions
  PrintBoard(board: board.Board)
}

// CONVERSIONS -----------------------------------------------------------------

pub fn id() -> Nil {
  Id(name: "girlchesser") |> to_string |> io.println
}

pub fn options() -> Nil {
  Options |> to_string |> io.println
}

pub fn uci_ok() -> Nil {
  UciOk |> to_string |> io.println
}

pub fn ready_ok() -> Nil {
  ReadyOk |> to_string |> io.println
}

pub fn best_move(move: Move, ponder: Option(Move)) -> Nil {
  BestMove(move: move, ponder: ponder) |> to_string |> io.println
}

pub fn print_board(board: board.Board) -> Nil {
  PrintBoard(board) |> to_string |> io.println
}

fn to_string(response: Response) -> String {
  case response {
    Id(name) -> "id name " <> name

    Options ->
      "option name Hash type spin default 16 min 16 max 16
option name Threads type spin default 1 min 1 max 1"

    UciOk -> "uciok"

    ReadyOk -> "readyok"

    BestMove(move, None) -> "bestmove " <> move.to_string(move)

    BestMove(move, Some(ponder)) -> "
        bestmove " <> move.to_string(move) <> " ponder " <> move.to_string(
        ponder,
      )

    PrintBoard(board) -> board.to_string(board)
  }
}
