import girlchesser/bench
import girlchesser/engine
import girlchesser/interface/http
import girlchesser/interface/uci
import gleam/erlang
import gleam/erlang/process

pub fn main() {
  let assert Ok(engine) = engine.start()

  case erlang.start_arguments() {
    ["bench", ..] -> {
      bench.bench()
    }

    ["uci", ..] -> {
      let assert Ok(_) = uci.start_server(engine)

      process.sleep_forever()
    }

    _ -> {
      let assert Ok(_) = http.start_server(engine)

      process.sleep_forever()
    }
  }
}
