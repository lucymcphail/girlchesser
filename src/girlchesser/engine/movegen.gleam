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

/// Generate all valid moves for the current player. These moves are guaranteed
/// to never leave the player in check.
///
pub fn legal(board: Board) -> List(Move) {
  use move <- list.filter(pseudolegal(board))
  let next = board.move(board, move) |> board.swap_sides

  !is_in_check(next)
}

/// Generate all moves that the current player can make, regardless of whether
/// they would leave the player in check.
///
pub fn pseudolegal(board: Board) -> List(Move) {
  list.flatten([
    pawn(board),
    knight(board),
    bishop(board),
    rook(board),
    queen(board),
    king(board),
  ])
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
pub fn pawn(board: Board) -> List(Move) {
  let pawn_direction = case board.side_to_move {
    board.Black -> 16
    board.White -> -16
  }

  let empty = list.new()
  use square <- generate_moves(board, for: board.Pawn)

  empty
  |> pawn_one_space_moves(board, square, square + pawn_direction)
  |> pawn_two_space_moves(board, square, pawn_direction)
  |> pawn_capture_moves(board, square, square + pawn_direction - 1)
  |> pawn_capture_moves(board, square, square + pawn_direction + 1)
  |> pawn_promotion_moves(board, square, square + pawn_direction)
}

fn pawn_one_space_moves(
  moves: List(Move),
  board: Board,
  square: Position,
  target: Position,
) -> List(Move) {
  case iv.get(board.pieces, target) {
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
  case iv.get(board.pieces, target) {
    Ok(board.Occupied(colour:, ..)) if colour != board.side_to_move -> [
      board.Move(square, target),
      ..moves
    ]

    _ if board.en_passant == option.Some(target) -> [
      board.EnPassant(square, target),
      ..moves
    ]

    _ -> moves
  }
}

fn pawn_promotion_moves(
  moves: List(Move),
  board: Board,
  square: Position,
  target: Position,
) -> List(Move) {
  case iv.get(board.pieces, target), position.rank(target) {
    Ok(board.Empty), 1 | Ok(board.Empty), 8 -> [
      board.Promote(square, target, board.Knight),
      board.Promote(square, target, board.Bishop),
      board.Promote(square, target, board.Rook),
      board.Promote(square, target, board.Queen),
      ..moves
    ]

    _, _ -> moves
  }
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
pub fn king(board: Board) -> List(Move) {
  let empty = list.new()
  let rights = case board.side_to_move {
    board.Black -> board.black_castle_rights
    board.White -> board.white_castle_rights
  }

  use square <- generate_moves(board, for: board.King)

  empty
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
pub fn rook(board: Board) -> List(board.Move) {
  let empty = list.new()
  use square <- generate_moves(board, for: board.Rook)
  use moves, direction <- list.fold(rook_directions, empty)

  generate_sliding_moves(moves, board, square, direction, 1)
}

// BISHOP MOVES ----------------------------------------------------------------

const bishop_directions = [-17, -15, 15, 17]

/// Generate all possible pseudolegal bishop moves. These moves may leave the player
/// in check!
///
pub fn bishop(board: Board) -> List(board.Move) {
  let empty = list.new()
  use square <- generate_moves(board, for: board.Bishop)
  use moves, direction <- list.fold(bishop_directions, empty)

  generate_sliding_moves(moves, board, square, direction, 1)
}

// QUEEN MOVES -----------------------------------------------------------------

const queen_directions = [-17, -16, -15, -1, 1, 15, 16, 17]

/// Generate all possible pseudolegal queen moves. These moves may leave the player
/// in check!
///
pub fn queen(board: Board) -> List(board.Move) {
  let empty = list.new()
  use square <- generate_moves(board, for: board.Queen)
  use moves, direction <- list.fold(queen_directions, empty)

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
pub fn knight(board: Board) -> List(board.Move) {
  let empty = list.new()
  use square <- generate_moves(board, for: board.Knight)
  use moves, direction <- list.fold(knight_directions, empty)

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
  using generator: fn(Position) -> List(Move),
) -> List(Move) {
  use moves, square, index <- list.index_fold(
    board.pieces |> iv.to_list,
    list.new(),
  )

  case square {
    board.Empty | board.OutsideBoard -> moves
    board.Occupied(..) -> {
      case square.colour == board.side_to_move && square.piece == piece {
        True -> list.append(generator(index), moves)
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

  use offset <- list.any(pawn_directions)

  let pawn_square = king + offset
  let enemy_pawn =
    board.Occupied(board.other_colour(board.side_to_move), board.Pawn)

  case iv.get(board.pieces, pawn_square) {
    Ok(piece) if piece == enemy_pawn -> True
    _ -> False
  }
}

fn check_knight_attacks(board: Board, king: Position) -> Bool {
  use offset <- list.any(knight_directions)

  let knight_square = king + offset
  let enemy_knight =
    board.Occupied(board.other_colour(board.side_to_move), board.Knight)

  case iv.get(board.pieces, knight_square) {
    Ok(piece) if piece == enemy_knight -> True
    _ -> False
  }
}

fn check_straight_attacks(board: Board, king: Position) -> Bool {
  use direction <- list.any(rook_directions)

  case check_ray_for_enemy_piece(board, king, direction, 1) {
    Ok(board.Rook) | Ok(board.Queen) -> True
    _ -> False
  }
}

fn check_diagonal_attacks(board: Board, king: Position) -> Bool {
  use direction <- list.any(bishop_directions)

  case check_ray_for_enemy_piece(board, king, direction, 1) {
    Ok(board.Bishop) | Ok(board.Queen) -> True
    _ -> False
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
