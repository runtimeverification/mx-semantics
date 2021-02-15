```k
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

    syntax FuncCoverageDescription ::= fcd ( mod: Int, addr: Int, id: OptionalId ) [klabel(fcd), symbol]
 // ----------------------------------------------------------------------------------------------------

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
          <caller> .Bytes </caller>
          <callee> .Bytes </callee>
          <callValue> 0 </callValue>
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

### Sync With WASM VM

`#endWASM` waits for the WASM VM to finish the execution and check the return code.

```k
    syntax InternalCmd ::= "#endWASM"
 // ---------------------------------
    rule <commands> #endWASM => dropWorldState ... </commands>
         <returnCode> .ReturnCode => OK </returnCode>
         <instrs> . </instrs>

    rule <commands> #endWASM => #exception ... </commands>
         <returnCode> _:ExceptionCode </returnCode>
         <instrs> . </instrs>
```

### Elrond Exception Command

`#exception` drops the rest of the computation in the `commands` cell and reverts the state.

```k
    syntax InternalCmd ::= "#exception"
 // -----------------------------------
    rule <commands> (#exception ~> _) => popWorldState </commands> [priority(60)]
```

### Host Calls

Here, host calls are implemented, by defining the semantics when `hostCall(MODULE_NAME, EXPORT_NAME, TYPE)` is left on top of the `instrs` cell.

#### Host Call : finish

```k
    rule <instrs> hostCall("env", "finish", [ i32 i32 .ValTypes ] -> [ .ValTypes ]) => #local.get(0) ~> #local.get(1) ~> #finish ... </instrs>

    syntax InternalInstr ::= "#finish"
 // ----------------------------------
    rule <instrs> #finish => .K ... </instrs>
         <valstack> <i32> LENGTH : <i32> OFFSET : VS => VS </valstack>
         <callee> CALLEE </callee>
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
               => #setMem(CALLER, OFFSET)
                  ...
         </instrs>
         <locals> 0 |-> <i32> OFFSET </locals>
         <caller> CALLER </caller>

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

    rule <instrs> hostCall("env", "bigIntSub", [ i32 i32 i32 .ValTypes ] -> [ .ValTypes ]) => . ... </instrs>
         <locals> 0 |-> <i32> DST  1 |-> <i32> OP1_IDX  2 |-> <i32> OP2_IDX </locals>
         <bigIntHeap> HEAP => HEAP [DST <- {HEAP[OP1_IDX]}:>Int -Int {HEAP[OP2_IDX]}:>Int] </bigIntHeap>

    rule <instrs> hostCall("env", "bigIntMul", [ i32 i32 i32 .ValTypes ] -> [ .ValTypes ]) => . ... </instrs>
         <locals> 0 |-> <i32> DST  1 |-> <i32> OP1_IDX  2 |-> <i32> OP2_IDX </locals>
         <bigIntHeap> HEAP => HEAP [DST <- {HEAP[OP1_IDX]}:>Int *Int {HEAP[OP2_IDX]}:>Int] </bigIntHeap>

    rule <instrs> hostCall("env", "bigIntTDiv", [ i32 i32 i32 .ValTypes ] -> [ .ValTypes ]) => . ... </instrs>
         <locals> 0 |-> <i32> DST  1 |-> <i32> OP1_IDX  2 |-> <i32> OP2_IDX </locals>
         <bigIntHeap> HEAP => HEAP [DST <- {HEAP[OP1_IDX]}:>Int /Int {HEAP[OP2_IDX]}:>Int] </bigIntHeap>

    rule <instrs> hostCall("env", "bigIntSign", [ i32 .ValTypes ] -> [ i32 .ValTypes ])
               => i32.const #bigIntSign({HEAP[IDX]}:>Int)
                  ...
         </instrs>
         <locals> 0 |-> <i32> IDX </locals>
         <bigIntHeap> HEAP </bigIntHeap>

    rule <instrs> hostCall("env", "bigIntCmp", [ i32 i32 .ValTypes ] -> [ i32 .ValTypes ])
               => i32.const #cmpInt({HEAP[IDX1]}:>Int, {HEAP[IDX2]}:>Int)
                  ...
         </instrs>
         <locals> 0 |-> <i32> IDX1  1 |-> <i32> IDX2 </locals>
         <bigIntHeap> HEAP </bigIntHeap>

    rule <instrs> hostCall("env", "bigIntSetSignedBytes", [ i32 i32 i32 .ValTypes ] -> [ .ValTypes ]) => #setBigInt(IDX, OFFSET, LENGTH, Signed) ... </instrs>
         <locals> 0 |-> <i32> IDX 1 |-> <i32> OFFSET 2 |-> <i32> LENGTH </locals>

    rule <instrs> hostCall("env", "bigIntSetUnsignedBytes", [ i32 i32 i32 .ValTypes ] -> [ .ValTypes ]) => #setBigInt(IDX, OFFSET, LENGTH, Unsigned) ... </instrs>
         <locals> 0 |-> <i32> IDX 1 |-> <i32> OFFSET 2 |-> <i32> LENGTH </locals>

    rule <instrs> hostCall("env", "bigIntSignedByteLength", [ i32 .ValTypes ] -> [ i32 .ValTypes ]) => i32.const lengthBytes(Int2Bytes({HEAP[IDX]}:>Int, BE, Signed)) ... </instrs>
         <locals> 0 |-> <i32> IDX </locals>
         <bigIntHeap> HEAP </bigIntHeap>

    rule <instrs> hostCall("env", "bigIntUnsignedByteLength", [ i32 .ValTypes ] -> [ i32 .ValTypes ]) => i32.const lengthBytes(Int2Bytes({HEAP[IDX]}:>Int, BE, Unsigned)) ... </instrs>
         <locals> 0 |-> <i32> IDX </locals>
         <bigIntHeap> HEAP </bigIntHeap>

    rule <instrs> hostCall("env", "bigIntGetSignedBytes", [ i32 i32 .ValTypes ] -> [ i32 .ValTypes ]) => #getBigInt(IDX, OFFSET, Signed) ... </instrs>
         <locals> 0 |-> <i32> IDX  1 |-> <i32> OFFSET </locals>

    rule <instrs> hostCall("env", "bigIntGetUnsignedBytes", [ i32 i32 .ValTypes ] -> [ i32 .ValTypes ]) => #getBigInt(IDX, OFFSET, Unsigned) ... </instrs>
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

```k
    syntax Int ::= #unsigned( Argument ) [function, functional]
                 |   #signed( Argument ) [function, functional]
 // -----------------------------------------------------------
    rule #unsigned(A) => valueArg(A)
    rule #signed(A)   => valueArg(A)                                     requires notBool 2 ^Int (8 *Int lengthArg(A) -Int 1) <=Int valueArg(A)
    rule #signed(A)   => valueArg(A) -Int (2 ^Int (lengthArg(A) *Int 8)) requires         2 ^Int (8 *Int lengthArg(A) -Int 1) <=Int valueArg(A)
```

```k
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

#### Block Information

```k
    rule <instrs> hostCall("env", "getBlockTimestamp", [ .ValTypes ] -> [ i64 .ValTypes ]) => i64.const TIMESTAMP ... </instrs>
         <curBlockTimestamp> TIMESTAMP </curBlockTimestamp>

    rule <instrs> hostCall("env", "getBlockRandomSeed", [ i32 .ValTypes ] -> [ .ValTypes ])
               => #setMem(SEED, OFFSET)
                  ...
         </instrs>
         <locals> 0 |-> <i32> OFFSET </locals>
         <curBlockRandomSeed> SEED </curBlockRandomSeed>

```

#### Other Host Calls

The (incorrect) default implementation of a host call is to just return zero values of the correct type.

```k
    rule <instrs> hostCall("env", "asyncCall", [ DOM ] -> [ CODOM ]) => . ... </instrs>
         <valstack> VS => #zero(CODOM) ++ #drop(lengthValTypes(DOM), VS) </valstack>

    rule <instrs> hostCall("env", "signalError", [ i32 i32 .ValTypes ] -> [ .ValTypes ] )
               => #local.get(0) ~> #local.get(1) ~> #signalError ...
         </instrs>

    syntax InternalInstr ::= "#signalError"
 // ---------------------------------------
    rule <instrs> (#signalError ~> _) => .K </instrs>
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

    rule <instrs> hostCall("env", "transferValue", [ i32 i32 i32 i32 .ValTypes ] -> [ i32 .ValTypes ])
               => #local.get(0) ~> #local.get(1) ~> #local.get(2) ~> #local.get(3)
               ~> #transferValue
                  ...
         </instrs>

    syntax InternalInstr ::= "#transferValue"
                           | #transferValueAux ( Bytes, Bytes, Int )
 // ----------------------------------------------------------------
    rule <instrs> #transferValue
               => #transferValueAux(CALLEE, #getBytesRange(DATA, DESTOFFSET, 32), Bytes2Int(#getBytesRange(DATA, VALUEOFFSET, 32), BE, Unsigned))
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

    rule <instrs> #transferValueAux(ACCTFROM, ACCTTO, VALUE) => i32.const 0 ... </instrs>
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

### Calling Contracts

```k
    syntax Accounts ::= "{" AccountsCellFragment "|" Set "}"

    syntax InternalCmd ::= "pushWorldState"
 // ---------------------------------------
    rule <commands> pushWorldState => .K ... </commands>
         <interimStates> (.List => ListItem({ ACCTDATA | ACCTS })) ... </interimStates>
         <activeAccounts> ACCTS    </activeAccounts>
         <accounts>       ACCTDATA </accounts>
      [priority(60)]

    syntax InternalCmd ::= "popWorldState"
 // --------------------------------------
    rule <commands> popWorldState => .K ... </commands>
         <interimStates> (ListItem({ ACCTDATA | ACCTS }) => .List) ... </interimStates>
         <activeAccounts> _ => ACCTS    </activeAccounts>
         <accounts>       _ => ACCTDATA </accounts>
      [priority(60)]

    syntax InternalCmd ::= "dropWorldState"
 // ---------------------------------------
    rule <commands> dropWorldState => .K ... </commands>
         <interimStates> (ListItem(_) => .List) ... </interimStates>
      [priority(60)]

    syntax InternalCmd ::= transferFunds ( Bytes, Bytes, Int )
 // ----------------------------------------------------------
    rule <commands> transferFunds(ACCT, ACCT, VALUE) => . ... </commands>
         <account>
           <address> ACCT </address>
           <balance> ORIGFROM </balance>
           ...
         </account>
      requires VALUE <=Int ORIGFROM
      [priority(60)]

    rule <commands> transferFunds(ACCTFROM, ACCTTO, VALUE) => . ... </commands>
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

    syntax InternalCmd ::= callContract ( Bytes, Bytes, Int,     String, List, Int, Int ) [klabel(callContractString)]
                         | callContract ( Bytes, Bytes, Int, WasmString, List, Int, Int ) [klabel(callContractWasmString)]
                         | mkCall       ( Bytes, Bytes, Int, WasmString, List, Int, Int )
 // ----------------------------------------------------------------------------------------------------------------------
    rule <commands> callContract(FROM, TO, VALUE, FUNCNAME:String, ARGS, GASLIMIT, GASPRICE)
                 => callContract(FROM, TO, VALUE, #unparseWasmString("\"" +String FUNCNAME +String "\""), ARGS, GASLIMIT, GASPRICE)
                    ...
         </commands>
      [priority(60)]

    rule <commands> callContract(FROM, TO, VALUE, FUNCNAME:WasmStringToken, ARGS, GASLIMIT, GASPRICE)
                 => pushWorldState
                 ~> transferFunds(FROM, TO, VALUE)
                 ~> mkCall(FROM, TO, VALUE, FUNCNAME, ARGS, GASLIMIT, GASPRICE)
                 ~> #endWASM                
                    ...
         </commands>
      [priority(60)]

    rule <commands> mkCall(FROM, TO, VALUE, FUNCNAME:WasmStringToken, ARGS, _GASLIMIT, _GASPRICE) => .K ... </commands>
         <callingArguments> _ => ARGS </callingArguments>
         <caller> _ => FROM </caller>
         <callee> _ => TO   </callee>
         <callValue> _ => VALUE </callValue>
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

endmodule
```

## Mandos Testing Framework

```k
module MANDOS
    imports ELROND

    configuration
      <mandos>
        <k> $PGM:Steps </k>
        <newAddresses> .Map </newAddresses>
        <checkedAccounts> .Set </checkedAccounts>
        <elrond/>
        <exit-code exit=""> 0 </exit-code>
      </mandos>
```

### Wasm and Elrond Interaction

Only take the next step once both the Elrond node and Wasm are done executing.

```k
    syntax Step ::= "#wait"
 // -----------------------
    rule <k> #wait => . ... </k>
         <commands> . </commands>
         <instrs> . </instrs>

    syntax Steps ::= List{Step, ""} [klabel(mandosSteps), symbol]
 // -------------------------------------------------------------
    rule <k> .Steps => . </k> [priority(60)]
    rule <k> S:Step SS:Steps => S ~> SS ... </k> [priority(60)]

    syntax Step ::= "setExitCode" Int
 // ---------------------------------
    rule <k> setExitCode I => . ... </k>
         <commands> . </commands>
         <instrs> . </instrs>
         <exit-code> _ => I </exit-code>
      [priority(60)]

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
      [priority(60)]
```

### State Setup

```k
    syntax Step ::= setAccount    ( address: Address, nonce: Int, balance: Int, code: Code, storage: Map )  [klabel(setAccount), symbol]
                  | setAccountAux ( address: Bytes, nonce: Int, balance: Int, code: Code, storage: Map )    [klabel(setAccountAux), symbol]
                  | createAndSetAccount ( Bytes, Int, Int, CodeIndex, Map)                                  [klabel(createAndSetAccount), symbol]
 // ---------------------------------------------------------------------------------------------------------------------------------------------
    rule <k> setAccount(ADDRESS, NONCE, BALANCE, CODE, STORAGE)
          => setAccountAux(#address2Bytes(ADDRESS), NONCE, BALANCE, CODE, STORAGE) ... </k>
      [priority(60)]

    rule <k> setAccountAux(ADDRESS, NONCE, BALANCE, .Code, STORAGE)
          => createAndSetAccount(ADDRESS, NONCE, BALANCE, .CodeIndex, STORAGE) ... </k>
      [priority(60)]

    rule <k> setAccountAux(ADDRESS, NONCE, BALANCE, MODULE:ModuleDecl, STORAGE)
          => MODULE ~> createAndSetAccount(ADDRESS, NONCE, BALANCE, NEXTIDX, STORAGE) ... </k>
         <nextModuleIdx> NEXTIDX </nextModuleIdx>
      [priority(60)]

    rule <k> createAndSetAccount(ADDRESS, NONCE, BALANCE, CODEIDX, STORAGE) => #wait ... </k>
         <commands> . => createAccount(ADDRESS) ~> setAccountFields(ADDRESS, NONCE, BALANCE, CODEIDX, STORAGE) </commands>
      [priority(60)]

    syntax Step ::= newAddress    ( Address, Int, Address ) [klabel(newAddress), symbol]
                  | newAddressAux ( Bytes, Int, Bytes )     [klabel(newAddressAux), symbol]
 // ---------------------------------------------------------------------------------------
    rule <k> newAddress(CREATOR, NONCE, NEW)
          => newAddressAux(#address2Bytes(CREATOR), NONCE, #address2Bytes(NEW)) ... </k>
      [priority(60)]

    rule <k> newAddressAux(CREATOR, NONCE, NEW) => . ... </k>
         <newAddresses> NEWADDRESSES => NEWADDRESSES [tuple(CREATOR, NONCE) <- NEW] </newAddresses>
      [priority(60)]

    syntax AddressNonce ::= tuple( Bytes , Int )
 // ----------------------------------------------

    syntax Step      ::= setCurBlockInfo  ( BlockInfo ) [klabel(setCurBlockInfo), symbol]
                       | setPrevBlockInfo ( BlockInfo ) [klabel(setPrevBlockInfo), symbol]
    syntax BlockInfo ::= blockTimestamp  ( Int )   [klabel(blockTimestamp), symbol]
                       | blockNonce      ( Int )   [klabel(blockNonce), symbol]
                       | blockRound      ( Int )   [klabel(blockRound), symbol]
                       | blockEpoch      ( Int )   [klabel(blockEpoch), symbol]
                       | blockRandomSeed ( Bytes ) [klabel(blockRandomSeed), symbol]
 // --------------------------------------------------------------------------------
    rule <k> setCurBlockInfo(blockTimestamp(TIMESTAMP)) => . ... </k>
         <curBlockTimestamp> _ => TIMESTAMP </curBlockTimestamp>
      [priority(60)]

    rule <k> setCurBlockInfo(blockNonce(NONCE)) => . ... </k>
         <curBlockNonce> _ => NONCE </curBlockNonce>
      [priority(60)]

    rule <k> setCurBlockInfo(blockRound(ROUND)) => . ... </k>
         <curBlockRound> _ => ROUND </curBlockRound>
      [priority(60)]

    rule <k> setCurBlockInfo(blockEpoch(EPOCH)) => . ... </k>
         <curBlockEpoch> _ => EPOCH </curBlockEpoch>
      [priority(60)]

    rule <k> setCurBlockInfo(blockRandomSeed(SEED)) => . ... </k>
         <curBlockRandomSeed> _ => SEED </curBlockRandomSeed>
      [priority(60)]

    rule <k> setPrevBlockInfo(blockTimestamp(TIMESTAMP)) => . ... </k>
         <prevBlockTimestamp> _ => TIMESTAMP </prevBlockTimestamp>
      [priority(60)]

    rule <k> setPrevBlockInfo(blockNonce(NONCE)) => . ... </k>
         <prevBlockNonce> _ => NONCE </prevBlockNonce>
      [priority(60)]

    rule <k> setPrevBlockInfo(blockRound(ROUND)) => . ... </k>
         <prevBlockRound> _ => ROUND </prevBlockRound>
      [priority(60)]

    rule <k> setPrevBlockInfo(blockEpoch(EPOCH)) => . ... </k>
         <prevBlockEpoch> _ => EPOCH </prevBlockEpoch>
      [priority(60)]

    rule <k> setPrevBlockInfo(blockRandomSeed(SEED)) => . ... </k>
         <prevBlockRandomSeed> _ => SEED </prevBlockRandomSeed>
      [priority(60)]
```

### Check State
```k
    syntax Step ::= checkAccountNonce    ( Address, Int ) [klabel(checkAccountNonce), symbol]
                  | checkAccountNonceAux ( Bytes, Int )   [klabel(checkAccountNonceAux), symbol]
 // --------------------------------------------------------------------------------------------
    rule <k> checkAccountNonce(ADDRESS, NONCE)
             => checkAccountNonceAux(#address2Bytes(ADDRESS), NONCE) ... </k>
      [priority(60)]

    rule <k> checkAccountNonceAux(ADDR, NONCE) => . ... </k>
         <account>
           <address> ADDR </address>
           <nonce> NONCE </nonce>
           ...
         </account>
      [priority(60)]

    syntax Step ::= checkAccountBalance    ( Address, Int ) [klabel(checkAccountBalance), symbol]
                  | checkAccountBalanceAux ( Bytes, Int )   [klabel(checkAccountBalanceAux), symbol]
 // ------------------------------------------------------------------------------------------------
    rule <k> checkAccountBalance(ADDRESS, BALANCE)
             => checkAccountBalanceAux(#address2Bytes(ADDRESS), BALANCE) ... </k>
      [priority(60)]

    rule <k> checkAccountBalanceAux(ADDR, BALANCE) => . ... </k>
         <account>
           <address> ADDR </address>
           <balance> BALANCE </balance>
           ...
         </account>
      [priority(60)]

    syntax Step ::= checkAccountStorage    ( Address, Map ) [klabel(checkAccountStorage), symbol]
                  | checkAccountStorageAux ( Bytes, Map )   [klabel(checkAccountStorageAux), symbol]
 // ------------------------------------------------------------------------------------------------
    rule <k> checkAccountStorage(ADDRESS, STORAGE)
             => checkAccountStorageAux(#address2Bytes(ADDRESS), STORAGE) ... </k>
      [priority(60)]

    rule <k> checkAccountStorageAux(ADDR, STORAGE) => . ... </k>
         <account>
           <address> ADDR </address>
           <storage> STORAGE </storage>
           ...
         </account>
      [priority(60)]

    syntax Step ::= checkAccountCode    ( Address, String ) [klabel(checkAccountCode), symbol]
                  | checkAccountCodeAux ( Bytes, String )   [klabel(checkAccountCodeAux), symbol]
 // ---------------------------------------------------------------------------------------------
    rule <k> checkAccountCode(ADDRESS, CODEPATH)
             => checkAccountCodeAux(#address2Bytes(ADDRESS), CODEPATH) ... </k>
      [priority(60)]

    rule <k> checkAccountCodeAux(ADDR, "") => . ... </k>
         <account>
           <address> ADDR </address>
           <codeIdx> .CodeIndex </codeIdx>
           ...
         </account>
      [priority(60)]

    rule <k> checkAccountCodeAux(ADDR, CODEPATH) => . ... </k>
         <account>
           <address> ADDR </address>
           <codeIdx> CODEINDEX </codeIdx>
           ...
         </account>
         <moduleInst>
           <modIdx> CODEINDEX </modIdx>
           <moduleMetadata>
             <moduleFileName> CODEPATH </moduleFileName>
             ...
           </moduleMetadata>
           ...
         </moduleInst>
      requires CODEPATH =/=String ""
      [priority(60)]

    syntax Step ::= checkedAccount    ( Address ) [klabel(checkedAccount), symbol]
                  | checkedAccountAux ( Bytes )   [klabel(checkedAccountAux), symbol]
 // ---------------------------------------------------------------------------------
    rule <k> checkedAccount(ADDRESS)
             => checkedAccountAux(#address2Bytes(ADDRESS)) ... </k>
      [priority(60)]

    rule <k> checkedAccountAux(ADDR) => . ... </k>
         <checkedAccounts> ... (.Set => SetItem(ADDR)) ... </checkedAccounts>
      [priority(60)]

    syntax Step ::= "checkNoAdditionalAccounts" [klabel(checkNoAdditionalAccounts), symbol]
 // ---------------------------------------------------------------------------------------
    rule <k> checkNoAdditionalAccounts => . ... </k>
         <checkedAccounts> CHECKEDACCTS </checkedAccounts>
         <activeAccounts> CHECKEDACCTS </activeAccounts>
      [priority(60)]

    syntax Step ::= "clearCheckedAccounts" [klabel(clearCheckedAccounts), symbol]
 // -----------------------------------------------------------------------------
    rule <k> clearCheckedAccounts => . ... </k>
         <checkedAccounts> _ => .Set </checkedAccounts>
      [priority(60)]
```

### Contract Interactions

```k
    syntax Step ::= scDeploy ( DeployTx, Expect ) [klabel(scDeploy), symbol]
 // ------------------------------------------------------------------------
    rule <k> scDeploy( TX, EXPECT ) => TX ~> EXPECT ... </k> [priority(60)]

    syntax DeployTx ::= deployTx    ( Address, Int, ModuleDecl, List, Int, Int ) [klabel(deployTx), symbol]
                      | deployTxAux ( Bytes, Int, ModuleDecl, List, Int, Int )   [klabel(deployTxAux), symbol]
 // ----------------------------------------------------------------------------------------------------------
    rule <k> deployTx(FROM, VALUE, MODULE, ARGS, GASLIMIT, GASPRICE)
          => deployTxAux(#address2Bytes(FROM), VALUE, MODULE, ARGS, GASLIMIT, GASPRICE) ... </k>
      [priority(60)]

    rule <k> deployTxAux(FROM, VALUE, MODULE, ARGS, GASLIMIT, GASPRICE)
          => MODULE ~> deployLastModule(FROM, VALUE, ARGS, GASLIMIT, GASPRICE) ... </k>
      [priority(60)]

    syntax Deployment ::= deployLastModule( Bytes, Int, List, Int, Int )
 // ----------------------------------------------------------------------
    rule <k> deployLastModule(FROM, VALUE, ARGS, GASLIMIT, GASPRICE) => #wait ... </k>
         <commands> . => createAccount(NEWADDR)
                 ~> setAccountCodeIndex(NEWADDR, NEXTIDX -Int 1)
                 ~> callContract(FROM, NEWADDR, VALUE, "init", ARGS, GASLIMIT, GASPRICE)
         </commands>
         <account>
            <address> FROM </address>
            <nonce> NONCE => NONCE +Int 1 </nonce>
            <balance> BALANCE => BALANCE -Int GASLIMIT *Int GASPRICE </balance>
            ...
         </account>
         <nextModuleIdx> NEXTIDX </nextModuleIdx>
         <newAddresses> ... tuple(FROM, NONCE) |-> NEWADDR:Bytes ... </newAddresses>
         <logging> S => S +String " -- deployLastModule: " +String Int2String(NEXTIDX -Int 1) </logging>
      [priority(60)]

    syntax Step ::= scCall( CallTx, Expect ) [klabel(scCall), symbol]
 // ----------------------------------------------------------------
    rule <k> scCall( TX, EXPECT ) => TX ~> EXPECT ... </k> [priority(60)]

    syntax CallTx ::= callTx    (from: Address, to: Address, value: Int, func: WasmString, args: List, gasLimit: Int, gasPrice: Int) [klabel(callTx), symbol]
                    | callTxAux (from: Bytes,   to: Bytes,   value: Int, func: WasmString, args: List, gasLimit: Int, gasPrice: Int) [klabel(callTxAux), symbol]
 // ------------------------------------------------------------------------------------------------------------------------------------------------------------
    rule <k> callTx(FROM, TO, VALUE, FUNCTION, ARGS, GASLIMIT, GASPRICE)
          => callTxAux(#address2Bytes(FROM), #address2Bytes(TO), VALUE, FUNCTION, ARGS, GASLIMIT, GASPRICE) ... </k>
      [priority(60)]

    rule <k> callTxAux(FROM, TO, VALUE, FUNCTION, ARGS, GASLIMIT, GASPRICE) => #wait ... </k>
         <commands> . => callContract(FROM, TO, VALUE, FUNCTION, ARGS, GASLIMIT, GASPRICE) </commands>
         <account>
            <address> FROM </address>
            <nonce> NONCE => NONCE +Int 1 </nonce>
            <balance> BALANCE => BALANCE -Int GASLIMIT *Int GASPRICE </balance>
            ...
         </account>
         <logging> S => S +String " -- call contract: " +String #parseWasmString(FUNCTION) </logging>
      [priority(60)]

    syntax Expect ::= ".Expect" [klabel(.Expect), symbol]
 // -------------------------------------------------------
    rule <k> .Expect => . ... </k> [priority(60)]

    syntax Step ::= transfer(TransferTx) [klabel(transfer), symbol]
 // -----------------------------------------------------
    rule <k> transfer(TX) => TX ... </k> [priority(60)]

    syntax TransferTx ::= transferTx    ( from: Address, to: Bytes, value: Int ) [klabel(transferTx), symbol]
                        | transferTxAux ( from: Bytes, to: Bytes, value: Int )   [klabel(transferTxAux), symbol]
 // ------------------------------------------------------------------------------------------------------------
    rule <k> transferTx(FROM, TO, VAL) => transferTxAux(#address2Bytes(FROM), #address2Bytes(TO), VAL) ... </k> [priority(60)]

    rule <k> transferTxAux(FROM, TO, VAL) => #wait ... </k>
         <commands> . => transferFunds(FROM, TO, VAL) </commands>
      [priority(60)]

    syntax Step ::= validatorReward(ValidatorRewardTx) [klabel(validatorReward), symbol]
 // ------------------------------------------------------------------------------------
    rule <k> validatorReward(TX) => TX ... </k> [priority(60)]

    syntax ValidatorRewardTx ::= validatorRewardTx    ( to: Address, value: Int) [klabel(validatorRewardTx), symbol]
                               | validatorRewardTxAux ( to: Bytes, value: Int )  [klabel(validatorRewardTxAux), symbol]
 // -------------------------------------------------------------------------------------------------------------------
    rule <k> validatorRewardTx(TO, VAL) => validatorRewardTxAux(#address2Bytes(TO), VAL) ... </k> [priority(60)]

    rule <k> validatorRewardTxAux(TO, VAL) => . ... </k>
         <account>
           <address> TO </address>
            <storage> STOR => STOR[String2Bytes("ELRONDrewards") <- #incBytes({STOR[String2Bytes("ELRONDrewards")]}:>Bytes, VAL)] </storage>
            <balance> TO_BAL => TO_BAL +Int VAL </balance>
            ...
         </account>
      [priority(60)]

    syntax Bytes ::= #incBytes(val : Bytes, inc : Int) [function]
 // -------------------------------------------------------------
    rule #incBytes(VAL, INC) => Int2Bytes(Bytes2Int(VAL, BE, Signed) +Int INC, BE, Signed)

```

### Assertions About State

```k
    syntax Step ::= Assertion

    syntax Assertion ::= #assertMessage ( Bytes )
 // ---------------------------------------------
    rule <k> #assertMessage(BS) => . ... </k>
         <message> BS </message>
      [priority(60)]
```

```k
endmodule
```
