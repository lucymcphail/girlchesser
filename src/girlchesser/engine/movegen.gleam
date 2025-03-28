////
////

// IMPORTS ---------------------------------------------------------------------

import girlchesser/board.{type Board, type CastleRights, type Move, type Piece}
import girlchesser/board/position.{type Position}
import gleam/bool
import gleam/list
import gleam/option
import iv

// MOVES -----------------------------------------------------------------------

const generators = [pawn, knight, bishop, rook, queen, king]

/// Generate all valid moves for the current player. These moves are guaranteed
/// to never leave the player in check.
///
pub fn legal(board: Board) -> List(Move) {
  do_legal(board, pseudolegal(board), [])
}

fn do_legal(
  board: Board,
  pseudolegal: List(Move),
  moves: List(Move),
) -> List(Move) {
  case pseudolegal {
    [] -> moves
    [move, ..rest] ->
      case is_in_check(board.move(board, move) |> board.swap_sides) {
        True -> do_legal(board, rest, moves)
        False -> do_legal(board, rest, [move, ..moves])
      }
  }
}

/// Generate all moves that the current player can make, regardless of whether
/// they would leave the player in check.
///
pub fn pseudolegal(board: Board) -> List(Move) {
  use moves, generator <- list.fold(generators, [])
  generator(board, moves)
}

// PAWN MOVES ------------------------------------------------------------------

/// General all possible pseudolegal pawn moves. These moves may leave the player
/// in check!
///
/// Possible moves include:
///
///   - Moving one square forward
///   - Moving two squares forward from the starting rank
///   - Capturing diagonally (including en passant)
///   - Promoting
///
pub fn pawn(board: Board, moves: List(Move)) -> List(Move) {
  let pawn_direction = case board.side_to_move {
    board.Black -> 16
    board.White -> -16
  }

  use moves, square <- generate_moves(board, for: board.Pawn, with: moves)

  moves
  |> pawn_one_space_moves(board, square, square + pawn_direction)
  |> pawn_two_space_moves(board, square, pawn_direction)
  |> pawn_capture_moves(board, square, square + pawn_direction - 1)
  |> pawn_capture_moves(board, square, square + pawn_direction + 1)
}

fn pawn_one_space_moves(
  moves: List(Move),
  board: Board,
  square: Position,
  target: Position,
) -> List(Move) {
  let is_promoting = position.rank(target) == 1 || position.rank(target) == 8

  case iv.get(board.pieces, target) {
    Ok(board.Empty) if is_promoting ->
      list.append(promotions(square, target), moves)

    Ok(board.Empty) -> [board.Move(square, target), ..moves]

    _ -> moves
  }
}

fn pawn_two_space_moves(
  moves: List(Move),
  board: Board,
  square: Position,
  direction: Int,
) -> List(Move) {
  let starting_rank = case board.side_to_move {
    board.Black -> 7
    board.White -> 2
  }

  use <- bool.guard(position.rank(square) != starting_rank, moves)
  let in_front = iv.get(board.pieces, square + direction)
  let target = iv.get(board.pieces, square + direction * 2)

  case in_front, target {
    Ok(board.Empty), Ok(board.Empty) -> [
      board.Move(square, square + direction * 2),
      ..moves
    ]

    _, _ -> moves
  }
}

fn pawn_capture_moves(
  moves: List(Move),
  board: Board,
  square: Position,
  target: Position,
) -> List(Move) {
  let is_promoting = position.rank(target) == 1 || position.rank(target) == 8

  case iv.get(board.pieces, target) {
    Ok(board.Occupied(colour:, ..)) if colour != board.side_to_move ->
      case is_promoting {
        True -> list.append(promotions(square, target), moves)
        False -> [board.Move(square, target), ..moves]
      }

    _ if board.en_passant == option.Some(target) ->
      case is_promoting {
        True -> list.append(promotions(square, target), moves)
        False -> [board.EnPassant(square, target), ..moves]
      }

    _ -> moves
  }
}

fn promotions(source: Position, target: Position) {
  [
    board.Promote(source, target, board.Knight),
    board.Promote(source, target, board.Bishop),
    board.Promote(source, target, board.Rook),
    board.Promote(source, target, board.Queen),
  ]
}

// KING MOVES ------------------------------------------------------------------

/// Generate all possible pseudolegal king moves. These moves may leave the player
/// in check!
///
/// Possible moves include:
///
///   - Moving one square in any direction
///   - Castling
///
pub fn king(board: Board, moves: List(Move)) -> List(Move) {
  let rights = case board.side_to_move {
    board.Black -> board.black_castle_rights
    board.White -> board.white_castle_rights
  }

  use moves, square <- generate_moves(board, for: board.King, with: moves)

  moves
  |> king_one_space_moves(board, square)
  |> king_castling_moves(board, square, rights)
}

const king_directions = [-17, -16, -15, -1, 1, 15, 16, 17]

fn king_one_space_moves(
  moves: List(Move),
  board: Board,
  square: Position,
) -> List(Move) {
  use moves, direction <- list.fold(king_directions, moves)
  let target = square + direction

  case iv.get(board.pieces, target) {
    Ok(board.Empty) -> [board.Move(square, target), ..moves]
    Ok(board.Occupied(colour, _)) if colour != board.side_to_move -> [
      board.Move(square, target),
      ..moves
    ]
    _ -> moves
  }
}

fn king_castling_moves(
  moves: List(Move),
  board: Board,
  square: Position,
  rights: CastleRights,
) -> List(Move) {
  let kingside_castle = board.Castle(square, square + 2)
  let queenside_castle = board.Castle(square, square - 2)

  case rights {
    board.Both -> {
      let can_castle_kingside = can_castle(board, board.side_to_move, KingSide)
      let can_castle_queenside =
        can_castle(board, board.side_to_move, QueenSide)

      case can_castle_kingside && can_castle_queenside {
        True -> [kingside_castle, queenside_castle, ..moves]
        False if can_castle_kingside -> [kingside_castle, ..moves]
        False if can_castle_queenside -> [queenside_castle, ..moves]
        False -> moves
      }
    }

    board.KingSide -> {
      case can_castle(board, board.side_to_move, KingSide) {
        True -> [kingside_castle, ..moves]
        False -> moves
      }
    }

    board.QueenSide -> {
      case can_castle(board, board.side_to_move, QueenSide) {
        True -> [queenside_castle, ..moves]
        False -> moves
      }
    }

    _ -> moves
  }
}

type CastlingDirection {
  KingSide
  QueenSide
}

fn can_castle(
  board: Board,
  colour: board.Colour,
  direction: CastlingDirection,
) -> Bool {
  let source_square = case colour {
    board.Black -> position.from(5, 8)
    board.White -> position.from(5, 1)
  }

  let castling_rank = case colour {
    board.Black -> 8
    board.White -> 1
  }

  let must_be_empty_squares = case direction {
    KingSide -> [
      position.from(6, castling_rank),
      position.from(7, castling_rank),
    ]

    QueenSide -> [
      position.from(3, castling_rank),
      position.from(4, castling_rank),
      // this square needs to be empty to castle queenside, but since
      // the king never moves through it, we don't need to check
      // whether this square is attacked.
      position.from(2, castling_rank),
    ]
  }

  // first, check if all the squares we're trying to castle through are empty
  case
    list.all(must_be_empty_squares, fn(square) {
      case iv.get(board.pieces, square) {
        Ok(board.Empty) -> True
        _ -> False
      }
    })
  {
    False -> False
    True ->
      // next, check if we're currently in check (doing this after
      // ruling out the castle being blocked, in order to potentially
      // save the expensive check computation)
      case is_in_check(board) {
        True -> False
        False -> {
          // finally, check that we're not castling through check
          let must_not_be_in_check_squares = list.take(must_be_empty_squares, 2)

          use square <- list.all(must_not_be_in_check_squares)
          use <- bool.guard(
            iv.get(board.pieces, square) != Ok(board.Empty),
            False,
          )

          let pieces =
            board.pieces
            |> iv.try_set(source_square, board.Empty)
            |> iv.try_set(
              square,
              board.Occupied(board.side_to_move, board.King),
            )

          !is_in_check(board.Board(..board, pieces:))
        }
      }
  }
}

// ROOK MOVES ------------------------------------------------------------------

const rook_directions = [-16, -1, 1, 16]

/// Generate all possible pseudolegal rook moves. These moves may leave the player
/// in check!
///
pub fn rook(board: Board, moves: List(board.Move)) -> List(board.Move) {
  use moves, square <- generate_moves(board, for: board.Rook, with: moves)
  use moves, direction <- list.fold(rook_directions, moves)

  generate_sliding_moves(moves, board, square, direction, 1)
}

// BISHOP MOVES ----------------------------------------------------------------

const bishop_directions = [-17, -15, 15, 17]

/// Generate all possible pseudolegal bishop moves. These moves may leave the player
/// in check!
///
pub fn bishop(board: Board, moves: List(board.Move)) -> List(board.Move) {
  use moves, square <- generate_moves(board, for: board.Bishop, with: moves)
  use moves, direction <- list.fold(bishop_directions, moves)

  generate_sliding_moves(moves, board, square, direction, 1)
}

// QUEEN MOVES -----------------------------------------------------------------

const queen_directions = [-17, -16, -15, -1, 1, 15, 16, 17]

/// Generate all possible pseudolegal queen moves. These moves may leave the player
/// in check!
///
pub fn queen(board: Board, moves: List(board.Move)) -> List(board.Move) {
  use moves, square <- generate_moves(board, for: board.Queen, with: moves)
  use moves, direction <- list.fold(queen_directions, moves)

  generate_sliding_moves(moves, board, square, direction, 1)
}

// KNIGHT MOVES ----------------------------------------------------------------

///     -33 --- -31
/// -18      |      -14
///  |------ 0 ------|
///  14      |       18
///     +31 --- +33
const knight_directions = [-33, -31, -18, -14, 14, 18, 31, 33]

/// Generate all possible pseudolegal knight moves. These moves may leave the player
/// in check!
///
pub fn knight(board: Board, moves: List(Move)) -> List(board.Move) {
  use moves, square <- generate_moves(board, for: board.Knight, with: moves)
  use moves, direction <- list.fold(knight_directions, moves)

  case iv.get(board.pieces, square + direction) {
    Ok(board.Occupied(colour, _)) if colour != board.side_to_move -> [
      board.Move(square, square + direction),
      ..moves
    ]

    Ok(board.Empty) -> [board.Move(square, square + direction), ..moves]

    _ -> moves
  }
}

// UTILS -----------------------------------------------------------------------

fn generate_moves(
  board: Board,
  for piece: Piece,
  with moves: List(Move),
  using generator: fn(List(Move), Position) -> List(Move),
) -> List(Move) {
  use moves, square, index <- iv.index_fold(board.pieces, moves)

  case square {
    board.Empty | board.OutsideBoard -> moves
    board.Occupied(..) -> {
      case square.colour == board.side_to_move && square.piece == piece {
        True -> generator(moves, index)
        False -> moves
      }
    }
  }
}

fn generate_sliding_moves(
  moves: List(Move),
  board: Board,
  square: Position,
  direction: Int,
  index: Int,
) -> List(board.Move) {
  let target = square + direction * index

  case iv.get(board.pieces, target) {
    Ok(board.Empty) ->
      [board.Move(square, target), ..moves]
      |> generate_sliding_moves(board, square, direction, index + 1)

    Ok(board.Occupied(colour, _)) if colour != board.side_to_move -> [
      board.Move(square, target),
      ..moves
    ]

    _ -> moves
  }
}

fn is_in_check(board: Board) -> Bool {
  // legal chess positions have exactly one king of each colour, so it's
  // fine to assert here
  let assert Ok(king) =
    iv.index_of(
      board.pieces,
      of: board.Occupied(board.side_to_move, board.King),
    )

  check_straight_attacks(board, king)
  || check_diagonal_attacks(board, king)
  || check_knight_attacks(board, king)
  || check_pawn_attacks(board, king)
}

fn check_pawn_attacks(board: Board, king: Position) -> Bool {
  let pawn_directions = case board.side_to_move {
    board.White -> [-17, -15]
    board.Black -> [15, 17]
  }

  do_check_pawn_attacks(board, king, pawn_directions)
}

fn do_check_pawn_attacks(
  board: Board,
  king: Position,
  directions: List(Int),
) -> Bool {
  case directions {
    [] -> False
    [offset, ..rest] -> {
      let pawn_square = king + offset
      let enemy_pawn =
        board.Occupied(board.other_colour(board.side_to_move), board.Pawn)

      case iv.get(board.pieces, pawn_square) {
        Ok(piece) if piece == enemy_pawn -> True
        _ -> do_check_pawn_attacks(board, king, rest)
      }
    }
  }
}

fn check_knight_attacks(board: Board, king: Position) -> Bool {
  do_check_knight_attacks(board, king, knight_directions)
}

fn do_check_knight_attacks(
  board: Board,
  king: Position,
  directions: List(Int),
) -> Bool {
  case directions {
    [] -> False
    [offset, ..rest] -> {
      let knight_square = king + offset
      let enemy_knight =
        board.Occupied(board.other_colour(board.side_to_move), board.Knight)

      case iv.get(board.pieces, knight_square) {
        Ok(piece) if piece == enemy_knight -> True
        _ -> do_check_knight_attacks(board, king, rest)
      }
    }
  }
}

fn check_straight_attacks(board: Board, king: Position) -> Bool {
  do_check_straight_attacks(board, king, rook_directions)
}

fn do_check_straight_attacks(
  board: Board,
  king: Position,
  directions: List(Int),
) -> Bool {
  case directions {
    [] -> False
    [direction, ..rest] -> {
      case check_ray_for_enemy_piece(board, king, direction, 1) {
        Ok(board.Rook) | Ok(board.Queen) -> True
        _ -> do_check_straight_attacks(board, king, rest)
      }
    }
  }
}

fn check_diagonal_attacks(board: Board, king: Position) -> Bool {
  do_check_diagonal_attacks(board, king, bishop_directions)
}

fn do_check_diagonal_attacks(
  board: Board,
  king: Position,
  directions: List(Int),
) -> Bool {
  case directions {
    [] -> False
    [direction, ..rest] -> {
      case check_ray_for_enemy_piece(board, king, direction, 1) {
        Ok(board.Bishop) | Ok(board.Queen) -> True
        _ -> do_check_diagonal_attacks(board, king, rest)
      }
    }
  }
}

fn check_ray_for_enemy_piece(
  board: Board,
  square: Position,
  direction: Int,
  index: Int,
) -> Result(board.Piece, Nil) {
  let target = square + direction * index

  case iv.get(board.pieces, target) {
    Ok(board.Empty) ->
      check_ray_for_enemy_piece(board, square, direction, index + 1)

    Ok(board.Occupied(colour, piece)) if colour != board.side_to_move ->
      Ok(piece)

    _ -> Error(Nil)
  }
}
