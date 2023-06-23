
module INT-TYPE
  import BYTES-SYNTAX

  syntax WrappedInt
  syntax Int

  syntax WrappedInt ::= wrap(Int)  [symbol, klabel(wrapInt)]
  syntax Int ::= unwrap(WrappedInt)  [function, total, injective, symbol, klabel(unwrapInt)]
  rule unwrap(wrap(A:Int)) => A
endmodule
