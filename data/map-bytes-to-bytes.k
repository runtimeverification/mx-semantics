
// require "bytes-type.k"
// require "bytes-type.k"

module MAP-BYTES-TO-BYTES
  imports private BOOL-SYNTAX
  imports private INT-SYNTAX
  // imports private LIST-BYTES
  // imports private LIST-BYTES
  imports private LIST
  // imports private SET-BYTES
  imports private SET
  // imports BYTES-TYPE
  // imports BYTES-TYPE

  syntax Bytes
  syntax Bytes

  syntax MapBytesToBytes [hook(MAP.Map)]
  syntax MapBytesToBytes ::= MapBytesToBytes MapBytesToBytes
         [ left, function, hook(MAP.concat), klabel(_MapBytesToBytes_),
           symbol, assoc, comm, unit(.MapBytesToBytes), element(_Bytes2Bytes|->_),
           index(0), format(%1%n%2)
         ]
  syntax MapBytesToBytes ::= ".MapBytesToBytes"
         [ function, total, hook(MAP.unit),
           klabel(.MapBytesToBytes), symbol, latex(\dotCt{MapBytesToBytes})
         ]
  syntax MapBytesToBytes ::= Bytes "Bytes2Bytes|->" Bytes
         [ function, total, hook(MAP.element),
           klabel(_Bytes2Bytes|->_), symbol,
           latex({#1}\mapsto{#2}), injective
         ]

  syntax priorities _Bytes2Bytes|->_ > _MapBytesToBytes_ .MapBytesToBytes
  syntax non-assoc _Bytes2Bytes|->_
  syntax Bytes ::= MapBytesToBytes "[" Bytes "]"
                 [function, hook(MAP.lookup), klabel(MapBytesToBytes:lookup), symbol]
  syntax Bytes ::= MapBytesToBytes "[" Bytes "]" "orDefault" Bytes
                 [ function, total, hook(MAP.lookupOrDefault),
                   klabel(MapBytesToBytes:lookupOrDefault)
                 ]
  syntax MapBytesToBytes ::= MapBytesToBytes "[" key: Bytes "<-" value: Bytes "]"
                 [ function, total, klabel(MapBytesToBytes:update), symbol,
                   hook(MAP.update), prefer
                 ]
  syntax MapBytesToBytes ::= MapBytesToBytes "[" Bytes "<-" "undef" "]"
                 [ function, total, hook(MAP.remove),
                   klabel(_MapBytesToBytes[_<-undef]), symbol
                 ]
  syntax MapBytesToBytes ::= MapBytesToBytes "-Map" MapBytesToBytes
                 [ function, total, hook(MAP.difference),
                   latex({#1}-_{\it MapBytesToBytesMap}{#2})
                 ]
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

  syntax List ::= "keys_list" "(" MapBytesToBytes ")"
                 [function, hook(MAP.keys_list)]
  // syntax ListBytes ::= "keys_list" "(" MapBytesToBytes ")"
  //                [function, hook(MAP.keys_list)]

  syntax Bool ::= Bytes "in_keys" "(" MapBytesToBytes ")"
                 [function, total, hook(MAP.in_keys)]

  syntax List ::= values(MapBytesToBytes)
                 [function, hook(MAP.values)]
  // syntax ListBytes ::= values(MapBytesToBytes)
  //                [function, hook(MAP.values)]

  syntax Int ::= size(MapBytesToBytes)
                 [function, total, hook(MAP.size), klabel(MapBytesToBytes.sizeMap)]
  syntax Bool ::= MapBytesToBytes "<=Map" MapBytesToBytes
                 [function, total, hook(MAP.inclusion)]
  syntax Bytes ::= choice(MapBytesToBytes)
                 [function, hook(MAP.choice), klabel(MapBytesToBytes:choice)]
endmodule

module MAP-BYTES-TO-BYTES-PRIMITIVE
  imports MAP-BYTES-TO-BYTES-PRIMITIVE-CONCRETE
  imports MAP-BYTES-TO-BYTES-PRIMITIVE-SYMBOLIC
endmodule

module MAP-BYTES-TO-BYTES-PRIMITIVE-CONCRETE [concrete]
  imports public  BOOL
  imports private K-EQUAL
  imports public  MAP-BYTES-TO-BYTES
  imports private MAP-BYTES-TO-BYTES-KORE-SYMBOLIC

  syntax Bytes ::= MapBytesToBytes "{{" Bytes "}}"
                 [function, klabel(MapBytesToBytes:primitiveLookup)]
  syntax Bytes ::= MapBytesToBytes "{{" Bytes "}}" "orDefault" Bytes
                 [ function, total, klabel(MapBytesToBytes:primitiveLookupOrDefault) ]
  syntax MapBytesToBytes ::= MapBytesToBytes "{{" key: Bytes "<-" value: Bytes "}}"
                 [ function, total, klabel(MapBytesToBytes:primitiveUpdate), symbol,
                   prefer
                 ]
  syntax MapBytesToBytes ::= MapBytesToBytes "{{" Bytes "<-" "undef" "}}"
                 [ function, total, klabel(MapBytesToBytes:primitiveRemove), symbol ]
  syntax Bool ::= Bytes "in_keys" "{{" MapBytesToBytes "}}"
                 [function, total, klabel(MapBytesToBytes:primitiveInKeys)]

  rule M:MapBytesToBytes {{ Key:Bytes }}
      => M[Key]
  rule M:MapBytesToBytes {{ Key:Bytes }} orDefault Value:Bytes
      => M[Key] orDefault Value
  rule M:MapBytesToBytes {{ Key:Bytes <- Value:Bytes }}
      => M[Key <- Value]
  rule M:MapBytesToBytes {{ Key:Bytes <- undef }}
      => M[Key <- undef]
  rule Key:Bytes in_keys {{ M:MapBytesToBytes}} => Key in_keys(M)
endmodule

module MAP-BYTES-TO-BYTES-PRIMITIVE-SYMBOLIC  [symbolic]
  imports public  BOOL
  imports private K-EQUAL
  imports public  MAP-BYTES-TO-BYTES
  imports private MAP-BYTES-TO-BYTES-KORE-SYMBOLIC

  syntax Bytes ::= MapBytesToBytes "{{" Bytes "}}"
                 [function, klabel(MapBytesToBytes:primitiveLookup)]
  syntax Bytes ::= MapBytesToBytes "{{" Bytes "}}" "orDefault" Bytes
                 [ function, total, klabel(MapBytesToBytes:primitiveLookupOrDefault) ]
  syntax MapBytesToBytes ::= MapBytesToBytes "{{" key: Bytes "<-" value: Bytes "}}"
                 [ function, total, klabel(MapBytesToBytes:primitiveUpdate), symbol,
                   prefer
                 ]
  syntax MapBytesToBytes ::= MapBytesToBytes "{{" Bytes "<-" "undef" "}}"
                 [ function, total, klabel(MapBytesToBytes:primitiveRemove), symbol ]
  syntax Bool ::= Bytes "in_keys" "{{" MapBytesToBytes "}}"
                 [function, total, klabel(MapBytesToBytes:primitiveInKeys)]

  // Definitions
  // -----------

  rule (Key Bytes2Bytes|-> V:Bytes M:MapBytesToBytes)
          {{ Key:Bytes }}
      => V
      ensures notBool Key in_keys {{ M }}

  rule (Key Bytes2Bytes|-> V:Bytes M:MapBytesToBytes)
          {{ Key:Bytes }} orDefault _:Bytes
      => V
      ensures notBool Key in_keys {{ M }}
  rule M:MapBytesToBytes {{ Key:Bytes }} orDefault V:Bytes
      => V
      requires notBool Key in_keys {{ M }}

  rule (Key Bytes2Bytes|-> _:Bytes M:MapBytesToBytes)
          {{ Key:Bytes <- Value:Bytes }}
      => (Key Bytes2Bytes|-> Value) M
  rule M:MapBytesToBytes {{ Key:Bytes <- Value:Bytes }}
      => (Key Bytes2Bytes|-> Value) M
      requires notBool Key in_keys {{ M }}

  rule (Key Bytes2Bytes|-> _:Bytes M:MapBytesToBytes)
          {{ Key:Bytes <- undef }}
      => M
      ensures notBool Key in_keys {{ M }}
  rule M:MapBytesToBytes {{ Key:Bytes <- undef }}
      => M
      requires notBool Key in_keys {{ M }}

  rule Key:Bytes in_keys
          {{Key Bytes2Bytes|-> _:Bytes M:MapBytesToBytes}}
      => true
      ensures notBool Key in_keys {{ M }}
  rule _Key:Bytes in_keys {{ .MapBytesToBytes }}
      => false
  rule Key:Bytes in_keys
          {{Key2:Bytes Bytes2Bytes|-> _:Bytes M:MapBytesToBytes}}
      => true
      requires Key =/=K Key2
      ensures notBool Key2 in_keys (M)
      [simplification]

  // Translation rules
  rule M:MapBytesToBytes[Key:Bytes]
      => M{{Key}}
      [simplification, symbolic(M)]
  rule M:MapBytesToBytes[Key:Bytes]
      => M{{Key}}
      [simplification, symbolic(Key)]
  rule M:MapBytesToBytes{{Key}}
      => M[Key]
      [simplification, concrete]

  rule M:MapBytesToBytes [ Key:Bytes ] orDefault Value:Bytes
      => M {{ Key }} orDefault Value
      [simplification, symbolic(M)]
  rule M:MapBytesToBytes [ Key:Bytes ] orDefault Value:Bytes
      => M {{ Key }} orDefault Value
      [simplification, symbolic(Key)]
  rule M:MapBytesToBytes [ Key:Bytes ] orDefault Value:Bytes
      => M {{ Key }} orDefault Value
      [simplification, symbolic(Value)]
  rule M:MapBytesToBytes{{Key}} orDefault Value
      => M[Key] orDefault Value
      [simplification, concrete]

  rule M:MapBytesToBytes[Key:Bytes <- Value:Bytes]
      => M {{ Key <- Value }}
      [simplification, symbolic(M)]
  rule M:MapBytesToBytes[Key:Bytes <- Value:Bytes]
      => M {{ Key <- Value }}
      [simplification, symbolic(Key)]
  rule M:MapBytesToBytes[Key:Bytes <- Value:Bytes]
      => M {{ Key <- Value }}
      [simplification, symbolic(Value)]
  rule M:MapBytesToBytes{{Key <- Value}} => M[Key <- Value ]
      [simplification, concrete]

  rule M:MapBytesToBytes[Key:Bytes <- undef]
      => M {{ Key <- undef }}
      [simplification, symbolic(M)]
  rule M:MapBytesToBytes[Key:Bytes <- undef]
      => M {{ Key <- undef }}
      [simplification, symbolic(Key)]
  rule M:MapBytesToBytes{{Key <- undef}} => M[Key <- undef]
      [simplification, concrete]

  rule Key:Bytes in_keys (M:MapBytesToBytes)
      => Key in_keys {{M}}
      [simplification, symbolic(M)]
  rule Key:Bytes in_keys (M:MapBytesToBytes)
      => Key in_keys {{M}}
      [simplification, symbolic(Key)]
  rule Key in_keys {{M:MapBytesToBytes}} => Key in_keys(M)
      [simplification, concrete]

  // Symbolic execution rules
  // ------------------------
  syntax Bool ::= definedPrimitiveLookup(MapBytesToBytes, Bytes)  [function, total]
  rule definedPrimitiveLookup(M:MapBytesToBytes, K:Bytes) => K in_keys{{M}}

  rule #Ceil(@M:MapBytesToBytes {{@K:Bytes}})
      => {definedPrimitiveLookup(@M, @K) #Equals true}
          #And #Ceil(@M) #And #Ceil(@K)
      [simplification]

  rule M:MapBytesToBytes {{ K <- _ }} {{ K <- V }} => M {{ K <- V }} [simplification]
  rule (K1 Bytes2Bytes|-> V1 M:MapBytesToBytes) {{ K2 <- V2 }}
      => (K1 Bytes2Bytes|-> V1 (M {{ K2 <- V2 }}))
      requires K1 =/=K K2
      [simplification]

  rule (K1 Bytes2Bytes|-> V1 M:MapBytesToBytes) {{ K2 <- undef }}
      => (K1 Bytes2Bytes|-> V1 (M {{ K2 <- undef }}))
      requires K1 =/=K K2
      [simplification]

  rule (K1 Bytes2Bytes|-> _V M:MapBytesToBytes) {{ K2 }} => M {{K2}}
      requires K1 =/=K K2
      ensures notBool (K1 in_keys(M))
      [simplification]
  rule (_MAP:MapBytesToBytes {{ K  <-  V1 }}) {{ K }}  => V1 [simplification]
  rule ( MAP:MapBytesToBytes {{ K1 <- _V1 }}) {{ K2 }} => MAP {{ K2 }}
      requires K1 =/=K K2
      [simplification]

  rule (K1 Bytes2Bytes|-> _V M:MapBytesToBytes) {{ K2 }} orDefault D
      => M {{K2}} orDefault D
      requires K1 =/=K K2
      ensures notBool (K1 in_keys(M))
      [simplification]
  rule (_MAP:MapBytesToBytes {{ K  <-  V1 }}) {{ K }} orDefault _ => V1 [simplification]
  rule ( MAP:MapBytesToBytes {{ K1 <- _V1 }}) {{ K2 }} orDefault D
      => MAP {{ K2 }} orDefault D
      requires K1 =/=K K2
      [simplification]

  rule K in_keys{{_M:MapBytesToBytes {{ K <- undef }} }} => false [simplification]
  rule K in_keys{{_M:MapBytesToBytes {{ K <- _ }} }} => true [simplification]
  rule K1 in_keys{{ M:MapBytesToBytes {{ K2 <- _ }} }}
      => true requires K1 ==K K2 orBool K1 in_keys{{M}}
      [simplification]
  rule K1 in_keys{{ M:MapBytesToBytes {{ K2 <- _ }} }}
      => K1 in_keys {{ M }}
      requires K1 =/=K K2
      [simplification]

  rule K1 in_keys {{ (K2 Bytes2Bytes|-> V) M:MapBytesToBytes }}
      => K1 ==K K2 orBool K1 in_keys {{ M }}
    requires definedMapElementConcat(K2, V, M)
    [simplification(100)]
      

  rule {false #Equals @Key in_keys{{ Key' Bytes2Bytes|-> Val @M:MapBytesToBytes }}}
      =>  #Ceil(@Key) #And #Ceil(Key' Bytes2Bytes|-> Val @M)
          #And #Not({ @Key #Equals Key' })
          #And {false #Equals @Key in_keys{{@M}}}
      [simplification]
  rule {@Key in_keys{{Key' Bytes2Bytes|-> Val @M:MapBytesToBytes}} #Equals false}
      =>  #Ceil(@Key) #And #Ceil(Key' Bytes2Bytes|-> Val @M)
          #And #Not({@Key #Equals Key' })
          #And {@Key in_keys{{@M}} #Equals false}
      [simplification]

endmodule

module MAP-BYTES-TO-BYTES-KORE-SYMBOLIC
  imports MAP-BYTES-TO-BYTES
  imports private K-EQUAL
  imports private BOOL

  syntax Bool ::= definedMapElementConcat(Bytes, Bytes, MapBytesToBytes)  [function, total]
  rule definedMapElementConcat(K, _V, M:MapBytesToBytes) => notBool K in_keys(M)

  rule #Ceil(@M:MapBytesToBytes [@K:Bytes])
      => {(@K in_keys(@M)) #Equals true}
          #And #Ceil(@M) #And #Ceil(@K)
      [simplification]

  rule (K Bytes2Bytes|-> _ M:MapBytesToBytes) [ K <- V ] => (K Bytes2Bytes|-> V M) [simplification]
  rule M:MapBytesToBytes [ K <- V ] => (K Bytes2Bytes|-> V M) requires notBool (K in_keys(M))
      [simplification]
  rule M:MapBytesToBytes [ K <- _ ] [ K <- V ] => M [ K <- V ] [simplification]
  rule (K1 Bytes2Bytes|-> V1 M:MapBytesToBytes) [ K2 <- V2 ] => (K1 Bytes2Bytes|-> V1 (M [ K2 <- V2 ]))
      requires K1 =/=K K2
      [simplification]

  rule (K Bytes2Bytes|-> _ M:MapBytesToBytes) [ K <- undef ] => M
      ensures notBool (K in_keys(M))
      [simplification]
  rule M:MapBytesToBytes [ K <- undef ] => M
      requires notBool (K in_keys(M))
      [simplification]
  rule (K1 Bytes2Bytes|-> V1 M:MapBytesToBytes) [ K2 <- undef ]
      => (K1 Bytes2Bytes|-> V1 (M [ K2 <- undef ]))
      requires K1 =/=K K2
      [simplification]

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
    requires definedMapElementConcat(K, V, M)
    [simplification(50)]
  rule K1 in_keys((K2 Bytes2Bytes|-> V) M:MapBytesToBytes)
      => K1 in_keys(M)
    requires true
        andBool definedMapElementConcat(K2, V, M)
        andBool K1 =/=K K2
    [simplification(50)]
  rule K1 in_keys((K2 Bytes2Bytes|-> V) M:MapBytesToBytes)
      => K1 ==K K2 orBool K1 in_keys(M)
    requires definedMapElementConcat(K2, V, M)
    [simplification(100)]
      

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

module MAP-BYTES-TO-BYTES-CURLY-BRACE
  imports private BOOL
  imports private K-EQUAL-SYNTAX
  imports MAP-BYTES-TO-BYTES

  syntax MapBytesToBytes ::= MapBytesToBytes "{" key:Bytes "<-" value:Bytes "}"
      [function, total, klabel(MapBytesToBytes:curly_update), symbol]
  rule M:MapBytesToBytes{Key <- Value} => M (Key Bytes2Bytes|-> Value)
    requires notBool Key in_keys(M)
  rule (Key Bytes2Bytes|-> _ M:MapBytesToBytes){Key <- Value}
      => M (Key Bytes2Bytes|-> Value)
  rule (M:MapBytesToBytes{Key <- Value})(A Bytes2Bytes|-> B N:MapBytesToBytes)
      => (M (A Bytes2Bytes|-> B)) {Key <- Value} N
      requires notBool A ==K Key
      [simplification]

  rule M:MapBytesToBytes{Key1 <- Value1}[Key2 <- Value2]
      => ((M:MapBytesToBytes[Key2 <- Value2]{Key1 <- Value1}) #And #Not ({Key1 #Equals Key2}))
        #Or ((M:MapBytesToBytes[Key2 <- Value2]) #And {Key1 #Equals Key2})
      [simplification(20)]
  rule M:MapBytesToBytes[Key <- Value]
      => M:MapBytesToBytes{Key <- Value}
      [simplification(100)]
  rule M:MapBytesToBytes{Key1 <- _Value1}[Key2] orDefault Value2
      => M[Key2] orDefault Value2
      requires Key1 =/=K Key2
      [simplification]
  rule _M:MapBytesToBytes{Key <- Value1}[Key] orDefault _Value2
      => Value1
      [simplification]
  // rule M:MapBytesToBytes{Key1 <- Value1}[Key2] orDefault Value2
  //     => (M[Key2] orDefault Value2 #And #Not ({Key1 #Equals Key2}))
  //       #Or (Value1 #And {Key1 #Equals Key2})
  //     [simplification]
  rule M:MapBytesToBytes{Key1 <- Value1}[Key2]
      => (M[Key2] #And #Not ({Key1 #Equals Key2}))
        #Or (Value1 #And {Key1 #Equals Key2})
      [simplification]

  rule Key1 in_keys(_:MapBytesToBytes{Key1 <- _})
      => true
      [simplification(50)]
  rule Key1 in_keys(M:MapBytesToBytes{Key2 <- _})
      => Key1 in_keys(M)
      requires notBool Key1 ==K Key2
      [simplification(50)]
  rule K1 in_keys(M:MapBytesToBytes { K2 <- _ })
      => K1 ==K K2 orBool K1 in_keys(M)
    [simplification(100)]
      
endmodule
