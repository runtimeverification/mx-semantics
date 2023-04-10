Base Operations
===============

Go implementation: [mx-chain-vm-go/vmhost/vmhooks/baseOps.go](https://github.com/multiversx/mx-chain-vm-go/blob/ea3d78d34c35f7ef9c1a9ea4fce8288608763229/vmhost/vmhooks/baseOps.go)

```k
require "../elrond-config.md"

module BASEOPS
     imports ELROND-CONFIG
     imports EEI-HELPERS

    // extern void getSCAddress(void *context, int32_t resultOffset);
    rule <instrs> hostCall("env", "getSCAddress", [ i32  .ValTypes ] -> [ .ValTypes ])
               => #memStore(RESULTOFFSET, CALLEE)
                  ...
         </instrs>
         <locals>
           0 |-> <i32> RESULTOFFSET
         </locals>
         <callee> CALLEE </callee>

    // extern int32_t isSmartContract(void *context, int32_t addressOffset);
    rule <instrs> hostCall("env", "isSmartContract", [ i32 .ValTypes ] -> [ i32 .ValTypes ])
               => #memLoad(ADDROFFSET, 32)
               ~> #checkIsSmartContract
                  ...
         </instrs>
         <locals>
           0 |-> <i32> ADDROFFSET
         </locals>

    syntax InternalInstr ::= "#checkIsSmartContract"
 // ------------------------------------------------
    rule <instrs> #checkIsSmartContract => i32.const 1 ... </instrs>
         <bytesStack> ADDR : STACK => STACK </bytesStack>
         <account>
           <address> ADDR </address>
           <codeIdx> _:Int </codeIdx>
           ...
         </account>

    rule <instrs> #checkIsSmartContract => i32.const 0 ... </instrs>
         <bytesStack> ADDR : STACK => STACK </bytesStack>
         <account>
           <address> ADDR </address>
           <codeIdx> .CodeIndex </codeIdx>
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
           0 |-> <i32> ADDROFFSET
           1 |-> <i32> RESULTOFFSET
         </locals>

    syntax InternalInstr ::= "#getExternalBalance"
 // ----------------------------------------------
    rule <instrs> #getExternalBalance => . ... </instrs>
         <bytesStack> ADDR : STACK => Int2Bytes(BAL, BE, Unsigned) : STACK </bytesStack>
         <account>
           <address> ADDR </address>
           <balance> BAL </balance>
           ...
         </account>

    // extern int32_t transferValue(void *context, int32_t dstOffset, int32_t valueOffset, int32_t dataOffset, int32_t length);
    rule <instrs> hostCall("env", "transferValue", [ i32 i32 i32 i32 .ValTypes ] -> [ i32 .ValTypes ])
               => #memLoad(DSTOFFSET, 32)
               ~> #memLoad(VALUEOFFSET, 32)
               ~> #memLoad(DATAOFFSET, LENGTH)
               ~> #transferValue
                  ...
         </instrs>
         <locals>
           0 |-> <i32> DSTOFFSET
           1 |-> <i32> VALUEOFFSET
           2 |-> <i32> DATAOFFSET
           3 |-> <i32> LENGTH
         </locals>

    syntax InternalInstr ::= "#transferValue"
                           | "#waitForTransfer"
 // -------------------------------------------
    rule <commands> (. => transferFunds(CALLEE, DEST, Bytes2Int(VALUE, BE, Unsigned))) ... </commands>
         <instrs> #transferValue => #waitForTransfer ~> i32.const 0 ... </instrs>
         <callee> CALLEE </callee>
         <bytesStack> _DATA : VALUE : DEST : STACK => STACK </bytesStack>

    rule <commands> #transferSuccess => . ... </commands>
         <instrs> #waitForTransfer => . ... </instrs>

    // extern int32_t getArgumentLength(void *context, int32_t id);
    rule <instrs> hostCall("env", "getArgumentLength", [ i32 .ValTypes ] -> [ i32 .ValTypes ]) => i32.const lengthBytes({ARGS[IDX]}:>Bytes) ... </instrs>
         <locals> 0 |-> <i32> IDX </locals>
         <callArgs> ARGS </callArgs>
      requires IDX <Int size(ARGS)
       andBool isBytes(ARGS[IDX])

    // extern int32_t getArgument(void *context, int32_t id, int32_t argOffset);
    rule <instrs> hostCall("env", "getArgument", [ i32 i32 .ValTypes ] -> [ i32 .ValTypes ])
               => #memStore(OFFSET, {ARGS[IDX]}:>Bytes)
               ~> i32.const lengthBytes({ARGS[IDX]}:>Bytes)
                  ...
         </instrs>
         <locals>
           0 |-> <i32> IDX
           1 |-> <i32> OFFSET
         </locals>
         <callArgs> ARGS </callArgs>
      requires IDX <Int size(ARGS)
       andBool isBytes(ARGS[IDX])

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
           0 |-> <i32> KEYOFFSET
           1 |-> <i32> KEYLENGTH
           2 |-> <i32> VALOFFSET
           3 |-> <i32> VALLENGTH
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
           0 |-> <i32> KEYOFFSET
           1 |-> <i32> KEYLENGTH
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
           0 |-> <i32> KEYOFFSET
           1 |-> <i32> KEYLENGTH
           2 |-> <i32> VALOFFSET
         </locals>

    // extern void getCaller(void *context, int32_t resultOffset);
    rule <instrs> hostCall("env", "getCaller", [ i32 .ValTypes ] -> [ .ValTypes ])
               => #memStore(OFFSET, CALLER)
                  ...
         </instrs>
         <locals> 0 |-> <i32> OFFSET </locals>
         <caller> CALLER </caller>

    // extern void checkNoPayment(void *context);
    rule <instrs> hostCall("env", "checkNoPayment", [ .ValTypes ] -> [ .ValTypes ]) => . ... </instrs>
         <callValue> 0 </callValue>
         <esdtTransfers> .List </esdtTransfers>

    // extern int32_t getESDTTokenName(void *context, int32_t resultOffset);
    rule <instrs> hostCall("env", "getESDTTokenName", [ i32 .ValTypes ] -> [ i32 .ValTypes ])
               => #memStore(OFFSET, TOKENNAME)
               ~> i32.const lengthBytes(TOKENNAME)
                  ...
         </instrs>
         <locals> 0 |-> <i32> OFFSET </locals>
         <esdtTransfers> ListItem( esdtTransfer( TOKENNAME , _VALUE , _NONCE ) ) </esdtTransfers>

    // extern int32_t   getNumESDTTransfers(void* context);
    rule <instrs> hostCall ( "env" , "getNumESDTTransfers" , [ .ValTypes ] -> [ i32  .ValTypes ] )
               => i32.const size( TS )
                  ...
         </instrs>
         <esdtTransfers> TS </esdtTransfers>
 
    // extern void writeEventLog(void *context, int32_t numTopics, int32_t topicLengthsOffset, int32_t topicOffset, int32_t dataOffset, int32_t dataLength);
    rule <instrs> hostCall("env", "writeEventLog", [ i32 i32 i32 i32 i32 .ValTypes ] -> [ .ValTypes ])
               => #getArgsFromMemory(NUMTOPICS, TOPICLENGTHOFFSET, TOPICOFFSET)
               ~> #memLoad(DATAOFFSET, DATALENGTH)
               ~> #writeLog
                  ...
         </instrs>
         <locals>
           0 |-> <i32> NUMTOPICS
           1 |-> <i32> TOPICLENGTHOFFSET
           2 |-> <i32> TOPICOFFSET
           3 |-> <i32> DATAOFFSET
           4 |-> <i32> DATALENGTH
         </locals>
 
    // extern void returnData(void* context, int32_t dataOffset, int32_t length);
    rule <instrs> hostCall("env", "finish", [ i32 i32 .ValTypes ] -> [ .ValTypes ])
               => #returnData(OFFSET, LENGTH)
                  ...
         </instrs>
         <locals>
           0 |-> <i32> OFFSET
           1 |-> <i32> LENGTH
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
           0 |-> <i32> OFFSET
           1 |-> <i32> LENGTH
         </locals>
 
    syntax InternalInstr ::= "#signalError"
 // ---------------------------------------
    rule <commands> (. => #exception(UserError)) ... </commands>
         <instrs> (#signalError ~> _) => . </instrs>
         <bytesStack> DATA : STACK => STACK </bytesStack>
         <message> MSG => MSG +Bytes DATA </message>

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
         <locals> 0 |-> <i32> OFFSET </locals>
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
         <locals> 0 |-> <i32> OFFSET </locals>
         <prevBlockRandomSeed> SEED </prevBlockRandomSeed>

 // extern int32_t   validateTokenIdentifier(void* context, int32_t tokenIdHandle);
   rule <instrs> hostCall("env", "validateTokenIdentifier", [ i32 .ValTypes ] -> [ i32 .ValTypes ])
              => i32 . const #bool( #validateToken(TokId) )
                 ...
        </instrs>
        <locals> 0 |-> <i32> ID_IDX </locals>
        <bufferHeap> ... ID_IDX |-> TokId ... </bufferHeap>

  // TODO implement contract call after ESDT transfer
    syntax InternalInstr ::= #transferESDTNFTExecuteWithTypedArgs(Bytes, List, Int, Bytes, List)
 // -------------------------------------------------------------------------------------------
    rule <instrs> #transferESDTNFTExecuteWithTypedArgs(Dest, Transfers, _GasLimit, b"", _Data)
               => #waitForTransfer
               ~> i32.const 0
                  ...
         </instrs>
         <callee> Callee </callee>
         <commands> (. => transferESDTs(Callee, Dest, Transfers)) ... </commands>


  // TODO implement contract call after transfer
    syntax InternalInstr ::= #transferValueExecuteWithTypedArgs(Bytes, Int, Int, Bytes, List)
 // -------------------------------------------------------------------------------------------
    rule <instrs> #transferValueExecuteWithTypedArgs(Dest, Value, _GasLimit, b"", _Data)
               => #waitForTransfer
               ~> i32.const 0
                  ...
         </instrs>
         <callee> Callee </callee>
         <commands> (. => transferFunds(Callee, Dest, Value)) ... </commands>

```

The (incorrect) default implementation of a host call is to just return zero values of the correct type.

```k
    // TODO implement asyncCall
    rule <instrs> hostCall("env", "asyncCall", [ DOM ] -> [ CODOM ]) => . ... </instrs>
         <valstack> VS => #zero(CODOM) ++ #drop(lengthValTypes(DOM), VS) </valstack>
endmodule

module EEI-HELPERS
  imports BOOL
  imports INT
  imports BYTES
  imports STRING

  syntax Int ::= "#tickerMinLen"                 [macro]
               | "#tickerMaxLen"                 [macro]
               | "#randomCharsLen"               [macro]
               | "#idMinLen"                     [macro]
               | "#idMaxLen"                     [macro]

  rule #tickerMinLen    => 3
  rule #tickerMaxLen    => 10
  rule #randomCharsLen  => 6
  rule #idMinLen        => 10
  rule #idMaxLen        => 17

  syntax Bool ::= #validateToken( Bytes )                [function, total]
 // -----------------------------------------------------------------
  rule #validateToken(Bs) => false requires lengthBytes(Bs) <Int #idMinLen
                                     orBool lengthBytes(Bs) >Int #idMaxLen
  rule #validateToken(Bs) => #isTickerValid( #getTicker(Bs) ) 
                     andBool #randomCharsAreValid( #getRandomChars(Bs) )
                     andBool Bs[(lengthBytes(Bs) -Int #randomCharsLen) -Int 1 ] ==Int ordChar("-")
                              requires lengthBytes(Bs) >=Int #idMinLen
                               andBool lengthBytes(Bs) <=Int #idMaxLen

  syntax Bytes ::= #getTicker(Bytes)                    [function, total]
                 | #getRandomChars(Bytes)               [function, total]
 // ------------------------------------------------------------------------------------
  rule #getTicker(Bs) => substrBytes(Bs, 0, lengthBytes(Bs) -Int #randomCharsLen -Int 1) 
    requires lengthBytes(Bs) >=Int #randomCharsLen
  rule #getRandomChars(Bs) => substrBytes(Bs, lengthBytes(Bs) -Int #randomCharsLen, lengthBytes(Bs))
    requires lengthBytes(Bs) >=Int #randomCharsLen
  // make the functions total
  rule #getTicker(Bs) => .Bytes
    requires lengthBytes(Bs) <Int #randomCharsLen
  rule #getRandomChars(Bs) => .Bytes
    requires lengthBytes(Bs) <Int #randomCharsLen


  syntax Bool ::= #isTickerValid( Bytes )                [function, total]
 // ----------------------------------------------------------------------
  rule #isTickerValid(Ticker) => false
    requires lengthBytes(Ticker) <Int #tickerMinLen
      orBool lengthBytes(Ticker) >Int #tickerMaxLen
  rule #isTickerValid(Ticker) => #allReadable(Ticker, 0)
    requires lengthBytes(Ticker) >=Int #tickerMinLen
      orBool lengthBytes(Ticker) <=Int #tickerMaxLen
  
  syntax Bool ::= #allReadable(Bytes, Int)       [function, total]
                | #readableChar(Int)             [function, total]
 // ---------------------------------------------------------
  rule #allReadable(Bs, Ix) => #readableChar(Bs[Ix]) andBool #allReadable(Bs, Ix +Int 1)   
                                            requires Ix <Int lengthBytes(Bs) andBool Ix >=Int 0
  rule #allReadable(Bs, Ix) => true         requires Ix >=Int lengthBytes(Bs)
  rule #allReadable(_Bs, Ix => 0)           requires Ix <Int 0

  rule #readableChar(X) => ( X >=Int ordChar("A") andBool X <=Int ordChar("Z") )
                    orBool ( X >=Int ordChar("0") andBool X <=Int ordChar("9") )


  syntax Bool ::= #randomCharsAreValid(Bytes)     [function, total]
 // ---------------------------------------------------------------
  rule #randomCharsAreValid(Bs) => false                      requires lengthBytes(Bs) =/=Int #randomCharsLen
  rule #randomCharsAreValid(Bs) => #allValidRandom(Bs, 0)     requires lengthBytes(Bs) ==Int #randomCharsLen
  
  syntax Bool ::= #allValidRandom(Bytes, Int)       [function, total]
                | #validRandom(Int)                 [function, total]
 // ---------------------------------------------------------
  rule #allValidRandom(Bs, Ix) => #validRandom(Bs[Ix]) andBool #allValidRandom(Bs, Ix +Int 1)   
                                               requires Ix <Int lengthBytes(Bs) andBool Ix >=Int 0
  rule #allValidRandom(Bs, Ix) => true         requires Ix >=Int lengthBytes(Bs)
  rule #allValidRandom(_Bs, Ix => 0)           requires Ix <Int 0

  rule #validRandom(X) => ( X >=Int ordChar("a") andBool X <=Int ordChar("f") )
                   orBool ( X >=Int ordChar("0") andBool X <=Int ordChar("9") )

endmodule
```