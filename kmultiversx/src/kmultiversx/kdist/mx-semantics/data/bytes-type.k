
module BYTES-TYPE
  imports BYTES

  syntax WrappedBytes
  syntax BYTES

  syntax WrappedBytes ::= wrap(Bytes)    [symbol(wrapBytes)]
  syntax Bytes ::= unwrap(WrappedBytes)  [function, total, injective, symbol(unwrapBytes)]
  rule unwrap(wrap(A:Bytes)) => A
endmodule
