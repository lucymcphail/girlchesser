import girlchesser/fen
import gleam/dynamic/decode

pub type Player {
  White
  Black
}

pub fn player_decoder() {
  use player_string <- decode.then(decode.string)
  case player_string {
    "white" -> decode.success(White)
    "black" -> decode.success(Black)
    _ -> decode.failure(White, "Invalid player")
  }
}

pub fn move(fen: String, _, _) -> Result(String, String) {
  let _board = fen.parse(fen)
  Ok("e2e4")
}
