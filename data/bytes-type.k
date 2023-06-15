
module BYTES-TYPE
  import BYTES-SYNTAX

  syntax WrappedBytes
  syntax Bytes

  syntax WrappedBytes ::= wrap(Bytes)
  syntax Bytes ::= unwrap(WrappedBytes)  [function, total, injective]
  rule unwrap(wrap(A:Bytes)) => A
endmodule
