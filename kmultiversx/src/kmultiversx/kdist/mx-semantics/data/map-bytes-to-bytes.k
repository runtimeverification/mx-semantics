
requires "bytes-type.k"
// requires "bytes-type.k"
requires "list-bytes.k"

module MAP-BYTES-TO-BYTES
  imports private BOOL-SYNTAX
  imports private INT-SYNTAX
  imports private LIST-BYTES
  imports private LIST-BYTES
  // imports private LIST
  // imports private SET-BYTES
  imports private SET
  imports BYTES-TYPE
  imports BYTES-TYPE

  syntax Bytes
  syntax Bytes

  syntax MapBytesToBytes [hook(MAP.Map)]
  syntax MapBytesToBytes ::= MapBytesToBytes MapBytesToBytes
         [ left, function, hook(MAP.concat), symbol(_MapBytesToBytes_),
           assoc, comm, unit(.MapBytesToBytes), element(_Bytes2Bytes|->_),
           index(0), format(%1%n%2)
         ]
  syntax MapBytesToBytes ::= ".MapBytesToBytes"
         [ function, total, hook(MAP.unit),
           symbol(.MapBytesToBytes)
         ]
  syntax MapBytesToBytes ::= WrappedBytes "Bytes2Bytes|->" WrappedBytes
         [ function, total, hook(MAP.element),
           symbol(_Bytes2Bytes|->_),
           injective
         ]

  syntax priority _Bytes2Bytes|->_ > _MapBytesToBytes_ .MapBytesToBytes
  syntax non-assoc _Bytes2Bytes|->_
  syntax WrappedBytes ::= MapBytesToBytes "[" WrappedBytes "]"
                 [function, hook(MAP.lookup), symbol(MapBytesToBytes:lookup)]
  syntax WrappedBytes ::= MapBytesToBytes "[" WrappedBytes "]" "orDefault" WrappedBytes
                 [ function, total, hook(MAP.lookupOrDefault),
                   symbol(MapBytesToBytes:lookupOrDefault)
                 ]
  syntax MapBytesToBytes ::= MapBytesToBytes "[" key: WrappedBytes "<-" value: WrappedBytes "]"
                 [ function, total, symbol(MapBytesToBytes:update),
                   hook(MAP.update), prefer
                 ]
  syntax MapBytesToBytes ::= MapBytesToBytes "[" WrappedBytes "<-" "undef" "]"
                 [ function, total, hook(MAP.remove),
                   symbol(_MapBytesToBytes[_<-undef])
                 ]
  syntax MapBytesToBytes ::= MapBytesToBytes "-Map" MapBytesToBytes
                 [ function, total, hook(MAP.difference) ]
  syntax MapBytesToBytes ::= updateMap(MapBytesToBytes, MapBytesToBytes)
                 [function, total, hook(MAP.updateAll)]

  syntax MapBytesToBytes ::= removeAll(MapBytesToBytes, Set)
                 [function, total, hook(MAP.removeAll)]
  // syntax MapBytesToBytes ::= removeAll(MapBytesToBytes, SetBytes)
  //                [function, total, hook(MAP.removeAll)]

  syntax Set ::= keys(MapBytesToBytes)
                 [function, total, hook(MAP.keys)]
  // syntax SetBytes ::= keys(MapBytesToBytes)
  //                [function, total, hook(MAP.keys)]

  // syntax List ::= "keys_list" "(" MapBytesToBytes ")"
  //                [function, hook(MAP.keys_list)]
  syntax ListBytes ::= "keys_list" "(" MapBytesToBytes ")"
                 [function, hook(MAP.keys_list)]

  syntax Bool ::= WrappedBytes "in_keys" "(" MapBytesToBytes ")"
                 [function, total, hook(MAP.in_keys)]

  // syntax List ::= values(MapBytesToBytes)
  //                [function, hook(MAP.values)]
  syntax ListBytes ::= values(MapBytesToBytes)
                 [function, hook(MAP.values)]

  syntax Int ::= size(MapBytesToBytes)
                 [function, total, hook(MAP.size), symbol(MapBytesToBytes.sizeMap)]
  syntax Bool ::= MapBytesToBytes "<=Map" MapBytesToBytes
                 [function, total, hook(MAP.inclusion)]
  syntax WrappedBytes ::= choice(MapBytesToBytes)
                 [function, hook(MAP.choice), symbol(MapBytesToBytes:choice)]
endmodule

module MAP-BYTES-TO-BYTES-PRIMITIVE
  imports public  BOOL
  imports private K-EQUAL
  imports public  MAP-BYTES-TO-BYTES

  syntax Bytes ::= MapBytesToBytes "{{" Bytes "}}"
                 [function, symbol(MapBytesToBytes:primitiveLookup)]
  syntax Bytes ::= MapBytesToBytes "{{" Bytes "}}" "orDefault" Bytes
                 [ function, total, symbol(MapBytesToBytes:primitiveLookupOrDefault) ]
  syntax MapBytesToBytes ::= MapBytesToBytes "{{" key: Bytes "<-" value: Bytes "}}"
                 [ function, total, symbol(MapBytesToBytes:primitiveUpdate),
                   prefer
                 ]
  syntax MapBytesToBytes ::= MapBytesToBytes "{{" Bytes "<-" "undef" "}}"
                 [ function, total, symbol(MapBytesToBytes:primitiveRemove) ]
  syntax Bool ::= Bytes "in_keys" "{{" MapBytesToBytes "}}"
                 [function, total, symbol(MapBytesToBytes:primitiveInKeys)]

  rule (M:MapBytesToBytes {{ Key:Bytes }})
      => (unwrap( M[wrap(Key)] ))
  rule M:MapBytesToBytes {{ Key:Bytes }} orDefault Value:Bytes
      => unwrap( M[wrap(Key)] orDefault wrap(Value) )
  rule M:MapBytesToBytes {{ Key:Bytes <- Value:Bytes }}
      => M[wrap(Key) <- wrap(Value)]
  rule M:MapBytesToBytes {{ Key:Bytes <- undef }}
      => M[wrap(Key) <- undef]
  rule Key:Bytes in_keys {{ M:MapBytesToBytes }} => wrap(Key) in_keys(M)
endmodule

module MAP-BYTES-TO-BYTES-SYMBOLIC
  imports MAP-BYTES-TO-BYTES-KORE-SYMBOLIC
endmodule

module MAP-BYTES-TO-BYTES-KORE-SYMBOLIC  [symbolic]
  imports MAP-BYTES-TO-BYTES
  imports private K-EQUAL
  imports private BOOL

  rule #Ceil(@M:MapBytesToBytes [@K:WrappedBytes])
      => {(@K in_keys(@M)) #Equals true}
          #And #Ceil(@M) #And #Ceil(@K)
      [simplification]

  rule (K Bytes2Bytes|-> _ M:MapBytesToBytes) [ K <- V ] => (K Bytes2Bytes|-> V M)
      [simplification, preserves-definedness]
  rule M:MapBytesToBytes [ K <- V ] => (K Bytes2Bytes|-> V M) requires notBool (K in_keys(M))
      [simplification, preserves-definedness]
  rule M:MapBytesToBytes [ K <- _ ] [ K <- V ] => M [ K <- V ] [simplification]
  // Adding the definedness condition `notBool (K1 in_keys(M))` in the ensures clause of the following rule would be redundant
  // because K1 also appears in the rhs, preserving the case when it's #Bottom.
  rule (K1 Bytes2Bytes|-> V1 M:MapBytesToBytes) [ K2 <- V2 ] => (K1 Bytes2Bytes|-> V1 (M [ K2 <- V2 ]))
      requires K1 =/=K K2
      [simplification, preserves-definedness]

  // Symbolic remove
  rule (K Bytes2Bytes|-> _ M:MapBytesToBytes) [ K <- undef ] => M
      ensures notBool (K in_keys(M))
      [simplification]
  rule M:MapBytesToBytes [ K <- undef ] => M
      requires notBool (K in_keys(M))
      [simplification]
  // Adding the definedness condition `notBool (K1 in_keys(M))` in the ensures clause of the following rule would be redundant
  // because K1 also appears in the rhs, preserving the case when it's #Bottom.
  rule (K1 Bytes2Bytes|-> V1 M:MapBytesToBytes) [ K2 <- undef ]
      => (K1 Bytes2Bytes|-> V1 (M [ K2 <- undef ]))
      requires K1 =/=K K2
      [simplification, preserves-definedness]

  // Symbolic lookup
  rule (K  Bytes2Bytes|->  V M:MapBytesToBytes) [ K ] => V
      ensures notBool (K in_keys(M))
      [simplification]
  rule (K1 Bytes2Bytes|-> _V M:MapBytesToBytes) [ K2 ] => M [K2]
      requires K1 =/=K K2
      ensures notBool (K1 in_keys(M))
      [simplification]
  rule (_MAP:MapBytesToBytes [ K  <-  V1 ]) [ K ]  => V1 [simplification]
  rule ( MAP:MapBytesToBytes [ K1 <- _V1 ]) [ K2 ] => MAP [ K2 ]
      requires K1 =/=K K2
      [simplification]

  rule (K  Bytes2Bytes|->  V M:MapBytesToBytes) [  K ] orDefault _ => V
      ensures notBool (K in_keys(M))
      [simplification]
  rule (K1 Bytes2Bytes|-> _V M:MapBytesToBytes) [ K2 ] orDefault D
      => M [K2] orDefault D
      requires K1 =/=K K2
      ensures notBool (K1 in_keys(M))
      [simplification]
  rule (_MAP:MapBytesToBytes [ K  <-  V1 ]) [ K ] orDefault _ => V1 [simplification]
  rule ( MAP:MapBytesToBytes [ K1 <- _V1 ]) [ K2 ] orDefault D
      => MAP [ K2 ] orDefault D
      requires K1 =/=K K2
      [simplification]
  rule .MapBytesToBytes [ _ ] orDefault D => D [simplification]

  // Symbolic in_keys
  rule K in_keys(_M:MapBytesToBytes [ K <- undef ]) => false [simplification]
  rule K in_keys(_M:MapBytesToBytes [ K <- _ ]) => true [simplification]
  rule K1 in_keys(M:MapBytesToBytes [ K2 <- _ ])
      => true requires K1 ==K K2 orBool K1 in_keys(M)
      [simplification]
  rule K1 in_keys(M:MapBytesToBytes [ K2 <- _ ])
      => K1 in_keys(M)
      requires K1 =/=K K2
      [simplification]

  rule K in_keys((K Bytes2Bytes|-> V) M:MapBytesToBytes)
      => true
    requires notBool K in_keys(M)
    [simplification(50), preserves-definedness]
  rule K1 in_keys((K2 Bytes2Bytes|-> V) M:MapBytesToBytes)
      => K1 in_keys(M)
    requires true
        andBool (notBool K2 in_keys(M))
        andBool K1 =/=K K2
    [simplification(50), preserves-definedness]
  rule K1 in_keys((K2 Bytes2Bytes|-> V) M:MapBytesToBytes)
      => K1 ==K K2 orBool K1 in_keys(M)
    requires notBool K2 in_keys(M)
    [simplification(100), preserves-definedness]


  rule {false #Equals @Key in_keys(.MapBytesToBytes)} => #Ceil(@Key) [simplification]
  rule {@Key in_keys(.MapBytesToBytes) #Equals false} => #Ceil(@Key) [simplification]
  rule {false #Equals @Key in_keys(Key' Bytes2Bytes|-> Val @M:MapBytesToBytes)}
      =>  #Ceil(@Key) #And #Ceil(Key' Bytes2Bytes|-> Val @M)
          #And #Not({@Key #Equals Key'})
          #And {false #Equals @Key in_keys(@M)}
      [simplification]
  rule {@Key in_keys(Key' Bytes2Bytes|-> Val @M:MapBytesToBytes) #Equals false}
      =>  #Ceil(@Key) #And #Ceil(Key' Bytes2Bytes|-> Val @M)
          #And #Not({@Key #Equals Key'})
          #And {@Key in_keys(@M) #Equals false}
      [simplification]
endmodule

