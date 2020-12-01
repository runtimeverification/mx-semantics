```k
require "test.md"
require "wasm-text.md"

module MANDOS-SYNTAX
    imports MANDOS
    imports WASM-TEXT-SYNTAX
endmodule
```

## Auto Allocate Host Modules

When `AUTO-ALLOCATE` is imported, an new module will be automatically created and registered whenever necessary to resolve an import.
This makes it possible to implement host modules easily in K.
Accessing the import will result in an instruction being left on the `instrs` cell that can't be resolved in the regular Wasm semantics.
Instead, the embedder can add rules for handling the host import.

Currently, only function imports are supported.
Calling an imported host function will result in `hostCall(MODULE_NAME, FUNCTION_NAME, FUNCTION_TYPE)` being left on the `instrs` cell.

```k
module AUTO-ALLOCATE
    imports WASM-TEXT

    syntax Stmt ::= "newEmptyModule" WasmString
 // -------------------------------------------
    rule <instrs> newEmptyModule MODNAME => . ... </instrs>
         <moduleRegistry> MR => MR [ MODNAME <- NEXT ] </moduleRegistry>
         <nextModuleIdx> NEXT => NEXT +Int 1 </nextModuleIdx>
         <moduleInstances> ( .Bag => <moduleInst> <modIdx> NEXT </modIdx> ... </moduleInst>) ... </moduleInstances>

    syntax Stmts ::=  autoAllocModules( ModuleDecl, Map ) [function]
                   | #autoAllocModules( Defns     , Map ) [function]
 // -----------------------------------------------------
    rule  autoAllocModules(#module(... importDefns: IS), MR) => #autoAllocModules(IS, MR)
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

## Coverage

```k
module WASM-COVERAGE
    imports WASM

    configuration
      <wasmCoverage>
          <coveredFuncs> .Set </coveredFuncs>
          <notCoveredFuncs> .Map </notCoveredFuncs>
          <wasm/>
      </wasmCoverage>

    syntax FuncCoverageDescription ::= fcd(mod: Int, addr: Int, id: OptionalId) [klabel(fcd), symbol]
 // -------------------------------------------------------------------------------------------------

    rule <instrs> ( invoke I ):Instr ... </instrs>
         <coveredFuncs> COV => COV SetItem(NCOV[I]) </coveredFuncs>
         <notCoveredFuncs> NCOV => NCOV [I <- undef] </notCoveredFuncs>
      requires I in_keys(NCOV)
      [priority(10)]

    rule <instrs> allocfunc(MOD, ADDR, _, _, _, #meta(... id: OID)) ... </instrs>
         <notCoveredFuncs> NCOV => NCOV [ ADDR <- fcd(MOD, ADDR, OID)] </notCoveredFuncs>
      requires notBool ADDR in_keys(NCOV)
      [priority(10)]

endmodule
```

## Elrond Node

```k
module ELROND-NODE
    imports DOMAINS
    imports WASM-TEXT

    configuration
      <node>
        <commands> .K </commands>
        <callState>
          <callingArguments> .List </callingArguments>
          <caller> .Address </caller>
          <callee> .Address </callee>
          <callValue> 0 </callValue>
          <returnData> .Bytes </returnData>
          <returnStatus> .ReturnStatus </returnStatus>
        </callState>
        <accounts>
          <account multiplicity="*" type="Map">
             <address> .Address </address>
             <nonce> 0 </nonce>
             <balance> 0 </balance>
```

If the code is "", it means the account is not a contract.
If the code is "file:<some_path>", then it is a contract, and the corresponding Wasm module is stored in the module registry, with the account's name as key.
If the code is an index, it is the exact module index from the Wasm store which specifies the contract.

```k
             <code> .Code </code>
```
Storage maps byte arrays to byte arrays.

```k
             <storage> .Map </storage>
           </account>
         </accounts>
       </node>

    syntax ReturnStatus ::= ".ReturnStatus"
                          | "Finish"
 // --------------------------------

    syntax Address ::= ".Address" | WasmString
    syntax String  ::= address2String(Address) [function]
 // -----------------------------------------------------
    rule address2String(.Address) => ".Address"
    rule address2String(WS:WasmStringToken) => substrString(#parseWasmString(WS), 2, lengthString(#parseWasmString(WS)))

    syntax Code ::= ".Code" [klabel(.Code), symbol]
                  | WasmString | Int
 // --------------------------------
```

The value is an unsigned integer representation of the bytes.
The length is the number of bytes the argument represents.

```k
    syntax Argument ::= arg(value : Int, length : Int) [klabel(tupleArg), symbol]
 // -----------------------------------------------------------------------------

    syntax Int ::= valueArg  ( Argument ) [function, functional]
                 | lengthArg ( Argument ) [function, functional]
 // ------------------------------------------------------------
    rule valueArg (arg(V, _)) => V
    rule lengthArg(arg(_, L)) => L
```

```k
endmodule
```

## Connecting Node and Wasm

```k
module ELROND
    imports WASM-TEXT
    imports WASM-COVERAGE
    imports AUTO-ALLOCATE
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

### Synchronization

In theory, the node and the Wasm engine can run in parallel.
For simplicity of debugging and profiling, we want to keep the semantics deterministic.
When control gets passed to the Wasm engine by putting commands on the `instrs` cell, the node will `#wait` until the Wasm engine is done executing.

```k
    syntax Wait ::= "#wait"
 // ----------------------
    rule <commands> #wait => . ... </commands>
         <instrs> . </instrs>
```

Parallelized semantics can be achieved by instead using the following rule:

```
    syntax Wait ::= "#wait"
 // --------------------
    rule <commands> #wait => . ... </commands>
```

### Host Calls

Here, host calls are implemented, by defining the semantics when `hostCall(MODULE_NAME, EXPORT_NAME, TYPE)` is left on top of the `instrs` cell.

#### Completing the Call

```k
    rule <instrs> hostCall("env", "finish", [ i32 i32 .ValTypes ] -> [ .ValTypes ]) => local.get 0 ~> local.get 1 ~> #finish ... </instrs>

    syntax EndCall ::= "#finish"
 // ----------------------------
    rule <instrs> #finish => #done ... </instrs>
         <valstack> <i32> LENGTH : <i32> OFFSET : VS => VS </valstack>
         <callee> CALLEE </callee>
         <returnData> _ => #getBytesRange(DATA, OFFSET, LENGTH) </returnData>
         <returnStatus> _ => Finish </returnStatus>
         <account>
           <address> CALLEE </address>
           <code> MODIDX:Int </code>
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


    syntax Done ::= "#done"
 // -----------------------
    rule <instrs> #done ~> _REST => . </instrs>
```

#### Call State

```k
    rule <instrs> hostCall("env", "getNumArguments", [ .ValTypes ] -> [ i32 .ValTypes ]) => i32.const size(ARGS) ... </instrs>
         <callingArguments> ARGS </callingArguments>

    rule <instrs> hostCall("env", "getArgumentLength", [ i32 .ValTypes ] -> [ i32 .ValTypes ]) => i32.const lengthArg({ARGS[IDX]}:>Argument) ... </instrs>
         <locals> 0 |-> <i32> IDX </locals>
         <callingArguments> ARGS </callingArguments>
      requires IDX <Int size(ARGS)

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

    rule <instrs> hostCall("env", "getCaller", [ i32 .ValTypes ] -> [ .ValTypes ])
               => #setMem(String2Bytes(address2String(CALLER)), OFFSET)
                  ...
         </instrs>
         <locals> 0 |-> <i32> OFFSET </locals>
         <caller> CALLER </caller>

    syntax MemOp ::= #setMem ( bytes : Bytes, offset : Int )
                   | #getMem ( offset : Int , lenght : Int )
 // --------------------------------------------------------
    rule <instrs> #setMem(BS, OFFSET) => . ... </instrs>
         <callee> CALLEE </callee>
         <account>
           <address> CALLEE </address>
           <code> MODIDX:Int </code>
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
           <code> MODIDX:Int </code>
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

#### BigInt Heap

```k
    rule <instrs> hostCall("env", "bigIntNew", [ i64 .ValTypes ] -> [ i32 .ValTypes ]) => i32.const size(HEAP) ... </instrs>
         <locals> 0 |-> <i64> INITIAL </locals>
         <bigIntHeap> HEAP => HEAP[size(HEAP) <- INITIAL] </bigIntHeap>

    rule <instrs> hostCall("env", "bigIntGetCallValue", [ i32 .ValTypes ] -> [ .ValTypes ]) => . ... </instrs>
         <locals> 0 |-> <i32> IDX </locals>
         <bigIntHeap> HEAP => HEAP[IDX <- VALUE] </bigIntHeap>
         <callValue> VALUE </callValue>

    rule <instrs> hostCall("env", "bigIntAdd", [ i32 i32 i32 .ValTypes ] -> [ .ValTypes ]) => . ... </instrs>
         <locals> 0 |-> <i32> DST  1 |-> <i32> OP1_IDX  2 |-> <i32> OP2_IDX </locals>
         <bigIntHeap> HEAP => HEAP [DST <- {HEAP[OP1_IDX]}:>Int +Int {HEAP[OP2_IDX]}:>Int] </bigIntHeap>

    rule <instrs> hostCall("env", "bigIntCmp", [ i32 i32 .ValTypes ] -> [ i32 .ValTypes ]) => i32.const cmpInt({HEAP[IDX1]}:>Int, {HEAP[IDX2]}:>Int) ... </instrs>
         <locals> 0 |-> <i32> IDX1  1 |-> <i32> IDX2 </locals>
         <bigIntHeap> HEAP </bigIntHeap>

    rule <instrs> hostCall("env", "bigIntSetSignedBytes", [ i32 i32 i32 .ValTypes ] -> [ .ValTypes ]) => #setBigInt(IDX, OFFSET, LENGTH, Signed) ... </instrs>
         <locals> 0 |-> <i32> IDX 1 |-> <i32> OFFSET 2 |-> <i32> LENGTH </locals>

    rule <instrs> hostCall("env", "bigIntSignedByteLength", [ i32 .ValTypes ] -> [ i32 .ValTypes ]) => i32.const lengthBytes(Int2Bytes({HEAP[IDX]}:>Int, BE, Signed)) ... </instrs>
         <locals> 0 |-> <i32> IDX </locals>
         <bigIntHeap> HEAP </bigIntHeap>

    rule <instrs> hostCall("env", "bigIntGetSignedBytes", [ i32 i32 .ValTypes ] -> [ i32 .ValTypes ]) => #getBigInt(IDX, OFFSET, Signed) ... </instrs>
         <locals> 0 |-> <i32> IDX  1 |-> <i32> OFFSET </locals>

    rule <instrs> hostCall("env", "bigIntGetSignedArgument", [ i32 i32 .ValTypes ] -> [ .ValTypes ]) =>  . ... </instrs>
         <locals> 0 |-> <i32> ARG_IDX  1 |-> <i32> BIG_IDX </locals>
         <callingArguments> ARGS </callingArguments>
         <bigIntHeap> HEAP => HEAP [BIG_IDX <- #signed({ARGS[ARG_IDX]}:>Argument)] </bigIntHeap>

    rule <instrs> hostCall("env", "bigIntGetUnsignedArgument", [ i32 i32 .ValTypes ] -> [ .ValTypes ]) =>  . ... </instrs>
         <locals> 0 |-> <i32> ARG_IDX  1 |-> <i32> BIG_IDX </locals>
         <callingArguments> ARGS </callingArguments>
         <bigIntHeap> HEAP => HEAP [BIG_IDX <- #unsigned({ARGS[ARG_IDX]}:>Argument)] </bigIntHeap>

    rule <instrs> hostCall("env", "bigIntFinishSigned", [ i32 .ValTypes ] -> [ .ValTypes ])
               => i32.const 0
               ~> #getBigInt(IDX, 0, Signed)
               ~> #finish
               ...
         </instrs>
         <locals> 0 |-> <i32> IDX </locals>
```

Note: The Elrond host API interprets bytes as big-endian when setting BigInts.

```k
    syntax BigIntOp ::= #getBigInt ( idx : Int , offset : Int , Signedness )
 // ------------------------------------------------------------------------
    rule <instrs> #getBigInt(BIGINT_IDX, OFFSET, SIGN) => i32.const lengthBytes(Int2Bytes({HEAP[BIGINT_IDX]}:>Int, BE, SIGN)) ...</instrs>
         <callee> CALLEE </callee>
         <account>
           <address> CALLEE </address>
           <code> MODIDX:Int </code>
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
           <code> MODIDX:Int </code>
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

    syntax Bytes ::= #getBytesRange ( Bytes , Int , Int ) [function]
 // ----------------------------------------------------------------
    rule #getBytesRange(BS, OFFSET, LENGTH) => substrBytes(BS, OFFSET, OFFSET +Int LENGTH)

    syntax Bytes ::= #setBytesRange ( Bytes , Int , Bytes ) [function]
 // ------------------------------------------------------------------
    rule #setBytesRange(BS, OFFSET, NEW) => replaceAtBytes(padRightBytes(BS, OFFSET +Int lengthBytes(NEW), 0), OFFSET, NEW)
```

```k
    syntax Int ::= #unsigned( Argument ) [function, functional]
                 |   #signed( Argument ) [function, functional]
 // -----------------------------------------------------------
    rule #unsigned(A) => valueArg(A)
    rule #signed(A)   => valueArg(A)                             requires notBool 2 ^Int (lengthArg(A) -Int 1) <=Int valueArg(A)
    rule #signed(A)   => valueArg(A) -Int (2 ^Int lengthArg(A)) requires         2 ^Int (lengthArg(A) -Int 1) <=Int valueArg(A)
```

```k
    syntax Int ::= cmpInt ( Int , Int ) [function, functional]
 // ----------------------------------------------------------
    rule cmpInt(I1, I2) => -1 requires I1  <Int I2
    rule cmpInt(I1, I2) =>  1 requires I1  >Int I2
    rule cmpInt(I1, I2) =>  0 requires I1 ==Int I2
```

#### Storage

Storing a value returns a status code indicating if and how the storage was modified.

TODO: Implement [reserved keys and read-only runtimes](https://github.com/ElrondNetwork/arwen-wasm-vm/blob/d6ea0489081f81fefba002609c34ece1365373dd/arwen/contexts/storage.go#L111).

```k
    rule <instrs> hostCall("env", "storageLoadLength", [ i32 i32 .ValTypes ] -> [ i32 .ValTypes ] ) => #getMem(KEYOFFSET, KEYLENGTH) ~> #storageLoad ~> #dropBytes ... </instrs>
         <locals>
           0 |-> <i32> KEYOFFSET
           1 |-> <i32> KEYLENGTH
         </locals>

    rule <instrs> hostCall("env", "storageLoad", [ i32 i32 i32 .ValTypes ] -> [ i32 .ValTypes ] ) => #getMem(KEYOFFSET, KEYLENGTH) ~> #storageLoad ~> #bytesToSetMem(VALOFFSET) ... </instrs>
         <locals>
           0 |-> <i32> KEYOFFSET
           1 |-> <i32> KEYLENGTH
           2 |-> <i32> VALOFFSET
         </locals>

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

    rule <instrs> hostCall("env", "int64storageStore", [ i32 i32 i64 .ValTypes ] -> [ i32 .ValTypes ] )
               => #getMem(KEYOFFSET, KEYLENGTH)
               ~> #pushBytes(Int2Bytes(8, VALUE, BE))
               ~> #storageStore
                  ...
         </instrs>
         <locals>
           0 |-> <i32> KEYOFFSET
           1 |-> <i32> KEYLENGTH
           2 |-> <i64> VALUE
         </locals>

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
           <code> MODIDX </code>
           ...
         </account>

    rule <instrs> #storageLoad => i32.const lengthBytes({STORAGE[KEY]}:>Bytes) ~> ... </instrs>
         <bytesStack> KEY : STACK => {STORAGE[KEY]}:>Bytes : STACK </bytesStack>
         <callee> CALLEE </callee>
         <account>
           <address> CALLEE </address>
           <storage> STORAGE </storage>
           <code> MODIDX </code>
           ...
         </account>

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

#### Other Host Calls

The (incorrect) default implementation of a host call is to just return zero values of the correct type.

```k
    rule <instrs> hostCall("env", "asyncCall", [ DOM ] -> [ CODOM ]) => . ... </instrs>
         <valstack> VS => #zero(CODOM) ++ #drop(lengthValTypes(DOM), VS) </valstack>
```

### Managing Accounts

Initialize account: if the address is already present with some value, add value to it, otherwise create the account.

```k
    syntax InitAccount ::= initAccount ( Address , Code )
 // -----------------------------------------------------
    rule <commands> initAccount(ADDR, CODE) => . ... </commands>
         <account>
           <address> ADDR </address>
           <code> .Code => CODE </code>
           ...
         </account>
         <logging> S => S +String " -- initAccount existing " +String address2String(ADDR) </logging>

    rule <commands> initAccount(ADDR, CODE) => . ... </commands>
         <accounts>
           ( .Bag
          => <account>
               <address> ADDR </address>
               <code> CODE </code>
               ...
             </account>
           )
           ...
         </accounts>
         <logging> S => S +String " -- initAccount new" +String address2String(ADDR) </logging>

    syntax CallContract ::= callContract ( Address , Address , Int ,     String , List , Int , Int ) [klabel(callContractString)]
                          | callContract ( Address , Address , Int , WasmString , List , Int , Int ) [klabel(callContractWasmString)]
 // ---------------------------------------------------------------------------------------------------------------------------------
    rule <commands> callContract(FROM, TO, VALUE, FUNCNAME:String, ARGS, GASLIMIT, GASPRICE) => callContract(FROM, TO, VALUE, #unparseWasmString("\"" +String FUNCNAME +String "\""), ARGS, GASLIMIT, GASPRICE) ... </commands>

    rule <commands> callContract(FROM, TO, VALUE, FUNCNAME:WasmStringToken, ARGS, _GASLIMIT, _GASPRICE) => #wait ... </commands>
         <callingArguments> _ => ARGS </callingArguments>
         <caller> _ => FROM </caller>
         <callee> _ => TO   </callee>
         <callValue> _ => VALUE </callValue>
         <bigIntHeap> _ => .Map </bigIntHeap>
         <account>
           <address> TO </address>
           <code> CODE:Int </code>
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

endmodule
```

## Mandos Testing Framework

```k
module MANDOS
    imports ELROND
    imports WASM-AUXIL

    configuration
      <mandos>
        <k> $PGM:Steps </k>
        <newAddresses> .Map </newAddresses>
        <elrond/>
        <exit-code exit=""> 0 </exit-code>
      </mandos>
```

### Wasm and Elrond Interaction

Only take the next step once both the Elrond node and Wasm are done executing.

```k
    rule <k> #wait => . ... </k>
         <commands> . </commands>
         <instrs> . </instrs>

    syntax Steps ::= List{Step, ""} [klabel(mandosSteps), symbol]
 // -------------------------------------------------------------
    rule <k> .Steps => . </k>
    rule <k> S:Step SS:Steps => S ~> SS ... </k>

    syntax Step ::= "setExitCode" Int
 // ---------------------------------
    rule <k> setExitCode I => . ... </k>
         <commands> . </commands>
         <instrs> . </instrs>
         <exit-code> _ => I </exit-code>

    syntax Step ::= ModuleDecl
 // --------------------------
    rule <k> (module _:OptionalId _:Defns):ModuleDecl #as M => #wait ... </k>
          <instrs> . => sequenceStmts(text2abstract(M .Stmts)) </instrs>
    rule <k> M:ModuleDecl => #wait ... </k>
          <instrs> . => M </instrs>
      [owise]

    syntax Step ::= "register" String [klabel(register), symbol]
 // ------------------------------------------------------------
    rule <k> register NAME => . ... </k>
         <moduleRegistry> REG => REG [NAME <- IDX -Int 1] </moduleRegistry>
         <nextModuleIdx> IDX </nextModuleIdx>
```

### State Setup

```k
    syntax Step ::= setAccount(Address, Int, Int, Code, Map) [klabel(setAccount), symbol]
 // -------------------------------------------------------------------------------------
    rule <k> setAccount(ADDRESS, NONCE, BALANCE, CODE, STORAGE) => . ... </k>
         <accounts>
           ( .Bag
          => <account>
               <address> ADDRESS </address>
               <nonce> NONCE </nonce>
               <balance> BALANCE </balance>
               <code> CODE </code>
               <storage> STORAGE </storage>
             </account>
           )
           ...
         </accounts>

    syntax Step ::= newAddress(Address, Int, Address) [klabel(newAddress), symbol]
 // ------------------------------------------------------------------------------
    rule <k> newAddress(CREATOR, NONCE, NEW) => . ... </k>
         <newAddresses> NEWADDRESSES => NEWADDRESSES [tuple(CREATOR, NONCE) <- NEW] </newAddresses>

    syntax AddressNonce ::= tuple( Address , Int )
 // ----------------------------------------------

    syntax Step      ::=  currentBlockInfo(BlockInfo) [klabel( currentBlockInfo), symbol]
                       | previousBlockInfo(BlockInfo) [klabel(previousBlockInfo), symbol]
    syntax BlockInfo ::= blockTimestamp(Int) [klabel(blockTimestamp), symbol]
                       | blockNonce(Int)     [klabel(blockNonce), symbol]
                       | blockRound(Int)     [klabel(blockRound), symbol]
                       | blockEpoch(Int)     [klabel(blockEpoch), symbol]
 // ---------------------------------------------------------------------
```

### Contract Interactions

```k
    syntax Step ::= scDeploy( DeployTx, Expect ) [klabel(scDeploy), symbol]
 // ----------------------------------------------------------------------
    rule <k> scDeploy( TX, EXPECT ) => TX ~> EXPECT ... </k>

    syntax DeployTx ::= deployTx( Address, Int , ModuleDecl , List , Int , Int ) [klabel(deployTx), symbol]
 // -------------------------------------------------------------------------------------------------------
    rule <k> deployTx(FROM, VALUE, MODULE, ARGS, GASLIMIT, GASPRICE) => MODULE ~> deployLastModule(FROM, VALUE, ARGS, GASLIMIT, GASPRICE) ... </k>

    syntax Deployment ::= deployLastModule( Address, Int, List, Int, Int )
 // ----------------------------------------------------------------------
    rule <k> deployLastModule(FROM, VALUE, ARGS, GASLIMIT, GASPRICE) => #wait ... </k>
         <commands> . => initAccount(NEWADDR, NEXTIDX -Int 1) ~> callContract(FROM, NEWADDR, VALUE, "init", ARGS, GASLIMIT, GASPRICE) </commands>
         <account>
            <address> FROM </address>
            <nonce> NONCE </nonce>
            ...
         </account>
         <nextModuleIdx> NEXTIDX </nextModuleIdx>
         <newAddresses> ... tuple(FROM, NONCE) |-> NEWADDR:Address ... </newAddresses>
         <logging> S => S +String " -- deployLastModule: " +String Int2String(NEXTIDX -Int 1) </logging>

    syntax Step ::= scCall( CallTx, Expect ) [klabel(scCall), symbol]
 // ----------------------------------------------------------------
    rule <k> scCall( TX, EXPECT ) => TX ~> EXPECT ... </k>

    syntax CallTx ::= callTx(from : Address, to : Address, value : Int, func : WasmString, args : List, gasLimit : Int, gasPrice : Int) [klabel(callTx), symbol]
 // ------------------------------------------------------------------------------------------------------------------------------------------------------------
    rule <k> callTx(FROM, TO, VALUE, FUNCTION, ARGS, GASLIMIT, GASPRICE) => #wait ... </k>
         <commands> . => callContract(FROM, TO, VALUE, FUNCTION, ARGS, GASLIMIT, GASPRICE) </commands>
         <logging> S => S +String " -- call contract: " +String #parseWasmString(FUNCTION) </logging>

    syntax Expect ::= ".Expect" [klabel(.Expect), symbol]
 // -------------------------------------------------------
    rule <k> .Expect => . ... </k>

    syntax Step ::= checkState() [klabel(checkState), symbol]
 // ---------------------------------------------------------

    syntax Step ::= transfer(TransferTx) [klabel(transfer), symbol]
 // -----------------------------------------------------
    rule <k> transfer(TX) => TX ... </k>

    syntax TransferTx ::= transferTx(from : Address, to : Address, value : Int) [klabel(transferTx), symbol]
 // --------------------------------------------------------------------------------------------------------
    rule <k> transferTx(FROM, TO, VAL) => . ... </k>
         <account>
           <address> FROM </address>
           <balance> FROM_BAL => FROM_BAL -Int VAL </balance>
           ...
         </account>
         <account>
           <address> TO </address>
           <balance> TO_BAL => TO_BAL +Int VAL </balance>
           ...
         </account>
      requires FROM_BAL >=Int VAL

    syntax Step ::= validatorReward(ValidatorRewardTx) [klabel(validatorReward), symbol]
 // ------------------------------------------------------------------------------------
    rule <k> validatorReward(TX) => TX ... </k>

    syntax ValidatorRewardTx ::= validatorRewardTx(to : Address, value : Int) [klabel(validatorRewardTx), symbol]
 // ------------------------------------------------------------------------------------------------
    rule <k> validatorRewardTx(TO, VAL) => . ... </k>
         <account>
           <address> TO </address>
            <storage> STOR => STOR[String2Bytes("ELRONDrewards") <- #incBytes({STOR[String2Bytes("ELRONDrewards")]}:>Bytes, VAL)] </storage>
            ...
         </account>

    syntax Bytes ::= #incBytes(val : Bytes, inc : Int) [function]
 // -------------------------------------------------------------
    rule #incBytes(VAL, INC) => Int2Bytes(Bytes2Int(VAL, BE, Signed) +Int INC, BE, Signed)

```

### Assertions About State

```k
    syntax Step ::= Assertion
```

```k
    syntax Assertion ::= #assertReturnData(Bytes)
 // ---------------------------------------------
    rule <k> #assertReturnData(BS) => . ... </k>
         <returnData> BS </returnData>
```

```k
endmodule
```
