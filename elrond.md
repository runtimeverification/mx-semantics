Elrond Semantics
================

```k
require "wasm-text.md"
require "wasm-coverage.md"
```

Elrond Node
-----------

```k
module ELROND-NODE
    imports DOMAINS
    imports WASM-TEXT

    configuration
      <node>
        <commands> .K </commands>
        <callState>
          <callingArguments> .List </callingArguments>
          <caller> .Bytes </caller>
          <callee> .Bytes </callee>
          <callValue> 0 </callValue>
          <out> .List </out>
          <message> .Bytes </message>
          <returnCode> .ReturnCode </returnCode>
          <interimStates> .List </interimStates>
        </callState>
        <activeAccounts> .Set </activeAccounts>
        <accounts>
          <account multiplicity="*" type="Map">
             <address> .Bytes </address>
             <nonce> 0 </nonce>
             <balance> 0 </balance>
```

If the codeIdx is ".CodeIndex", it means the account is not a contract.
If the codeIdx is an integer, it is the exact module index from the Wasm store which specifies the contract.

```k
             <codeIdx> .CodeIndex </codeIdx>
```
Storage maps byte arrays to byte arrays.

```k
             <storage> .Map </storage>
           </account>
         </accounts>
         <previousBlockInfo>
           <prevBlockTimestamp>  0 </prevBlockTimestamp>
           <prevBlockNonce>      0 </prevBlockNonce>
           <prevBlockRound>      0 </prevBlockRound>
           <prevBlockEpoch>      0 </prevBlockEpoch>
           <prevBlockRandomSeed> padRightBytes(.Bytes, 48, 0) </prevBlockRandomSeed>
         </previousBlockInfo>
         <currentBlockInfo>
           <curBlockTimestamp>  0 </curBlockTimestamp>
           <curBlockNonce>      0 </curBlockNonce>
           <curBlockRound>      0 </curBlockRound>
           <curBlockEpoch>      0 </curBlockEpoch>
           <curBlockRandomSeed> padRightBytes(.Bytes, 48, 0) </curBlockRandomSeed>
         </currentBlockInfo>
       </node>

    syntax ReturnCode ::= ".ReturnCode"
                        | "OK"
                        | ExceptionCode
    syntax ExceptionCode ::= "OutOfFunds"
                           | "UserError"
 // ------------------------------------

    syntax Address ::= Bytes
                     | WasmStringToken
    syntax Bytes ::= #address2Bytes ( Address ) [function, functional]
 // ------------------------------------------------------------------
    rule #address2Bytes(ADDR:WasmStringToken) => String2Bytes(#parseWasmString(ADDR))
    rule #address2Bytes(ADDR:Bytes) => ADDR

    syntax CodeIndex ::= ".CodeIndex" [klabel(.CodeIndex), symbol]
                       | Int
 // ----------------------------------------------------------

    syntax Code ::= ".Code" [klabel(.Code), symbol]
                  | ModuleDecl
 // ----------------------------------------------
```

The value is an unsigned integer representation of the bytes.
The length is the number of bytes the argument represents.

```k
    syntax Argument ::= arg ( value: Int, length: Int ) [klabel(tupleArg), symbol]
 // ------------------------------------------------------------------------------

    syntax Int ::= valueArg  ( Argument ) [function, functional]
                 | lengthArg ( Argument ) [function, functional]
 // ------------------------------------------------------------
    rule valueArg (arg(V, _)) => V
    rule lengthArg(arg(_, L)) => L

endmodule
```

Auto Allocate Host Modules
--------------------------

When `AUTO-ALLOCATE` is imported, an new module will be automatically created and registered whenever necessary to resolve an import.
This makes it possible to implement host modules easily in K.
Accessing the import will result in an instruction being left on the `instrs` cell that can't be resolved in the regular Wasm semantics.
Instead, the embedder can add rules for handling the host import.

Currently, only function imports are supported.
Calling an imported host function will result in `hostCall(MODULE_NAME, FUNCTION_NAME, FUNCTION_TYPE)` being left on the `instrs` cell.

```k
module WASM-AUTO-ALLOCATE
    imports WASM-TEXT

    syntax Stmt ::= "newEmptyModule" WasmString
 // -------------------------------------------
    rule <instrs> newEmptyModule MODNAME => . ... </instrs>
         <moduleRegistry> MR => MR [ MODNAME <- NEXT ] </moduleRegistry>
         <nextModuleIdx> NEXT => NEXT +Int 1 </nextModuleIdx>
         <moduleInstances> ( .Bag => <moduleInst> <modIdx> NEXT </modIdx> ... </moduleInst>) ... </moduleInstances>

    syntax Stmts ::=  autoAllocModules ( ModuleDecl, Map ) [function]
                   | #autoAllocModules ( Defns     , Map ) [function]
 // -----------------------------------------------------------------
    rule  autoAllocModules(#module(... importDefns:IS), MR) => #autoAllocModules(IS, MR)
```

In helper function `#autoAllocModules`, the module registry map is passed along to check if the module being imported from is present.
It is treated purely as a key set -- the actual stored values are not used or stored anywhere.

```k
    rule #autoAllocModules(.Defns, _) => .Stmts
    rule #autoAllocModules((#import(MOD, _, _) DS) => DS, MR) requires MOD in_keys(MR)
    rule #autoAllocModules((#import(MOD, _, _) DS), MR)
      => newEmptyModule MOD #autoAllocModules(DS, MR [MOD <- -1])
      requires notBool MOD in_keys(MR)

    rule <instrs> MD:ModuleDecl
               => sequenceStmts(autoAllocModules(MD, MR))
               ~> MD
              ...
         </instrs>
         <moduleRegistry> MR </moduleRegistry>
      requires autoAllocModules(MD, MR) =/=K .Stmts
      [priority(10)]

    syntax Instr ::= hostCall(String, String, FuncType)
 // ---------------------------------------------------
    rule <instrs> (. => allocfunc(HOSTMOD, NEXTADDR, TYPE, [ .ValTypes ], hostCall(wasmString2StringStripped(MOD), wasmString2StringStripped(NAME), TYPE) .Instrs, #meta(... id: String2Identifier("$auto-alloc:" +String #parseWasmString(MOD) +String ":" +String #parseWasmString(NAME) ), localIds: .Map )))
               ~> #import(MOD, NAME, #funcDesc(... type: TIDX))
              ...
         </instrs>
         <curModIdx> CUR </curModIdx>
         <moduleInst>
           <modIdx> CUR </modIdx>
           <types> ... TIDX |-> TYPE ... </types>
           ...
        </moduleInst>
        <nextFuncAddr> NEXTADDR => NEXTADDR +Int 1 </nextFuncAddr>
        <moduleRegistry> ... MOD |-> HOSTMOD ... </moduleRegistry>
        <moduleInst>
          <modIdx> HOSTMOD </modIdx>
          <exports> EXPORTS => EXPORTS [NAME <- NEXTFUNC ] </exports>
          <funcAddrs> FS => FS [NEXTFUNC <- NEXTADDR] </funcAddrs>
          <nextFuncIdx> NEXTFUNC => NEXTFUNC +Int 1 </nextFuncIdx>
          <nextTypeIdx> NEXTTYPE => NEXTTYPE +Int 1 </nextTypeIdx>
          <types> TYPES => TYPES [ NEXTTYPE <- TYPE ] </types>
          ...
        </moduleInst>
      requires notBool NAME in_keys(EXPORTS)

    syntax String ::= wasmString2StringStripped ( WasmString ) [function]
                    | #stripQuotes ( String ) [function]
 // ----------------------------------------------------
    rule wasmString2StringStripped(WS) => #stripQuotes(#parseWasmString(WS))

    rule #stripQuotes(S) => replaceAll(S, "\"", "")

endmodule
```

Combine Elrond Node With Wasm
-----------------------------

```k
module ELROND
    imports WASM-TEXT
    imports WASM-COVERAGE
    imports WASM-AUTO-ALLOCATE
    imports ELROND-NODE

    configuration
      <elrond>
        <wasmCoverage/>
        <node/>
        <bigIntHeap> .Map </bigIntHeap>
        <bytesStack> .BytesStack </bytesStack>
        <logging> "" </logging>
      </elrond>
```

### Helper Functions

#### Bytes Stack

```k
    syntax BytesStack ::= List{Bytes, ":"}
 // --------------------------------------

    syntax BytesOp ::= #pushBytes ( Bytes )
                     | "#dropBytes"
 // ---------------------------------------
    rule <instrs> #pushBytes(BS) => . ... </instrs>
         <bytesStack> STACK => BS : STACK </bytesStack>

    rule <instrs> #dropBytes => . ... </instrs>
         <bytesStack> _ : STACK => STACK </bytesStack>
```

#### World State

```k
    syntax Accounts ::= "{" AccountsCellFragment "|" Set "}"
 // --------------------------------------------------------

    syntax InternalCmd ::= "pushWorldState"
 // ---------------------------------------
    rule <commands> pushWorldState => . ... </commands>
         <interimStates> (.List => ListItem({ ACCTDATA | ACCTS })) ... </interimStates>
         <activeAccounts> ACCTS    </activeAccounts>
         <accounts>       ACCTDATA </accounts>
      [priority(60)]

    syntax InternalCmd ::= "popWorldState"
 // --------------------------------------
    rule <commands> popWorldState => . ... </commands>
         <interimStates> (ListItem({ ACCTDATA | ACCTS }) => .List) ... </interimStates>
         <activeAccounts> _ => ACCTS    </activeAccounts>
         <accounts>       _ => ACCTDATA </accounts>
      [priority(60)]

    syntax InternalCmd ::= "dropWorldState"
 // ---------------------------------------
    rule <commands> dropWorldState => . ... </commands>
         <interimStates> (ListItem(_) => .List) ... </interimStates>
      [priority(60)]
```

### Node And Wasm VM Synchronization

- `#endWasm` waits for the Wasm VM to finish the execution and check the return code.

```k
    syntax InternalCmd ::= "#endWasm"
 // ---------------------------------
    rule <commands> #endWasm => dropWorldState ... </commands>
         <returnCode> .ReturnCode => OK </returnCode>
         <instrs> . </instrs>

    rule <commands> #endWasm => #exception ... </commands>
         <returnCode> _:ExceptionCode </returnCode>
         <instrs> . </instrs>
```

- `#exception` drops the rest of the computation in the `commands` and `instrs` cells and reverts the state.

```k
    syntax InternalCmd ::= "#exception"
 // -----------------------------------
    rule <commands> (#exception ~> _) => popWorldState </commands>
         <instrs> _ => . </instrs>
```

### Managing Accounts

```k
    syntax InternalCmd ::= createAccount ( Bytes ) [klabel(createAccount), symbol]
 // ------------------------------------------------------------------------------
    rule <commands> createAccount(ADDR) => . ... </commands>
         <activeAccounts> ... (.Set => SetItem(ADDR)) ... </activeAccounts>
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
      [priority(60)]

    syntax InternalCmd ::= setAccountFields    ( Bytes, Int, Int, CodeIndex, Map )
                         | setAccountCodeIndex ( Bytes, CodeIndex )
 // ---------------------------------------------------------------
    rule <commands> setAccountFields(ADDR, NONCE, BALANCE, CODEIDX, STORAGE) => . ... </commands>
         <account>
           <address> ADDR </address>
           <nonce> _ => NONCE </nonce>
           <balance> _ => BALANCE </balance>
           <codeIdx> _ => CODEIDX </codeIdx>
           <storage> _ => STORAGE </storage>
         </account>
      [priority(60)]

    rule <commands> setAccountCodeIndex(ADDR, CODEIDX) => . ... </commands>
         <account>
           <address> ADDR </address>
           <codeIdx> _ => CODEIDX </codeIdx>
           ...
         </account>
      [priority(60)]
```

### Transfer Funds

```k
    syntax InternalCmd ::= transferFunds ( Bytes, Bytes, Int )
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

    rule <commands> #transferSuccess => . ... </commands>
         <instrs> . </instrs>
```

### Calling Contract

```k
    syntax InternalCmd ::= callContract ( Bytes, Bytes, Int,     String, List, Int, Int ) [klabel(callContractString)]
                         | callContract ( Bytes, Bytes, Int, WasmString, List, Int, Int ) [klabel(callContractWasmString)]
                         | mkCall       ( Bytes, Bytes, Int, WasmString, List, Int, Int )
 // -------------------------------------------------------------------------------------
    rule <commands> callContract(FROM, TO, VALUE, FUNCNAME:String, ARGS, GASLIMIT, GASPRICE)
                 => callContract(FROM, TO, VALUE, #unparseWasmString("\"" +String FUNCNAME +String "\""), ARGS, GASLIMIT, GASPRICE)
                    ...
         </commands>
      [priority(60)]

    rule <commands> callContract(FROM, TO, VALUE, FUNCNAME:WasmStringToken, ARGS, GASLIMIT, GASPRICE)
                 => pushWorldState
                 ~> transferFunds(FROM, TO, VALUE)
                 ~> mkCall(FROM, TO, VALUE, FUNCNAME, ARGS, GASLIMIT, GASPRICE)
                 ~> #endWasm
                    ...
         </commands>
      [priority(60)]

    rule <commands> mkCall(FROM, TO, VALUE, FUNCNAME:WasmStringToken, ARGS, _GASLIMIT, _GASPRICE) => . ... </commands>
         <callingArguments> _ => ARGS </callingArguments>
         <caller> _ => FROM </caller>
         <callee> _ => TO   </callee>
         <callValue> _ => VALUE </callValue>
         <out> _ => .List </out>
         <message> _ => .Bytes </message>
         <returnCode> _ => .ReturnCode </returnCode>
         <bigIntHeap> _ => .Map </bigIntHeap>
         <account>
           <address> TO </address>
           <codeIdx> CODE:Int </codeIdx>
           ...
         </account>
         <moduleInst>
           <modIdx> CODE </modIdx>
           <exports> ... FUNCNAME |-> FUNCIDX:Int </exports>
           <funcAddrs> ... FUNCIDX |-> FUNCADDR:Int ... </funcAddrs>
           ...
         </moduleInst>
         <instrs> . => ( invoke FUNCADDR ) </instrs>
         <logging> S => S +String " -- callContract " +String #parseWasmString(FUNCNAME) </logging>
      [priority(60)]
```

Host Calls
----------

Here, host calls are implemented, by defining the semantics when `hostCall(MODULE_NAME, EXPORT_NAME, TYPE)` is left on top of the `instrs` cell.

### Helper functions

#### Memory

```k
    syntax MemOp ::= #setMem ( bytes: Bytes, offset: Int )
                   | #getMem ( offset: Int , lenght: Int )
 // ------------------------------------------------------
    rule <instrs> #setMem(BS, OFFSET) => . ... </instrs>
         <callee> CALLEE </callee>
         <account>
           <address> CALLEE </address>
           <codeIdx> MODIDX:Int </codeIdx>
           ...
         </account>
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
      requires OFFSET +Int lengthBytes(BS) <=Int (SIZE *Int #pageSize())

    rule <instrs> #getMem(OFFSET, LENGTH) => . ... </instrs>
         <bytesStack> STACK => #getBytesRange(DATA, OFFSET, LENGTH) : STACK </bytesStack>
         <callee> CALLEE </callee>
         <account>
           <address> CALLEE </address>
           <codeIdx> MODIDX:Int </codeIdx>
           ...
         </account>
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
      requires OFFSET +Int LENGTH <=Int (SIZE *Int #pageSize())
```

#### Storage

Storing a value returns a status code indicating if and how the storage was modified.

TODO: Implement [reserved keys and read-only runtimes](https://github.com/ElrondNetwork/arwen-wasm-vm/blob/d6ea0489081f81fefba002609c34ece1365373dd/arwen/contexts/storage.go#L111).

```k
    syntax StorageOp ::= "#storageStore"
                       | "#storageLoad"
                       | #bytesToSetMem (offset : Int)
 // --------------------------------------------------
    rule <instrs> #storageStore => i32.const #storageStatus(STORAGE, KEY, VALUE) ... </instrs>
         <bytesStack> VALUE : KEY : STACK => STACK </bytesStack>
         <callee> CALLEE </callee>
         <account>
           <address> CALLEE </address>
           <storage> STORAGE => #updateStorage(STORAGE, KEY, VALUE) </storage>
           ...
         </account>

    rule <instrs> #storageLoad => i32.const lengthBytes({STORAGE[KEY]}:>Bytes) ... </instrs>
         <bytesStack> KEY : STACK => {STORAGE[KEY]}:>Bytes : STACK </bytesStack>
         <callee> CALLEE </callee>
         <account>
           <address> CALLEE </address>
           <storage> STORAGE </storage>
           ...
         </account>
      requires KEY in_keys(STORAGE)

    rule <instrs> #storageLoad => i32.const 0 ... </instrs>
         <bytesStack> KEY : STACK => .Bytes : STACK </bytesStack>
         <callee> CALLEE </callee>
         <account>
           <address> CALLEE </address>
           <storage> STORAGE </storage>
           ...
         </account>
      requires notBool KEY in_keys(STORAGE)

    rule <instrs> #bytesToSetMem(OFFSET) => #setMem(BS, OFFSET) ... </instrs>
         <bytesStack> BS : STACK => STACK </bytesStack>

    syntax Map ::= #updateStorage ( Map , key : Bytes , val : Bytes ) [function, functional]
 // ----------------------------------------------------------------------------------------
    rule #updateStorage(STOR, KEY, VAL) => STOR [KEY <- undef] requires VAL  ==K .Bytes
    rule #updateStorage(STOR, KEY, VAL) => STOR [KEY <- VAL  ] requires VAL =/=K .Bytes

    syntax Int ::= #storageStatus ( Map , key : Bytes , val : Bytes ) [function, functional]
                 | #StorageUnmodified () [function, functional]
                 | #StorageModified   () [function, functional]
                 | #StorageAdded      () [function, functional]
                 | #StorageDeleted    () [function, functional]
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

#### Bytes

```k
    syntax Bytes ::= #getBytesRange ( Bytes , Int , Int ) [function]
 // ----------------------------------------------------------------
    rule #getBytesRange(_,  OFFSET, LENGTH) => .Bytes
      requires notBool (LENGTH >=Int 0 andBool OFFSET >=Int 0)

    rule #getBytesRange(BS, OFFSET, LENGTH) => substrBytes(padRightBytes(BS, OFFSET +Int LENGTH, 0), OFFSET, OFFSET +Int LENGTH)
      requires OFFSET >=Int 0 andBool LENGTH >=Int 0 andBool OFFSET <Int lengthBytes(BS)

    rule #getBytesRange(_, _, LENGTH) => padRightBytes(.Bytes, LENGTH, 0) [owise]

    syntax Bytes ::= #setBytesRange ( Bytes , Int , Bytes ) [function]
 // ------------------------------------------------------------------
    rule #setBytesRange(BS, OFFSET, NEW) => replaceAtBytes(padRightBytes(BS, OFFSET +Int lengthBytes(NEW), 0), OFFSET, NEW)
```

#### Integer Operation

```k
    syntax Int ::= #unsigned( Argument ) [function, functional]
                 |   #signed( Argument ) [function, functional]
 // -----------------------------------------------------------
    rule #unsigned(A) => valueArg(A)
    rule #signed(A)   => valueArg(A)                                     requires notBool 2 ^Int (8 *Int lengthArg(A) -Int 1) <=Int valueArg(A)
    rule #signed(A)   => valueArg(A) -Int (2 ^Int (lengthArg(A) *Int 8)) requires         2 ^Int (8 *Int lengthArg(A) -Int 1) <=Int valueArg(A)

    syntax Int ::= #cmpInt ( Int , Int ) [function, functional]
 // -----------------------------------------------------------
    rule #cmpInt(I1, I2) => -1 requires I1  <Int I2
    rule #cmpInt(I1, I2) =>  1 requires I1  >Int I2
    rule #cmpInt(I1, I2) =>  0 requires I1 ==Int I2

    syntax Int ::= #bigIntSign ( Int ) [function, functional]
 // ---------------------------------------------------------
    rule #bigIntSign(I) => 0  requires I ==Int 0
    rule #bigIntSign(I) => 1  requires I >Int 0
    rule #bigIntSign(I) => -1 requires I <Int 0
```

### Elrond EI

```k
    // extern int32_t transferValue(void *context, int32_t dstOffset, int32_t valueOffset, int32_t dataOffset, int32_t length);
    rule <instrs> hostCall("env", "transferValue", [ i32 i32 i32 i32 .ValTypes ] -> [ i32 .ValTypes ])
               => #local.get(0) ~> #local.get(1) ~> #local.get(2) ~> #local.get(3)
               ~> #transferValue
                  ...
         </instrs>

    syntax InternalInstr ::= "#transferValue"
                           | #transferValueAux ( Bytes, Bytes, Int )
                           | "#waitForTransfer"
 // -------------------------------------------
    rule <instrs> #transferValue
               => #transferValueAux(CALLEE,
                                    #getBytesRange(DATA, DESTOFFSET, 32),
                                    Bytes2Int(#getBytesRange(DATA, VALUEOFFSET, 32), BE, Unsigned))
                  ...
         </instrs>
         <callee> CALLEE </callee>
         <valstack> <i32> _ : <i32> _ : <i32> VALUEOFFSET : <i32> DESTOFFSET : VS => VS </valstack>
         <account>
           <address> CALLEE </address>
           <codeIdx> MODIDX:Int </codeIdx>
           ...
         </account>
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
      requires (VALUEOFFSET +Int 32) <=Int (SIZE *Int #pageSize())
       andBool (DESTOFFSET +Int 32) <=Int (SIZE *Int #pageSize())

    rule <commands> (. => transferFunds(ACCTFROM, ACCTTO, VALUE)) ... </commands>
         <instrs> #transferValueAux(ACCTFROM, ACCTTO, VALUE) => #waitForTransfer ~> i32.const 0 ... </instrs>

    rule <commands> #transferSuccess => . ... </commands>
         <instrs> #waitForTransfer => . ... </instrs>

    // extern int32_t getArgumentLength(void *context, int32_t id);
    rule <instrs> hostCall("env", "getArgumentLength", [ i32 .ValTypes ] -> [ i32 .ValTypes ]) => i32.const lengthArg({ARGS[IDX]}:>Argument) ... </instrs>
         <locals> 0 |-> <i32> IDX </locals>
         <callingArguments> ARGS </callingArguments>
      requires IDX <Int size(ARGS)

    // extern int32_t getArgument(void *context, int32_t id, int32_t argOffset);
    rule <instrs> hostCall("env", "getArgument", [ i32 i32 .ValTypes ] -> [ i32 .ValTypes ])
               => #setMem(Int2Bytes(lengthArg({ARGS[IDX]}:>Argument), valueArg({ARGS[IDX]}:>Argument), BE), OFFSET)
               ~> i32.const lengthArg({ARGS[IDX]}:>Argument)
                  ...
         </instrs>
         <locals>
           0 |-> <i32> IDX
           1 |-> <i32> OFFSET
         </locals>
         <callingArguments> ARGS </callingArguments>

    // extern int32_t getNumArguments(void *context);
    rule <instrs> hostCall("env", "getNumArguments", [ .ValTypes ] -> [ i32 .ValTypes ]) => i32.const size(ARGS) ... </instrs>
         <callingArguments> ARGS </callingArguments>

    // extern int32_t storageStore(void *context, int32_t keyOffset, int32_t keyLength , int32_t dataOffset, int32_t dataLength);
    rule <instrs> hostCall("env", "storageStore", [ i32 i32 i32 i32 .ValTypes ] -> [ i32 .ValTypes ] )
               => #getMem(KEYOFFSET, KEYLENGTH)
               ~> #getMem(VALOFFSET, VALLENGTH)
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
               => #getMem(KEYOFFSET, KEYLENGTH)
               ~> #storageLoad
               ~> #dropBytes
                  ...
         </instrs>
         <locals>
           0 |-> <i32> KEYOFFSET
           1 |-> <i32> KEYLENGTH
         </locals>

    // extern int32_t storageLoad(void *context, int32_t keyOffset, int32_t keyLength , int32_t dataOffset);
    rule <instrs> hostCall("env", "storageLoad", [ i32 i32 i32 .ValTypes ] -> [ i32 .ValTypes ] )
               => #getMem(KEYOFFSET, KEYLENGTH)
               ~> #storageLoad
               ~> #bytesToSetMem(VALOFFSET)
                  ...
         </instrs>
         <locals>
           0 |-> <i32> KEYOFFSET
           1 |-> <i32> KEYLENGTH
           2 |-> <i32> VALOFFSET
         </locals>

    // extern void getCaller(void *context, int32_t resultOffset);
    rule <instrs> hostCall("env", "getCaller", [ i32 .ValTypes ] -> [ .ValTypes ])
               => #setMem(CALLER, OFFSET)
                  ...
         </instrs>
         <locals> 0 |-> <i32> OFFSET </locals>
         <caller> CALLER </caller>

    // extern void returnData(void* context, int32_t dataOffset, int32_t length);
    rule <instrs> hostCall("env", "finish", [ i32 i32 .ValTypes ] -> [ .ValTypes ]) => #local.get(0) ~> #local.get(1) ~> #finish ... </instrs>

    syntax InternalInstr ::= "#finish"
 // ----------------------------------
    rule <instrs> #finish => . ... </instrs>
         <valstack> <i32> LENGTH : <i32> OFFSET : VS => VS </valstack>
         <callee> CALLEE </callee>
         <out> ... (.List => ListItem(#getBytesRange(DATA, OFFSET, LENGTH))) </out>
         <account>
           <address> CALLEE </address>
           <codeIdx> MODIDX:Int </codeIdx>
           ...
         </account>
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
      requires (OFFSET +Int LENGTH) <=Int (SIZE *Int #pageSize())

    // extern void signalError(void* context, int32_t messageOffset, int32_t messageLength);
    rule <instrs> hostCall("env", "signalError", [ i32 i32 .ValTypes ] -> [ .ValTypes ] )
               => #local.get(0) ~> #local.get(1) ~> #signalError ...
         </instrs>

    syntax InternalInstr ::= "#signalError"
 // ---------------------------------------
    rule <instrs> (#signalError ~> _) => . </instrs>
         <valstack> <i32> LENGTH : <i32> OFFSET : VS => VS </valstack>
         <callee> CALLEE </callee>
         <returnCode> _ => UserError </returnCode>
         <message> MSG => MSG +Bytes #getBytesRange(DATA, OFFSET, LENGTH) </message>
         <account>
           <address> CALLEE </address>
           <codeIdx> MODIDX:Int </codeIdx>
           ...
         </account>
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
      requires (OFFSET +Int LENGTH) <=Int (SIZE *Int #pageSize())

    // extern long long getBlockTimestamp(void *context);
    rule <instrs> hostCall("env", "getBlockTimestamp", [ .ValTypes ] -> [ i64 .ValTypes ]) => i64.const TIMESTAMP ... </instrs>
         <curBlockTimestamp> TIMESTAMP </curBlockTimestamp>

    // extern void getBlockRandomSeed(void *context, int32_t resultOffset);
    rule <instrs> hostCall("env", "getBlockRandomSeed", [ i32 .ValTypes ] -> [ .ValTypes ])
               => #setMem(SEED, OFFSET)
                  ...
         </instrs>
         <locals> 0 |-> <i32> OFFSET </locals>
         <curBlockRandomSeed> SEED </curBlockRandomSeed>
```

### BigInt Ops

```k
    syntax InternalInstr ::= #getBigInt ( idx : Int , offset : Int , Signedness )
 // -----------------------------------------------------------------------------
    rule <instrs> #getBigInt(BIGINT_IDX, OFFSET, SIGN) => i32.const lengthBytes(Int2Bytes({HEAP[BIGINT_IDX]}:>Int, BE, SIGN)) ...</instrs>
         <callee> CALLEE </callee>
         <account>
           <address> CALLEE </address>
           <codeIdx> MODIDX:Int </codeIdx>
           ...
         </account>
         <moduleInst>
           <modIdx> MODIDX </modIdx>
           <memAddrs> 0 |-> MEMADDR </memAddrs>
           ...
         </moduleInst>
         <memInst>
           <mAddr> MEMADDR </mAddr>
           <msize> SIZE </msize>
           <mdata> DATA => #setBytesRange(DATA, OFFSET, Int2Bytes({HEAP[BIGINT_IDX]}:>Int, BE, SIGN)) </mdata>
           ...
         </memInst>
         <bigIntHeap> HEAP </bigIntHeap>
      requires (OFFSET +Int lengthBytes(Int2Bytes({HEAP[BIGINT_IDX]}:>Int, BE, SIGN))) <=Int (SIZE *Int #pageSize())

    syntax BigIntOp ::= #setBigInt ( idx : Int , offset : Int , length : Int , Signedness )
 // ---------------------------------------------------------------------------------------
    rule <instrs> #setBigInt(BIGINT_IDX, OFFSET, LENGTH, SIGN) => . ... </instrs>
         <callee> CALLEE </callee>
         <account>
           <address> CALLEE </address>
           <codeIdx> MODIDX:Int </codeIdx>
           ...
         </account>
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
         <bigIntHeap> HEAP => HEAP [BIGINT_IDX <- Bytes2Int(#getBytesRange(DATA, OFFSET, LENGTH), BE, SIGN)] </bigIntHeap>
      requires (OFFSET +Int LENGTH) <=Int (SIZE *Int #pageSize())
```

```k
    // extern int32_t bigIntNew(void* context, long long smallValue);
    rule <instrs> hostCall("env", "bigIntNew", [ i64 .ValTypes ] -> [ i32 .ValTypes ]) => i32.const size(HEAP) ... </instrs>
         <locals> 0 |-> <i64> INITIAL </locals>
         <bigIntHeap> HEAP => HEAP[size(HEAP) <- INITIAL] </bigIntHeap>

    // extern int32_t bigIntUnsignedByteLength(void* context, int32_t reference);
    rule <instrs> hostCall("env", "bigIntUnsignedByteLength", [ i32 .ValTypes ] -> [ i32 .ValTypes ]) => i32.const lengthBytes(Int2Bytes({HEAP[IDX]}:>Int, BE, Unsigned)) ... </instrs>
         <locals> 0 |-> <i32> IDX </locals>
         <bigIntHeap> HEAP </bigIntHeap>

    // extern int32_t bigIntSignedByteLength(void* context, int32_t reference);
    rule <instrs> hostCall("env", "bigIntSignedByteLength", [ i32 .ValTypes ] -> [ i32 .ValTypes ]) => i32.const lengthBytes(Int2Bytes({HEAP[IDX]}:>Int, BE, Signed)) ... </instrs>
         <locals> 0 |-> <i32> IDX </locals>
         <bigIntHeap> HEAP </bigIntHeap>

    // extern int32_t bigIntGetUnsignedBytes(void* context, int32_t reference, int32_t byteOffset);
    rule <instrs> hostCall("env", "bigIntGetUnsignedBytes", [ i32 i32 .ValTypes ] -> [ i32 .ValTypes ]) => #getBigInt(IDX, OFFSET, Unsigned) ... </instrs>
         <locals> 0 |-> <i32> IDX  1 |-> <i32> OFFSET </locals>

    // extern int32_t bigIntGetSignedBytes(void* context, int32_t reference, int32_t byteOffset);
    rule <instrs> hostCall("env", "bigIntGetSignedBytes", [ i32 i32 .ValTypes ] -> [ i32 .ValTypes ]) => #getBigInt(IDX, OFFSET, Signed) ... </instrs>
         <locals> 0 |-> <i32> IDX  1 |-> <i32> OFFSET </locals>

    // extern void bigIntSetUnsignedBytes(void* context, int32_t destination, int32_t byteOffset, int32_t byteLength);
    rule <instrs> hostCall("env", "bigIntSetUnsignedBytes", [ i32 i32 i32 .ValTypes ] -> [ .ValTypes ]) => #setBigInt(IDX, OFFSET, LENGTH, Unsigned) ... </instrs>
         <locals> 0 |-> <i32> IDX 1 |-> <i32> OFFSET 2 |-> <i32> LENGTH </locals>

    // extern void bigIntSetSignedBytes(void* context, int32_t destination, int32_t byteOffset, int32_t byteLength);
    rule <instrs> hostCall("env", "bigIntSetSignedBytes", [ i32 i32 i32 .ValTypes ] -> [ .ValTypes ]) => #setBigInt(IDX, OFFSET, LENGTH, Signed) ... </instrs>
         <locals> 0 |-> <i32> IDX 1 |-> <i32> OFFSET 2 |-> <i32> LENGTH </locals>

    // extern void bigIntAdd(void* context, int32_t destination, int32_t op1, int32_t op2);
    rule <instrs> hostCall("env", "bigIntAdd", [ i32 i32 i32 .ValTypes ] -> [ .ValTypes ]) => . ... </instrs>
         <locals> 0 |-> <i32> DST  1 |-> <i32> OP1_IDX  2 |-> <i32> OP2_IDX </locals>
         <bigIntHeap> HEAP => HEAP [DST <- {HEAP[OP1_IDX]}:>Int +Int {HEAP[OP2_IDX]}:>Int] </bigIntHeap>

    // extern void bigIntSub(void* context, int32_t destination, int32_t op1, int32_t op2);
    rule <instrs> hostCall("env", "bigIntSub", [ i32 i32 i32 .ValTypes ] -> [ .ValTypes ]) => . ... </instrs>
         <locals> 0 |-> <i32> DST  1 |-> <i32> OP1_IDX  2 |-> <i32> OP2_IDX </locals>
         <bigIntHeap> HEAP => HEAP [DST <- {HEAP[OP1_IDX]}:>Int -Int {HEAP[OP2_IDX]}:>Int] </bigIntHeap>

    // extern void bigIntMul(void* context, int32_t destination, int32_t op1, int32_t op2);
    rule <instrs> hostCall("env", "bigIntMul", [ i32 i32 i32 .ValTypes ] -> [ .ValTypes ]) => . ... </instrs>
         <locals> 0 |-> <i32> DST  1 |-> <i32> OP1_IDX  2 |-> <i32> OP2_IDX </locals>
         <bigIntHeap> HEAP => HEAP [DST <- {HEAP[OP1_IDX]}:>Int *Int {HEAP[OP2_IDX]}:>Int] </bigIntHeap>

    // extern void bigIntTDiv(void* context, int32_t destination, int32_t op1, int32_t op2);
    rule <instrs> hostCall("env", "bigIntTDiv", [ i32 i32 i32 .ValTypes ] -> [ .ValTypes ]) => . ... </instrs>
         <locals> 0 |-> <i32> DST  1 |-> <i32> OP1_IDX  2 |-> <i32> OP2_IDX </locals>
         <bigIntHeap> HEAP => HEAP [DST <- {HEAP[OP1_IDX]}:>Int /Int {HEAP[OP2_IDX]}:>Int] </bigIntHeap>

    // extern int32_t bigIntSign(void* context, int32_t op);
    rule <instrs> hostCall("env", "bigIntSign", [ i32 .ValTypes ] -> [ i32 .ValTypes ])
               => i32.const #bigIntSign({HEAP[IDX]}:>Int)
                  ...
         </instrs>
         <locals> 0 |-> <i32> IDX </locals>
         <bigIntHeap> HEAP </bigIntHeap>

    // extern int32_t bigIntCmp(void* context, int32_t op1, int32_t op2);
    rule <instrs> hostCall("env", "bigIntCmp", [ i32 i32 .ValTypes ] -> [ i32 .ValTypes ])
               => i32.const #cmpInt({HEAP[IDX1]}:>Int, {HEAP[IDX2]}:>Int)
                  ...
         </instrs>
         <locals> 0 |-> <i32> IDX1  1 |-> <i32> IDX2 </locals>
         <bigIntHeap> HEAP </bigIntHeap>

    // extern void bigIntFinishSigned(void* context, int32_t reference);
    rule <instrs> hostCall("env", "bigIntFinishSigned", [ i32 .ValTypes ] -> [ .ValTypes ])
               => i32.const 0
               ~> #getBigInt(IDX, 0, Signed)
               ~> #finish
               ...
         </instrs>
         <locals> 0 |-> <i32> IDX </locals>

    // extern void bigIntGetUnsignedArgument(void *context, int32_t id, int32_t destination);
    rule <instrs> hostCall("env", "bigIntGetUnsignedArgument", [ i32 i32 .ValTypes ] -> [ .ValTypes ]) =>  . ... </instrs>
         <locals> 0 |-> <i32> ARG_IDX  1 |-> <i32> BIG_IDX </locals>
         <callingArguments> ARGS </callingArguments>
         <bigIntHeap> HEAP => HEAP [BIG_IDX <- #unsigned({ARGS[ARG_IDX]}:>Argument)] </bigIntHeap>

    // extern void bigIntGetSignedArgument(void *context, int32_t id, int32_t destination);
    rule <instrs> hostCall("env", "bigIntGetSignedArgument", [ i32 i32 .ValTypes ] -> [ .ValTypes ]) =>  . ... </instrs>
         <locals> 0 |-> <i32> ARG_IDX  1 |-> <i32> BIG_IDX </locals>
         <callingArguments> ARGS </callingArguments>
         <bigIntHeap> HEAP => HEAP [BIG_IDX <- #signed({ARGS[ARG_IDX]}:>Argument)] </bigIntHeap>

    // extern void bigIntGetCallValue(void *context, int32_t destination);
    rule <instrs> hostCall("env", "bigIntGetCallValue", [ i32 .ValTypes ] -> [ .ValTypes ]) => . ... </instrs>
         <locals> 0 |-> <i32> IDX </locals>
         <bigIntHeap> HEAP => HEAP[IDX <- VALUE] </bigIntHeap>
         <callValue> VALUE </callValue>
```

### Other Host Calls

The (incorrect) default implementation of a host call is to just return zero values of the correct type.

```k
    rule <instrs> hostCall("env", "asyncCall", [ DOM ] -> [ CODOM ]) => . ... </instrs>
         <valstack> VS => #zero(CODOM) ++ #drop(lengthValTypes(DOM), VS) </valstack>

endmodule
```
