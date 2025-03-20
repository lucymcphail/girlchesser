import girlchesser/board/board
import girlchesser/board/movegen
import girlchesser/fen
import gleam/dynamic/decode
import gleam/int
import iv

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
  let assert Ok(pos) = fen.parse(fen)
  let moves = movegen.generate_moves(pos)
  case iv.get(moves, int.random(iv.length(moves))) {
    Ok(move) -> {
      Ok(board.move_to_string(move))
    }
    _ -> Ok("failed")
  }
}
