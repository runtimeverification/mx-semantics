
module INT-TYPE
  import BYTES-SYNTAX

  syntax WrappedInt
  syntax Int

  syntax WrappedInt ::= wrap(Int)
  syntax Int ::= unwrap(WrappedInt)  [function, total, injective]
  rule unwrap(wrap(A:Int)) => A
endmodule
