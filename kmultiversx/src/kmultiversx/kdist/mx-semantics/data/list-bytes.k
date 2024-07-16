requires "bytes-type.k"

module LIST-BYTES
  imports private INT-SYNTAX
  imports private BASIC-K
  imports BYTES-TYPE

  syntax Bytes

  syntax ListBytes [hook(LIST.List)]
  syntax ListBytes ::= ListBytes ListBytes
          [ left, function, total, hook(LIST.concat),
            symbol(_ListBytes_), smtlib(smt_seq_concat),
            assoc, unit(.ListBytes), element(ListBytesItem),
            format(%1%n%2)
          ]
  syntax ListBytes ::= ".ListBytes"
          [ function, total, hook(LIST.unit), symbol(.ListBytes),
            smtlib(smt_seq_nil)
          ]
  syntax ListBytes ::= ListItem(WrappedBytes)
          [ function, total, hook(LIST.element), symbol(ListBytesItem),
            smtlib(smt_seq_elem)
          ]
  syntax WrappedBytes ::= ListBytes "[" Int "]"
          [ function, hook(LIST.get), symbol(ListBytes:get) ]
  syntax ListBytes ::= ListBytes "[" index: Int "<-" value: WrappedBytes "]"
          [function, hook(LIST.update), symbol(ListBytes:set)]
  syntax ListBytes ::= makeListBytes(length: Int, value: WrappedBytes)
          [function, hook(LIST.make)]
  syntax ListBytes ::= updateList(dest: ListBytes, index: Int, src: ListBytes)
          [function, hook(LIST.updateAll)]
  syntax ListBytes ::= fillList(ListBytes, index: Int, length: Int, value: WrappedBytes)
          [function, hook(LIST.fill)]
  syntax ListBytes ::= range(ListBytes, fromFront: Int, fromBack: Int)
          [function, hook(LIST.range), symbol(ListBytes:range)]
  syntax Bool ::= WrappedBytes "in" ListBytes
          [function, total, hook(LIST.in), symbol(_inListBytes_)]
  syntax Int ::= size(ListBytes)
          [function, total, hook(LIST.size), symbol(sizeListBytes), smtlib(smt_seq_len)]
endmodule

module LIST-BYTES-EXTENSIONS
  imports BOOL
  imports INT
  imports LIST-BYTES

  syntax WrappedBytes ::= ListBytes "[" Int "]" "orDefault" WrappedBytes
          [ function, total, symbol(ListBytes:getOrDefault) ]

  syntax Bytes ::= ListBytes "{{" Int "}}"
                 [function, symbol(ListBytes:primitiveLookup)]
// -----------------------------------------------------------
  rule L:ListBytes {{ I:Int }} => unwrap( L[ I ] )
       [preserves-definedness] // defined or undefined on both sides

  syntax Bytes ::= ListBytes "{{" Int "}}" "orDefault" Bytes
                 [ function, total, symbol(ListBytes:primitiveLookupOrDefault) ]
// -----------------------------------------------------------------------------
  rule L:ListBytes {{ I:Int }} orDefault Value:Bytes
      => unwrap( L [I] orDefault wrap(Value) )

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

  syntax ListBytes ::= ListItemWrap( Bytes )
      [function, total, symbol(ListBytesItemWrap)]
  rule ListItemWrap( B:Bytes ) => ListItem(wrap(B))


  syntax ListBytes ::= ListBytes "{{" Int "<-" Bytes "}}"
                 [function, symbol(ListBytes:primitiveSet)]
// -----------------------------------------------------------
  rule L:ListBytes {{ I:Int <- V:Bytes }}
      => L[ I <- wrap(V)]

  // Workaround for the Haskell backend missing the range hook.
  // See https://github.com/runtimeverification/haskell-backend/issues/3706
  rule range(ListItem(_) L:ListBytes, FromStart:Int, FromEnd:Int)
      => range(L, FromStart -Int 1, FromEnd)
      requires 0 <Int FromStart
  rule range(L:ListBytes ListItem(_), 0, FromEnd:Int)
      => range(L, 0, FromEnd -Int 1)
      requires 0 <Int FromEnd
  rule range(L:ListBytes, 0, 0)
      => L

  syntax Bool ::= rangeDefined(ListBytes, fromStart:Int, fromEnd:Int)  [function, total]
  rule rangeDefined(L:ListBytes, FromStart:Int, FromEnd:Int)
      => 0 <=Int FromStart
        andBool 0 <=Int FromEnd
        andBool FromStart +Int FromEnd <=Int size(L)

  rule #Ceil(range(L:ListBytes, FromStart:Int, FromEnd:Int))
      => {true #Equals rangeDefined(L, FromStart, FromEnd)}
      [simplification]

  syntax ListBytes ::= rangeTotal(ListBytes, Int, Int)
      [function, total, symbol(ListBytes:rangeTotal)]
// ----------------------------------------------------------
  rule rangeTotal(L, Front, Back) => range(L, Front, Back)
    requires 0 <=Int Front
     andBool 0 <=Int Back
     andBool size(L) >=Int Front +Int Back

  rule rangeTotal(L, Front, Back) => rangeTotal(L, 0, Back)
    requires Front <Int 0

  rule rangeTotal(L, Front, Back) => rangeTotal(L, Front, 0)
    requires 0 <=Int Front
     andBool Back <Int 0

  rule rangeTotal(L, Front, Back) => .ListBytes
    requires 0 <=Int Front
     andBool 0 <=Int Back
     andBool size(L) <Int Front +Int Back

endmodule
