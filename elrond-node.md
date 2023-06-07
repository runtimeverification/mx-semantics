Elrond Node
===========

```k
require "wasm.md"

module ELROND-NODE
    imports DOMAINS
    imports WASM

    configuration
      <node>
        <commands> .K </commands>
        <callState>
          // input
          <callee> .Bytes </callee>
          <vmInput>
            <caller> .Bytes </caller>
            <callArgs> .List </callArgs>
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
          <bufferHeap> .Map </bufferHeap>
          <bytesStack> .BytesStack </bytesStack>
          <contractModIdx> .Int </contractModIdx>
          // output
          <out> .List </out>
          <logs> .List </logs>
        </callState>
        <callStack> .List </callStack>
        <interimStates> .List </interimStates>
        <vmOutput> .VMOutput </vmOutput>
        <activeAccounts> .Set </activeAccounts>
        <accounts>
          <account multiplicity="*" type="Map">
            <address> .Bytes </address>
            <nonce> 0 </nonce>
            <balance> 0 </balance>
            <esdtDatas>
              <esdtData multiplicity="*" type="Map">
                <esdtId> .Bytes </esdtId>
                <esdtBalance> 0 </esdtBalance>
                <frozen> false </frozen>
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

    syntax VMOutput ::= ".VMOutput"
                      | VMOutput( returnCode: ReturnCode , returnMessage: Bytes , out: List, logs: List )

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
    syntax BytesStack ::= List{Bytes, ":"}
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
    syntax InternalCmd ::= "pushCallState"
 // ---------------------------------------
    rule <commands> pushCallState => . ... </commands>
         <callStack> (.List => ListItem(CALLSTATE)) ... </callStack>
         <callState> CALLSTATE </callState>
      [priority(60)]

    syntax InternalCmd ::= "popCallState"
 // --------------------------------------
    rule <commands> popCallState => . ... </commands>
         <callStack> (ListItem(CALLSTATE) => .List) ... </callStack>
         <callState> _ => CALLSTATE </callState>
      [priority(60)]

    syntax InternalCmd ::= "dropCallState"
 // ---------------------------------------
    rule <commands> dropCallState => . ... </commands>
         <callStack> (ListItem(_) => .List) ... </callStack>
      [priority(60)]
```

## World State

```k
    syntax AccountsCellFragment

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

```k
endmodule
```