Elrond Node
===========

```k
require "data/list-bytes.k"
require "data/map-bytes-to-bytes.k"
require "data/map-int-to-bytes.k"
require "wasm-semantics/wasm.md"

module ELROND-NODE
    imports DOMAINS
    imports LIST-BYTES
    imports MAP-BYTES-TO-BYTES
    imports MAP-INT-TO-BYTES
    imports WASM

    configuration
      <node>
        <commands> .K </commands>
        <callState>
          // input
          <callee> .Bytes </callee>
          <vmInput>
            <caller> .Bytes </caller>
            <callArgs> .ListBytes </callArgs>
            <callValue> 0 </callValue>
            <esdtTransfers> .List </esdtTransfers>
            // gas
            <gasProvided> 0 </gasProvided>
            <gasPrice> 0 </gasPrice>
          </vmInput>
          // executional
          // every contract call uses its own wasm module instance, managed data heaps, and bytesStack.
          <wasm/>
          <bigIntHeap> .Map </bigIntHeap>
          <bufferHeap> .MapIntToBytes </bufferHeap>
          <bytesStack> .BytesStack </bytesStack>
          <contractModIdx> .Int </contractModIdx>
          // output
          <out> .ListBytes </out>
          <logs> .List </logs>
        </callState>
        <callStack> .List </callStack>
        <interimStates> .List </interimStates>
        <vmOutput> .VMOutput </vmOutput>
        <accounts>
          <account multiplicity="*" type="Map">
            <address> .Bytes </address>
            <nonce> 0 </nonce>
            <balance> 0 </balance>
            <esdtDatas>
              <esdtData multiplicity="*" type="Map">
                <esdtId>     .Bytes </esdtId>
                <esdtBalance> 0     </esdtBalance>
                <esdtRoles>  .Set   </esdtRoles>
              </esdtData>
            </esdtDatas>
```

If the `code` is `.Code`, it means the account is not a contract.
If the `code` is a `ModuleDecl`, it is the Wasm module which specifies the contract.
If the account is not a contract, `ownerAddress` is `.Bytes`.

```k
             <code> .Code </code>
             <ownerAddress> .Bytes </ownerAddress>
```
Storage maps byte arrays to byte arrays.

```k
             <storage> .MapBytesToBytes </storage>
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

    syntax VmInputCell

    syntax ReturnCode    ::= "OK"          [klabel(OK), symbol]
                           | ExceptionCode
    syntax ExceptionCode ::= "FunctionNotFound"         [klabel(FunctionNotFound), symbol]         
                           | "FunctionWrongSignature"   [klabel(FunctionWrongSignature), symbol]
                           | "ContractNotFound"         [klabel(ContractNotFound), symbol]
                           | "UserError"                [klabel(UserError), symbol]
                           | "OutOfGas"                 [klabel(OutOfGas), symbol]
                           | "AccountCollision"         [klabel(AccountCollision), symbol]
                           | "OutOfFunds"               [klabel(OutOfFunds), symbol]
                           | "CallStackOverFlow"        [klabel(CallStackOverFlow), symbol]
                           | "ContractInvalid"          [klabel(ContractInvalid), symbol]
                           | "ExecutionFailed"          [klabel(ExecutionFailed), symbol]
                           | "UpgradeFailed"            [klabel(UpgradeFailed), symbol]
                           | "SimulateFailed"           [klabel(SimulateFailed), symbol]

    syntax VMOutput ::= ".VMOutput"  [klabel(.VMOutput), symbol]
                      | VMOutput( returnCode: ReturnCode , returnMessage: Bytes , out: ListBytes, logs: List )
                        [klabel(VMOutput), symbol]

 // ------------------------------------------------------------------

    syntax Address ::= Bytes
                     | WasmStringToken

    syntax WasmStringToken ::= #unparseWasmString ( String          ) [function, total, hook(STRING.string2token)]

    syntax Bytes ::= #address2Bytes ( Address ) [function, total]
 // ------------------------------------------------------------------
    rule #address2Bytes(ADDR:WasmStringToken) => String2Bytes(#parseWasmString(ADDR))
    rule #address2Bytes(ADDR:Bytes) => ADDR

    syntax Code ::= ".Code" [klabel(.Code), symbol]
                  | ModuleDecl
 // ----------------------------------------------

    syntax ESDTTransfer ::= esdtTransfer( tokenName : Bytes , tokenValue : Int , tokenNonce : Int )    [klabel(esdtTransfer), symbol]

```

### Bytes Stack

```k
    syntax BytesStack ::= List{Bytes, ":"}  [klabel(bytesStackList), symbol]
 // --------------------------------------

    syntax BytesOp ::= #pushBytes ( Bytes )
                     | "#dropBytes"
 // ---------------------------------------
    rule <instrs> #pushBytes(BS) => . ... </instrs>
         <bytesStack> STACK => BS : STACK </bytesStack>

    rule <instrs> #dropBytes => . ... </instrs>
         <bytesStack> _ : STACK => STACK </bytesStack>

    syntax InternalInstr ::= "#returnLength"
 // ----------------------------------------
    rule <instrs> #returnLength => i32.const lengthBytes(BS) ... </instrs>
         <bytesStack> BS : _ </bytesStack>

    syntax InternalInstr ::= "#bytesEqual"
 // --------------------------------------
    rule <instrs> #bytesEqual => i32.const #bool( BS1 ==K BS2 ) ... </instrs>
         <bytesStack> BS1 : BS2 : _ </bytesStack>

```

## Call State

The `<callStack>` cell stores a list of previous contract execution states. These internal commands manages the callstack when calling and returning from a contract.

```k
    syntax InternalCmd ::= "pushCallState"  [klabel(pushCallState), symbol]
 // ---------------------------------------
    rule [pushCallState]:
         <commands> pushCallState => . ... </commands>
         <callStack> (.List => ListItem(CALLSTATE)) ... </callStack>
         <callState> CALLSTATE </callState>
      [priority(60)]

    syntax InternalCmd ::= "popCallState"  [klabel(popCallState), symbol]
 // --------------------------------------
    rule [popCallState]:
         <commands> popCallState => . ... </commands>
         <callStack> (ListItem(CALLSTATE) => .List) ... </callStack>
         <callState> _ => CALLSTATE </callState>
      [priority(60)]

    syntax InternalCmd ::= "dropCallState"  [klabel(dropCallState), symbol]
 // ---------------------------------------
    rule [dropCallState]:
         <commands> dropCallState => . ... </commands>
         <callStack> (ListItem(_) => .List) ... </callStack>
      [priority(60)]
```

## World State

```k
    syntax AccountsCellFragment

    syntax Accounts ::= "{" AccountsCellFragment "}"
 // --------------------------------------------------------

    syntax InternalCmd ::= "pushWorldState"  [klabel(pushWorldState), symbol]
 // ---------------------------------------
    rule [pushWorldState]:
         <commands> pushWorldState => . ... </commands>
         <interimStates> (.List => ListItem({ ACCTDATA })) ... </interimStates>
         <accounts>       ACCTDATA </accounts>
      [priority(60)]

    syntax InternalCmd ::= "popWorldState"  [klabel(popWorldState), symbol]
 // --------------------------------------
    rule [popWorldState]:
         <commands> popWorldState => . ... </commands>
         <interimStates> (ListItem({ ACCTDATA }) => .List) ... </interimStates>
         <accounts>       _ => ACCTDATA </accounts>
      [priority(60)]

    syntax InternalCmd ::= "dropWorldState"  [klabel(dropWorldState), symbol]
 // ---------------------------------------
    rule [dropWorldState]:
         <commands> dropWorldState => . ... </commands>
         <interimStates> (ListItem(_) => .List) ... </interimStates>
      [priority(60)]
```

## Misc

```k
    syntax InternalCmd ::= "#transferSuccess"

    syntax InternalCmd ::= checkAccountExists( Bytes )
 // ------------------------------------------------------
    rule [checkAccountExists-pass]:
        <commands> checkAccountExists(ADDR) => . ... </commands>
        <account>
          <address> ADDR </address>
          ...
        </account>
      [priority(60)]

    rule [checkAccountExists-fail]:
        <commands> checkAccountExists(ADDR) 
                => #exception(ExecutionFailed, b"account not found: " +Bytes ADDR) ... 
        </commands>
      [priority(61)]

    syntax InternalCmd ::= #exception( ExceptionCode , Bytes )
 // ---------------------------------------------------

    syntax Bool ::= isBuiltinFunction(WasmStringToken)       [function, total]
 // --------------------------------------------------------------------------
    rule isBuiltinFunction(_) => false                          [owise]

    syntax InternalCmd ::= processBuiltinFunc(String, Bytes, Bytes, VmInputCell)  [klabel(processBuiltinFunc),symbol]

    syntax InternalCmd ::= checkBool(Bool, String)    [klabel(checkBool), symbol]
 // -----------------------------------------------------------------------------------
    rule [checkBool-t]:
        <commands> checkBool(true, ERR) => #exception(ExecutionFailed, String2Bytes(ERR)) ... </commands>
    rule [checkBool-f]:
        <commands> checkBool(false,  _)   => . ... </commands>

    syntax WasmCell
    syntax InternalCmd ::= newWasmInstance(Bytes, ModuleDecl)  [klabel(newWasmInstance), symbol]
                         | mkCall( Bytes, WasmString, VmInputCell )

endmodule
```