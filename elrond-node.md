Elrond Node
===========

```k
require "wasm-text.md"

module ELROND-NODE
    imports BYTES
    imports LIST
    imports MAP
    imports SET
    imports WASM-TEXT

    configuration
      <node>
        <commands> .K </commands>
        <callState>
          <callArgs> .List </callArgs>
          <caller> .Bytes </caller>
          <callee> .Bytes </callee>
          <callValue> 0 </callValue>
          <esdtTokenName> .Bytes </esdtTokenName>
          <esdtValue> 0 </esdtValue>
          <out> .List </out>
          <message> .Bytes </message>
          <returnCode> .ReturnCode </returnCode>
          <interimStates> .List </interimStates>
          <logs> .List </logs>
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

    syntax ReturnCode    ::= ".ReturnCode"
                           | "OK"          [klabel(OK), symbol]
                           | ExceptionCode
    syntax ExceptionCode ::= "OutOfFunds"
                           | "UserError"   [klabel(UserError), symbol]
 // ------------------------------------------------------------------

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

endmodule
```

