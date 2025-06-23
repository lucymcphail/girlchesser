import argv
import girlchesser/bench
import girlchesser/engine
import girlchesser/interface/http
import girlchesser/interface/uci
import gleam/erlang/process

const tournament_interface_enabled = True

pub fn main() {
  let assert Ok(engine) = engine.start()

  case tournament_interface_enabled {
    True -> {
      let assert Ok(_) = http.start_server(engine)

      process.sleep_forever()
    }

    False -> {
      case argv.load().arguments {
        ["bench", ..] -> {
          bench.bench()
        }

        _ -> {
          let assert Ok(_) = uci.start_server(engine)

          process.sleep_forever()
        }
      }
    }
  }
}
