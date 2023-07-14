
module BYTES-TYPE
  import BYTES

  syntax WrappedBytes
  syntax BYTES

  syntax WrappedBytes ::= wrap(Bytes)    [symbol, klabel(wrapBytes)]
  syntax Bytes ::= unwrap(WrappedBytes)  [function, total, injective, symbol, klabel(unwrapBytes)]
  rule unwrap(wrap(A:Bytes)) => A
endmodule
