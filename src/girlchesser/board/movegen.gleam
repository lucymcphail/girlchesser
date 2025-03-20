import girlchesser/board/board.{type Board}
import gleam/list
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

pub fn generate_pawn_moves(pos: Board) -> iv.Array(board.Move) {
  let pawn_direction = case pos.side_to_move {
    board.Black -> 16
    board.White -> -16
  }

  let starting_rank = case pos.side_to_move {
    board.Black -> 7
    board.White -> 2
  }

  my_pieces(pos, board.Pawn)
  |> iv.flat_map(fn(square) {
    // One space moves ---------------------------------------------------------
    let moves = case pos.pieces |> iv.get(square + pawn_direction) {
      Ok(board.Empty) ->
        iv.from_list([board.NormalMove(square, square + pawn_direction)])
      _ -> iv.from_list([])
    }

    // Two space moves ---------------------------------------------------------
    let moves = case
      board.rank(square) == starting_rank
      && pos.pieces |> iv.get(square + pawn_direction) == Ok(board.Empty)
      && pos.pieces |> iv.get(square + pawn_direction * 2) == Ok(board.Empty)
    {
      True ->
        moves
        |> iv.append(board.NormalMove(square, square + pawn_direction * 2))
      False -> moves
    }

    // Captures ----------------------------------------------------------------
    // left
    let moves = case pos.pieces |> iv.get(square + pawn_direction - 1) {
      Ok(board.Occupied(color, _)) ->
        case color != pos.side_to_move {
          True ->
            moves
            |> iv.append(board.NormalMove(square, square + pawn_direction - 1))
          False -> moves
        }
      _ -> moves
    }
    // right
    let moves = case pos.pieces |> iv.get(square + pawn_direction + 1) {
      Ok(board.Occupied(color, _)) ->
        case color != pos.side_to_move {
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
      pos.en_passant == option.Some(square + pawn_direction - 1)
    {
      True ->
        moves
        |> iv.append(board.EnPassantMove(square, square + pawn_direction - 1))
      False -> moves
    }
    // right
    let moves = case
      pos.en_passant == option.Some(square + pawn_direction + 1)
    {
      True ->
        moves
        |> iv.append(board.EnPassantMove(square, square + pawn_direction + 1))
      False -> moves
    }

    // Promotion ---------------------------------------------------------------
    let to_rank = board.rank(square + pawn_direction)
    let moves = case
      { to_rank == 1 || to_rank == 8 }
      && iv.get(pos.pieces, square + pawn_direction) == Ok(board.Empty)
    {
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

pub type CastlingDirection {
  KingSide
  QueenSide
}

pub fn can_castle(
  pos: Board,
  color: board.Color,
  direction: CastlingDirection,
) -> Bool {
  let source_square = case color {
    board.Black -> board.square(5, 8)
    board.White -> board.square(5, 1)
  }

  let castling_squares = case color {
    board.Black ->
      case direction {
        KingSide -> [board.square(6, 8), board.square(7, 8)]
        QueenSide -> [
          board.square(2, 8),
          board.square(3, 8),
          board.square(4, 8),
        ]
      }
    board.White ->
      case direction {
        KingSide -> [board.square(6, 1), board.square(7, 1)]
        QueenSide -> [
          board.square(2, 1),
          board.square(3, 1),
          board.square(4, 1),
        ]
      }
  }

  case
    castling_squares
    |> list.all(fn(square) {
      case pos.pieces |> iv.get(square) {
        Ok(piece) -> piece == board.Empty
        Error(_) -> False
      }
    })
  {
    False -> False
    True ->
      castling_squares
      |> list.all(fn(square) {
        let pieces =
          pos.pieces
          |> iv.try_set(source_square, board.Empty)
          |> iv.try_set(square, board.Occupied(pos.side_to_move, board.King))
        !is_in_check(board.Board(..pos, pieces:), pos.side_to_move)
      })
  }
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
    let moves = case pos.side_to_move {
      board.Black ->
        case pos.black_castle_rights {
          board.Both ->
            case
              can_castle(pos, board.Black, KingSide)
              && can_castle(pos, board.Black, QueenSide)
            {
              True ->
                moves
                |> iv.append_list([
                  board.CastlingMove(square, square + 2),
                  board.CastlingMove(square, square - 2),
                ])
              False ->
                case can_castle(pos, board.Black, KingSide) {
                  True ->
                    moves |> iv.append(board.CastlingMove(square, square + 2))
                  False ->
                    case can_castle(pos, board.Black, QueenSide) {
                      True ->
                        moves
                        |> iv.append(board.CastlingMove(square, square - 2))
                      False -> moves
                    }
                }
            }
          board.KingSide ->
            case can_castle(pos, board.Black, KingSide) {
              True -> moves |> iv.append(board.CastlingMove(square, square + 2))
              False -> moves
            }
          board.QueenSide ->
            case can_castle(pos, board.Black, QueenSide) {
              True -> moves |> iv.append(board.CastlingMove(square, square - 2))
              False -> moves
            }
          board.NoRights -> moves
        }

      board.White ->
        case pos.black_castle_rights {
          board.Both ->
            case
              can_castle(pos, board.White, KingSide)
              && can_castle(pos, board.White, QueenSide)
            {
              True ->
                moves
                |> iv.append_list([
                  board.CastlingMove(square, square + 2),
                  board.CastlingMove(square, square - 2),
                ])
              False ->
                case can_castle(pos, board.White, KingSide) {
                  True ->
                    moves |> iv.append(board.CastlingMove(square, square + 2))
                  False ->
                    case can_castle(pos, board.White, QueenSide) {
                      True ->
                        moves
                        |> iv.append(board.CastlingMove(square, square - 2))
                      False -> moves
                    }
                }
            }
          board.KingSide ->
            case can_castle(pos, board.White, KingSide) {
              True -> moves |> iv.append(board.CastlingMove(square, square + 2))
              False -> moves
            }
          board.QueenSide ->
            case can_castle(pos, board.White, QueenSide) {
              True -> moves |> iv.append(board.CastlingMove(square, square - 2))
              False -> moves
            }
          board.NoRights -> moves
        }
    }

    moves
  })
}

fn make_sliding_moves(
  pos: Board,
  square: Int,
  direction: Int,
) -> iv.Array(board.Move) {
  do_make_sliding_moves(pos, square, direction, 1, iv.from_list([]))
}

fn do_make_sliding_moves(
  pos: Board,
  square: Int,
  direction: Int,
  index: Int,
  acc: iv.Array(board.Move),
) -> iv.Array(board.Move) {
  let target = square + direction * index
  case iv.get(pos.pieces, target) {
    Ok(piece) ->
      case piece {
        board.Empty -> {
          let acc = acc |> iv.append(board.NormalMove(square, target))
          do_make_sliding_moves(pos, square, direction, index + 1, acc)
        }
        board.Occupied(color, _) ->
          case color != pos.side_to_move {
            True -> acc |> iv.append(board.NormalMove(square, target))
            False -> acc
          }
        board.OutsideBoard -> acc
      }
    Error(_) -> acc
  }
}

pub fn generate_bishop_moves(pos: Board) -> iv.Array(board.Move) {
  my_pieces(pos, board.Bishop)
  |> iv.flat_map(fn(square) {
    iv.from_list([-17, -15, 15, 17])
    |> iv.flat_map(fn(direction) { make_sliding_moves(pos, square, direction) })
  })
}

pub fn generate_rook_moves(pos: Board) -> iv.Array(board.Move) {
  my_pieces(pos, board.Rook)
  |> iv.flat_map(fn(square) {
    iv.from_list([-16, -1, 1, 16])
    |> iv.flat_map(fn(direction) { make_sliding_moves(pos, square, direction) })
  })
}

pub fn generate_queen_moves(pos: Board) -> iv.Array(board.Move) {
  my_pieces(pos, board.Queen)
  |> iv.flat_map(fn(square) {
    iv.from_list([-17, -16, -15, -1, 1, 15, 16, 17])
    |> iv.flat_map(fn(direction) { make_sliding_moves(pos, square, direction) })
  })
}

pub fn generate_knight_moves(pos: Board) -> iv.Array(board.Move) {
  my_pieces(pos, board.Knight)
  |> iv.flat_map(fn(square) {
    //     -33 --- -31
    // -18      |      -14
    //  |------ 0 ------|
    //  14      |       18
    //     +31 --- +33
    iv.from_list([-33, -31, -18, -14, 14, 18, 31, 33])
    |> iv.filter_map(fn(offset) {
      case can_move_to(pos, square + offset) {
        True -> Ok(board.NormalMove(square, square + offset))
        False -> Error("")
      }
    })
  })
}

pub fn generate_pseudolegal_moves(pos: Board) -> iv.Array(board.Move) {
  iv.flatten(
    iv.from_list([
      generate_pawn_moves(pos),
      generate_knight_moves(pos),
      generate_bishop_moves(pos),
      generate_rook_moves(pos),
      generate_queen_moves(pos),
      generate_king_moves(pos),
    ]),
  )
}

fn is_in_check(pos: Board, color: board.Color) -> Bool {
  // let the other player have a free turn,
  let pos = board.Board(..pos, side_to_move: board.other_color(color))

  // and see if they can capture the king
  generate_pseudolegal_moves(pos)
  |> iv.any(fn(move) {
    case pos.pieces |> iv.get(move.to) {
      Ok(piece) ->
        case piece {
          board.Occupied(_, board.King) -> True
          _ -> False
        }
      _ -> False
    }
  })
}

pub fn generate_moves(pos: Board) -> iv.Array(board.Move) {
  generate_pseudolegal_moves(pos)
  |> iv.filter(fn(move) {
    board.move_to_string(move)
    case board.make_move(pos, move) {
      Ok(new_pos) -> !is_in_check(new_pos, pos.side_to_move)
      Error(_) -> False
    }
  })
}
