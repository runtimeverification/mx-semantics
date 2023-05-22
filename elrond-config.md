Elrond Configuration
====================

Combine Elrond node with Wasm.

```k
require "auto-allocate.md"
require "blockchain-k-plugin/krypto.md"
require "elrond-node.md"
require "wasm-text.md"
require "wasm-coverage.md"

module ELROND-CONFIG
    imports KRYPTO
    imports WASM-COVERAGE
    imports WASM-AUTO-ALLOCATE
    imports ELROND-NODE

    configuration
      <elrond>
        <wasmCoverage/>
        <node/>
        <logging> "" </logging>
      </elrond>
```

## Helper Functions

### Misc

```k
    syntax Bool ::= #hasPrefix ( String , String ) [function, total]
 // ---------------------------------------------------------------------
    rule #hasPrefix(STR, PREFIX) => true
      requires lengthString(STR) >=Int lengthString(PREFIX)
       andBool substrString(STR, 0, lengthString(PREFIX)) ==String PREFIX

    rule #hasPrefix(STR, PREFIX) => false
      requires notBool (       lengthString(STR) >=Int lengthString(PREFIX)
                       andBool substrString(STR, 0, lengthString(PREFIX)) ==String PREFIX)
```

### Memory

```k
    syntax InternalInstr ::= #memStoreFromBytesStack ( Int )
                           | #memStore ( offset: Int , bytes: Bytes )
 // -----------------------------------------------------------------
    rule <instrs> #memStoreFromBytesStack(OFFSET) => #memStore(OFFSET, BS) ... </instrs>
         <bytesStack> BS : _ </bytesStack>

    rule <instrs> #memStore(OFFSET, _) 
               => #throwException(ExecutionFailed, "bad bounds (lower)") ... 
         </instrs>
      requires #signed(i32 , OFFSET) <Int 0

    rule <instrs> #memStore(OFFSET, BS) 
               => #throwException(ExecutionFailed, "bad bounds (upper)") ... 
         </instrs>
         <contractModIdx> MODIDX:Int </contractModIdx>
         <moduleInst>
           <modIdx> MODIDX </modIdx>
           <memAddrs> 0 |-> MEMADDR </memAddrs>
           ...
         </moduleInst>
         <memInst>
           <mAddr> MEMADDR </mAddr>
           <msize> SIZE </msize>
           ...
         </memInst>
      requires 0 <=Int #signed(i32 , OFFSET)
       andBool #signed(i32 , OFFSET) +Int lengthBytes(BS) >Int (SIZE *Int #pageSize())

    rule <instrs> #memStore(OFFSET, BS) => . ... </instrs>
         <contractModIdx> MODIDX:Int </contractModIdx>
         <moduleInst>
           <modIdx> MODIDX </modIdx>
           <memAddrs> 0 |-> MEMADDR </memAddrs>
           ...
         </moduleInst>
         <memInst>
           <mAddr> MEMADDR </mAddr>
           <msize> SIZE </msize>
           <mdata> DATA => #setBytesRange(DATA, OFFSET, BS) </mdata>
           ...
         </memInst>
      requires #signed(i32 , OFFSET) +Int lengthBytes(BS) <=Int (SIZE *Int #pageSize())
       andBool 0 <=Int #signed(i32 , OFFSET)

    syntax InternalInstr ::= #memLoad ( offset: Int , length: Int )
 // ---------------------------------------------------------------

    rule <instrs> #memLoad(_, LENGTH) => #throwException(ExecutionFailed, "mem load: negative length") ... </instrs>
      requires #signed(i32 , LENGTH) <Int 0

    rule <instrs> #memLoad(OFFSET, LENGTH) => #throwException(ExecutionFailed, "mem load: bad bounds") ... </instrs>
         <contractModIdx> MODIDX:Int </contractModIdx>
         <moduleInst>
           <modIdx> MODIDX </modIdx>
           <memAddrs> 0 |-> MEMADDR </memAddrs>
           ...
         </moduleInst>
         <memInst>
           <mAddr> MEMADDR </mAddr>
           <msize> SIZE </msize>
           ...
         </memInst>
      requires #signed(i32 , LENGTH) >=Int 0
       andBool (#signed(i32 , OFFSET) <Int 0
         orBool #signed(i32 , OFFSET) +Int #signed(i32 , LENGTH) >Int (SIZE *Int #pageSize()))

    rule <instrs> #memLoad(OFFSET, LENGTH) => . ... </instrs>
         <bytesStack> STACK => #getBytesRange(DATA, OFFSET, LENGTH) : STACK </bytesStack>
         <contractModIdx> MODIDX:Int </contractModIdx>
         <moduleInst>
           <modIdx> MODIDX </modIdx>
           <memAddrs> 0 |-> MEMADDR </memAddrs>
           ...
         </moduleInst>
         <memInst>
           <mAddr> MEMADDR </mAddr>
           <msize> SIZE </msize>
           <mdata> DATA </mdata>
           ...
         </memInst>
      requires #signed(i32 , LENGTH) >=Int 0
       andBool #signed(i32 , OFFSET) >=Int 0
       andBool #signed(i32 , OFFSET) +Int #signed(i32 , LENGTH) <=Int (SIZE *Int #pageSize())
```

### Storage

Storing a value returns a status code indicating if and how the storage was modified.

TODO: Implement [reserved keys and read-only runtimes](https://github.com/ElrondNetwork/arwen-wasm-vm/blob/d6ea0489081f81fefba002609c34ece1365373dd/arwen/contexts/storage.go#L111).

```k
    syntax InternalInstr ::= "#storageStore"
 // ----------------------------------------
    rule <instrs> #storageStore => #setStorage(KEY, VALUE) ... </instrs>
         <bytesStack> VALUE : KEY : STACK => STACK </bytesStack>

    syntax InternalInstr ::= #setStorage ( Bytes , Bytes )
 // ------------------------------------------------------
    rule <instrs> #setStorage(KEY, VALUE)
               => #isReservedKey(Bytes2String(KEY))
               ~> #writeToStorage(KEY, VALUE)
                  ...
         </instrs>

    syntax InternalInstr ::= #writeToStorage ( Bytes , Bytes )
 // ----------------------------------------------------------
    rule <instrs> #writeToStorage(KEY, VALUE) => i32.const #storageStatus(STORAGE, KEY, VALUE) ... </instrs>
         <callee> CALLEE </callee>
         <account>
           <address> CALLEE </address>
           <storage> STORAGE => #updateStorage(STORAGE, KEY, VALUE) </storage>
           ...
         </account>

    syntax InternalInstr ::= #isReservedKey ( String )
 // --------------------------------------------------
    rule <instrs> #isReservedKey(KEY) => . ... </instrs>
      requires notBool #hasPrefix(KEY, "ELROND")

    rule <instrs> #isReservedKey(KEY)
               => #throwException(UserError, "cannot write to storage under Elrond reserved key") ...
         </instrs>
      requires         #hasPrefix(KEY, "ELROND")

    syntax InternalInstr ::= "#storageLoad"
                           | "#storageLoadFromAddress"
 // ---------------------------------------
    rule <instrs> #storageLoad => . ... </instrs>
         <bytesStack> KEY : STACK => #lookupStorage(STORAGE, KEY) : STACK </bytesStack>
         <callee> CALLEE </callee>
         <account>
           <address> CALLEE </address>
           <storage> STORAGE </storage>
           ...
         </account>
         requires #lookupStorageDefined(STORAGE, KEY)

    rule <instrs> #storageLoadFromAddress => . ... </instrs>
         <bytesStack> ADDR : KEY : STACK => #lookupStorage(STORAGE, KEY) : STACK </bytesStack>
         <account>
           <address> ADDR </address>
           <storage> STORAGE </storage>
           ...
         </account>
         requires #lookupStorageDefined(STORAGE, KEY)

    syntax Map ::= #updateStorage ( Map , key : Bytes , val : Bytes ) [function, total]
 // ----------------------------------------------------------------------------------------
    rule #updateStorage(STOR, KEY, VAL) => STOR [KEY <- undef] requires VAL  ==K .Bytes
    rule #updateStorage(STOR, KEY, VAL) => STOR [KEY <- VAL  ] requires VAL =/=K .Bytes

    syntax Bytes ::= #lookupStorage ( Map , key: Bytes ) [function]
 // ---------------------------------------------------------------
    rule #lookupStorage(STORAGE, KEY) => {STORAGE[KEY]}:>Bytes
      requires         KEY in_keys(STORAGE)
       andBool isBytes(STORAGE[KEY])

    rule #lookupStorage(STORAGE, KEY) => .Bytes
      requires notBool KEY in_keys(STORAGE)

    syntax Bool ::= #lookupStorageDefined( Map , Bytes )       [function, total]
 // -----------------------------------------------------------------------------------
    rule #lookupStorageDefined(STORAGE, KEY) => notBool( KEY in_keys(STORAGE) )
                                         orBool isBytes(STORAGE[KEY] orDefault .Bytes) 

    syntax Int ::= #storageStatus ( Map , key : Bytes , val : Bytes ) [function, total]
                 | #StorageUnmodified () [function, total]
                 | #StorageModified   () [function, total]
                 | #StorageAdded      () [function, total]
                 | #StorageDeleted    () [function, total]
 // -----------------------------------------------------------
    rule #storageStatus(STOR, KEY,  VAL) => #StorageUnmodified() requires VAL  ==K .Bytes andBool notBool KEY in_keys(STOR)
    rule #storageStatus(STOR, KEY,  VAL) => #StorageUnmodified() requires VAL =/=K .Bytes andBool         KEY in_keys(STOR) andBool STOR[KEY]  ==K VAL
    rule #storageStatus(STOR, KEY,  VAL) => #StorageModified  () requires VAL =/=K .Bytes andBool         KEY in_keys(STOR) andBool STOR[KEY] =/=K VAL
    rule #storageStatus(STOR, KEY,  VAL) => #StorageAdded     () requires VAL =/=K .Bytes andBool notBool KEY in_keys(STOR)
    rule #storageStatus(STOR, KEY,  VAL) => #StorageDeleted   () requires VAL  ==K .Bytes andBool         KEY in_keys(STOR)

    rule #StorageUnmodified() => 0
    rule #StorageModified  () => 1
    rule #StorageAdded     () => 2
    rule #StorageDeleted   () => 3
```


### Integer Operation

```k
    syntax Int ::= #cmpInt ( Int , Int ) [function, total]
 // -----------------------------------------------------------
    rule #cmpInt(I1, I2) => -1 requires I1  <Int I2
    rule #cmpInt(I1, I2) =>  1 requires I1  >Int I2
    rule #cmpInt(I1, I2) =>  0 requires I1 ==Int I2

    syntax Int ::= #bigIntSign ( Int ) [function, total]
 // ---------------------------------------------------------
    rule #bigIntSign(I) => 0  requires I ==Int 0
    rule #bigIntSign(I) => 1  requires I >Int 0
    rule #bigIntSign(I) => -1 requires I <Int 0

    syntax Int ::= "minSInt32"         [macro]
                 | "maxSInt32"         [macro]
                 | "minUInt32"         [macro]
                 | "maxUInt32"         [macro]
                 | "minSInt64"         [macro]
                 | "maxSInt64"         [macro]
                 | "minUInt64"         [macro]
                 | "maxUInt64"         [macro]
 // --------------------------
    rule minSInt32 => -2147483648            /* -2^31     */
    rule maxSInt32 =>  2147483647            /*  2^31 - 1 */
    rule minUInt32 =>  0                    
    rule maxUInt32 =>  4294967296            /*  2^32 - 1 */
    rule minSInt64 => -9223372036854775808   /* -2^63     */
    rule maxSInt64 =>  9223372036854775807   /*  2^63 - 1 */
    rule minUInt64 =>  0                    
    rule maxUInt64 =>  18446744073709551615  /*  2^64 - 1 */

    syntax InternalInstr ::= #returnIfUInt64 ( Int , String )
                           | #returnIfSInt64 ( Int , String )
 // ---------------------------------------------------------
    rule <instrs> #returnIfUInt64(V, _) => i64.const V ... </instrs>
      requires          minUInt64 <=Int V andBool V <=Int maxUInt64

    rule <instrs> #returnIfUInt64(V, ERRORMSG) 
               => #throwException(UserError, ERRORMSG) ... 
         </instrs>
      requires notBool (minUInt64 <=Int V andBool V <=Int maxUInt64)

    rule <instrs> #returnIfSInt64(V, _) => i64.const V ... </instrs>
      requires          minSInt64 <=Int V andBool V <=Int maxSInt64

    rule <instrs> #returnIfSInt64(V, ERRORMSG) 
               => #throwException(UserError, ERRORMSG) ... 
         </instrs>
      requires notBool (minSInt64 <=Int V andBool V <=Int maxSInt64)

    syntax InternalInstr ::= #loadBytesAsUInt64 ( String )
                           | #loadBytesAsSInt64 ( String )
 // ------------------------------------------------------
    rule <instrs> #loadBytesAsUInt64(ERRORMSG) => #returnIfUInt64(Bytes2Int(BS, BE, Unsigned), ERRORMSG) ... </instrs>
         <bytesStack> BS : STACK => STACK </bytesStack>

    rule <instrs> #loadBytesAsSInt64(ERRORMSG) => #returnIfSInt64(Bytes2Int(BS, BE, Signed), ERRORMSG) ... </instrs>
         <bytesStack> BS : STACK => STACK </bytesStack>
```

### Output

```k
    syntax InternalInstr ::= "#appendToOutFromBytesStack"
                           | #appendToOut ( Bytes )
 // -----------------------------------------------
    rule <instrs> #appendToOutFromBytesStack => . ... </instrs>
         <bytesStack> OUT : STACK => STACK </bytesStack>
         <out> ... (.List => ListItem(OUT)) </out>

    rule <instrs> #appendToOut(OUT) => . ... </instrs>
         <out> ... (.List => ListItem(OUT)) </out>
```

### Parsing

```k
    syntax String ::= #alignHexString ( String ) [function, total]
 // -------------------------------------------------------------------
    rule #alignHexString(S) => S             requires         lengthString(S) modInt 2 ==Int 0
    rule #alignHexString(S) => "0" +String S requires notBool lengthString(S) modInt 2 ==Int 0

    syntax Bytes ::= #parseHexBytes     ( String ) [function]
                   | #parseHexBytesAux  ( String ) [function]
 // ---------------------------------------------------------
    rule #parseHexBytes(S)  => #parseHexBytesAux(#alignHexString(S))
    rule #parseHexBytesAux("") => .Bytes
    rule #parseHexBytesAux(S)  => Int2Bytes(lengthString(S) /Int 2, String2Base(S, 16), BE)
      requires 2 <=Int lengthString(S)
```

### Log

```k
    syntax LogEntry ::= logEntry ( Bytes , Bytes , List , Bytes ) [klabel(logEntry), symbol]
 // ----------------------------------------------------------------------------------------

    syntax InternalInstr ::= #getArgsFromMemory    ( Int , Int , Int )
                           | #getArgsFromMemoryAux ( Int , Int , Int , Int , Int )
 // ------------------------------------------------------------------------------
    rule <instrs> #getArgsFromMemory(NUMARGS, LENGTHOFFSET, DATAOFFSET)
               => #getArgsFromMemoryAux(NUMARGS, 0, NUMARGS, LENGTHOFFSET, DATAOFFSET)
                  ...
         </instrs>
      requires 0 <=Int #signed(i32, NUMARGS)

    rule <instrs> #getArgsFromMemory(NUMARGS, _, _)
               => #throwException(ExecutionFailed, "negative numArguments") ...
         </instrs>
      requires #signed(i32, NUMARGS) <Int 0

    rule <instrs> #getArgsFromMemoryAux(NUMARGS, TOTALLEN, 0,  _, _)
               => i32.const TOTALLEN
               ~> i32.const NUMARGS
                  ...
         </instrs>

    rule <instrs> #getArgsFromMemoryAux(NUMARGS, TOTALLEN, COUNTER, LENGTHOFFSET, DATAOFFSET)
               => #memLoad(LENGTHOFFSET, 4)
               ~> #loadArgDataWithLengthOnStack(NUMARGS, TOTALLEN, COUNTER, LENGTHOFFSET, DATAOFFSET)
                  ...
         </instrs>
       requires 0 <Int COUNTER

    syntax InternalInstr ::= #loadArgDataWithLengthOnStack( Int , Int , Int , Int , Int )
                           | #loadArgData                 ( Int , Int , Int , Int , Int , Int )
 // -------------------------------------------------------------------------------------------
    rule <instrs> #loadArgDataWithLengthOnStack(NUMARGS, TOTALLEN, COUNTER, LENGTHOFFSET, DATAOFFSET)
               => #loadArgData(Bytes2Int(ARGLEN, LE, Unsigned), NUMARGS, TOTALLEN, COUNTER, LENGTHOFFSET, DATAOFFSET)
                  ...
         </instrs>
         <bytesStack> ARGLEN : STACK => STACK </bytesStack>


    rule <instrs> #loadArgData(ARGLEN, NUMARGS, TOTALLEN, COUNTER, LENGTHOFFSET, DATAOFFSET)
               => #memLoad(DATAOFFSET, ARGLEN)
               ~> #getArgsFromMemoryAux(NUMARGS, TOTALLEN +Int ARGLEN, COUNTER -Int 1, LENGTHOFFSET +Int 4, DATAOFFSET +Int ARGLEN)
                  ...
         </instrs>

    syntax InternalInstr ::= "#writeLog"
                           | #writeLogAux ( Int , List , Bytes )
 // ------------------------------------------------------------
    rule <instrs> #writeLog => #writeLogAux(NUMTOPICS, .List, DATA) ... </instrs>
         <bytesStack> DATA : STACK => STACK </bytesStack>
         <valstack> <i32> NUMTOPICS : <i32> _ : VALSTACK => VALSTACK </valstack>

    rule <instrs> #writeLogAux(1, TOPICS, DATA) => . ... </instrs>
         <bytesStack> IDENTIFIER : STACK => STACK </bytesStack>
         <callee> CALLEE </callee>
         <logs> ... (.List => ListItem(logEntry(CALLEE, IDENTIFIER, TOPICS, DATA))) </logs>

    rule <instrs> #writeLogAux(NUMTOPICS, TOPICS, DATA)
               => #writeLogAux(NUMTOPICS -Int 1, ListItem(TOPIC) TOPICS, DATA)
                  ...
         </instrs>
         <bytesStack> TOPIC : STACK => STACK </bytesStack>
       requires 1 <Int NUMTOPICS
```

## Node And Wasm VM Synchronization

- `#endWasm` waits for the Wasm VM to finish the execution and check the return code.
- `#waitWasm` waits for the Wasm VM to finish

TODO should VMOutputs be merged to the callstate after #endWasm? Contract A writes to <out>, then calls B. B writes to <out> as well. What should be the final output in VMOutputs? Also consider the failure case.

```k
    syntax InternalCmd ::= "#endWasm"
                         | "#waitWasm"
 // ---------------------------------
    rule <commands> #endWasm => popCallState ~> dropWorldState ... </commands>
         <instrs> . </instrs>
         <out> OUT </out>
         <logs> LOGS </logs>
         <vmOutput> .VMOutput => VMOutput( OK , .Bytes , OUT , LOGS) </vmOutput>
      [priority(60)]

    rule <commands> #waitWasm => . ... </commands>
         <instrs> . </instrs>
      [priority(60)]
```


## Exception Handling

- `#exception` drops the rest of the computation in the `commands` and `instrs` cells and reverts the state.

TODO confirm the error propagation mechanism. For example, A calls B, B calls C. Should A and B fail, too? What should be the resulting VMOutput? 

```k
    syntax InternalCmd ::= #exception ( ExceptionCode )
 // ---------------------------------------------------
    rule [exception-revert]:
        <commands> (#exception(_EC) ~> #endWasm) => dropCallState ~> popWorldState ... </commands>
      [priority(10)]
    
    rule [exception-skip]:
        <commands> #exception(_EC) ~> (CMD:InternalCmd => . ) ... </commands>
      requires CMD =/=K #endWasm
      [priority(10)]

    syntax InternalInstr ::= #throwException( ExceptionCode , String )
                           | #throwExceptionBs( ExceptionCode , Bytes )
 // ------------------------------------------------------------------
    rule [throwException]:
        <instrs> #throwException( EC , MSG )
              => #throwExceptionBs( EC , String2Bytes(MSG) ) ...
        </instrs>

    rule [throwExceptionBs]:
        <instrs> (#throwExceptionBs( EC , MSG ) ~> _ ) => . </instrs>
        <commands> (. => #exception(EC)) ... </commands>
        <out> OUT </out>
        <logs> LOGS </logs>
        <vmOutput> .VMOutput => VMOutput( EC , MSG , OUT , LOGS) </vmOutput>

```

## Managing Accounts

```k
    syntax InternalCmd ::= createAccount ( Bytes ) [klabel(createAccount), symbol]
 // ------------------------------------------------------------------------------
    // ignore if the account already exists
    rule <commands> createAccount(ADDR) => . ... </commands>
         <activeAccounts> ADDRs => ADDRs |Set SetItem(ADDR) </activeAccounts>
         <account>
           <address> ADDR </address>
           ...
         </account>
         <logging> S => S +String " -- initAccount duplicate " +String Bytes2String(ADDR) </logging>
      [priority(60)]

    rule <commands> createAccount(ADDR) => . ... </commands>
         <activeAccounts> ADDRs => ADDRs |Set SetItem(ADDR) </activeAccounts>
         <accounts>
           ( .Bag
          => <account>
               <address> ADDR </address>
               ...
             </account>
           )
           ...
         </accounts>
         <logging> S => S +String " -- initAccount new " +String Bytes2String(ADDR) </logging>
      [priority(61)]

    syntax InternalCmd ::= setAccountFields    ( Bytes, Int, Int, Code, Bytes, Map )
                         | setAccountCode      ( Bytes, Code )
                         | setAccountOwner     ( Bytes, Bytes )
 // ---------------------------------------------------------------
    rule <commands> setAccountFields(ADDR, NONCE, BALANCE, CODE, OWNER_ADDR, STORAGE) => . ... </commands>
         <account>
           <address> ADDR </address>
           <nonce> _ => NONCE </nonce>
           <balance> _ => BALANCE </balance>
           <code> _ => CODE </code>
           <ownerAddress> _ => OWNER_ADDR </ownerAddress>
           <storage> _ => STORAGE </storage>
           ...
         </account>
      [priority(60)]

    rule <commands> setAccountCode(ADDR, CODE) => . ... </commands>
         <account>
           <address> ADDR </address>
           <code> _ => CODE </code>
           ...
         </account>
      [priority(60)]

    rule <commands> setAccountOwner(ADDR, OWNER) => . ... </commands>
         <account>
           <address> ADDR </address>
           <ownerAddress> _ => OWNER </ownerAddress>
           ...
         </account>
      [priority(60)]
```

## Transfer Funds

```k
    syntax InternalCmd ::= transferFunds ( Bytes, Bytes, Int )
                         | transferESDT ( Bytes , Bytes , ESDTTransfer )
                         | transferESDTs ( Bytes , Bytes , List )
                         | "#transferSuccess"
 // -----------------------------------------
    rule <commands> transferFunds(ACCT, ACCT, VALUE) => #transferSuccess ... </commands>
         <account>
           <address> ACCT </address>
           <balance> ORIGFROM </balance>
           ...
         </account>
      requires VALUE <=Int ORIGFROM
      [priority(60)]

    rule <commands> transferFunds(ACCTFROM, ACCTTO, VALUE) => #transferSuccess ... </commands>
         <account>
           <address> ACCTFROM </address>
           <balance> ORIGFROM => ORIGFROM -Int VALUE </balance>
           ...
         </account>
         <account>
           <address> ACCTTO </address>
           <balance> ORIGTO => ORIGTO +Int VALUE </balance>
           ...
         </account>
      requires ACCTFROM =/=K ACCTTO andBool VALUE <=Int ORIGFROM
      [priority(60)]

    // transferESDTs performs multiple ESDT transfers and finally returns #transferSuccess
    // TODO handle failure if one of the transfers fails
    rule <commands> transferESDTs(_, _, .List) => #transferSuccess ... </commands>
    rule <commands> transferESDTs(FROM, TO, ListItem(T:ESDTTransfer) Ls) 
                 => transferESDT(FROM, TO, T) 
                 ~> transferESDTs(FROM, TO, Ls)
                    ... 
         </commands>
  
    // TODO handle failure cases
    // - insufficient balance
    // - frozen / paused / non-payable / limited transfer...
    // TODO implement NFT/SFT transfers
    rule <commands> transferESDT(ACCT, ACCT, esdtTransfer(TOKEN, VALUE, 0)) 
                 => . ... 
         </commands>
         <account>
           <address> ACCT </address>
           <esdtData>
             <esdtId> TOKEN </esdtId>
             <esdtBalance> ORIGFROM </esdtBalance>
             <frozen> false </frozen>
           </esdtData>
           ...
         </account>
      requires VALUE <=Int ORIGFROM
      [priority(60)]

    rule <commands> transferESDT(ACCTFROM, ACCTTO, esdtTransfer(TOKEN, VALUE, 0)) 
                 => . ... 
         </commands>
         <account>
           <address> ACCTFROM </address>
           <esdtData>
             <esdtId> TOKEN </esdtId>
             <esdtBalance> ORIGFROM => ORIGFROM -Int VALUE </esdtBalance>
             <frozen> false </frozen>
           </esdtData>
           ...
         </account>
         <account>
           <address> ACCTTO </address>
           <esdtData>
             <esdtId> TOKEN </esdtId>
             <esdtBalance> ORIGTO => ORIGTO +Int VALUE </esdtBalance>
             <frozen> false </frozen>
           </esdtData>
           ...
         </account>
      requires ACCTFROM =/=K ACCTTO andBool VALUE <=Int ORIGFROM
      [priority(60)]

    rule <commands> transferESDT(ACCTFROM, ACCTTO, esdtTransfer(TOKEN, VALUE, 0)) 
                 => . ... 
         </commands>
         <account>
           <address> ACCTFROM </address>
           <esdtData>
             <esdtId> TOKEN </esdtId>
             <esdtBalance> ORIGFROM => ORIGFROM -Int VALUE </esdtBalance>
             <frozen> false </frozen>
           </esdtData>
           ...
         </account>
         <account>
           <address> ACCTTO </address>
           (.Bag => <esdtData>
             <esdtId> TOKEN </esdtId>
             <esdtBalance> VALUE </esdtBalance>
             <frozen> false </frozen>
           </esdtData>)
           ...
         </account>
      requires ACCTFROM =/=K ACCTTO andBool VALUE <=Int ORIGFROM
      [priority(61)]

    rule <commands> #transferSuccess => . ... </commands>
         <instrs> . </instrs>
```

## Calling Contract

```k
    syntax InternalCmd ::= callContract ( Bytes, Bytes, Int, List,     String, List, Int, Int ) [klabel(callContractString)]
                         | callContract ( Bytes, Bytes, Int, List, WasmString, List, Int, Int ) [klabel(callContractWasmString)]
                         | mkCall       ( Bytes, Bytes, Int, List, WasmString, List, Int, Int )
 // -------------------------------------------------------------------------------------
    rule <commands> callContract(FROM, TO, VALUE, ESDT, FUNCNAME:String, ARGS, GASLIMIT, GASPRICE)
                 => callContract(FROM, TO, VALUE, ESDT, #unparseWasmString("\"" +String FUNCNAME +String "\""), ARGS, GASLIMIT, GASPRICE)
                    ...
         </commands>
      [priority(60)]

    // TODO compare with the EVM contract call implementation
    rule [callContract]:
        <commands> callContract(FROM, TO, VALUE, ESDT, FUNCNAME:WasmStringToken, ARGS, GASLIMIT, GASPRICE)
                => pushWorldState
                ~> pushCallState
                ~> transferFunds(FROM, TO, VALUE)
                ~> transferESDTs(FROM, TO, ESDT)
                ~> newWasmInstance(CODE)
                ~> mkCall(FROM, TO, VALUE, ESDT, FUNCNAME, ARGS, GASLIMIT, GASPRICE)
                ~> #endWasm
                   ...
        </commands>
        <account>
          <address> TO </address>
          <code> CODE </code>
          ...
        </account>
        <vmOutput> _ => .VMOutput </vmOutput>
        <logging> S => S +String " -- callContract " +String #parseWasmString(FUNCNAME) </logging>

      [priority(60)]

```

Every contract call runs in its own Wasm instance initialized with the contract's code.

```k
    syntax WasmCell
    syntax InternalCommand ::= newWasmInstance(ModuleDecl)
                             | "setContractModIdx"
 // ------------------------------------------------------
    rule [newWasmInstance]:
        <commands> newWasmInstance(CODE) => #waitWasm ~> setContractModIdx ...</commands>
        ( _:WasmCell => <wasm> 
          <instrs> initContractModule(CODE) </instrs>
          ...
        </wasm>)
    rule [setContractModIdx]:
        <commands> setContractModIdx => . ... </commands>
        <contractModIdx> _ => NEXTIDX -Int 1 </contractModIdx>
        <nextModuleIdx> NEXTIDX </nextModuleIdx>

    syntax K ::= initContractModule(ModuleDecl)   [function]
 // ------------------------------------------------------------------------
    rule initContractModule((module _:OptionalId _:Defns):ModuleDecl #as M) 
      => sequenceStmts(text2abstract(M .Stmts))

    rule initContractModule(M:ModuleDecl) => M              [owise]

    rule [mkCall]:
        <commands> mkCall(FROM, TO, VALUE, ESDT, FUNCNAME:WasmStringToken, ARGS, _GASLIMIT, _GASPRICE) => . ... </commands>
        <callState>
          // call input
          <caller> _ => FROM </caller>
          <callee> _ => TO   </callee>
          <callArgs> _ => ARGS </callArgs>
          <callValue> _ => VALUE </callValue>
          <esdtTransfers> _ => ESDT </esdtTransfers>
          // executional
          <wasm>
            <instrs> . => ( invoke FUNCADDR ) </instrs>
            <moduleInst>
              <modIdx> MODIDX </modIdx>
              <exports> ... FUNCNAME |-> FUNCIDX:Int </exports>
              <funcAddrs> ... FUNCIDX |-> FUNCADDR:Int ... </funcAddrs>
              ...
            </moduleInst>
            ...
          </wasm>
          <bigIntHeap> _ => .Map </bigIntHeap>
          <bufferHeap> _ => .Map </bufferHeap>
          <bytesStack> _ => .BytesStack </bytesStack>
          <contractModIdx> MODIDX:Int </contractModIdx>
          // output
          <out> _ => .List </out>
          <logs> _ => .List </logs>
        </callState>
      [priority(60)]

    rule [mkCall-func-not-found]:
        <commands> mkCall(_FROM, _TO, _VALUE, _ESDT, FUNCNAME:WasmStringToken, _ARGS, _GASLIMIT, _GASPRICE) => . ... </commands>
        <contractModIdx> MODIDX:Int </contractModIdx>
        <moduleInst>
          <modIdx> MODIDX </modIdx>
          <exports> EXPORTS </exports>
          ...
        </moduleInst>
        <instrs> . => #throwException(FunctionNotFound, "invalid function (not found)") </instrs>
        <logging> S => S +String " -- callContract not found " +String #parseWasmString(FUNCNAME) </logging>
      requires notBool( FUNCNAME in_keys(EXPORTS) )
      [priority(60)]

endmodule
```
