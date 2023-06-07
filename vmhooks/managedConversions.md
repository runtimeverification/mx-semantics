# Managed Conversions

Go implementation: [mx-chain-vm-go/vmhost/vmhooks/managedConversions.go](https://github.com/multiversx/mx-chain-vm-go/blob/ea3d78d34c35f7ef9c1a9ea4fce8288608763229/vmhost/vmhooks/managedConversions.go)

```k
require "../elrond-config.md"
require "manBufOps.md"
require "utils.md"


module MANAGEDCONVERSIONS
    imports ELROND-CONFIG
    imports MANBUFOPS
    imports UTILS

    syntax InternalInstr ::= #writeEsdtsToBytes(List)
                           | #writeEsdtToBytes(ESDTTransfer)
 // ---------------------------------------------------------------------
    rule <instrs> #writeEsdtsToBytes(.List) => . ... </instrs>

    rule <instrs> #writeEsdtsToBytes(Ts ListItem(T))
               => #writeEsdtToBytes(T)
               ~> #writeEsdtsToBytes(Ts)
                  ... 
        </instrs>
    
    rule <instrs> #writeEsdtToBytes(esdtTransfer(TokId, Value, Nonce))
               => #setBuffer(      #newKey(BUF_HEAP) , TokId )
               ~> #setBigIntValue( #newKey(INT_HEAP) , Value )
               ~> #pushBytes(
                    Int2Bytes(4, #newKey(BUF_HEAP), BE) +Bytes
                    Int2Bytes(8, Nonce,             BE) +Bytes
                    Int2Bytes(4, #newKey(INT_HEAP), BE)
                  )
               ~> #appendBytes
                  ...
        </instrs>
        <bufferHeap> BUF_HEAP </bufferHeap>
        <bigIntHeap> INT_HEAP </bigIntHeap>

    syntax ListResult ::= readESDTTransfers(Int)           [function, total]
                        | readESDTTransfersR(BytesResult)  [function, total]
                        | readESDTTransfersH(Bytes)        [function, total]
 // ----------------------------------------------------------------------
    rule readESDTTransfers(IDX)       => readESDTTransfersR(getBuffer(IDX))
    rule readESDTTransfersR(BS:Bytes) => readESDTTransfersH(BS)
    rule readESDTTransfersR(E:Error)  => E
    
    rule readESDTTransfersH(Bs) => .List    
      requires lengthBytes(Bs) ==Int 0        
    rule readESDTTransfersH(Bs) => Err("invalid managed vector of ESDT transfers")
      requires lengthBytes(Bs) <Int 16
       andBool lengthBytes(Bs) >Int 0 
    rule readESDTTransfersH(Bs) 
      => catListResult( readESDTTransfer(substrBytes(Bs, 0, 16))
                      , readESDTTransfersH(substrBytes(Bs, 16, lengthBytes(Bs)))
                      )
      requires lengthBytes(Bs) >=Int 16

    syntax ListResult ::= readESDTTransfer(Bytes)          [function, total]
 // ----------------------------------------------------------------------------------
    rule readESDTTransfer(Bs) 
        => mkEsdtTransferFromResults(
              getBuffer( Bytes2Int(substrBytes(Bs, 0, 4), BE, Unsigned) ),
              getBigInt( Bytes2Int(substrBytes(Bs, 12, 16), BE, Unsigned) ),
              Bytes2Int(substrBytes(Bs, 4, 12), BE, Unsigned)
           )
      requires lengthBytes(Bs) ==Int 16

    rule readESDTTransfer(Bs) => Err("invalid ESDT transfer object encoding")
      requires lengthBytes(Bs) =/=Int 16

    syntax ListResult ::= mkEsdtTransferFromResults(BytesResult, IntResult, IntResult)   [function, total]
 // -------------------------------------------------------------------------------------------
    rule mkEsdtTransferFromResults(TokId,   Value,  Nonce)  => ListItem(esdtTransfer(TokId, Value, Nonce))
    rule mkEsdtTransferFromResults(Err(E),  _,      _)      => Err(E)
    rule mkEsdtTransferFromResults(_:Bytes, Err(E), _)      => Err(E)
    rule mkEsdtTransferFromResults(_:Bytes, _:Int,  Err(E)) => Err(E)
    
    syntax ListResult ::= readManagedVecOfManagedBuffers(Int)                     [function, total]
 // ----------------------------------------------------------------------------------------------------
    rule [[ readManagedVecOfManagedBuffers(BUFFER_IDX) => chunks2buffers(VecBs) ]]
      <bufferHeap> ... BUFFER_IDX |-> VecBs:Bytes ... </bufferHeap>
    rule readManagedVecOfManagedBuffers(_) => Err("no managed buffer under the given handle")
      [owise]

    // split bytes into chunks of 4 and use each chunk as a buffer id
    syntax ListResult ::= chunks2buffers(Bytes)                         [function, total]
 // ------------------------------------------------------------------------------------------
    rule chunks2buffers(VecBs) => .List
      requires lengthBytes(VecBs) ==Int 0

    rule chunks2buffers(VecBs) => Err("invalid managed vector of managed buffer handles")
      requires lengthBytes(VecBs) =/=Int 0
       andBool lengthBytes(VecBs) <Int 4

    rule chunks2buffers(VecBs)  
      => catListResult( BytesResult2ListResult(
                          getBuffer(Bytes2Int(substrBytes(VecBs, 0, 4), BE, Unsigned))
                        )
                      , chunks2buffers(substrBytes(VecBs, 4, lengthBytes(VecBs)))
                      ) 
      requires lengthBytes(VecBs) >=Int 4

endmodule
```