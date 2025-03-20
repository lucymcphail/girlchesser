import girlchesser/board/board.{type Board}
import gleam/option
import iv

fn my_pieces(pos: Board, piece: board.Piece) -> iv.Array(Int) {
  pos.pieces
  |> iv.index_map(fn(square, i) { #(i, square) })
  |> iv.filter_map(fn(indexed_square) {
    let #(i, square) = indexed_square
    case square == board.Occupied(pos.side_to_move, piece) {
      True -> Ok(i)
      False -> Error("")
    }
  })
}

pub fn can_move_to(board: Board, square: Int) -> Bool {
  case board.pieces |> iv.get(square) {
    Ok(piece) ->
      case piece {
        board.Occupied(color, _) -> color != board.side_to_move
        board.Empty -> True
        board.OutsideBoard -> False
      }
    Error(_) -> False
  }
}

pub fn generate_pawn_moves(board: Board) -> iv.Array(board.Move) {
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

    // Captures ----------------------------------------------------------------
    // left
    let moves = case board.pieces |> iv.get(square + pawn_direction - 1) {
      Ok(board.Occupied(color, _)) ->
        case color != board.side_to_move {
          True ->
            moves
            |> iv.append(board.NormalMove(square, square + pawn_direction - 1))
          False -> moves
        }
      _ -> moves
    }
    // right
    let moves = case board.pieces |> iv.get(square + pawn_direction + 1) {
      Ok(board.Occupied(color, _)) ->
        case color != board.side_to_move {
          True ->
            moves
            |> iv.append(board.NormalMove(square, square + pawn_direction + 1))
          False -> moves
        }
      _ -> moves
    }

    // En passant --------------------------------------------------------------
    // left
    let moves = case
      board.en_passant == option.Some(square + pawn_direction - 1)
    {
      True ->
        moves
        |> iv.append(board.EnPassantMove(square, square + pawn_direction - 1))
      False -> moves
    }
    // right
    let moves = case
      board.en_passant == option.Some(square + pawn_direction + 1)
    {
      True ->
        moves
        |> iv.append(board.EnPassantMove(square, square + pawn_direction + 1))
      False -> moves
    }

    // Promotion ---------------------------------------------------------------
    let to_rank = board.rank(square + pawn_direction)
    let moves = case to_rank == 1 || to_rank == 8 {
      True ->
        moves
        |> iv.append_list([
          board.PromotionMove(square, square + pawn_direction, board.Knight),
          board.PromotionMove(square, square + pawn_direction, board.Bishop),
          board.PromotionMove(square, square + pawn_direction, board.Rook),
          board.PromotionMove(square, square + pawn_direction, board.Queen),
        ])
      False -> moves
    }

    moves
  })
}

pub fn generate_king_moves(pos: Board) -> iv.Array(board.Move) {
  my_pieces(pos, board.King)
  |> iv.flat_map(fn(square) {
    // Normal moves ------------------------------------------------------------
    let moves =
      iv.from_list([-17, -16, -15, -1, 1, 15, 16, 17])
      |> iv.filter_map(fn(offset) {
        case can_move_to(pos, square) {
          True -> Ok(board.NormalMove(square, square + offset))
          False -> Error("")
        }
      })

    // Castling ----------------------------------------------------------------
    // TODO: disallow castling through pieces or through check
    let moves = case pos.side_to_move {
      board.Black ->
        case pos.black_castle_rights {
          board.Both ->
            moves
            |> iv.append_list([
              board.CastlingMove(square, square + 2),
              board.CastlingMove(square, square - 2),
            ])
          board.KingSide ->
            moves |> iv.append(board.CastlingMove(square, square + 2))
          board.QueenSide ->
            moves |> iv.append(board.CastlingMove(square, square - 2))
          board.NoRights -> moves
        }

      board.White ->
        case pos.white_castle_rights {
          board.Both ->
            moves
            |> iv.append_list([
              board.CastlingMove(square, square + 2),
              board.CastlingMove(square, square - 2),
            ])
          board.KingSide ->
            moves |> iv.append(board.CastlingMove(square, square + 2))
          board.QueenSide ->
            moves |> iv.append(board.CastlingMove(square, square - 2))
          board.NoRights -> moves
        }
    }

    moves
  })
}

pub fn generate_bishop_moves(board: Board) -> iv.Array(board.Move) {
  todo
}

pub fn generate_rook_moves(board: Board) -> iv.Array(board.Move) {
  todo
}

pub fn generate_queen_moves(board: Board) -> iv.Array(board.Move) {
  todo
}

pub fn generate_knight_moves(pos: Board) -> iv.Array(board.Move) {
  my_pieces(pos, board.Knight)
  |> iv.flat_map(fn(square) {
    iv.from_list([-33, -31, -18, -14, 14, 18, 31, 33])
    |> iv.filter_map(fn(offset) {
      case can_move_to(pos, square) {
        True -> Ok(board.NormalMove(square, square + offset))
        False -> Error("")
      }
    })
  })
}

pub fn generate_pseudolegal_moves(board: Board) -> iv.Array(board.Move) {
  iv.flatten(
    iv.from_list([
      generate_pawn_moves(board),
      generate_knight_moves(board),
      generate_bishop_moves(board),
      generate_rook_moves(board),
      generate_queen_moves(board),
      generate_king_moves(board),
    ]),
  )
}
