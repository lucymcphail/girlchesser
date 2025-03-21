import birdie
import girlchesser/board
import uci/request

// POSITION --------------------------------------------------------------------

pub fn position_startpos_test() {
  let input = "position startpos"
  let assert Ok(request.Position(board)) = request.parse(input)

  board
  |> board.to_string
  |> birdie.snap("[uci] " <> input)
}

pub fn position_startpos_moves_test() {
  let input = "position startpos moves e2e4 e7e5 g1f3"
  let assert Ok(request.Position(board)) = request.parse(input)

  board
  |> board.to_string
  |> birdie.snap("[uci] " <> input)
}

pub fn postition_fen_test() {
  let input =
    "position fen rnbqkbnr/ppp2ppp/4p3/8/2PP4/8/PP2PPPP/RNBQKBNR b KQkq - 0 3"
  let assert Ok(request.Position(board)) = request.parse(input)

  board
  |> board.to_string
  |> birdie.snap("[uci] " <> input)
}

pub fn postition_fen_moves_test() {
  let input =
    "position fen rnbqkbnr/ppp2ppp/4p3/8/2PP4/8/PP2PPPP/RNBQKBNR b KQkq - 0 3 moves b8c6 g1f3 g8f6"
  let assert Ok(request.Position(board)) = request.parse(input)

  board
  |> board.to_string
  |> birdie.snap("[uci] " <> input)
}
