
# Utils

```k
module UTILS
    imports STRING
    imports INT
    imports LIST
    imports BYTES

    syntax Error ::= Err(String)
    syntax ListResult  ::= List | Error
    syntax BytesResult ::= Bytes | Error
    syntax IntResult   ::= Int | Error

    syntax ListResult ::= catListResult(ListResult, ListResult)    [function, total]
 // --------------------------------------------------------------------------------
    rule catListResult(ERR:Error, _)      => ERR
    rule catListResult(_:List, ERR:Error) => ERR
    rule catListResult(A:List, B:List)    => A B

    syntax ListResult ::= BytesResult2ListResult(BytesResult)       [function, total]
 // ---------------------------------------------------------------------------------
    rule BytesResult2ListResult(BS:Bytes) => ListItem(BS)
    rule BytesResult2ListResult(Err(E))   => Err(E)

    syntax ListResult ::= IntResult2ListResult(IntResult)           [function, total]
 // ---------------------------------------------------------------------------------
    rule IntResult2ListResult(BS:Int) => ListItem(BS)
    rule IntResult2ListResult(Err(E)) => Err(E)

endmodule
```