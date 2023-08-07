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

 // extern void managedGetOriginalTxHash(void* context, int32_t resultHandle);
    rule [managedGetOriginalTxHash]:
        <instrs> hostCall("env", "managedGetOriginalTxHash", [i32 .ValTypes] -> [ .ValTypes ] )
              => #setBuffer(BUF_IDX, HASH)
                 ...
        </instrs>
        <locals> 0 |-> <i32> BUF_IDX </locals>
        <originalTxHash> HASH </originalTxHash>

 // extern int32_t managedDeployFromSourceContract(void*, long long gas, int32_t valHandle, int32_t addrHandle, int32_t codeMetaHandle, int32_t argsHandle, int32_t resAddrHandle, int32_t resHandle);
    rule [managedDeployFromSourceContract]:
        <instrs> hostCall("env", "managedDeployFromSourceContract",
                          [i64 i32 i32 i32 i32 i32 i32 .ValTypes] -> [i32 .ValTypes ] )
              => #deployFromSourceContractAux(
                    getBuffer(ADDR_IDX), 
                    getBigInt(VAL_IDX),
                    readManagedVecOfManagedBuffers(ARGS_IDX), 
                    GAS
                  )
              ~> #setBuffer(RES_ADDR_IDX, genNewAddress(CALLEE, NONCE))
              ~> #setReturnDataIfExists(size(OUT), RES_IDX)
              ~> i32.const 0
                 ...
        </instrs>
        <locals>
          0 |-> <i64> GAS
          1 |-> <i32> VAL_IDX
          2 |-> <i32> ADDR_IDX
          3 |-> <i32> _ // TODO use code metadata handle
          4 |-> <i32> ARGS_IDX
          5 |-> <i32> RES_ADDR_IDX
          6 |-> <i32> RES_IDX
        </locals>
        <out> OUT </out>
        <callee> CALLEE </callee>
        <account>
           <address> CALLEE </address>
           <nonce> NONCE </nonce>
           ...
        </account>

    syntax InternalInstr ::= #setReturnDataIfExists(Int, Int) // oldLen, resHandle
 // -----------------------------------------------------------
    rule [setReturnDataIfExists]:
        <instrs> #setReturnDataIfExists(OldLen, DestHandle)
              => #setBuffer(DestHandle, .Bytes) ... // TODO implement WriteManagedVecOfManagedBuffers
        </instrs>
        <out> OUTPUT </out>
      requires size(OUTPUT) >Int OldLen

    rule [setReturnDataIfExists-nil]:
        <instrs> #setReturnDataIfExists(OldLen, DestHandle)
              => #setBuffer(DestHandle, .Bytes) ...
        </instrs>
        <out> OUTPUT </out>
      requires size(OUTPUT) <=Int OldLen
    
    syntax InternalInstr ::= #deployFromSourceContractAux(BytesResult, IntResult, ListBytesResult, Int)
                           | #deployFromSourceContract(Bytes, Int, ListBytes, Int)
 // --------------------------------------------------------------------------------------------------
    rule [deployFromSourceContractAux]:
        <instrs> #deployFromSourceContractAux(SRC_ADDR:Bytes, VAL:Int, ARGS:ListBytes, GAS:Int)
              => #deployFromSourceContract(SRC_ADDR, VAL, ARGS, GAS) ...
        </instrs>

    rule [deployFromSourceContractAux-err]:
        <instrs> #deployFromSourceContractAux(_,_,_,_)
              => #throwException(ExecutionFailed, "managedDeployFromSourceContract: argument parsing failed") ...
        </instrs>
      [owise]

    rule [deployFromSourceContract]:
        <instrs> #deployFromSourceContract(SRC_ADDR, VAL, ARGS, GAS)
              => #finishExecuteOnDestContext  // wait for the 'init' function
              ~> drop
                 ...
        </instrs>
        <commands> (. => deployContract(FROM, CODE, VAL, ARGS, GAS, GASPRICE, HASH)) ... </commands>
        <account>
          <address> SRC_ADDR </address>
          <code> CODE:ModuleDecl </code>
          ...
        </account>
        <callee> FROM </callee>
        <gasPrice> GASPRICE </gasPrice>
        <originalTxHash> HASH </originalTxHash>

    rule [deployFromSourceContract-notfound]:
        <instrs> #deployFromSourceContract(SRC_ADDR, _, _, _)
              => #throwExceptionBs(ExecutionFailed, b"source contract not found: " +Bytes SRC_ADDR) ...
        </instrs>
      [owise]
        
        

endmodule
```