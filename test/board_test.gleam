import birdie
import girlchesser/board
import girlchesser/board/position
import girlchesser/fen
import gleam/option
import gleeunit/should

pub fn move_1_test() {
  fen.startpos
  |> fen.parse
  |> should.be_ok
  |> board.move(board.Move(position.from(5, 2), position.from(5, 4)))
  |> board.move(board.Move(position.from(4, 7), position.from(4, 5)))
  |> board.move(board.Move(position.from(5, 4), position.from(4, 5)))
  |> board.move(board.Move(position.from(4, 8), position.from(4, 5)))
  |> board.move(board.Move(position.from(2, 1), position.from(3, 3)))
  |> board.move(board.Move(position.from(4, 5), position.from(1, 5)))
  |> board.to_string
  |> birdie.snap("[board] Scandinavian defence")
}

pub fn en_passant_test() {
  "rnbqkbnr/ppp1ppp1/7p/3pP3/8/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 3"
  |> fen.parse
  |> should.be_ok
  |> board.move(board.EnPassant(position.from(5, 5), position.from(4, 6)))
  |> board.to_string
  |> birdie.snap("[board] Capturing en passant")
}

pub fn castling_kingside_test() {
  "r1bqk1nr/pppp1ppp/2n5/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4"
  |> fen.parse
  |> should.be_ok
  |> board.move(board.Castle(position.from(5, 1), position.from(7, 1)))
  |> board.to_string
  |> birdie.snap("[board] Castling kingside")
}

pub fn castling_queenside_test() {
  "r3k1nr/pppq1ppp/2npb3/2b1p3/2B1P3/2NP1N2/PPPB1PPP/R2Q1RK1 b kq - 4 7"
  |> fen.parse
  |> should.be_ok
  |> board.move(board.Castle(position.from(5, 8), position.from(3, 8)))
  |> board.to_string
  |> birdie.snap("[board] Castling queenside")
}

pub fn en_passant_target_test() {
  let pos =
    fen.startpos
    |> fen.parse
    |> should.be_ok
    |> board.move(board.Move(position.from(5, 2), position.from(5, 4)))

  pos.en_passant
  |> should.equal(option.Some(position.from(5, 3)))

  let pos =
    pos
    |> board.move(board.Move(position.from(5, 7), position.from(5, 5)))

  pos.en_passant
  |> should.equal(option.Some(position.from(5, 6)))

  let pos =
    pos
    |> board.move(board.Move(position.from(7, 1), position.from(6, 3)))

  pos.en_passant
  |> should.equal(option.None)
}

pub fn castle_rights_1_test() {
  let pos =
    "r1bqk1nr/pppp1Bpp/2n5/2b1p3/4P3/5N2/PPPP1PPP/RNBQK2R b KQkq - 0 4"
    |> fen.parse
    |> should.be_ok
    |> board.move(board.Move(position.from(5, 8), position.from(6, 7)))

  pos.black_castle_rights
  |> should.equal(board.NoRights)

  let pos =
    pos
    |> board.move(board.Move(position.from(8, 1), position.from(7, 1)))

  pos.white_castle_rights
  |> should.equal(board.QueenSide)
}

pub fn castle_rights_2_test() {
  let pos =
    "rnbqkbnr/1ppppp1p/5Qp1/p7/4P3/8/PPPP1PPP/RNB1KBNR w KQkq - 0 4"
    |> fen.parse
    |> should.be_ok
    |> board.move(board.Move(position.from(6, 6), position.from(8, 8)))

  pos.black_castle_rights
  |> should.equal(board.QueenSide)
}
