
# Utils

```k
requires "../data/bytes-type.k"
requires "../data/list-bytes.k"

module UTILS
    imports STRING
    imports INT
    imports LIST
    imports LIST-BYTES
    imports BYTES-TYPE
    imports UTILS-CEILS

    syntax Error ::= Err(String)
    syntax ListBytesResult  ::= ListBytes | Error
    syntax ListResult  ::= List | Error
    syntax BytesResult ::= Bytes | Error
    syntax IntResult   ::= Int | Error

    syntax ListResult ::= catListResult(ListResult, ListResult)    [function, total]
 // --------------------------------------------------------------------------------
    rule catListResult(ERR:Error, _)      => ERR
    rule catListResult(_:List, ERR:Error) => ERR
    rule catListResult(A:List, B:List)    => A B

    syntax ListBytesResult ::= catListBytesResult(ListBytesResult, ListBytesResult)    [function, total]
 // --------------------------------------------------------------------------------
    rule catListBytesResult(ERR:Error, _)             => ERR
    rule catListBytesResult(_:ListBytes, ERR:Error)   => ERR
    rule catListBytesResult(A:ListBytes, B:ListBytes) => A B

    syntax ListBytesResult ::= BytesResult2ListResult(BytesResult)       [function, total]
 // ---------------------------------------------------------------------------------
    rule BytesResult2ListResult(BS:Bytes) => ListItem(wrap(BS))
    rule BytesResult2ListResult(Err(E))   => Err(E)

    syntax ListResult ::= IntResult2ListResult(IntResult)           [function, total]
 // ---------------------------------------------------------------------------------
    rule IntResult2ListResult(BS:Int) => ListItem(BS)
    rule IntResult2ListResult(Err(E)) => Err(E)

endmodule

module UTILS-CEILS
    imports BOOL
    imports LIST-BYTES
    imports INT
    imports LIST
    imports WASM-DATA

    syntax Bool ::= definedListLookup(List, index: Int) [function, total]
 // ---------------------------------------------------------------------------------
    rule definedListLookup (L:List, Idx:Int)
        => (Idx >=Int 0 -Int size(L)) andBool (Idx <Int size(L))
    rule #Ceil(@Arg0:List[@Index:Int])
        =>  ( ( {true #Equals definedListLookup(@Arg0, @Index)} // TODO: This is wrong, use #Ceil(true #And definedListLookup(@Arg0, @Index))
              #And #Ceil(@Arg0)
              )
            #And #Ceil(@Index)
            )
        [simplification]

    syntax KItem ::= List "{{" Int "}}"
        [function, total, klabel(listLookupTotal), symbol, no-evaluators]
 // ---------------------------------------------------------------------------------
    rule L:List{{Index:Int}}
        => L[Index]
        requires definedListLookup(L, Index)
        [concrete, simplification]
    rule L:List{{Index:Int}} => 0
        requires notBool definedListLookup(L, Index)
        [simplification]

    rule L:List[Index:Int]
        => L{{Index}}
        requires definedListLookup(L, Index)
        [symbolic(L), simplification]

    rule L:List[Index:Int]
        => L{{Index}}
        requires definedListLookup(L, Index)
        [symbolic(Index), simplification]


    syntax Bool ::= definedBytesListLookup(ListBytes, index: Int) [function, total]
 // ---------------------------------------------------------------------------------
    rule definedBytesListLookup (L:ListBytes, Idx:Int)
        => (Idx >=Int 0 -Int size(L)) andBool (Idx <Int size(L))
    rule #Ceil(@Arg0:ListBytes[@Index:Int])
        =>  ( ( {true #Equals definedBytesListLookup(@Arg0, @Index)} // TODO: This is wrong, use #Ceil(true #And definedBytesListLookup(@Arg0, @Index))
              #And #Ceil(@Arg0)
              )
            #And #Ceil(@Index)
            )
        [simplification]

endmodule
```
