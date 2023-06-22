
module BYTES-TYPE
  import BYTES-SYNTAX

  syntax WrappedBytes
  syntax Bytes

  syntax WrappedBytes ::= wrap(Bytes)  [symbol, klabel(wrapBytes)]
  syntax Bytes ::= unwrap(WrappedBytes)  [function, total, injective, symbol, klabel(unwrapBytes)]
  rule unwrap(wrap(A:Bytes)) => A
endmodule
