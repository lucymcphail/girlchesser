import birdie
import girlchesser/board/board.{Move, square}
import girlchesser/fen
import gleam/option
import gleeunit/should

pub fn make_move_1_test() {
  fen.startpos
  |> fen.parse
  |> should.be_ok
  |> board.make_move(Move(square(5, 2), square(5, 4)))
  |> should.be_ok
  |> board.make_move(Move(square(4, 7), square(4, 5)))
  |> should.be_ok
  |> board.make_move(Move(square(5, 4), square(4, 5)))
  |> should.be_ok
  |> board.make_move(Move(square(4, 8), square(4, 5)))
  |> should.be_ok
  |> board.make_move(Move(square(2, 1), square(3, 3)))
  |> should.be_ok
  |> board.make_move(Move(square(4, 5), square(1, 5)))
  |> should.be_ok
  |> board.to_string
  |> birdie.snap("[board] Scandinavian defence")
}

pub fn en_passant_test() {
  "rnbqkbnr/ppp1ppp1/7p/3pP3/8/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 3"
  |> fen.parse
  |> should.be_ok
  |> board.make_move(Move(square(5, 5), square(4, 6)))
  |> should.be_ok
  |> board.to_string
  |> birdie.snap("[board] Capturing en passant")
}

pub fn en_passant_target_test() {
  let pos =
    fen.startpos
    |> fen.parse
    |> should.be_ok
    |> board.make_move(Move(square(5, 2), square(5, 4)))
    |> should.be_ok

  pos.en_passant
  |> should.equal(option.Some(square(5, 3)))

  let pos =
    pos
    |> board.make_move(Move(square(5, 7), square(5, 5)))
    |> should.be_ok

  pos.en_passant
  |> should.equal(option.Some(square(5, 6)))

  let pos =
    pos
    |> board.make_move(Move(square(7, 1), square(6, 3)))
    |> should.be_ok

  pos.en_passant
  |> should.equal(option.None)
}

pub fn castle_rights_1_test() {
  let pos =
    "r1bqk1nr/pppp1Bpp/2n5/2b1p3/4P3/5N2/PPPP1PPP/RNBQK2R b KQkq - 0 4"
    |> fen.parse
    |> should.be_ok
    |> board.make_move(Move(square(5, 8), square(6, 7)))
    |> should.be_ok

  pos.black_castle_rights
  |> should.equal(board.NoRights)

  let pos =
    pos
    |> board.make_move(Move(square(8, 1), square(7, 1)))
    |> should.be_ok

  pos.white_castle_rights
  |> should.equal(board.QueenSide)
}

pub fn castle_rights_2_test() {
  let pos =
    "rnbqkbnr/1ppppp1p/5Qp1/p7/4P3/8/PPPP1PPP/RNB1KBNR w KQkq - 0 4"
    |> fen.parse
    |> should.be_ok
    |> board.make_move(Move(square(6, 6), square(8, 8)))
    |> should.be_ok

  pos.black_castle_rights
  |> should.equal(board.QueenSide)
}
