// IMPORTS ---------------------------------------------------------------------

import girlchesser/board/move
import girlchesser/engine.{type Engine}
import girlchesser/fen
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/json
import gleam/list
import gleam/result
import mist
import wisp.{type Request, type Response}
import wisp/wisp_mist

pub fn start_server(engine: Engine) {
  handle_request(_, engine)
  |> wisp_mist.handler("")
  |> mist.new
  |> mist.bind("0.0.0.0")
  |> mist.port(8000)
  |> mist.start_http
}

fn handle_request(request: Request, engine: Engine) -> Response {
  case wisp.path_segments(request) {
    ["move"] -> handle_move(request, engine)
    _ -> wisp.not_found()
  }
}

fn handle_move(request: Request, engine: Engine) -> Response {
  use body <- wisp.require_string_body(request)
  let data =
    json.parse(body, {
      use fen <- decode.field("fen", decode.string)
      use failed_moves <- decode.field(
        "failed_moves",
        decode.list(decode.string),
      )

      case fen.parse(fen), result.all(list.map(failed_moves, move.parse)) {
        Ok(board), Ok(attempts) -> decode.success(#(board, attempts))
        _, _ -> {
          let assert Ok(board) = fen.parse(fen.startpos)
          let attempts = []

          decode.failure(#(board, attempts), "")
        }
      }
    })

  case data {
    Error(_) -> wisp.bad_request()
    Ok(#(board, attempts)) -> {
      let move = process.call(engine, engine.Move(board, attempts, _), 5000)

      wisp.ok() |> wisp.string_body(move.to_string(move))
    }
  }
}
