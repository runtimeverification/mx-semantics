Managed EI
==========

Go implementation: [mx-chain-vm-go/vmhost/vmhooks/managedei.go](https://github.com/multiversx/mx-chain-vm-go/blob/ea3d78d34c35f7ef9c1a9ea4fce8288608763229/vmhost/vmhooks/managedei.go)

```k
require "../elrond-config.md"
require "manBufOps.md"
require "managedConversions.md"

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
               => .
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
               => #pushBytes(.Bytes)
               ~> #writeEsdtsToBytes(ESDTS)
               ~> #setBufferFromBytesStack(DEST_IDX)
               ~> #dropBytes
                  ...
         </instrs>
         <locals>  0 |-> <i32> DEST_IDX  </locals>
         <esdtTransfers> ESDTS </esdtTransfers>
  
 // extern int32_t   managedMultiTransferESDTNFTExecute(void* context, int32_t dstHandle, int32_t tokenTransfersHandle, long long gasLimit, int32_t functionHandle, int32_t argumentsHandle);
    rule <instrs> hostCall("env", "managedMultiTransferESDTNFTExecute", [ i32 i32 i64 i32 i32 .ValTypes ] -> [ i32 .ValTypes ] )
               => #transferESDTNFTExecuteWithTypedArgs(
                    Dest, 
                    #readESDTTransfers(EsdtBytes), 
                    GAS_LIMIT, 
                    FuncName, 
                    #readManagedVecOfManagedBuffers(ArgsBytes)
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
         <bufferHeap>
            ...
            DEST_IDX |-> Dest
            FUNC_IDX |-> FuncName
            TRANSFERS_IDX |-> EsdtBytes
            ARGS_IDX |-> ArgsBytes
            ...
         </bufferHeap>

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
                    Dest, 
                    Value, 
                    GAS_LIMIT, 
                    FuncName, 
                    #readManagedVecOfManagedBuffers(ArgsBytes)
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
         <bufferHeap>
            ...
            DEST_IDX |-> Dest
            FUNC_IDX |-> FuncName
            ARGS_IDX |-> ArgsBytes
            ...
         </bufferHeap>
         <bigIntHeap>
          ... VALUE_IDX |-> Value ...
         </bigIntHeap>

endmodule
```