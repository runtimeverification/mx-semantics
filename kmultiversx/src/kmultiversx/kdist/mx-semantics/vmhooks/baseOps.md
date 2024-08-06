Base Operations
===============

Go implementation: [mx-chain-vm-go/vmhost/vmhooks/baseOps.go](https://github.com/multiversx/mx-chain-vm-go/blob/ea3d78d34c35f7ef9c1a9ea4fce8288608763229/vmhost/vmhooks/baseOps.go)

```k
requires "../elrond-config.md"
requires "async.md"
requires "eei-helpers.md"
requires "utils.md"

module BASEOPS
    imports ELROND-CONFIG
    imports EEI-HELPERS
    imports UTILS
    imports ASYNC-HELPERS

    imports private LIST-BYTES-EXTENSIONS

    // extern void getSCAddress(void *context, int32_t resultOffset);
    rule <instrs> hostCall("env", "getSCAddress", [ i32  .ValTypes ] -> [ .ValTypes ])
               => #memStore(RESULTOFFSET, CALLEE)
                  ...
         </instrs>
         <locals>
           ListItem(<i32> RESULTOFFSET)
         </locals>
         <callee> CALLEE </callee>

    // TODO refactor this with #isSmartContract boolean function
    // extern int32_t isSmartContract(void *context, int32_t addressOffset);
    rule <instrs> hostCall("env", "isSmartContract", [ i32 .ValTypes ] -> [ i32 .ValTypes ])
               => #memLoad(ADDROFFSET, 32)
               ~> #checkIsSmartContract
                  ...
         </instrs>
         <locals>
           ListItem(<i32> ADDROFFSET)
         </locals>

    syntax InternalInstr ::= "#checkIsSmartContract"  [symbol(checkIsSmartContract)]
 // ------------------------------------------------
    rule [checkIsSmartContract-code]:
         <instrs> #checkIsSmartContract => i32.const 1 ... </instrs>
         <bytesStack> ADDR : STACK => STACK </bytesStack>
         <account>
           <address> ADDR </address>
           <code> _:ModuleDecl </code>
           ...
         </account>

    rule [checkIsSmartContract-no-code]:
         <instrs> #checkIsSmartContract => i32.const 0 ... </instrs>
         <bytesStack> ADDR : STACK => STACK </bytesStack>
         <account>
           <address> ADDR </address>
           <code> .Code </code>
           ...
         </account>

    // extern void getExternalBalance(void *context, int32_t addressOffset, int32_t resultOffset);
    rule <instrs> hostCall("env", "getExternalBalance", [ i32 i32 .ValTypes ] -> [ .ValTypes ])
               => #memLoad(ADDROFFSET, 32)
               ~> #getExternalBalance
               ~> #memStoreFromBytesStack(RESULTOFFSET)
               ~> #dropBytes
                  ...
         </instrs>
         <locals>
           ListItem(<i32> ADDROFFSET)
           ListItem(<i32> RESULTOFFSET)
         </locals>

    syntax InternalInstr ::= "#getExternalBalance"
 // ----------------------------------------------
    rule <instrs> #getExternalBalance => .K ... </instrs>
         <bytesStack> ADDR : STACK => Int2Bytes(BAL, BE, Unsigned) : STACK </bytesStack>
         <account>
           <address> ADDR </address>
           <balance> BAL </balance>
           ...
         </account>

    // return 0 if account does not exist (see the priority)
    rule <instrs> #getExternalBalance => .K ... </instrs>
         <bytesStack> _ADDR : STACK => Int2Bytes(0, BE, Unsigned) : STACK </bytesStack>
      [priority(201)]
         
    // extern int32_t transferValue(void *context, int32_t dstOffset, int32_t valueOffset, int32_t dataOffset, int32_t length);
    rule <instrs> hostCall("env", "transferValue", [ i32 i32 i32 i32 .ValTypes ] -> [ i32 .ValTypes ])
               => #memLoad(DSTOFFSET, 32)
               ~> #memLoad(VALUEOFFSET, 32)
               ~> #memLoad(DATAOFFSET, LENGTH)
               ~> #transferValue
                  ...
         </instrs>
         <locals>
           ListItem(<i32> DSTOFFSET)
           ListItem(<i32> VALUEOFFSET)
           ListItem(<i32> DATAOFFSET)
           ListItem(<i32> LENGTH)
         </locals>

    syntax InternalInstr ::= "#transferValue"
 // -------------------------------------------
    rule <instrs> #transferValue => #waitCommands ~> i32.const 0 ... </instrs>
         <commands> (.K => transferFunds(CALLEE, DEST, Bytes2Int(VALUE, BE, Unsigned))) ... </commands>
         <callee> CALLEE </callee>
         <bytesStack> _DATA : VALUE : DEST : STACK => STACK </bytesStack>

    syntax Bool ::= #validArgIdx( Int , ListBytes )        [function, total]
 // -------------------------------------------------------------------
    rule #validArgIdx(IDX, ARGS)
        => 0 <=Int #signed(i32, IDX)
          andBool definedSigned(i32, IDX)
          andBool definedBytesListLookup(ARGS, IDX)

    // extern int32_t getArgumentLength(void *context, int32_t id);
    rule <instrs> hostCall("env", "getArgumentLength", [ i32 .ValTypes ] -> [ i32 .ValTypes ]) 
               => i32.const lengthBytes( ARGS {{ IDX }} ) ...
         </instrs>
         <locals> ListItem(<i32> IDX:Int) </locals>
         <callArgs> ARGS:ListBytes </callArgs>
      requires #validArgIdx(IDX, ARGS)

    rule <instrs> hostCall("env", "getArgumentLength", [ i32 .ValTypes ] -> [ i32 .ValTypes ])
               => #throwException(ExecutionFailed, "invalid argument") ... 
         </instrs>
         <locals> ListItem(<i32> IDX) </locals>
         <callArgs> ARGS </callArgs>
      requires notBool #validArgIdx(IDX, ARGS)

    // extern int32_t getArgument(void *context, int32_t id, int32_t argOffset);
    rule <instrs> hostCall("env", "getArgument", [ i32 i32 .ValTypes ] -> [ i32 .ValTypes ])
               => #memStore(OFFSET, ARGS {{ IDX }} )
               ~> i32.const lengthBytes( ARGS {{ IDX }} )
                  ...
         </instrs>
         <locals>
           ListItem(<i32> IDX)
           ListItem(<i32> OFFSET)
         </locals>
         <callArgs> ARGS </callArgs>
      requires #validArgIdx(IDX, ARGS)

    rule <instrs> hostCall("env", "getArgument", [ i32 i32 .ValTypes ] -> [ i32 .ValTypes ])
               => #throwException(ExecutionFailed, "invalid argument") ...
         </instrs>
         <locals>
           ListItem(<i32> IDX)
           ListItem(<i32> _OFFSET)
         </locals>
         <callArgs> ARGS </callArgs>
      requires notBool #validArgIdx(IDX, ARGS)

    // extern int32_t getNumArguments(void *context);
    rule <instrs> hostCall("env", "getNumArguments", [ .ValTypes ] -> [ i32 .ValTypes ]) => i32.const size(ARGS) ... </instrs>
         <callArgs> ARGS </callArgs>

    // extern int32_t storageStore(void *context, int32_t keyOffset, int32_t keyLength , int32_t dataOffset, int32_t dataLength);
    rule <instrs> hostCall("env", "storageStore", [ i32 i32 i32 i32 .ValTypes ] -> [ i32 .ValTypes ] )
               => #memLoad(KEYOFFSET, KEYLENGTH)
               ~> #memLoad(VALOFFSET, VALLENGTH)
               ~> #storageStore
                  ...
         </instrs>
         <locals>
           ListItem(<i32> KEYOFFSET)
           ListItem(<i32> KEYLENGTH)
           ListItem(<i32> VALOFFSET)
           ListItem(<i32> VALLENGTH)
         </locals>

    // extern int32_t storageLoadLength(void *context, int32_t keyOffset, int32_t keyLength );
    rule <instrs> hostCall("env", "storageLoadLength", [ i32 i32 .ValTypes ] -> [ i32 .ValTypes ] )
               => #memLoad(KEYOFFSET, KEYLENGTH)
               ~> #storageLoad
               ~> #returnLength
               ~> #dropBytes
                  ...
         </instrs>
         <locals>
           ListItem(<i32> KEYOFFSET)
           ListItem(<i32> KEYLENGTH)
         </locals>

    // extern int32_t storageLoad(void *context, int32_t keyOffset, int32_t keyLength , int32_t dataOffset);
    rule <instrs> hostCall("env", "storageLoad", [ i32 i32 i32 .ValTypes ] -> [ i32 .ValTypes ] )
               => #memLoad(KEYOFFSET, KEYLENGTH)
               ~> #storageLoad
               ~> #memStoreFromBytesStack(VALOFFSET)
               ~> #returnLength
               ~> #dropBytes
                  ...
         </instrs>
         <locals>
           ListItem(<i32> KEYOFFSET)
           ListItem(<i32> KEYLENGTH)
           ListItem(<i32> VALOFFSET)
         </locals>

    // extern void getCaller(void *context, int32_t resultOffset);
    rule <instrs> hostCall("env", "getCaller", [ i32 .ValTypes ] -> [ .ValTypes ])
               => #memStore(OFFSET, CALLER)
                  ...
         </instrs>
         <locals> ListItem(<i32> OFFSET) </locals>
         <caller> CALLER </caller>

    // extern void checkNoPayment(void *context);
    // Call value is not positive (it can be negative), and the ESDT transfer list is empty
    rule [checkNoPayment-pass]:
        <instrs> hostCall("env", "checkNoPayment", [ .ValTypes ] -> [ .ValTypes ]) => .K ... </instrs>
        <callValue> VAL </callValue>
        <esdtTransfers> T:List </esdtTransfers>
      requires VAL <=Int 0 andBool size(T) ==K 0

    rule [checkNoPayment-fail-egld]:
        <instrs> hostCall("env", "checkNoPayment", [ .ValTypes ] -> [ .ValTypes ]) 
              => #throwException(ExecutionFailed, "function does not accept EGLD payment") ... 
        </instrs>
        <callValue> VAL </callValue>
      requires 0 <Int VAL

    rule [checkNoPayment-fail-esdt]:
        <instrs> hostCall("env", "checkNoPayment", [ .ValTypes ] -> [ .ValTypes ]) 
              => #throwException(ExecutionFailed, "function does not accept ESDT payment") ... 
        </instrs>
        <callValue> VAL </callValue>
        <esdtTransfers> T:List </esdtTransfers>
      requires VAL <=Int 0 andBool 0 <Int size(T)

    // extern int32_t getESDTTokenName(void *context, int32_t resultOffset);
    rule [getESDTTokenName]:
        <instrs> hostCall("env", "getESDTTokenName", [ i32 .ValTypes ] -> [ i32 .ValTypes ])
              => #memStore(OFFSET, TOKENNAME)
              ~> i32.const lengthBytes(TOKENNAME)
                ...
        </instrs>
        <locals> ListItem(<i32> OFFSET) </locals>
        <esdtTransfers> ListItem( esdtTransfer( TOKENNAME , _VALUE , _NONCE ) ) </esdtTransfers>

    rule [getESDTTokenName-too-many]:
        <instrs> hostCall("env", "getESDTTokenName", [ i32 .ValTypes ] -> [ i32 .ValTypes ])
              => #throwException(ExecutionFailed, "too many ESDT transfers")
                ...
        </instrs>
        <locals> ListItem(<i32> _) </locals>
        <esdtTransfers> ESDTs </esdtTransfers>
      requires size(ESDTs) >Int 1

    rule [getESDTTokenName-none]:
        <instrs> hostCall("env", "getESDTTokenName", [ i32 .ValTypes ] -> [ i32 .ValTypes ])
              => #throwException(ExecutionFailed, "invalid token index")
                ...
        </instrs>
        <locals> ListItem(<i32> _) </locals>
        <esdtTransfers> .List </esdtTransfers>

    // extern int32_t   getNumESDTTransfers(void* context);
    rule <instrs> hostCall ( "env" , "getNumESDTTransfers" , [ .ValTypes ] -> [ i32  .ValTypes ] )
               => i32.const size( TS )
                  ...
         </instrs>
         <esdtTransfers> TS </esdtTransfers>
 
    // long long getCurrentESDTNFTNonce(void* context, int32_t addressOffset, int32_t tokenIDOffset, int32_t tokenIDLen);
    rule <instrs> hostCall("env", "getCurrentESDTNFTNonce", [ i32 i32 i32 .ValTypes ] -> [ i64 .ValTypes ])
               => #memLoad(ADDR_OFFSET, 32)
               ~> #memLoad(TOKEN_OFFSET, TOKEN_LEN)
               ~> #getCurrentESDTNFTNonce
               ~> #dropBytes
               ~> #dropBytes
                 ...
        </instrs>
        <locals>
          ListItem(<i32> ADDR_OFFSET)
          ListItem(<i32> TOKEN_OFFSET)
          ListItem(<i32> TOKEN_LEN)
        </locals>

    syntax InternalInstr ::= "#getCurrentESDTNFTNonce"    [symbol(getCurrentESDTNFTNonce)]
 // ----------------------------------------------------------------------------------------------
    rule [getCurrentESDTNFTNonce]:
        <instrs> #getCurrentESDTNFTNonce => i64.const LAST_NONCE ... </instrs>
        <bytesStack> TOKEN : ADDR : _ </bytesStack>
        <account>
          <address> ADDR </address>
          <esdtData>
            <esdtId> TOKEN </esdtId> 
            <esdtLastNonce> LAST_NONCE </esdtLastNonce>
            ...
          </esdtData>
          ...
        </account>

    rule [getCurrentESDTNFTNonce-none]:
        <instrs> #getCurrentESDTNFTNonce => i64.const 0 ... </instrs>
      [owise]

    // extern void writeEventLog(void *context, int32_t numTopics, int32_t topicLengthsOffset, int32_t topicOffset, int32_t dataOffset, int32_t dataLength);
    rule <instrs> hostCall("env", "writeEventLog", [ i32 i32 i32 i32 i32 .ValTypes ] -> [ .ValTypes ])
               => #getArgsFromMemory(NUMTOPICS, TOPICLENGTHOFFSET, TOPICOFFSET)
               ~> #memLoad(DATAOFFSET, DATALENGTH)
               ~> #writeLog
                  ...
         </instrs>
         <locals>
           ListItem(<i32> NUMTOPICS)
           ListItem(<i32> TOPICLENGTHOFFSET)
           ListItem(<i32> TOPICOFFSET)
           ListItem(<i32> DATAOFFSET)
           ListItem(<i32> DATALENGTH)
         </locals>
 
    // extern void returnData(void* context, int32_t dataOffset, int32_t length);
    rule <instrs> hostCall("env", "finish", [ i32 i32 .ValTypes ] -> [ .ValTypes ])
               => #returnData(OFFSET, LENGTH)
                  ...
         </instrs>
         <locals>
           ListItem(<i32> OFFSET)
           ListItem(<i32> LENGTH)
         </locals>

    syntax InternalInstr ::= #returnData ( Int, Int )
 // -------------------------------------------------
    rule <instrs> #returnData(OFFSET, LENGTH)
               => #memLoad(OFFSET, LENGTH)
               ~> #appendToOutFromBytesStack
                  ...
         </instrs>

    // extern void signalError(void* context, int32_t messageOffset, int32_t messageLength);
    rule <instrs> hostCall("env", "signalError", [ i32 i32 .ValTypes ] -> [ .ValTypes ] )
               => #memLoad(OFFSET, LENGTH)
               ~> #signalError
                  ...
         </instrs>
         <locals>
           ListItem(<i32> OFFSET)
           ListItem(<i32> LENGTH)
         </locals>
 
    syntax InternalInstr ::= "#signalError"
 // ---------------------------------------
    rule <instrs> #signalError => #throwExceptionBs(UserError, DATA) ... </instrs>
         <bytesStack> DATA : STACK => STACK </bytesStack>

   // extern long long getGasLeft(void *context);
    rule [getGasLeft]:
        <instrs> hostCall("env", "getGasLeft", [ .ValTypes ] -> [ i64 .ValTypes ]) 
              => i64.const GAS ...
        </instrs>
        <gasProvided> GAS </gasProvided>

    // extern long long getBlockTimestamp(void *context);
    rule <instrs> hostCall("env", "getBlockTimestamp", [ .ValTypes ] -> [ i64 .ValTypes ]) => i64.const TIMESTAMP ... </instrs>
         <curBlockTimestamp> TIMESTAMP </curBlockTimestamp>
 
    // extern long long getBlockNonce(void *context);
    rule <instrs> hostCall("env", "getBlockNonce", [ .ValTypes ] -> [ i64 .ValTypes ]) => i64.const NONCE ... </instrs>
         <curBlockNonce> NONCE </curBlockNonce>

    // extern long long getBlockRound(void *context);
    rule <instrs> hostCall("env", "getBlockRound", [ .ValTypes ] -> [ i64 .ValTypes ]) => i64.const ROUND ... </instrs>
         <curBlockRound> ROUND </curBlockRound>
 
    // extern long long getBlockEpoch(void *context);
    rule <instrs> hostCall("env", "getBlockEpoch", [ .ValTypes ] -> [ i64 .ValTypes ]) => i64.const EPOCH ... </instrs>
         <curBlockEpoch> EPOCH </curBlockEpoch>
 
    // extern void getBlockRandomSeed(void *context, int32_t resultOffset);
    rule <instrs> hostCall("env", "getBlockRandomSeed", [ i32 .ValTypes ] -> [ .ValTypes ])
               => #memStore(OFFSET, SEED)
                  ...
         </instrs>
         <locals> ListItem(<i32> OFFSET) </locals>
         <curBlockRandomSeed> SEED </curBlockRandomSeed>
 
    // extern long long getPrevBlockTimestamp(void *context);
    rule <instrs> hostCall("env", "getPrevBlockTimestamp", [ .ValTypes ] -> [ i64 .ValTypes ]) => i64.const TIMESTAMP ... </instrs>
         <prevBlockTimestamp> TIMESTAMP </prevBlockTimestamp>

    // extern long long getPrevBlockNonce(void *context);
    rule <instrs> hostCall("env", "getPrevBlockNonce", [ .ValTypes ] -> [ i64 .ValTypes ]) => i64.const NONCE ... </instrs>
         <prevBlockNonce> NONCE </prevBlockNonce>

    // extern long long getPrevBlockRound(void *context);
    rule <instrs> hostCall("env", "getPrevBlockRound", [ .ValTypes ] -> [ i64 .ValTypes ]) => i64.const ROUND ... </instrs>
         <prevBlockRound> ROUND </prevBlockRound>

    // extern long long getPrevBlockEpoch(void *context);
    rule <instrs> hostCall("env", "getPrevBlockEpoch", [ .ValTypes ] -> [ i64 .ValTypes ]) => i64.const EPOCH ... </instrs>
         <prevBlockEpoch> EPOCH </prevBlockEpoch>

    // extern void getPrevBlockRandomSeed(void *context, int32_t resultOffset);
    rule <instrs> hostCall("env", "getPrevBlockRandomSeed", [ i32 .ValTypes ] -> [ .ValTypes ])
               => #memStore(OFFSET, SEED)
                  ...
         </instrs>
         <locals> ListItem(<i32> OFFSET) </locals>
         <prevBlockRandomSeed> SEED </prevBlockRandomSeed>

 // extern int32_t   validateTokenIdentifier(void* context, int32_t tokenIdHandle);
   rule <instrs> hostCall("env", "validateTokenIdentifier", [ i32 .ValTypes ] -> [ i32 .ValTypes ])
              => i32 . const #bool( #validateToken(TokId) )
                 ...
        </instrs>
        <locals> ListItem(<i32> ID_IDX) </locals>
        <bufferHeap> ... ID_IDX |-> TokId ... </bufferHeap>

  // TODO check arguments and handle errors if any
  // TODO handle Callee is not a contract
    syntax InternalInstr ::= #transferESDTNFTExecuteWithTypedArgs(BytesResult, ListResult, Int, BytesResult, ListBytesResult)
 // -------------------------------------------------------------------------------------------
    rule <instrs> #transferESDTNFTExecuteWithTypedArgs(Dest, Transfers, _GasLimit, b"", _Args)
               => #waitCommands
               ~> i32.const 0
                  ...
         </instrs>
         <callee> Callee </callee>
         <commands> (.K => transferESDTs(Callee, Dest, Transfers)) ... </commands>

    rule [transfer-esdt-and-execute]:
        <instrs> #transferESDTNFTExecuteWithTypedArgs(Dest, Transfers, GasLimit, Func, Args)
              => #executeOnDestContext(Dest, 0, Transfers, GasLimit, Func, Args)
                 ...
        </instrs>
      requires 0 <Int lengthBytes(Func)

  // TODO check arguments and handle errors if any
    syntax InternalInstr ::= #transferValueExecuteWithTypedArgs(BytesResult, IntResult, Int, BytesResult, ListBytesResult)
 // -------------------------------------------------------------------------------------------
    rule <instrs> #transferValueExecuteWithTypedArgs(Dest, Value, _GasLimit, b"", _Args)
               => #waitCommands
               ~> i32.const 0
                  ...
         </instrs>
         <callee> Callee </callee>
         <commands> (.K => transferFunds(Callee, Dest, Value)) ... </commands>

    rule [transfer-and-execute]:
        <instrs> #transferValueExecuteWithTypedArgs(Dest, Value, GasLimit, Func, Args)
              => #executeOnDestContext(Dest, Value, .List, GasLimit, Func, Args)
                 ...
        </instrs>
      requires 0 <Int lengthBytes(Func)

    syntax InternalInstr ::= #executeOnDestContextWithTypedArgs(
        BytesResult, IntResult, ListResult, Int, BytesResult, ListBytesResult)
 // ----------------------------------------------------------------------------
    rule [executeOnDestContextWithTypedArgs]:
        <instrs> #executeOnDestContextWithTypedArgs(
          Dest:Bytes, Value:Int, Esdt:List, Gas:Int, Func:Bytes, Args:ListBytes)
              => #executeOnDestContext(Dest, Value, Esdt, Gas, Func, Args)
                 ...
        </instrs>

    syntax InternalInstr ::= #executeOnDestContext(Bytes, Int, List, Int, Bytes, ListBytes)
 // -----------------------------------------------------------------------------------------
    rule [executeOnDestContext]:
        <instrs> #executeOnDestContext(Dest, Value, Esdt, GasLimit, Func, Args)
              => #waitCommands
              ~> #finishExecuteOnDestContext
                 ...
        </instrs>
        <callee> Callee </callee>
        <txHash> HASH </txHash>
        <commands> 
          (.K => callContract( Dest, Bytes2String(Func), 
                               prepareIndirectContractCallInput(Callee, Value, Esdt, GasLimit, Args, HASH))) ... 
        </commands>
        // TODO requires not IsOutOfVMFunctionExecution
        

    syntax VmInputCell ::= prepareIndirectContractCallInput(Bytes, Int, List, Int, ListBytes, Bytes)   [function, total]
 // -----------------------------------------------------------------------------------
    rule prepareIndirectContractCallInput(SENDER, VALUE, ESDT, GASLIMIT, ARGS, HASH)
      => <vmInput>
            <caller> SENDER </caller>
            <callArgs> ARGS </callArgs>
            <callValue> VALUE </callValue>
            <callType> DirectCall </callType>
            <esdtTransfers> ESDT </esdtTransfers>
            // gas
            <gasProvided> GASLIMIT </gasProvided>
            <gasPrice> 0 </gasPrice>
            <txHash> HASH </txHash>
          </vmInput>

```

`#finishExecuteOnDestContext` takes the VM output returned from the callee, and applies to the caller's context.
If the call is successful; outputs and logs in the VM output are merged to the caller's output and logs.
If the result is a failure; `resolveErrorFromOutput` throws a new exception.

```k
    syntax InternalInstr ::= "#finishExecuteOnDestContext"  [symbol(finishExecuteOnDestContext)]
 // ------------------------------------------------------
    rule [finishExecuteOnDestContext-ok]:
        <instrs> #finishExecuteOnDestContext
              => i32.const 0
                 ...
        </instrs>
        <vmOutput>
          VMOutput( ... returnCode: OK , out: OUTPUT, logs: LOGS, outputAccounts: OA2 ) => .VMOutput
        </vmOutput>
        // merge outputs
        <out> ... (.ListBytes => OUTPUT) </out>
        <logs> ... (.List => LOGS) </logs>
        <outputAccounts> OA => updateMap(OA, OA2) </outputAccounts> // TODO concat common items
 
    rule [finishExecuteOnDestContext-exception]:
        <instrs> #finishExecuteOnDestContext
              => resolveErrorFromOutput(EC, MSG)
                 ...
        </instrs>
        <vmOutput>
          VMOutput( ... returnCode: EC:ExceptionCode, returnMessage: MSG ) => .VMOutput
        </vmOutput>

    // FIXME This does not always return correct codes/messages
    syntax InternalInstr ::= resolveErrorFromOutput(ExceptionCode, Bytes) [function, total]
 // -----------------------------------------------------------------------
    rule resolveErrorFromOutput(ExecutionFailed, b"memory limit reached")
        => #throwExceptionBs(ExecutionFailed, b"execution failed")

    rule resolveErrorFromOutput(FunctionNotFound, MSG)
        => #throwExceptionBs(ExecutionFailed, MSG)

    rule resolveErrorFromOutput(UserError, MSG)
        => #throwExceptionBs(ExecutionFailed, #if MSG ==K b"action is not allowed"
                                              #then MSG
                                              #else b"error signalled by smartcontract" #fi)

    rule resolveErrorFromOutput(OutOfFunds, _)
        => #throwExceptionBs(ExecutionFailed, b"failed transfer (insufficient funds)")

    rule resolveErrorFromOutput(EC, MSG)
        => #throwExceptionBs(EC, MSG)
        [owise]
    
    rule [cleanReturnData]:
        <instrs> hostCall ( "env" , "cleanReturnData" , [ .ValTypes ] -> [ .ValTypes ] ) => .K ... </instrs>
        <out> _ => .ListBytes </out>

```

## Async Calls

```k
    syntax InternalInstr ::= #createAsyncCallWithTypedArgs(
                                dest: BytesResult,
                                value: IntResult,
                                func: BytesResult,
                                args: ListBytesResult,
                                gas: Int,
                                extraGasForCallBack: Int,
                                callbackClosure: BytesResult)
 // ----------------------------------------------------------------------------
    rule [createAsyncCallWithTypedArgs]:
        <instrs> #createAsyncCallWithTypedArgs(
                    DEST:Bytes,
                    VALUE:Int,
                    FUNC:Bytes,
                    ARGS:ListBytes,
                    GAS:Int,
                    _GAS_CB:Int,
                    CB_CLOSURE:Bytes)
              => #waitCommands
              ~> i32.const 0
                 ...
        </instrs>
        <bytesStack> ERROR_CB : SUCC_CB : S => S </bytesStack>
        <commands>
          (.K => #registerAsyncCall(#asyncCall( ...
                      dest: DEST,
                      func: Bytes2String(FUNC),
                      args: ARGS,
                      valueBytes: Int2Bytes(VALUE, BE, Unsigned),
                      successCallback: Bytes2String(SUCC_CB),
                      errorCallback: Bytes2String(ERROR_CB),
                      gas: GAS,
                      closure: CB_CLOSURE
                    ) ) ) ...
        </commands>

endmodule
```
