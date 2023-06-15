
require "int-type.k"
require "bytes-type.k"

module MAP-INT-TO-BYTES
  imports private BOOL-SYNTAX
  imports private INT-SYNTAX
  // imports private LIST-INT
  // imports private LIST-BYTES
  imports private LIST
  // imports private SET-INT
  imports private SET
  imports INT-TYPE
  imports BYTES-TYPE

  syntax Int
  syntax Bytes

  syntax MapIntToBytes [hook(MAP.Map)]
  syntax MapIntToBytes ::= MapIntToBytes MapIntToBytes
         [ left, function, hook(MAP.concat), klabel(_MapIntToBytes_),
           symbol, assoc, comm, unit(.MapIntToBytes), element(_Int2Bytes|->_),
           index(0), format(%1%n%2)
         ]
  syntax MapIntToBytes ::= ".MapIntToBytes"
         [ function, total, hook(MAP.unit),
           klabel(.MapIntToBytes), symbol, latex(\dotCt{MapIntToBytes})
         ]
  syntax MapIntToBytes ::= WrappedInt "Int2Bytes|->" WrappedBytes
         [ function, total, hook(MAP.element),
           klabel(_Int2Bytes|->_), symbol,
           latex({#1}\mapsto{#2}), injective
         ]

  syntax priorities _Int2Bytes|->_ > _MapIntToBytes_ .MapIntToBytes
  syntax non-assoc _Int2Bytes|->_
  syntax WrappedBytes ::= MapIntToBytes "[" WrappedInt "]"
                 [function, hook(MAP.lookup), klabel(MapIntToBytes:lookup), symbol]
  syntax WrappedBytes ::= MapIntToBytes "[" WrappedInt "]" "orDefault" WrappedBytes
                 [ function, total, hook(MAP.lookupOrDefault),
                   klabel(MapIntToBytes:lookupOrDefault)
                 ]
  syntax MapIntToBytes ::= MapIntToBytes "[" key: WrappedInt "<-" value: WrappedBytes "]"
                 [ function, total, klabel(MapIntToBytes:update), symbol,
                   hook(MAP.update), prefer
                 ]
  syntax MapIntToBytes ::= MapIntToBytes "[" WrappedInt "<-" "undef" "]"
                 [ function, total, hook(MAP.remove),
                   klabel(_MapIntToBytes[_<-undef]), symbol
                 ]
  syntax MapIntToBytes ::= MapIntToBytes "-Map" MapIntToBytes
                 [ function, total, hook(MAP.difference),
                   latex({#1}-_{\it MapIntToBytesMap}{#2})
                 ]
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

  syntax List ::= "keys_list" "(" MapIntToBytes ")"
                 [function, hook(MAP.keys_list)]
  // syntax ListInt ::= "keys_list" "(" MapIntToBytes ")"
  //                [function, hook(MAP.keys_list)]

  syntax Bool ::= WrappedInt "in_keys" "(" MapIntToBytes ")"
                 [function, total, hook(MAP.in_keys)]

  syntax List ::= values(MapIntToBytes)
                 [function, hook(MAP.values)]
  // syntax ListBytes ::= values(MapIntToBytes)
  //                [function, hook(MAP.values)]

  syntax Int ::= size(MapIntToBytes)
                 [function, total, hook(MAP.size), klabel(MapIntToBytes.sizeMap)]
  syntax Bool ::= MapIntToBytes "<=Map" MapIntToBytes
                 [function, total, hook(MAP.inclusion)]
  syntax WrappedInt ::= choice(MapIntToBytes)
                 [function, hook(MAP.choice), klabel(MapIntToBytes:choice)]
endmodule

module MAP-INT-TO-BYTES-PRIMITIVE
  imports public  BOOL
  imports private K-EQUAL
  imports public  MAP-INT-TO-BYTES
  imports private MAP-INT-TO-BYTES-KORE-SYMBOLIC

  syntax Bytes ::= MapIntToBytes "{{" Int "}}"
                 [function, klabel(MapIntToBytes:primitiveLookup)]
  syntax Bytes ::= MapIntToBytes "{{" Int "}}" "orDefault" Bytes
                 [ function, total, klabel(MapIntToBytes:primitiveLookupOrDefault) ]
  syntax MapIntToBytes ::= MapIntToBytes "{{" key: Int "<-" value: Bytes "}}"
                 [ function, total, klabel(MapIntToBytes:primitiveUpdate), symbol,
                   prefer
                 ]
  syntax MapIntToBytes ::= MapIntToBytes "{{" Int "<-" "undef" "}}"
                 [ function, total, klabel(MapIntToBytes:primitiveRemove), symbol ]
  syntax Bool ::= Int "in_keys" "{{" MapIntToBytes "}}"
                 [function, total, klabel(MapIntToBytes:primitiveInKeys)]

  // Definitions
  // -----------

  rule (wrap(Key) Int2Bytes|-> V:WrappedBytes M:MapIntToBytes)
          {{ Key:Int }}
      => unwrap(V)
      ensures notBool Key in_keys {{ M }}

  rule (wrap(Key) Int2Bytes|-> V:WrappedBytes M:MapIntToBytes)
          {{ Key:Int }} orDefault _:Bytes
      => unwrap(V)
      ensures notBool Key in_keys {{ M }}
  rule M:MapIntToBytes {{ Key:Int }} orDefault V:Bytes
      => V
      requires notBool Key in_keys {{ M }}

  rule (wrap(Key) Int2Bytes|-> _:WrappedBytes M:MapIntToBytes)
          {{ Key:Int <- Value:Bytes }}
      => (wrap(Key) Int2Bytes|-> wrap(Value)) M
  rule M:MapIntToBytes {{ Key:Int <- Value:Bytes }}
      => (wrap(Key) Int2Bytes|-> wrap(Value)) M
      requires notBool Key in_keys {{ M }}

  rule (wrap(Key) Int2Bytes|-> _:WrappedBytes M:MapIntToBytes)
          {{ Key:Int <- undef }}
      => M
      ensures notBool Key in_keys {{ M }}
  rule M:MapIntToBytes {{ Key:Int <- undef }}
      => M
      requires notBool Key in_keys {{ M }}

  rule Key:Int in_keys
          {{wrap(Key) Int2Bytes|-> _:WrappedBytes M:MapIntToBytes}}
      => true
      ensures notBool Key in_keys {{ M }}
  rule _Key:Int in_keys {{ .MapIntToBytes }}
      => false
  rule Key:Int in_keys
          {{Key2:WrappedInt Int2Bytes|-> _:WrappedBytes M:MapIntToBytes}}
      => true
      requires Key =/=K unwrap(Key2)
      ensures notBool Key2 in_keys (M)
      [simplification]

  // Translation rules
  rule M:MapIntToBytes[Key:WrappedInt]
      => wrap(M{{unwrap(Key)}})
      [simplification, symbolic(M)]
  rule M:MapIntToBytes[Key:WrappedInt]
      => wrap(M{{unwrap(Key)}})
      [simplification, symbolic(Key)]
  rule M:MapIntToBytes{{Key}}
      => unwrap(M[wrap(Key)])
      [simplification, concrete]

  rule M:MapIntToBytes [ Key:WrappedInt ] orDefault Value:WrappedBytes
      => wrap(M {{ unwrap(Key) }} orDefault unwrap(Value))
      [simplification, symbolic(M)]
  rule M:MapIntToBytes [ Key:WrappedInt ] orDefault Value:WrappedBytes
      => wrap(M {{ unwrap(Key) }} orDefault unwrap(Value))
      [simplification, symbolic(Key)]
  rule M:MapIntToBytes [ Key:WrappedInt ] orDefault Value:WrappedBytes
      => wrap(M {{ unwrap(Key) }} orDefault unwrap(Value))
      [simplification, symbolic(Value)]
  rule M:MapIntToBytes{{Key}} orDefault Value
      => unwrap(M[wrap(Key)] orDefault wrap(Value))
      [simplification, concrete]

  rule M:MapIntToBytes[Key:WrappedInt <- Value:WrappedBytes]
      => M {{ unwrap(Key) <- unwrap(Value) }}
      [simplification, symbolic(M)]
  rule M:MapIntToBytes[Key:WrappedInt <- Value:WrappedBytes]
      => M {{ unwrap(Key) <- unwrap(Value) }}
      [simplification, symbolic(Key)]
  rule M:MapIntToBytes[Key:WrappedInt <- Value:WrappedBytes]
      => M {{ unwrap(Key) <- unwrap(Value) }}
      [simplification, symbolic(Value)]
  rule M:MapIntToBytes{{Key <- Value}} => M[wrap(Key) <- wrap(Value) ]
      [simplification, concrete]

  rule M:MapIntToBytes[Key:WrappedInt <- undef]
      => M {{ unwrap(Key) <- undef }}
      [simplification, symbolic(M)]
  rule M:MapIntToBytes[Key:WrappedInt <- undef]
      => M {{ unwrap(Key) <- undef }}
      [simplification, symbolic(Key)]
  rule M:MapIntToBytes{{Key <- undef}} => M[wrap(Key) <- undef]
      [simplification, concrete]

  rule Key:WrappedInt in_keys (M:MapIntToBytes)
      => unwrap(Key) in_keys {{M}}
      [simplification, symbolic(M)]
  rule Key:WrappedInt in_keys (M:MapIntToBytes)
      => unwrap(Key) in_keys {{M}}
      [simplification, symbolic(Key)]
  rule Key in_keys {{M:MapIntToBytes}} => wrap(Key) in_keys(M)
      [simplification, concrete]

  // Symbolic execution rules
  // ------------------------
  syntax Bool ::= definedPrimitiveLookup(MapIntToBytes, Int)  [function, total]
  rule definedPrimitiveLookup(M:MapIntToBytes, K:Int) => K in_keys{{M}}

  rule #Ceil(@M:MapIntToBytes {{@K:Int}})
      => {definedPrimitiveLookup(@M, @K) #Equals true}
          #And #Ceil(@M) #And #Ceil(@K)
      [simplification]

  rule M:MapIntToBytes {{ K <- _ }} {{ K <- V }} => M {{ K <- V }} [simplification]
  rule (K1 Int2Bytes|-> V1 M:MapIntToBytes) {{ K2 <- V2 }}
      => (K1 Int2Bytes|-> V1 (M {{ K2 <- V2 }}))
      requires unwrap(K1) =/=K K2
      [simplification]

  rule (K1 Int2Bytes|-> V1 M:MapIntToBytes) {{ K2 <- undef }}
      => (K1 Int2Bytes|-> V1 (M {{ K2 <- undef }}))
      requires unwrap(K1) =/=K K2
      [simplification]

  rule (K1 Int2Bytes|-> _V M:MapIntToBytes) {{ K2 }} => M {{K2}}
      requires unwrap(K1) =/=K K2
      ensures notBool (K1 in_keys(M))
      [simplification]
  rule (_MAP:MapIntToBytes {{ K  <-  V1 }}) {{ K }}  => V1 [simplification]
  rule ( MAP:MapIntToBytes {{ K1 <- _V1 }}) {{ K2 }} => MAP {{ K2 }}
      requires K1 =/=K K2
      [simplification]

  rule (K1 Int2Bytes|-> _V M:MapIntToBytes) {{ K2 }} orDefault D
      => M {{K2}} orDefault D
      requires unwrap(K1) =/=K K2
      ensures notBool (K1 in_keys(M))
      [simplification]
  rule (_MAP:MapIntToBytes {{ K  <-  V1 }}) {{ K }} orDefault _ => V1 [simplification]
  rule ( MAP:MapIntToBytes {{ K1 <- _V1 }}) {{ K2 }} orDefault D
      => MAP {{ K2 }} orDefault D
      requires K1 =/=K K2
      [simplification]

  rule K in_keys{{_M:MapIntToBytes {{ K <- undef }} }} => false [simplification]
  rule K in_keys{{_M:MapIntToBytes {{ K <- _ }} }} => true [simplification]
  rule K1 in_keys{{ M:MapIntToBytes {{ K2 <- _ }} }}
      => true requires K1 ==K K2 orBool K1 in_keys{{M}}
      [simplification]
  rule K1 in_keys{{ M:MapIntToBytes {{ K2 <- _ }} }}
      => K1 in_keys {{ M }}
      requires K1 =/=K K2
      [simplification]

  rule K1 in_keys {{ (K2 Int2Bytes|-> V) M:MapIntToBytes }}
      => K1 ==K unwrap(K2) orBool K1 in_keys {{ M }}
    requires definedMapElementConcat(K2, V, M)
    [simplification(100)]
      

  rule {false #Equals @Key in_keys{{ Key' Int2Bytes|-> Val @M:MapIntToBytes }}}
      =>  #Ceil(@Key) #And #Ceil(Key' Int2Bytes|-> Val @M)
          #And #Not({ @Key #Equals unwrap(Key') })
          #And {false #Equals @Key in_keys{{@M}}}
      [simplification]
  rule {@Key in_keys{{Key' Int2Bytes|-> Val @M:MapIntToBytes}} #Equals false}
      =>  #Ceil(@Key) #And #Ceil(Key' Int2Bytes|-> Val @M)
          #And #Not({@Key #Equals unwrap(Key') })
          #And {@Key in_keys{{@M}} #Equals false}
      [simplification]

endmodule

module MAP-INT-TO-BYTES-KORE-SYMBOLIC
  imports MAP-INT-TO-BYTES
  imports private K-EQUAL
  imports private BOOL

  syntax Bool ::= definedMapElementConcat(WrappedInt, WrappedBytes, MapIntToBytes)  [function, total]
  rule definedMapElementConcat(K, _V, M:MapIntToBytes) => notBool K in_keys(M)

  rule #Ceil(@M:MapIntToBytes [@K:WrappedInt])
      => {(@K in_keys(@M)) #Equals true}
          #And #Ceil(@M) #And #Ceil(@K)
      [simplification]

  rule (K Int2Bytes|-> _ M:MapIntToBytes) [ K <- V ] => (K Int2Bytes|-> V M) [simplification]
  rule M:MapIntToBytes [ K <- V ] => (K Int2Bytes|-> V M) requires notBool (K in_keys(M))
      [simplification]
  rule M:MapIntToBytes [ K <- _ ] [ K <- V ] => M [ K <- V ] [simplification]
  rule (K1 Int2Bytes|-> V1 M:MapIntToBytes) [ K2 <- V2 ] => (K1 Int2Bytes|-> V1 (M [ K2 <- V2 ]))
      requires K1 =/=K K2
      [simplification]

  rule (K Int2Bytes|-> _ M:MapIntToBytes) [ K <- undef ] => M
      ensures notBool (K in_keys(M))
      [simplification]
  rule M:MapIntToBytes [ K <- undef ] => M
      requires notBool (K in_keys(M))
      [simplification]
  rule (K1 Int2Bytes|-> V1 M:MapIntToBytes) [ K2 <- undef ]
      => (K1 Int2Bytes|-> V1 (M [ K2 <- undef ]))
      requires K1 =/=K K2
      [simplification]

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
    requires definedMapElementConcat(K, V, M)
    [simplification(50)]
  rule K1 in_keys((K2 Int2Bytes|-> V) M:MapIntToBytes)
      => K1 in_keys(M)
    requires true
        andBool definedMapElementConcat(K2, V, M)
        andBool K1 =/=K K2
    [simplification(50)]
  rule K1 in_keys((K2 Int2Bytes|-> V) M:MapIntToBytes)
      => K1 ==K K2 orBool K1 in_keys(M)
    requires definedMapElementConcat(K2, V, M)
    [simplification(100)]
      

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

module MAP-INT-TO-BYTES-CURLY-BRACE
  imports private BOOL
  imports private K-EQUAL-SYNTAX
  imports MAP-INT-TO-BYTES

  syntax MapIntToBytes ::= MapIntToBytes "{" key:WrappedInt "<-" value:WrappedBytes "}"
      [function, total, klabel(MapIntToBytes:curly_update), symbol]
  rule M:MapIntToBytes{Key <- Value} => M (Key Int2Bytes|-> Value)
    requires notBool Key in_keys(M)
  rule (Key Int2Bytes|-> _ M:MapIntToBytes){Key <- Value}
      => M (Key Int2Bytes|-> Value)
  rule (M:MapIntToBytes{Key <- Value})(A Int2Bytes|-> B N:MapIntToBytes)
      => (M (A Int2Bytes|-> B)) {Key <- Value} N
      requires notBool A ==K Key
      [simplification]

  rule M:MapIntToBytes{Key1 <- Value1}[Key2 <- Value2]
      => ((M:MapIntToBytes[Key2 <- Value2]{Key1 <- Value1}) #And #Not ({Key1 #Equals Key2}))
        #Or ((M:MapIntToBytes[Key2 <- Value2]) #And {Key1 #Equals Key2})
      [simplification(20)]
  rule M:MapIntToBytes[Key <- Value]
      => M:MapIntToBytes{Key <- Value}
      [simplification(100)]
  rule M:MapIntToBytes{Key1 <- _Value1}[Key2] orDefault Value2
      => M[Key2] orDefault Value2
      requires Key1 =/=K Key2
      [simplification]
  rule _M:MapIntToBytes{Key <- Value1}[Key] orDefault _Value2
      => Value1
      [simplification]
  // rule M:MapIntToBytes{Key1 <- Value1}[Key2] orDefault Value2
  //     => (M[Key2] orDefault Value2 #And #Not ({Key1 #Equals Key2}))
  //       #Or (Value1 #And {Key1 #Equals Key2})
  //     [simplification]
  rule M:MapIntToBytes{Key1 <- Value1}[Key2]
      => (M[Key2] #And #Not ({Key1 #Equals Key2}))
        #Or (Value1 #And {Key1 #Equals Key2})
      [simplification]

  rule Key1 in_keys(_:MapIntToBytes{Key1 <- _})
      => true
      [simplification(50)]
  rule Key1 in_keys(M:MapIntToBytes{Key2 <- _})
      => Key1 in_keys(M)
      requires notBool Key1 ==K Key2
      [simplification(50)]
  rule K1 in_keys(M:MapIntToBytes { K2 <- _ })
      => K1 ==K K2 orBool K1 in_keys(M)
    [simplification(100)]
      
endmodule
