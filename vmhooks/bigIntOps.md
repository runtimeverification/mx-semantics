Big Integers
============

Go implementation: [mx-chain-vm-go/vmhost/vmhooks/bigIntOps.go](https://github.com/multiversx/mx-chain-vm-go/blob/ea3d78d34c35f7ef9c1a9ea4fce8288608763229/vmhost/vmhooks/bigIntOps.go)

```k
require "../elrond-config.md"
require "baseOps.md"

module BIGINT-HELPERS
     imports ELROND-CONFIG
     imports BASEOPS

    syntax InternalInstr ::= #getBigInt ( idx : Int ,  Signedness )
 // ---------------------------------------------------------------
    rule <instrs> #getBigInt(BIGINT_IDX, SIGN) => . ... </instrs>
         <bytesStack> STACK => Int2Bytes({HEAP[BIGINT_IDX]}:>Int, BE, SIGN) : STACK </bytesStack>
         <bigIntHeap> HEAP </bigIntHeap>
      requires BIGINT_IDX in_keys(HEAP)
       andBool isInt(HEAP[BIGINT_IDX])

    syntax InternalInstr ::= #setBigIntFromBytesStack ( idx: Int , Signedness )
                           | #setBigInt ( idx: Int , value: Bytes , Signedness )
                           | #setBigIntValue ( Int , Int )
 // ----------------------------------------------------------------------------
    rule <instrs> #setBigIntFromBytesStack(BIGINT_IDX, SIGN) => #setBigInt(BIGINT_IDX, BS, SIGN) ... </instrs>
         <bytesStack> BS : _ </bytesStack>

    rule <instrs> #setBigInt(BIGINT_IDX, BS, SIGN) => . ... </instrs>
         <bigIntHeap> HEAP => HEAP [BIGINT_IDX <- Bytes2Int(BS, BE, SIGN)] </bigIntHeap>

    rule <instrs> #setBigIntValue(BIGINT_IDX, VALUE) => . ... </instrs>
         <bigIntHeap> HEAP => HEAP [BIGINT_IDX <- VALUE] </bigIntHeap>
endmodule

module BIGINTOPS
     imports BIGINT-HELPERS

    // extern int32_t bigIntNew(void* context, long long smallValue);
    rule <instrs> hostCall("env", "bigIntNew", [ i64 .ValTypes ] -> [ i32 .ValTypes ]) => i32.const size(HEAP) ... </instrs>
         <locals> 0 |-> <i64> INITIAL </locals>
         <bigIntHeap> HEAP => HEAP[size(HEAP) <- INITIAL] </bigIntHeap>

    // extern int32_t bigIntUnsignedByteLength(void* context, int32_t reference);
    rule <instrs> hostCall("env", "bigIntUnsignedByteLength", [ i32 .ValTypes ] -> [ i32 .ValTypes ]) => i32.const lengthBytes(Int2Bytes({HEAP[IDX]}:>Int, BE, Unsigned)) ... </instrs>
         <locals> 0 |-> <i32> IDX </locals>
         <bigIntHeap> HEAP </bigIntHeap>
      requires IDX in_keys(HEAP)
       andBool isInt(HEAP[IDX])

    // extern int32_t bigIntSignedByteLength(void* context, int32_t reference);
    rule <instrs> hostCall("env", "bigIntSignedByteLength", [ i32 .ValTypes ] -> [ i32 .ValTypes ]) => i32.const lengthBytes(Int2Bytes({HEAP[IDX]}:>Int, BE, Signed)) ... </instrs>
         <locals> 0 |-> <i32> IDX </locals>
         <bigIntHeap> HEAP </bigIntHeap>
      requires IDX in_keys(HEAP)
       andBool isInt(HEAP[IDX])

    // extern int32_t bigIntGetUnsignedBytes(void* context, int32_t reference, int32_t byteOffset);
    rule <instrs> hostCall("env", "bigIntGetUnsignedBytes", [ i32 i32 .ValTypes ] -> [ i32 .ValTypes ])
               => #getBigInt(IDX, Unsigned)
               ~> #memStoreFromBytesStack(OFFSET)
               ~> #returnLength
               ~> #dropBytes
                  ...
         </instrs>
         <locals> 0 |-> <i32> IDX  1 |-> <i32> OFFSET </locals>

    // extern int32_t bigIntGetSignedBytes(void* context, int32_t reference, int32_t byteOffset);
    rule <instrs> hostCall("env", "bigIntGetSignedBytes", [ i32 i32 .ValTypes ] -> [ i32 .ValTypes ])
               => #getBigInt(IDX, Signed)
               ~> #memStoreFromBytesStack(OFFSET)
               ~> #returnLength
               ~> #dropBytes
                  ...
         </instrs>
         <locals> 0 |-> <i32> IDX  1 |-> <i32> OFFSET </locals>

    // extern void bigIntSetUnsignedBytes(void* context, int32_t destination, int32_t byteOffset, int32_t byteLength);
    rule <instrs> hostCall("env", "bigIntSetUnsignedBytes", [ i32 i32 i32 .ValTypes ] -> [ .ValTypes ])
               => #memLoad(OFFSET, LENGTH)
               ~> #setBigIntFromBytesStack(IDX, Unsigned)
               ~> #dropBytes
                  ...
         </instrs>
         <locals> 0 |-> <i32> IDX 1 |-> <i32> OFFSET 2 |-> <i32> LENGTH </locals>

    // extern void bigIntSetSignedBytes(void* context, int32_t destination, int32_t byteOffset, int32_t byteLength);
    rule <instrs> hostCall("env", "bigIntSetSignedBytes", [ i32 i32 i32 .ValTypes ] -> [ .ValTypes ])
               => #memLoad(OFFSET, LENGTH)
               ~> #setBigIntFromBytesStack(IDX, Signed)
               ~> #dropBytes
                  ...
         </instrs>
         <locals> 0 |-> <i32> IDX 1 |-> <i32> OFFSET 2 |-> <i32> LENGTH </locals>

 // extern void      bigIntSetInt64(void* context, int32_t destinationHandle, long long value);
    rule <instrs> hostCall ( "env" , "bigIntSetInt64" , [ i32  i64  .ValTypes ] -> [ .ValTypes ] )
               => #setBigIntValue(DEST_IDX, VALUE)
                  ...
         </instrs>
         <locals> 0 |-> <i32> DEST_IDX 1 |-> <i64> VALUE </locals>

    // extern void bigIntAdd(void* context, int32_t destination, int32_t op1, int32_t op2);
    rule <instrs> hostCall("env", "bigIntAdd", [ i32 i32 i32 .ValTypes ] -> [ .ValTypes ]) => . ... </instrs>
         <locals> 0 |-> <i32> DST  1 |-> <i32> OP1_IDX  2 |-> <i32> OP2_IDX </locals>
         <bigIntHeap> HEAP => HEAP [DST <- {HEAP[OP1_IDX]}:>Int +Int {HEAP[OP2_IDX]}:>Int] </bigIntHeap>
      requires OP1_IDX in_keys(HEAP)
       andBool isInt(HEAP[OP1_IDX])
       andBool OP2_IDX in_keys(HEAP)
       andBool isInt(HEAP[OP2_IDX])

    // extern void bigIntSub(void* context, int32_t destination, int32_t op1, int32_t op2);
    rule <instrs> hostCall("env", "bigIntSub", [ i32 i32 i32 .ValTypes ] -> [ .ValTypes ]) => . ... </instrs>
         <locals> 0 |-> <i32> DST  1 |-> <i32> OP1_IDX  2 |-> <i32> OP2_IDX </locals>
         <bigIntHeap> HEAP => HEAP [DST <- {HEAP[OP1_IDX]}:>Int -Int {HEAP[OP2_IDX]}:>Int] </bigIntHeap>
      requires OP1_IDX in_keys(HEAP)
       andBool isInt(HEAP[OP1_IDX])
       andBool OP2_IDX in_keys(HEAP)
       andBool isInt(HEAP[OP2_IDX])

    // extern void bigIntMul(void* context, int32_t destination, int32_t op1, int32_t op2);
    rule <instrs> hostCall("env", "bigIntMul", [ i32 i32 i32 .ValTypes ] -> [ .ValTypes ]) => . ... </instrs>
         <locals> 0 |-> <i32> DST  1 |-> <i32> OP1_IDX  2 |-> <i32> OP2_IDX </locals>
         <bigIntHeap> HEAP => HEAP [DST <- {HEAP[OP1_IDX]}:>Int *Int {HEAP[OP2_IDX]}:>Int] </bigIntHeap>
      requires OP1_IDX in_keys(HEAP)
       andBool isInt(HEAP[OP1_IDX])
       andBool OP2_IDX in_keys(HEAP)
       andBool isInt(HEAP[OP2_IDX])

    // extern void bigIntTDiv(void* context, int32_t destination, int32_t op1, int32_t op2);
    rule <instrs> hostCall("env", "bigIntTDiv", [ i32 i32 i32 .ValTypes ] -> [ .ValTypes ]) => . ... </instrs>
         <locals> 0 |-> <i32> DST  1 |-> <i32> OP1_IDX  2 |-> <i32> OP2_IDX </locals>
         <bigIntHeap> HEAP => HEAP [DST <- {HEAP[OP1_IDX]}:>Int /Int {HEAP[OP2_IDX]}:>Int] </bigIntHeap>
      requires OP1_IDX in_keys(HEAP)
       andBool isInt(HEAP[OP1_IDX])
       andBool OP2_IDX in_keys(HEAP)
       andBool isInt(HEAP[OP2_IDX])

    // extern int32_t bigIntSign(void* context, int32_t op);
    rule <instrs> hostCall("env", "bigIntSign", [ i32 .ValTypes ] -> [ i32 .ValTypes ])
               => i32.const #bigIntSign({HEAP[IDX]}:>Int)
                  ...
         </instrs>
         <locals> 0 |-> <i32> IDX </locals>
         <bigIntHeap> HEAP </bigIntHeap>
      requires IDX in_keys(HEAP)
       andBool isInt(HEAP[IDX])

    // extern int32_t bigIntCmp(void* context, int32_t op1, int32_t op2);
    rule <instrs> hostCall("env", "bigIntCmp", [ i32 i32 .ValTypes ] -> [ i32 .ValTypes ])
               => i32.const #cmpInt({HEAP[IDX1]}:>Int, {HEAP[IDX2]}:>Int)
                  ...
         </instrs>
         <locals> 0 |-> <i32> IDX1  1 |-> <i32> IDX2 </locals>
         <bigIntHeap> HEAP </bigIntHeap>
      requires IDX1 in_keys(HEAP)
       andBool isInt(HEAP[IDX1])
       andBool IDX2 in_keys(HEAP)
       andBool isInt(HEAP[IDX2])

    // extern void bigIntFinishUnsigned(void* context, int32_t reference);
    rule <instrs> hostCall("env", "bigIntFinishUnsigned", [ i32 .ValTypes ] -> [ .ValTypes ])
               => #getBigInt(IDX, Unsigned)
               ~> #appendToOutFromBytesStack
                  ...
         </instrs>
         <locals> 0 |-> <i32> IDX </locals>

    // extern void bigIntFinishSigned(void* context, int32_t reference);
    rule <instrs> hostCall("env", "bigIntFinishSigned", [ i32 .ValTypes ] -> [ .ValTypes ])
               => #getBigInt(IDX, Signed)
               ~> #appendToOutFromBytesStack
                  ...
         </instrs>
         <locals> 0 |-> <i32> IDX </locals>

    // extern int32_t bigIntStorageStoreUnsigned(void *context, int32_t keyOffset, int32_t keyLength, int32_t source);
    rule <instrs> hostCall("env", "bigIntStorageStoreUnsigned", [ i32 i32 i32 .ValTypes ] -> [ i32 .ValTypes ])
               => #memLoad(KEYOFFSET, KEYLENGTH)
               ~> #getBigInt(BIGINTIDX, Unsigned)
               ~> #storageStore
                  ...
         </instrs>
         <locals>
           0 |-> <i32> KEYOFFSET
           1 |-> <i32> KEYLENGTH
           2 |-> <i32> BIGINTIDX
         </locals>

    // extern int32_t bigIntStorageLoadUnsigned(void *context, int32_t keyOffset, int32_t keyLength, int32_t destination);
    rule <instrs> hostCall("env", "bigIntStorageLoadUnsigned", [ i32 i32 i32 .ValTypes ] -> [ i32 .ValTypes ])
               => #memLoad(KEYOFFSET, KEYLENGTH)
               ~> #storageLoad
               ~> #setBigIntFromBytesStack(DEST, Unsigned)
               ~> #returnLength
               ~> #dropBytes
                  ...
         </instrs>
         <locals>
           0 |-> <i32> KEYOFFSET
           1 |-> <i32> KEYLENGTH
           2 |-> <i32> DEST
         </locals>

    // extern void bigIntGetUnsignedArgument(void *context, int32_t id, int32_t destination);
    rule <instrs> hostCall("env", "bigIntGetUnsignedArgument", [ i32 i32 .ValTypes ] -> [ .ValTypes ]) =>  . ... </instrs>
         <locals> 0 |-> <i32> ARG_IDX  1 |-> <i32> BIG_IDX </locals>
         <callArgs> ARGS </callArgs>
         <bigIntHeap> HEAP => HEAP [BIG_IDX <- Bytes2Int({ARGS[ARG_IDX]}:>Bytes, BE, Unsigned)] </bigIntHeap>
      requires ARG_IDX <Int size(ARGS)
       andBool isBytes(ARGS[ARG_IDX])

    // extern void bigIntGetSignedArgument(void *context, int32_t id, int32_t destination);
    rule <instrs> hostCall("env", "bigIntGetSignedArgument", [ i32 i32 .ValTypes ] -> [ .ValTypes ]) =>  . ... </instrs>
         <locals> 0 |-> <i32> ARG_IDX  1 |-> <i32> BIG_IDX </locals>
         <callArgs> ARGS </callArgs>
         <bigIntHeap> HEAP => HEAP [BIG_IDX <- Bytes2Int({ARGS[ARG_IDX]}:>Bytes, BE, Signed)] </bigIntHeap>
      requires ARG_IDX <Int size(ARGS)
       andBool isBytes(ARGS[ARG_IDX])

    // extern void bigIntGetCallValue(void *context, int32_t destination);
    rule <instrs> hostCall("env", "bigIntGetCallValue", [ i32 .ValTypes ] -> [ .ValTypes ]) => . ... </instrs>
         <locals> 0 |-> <i32> IDX </locals>
         <bigIntHeap> HEAP => HEAP[IDX <- VALUE] </bigIntHeap>
         <callValue> VALUE </callValue>

    // extern void bigIntGetExternalBalance(void *context, int32_t addressOffset, int32_t result);
    rule <instrs> hostCall("env", "bigIntGetExternalBalance", [ i32 i32 .ValTypes ] -> [ .ValTypes ])
               => #memLoad(ADDROFFSET, 32)
               ~> #getExternalBalance
               ~> #setBigIntFromBytesStack(RESULT, Unsigned)
               ~> #dropBytes
                  ...
         </instrs>
         <locals>
           0 |-> <i32> ADDROFFSET
           1 |-> <i32> RESULT
         </locals>

    // extern void bigIntGetESDTExternalBalance(void* context, int32_t addressOffset, int32_t tokenIDOffset, int32_t tokenIDLen, long long nonce, int32_t resultHandle);
    rule <instrs> hostCall ( "env" , "bigIntGetESDTExternalBalance" , [ i32  i32  i32  i64  i32  .ValTypes ] -> [ .ValTypes ] )
               => #memLoad(ADDR_OFFSET, 32)
               ~> #memLoad(TOK_ID_OFFSET, TOK_ID_LEN)
               ~> #bigIntGetESDTExternalBalance(RES_HANDLE)
               ~> #dropBytes
               ~> #dropBytes
                  ...
         </instrs>
         <locals>
           0 |-> <i32> ADDR_OFFSET
           1 |-> <i32> TOK_ID_OFFSET
           2 |-> <i32> TOK_ID_LEN
           3 |-> <i64> _NONCE   // TODO use nonce
           4 |-> <i32> RES_HANDLE
         </locals>

    syntax InternalInstr ::= #bigIntGetESDTExternalBalance(Int)
 // -----------------------------------------------------------
    rule <instrs> #bigIntGetESDTExternalBalance(RES_HANDLE)
               => #setBigIntValue( RES_HANDLE , BALANCE )
                  ...
         </instrs>
         <bytesStack> TOK_ID : ADDR : _ </bytesStack>
         <account>
           <address> ADDR </address>
           <esdtData>
             <esdtId> TOK_ID </esdtId>
             <esdtBalance> BALANCE </esdtBalance>
             ...
           </esdtData>
           ...
         </account>
      [priority(60)]

    rule <instrs> #bigIntGetESDTExternalBalance(RES_HANDLE)
               => #setBigIntValue( RES_HANDLE , 0 )
                  ...
         </instrs>
         <bytesStack> _TOK_ID : ADDR : _ </bytesStack>
         <account>
           <address> ADDR </address>
           ...
         </account>
      [priority(61)]


endmodule
```

