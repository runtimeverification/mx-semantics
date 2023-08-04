requires "bytes-type.k"

module LIST-BYTES
  imports private INT-SYNTAX
  imports private BASIC-K
  
  imports private BYTES-TYPE
  
  syntax Bytes

  syntax ListBytes [hook(LIST.List)]
  syntax ListBytes ::= ListBytes ListBytes
          [ left, function, total, hook(LIST.concat),
            klabel(_ListBytes_), symbol, smtlib(smt_seq_concat),
            assoc, unit(.ListBytes), element(ListBytesItem),
            format(%1%n%2)
          ]
  syntax ListBytes ::= ".ListBytes"
          [ function, total, hook(LIST.unit), klabel(.ListBytes),
            symbol, smtlib(smt_seq_nil), latex(\dotCt{ListBytes})
          ]
  syntax ListBytes ::= ListItem(WrappedBytes)
          [ function, total, hook(LIST.element), klabel(ListBytesItem),
            symbol, smtlib(smt_seq_elem)
          ]
  syntax WrappedBytes ::= ListBytes "[" Int "]"
          [ function, hook(LIST.get), klabel(ListBytes:get), symbol ]
  syntax ListBytes ::= ListBytes "[" index: Int "<-" value: WrappedBytes "]"
          [function, hook(LIST.update), klabel(ListBytes:set)]
  syntax ListBytes ::= makeListBytes(length: Int, value: WrappedBytes)
          [function, hook(LIST.make)]
  syntax ListBytes ::= updateList(dest: ListBytes, index: Int, src: ListBytes)
          [function, hook(LIST.updateAll)]
  syntax ListBytes ::= fillList(ListBytes, index: Int, length: Int, value: WrappedBytes)
          [function, hook(LIST.fill)]
  syntax ListBytes ::= range(ListBytes, fromFront: Int, fromBack: Int)
          [function, hook(LIST.range), klabel(ListBytes:range), symbol]
  syntax Bool ::= WrappedBytes "in" ListBytes
          [function, total, hook(LIST.in), klabel(_inListBytes_)]
  syntax Int ::= size(ListBytes)
          [function, total, hook(LIST.size), klabel (sizeListBytes), smtlib(smt_seq_len)]
endmodule

module LIST-BYTES-EXTENSIONS
  imports BOOL
  imports INT
  imports LIST-BYTES

  syntax WrappedBytes ::= ListBytes "[" Int "]" "orDefault" WrappedBytes
          [ function, total, klabel(ListBytes:getOrDefault), symbol ]

  rule ListItem(V:WrappedBytes) _:ListBytes [0] orDefault _:WrappedBytes
      => V
  rule _:ListBytes ListItem(V:WrappedBytes) [-1] orDefault _:WrappedBytes
      => V
  rule .ListBytes [_:Int] orDefault D:WrappedBytes => D

  rule ListItem(_:WrappedBytes) L:ListBytes [I:Int] orDefault D:WrappedBytes
      => L[I -Int 1] orDefault D
    requires 0 <Int I
  rule L:ListBytes ListItem(_:WrappedBytes) [I:Int] orDefault D:WrappedBytes
      => L[I +Int 1] orDefault D
    requires I <Int 0

  rule L:ListBytes[I:Int] orDefault D:WrappedBytes => D
    requires notBool (0 -Int size(L) <=Int I andBool I <Int size(L))
    [simplification]
endmodule
