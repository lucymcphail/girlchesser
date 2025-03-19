import girlchesser/board/board
import iv

fn my_pieces(board: board.Board, piece: board.Piece) -> iv.Array(Int) {
  board.pieces
  |> iv.index_map(fn(square, i) { #(i, square) })
  |> iv.filter_map(fn(indexed_square) {
    let #(i, square) = indexed_square
    case square == board.Occupied(board.side_to_move, piece) {
      True -> Ok(i)
      False -> Error("")
    }
  })
}

pub fn generate_pawn_moves(board: board.Board) -> iv.Array(board.Move) {
  let pawn_direction = case board.side_to_move {
    board.Black -> 16
    board.White -> -16
  }

  let starting_rank = case board.side_to_move {
    board.Black -> 7
    board.White -> 2
  }

  my_pieces(board, board.Pawn)
  |> iv.flat_map(fn(square) {
    // One space moves ---------------------------------------------------------
    let moves = case board.pieces |> iv.get(square + pawn_direction) {
      Ok(board.Empty) ->
        iv.from_list([board.NormalMove(square, square + pawn_direction)])
      _ -> iv.from_list([])
    }

    // Two space moves ---------------------------------------------------------
    let moves = case
      board.rank(square) == starting_rank
      && board.pieces |> iv.get(square + pawn_direction) == Ok(board.Empty)
      && board.pieces |> iv.get(square + pawn_direction * 2) == Ok(board.Empty)
    {
      True ->
        moves
        |> iv.append(board.NormalMove(square, square + pawn_direction * 2))
      False -> moves
    }
    moves
  })
}
