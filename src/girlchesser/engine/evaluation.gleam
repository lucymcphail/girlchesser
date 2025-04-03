////
////

// IMPORTS ---------------------------------------------------------------------

import girlchesser/board.{type Board}
import iv

// EVALUATION ------------------------------------------------------------------

/// Evaluate a chess position by comparing the material difference in
/// each player's pieces.
///
pub fn evaluate(board: Board) -> Float {
  material_difference(board)
}

/// Calculate the material difference in the given position, where
/// positive values represent a material advantage for the player
/// whose turn it is to move.
///
fn material_difference(board: Board) -> Float {
  use acc, square <- iv.fold(board.pieces, 0.0, _)

  let value = case square {
    board.Occupied(_, board.Pawn) -> 1.0
    board.Occupied(_, board.Knight) -> 3.0
    board.Occupied(_, board.Bishop) -> 3.0
    board.Occupied(_, board.Rook) -> 5.0
    board.Occupied(_, board.Queen) -> 9.0
    _ -> 0.0
  }

  case square {
    // our piece, add to the score
    board.Occupied(colour, _) if colour == board.side_to_move -> acc +. value

    // enemy piece, subtract from the score
    board.Occupied(_, _) -> acc -. value

    _ -> acc
  }
}
