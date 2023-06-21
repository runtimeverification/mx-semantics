
module LIST-BYTES
  imports private INT-SYNTAX
  imports private BASIC-K

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
  syntax ListBytes ::= ListItem(Bytes)
          [ function, total, hook(LIST.element), klabel(ListBytesItem),
            symbol, smtlib(smt_seq_elem)
          ]
  syntax Bytes ::= ListBytes "[" Int "]"
          [ function, hook(LIST.get), klabel(ListBytes:get), symbol ]
  syntax ListBytes ::= ListBytes "[" index: Int "<-" value: Bytes "]"
          [function, hook(LIST.update), klabel(ListBytes:set)]
  syntax ListBytes ::= makeListBytes(length: Int, value: Bytes)
          [function, hook(LIST.make)]
  syntax ListBytes ::= updateList(dest: ListBytes, index: Int, src: ListBytes)
          [function, hook(LIST.updateAll)]
  syntax ListBytes ::= fillList(ListBytes, index: Int, length: Int, value: Bytes)
          [function, hook(LIST.fill)]
  syntax ListBytes ::= range(ListBytes, fromFront: Int, fromBack: Int)
          [function, hook(LIST.range), klabel(ListBytes:range), symbol]
  syntax Bool ::= Bytes "in" ListBytes
          [function, total, hook(LIST.in), klabel(_inListBytes_)]
  syntax Int ::= size(ListBytes)
          [function, total, hook(LIST.size), klabel (sizeListBytes), smtlib(smt_seq_len)]
endmodule

module LIST-BYTES-EXTENSIONS
  imports BOOL
  imports INT
  imports LIST-BYTES

  syntax Bytes ::= ListBytes "[" Int "]" "orDefault" Bytes
          [ function, total, klabel(ListBytes:getOrDefault), symbol ]

  rule ListItem(V:Bytes) _:ListBytes [0] orDefault _:Bytes
      => V
  rule _:ListBytes ListItem(V:Bytes) [-1] orDefault _:Bytes
      => V
  rule .ListBytes [_:Int] orDefault D:Bytes => D

  rule ListItem(_:Bytes) L:ListBytes [I:Int] orDefault D:Bytes
      => L[I -Int 1] orDefault D
    requires 0 <Int I
  rule L:ListBytes ListItem(_:Bytes) [I:Int] orDefault D:Bytes
      => L[I +Int 1] orDefault D
    requires I <Int 0

  rule L:ListBytes[I:Int] orDefault D:Bytes => D
    requires notBool (0 -Int size(L) <=Int I andBool I <Int size(L))
    [simplification]
endmodule
