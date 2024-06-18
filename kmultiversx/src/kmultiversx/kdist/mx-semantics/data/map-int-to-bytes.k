
requires "int-type.k"
requires "bytes-type.k"

module MAP-INT-TO-BYTES
  imports private BOOL-SYNTAX
  imports private INT-SYNTAX
  imports private LIST-INT
  imports private LIST-BYTES
  // imports private LIST
  // imports private SET-INT
  imports private SET
  imports INT-TYPE
  imports BYTES-TYPE

  syntax Int
  syntax Bytes

  syntax MapIntToBytes [hook(MAP.Map)]
  syntax MapIntToBytes ::= MapIntToBytes MapIntToBytes
         [ left, function, hook(MAP.concat), symbol(_MapIntToBytes_),
           assoc, comm, unit(.MapIntToBytes), element(_Int2Bytes|->_),
           index(0), format(%1%n%2)
         ]
  syntax MapIntToBytes ::= ".MapIntToBytes"
         [ function, total, hook(MAP.unit),
           symbol(.MapIntToBytes)
         ]
  syntax MapIntToBytes ::= WrappedInt "Int2Bytes|->" WrappedBytes
         [ function, total, hook(MAP.element),
           symbol(_Int2Bytes|->_),
           injective
         ]

  syntax priority _Int2Bytes|->_ > _MapIntToBytes_ .MapIntToBytes
  syntax non-assoc _Int2Bytes|->_
  syntax WrappedBytes ::= MapIntToBytes "[" WrappedInt "]"
                 [function, hook(MAP.lookup), symbol(MapIntToBytes:lookup)]
  syntax WrappedBytes ::= MapIntToBytes "[" WrappedInt "]" "orDefault" WrappedBytes
                 [ function, total, hook(MAP.lookupOrDefault),
                   symbol(MapIntToBytes:lookupOrDefault)
                 ]
  syntax MapIntToBytes ::= MapIntToBytes "[" key: WrappedInt "<-" value: WrappedBytes "]"
                 [ function, total, symbol(MapIntToBytes:update),
                   hook(MAP.update), prefer
                 ]
  syntax MapIntToBytes ::= MapIntToBytes "[" WrappedInt "<-" "undef" "]"
                 [ function, total, hook(MAP.remove),
                   symbol(_MapIntToBytes[_<-undef])
                 ]
  syntax MapIntToBytes ::= MapIntToBytes "-Map" MapIntToBytes
                 [ function, total, hook(MAP.difference) ]
  syntax MapIntToBytes ::= updateMap(MapIntToBytes, MapIntToBytes)
                 [function, total, hook(MAP.updateAll)]

  syntax MapIntToBytes ::= removeAll(MapIntToBytes, Set)
                 [function, total, hook(MAP.removeAll)]
  // syntax MapIntToBytes ::= removeAll(MapIntToBytes, SetInt)
  //                [function, total, hook(MAP.removeAll)]

  syntax Set ::= keys(MapIntToBytes)
                 [function, total, hook(MAP.keys)]
  // syntax SetInt ::= keys(MapIntToBytes)
  //                [function, total, hook(MAP.keys)]

  // syntax List ::= "keys_list" "(" MapIntToBytes ")"
  //                [function, hook(MAP.keys_list)]
  syntax ListInt ::= "keys_list" "(" MapIntToBytes ")"
                 [function, hook(MAP.keys_list)]

  syntax Bool ::= WrappedInt "in_keys" "(" MapIntToBytes ")"
                 [function, total, hook(MAP.in_keys)]

  // syntax List ::= values(MapIntToBytes)
  //                [function, hook(MAP.values)]
  syntax ListBytes ::= values(MapIntToBytes)
                 [function, hook(MAP.values)]

  syntax Int ::= size(MapIntToBytes)
                 [function, total, hook(MAP.size), symbol(MapIntToBytes.sizeMap)]
  syntax Bool ::= MapIntToBytes "<=Map" MapIntToBytes
                 [function, total, hook(MAP.inclusion)]
  syntax WrappedInt ::= choice(MapIntToBytes)
                 [function, hook(MAP.choice), symbol(MapIntToBytes:choice)]
endmodule

module MAP-INT-TO-BYTES-PRIMITIVE
  imports public  BOOL
  imports private K-EQUAL
  imports public  MAP-INT-TO-BYTES

  syntax Bytes ::= MapIntToBytes "{{" Int "}}"
                 [function, symbol(MapIntToBytes:primitiveLookup)]
  syntax Bytes ::= MapIntToBytes "{{" Int "}}" "orDefault" Bytes
                 [ function, total, symbol(MapIntToBytes:primitiveLookupOrDefault) ]
  syntax MapIntToBytes ::= MapIntToBytes "{{" key: Int "<-" value: Bytes "}}"
                 [ function, total, symbol(MapIntToBytes:primitiveUpdate),
                   prefer
                 ]
  syntax MapIntToBytes ::= MapIntToBytes "{{" Int "<-" "undef" "}}"
                 [ function, total, symbol(MapIntToBytes:primitiveRemove) ]
  syntax Bool ::= Int "in_keys" "{{" MapIntToBytes "}}"
                 [function, total, symbol(MapIntToBytes:primitiveInKeys)]

  rule (M:MapIntToBytes {{ Key:Int }})
      => (unwrap( M[wrap(Key)] ))
  rule M:MapIntToBytes {{ Key:Int }} orDefault Value:Bytes
      => unwrap( M[wrap(Key)] orDefault wrap(Value) )
  rule M:MapIntToBytes {{ Key:Int <- Value:Bytes }}
      => M[wrap(Key) <- wrap(Value)]
  rule M:MapIntToBytes {{ Key:Int <- undef }}
      => M[wrap(Key) <- undef]
  rule Key:Int in_keys {{ M:MapIntToBytes }} => wrap(Key) in_keys(M)
endmodule

module MAP-INT-TO-BYTES-SYMBOLIC
  imports MAP-INT-TO-BYTES-KORE-SYMBOLIC
endmodule

module MAP-INT-TO-BYTES-KORE-SYMBOLIC  [symbolic]
  imports MAP-INT-TO-BYTES
  imports private K-EQUAL
  imports private BOOL

  rule #Ceil(@M:MapIntToBytes [@K:WrappedInt])
      => {(@K in_keys(@M)) #Equals true}
          #And #Ceil(@M) #And #Ceil(@K)
      [simplification]

  rule (K Int2Bytes|-> _ M:MapIntToBytes) [ K <- V ] => (K Int2Bytes|-> V M)
      [simplification, preserves-definedness]
  rule M:MapIntToBytes [ K <- V ] => (K Int2Bytes|-> V M) requires notBool (K in_keys(M))
      [simplification, preserves-definedness]
  rule M:MapIntToBytes [ K <- _ ] [ K <- V ] => M [ K <- V ] [simplification]
  // Adding the definedness condition `notBool (K1 in_keys(M))` in the ensures clause of the following rule would be redundant
  // because K1 also appears in the rhs, preserving the case when it's #Bottom.
  rule (K1 Int2Bytes|-> V1 M:MapIntToBytes) [ K2 <- V2 ] => (K1 Int2Bytes|-> V1 (M [ K2 <- V2 ]))
      requires K1 =/=K K2
      [simplification, preserves-definedness]

  // Symbolic remove
  rule (K Int2Bytes|-> _ M:MapIntToBytes) [ K <- undef ] => M
      ensures notBool (K in_keys(M))
      [simplification]
  rule M:MapIntToBytes [ K <- undef ] => M
      requires notBool (K in_keys(M))
      [simplification]
  // Adding the definedness condition `notBool (K1 in_keys(M))` in the ensures clause of the following rule would be redundant
  // because K1 also appears in the rhs, preserving the case when it's #Bottom.
  rule (K1 Int2Bytes|-> V1 M:MapIntToBytes) [ K2 <- undef ]
      => (K1 Int2Bytes|-> V1 (M [ K2 <- undef ]))
      requires K1 =/=K K2
      [simplification, preserves-definedness]

  // Symbolic lookup
  rule (K  Int2Bytes|->  V M:MapIntToBytes) [ K ] => V
      ensures notBool (K in_keys(M))
      [simplification]
  rule (K1 Int2Bytes|-> _V M:MapIntToBytes) [ K2 ] => M [K2]
      requires K1 =/=K K2
      ensures notBool (K1 in_keys(M))
      [simplification]
  rule (_MAP:MapIntToBytes [ K  <-  V1 ]) [ K ]  => V1 [simplification]
  rule ( MAP:MapIntToBytes [ K1 <- _V1 ]) [ K2 ] => MAP [ K2 ]
      requires K1 =/=K K2
      [simplification]

  rule (K  Int2Bytes|->  V M:MapIntToBytes) [  K ] orDefault _ => V
      ensures notBool (K in_keys(M))
      [simplification]
  rule (K1 Int2Bytes|-> _V M:MapIntToBytes) [ K2 ] orDefault D
      => M [K2] orDefault D
      requires K1 =/=K K2
      ensures notBool (K1 in_keys(M))
      [simplification]
  rule (_MAP:MapIntToBytes [ K  <-  V1 ]) [ K ] orDefault _ => V1 [simplification]
  rule ( MAP:MapIntToBytes [ K1 <- _V1 ]) [ K2 ] orDefault D
      => MAP [ K2 ] orDefault D
      requires K1 =/=K K2
      [simplification]
  rule .MapIntToBytes [ _ ] orDefault D => D [simplification]

  // Symbolic in_keys
  rule K in_keys(_M:MapIntToBytes [ K <- undef ]) => false [simplification]
  rule K in_keys(_M:MapIntToBytes [ K <- _ ]) => true [simplification]
  rule K1 in_keys(M:MapIntToBytes [ K2 <- _ ])
      => true requires K1 ==K K2 orBool K1 in_keys(M)
      [simplification]
  rule K1 in_keys(M:MapIntToBytes [ K2 <- _ ])
      => K1 in_keys(M)
      requires K1 =/=K K2
      [simplification]

  rule K in_keys((K Int2Bytes|-> V) M:MapIntToBytes)
      => true
    requires notBool K in_keys(M)
    [simplification(50), preserves-definedness]
  rule K1 in_keys((K2 Int2Bytes|-> V) M:MapIntToBytes)
      => K1 in_keys(M)
    requires true
        andBool (notBool K2 in_keys(M))
        andBool K1 =/=K K2
    [simplification(50), preserves-definedness]
  rule K1 in_keys((K2 Int2Bytes|-> V) M:MapIntToBytes)
      => K1 ==K K2 orBool K1 in_keys(M)
    requires notBool K2 in_keys(M)
    [simplification(100), preserves-definedness]


  rule {false #Equals @Key in_keys(.MapIntToBytes)} => #Ceil(@Key) [simplification]
  rule {@Key in_keys(.MapIntToBytes) #Equals false} => #Ceil(@Key) [simplification]
  rule {false #Equals @Key in_keys(Key' Int2Bytes|-> Val @M:MapIntToBytes)}
      =>  #Ceil(@Key) #And #Ceil(Key' Int2Bytes|-> Val @M)
          #And #Not({@Key #Equals Key'})
          #And {false #Equals @Key in_keys(@M)}
      [simplification]
  rule {@Key in_keys(Key' Int2Bytes|-> Val @M:MapIntToBytes) #Equals false}
      =>  #Ceil(@Key) #And #Ceil(Key' Int2Bytes|-> Val @M)
          #And #Not({@Key #Equals Key'})
          #And {@Key in_keys(@M) #Equals false}
      [simplification]
endmodule

