////
////

// TYPES -----------------------------------------------------------------------

///
///
pub type Position =
  Int

// CONSTRUCTORS ----------------------------------------------------------------

///
///
pub fn from(file file: Int, rank rank: Int) -> Position {
  { 16 * { 8 - rank } } + { file - 1 } + 36
}

///
///
pub fn from_8x8(pos: Int) -> Position {
  16 * { rank(pos) - 1 } + { file(pos) - 1 } + 36
}

// CONVERSIONS -----------------------------------------------------------------

///
///
pub fn split(position: Position) -> #(Int, Int) {
  #(file(position), rank(position))
}

///
///
pub fn file(position: Position) -> Int {
  { { position - 36 } % 8 } + 1
}

///
///
pub fn rank(position: Position) -> Int {
  8 - { { position - 36 } / 16 }
}
