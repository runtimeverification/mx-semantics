Managed Buffers
===============

Go implementation: [mx-chain-vm-go/vmhost/vmhooks/manBufOps.go](https://github.com/multiversx/mx-chain-vm-go/blob/ea3d78d34c35f7ef9c1a9ea4fce8288608763229/vmhost/vmhooks/manBufOps.go)

```k
require "../elrond-config.md"
require "bigIntOps.md"

module MANBUFOPS
     imports ELROND-CONFIG
     imports BIGINT-HELPERS
```

## Managed Buffer Internal Instructions

```k
    syntax InternalInstr ::= #getBuffer ( idx : Int )
 // ---------------------------------------------------------------
    rule <instrs> #getBuffer(BUFFER_IDX) => . ... </instrs>
         <bytesStack> STACK => {HEAP[BUFFER_IDX]}:>Bytes : STACK </bytesStack>
         <bufferHeap> HEAP </bufferHeap>
      requires BUFFER_IDX in_keys(HEAP)
       andBool isBytes(HEAP[BUFFER_IDX])

    syntax InternalInstr ::= #setBufferFromBytesStack ( idx: Int )
                           | #setBuffer ( idx: Int , value: Bytes )
 // ----------------------------------------------------------------------------
    rule <instrs> #setBufferFromBytesStack(BUFFER_IDX) => #setBuffer(BUFFER_IDX, BS) ... </instrs>
         <bytesStack> BS : _ </bytesStack>

    rule <instrs> #setBuffer(BUFFER_IDX, BS) => . ... </instrs>
         <bufferHeap> HEAP => HEAP [ BUFFER_IDX <- BS ] </bufferHeap>

    syntax InternalInstr ::= #appendBytesToBuffer( Int )
                           | "#appendBytes"
 // -----------------------------------------------------------------
    rule <instrs> #appendBytesToBuffer( DEST_IDX )
               => #getBuffer(DEST_IDX)
               ~> #appendBytes
               ~> #setBufferFromBytesStack( DEST_IDX )
                  ... 
         </instrs>

    rule <instrs> #appendBytes => . ... </instrs>
         <bytesStack> BS1 : BS2 : BSS => (BS1 +Bytes BS2) : BSS </bytesStack>

    syntax InternalInstr ::= #sliceBytes( Int , Int )
 // ------------------------------------------------------------------
    rule <instrs> #sliceBytes(OFFSET, LENGTH) => . ... </instrs>
         <bytesStack> (BS => substrBytes(BS, OFFSET, OFFSET +Int LENGTH)) : _ </bytesStack>
         requires #sliceBytesInBounds( BS , OFFSET , LENGTH )

    syntax Bool ::= #sliceBytesInBounds( Bytes , Int , Int )      [function, total]
    rule #sliceBytesInBounds( BS , OFFSET , LENGTH ) 
            => OFFSET >=Int 0 andBool 
               LENGTH >=Int 0 andBool 
               OFFSET +Int LENGTH <=Int lengthBytes(BS)
```

## Managed Buffer host functions

```k
 // extern int32_t   mBufferSetBytes(void* context, int32_t mBufferHandle, int32_t dataOffset, int32_t dataLength);
    rule <instrs> hostCall("env", "mBufferSetBytes", [ i32 i32 i32 .ValTypes ] -> [ i32 .ValTypes ] ) 
               => #memLoad(OFFSET, LENGTH) 
               ~> #setBufferFromBytesStack ( ARG_IDX ) 
               ~> #dropBytes
               ~> i32 . const 0
                  ... 
         </instrs>
         <locals> 0 |-> <i32> ARG_IDX  1 |-> <i32> OFFSET  2 |-> <i32> LENGTH </locals>

 // extern int32_t   mBufferFromBigIntUnsigned(void* context, int32_t mBufferHandle, int32_t bigIntHandle);
    rule <instrs> hostCall("env", "mBufferFromBigIntUnsigned", [ i32 i32 .ValTypes ] -> [ i32 .ValTypes ] ) 
               => #getBigInt(BIG_IDX, Unsigned) 
               ~> #setBufferFromBytesStack ( BUFF_IDX ) 
               ~> #dropBytes
               ~> i32 . const 0
                  ... 
         </instrs>
         <locals> 0 |-> <i32> BUFF_IDX  1 |-> <i32> BIG_IDX </locals>

 // extern int32_t   mBufferStorageStore(void* context, int32_t keyHandle, int32_t sourceHandle);
    rule <instrs> hostCall("env", "mBufferStorageStore", [ i32 i32 .ValTypes ] -> [ i32 .ValTypes ] ) 
               => #getBuffer(KEY_IDX) 
               ~> #getBuffer(VAL_IDX) 
               ~> #storageStore
               ~> i32 . const 0
                  ... 
         </instrs>
         <locals> 0 |-> <i32> KEY_IDX  1 |-> <i32> VAL_IDX </locals>

 // extern int32_t   mBufferStorageLoad(void* context, int32_t keyHandle, int32_t destinationHandle);
    rule <instrs> hostCall("env", "mBufferStorageLoad", [ i32 i32 .ValTypes ] -> [ i32 .ValTypes ] ) 
               => #getBuffer(KEY_IDX)
               ~> #storageLoad
               ~> #setBufferFromBytesStack(DEST_IDX)
               ~> #dropBytes
               ~> i32 . const 0
                  ... 
         </instrs>
         <locals> 0 |-> <i32> KEY_IDX  1 |-> <i32> DEST_IDX </locals>

 // extern int32_t   mBufferToBigIntUnsigned(void* context, int32_t mBufferHandle, int32_t bigIntHandle);
    rule <instrs> hostCall("env", "mBufferToBigIntUnsigned", [ i32 i32 .ValTypes ] -> [ i32 .ValTypes ] ) 
               => #getBuffer(KEY_IDX)
               ~> #setBigIntFromBytesStack(DEST_IDX, Unsigned)
               ~> #dropBytes
               ~> i32 . const 0
                  ... 
         </instrs>
         <locals> 0 |-> <i32> KEY_IDX  1 |-> <i32> DEST_IDX </locals>

 // extern int32_t   mBufferGetArgument(void* context, int32_t id, int32_t destinationHandle);
    rule <instrs> hostCall("env", "mBufferGetArgument", [ i32 i32 .ValTypes ] -> [ i32 .ValTypes ] ) 
               => #setBuffer(DEST_IDX, {ARGS[ARG_IDX]}:>Bytes)
               ~> i32 . const 0
                  ... 
         </instrs>
         <locals> 0 |-> <i32> ARG_IDX  1 |-> <i32> DEST_IDX </locals>
         <callArgs> ARGS </callArgs>
      requires ARG_IDX <Int size(ARGS)
       andBool isBytes(ARGS[ARG_IDX])

 // extern int32_t   mBufferAppend(void* context, int32_t accumulatorHandle, int32_t dataHandle);
    rule <instrs> hostCall("env", "mBufferAppend", [ i32 i32 .ValTypes ] -> [ i32 .ValTypes ] ) 
               => #getBuffer(DATA_IDX)
               ~> #appendBytesToBuffer( ACC_IDX )
               ~> #dropBytes
               ~> i32 . const 0
                  ...
         </instrs>
         <locals> 0 |-> <i32> ACC_IDX  1 |-> <i32> DATA_IDX </locals>


 // extern int32_t   mBufferEq(void* context, int32_t mBufferHandle1, int32_t mBufferHandle2);
    rule <instrs> hostCall ( "env" , "mBufferEq" , [ i32  i32  .ValTypes ] -> [ i32  .ValTypes ] ) 
               => #getBuffer(BUFF1_IDX)
               ~> #getBuffer(BUFF2_IDX)
               ~> #bytesEqual
               ~> #dropBytes
               ~> #dropBytes
                  ...
         </instrs>
         <locals> 0 |-> <i32> BUFF1_IDX  1 |-> <i32> BUFF2_IDX </locals>



 // extern int32_t   mBufferAppendBytes(void* context, int32_t accumulatorHandle, int32_t dataOffset, int32_t dataLength);
    rule <instrs> hostCall("env", "mBufferAppendBytes", [ i32 i32 i32 .ValTypes ] -> [ i32 .ValTypes ] ) 
               => #memLoad( OFFSET , LENGTH )
               ~> #appendBytesToBuffer( BUFF_IDX )
               ~> #dropBytes
               ~> i32 . const 0
                  ... 
         </instrs>
         <locals> 0 |-> <i32> BUFF_IDX  1 |-> <i32> OFFSET  2 |-> <i32> LENGTH </locals>

 // extern int32_t   mBufferGetLength(void* context, int32_t mBufferHandle);
    rule <instrs> hostCall("env", "mBufferGetLength", [ i32 .ValTypes ] -> [ i32 .ValTypes ] ) 
               => #getBuffer( BUFF_IDX )
               ~> #returnLength
               ~> #dropBytes
                  ... 
         </instrs>
         <locals> 0 |-> <i32> BUFF_IDX </locals>

 // extern int32_t   mBufferGetByteSlice(void* context, int32_t sourceHandle, int32_t startingPosition, int32_t sliceLength, int32_t resultOffset);
    rule <instrs> hostCall("env", "mBufferGetByteSlice", [ i32 i32 i32 i32 .ValTypes ] -> [ i32 .ValTypes ] ) 
               => #getBuffer( SRC_BUFF_IDX )
               ~> #mBufferGetByteSliceH( OFFSET , LENGTH , DEST_OFFSET )
               ~> #dropBytes
                  ... 
         </instrs>
         <locals> 0 |-> <i32> SRC_BUFF_IDX  1 |-> <i32> OFFSET  2 |-> <i32> LENGTH  3 |-> <i32> DEST_OFFSET </locals>


    syntax InternalInstr ::= #mBufferGetByteSliceH( Int , Int , Int )
 // ----------------------------------------------------------------
    rule <instrs> #mBufferGetByteSliceH( OFFSET , LENGTH , DEST_OFFSET )
               => #sliceBytes( OFFSET , LENGTH )
               ~> #memStoreFromBytesStack( DEST_OFFSET )
               ~> i32 . const 0
                  ...
         </instrs>
         <bytesStack> BS : _ </bytesStack>
         requires #sliceBytesInBounds( BS , OFFSET , LENGTH )

    rule <instrs> #mBufferGetByteSliceH( OFFSET , LENGTH , _DEST_OFFSET )
               => i32 . const 1
                  ...
         </instrs> 
         <bytesStack> BS : _ </bytesStack>
         requires notBool( #sliceBytesInBounds( BS , OFFSET , LENGTH ) )

 // extern int32_t   mBufferNew(void* context);
    rule <instrs> hostCall("env", "mBufferNew", [ .ValTypes ] -> [ i32 .ValTypes ] ) => i32.const size(HEAP) ... </instrs>
         <bufferHeap> HEAP => HEAP[size(HEAP) <- .Bytes] </bufferHeap>

 // extern int32_t   mBufferNewFromBytes(void* context, int32_t dataOffset, int32_t dataLength);
    rule <instrs> hostCall ( "env" , "mBufferNewFromBytes" , [ i32  i32  .ValTypes ] -> [ i32  .ValTypes ] )
              => #memLoad( OFFSET , LENGTH )
              ~> #setBufferFromBytesStack( size(HEAP) )
              ~> #dropBytes
              ~> i32 . const size(HEAP)
                 ... 
         </instrs>
         <locals> 0 |-> <i32> OFFSET  1 |-> <i32> LENGTH </locals>
         <bufferHeap> HEAP => HEAP[size(HEAP) <- .Bytes] </bufferHeap>

 // extern void      managedCaller(void* context, int32_t destinationHandle);
    rule <instrs> hostCall("env", "managedCaller", [ i32 .ValTypes ] -> [ .ValTypes ] )
               => #setBuffer( DEST_IDX , CALLER )
                 ... 
         </instrs>
         <locals> 0 |-> <i32> DEST_IDX </locals>
         <caller> CALLER </caller>

 // extern void      mBufferStorageLoadFromAddress(void* context, int32_t addressHandle, int32_t keyHandle, int32_t destinationHandle);
    rule <instrs> hostCall("env", "mBufferStorageLoadFromAddress", [ i32 i32 i32 .ValTypes ] -> [ .ValTypes ] )
               => #getBuffer( KEY_IDX )
               ~> #getBuffer( ADDR_IDX )
               ~> #storageLoadFromAddress
               ~> #setBufferFromBytesStack( DEST_IDX )
               ~> #dropBytes
                  ... 
         </instrs>
         <locals> 0 |-> <i32> ADDR_IDX  1 |-> <i32> KEY_IDX  2 |-> <i32> DEST_IDX </locals>



 // extern int32_t   mBufferFinish(void* context, int32_t sourceHandle);
    rule <instrs> hostCall ( "env" , "mBufferFinish" , [ i32  .ValTypes ] -> [ i32  .ValTypes ] )
               => #getBuffer( SRC_IDX )
               ~> #appendToOutFromBytesStack
               ~> i32 . const 0
                  ... 
         </instrs>
         <locals> 0 |-> <i32> SRC_IDX </locals>

 // extern int32_t   mBufferCopyByteSlice(void* context, int32_t sourceHandle, int32_t startingPosition, int32_t sliceLength, int32_t destinationHandle);
    rule <instrs> hostCall ( "env" , "mBufferCopyByteSlice" , [ i32  i32  i32  i32  .ValTypes ] -> [ i32  .ValTypes ] )
               => #getBuffer( SRC_IDX )
               ~> #mBufferCopyByteSliceH( OFFSET , LENGTH , DEST_IDX )
               ~> #dropBytes
                  ... 
         </instrs>
         <locals> 0 |-> <i32> SRC_IDX  1 |-> <i32> OFFSET  2 |-> <i32> LENGTH  3 |-> <i32> DEST_IDX </locals>

    syntax InternalInstr ::= #mBufferCopyByteSliceH( Int , Int , Int )
 // ------------------------------------------------------------------
    rule <instrs> #mBufferCopyByteSliceH( OFFSET , LENGTH , DEST_IDX )
               => #sliceBytes( OFFSET , LENGTH )
               ~> #setBufferFromBytesStack( DEST_IDX )
               ~> i32 . const 0
                  ...
         </instrs> 
         <bytesStack> BS : _ </bytesStack>
         requires #sliceBytesInBounds( BS , OFFSET , LENGTH )

    rule <instrs> #mBufferGetByteSliceH( OFFSET , LENGTH , _DEST_OFFSET )
               => i32 . const 1
                  ...
         </instrs> 
         <bytesStack> BS : _ </bytesStack>
         requires notBool( #sliceBytesInBounds( BS , OFFSET , LENGTH ) )

endmodule
```