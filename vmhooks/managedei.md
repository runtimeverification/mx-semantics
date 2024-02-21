Managed EI
==========

Go implementation: [mx-chain-vm-go/vmhost/vmhooks/managedei.go](https://github.com/multiversx/mx-chain-vm-go/blob/ea3d78d34c35f7ef9c1a9ea4fce8288608763229/vmhost/vmhooks/managedei.go)

```k
requires "../elrond-config.md"
requires "manBufOps.md"
requires "managedConversions.md"

module MANAGEDEI
    imports ELROND-CONFIG
    imports MANBUFOPS
    imports MANAGEDCONVERSIONS

    // extern void managedOwnerAddress(void* context, int32_t destinationHandle);
    rule <instrs> hostCall ( "env" , "managedOwnerAddress" , [ i32  .ValTypes ] -> [ .ValTypes ] )
               => #setBuffer( DEST_IDX , OWNER )
                  ...
         </instrs>
         <locals> 0 |-> <i32> DEST_IDX </locals>
         <callee> CALLEE </callee>
         <account>
            <address> CALLEE </address>
            <ownerAddress> OWNER </ownerAddress>
            ...
         </account>

    // TODO implement managedWriteLog
    // extern void      managedWriteLog(void* context, int32_t topicsHandle, int32_t dataHandle);
    rule <instrs> hostCall ( "env" , "managedWriteLog" , [ i32  i32  .ValTypes ] -> [ .ValTypes ] )
               => .K
                  ...
         </instrs>

 // extern void      managedSignalError(void* context, int32_t errHandle);
    rule <instrs> hostCall ( "env" , "managedSignalError" , [ i32  .ValTypes ] -> [ .ValTypes ] )
               => #getBuffer(ERR_IDX)
               ~> #signalError
                  ...
         </instrs>
         <locals>  0 |-> <i32> ERR_IDX  </locals>

 // extern void      managedGetMultiESDTCallValue(void* context, int32_t multiCallValueHandle);
    rule <instrs> hostCall ( "env" , "managedGetMultiESDTCallValue" , [ i32  .ValTypes ] -> [ .ValTypes ] )
               => #writeEsdtsToBytes(ESDTS)
               ~> #setBufferFromBytesStack(DEST_IDX)
               ~> #dropBytes
                  ...
         </instrs>
         <locals>  0 |-> <i32> DEST_IDX  </locals>
         <esdtTransfers> ESDTS </esdtTransfers>
  
 // extern int32_t   managedMultiTransferESDTNFTExecute(void* context, int32_t dstHandle, int32_t tokenTransfersHandle, long long gasLimit, int32_t functionHandle, int32_t argumentsHandle);
    rule [managedMultiTransferESDTNFTExecute]:
        <instrs> hostCall("env", "managedMultiTransferESDTNFTExecute", [ i32 i32 i64 i32 i32 .ValTypes ] -> [ i32 .ValTypes ] )
              => #transferESDTNFTExecuteWithTypedArgs(
                  getBuffer(DEST_IDX), 
                  readESDTTransfers(TRANSFERS_IDX), 
                  GAS_LIMIT, 
                  getBuffer(FUNC_IDX), 
                  readManagedVecOfManagedBuffers(ARGS_IDX)
                 )
                 ...
        </instrs>
        <locals>
          0 |-> <i32> DEST_IDX
          1 |-> <i32> TRANSFERS_IDX
          2 |-> <i64> GAS_LIMIT
          3 |-> <i32> FUNC_IDX
          4 |-> <i32> ARGS_IDX
        </locals>
        
 // extern void      managedSCAddress(void* context, int32_t destinationHandle);
    rule <instrs> hostCall ( "env" , "managedSCAddress" , [ i32  .ValTypes ] -> [ .ValTypes ] )
               => #setBuffer( DEST_IDX , CALLEE )
                  ...
         </instrs>
         <locals> 0 |-> <i32> DEST_IDX </locals>
         <callee> CALLEE </callee>

 // extern int32_t managedTransferValueExecute(void* context, int32_t dstHandle, int32_t valueHandle, long long gasLimit, int32_t functionHandle, int32_t argumentsHandle);
    rule <instrs> hostCall ( "env" , "managedTransferValueExecute" , [ i32  i32  i64  i32  i32  .ValTypes ] -> [ i32  .ValTypes ] )
               => #transferValueExecuteWithTypedArgs(
                    getBuffer(DEST_IDX), 
                    getBigInt(VALUE_IDX), 
                    GAS_LIMIT, 
                    getBuffer(FUNC_IDX), 
                    readManagedVecOfManagedBuffers(ARGS_IDX)
                  )
                  ...
         </instrs>
         <locals>
           0 |-> <i32> DEST_IDX
           1 |-> <i32> VALUE_IDX
           2 |-> <i64> GAS_LIMIT
           3 |-> <i32> FUNC_IDX
           4 |-> <i32> ARGS_IDX
         </locals>

 // extern int32_t managedExecuteOnDestContext(void* context, long long gas, int32_t addressHandle, int32_t valueHandle, int32_t functionHandle, int32_t argumentsHandle, int32_t resultHandle);
    rule [managedExecuteOnDestContext]:
        <instrs> hostCall ( "env" , "managedExecuteOnDestContext" , [i64 i32 i32 i32 i32 i32 .ValTypes ] -> [ i32  .ValTypes ] )
              => #executeOnDestContextWithTypedArgs(
                  getBuffer(DEST_IDX), 
                  getBigInt(VALUE_IDX),
                  .List,
                  GAS_LIMIT, 
                  getBuffer(FUNC_IDX), 
                  readManagedVecOfManagedBuffers(ARGS_IDX)
                 )
              ~> #setReturnDataIfExists(size(OUT), RES_IDX)
                 ...
        </instrs>
        <locals>
          0 |-> <i64> GAS_LIMIT
          1 |-> <i32> DEST_IDX
          2 |-> <i32> VALUE_IDX
          3 |-> <i32> FUNC_IDX
          4 |-> <i32> ARGS_IDX
          5 |-> <i32> RES_IDX
        </locals>
        <out> OUT </out>

    syntax InternalInstr ::= #setReturnDataIfExists(Int, Int)
 // ------------------------------------------------------
    rule [setReturnDataIfExists]:
        <instrs> #setReturnDataIfExists(OldLen, Dest)
              => #writeManagedVecOfManagedBuffers(rangeTotal(OUT, OldLen, 0), Dest)
                 ...
        </instrs>
        <out> OUT </out>
      requires OldLen <Int size(OUT)

    rule [setReturnDataIfExists-noData]:
        <instrs> #setReturnDataIfExists(OldLen, Dest)
              => #setBuffer(Dest, .Bytes)
                 ...
        </instrs>
        <out> OUT </out>
      requires OldLen >=Int size(OUT)

 // extern void managedGetBlockRandomSeed(void *context, int32_t resultHandle);
    rule <instrs> hostCall("env", "managedGetBlockRandomSeed", [i32  .ValTypes] -> [ .ValTypes ] )
               => #setBuffer(BUF_IDX, SEED)
                  ...
         </instrs>
         <locals> 0 |-> <i32> BUF_IDX </locals>
         <curBlockRandomSeed> SEED </curBlockRandomSeed>

 // extern void managedGetPrevBlockRandomSeed(void* context, int32_t resultHandle);
    rule [managedGetPrevBlockRandomSeed]:
        <instrs> hostCall("env", "managedGetPrevBlockRandomSeed", [i32 .ValTypes] -> [ .ValTypes ] )
              => #setBuffer(BUF_IDX, SEED)
                 ...
        </instrs>
        <locals> 0 |-> <i32> BUF_IDX </locals>
        <prevBlockRandomSeed> SEED </prevBlockRandomSeed>

endmodule
```
