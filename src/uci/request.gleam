// IMPORTS ---------------------------------------------------------------------

import girlchesser/board.{type Board}
import girlchesser/board/move
import girlchesser/engine.{type TimeControl}
import girlchesser/fen
import gleam/int
import gleam/set.{type Set}
import gleam/string

// TYPES -----------------------------------------------------------------------

pub type Request {
  Uci
  Debug(on: Bool)
  Isready
  SetOption(name: String, value: String)
  UciNewGame
  Position(board: Board)
  Go(time_control: TimeControl)
  Stop
  Ponderhit
  Quit

  // nonstandard extensions
  PrintBoard
  GoPerft(depth: Int)
}

// CONSTRUCTORS ----------------------------------------------------------------

///
///
pub fn parse(request: String) -> Result(Request, Nil) {
  case request {
    "debug " <> rest ->
      rest
      |> parse_whitespace
      |> parse_debug

    "go perft " <> rest ->
      rest
      |> parse_perft_depth

    "go" <> rest ->
      rest
      |> parse_whitespace
      |> parse_go

    "isready" -> Ok(Isready)

    "ponderhit" -> Ok(Ponderhit)

    "position " <> rest ->
      rest
      |> parse_whitespace
      |> parse_position

    "quit" -> panic as "received UCI quit command"

    "setoption " <> rest ->
      rest
      |> parse_whitespace
      |> parse_set_option

    "stop" -> Ok(Stop)

    "uci" -> Ok(Uci)

    "ucinewgame" -> Ok(UciNewGame)

    "printboard" -> Ok(PrintBoard)

    _ -> Error(Nil)
  }
}

// PARSE DEBUG ----------------------------------------------------------------

fn parse_debug(request: String) -> Result(Request, Nil) {
  case request {
    "on" -> Ok(Debug(on: True))
    "off" -> Ok(Debug(on: False))
    _ -> Error(Nil)
  }
}

// PARSE POSITION --------------------------------------------------------------

fn parse_position(request: String) -> Result(Request, Nil) {
  case request {
    "fen " <> rest ->
      rest
      |> parse_whitespace
      |> parse_position_fen

    // This is kind of lazy but we just try again but pretend we got a `fen`
    // string of the starting board.
    "startpos" <> rest -> parse_position("fen " <> fen.startpos <> " " <> rest)

    _ -> Error(Nil)
  }
}

fn parse_position_fen(request: String) -> Result(Request, Nil) {
  case parse_interesting(request, set.from_list(["m"])) {
    Ok(#(fen, rest)) ->
      case fen.parse(fen), parse_whitespace(rest) {
        Ok(board), "" -> Ok(Position(board))
        Ok(board), "oves " <> moves ->
          moves
          |> parse_whitespace
          |> parse_position_moves(board)

        _, _ -> Error(Nil)
      }
    Error(_) -> Error(Nil)
  }
}

fn parse_position_moves(request: String, board: Board) -> Result(Request, Nil) {
  case parse_interesting(request, set.from_list([" ", "\t"])) {
    Ok(#(move, rest)) ->
      case move.parse(move), parse_whitespace(rest) {
        Ok(move), "" ->
          move
          |> move.specialise(board, _)
          |> board.move(board, _)
          |> Position
          |> Ok

        Ok(move), rest ->
          move
          |> move.specialise(board, _)
          |> board.move(board, _)
          |> parse_position_moves(rest, _)

        _, _ -> Error(Nil)
      }
    Error(_) -> Error(Nil)
  }
}

// PARSE GO --------------------------------------------------------------------

fn parse_go(request: String) -> Result(Request, Nil) {
  case request {
    // if we just receive `go`, then default to 5s per move
    "" -> Ok(Go(engine.TimePerMove(5000)))

    "movetime " <> rest -> rest |> parse_go_movetime
    "wtime " <> rest -> rest |> parse_go_fischer()
    _ -> Error(Nil)
  }
}

fn parse_go_movetime(request: String) -> Result(Request, Nil) {
  case int.parse(request) {
    Ok(movetime) -> Ok(Go(engine.TimePerMove(movetime)))
    _ -> Error(Nil)
  }
}

fn parse_go_fischer(request: String) -> Result(Request, Nil) {
  case parse_number(request) {
    Ok(#(wtime, rest)) ->
      parse_go_fischer_btime(rest |> parse_whitespace, wtime)

    _ -> Error(Nil)
  }
}

fn parse_go_fischer_btime(request: String, wtime: Int) -> Result(Request, Nil) {
  case request {
    "btime " <> rest -> {
      case parse_number(rest) {
        Ok(#(btime, rest)) ->
          parse_go_fischer_winc(rest |> parse_whitespace, wtime, btime)

        _ -> Error(Nil)
      }
    }
    _ -> Error(Nil)
  }
}

fn parse_go_fischer_winc(
  request: String,
  wtime: Int,
  btime: Int,
) -> Result(Request, Nil) {
  case request {
    "winc " <> rest -> {
      case parse_number(rest) {
        Ok(#(winc, rest)) ->
          parse_go_fischer_binc(rest |> parse_whitespace, wtime, btime, winc)

        _ -> Error(Nil)
      }
    }
    _ -> Ok(Go(engine.Fischer(wtime, btime, 0, 0)))
  }
}

fn parse_go_fischer_binc(
  request: String,
  wtime: Int,
  btime: Int,
  winc: Int,
) -> Result(Request, Nil) {
  case request {
    "binc " <> rest -> {
      case parse_number(rest) {
        Ok(#(binc, _)) -> Ok(Go(engine.Fischer(wtime:, btime:, winc:, binc:)))

        _ -> Error(Nil)
      }
    }
    _ -> Error(Nil)
  }
}

// PARSE PERFT DEPTH -----------------------------------------------------------

fn parse_perft_depth(request: String) -> Result(Request, Nil) {
  case int.parse(request) {
    Ok(depth) -> Ok(GoPerft(depth))
    _ -> Error(Nil)
  }
}

// PARSE SETOPTION -------------------------------------------------------------

fn parse_set_option(request: String) -> Result(Request, Nil) {
  case request {
    "name " <> rest ->
      rest
      |> parse_whitespace
      |> parse_set_option_name

    _ -> Error(Nil)
  }
}

fn parse_set_option_name(request: String) -> Result(Request, Nil) {
  case parse_interesting(request, set.from_list([" ", "\t"])) {
    Ok(#(name, "value " <> rest)) ->
      rest
      |> parse_whitespace
      |> parse_set_option_value(name)

    _ -> Error(Nil)
  }
}

fn parse_set_option_value(name: String, request: String) -> Result(Request, Nil) {
  case parse_interesting(request, set.from_list([" ", "\t"])) {
    Ok(#(value, _)) -> Ok(SetOption(name, value))
    Error(_) -> Error(Nil)
  }
}

// PARSE UTILS -----------------------------------------------------------------

fn parse_whitespace(request: String) -> String {
  case request {
    " " <> rest | "\t" <> rest -> parse_whitespace(rest)
    _ -> request
  }
}

fn parse_interesting(
  request: String,
  break: Set(String),
) -> Result(#(String, String), Nil) {
  do_parse_interesting(request, break, "")
}

fn do_parse_interesting(
  request: String,
  break: Set(String),
  interesting: String,
) -> Result(#(String, String), Nil) {
  case string.pop_grapheme(request) {
    Error(_) if interesting == "" -> Error(Nil)
    Error(_) -> Ok(#(interesting, ""))
    Ok(#(char, rest)) ->
      case set.contains(break, char) {
        True -> Ok(#(interesting, rest))
        False -> do_parse_interesting(rest, break, interesting <> char)
      }
  }
}

fn parse_number(request: String) -> Result(#(Int, String), Nil) {
  case parse_interesting(request, set.from_list([" ", "\t"])) {
    Ok(#(number, rest)) ->
      case int.parse(number) {
        Ok(number) -> Ok(#(number, rest))
        Error(_) -> Error(Nil)
      }
    Error(_) -> Error(Nil)
  }
}
