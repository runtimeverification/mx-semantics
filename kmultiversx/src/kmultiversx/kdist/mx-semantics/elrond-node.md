Elrond Node
===========

```k
requires "wasm-semantics/wasm.md"
requires "data/async-call.k"
requires "data/list-bytes.k"
requires "data/map-bytes-to-bytes.k"
requires "data/map-int-to-bytes.k"

module ELROND-NODE
    imports DOMAINS
    imports ASYNC-CALL
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
          <function> .String </function>
          <vmInput>
            <caller> .Bytes </caller>
            <callArgs> .ListBytes </callArgs>
            <callValue> 0 </callValue>
            <callType> DirectCall </callType>
            <esdtTransfers> .List </esdtTransfers>
            // gas
            <gasProvided> 0 </gasProvided>
            <gasPrice> 0 </gasPrice>
            // tx ID
            <txHash> .Bytes </txHash>
          </vmInput>
          // executional
          // every contract call uses its own wasm module instance, managed data heaps, and bytesStack.
          <wasm/>
          <bigIntHeap> .Map   </bigIntHeap>
          <bufferHeap> .MapIntToBytes </bufferHeap>
          <bytesStack> .BytesStack </bytesStack>
          <contractModIdx> .Int </contractModIdx>
          <asyncCalls> .ListAsyncCall </asyncCalls>
          <out> .ListBytes </out>
          <logs> .List </logs>
          <outputAccounts> .Map </outputAccounts>
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
                <esdtProperties> .Bytes </esdtProperties>
                <esdtMetadata> .esdtMetadata </esdtMetadata>
                <esdtLastNonce> 0 </esdtLastNonce>
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

    syntax CallType ::= "DirectCall"                [symbol(DirectCall)]
                      | "AsynchronousCall"          [symbol(AsynchronousCall)]
                      | "AsynchronousCallBack"      [symbol(AsynchronousCallBack)]

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

    syntax Int ::= ReturnCode2Int( ReturnCode )     [function, total]
 // -----------------------------------------------------------------
    rule ReturnCode2Int( OK                     ) => 0
    rule ReturnCode2Int( FunctionNotFound       ) => 1
    rule ReturnCode2Int( FunctionWrongSignature ) => 2
    rule ReturnCode2Int( ContractNotFound       ) => 3
    rule ReturnCode2Int( UserError              ) => 4
    rule ReturnCode2Int( OutOfGas               ) => 5
    rule ReturnCode2Int( AccountCollision       ) => 6 
    rule ReturnCode2Int( OutOfFunds             ) => 7
    rule ReturnCode2Int( CallStackOverFlow      ) => 8
    rule ReturnCode2Int( ContractInvalid        ) => 9
    rule ReturnCode2Int( ExecutionFailed        ) => 10
    rule ReturnCode2Int( UpgradeFailed          ) => 11
    rule ReturnCode2Int( SimulateFailed         ) => 12


    syntax VMOutput ::= ".VMOutput"  [klabel(.VMOutput), symbol]
                      | VMOutput( returnCode: ReturnCode , returnMessage: Bytes , out: ListBytes, logs: List, outputAccounts: Map )
                        [klabel(VMOutput), symbol]

    syntax OutputAccount ::= OutputAccount ( addr: Bytes, transfers: List )             [klabel(OutputAccount), symbol]
    syntax OutputTransfer ::= OutputTransfer ( sender: Bytes, value: TransferValue )    [klabel(OutputTransfer), symbol]

    syntax Bool ::= nonZeroOutputTransfer(OutputTransfer)      [function, total]
 // ---------------------------------------------------------------------------
    rule nonZeroOutputTransfer(OutputTransfer(_, I:Int))  => I =/=Int 0
    rule nonZeroOutputTransfer(OutputTransfer(_, L:List)) => size(L) >Int 0

    syntax OutputAccount ::= appendToOutTransfers(OutputAccount, OutputTransfer)    [function, total]
 // -------------------------------------------------------------------------------------------------
    rule appendToOutTransfers(OutputAccount( A, Ts ), T) => OutputAccount(A, Ts ListItem(T))

    syntax InternalCmd ::= appendToOutAccount(Bytes, OutputTransfer)    [klabel(appendToOutAccount), symbol]
 // -------------------------------------------------------------------------------------------------
    rule [appendToOutAccount]:
        <commands> appendToOutAccount(ACC, T) => .K ... </commands>
        <outputAccounts>
          OAs => OAs [ ACC <- appendToOutTransfers(
                                { OAs [ ACC ] orDefault OutputAccount(ACC, .List) }:>OutputAccount,
                                T
                              ) ]
        </outputAccounts>
      requires nonZeroOutputTransfer(T)
       andBool isOutputAccount( OAs [ ACC ] orDefault OutputAccount(ACC, .List) ) 
      [priority(60), preserves-definedness]
      // Preserving definedness
      // - Map[_<-_], Map[_]orDefault_ and appendToOutTransfers are total
      // - {_}:>OutputAccount is checked

    rule [appendToOutAccount-zero]:
        <commands> appendToOutAccount(_, T) => .K ... </commands>
      requires notBool nonZeroOutputTransfer(T)
      [priority(60)]

    syntax TransferValue ::= Int            // EGLD transfer
                           | List

    syntax Address ::= Bytes
                     | WasmStringToken

    syntax WasmStringToken ::= #unparseWasmString ( String )         [function, total, hook(STRING.string2token)]
                             | #quoteUnparseWasmString ( String )   [function, total]
    rule #quoteUnparseWasmString(S) => #unparseWasmString("\"" +String S +String "\"")

    syntax Bytes ::= #address2Bytes ( Address ) [function, total]
 // ------------------------------------------------------------------
    rule #address2Bytes(ADDR:WasmStringToken) => String2Bytes(#parseWasmString(ADDR))
    rule #address2Bytes(ADDR:Bytes) => ADDR

    syntax Code ::= ".Code" [klabel(.Code), symbol]
                  | ModuleDecl
 // ----------------------------------------------

    syntax ESDTTransfer ::= esdtTransfer( tokenName : Bytes , tokenValue : Int , tokenNonce : Int )    [klabel(esdtTransfer), symbol]

    syntax ESDTMetadata ::= ".esdtMetadata"       [klabel(.esdtMetadata), symbol]
                          | esdtMetadata(
                                name: Bytes,
                                nonce: Int,
                                creator: Bytes,
                                royalties: Int,
                                hash: Bytes,
                                uris: ListBytes,
                                attributes: Bytes )      [klabel(esdtMetadata), symbol]
```

### Bytes Stack

```k
    syntax BytesStack ::= List{Bytes, ":"}  [symbol(bytesStackList)]
 // --------------------------------------

    syntax BytesOp ::= #pushBytes ( Bytes )
                     | "#dropBytes"
                     | "#appendBytes"
 // ---------------------------------------
    rule <instrs> #pushBytes(BS) => .K ... </instrs>
         <bytesStack> STACK => BS : STACK </bytesStack>

    rule <instrs> #dropBytes => .K ... </instrs>
         <bytesStack> _ : STACK => STACK </bytesStack>

    rule <instrs> #appendBytes => .K ... </instrs>
         <bytesStack> BS1 : BS2 : BSS => (BS1 +Bytes BS2) : BSS </bytesStack>

    syntax InternalInstr ::= "#returnLength"
 // ----------------------------------------
    rule <instrs> #returnLength => i32.const lengthBytes(BS) ... </instrs>
         <bytesStack> BS : _ </bytesStack>

    syntax InternalInstr ::= "#bytesEqual"
 // --------------------------------------
    rule <instrs> #bytesEqual => i32.const #bool( BS1 ==K BS2 ) ... </instrs>
         <bytesStack> BS1 : BS2 : _ </bytesStack>

```

### Output

```k
    syntax InternalInstr ::= "#appendToOutFromBytesStack"
                           | #appendToOut ( Bytes )
 // -----------------------------------------------
    rule <instrs> #appendToOutFromBytesStack => .K ... </instrs>
         <bytesStack> OUT : STACK => STACK </bytesStack>
         <out> ... (.ListBytes => ListItem(wrap(OUT))) </out>

    rule <instrs> #appendToOut(OUT) => .K ... </instrs>
         <out> ... (.ListBytes => ListItem(wrap(OUT))) </out>
```

## Call State

The `<callStack>` cell stores a list of previous contract execution states. These internal commands manages the callstack when calling and returning from a contract.

```k
    syntax InternalCmd ::= "pushCallState"  [klabel(pushCallState), symbol]
 // ---------------------------------------
    rule [pushCallState]:
         <commands> pushCallState => .K ... </commands>
         <callStack> (.List => ListItem(CALLSTATE)) ... </callStack>
         CALLSTATE:CallStateCell
      [priority(60)]

    syntax InternalCmd ::= "popCallState"  [klabel(popCallState), symbol]
 // --------------------------------------
    rule [popCallState]:
         <commands> popCallState => .K ... </commands>
         <callStack> (ListItem(CALLSTATE:CallStateCell) => .List) ... </callStack>
         (_:CallStateCell => CALLSTATE)
      [priority(60)]

    syntax InternalCmd ::= "dropCallState"  [klabel(dropCallState), symbol]
 // ---------------------------------------
    rule [dropCallState]:
         <commands> dropCallState => .K ... </commands>
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
         <commands> pushWorldState => .K ... </commands>
         <interimStates> (.List => ListItem({ ACCTDATA })) ... </interimStates>
         <accounts>       ACCTDATA </accounts>
      [priority(60)]

    syntax InternalCmd ::= "popWorldState"  [klabel(popWorldState), symbol]
 // --------------------------------------
    rule [popWorldState]:
         <commands> popWorldState => .K ... </commands>
         <interimStates> (ListItem({ ACCTDATA }) => .List) ... </interimStates>
         <accounts>       _ => ACCTDATA </accounts>
      [priority(60)]

    syntax InternalCmd ::= "dropWorldState"  [klabel(dropWorldState), symbol]
 // ---------------------------------------
    rule [dropWorldState]:
         <commands> dropWorldState => .K ... </commands>
         <interimStates> (ListItem(_) => .List) ... </interimStates>
      [priority(60)]
```

## Misc

```k
    syntax InternalCmd ::= checkAccountExists( Bytes )
 // ------------------------------------------------------
    rule [checkAccountExists-pass]:
        <commands> checkAccountExists(ADDR) => .K ... </commands>
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

    syntax ThrowException ::= #throwException( ExceptionCode , String )    [macro]
                            | #throwExceptionBs( ExceptionCode , Bytes )
 // ------------------------------------------------------------------------------
    rule #throwException( EC , MSG ) => #throwExceptionBs( EC , String2Bytes(MSG) )

    syntax InternalInstr ::= ThrowException

    syntax InternalCmd ::= #exception( ExceptionCode , Bytes )
 // ---------------------------------------------------

    syntax BuiltinFunction ::= "#notBuiltin"                           [klabel(#notBuiltin),symbol]
                             | toBuiltinFunction(String)               [function, total]
                             | toBuiltinFunction(WasmStringToken)      [function, total]
 // --------------------------------------------------------------------------
    rule toBuiltinFunction(_:String)          => #notBuiltin           [owise]
    rule toBuiltinFunction(S:WasmStringToken) => toBuiltinFunction(#parseWasmString(S))

    syntax Bool ::= isBuiltin(String)                        [function, total]
                  | isBuiltin(WasmStringToken)               [function, total]
 // --------------------------------------------------------------------------
    rule isBuiltin(S:String)          => toBuiltinFunction(S) =/=K #notBuiltin
    rule isBuiltin(S:WasmStringToken) => toBuiltinFunction(S) =/=K #notBuiltin

    syntax Bytes ::= BuiltinFunction2Bytes(BuiltinFunction)           [function, total]
 // -----------------------------------------------------------------------------------
    rule BuiltinFunction2Bytes(#notBuiltin) => b""

    syntax InternalCmd ::= processBuiltinFunction(BuiltinFunction, Bytes, Bytes, VmInputCell)
      [klabel(processBuiltinFunction),symbol]

    syntax InternalCmd ::= checkBool(Bool, String)    [symbol(checkBool)]
 // -----------------------------------------------------------------------------
    rule [checkBool-t]:
         <commands> checkBool(B, _)   => .K                                             ... </commands> requires B
    rule [checkBool-f]:
         <commands> checkBool(B, ERR) => #exception(ExecutionFailed, String2Bytes(ERR)) ... </commands> requires notBool B

    syntax WasmCell
    syntax InternalCmd ::= newWasmInstance(Bytes, ModuleDecl)  [klabel(newWasmInstance), symbol]
                         | mkCall( Bytes, WasmString, VmInputCell )

    syntax InternalCmd ::= "resetCallstate"      [klabel(resetCallState), symbol]
 // ---------------------------------------------------------------------------
    rule [resetCallstate]:
        <commands> resetCallstate => .K ... </commands>
        (_:CallStateCell => <callState> <instrs> .K </instrs> ... </callState>)
      [preserves-definedness] // all constant configuration cells should be defined

endmodule
```
