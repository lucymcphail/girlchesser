////
////   https://p4wn.sourceforge.net/src/fen-test.html
////

// IMPORTS ---------------------------------------------------------------------

import birdie
import girlchesser/board
import girlchesser/fen
import gleeunit/should

// SNAPSHOTS -------------------------------------------------------------------

pub fn checkmate_in_1_test() {
  "5k2/8/5K2/4Q3/5P2/8/8/8 w - - 3 61"
  |> fen.parse
  |> should.be_ok
  |> board.to_string
  |> birdie.snap("[fen] checkmate in 1")
}

pub fn checkmate_in_2_test() {
  "4kb2/3r1p2/2R3p1/6B1/p6P/P3p1P1/P7/5K2 w - - 0 36"
  |> fen.parse
  |> should.be_ok
  |> board.to_string
  |> birdie.snap("[fen] checkmate in 2")
}

pub fn checkmate_in_6_test() {
  "8/8/8/8/8/4K3/5Q2/7k w - - 11 56"
  |> fen.parse
  |> should.be_ok
  |> board.to_string
  |> birdie.snap("[fen] checkmate in 6")
}

pub fn en_passant_1_test() {
  "rn1qkbnr/p1p1pppp/8/1pPp4/3P1B2/8/PP2PPPP/Rb1QKBNR w KQkq b6 0 5"
  |> fen.parse
  |> should.be_ok
  |> board.to_string
  |> birdie.snap("[fen] en passant 1")
}

pub fn en_passant_2_test() {
  "rnb1r1k1/ppp2ppp/8/8/2PN4/2Nn4/P3BPPP/R3K2R w KQ - 5 14"
  |> fen.parse
  |> should.be_ok
  |> board.to_string
  |> birdie.snap("[fen] en passant 2")
}

pub fn initial_state_test() {
  "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 1 1"
  |> fen.parse
  |> should.be_ok
  |> board.to_string
  |> birdie.snap("[fen] initial state")
}

pub fn lategame_1_test() {
  "4k3/4n3/8/3N1R2/4R2p/7P/1r3BK1/8 b - - 6 42"
  |> fen.parse
  |> should.be_ok
  |> board.to_string
  |> birdie.snap("[fen] lategame 1")
}

pub fn lategame_2_test() {
  "8/p2P1N2/8/4p2k/1p2P3/1P1b2pK/P6P/n7 w - - 0 33"
  |> fen.parse
  |> should.be_ok
  |> board.to_string
  |> birdie.snap("[fen] lategame 2")
}

pub fn midgame_1_test() {
  "r3kb1r/ppBnp1pp/5p2/1N1n1b2/2BP4/5NP1/P4P1P/R1R3K1 b kq - 1 16"
  |> fen.parse
  |> should.be_ok
  |> board.to_string
  |> birdie.snap("[fen] midgame 1")
}

pub fn midgame_2_test() {
  "r3kb1r/1pBnp1pp/p4p2/1N1n1b2/2BP4/5NP1/P4P1P/R1R3K1 w kq - 0 17"
  |> fen.parse
  |> should.be_ok
  |> board.to_string
  |> birdie.snap("[fen] midgame 2")
}
