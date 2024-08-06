Elrond Configuration
====================

Combine Elrond node with Wasm.

```k

// TODO: #or patterns are currently not supported in the Booster backend. PR k#4363 aims to resolve
// this with a desugaring pass in the K frontend, but this solution may not handle rule labels properly.
// In PR #267, we worked around this by either duplicating rules or commenting out cells that contain #or patterns.
// The duplicated rules have labels ending with '-instrs-empty' and '-instrs-wait'.
//
// Once the issue with #or patterns is resolved in a way that supports rule labels,
// de-duplicate these rules and re-enable the commented-out #or patterns.
//
// K PR : https://github.com/runtimeverification/k/pull/4363
// K Issue: https://github.com/runtimeverification/k/issues/4355
// mx-semantics PR: https://github.com/runtimeverification/mx-semantics/pull/267

requires "vmhooks/async.md"
requires "wasm-semantics/wasm-text.md"
requires "plugin/krypto.md"
requires "auto-allocate.md"
requires "elrond-node.md"
requires "esdt.md"
requires "switch.md"
requires "wasm-semantics/wasm-text.md"

module ELROND-CONFIG
    imports ASYNC-HELPERS
    imports KRYPTO
    imports WASM-AUTO-ALLOCATE
    imports ELROND-NODE
    imports ESDT
    imports LIST-BYTES
    imports SWITCH

    configuration
      <elrond>
        <node/>
        <logging> "" </logging>
      </elrond>
```

## Helper Functions

### Misc

```k
    syntax Bool ::= #hasPrefix ( String , String ) [function, total]
 // ---------------------------------------------------------------------
    rule #hasPrefix(STR, PREFIX) => substrString(STR, 0, lengthString(PREFIX)) ==String PREFIX
      requires lengthString(STR) >=Int lengthString(PREFIX)

    rule #hasPrefix(STR, PREFIX) => false
      requires notBool (lengthString(STR) >=Int lengthString(PREFIX))
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
           <memAddrs> ListItem(MEMADDR) </memAddrs>
           ...
         </moduleInst>
         <mems> MEMS </mems>
      requires 0 <=Int #signed(i32 , OFFSET)
       andBool (#let memInst(_, SIZE, _) = MEMS[MEMADDR] #in #signed(i32 , OFFSET) +Int lengthBytes(BS) >Int (SIZE *Int #pageSize()))

    rule <instrs> #memStore(OFFSET, BS) => .K ... </instrs>
         <contractModIdx> MODIDX:Int </contractModIdx>
         <moduleInst>
           <modIdx> MODIDX </modIdx>
           <memAddrs> ListItem(MEMADDR) </memAddrs>
           ...
         </moduleInst>
         <mems> MEMS => MEMS [ MEMADDR <- #let memInst(MAX, SIZE, DATA) = MEMS[MEMADDR] #in memInst(MAX, SIZE, #setBytesRange(DATA, OFFSET, BS)) ] </mems>
      requires (#let memInst(_, SIZE, _) = MEMS[MEMADDR] #in #signed(i32 , OFFSET) +Int lengthBytes(BS) <=Int (SIZE *Int #pageSize()))
       andBool 0 <=Int #signed(i32 , OFFSET)
      [preserves-definedness] // setBytesRange total, MEMADDR key existed prior in <mems> map

    rule [memStore-owise]:
        <instrs> #memStore(_, _) => #throwException(ExecutionFailed, "mem store: memory instance not found") ... </instrs>
      [owise]

    syntax InternalInstr ::= #memLoad ( offset: Int , length: Int )
 // ---------------------------------------------------------------

    rule [memLoad-negative-length]:
        <instrs> #memLoad(_, LENGTH) => #throwException(ExecutionFailed, "mem load: negative length") ... </instrs>
      requires #signed(i32 , LENGTH) <Int 0

    rule [memLoad-zero-length]:
        <instrs> #memLoad(_, LENGTH) => .K ... </instrs>
        <bytesStack> STACK => .Bytes : STACK </bytesStack>
      requires LENGTH ==Int 0

    rule [memLoad-bad-bounds]:
         <instrs> #memLoad(OFFSET, LENGTH) => #throwException(ExecutionFailed, "mem load: bad bounds") ... </instrs>
         <contractModIdx> MODIDX:Int </contractModIdx>
         <moduleInst>
           <modIdx> MODIDX </modIdx>
           <memAddrs> ListItem(MEMADDR) </memAddrs>
           ...
         </moduleInst>
         <mems> MEMS </mems>
      requires #signed(i32 , LENGTH) >Int 0
       andBool (#signed(i32 , OFFSET) <Int 0
         orBool (#let memInst(_, SIZE, _) = MEMS[MEMADDR] #in #signed(i32 , OFFSET) +Int #signed(i32 , LENGTH) >Int (SIZE *Int #pageSize())))

    rule [memLoad]:
         <instrs> #memLoad(OFFSET, LENGTH) => .K ... </instrs>
         <bytesStack> STACK => #getBytesRange((#let memInst(_, _, DATA) = MEMS[MEMADDR] #in DATA), OFFSET, LENGTH) : STACK </bytesStack>
         <contractModIdx> MODIDX:Int </contractModIdx>
         <moduleInst>
           <modIdx> MODIDX </modIdx>
           <memAddrs> ListItem(MEMADDR) </memAddrs>
           ...
         </moduleInst>
         <mems> MEMS </mems>
      requires #signed(i32 , LENGTH) >Int 0
       andBool #signed(i32 , OFFSET) >=Int 0
       andBool (#let memInst(_, SIZE, _) = MEMS[MEMADDR] #in #signed(i32 , OFFSET) +Int #signed(i32 , LENGTH) <=Int (SIZE *Int #pageSize()))

    rule [memLoad-owise]:
        <instrs> #memLoad(_, _) => #throwException(ExecutionFailed, "mem load: memory instance not found") ... </instrs>
      [owise]
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
           <storage> STORAGE => STORAGE[KEY <- undef] </storage>
           ...
         </account>
         requires VALUE ==K .Bytes
         [preserves-definedness] // map update is total, CALLEE key existed prior
    rule <instrs> #writeToStorage(KEY, VALUE) => i32.const #storageStatus(STORAGE, KEY, VALUE) ... </instrs>
         <callee> CALLEE </callee>
         <account>
           <address> CALLEE </address>
           <storage> STORAGE => STORAGE[KEY <- VALUE] </storage>
           ...
         </account>
         requires VALUE =/=K .Bytes
         [preserves-definedness] // map update is total, CALLEE key existed prior

    rule [writeToStorage-unknown-addr]:
        <instrs> #writeToStorage(_, _) => #throwException(ExecutionFailed, "writeToStorage: unknown account address") ... </instrs>
      [owise]

    syntax InternalInstr ::= #isReservedKey ( String )
 // --------------------------------------------------
    rule <instrs> #isReservedKey(KEY) => .K ... </instrs>
      requires notBool #hasPrefix(KEY, "ELROND")

    rule <instrs> #isReservedKey(KEY)
               => #throwException(ExecutionFailed, "cannot write to storage under reserved key") ...
         </instrs>
      requires         #hasPrefix(KEY, "ELROND")

    syntax InternalInstr ::= "#storageLoad"
                           | "#storageLoadFromAddress"
 // ---------------------------------------
    rule <instrs> #storageLoad => #storageLoadFromAddress ... </instrs>
         <bytesStack> STACK => CALLEE : STACK </bytesStack>
         <callee> CALLEE </callee>

    rule [storageLoadFromAddress]:
        <instrs> #storageLoadFromAddress => .K ... </instrs>
        <bytesStack> ADDR : KEY : STACK => #lookupStorage(STORAGE, KEY) : STACK </bytesStack>
        <account>
          <address> ADDR </address>
          <storage> STORAGE </storage>
          ...
        </account>

    rule [storageLoadFromAddress-unknown-addr]:
        <instrs> #storageLoadFromAddress
              => #throwException(UserError, "storageLoadFromAddress: unknown account address") ...
        </instrs>
        // ADDR does not match any user
        // <bytesStack> ADDR : _ : _ </bytesStack>
      [owise]

    syntax Bytes ::= #lookupStorage ( Map , key: Bytes ) [function, total]
 // ---------------------------------------------------------------
    rule #lookupStorage(STORAGE, KEY) => {STORAGE[KEY] orDefault .Bytes}:>Bytes
        requires isBytes(STORAGE[KEY] orDefault .Bytes)
    rule #lookupStorage(_STORAGE, _KEY) => .Bytes  [owise]

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
    syntax Int ::= #cmpInt ( Int , Int ) [function, total, symbol(cmpInt), smtlib(cmpInt)]
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
    syntax LogEntry ::= logEntry ( Bytes , Bytes , ListBytes , Bytes ) [symbol(logEntry)]
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
                           | #writeLogAux ( Int , ListBytes , Bytes )
 // ------------------------------------------------------------
    rule <instrs> #writeLog => #writeLogAux(NUMTOPICS, .ListBytes, DATA) ... </instrs>
         <bytesStack> DATA : STACK => STACK </bytesStack>
         <valstack> <i32> NUMTOPICS : <i32> _ : VALSTACK => VALSTACK </valstack>

    rule <instrs> #writeLogAux(1, TOPICS, DATA) => .K ... </instrs>
         <bytesStack> IDENTIFIER : STACK => STACK </bytesStack>
         <callee> CALLEE </callee>
         <logs> ... (.List => ListItem(logEntry(CALLEE, IDENTIFIER, TOPICS, DATA))) </logs>

    rule <instrs> #writeLogAux(NUMTOPICS, TOPICS, DATA)
               => #writeLogAux(NUMTOPICS -Int 1, ListItem(wrap(TOPIC)) TOPICS, DATA)
                  ...
         </instrs>
         <bytesStack> TOPIC : STACK => STACK </bytesStack>
       requires 1 <Int NUMTOPICS
```


## Exception Handling

### `#exception`

`#exception` drops the rest of the commands until `#endWasm` and reverts the state using `popWorldState`.

```k
    rule [exception-revert]:
        <commands> (#exception(EC, MSG) ~> #endWasm) => popCallState ~> popWorldState ... </commands>
        <vmOutput> .VMOutput => VMOutput( EC , MSG , .ListBytes , .List, .Map) </vmOutput>
        <logging> S => S +String " -- Exception: " +String Bytes2String(MSG) </logging>

    rule [exception-skip]:
        <commands> #exception(_,_) ~> (CMD:InternalCmd => .K ) ... </commands>
      requires CMD =/=K #endWasm

```

### `#throwException*`

`#throwException*` clears the `<instrs>` cell and creates an `#exception(_,_)` command with the given error code and message.

```k
    rule [throwExceptionBs]:
        <instrs> (#throwExceptionBs( EC , MSG ) ~> _ ) => .K </instrs>
        <commands> (.K => #exception(EC,MSG)) ... </commands>
```

## Managing Accounts

```k
    syntax Bool ::= #isSmartContract(Bytes)      [function, total]
 // -------------------------------------------------------------
    rule [[ #isSmartContract(ADDR) => true ]]
        <account>
          <address> ADDR </address>
          <code> _:ModuleDecl </code>
          ...
        </account>

    rule #isSmartContract(_) => false              [owise]

    syntax InternalCmd ::= createAccount ( Bytes ) [symbol(createAccount)]
 // ------------------------------------------------------------------------------
    // ignore if the account already exists
    rule [createAccount-existing-instrs-empty]:
         <commands> createAccount(ADDR) => .K ... </commands>
         <account>
           <address> ADDR </address>
           ...
         </account>
         <instrs> .K </instrs>
      [priority(60)]
    rule [createAccount-existing-instrs-wait]:
         <commands> createAccount(ADDR) => .K ... </commands>
         <account>
           <address> ADDR </address>
           ...
         </account>
         <instrs> #waitCommands ... </instrs>
      [priority(60)]

    rule [createAccount-new-instrs-empty]:
         <commands> createAccount(ADDR) => .K ... </commands>
         <accounts>
           ( .Bag
          => <account>
               <address> ADDR </address>
               ...
             </account>
           )
           ...
         </accounts>
         <instrs> .K </instrs>
      [priority(61)]
    rule [createAccount-new-instrs-wait]:
         <commands> createAccount(ADDR) => .K ... </commands>
         <accounts>
           ( .Bag
          => <account>
               <address> ADDR </address>
               ...
             </account>
           )
           ...
         </accounts>
         <instrs> #waitCommands ... </instrs>
      [priority(61)]

    syntax InternalCmd ::= setAccountFields    ( Bytes, Int, Int, Code, Bytes, Map )  [symbol(setAccountFields)]
                         | setAccountCode      ( Bytes, Code )  [symbol(setAccountCode)]
                         | setAccountOwner     ( Bytes, Bytes )
 // ---------------------------------------------------------------
    rule [setAccountFields-instrs-empty]:
         <commands> setAccountFields(ADDR, NONCE, BALANCE, CODE, OWNER_ADDR, STORAGE) => .K ... </commands>
         <account>
           <address> ADDR </address>
           <nonce> _ => NONCE </nonce>
           <balance> _ => BALANCE </balance>
           <code> _ => CODE </code>
           <ownerAddress> _ => OWNER_ADDR </ownerAddress>
           <storage> _ => STORAGE </storage>
           ...
         </account>
         <instrs> .K </instrs>
      [priority(60)]
    rule [setAccountFields-instrs-wait]:
         <commands> setAccountFields(ADDR, NONCE, BALANCE, CODE, OWNER_ADDR, STORAGE) => .K ... </commands>
         <account>
           <address> ADDR </address>
           <nonce> _ => NONCE </nonce>
           <balance> _ => BALANCE </balance>
           <code> _ => CODE </code>
           <ownerAddress> _ => OWNER_ADDR </ownerAddress>
           <storage> _ => STORAGE </storage>
           ...
         </account>
         <instrs> #waitCommands ... </instrs>
      [priority(60)]

    rule [setAccountCode-instrs-empty]:
         <commands> setAccountCode(ADDR, CODE) => .K ... </commands>
         <account>
           <address> ADDR </address>
           <code> _ => CODE </code>
           ...
         </account>
         <instrs> .K </instrs>
      [priority(60)]
    rule [setAccountCode-instrs-wait]:
         <commands> setAccountCode(ADDR, CODE) => .K ... </commands>
         <account>
           <address> ADDR </address>
           <code> _ => CODE </code>
           ...
         </account>
         <instrs> #waitCommands ... </instrs>
      [priority(60)]

    rule [setAccountOwner-instrs-empty]:
         <commands> setAccountOwner(ADDR, OWNER) => .K ... </commands>
         <account>
           <address> ADDR </address>
           <ownerAddress> _ => OWNER </ownerAddress>
           ...
         </account>
         <instrs> .K </instrs>
      [priority(60)]
    rule [setAccountOwner-instrs-wait]:
         <commands> setAccountOwner(ADDR, OWNER) => .K ... </commands>
         <account>
           <address> ADDR </address>
           <ownerAddress> _ => OWNER </ownerAddress>
           ...
         </account>
         <instrs> #waitCommands ... </instrs>
      [priority(60)]
```

## Transfer Funds

### EGLD

- `transferFunds` first checks that the sender and receiver exist. Then, executes the transfer.
- `transferFundsH` assumes that the accounts exist.

```k
    syntax K           ::= transferFunds ( Bytes, Bytes, Int )    [function, total]
    syntax InternalCmd ::= transferFundsH ( Bytes, Bytes, Int )
 // -----------------------------------------
    rule transferFunds(A, B, V)
      => checkAccountExists(A)
      ~> checkAccountExists(B)
      ~> transferFundsH(A, B, V)

    rule [transferFundsH-self]:
        <commands> transferFundsH(ACCT, ACCT, VALUE)
                => appendToOutAccount(ACCT, OutputTransfer(ACCT, VALUE))
                   ...
        </commands>
        <account>
          <address> ACCT </address>
          <balance> ORIGFROM </balance>
          ...
        </account>
        <instrs> (#waitCommands ~> _) #Or .K </instrs>
      requires VALUE <=Int ORIGFROM
      [priority(60)]

    rule [transferFundsH]:
        <commands> transferFundsH(ACCTFROM, ACCTTO, VALUE)
                => appendToOutAccount(ACCTTO, OutputTransfer(ACCTFROM, VALUE))
                   ...
        </commands>
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
        <instrs> (#waitCommands ~> _) #Or .K </instrs>
      requires ACCTFROM =/=K ACCTTO andBool VALUE <=Int ORIGFROM
      [priority(60), preserves-definedness]
      // Preserving definedness:
      //   - Map updates preserve definedness
      //   - -Int and +Int are total

    rule [transferFundsH-oofunds]:
        <commands> transferFundsH(ACCT, _, VALUE) => #exception(OutOfFunds, b"") ... </commands>
        <account>
          <address> ACCT </address>
          <balance> ORIGFROM </balance>
          ...
        </account>
        <instrs> (#waitCommands ~> _) #Or .K </instrs>
      requires VALUE >Int ORIGFROM
      [priority(60)]

```

## Calling Contract

```k
    syntax InternalCmd ::= callContract    ( Bytes, String,     VmInputCell ) [symbol(callContractString), function, total]
                         | callContract    ( Bytes, WasmString, VmInputCell ) [symbol(callContractWasmString)]
                         | callContractAux ( Bytes, Bytes, WasmString, VmInputCell ) [symbol(callContractAux)]
 // -------------------------------------------------------------------------------------
    rule callContract(TO, FUNCNAME:String, VMINPUT)
      => callContract(TO, #quoteUnparseWasmString(FUNCNAME), VMINPUT)

    rule [callContract]:
        <commands> callContract(TO, FUNCNAME:WasmStringToken,
                                <vmInput>
                                  <caller> FROM </caller>
                                  <callValue> VALUE </callValue>
                                  <esdtTransfers> ESDT </esdtTransfers>
                                  _
                                </vmInput> #as VMINPUT
                   )
                => pushWorldState
                ~> pushCallState
                ~> resetCallstate
                ~> transferFunds(FROM, TO, VALUE)
                ~> transferESDTs(FROM, TO, ESDT)
                ~> callContractAux(FROM, TO, FUNCNAME, VMINPUT)
                ~> #endWasm
                   ...
        </commands>
        <vmOutput> _ => .VMOutput </vmOutput>
        <logging> S => S +String " -- callContract " +String #parseWasmString(FUNCNAME) </logging>

    rule [callContractAux]:
        <commands> callContractAux(_FROM, TO, FUNCNAME, VMINPUT)
                => newWasmInstance(TO, CODE)
                ~> mkCall(TO, FUNCNAME, VMINPUT)
                   ...
        </commands>
        <account>
          <address> TO </address>
          <code> CODE </code>
          ...
        </account>
        <instrs> .K </instrs>
      requires notBool(isBuiltin(FUNCNAME))
       andBool #token("\"callBack\"", "WasmStringToken") =/=K FUNCNAME
      [priority(60)]

    rule [callContractAux-builtin]:
        <commands> callContractAux(FROM, TO, FUNC, VMINPUT)
                => processBuiltinFunction(toBuiltinFunction(FUNC), FROM, TO, VMINPUT)
                   ...
        </commands>
        <instrs> .K </instrs>
      requires isBuiltin(FUNC)
      [priority(60)]

    rule [callContractAux-err-callback]:
        <commands> callContractAux(_, _, FUNCNAME:WasmString, _)
                => #exception(ExecutionFailed, b"invalid function (calling callBack() directly is forbidden)") ...
        </commands>
       <instrs> .K </instrs>
      requires #token("\"callBack\"", "WasmStringToken") ==K FUNCNAME
      [priority(60)]

    rule [callContractAux-not-contract]:
        <commands> callContractAux(_, TO, _:WasmString, _)
                => #exception(ContractNotFound, b"not a contract: " +Bytes TO) ...
        </commands>
        <account>
          <address> TO </address>
          <code> .Code </code>
          ...
        </account>
        <instrs> .K </instrs>
      [priority(61)]

```

Every contract call runs in its own Wasm instance initialized with the contract's code.

```k
    syntax InternalCmd ::= newWasmInstanceAux(Bytes, ModuleDecl)  [symbol(newWasmInstanceAux)]
 // --------------------------------------------------------------------------------------------------
    rule [newWasmInstance]:
        <commands> newWasmInstance(ADDR, CODE) => newWasmInstanceAux(ADDR, CODE) ... </commands>
        <instrs> .K </instrs>

    rule [newWasmInstanceAux]:
        <commands> newWasmInstanceAux(_, CODE) => #waitWasm ~> setContractModIdx ... </commands>
        ( _:WasmCell => <wasm>
          <instrs> initContractModule(CODE) </instrs>
          ...
        </wasm>)
      // TODO: It is fairly hard to check that this rule preserves definedness.
      // However, if that's not the case, then this axiom is invalid. We should
      // figure this out somehow. Preferably, we should make initContractModule
      // a total function. Otherwise, we should probably make a
      // `definedInitContractModule` function that we should use in the requires
      // clause.

    syntax InternalCmd ::= "setContractModIdx"
 // ------------------------------------------------------
    rule [setContractModIdx]:
        <commands> setContractModIdx => .K ... </commands>
        <contractModIdx> _ => NEXTIDX -Int 1 </contractModIdx>
        <nextModuleIdx> NEXTIDX </nextModuleIdx>
        <instrs> .K </instrs>

    syntax K ::= initContractModule(ModuleDecl)   [function]
 // ------------------------------------------------------------------------
    rule initContractModule((module _:OptionalId _:Defns):ModuleDecl #as M)
      => sequenceStmts(text2abstract(M .Stmts))

    rule initContractModule(M:ModuleDecl) => M              [owise]
```

Initialize the call state and invoke the endpoint function:

```k
    rule [mkCall]:
        <commands> mkCall(TO, FUNCNAME:WasmStringToken, VMINPUT) => .K ... </commands>
        <callState>
          <callee> _ => TO   </callee>
          <function> _ => #parseWasmString(FUNCNAME) </function>
          (_:VmInputCell => VMINPUT)
          // executional
          <wasm>
            <instrs> .K => ( invoke FUNCADDRS {{ FUNCIDX }} orDefault -1 ) </instrs>
            <moduleInst>
              <modIdx> MODIDX </modIdx>
              <exports> ... FUNCNAME |-> FUNCIDX:Int </exports>
              <funcAddrs> FUNCADDRS </funcAddrs>
              ...
            </moduleInst>
            ...
          </wasm>
          <bigIntHeap> _ => .Map </bigIntHeap>
          <bufferHeap> _ => .Map </bufferHeap>
          <bytesStack> _ => .BytesStack </bytesStack>
          <contractModIdx> MODIDX:Int </contractModIdx>
          <asyncCalls> _ => .ListAsyncCall </asyncCalls>
          // output
          <out> _ => .ListBytes </out>
          <logs> _ => .List </logs>
          <outputAccounts> _ </outputAccounts>
        </callState>
        requires isListIndex(FUNCIDX, FUNCADDRS)
      [priority(60)]

    rule [mkCall-func-not-found]:
        <commands> mkCall(_TO, FUNCNAME:WasmStringToken, _VMINPUT)
                => #exception(FunctionNotFound, b"invalid function (not found)") ...
        </commands>
        <contractModIdx> MODIDX:Int </contractModIdx>
        <moduleInst>
          <modIdx> MODIDX </modIdx>
          <exports> EXPORTS </exports>
          ...
        </moduleInst>
        <instrs> .K </instrs>
        <logging> S => S +String " -- callContract not found " +String #parseWasmString(FUNCNAME) </logging>
      requires notBool( FUNCNAME in_keys(EXPORTS) )
      [priority(60)]

endmodule
```
