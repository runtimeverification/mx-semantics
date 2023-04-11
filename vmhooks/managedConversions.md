# Managed Conversions

Go implementation: [mx-chain-vm-go/vmhost/vmhooks/managedConversions.go](https://github.com/multiversx/mx-chain-vm-go/blob/ea3d78d34c35f7ef9c1a9ea4fce8288608763229/vmhost/vmhooks/managedConversions.go)

```k
require "../elrond-config.md"
require "manBufOps.md"

module MANAGEDCONVERSIONS
    imports ELROND-CONFIG
    imports MANBUFOPS

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

    syntax List ::= #readESDTTransfers(Bytes)      [function]
 // ---------------------------------------------------------
    rule #readESDTTransfers(Bs) => .List            
      requires lengthBytes(Bs) <Int 16
    rule #readESDTTransfers(Bs) => ListItem(#readESDTTransfer(substrBytes(Bs, 0, 16)))
                                   #readESDTTransfers(substrBytes(Bs, 16, lengthBytes(Bs)))
      requires lengthBytes(Bs) >=Int 16

    syntax ESDTTransfer ::= #readESDTTransfer(Bytes)    [function]
 // --------------------------------------------------------------
    rule [[ #readESDTTransfer(Bs) => esdtTransfer( TokId, Value, Bytes2Int(substrBytes(Bs, 4, 12), BE, Unsigned)) ]]
        <bigIntHeap> 
          ...
          Bytes2Int(substrBytes(Bs, 12, 16), BE, Unsigned) |-> Value:Int 
          ...
        </bigIntHeap>
        <bufferHeap> 
          ... 
          Bytes2Int(substrBytes(Bs, 0, 4), BE, Unsigned) |-> TokId:Bytes
          ...
        </bufferHeap>
        requires lengthBytes(Bs) >=Int 16

    syntax List ::= #readManagedVecOfManagedBuffers(Bytes)                                 [function]
 // ----------------------------------------------------------------------------------------------------
    rule #readManagedVecOfManagedBuffers(VecBs) => .List   requires lengthBytes(VecBs) <Int 4
    rule [[ #readManagedVecOfManagedBuffers(VecBs) 
            => ListItem(Bs) #readManagedVecOfManagedBuffers(substrBytes(VecBs, 4, lengthBytes(VecBs)))
         ]]
        <bufferHeap> 
          ... 
          Bytes2Int(substrBytes(VecBs, 0, 4), BE, Unsigned) |-> Bs:Bytes
          ... 
        </bufferHeap>
        requires lengthBytes(VecBs) >=Int 4

endmodule
```