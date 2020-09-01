```k
require "test.md"
require "wasm-text.md"

module MANDOS-SYNTAX
    imports MANDOS
    imports WASM-TEXT-SYNTAX
endmodule

module AUTO-ALLOCATE
    imports WASM

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

    rule #autoAllocModules(.Defns, _) => .Stmts
    rule #autoAllocModules(((import MOD _ _) DS) => DS, MR) requires MOD in_keys(MR)
    rule #autoAllocModules(((import MOD _ _) DS), MR)
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
    rule <instrs> (. => allocfunc(HOSTMOD, NEXTADDR, TYPE, [ .ValTypes ], hostCall(#parseWasmString(MOD), #parseWasmString(NAME), TYPE) .Instrs, #meta(... id: , localIds: .Map )))
               ~> (import MOD NAME #funcDesc(... type: TIDX))
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

endmodule

module ELROND-NODE
    imports DOMAINS
    imports WASM-TEXT

    configuration
      <node>
        <commands> .K </commands>
        <accounts>
          <account multiplicity="*" type="Map">
             <address> .Address </address>
             <nonce> 0 </nonce>
             <balance> 0 </balance>
```

If the code is "", it means the account is not a contract.
If the code is "file:<some_path>", then it is a contract, and the corresponding Wasm module is stored in the module registry, with the account's name as key.

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
    rule address2String(WS:WasmStringToken) => #parseWasmString(WS)

    syntax Code ::= ".Code" | WasmString | Int
 // ------------------------------------------

    syntax Argument ::= arg(Int, Int) [klabel(tupleArg), symbol]
 // ------------------------------------------------------------

    syntax Int ::= valueArg  ( Argument ) [function, functional]
                 | lengthArg ( Argument ) [function, functional]
 // ------------------------------------------------------------
    rule valueArg (arg(V, _)) => V
    rule lengthArg(arg(_, L)) => L

    syntax Address ::= ".Address" | WasmString
 // ------------------------------------------

    syntax Code ::= ".Code" | WasmString
 // ------------------------------------

endmodule

module ELROND
    imports WASM-TEXT
    imports AUTO-ALLOCATE
    imports ELROND-NODE

    configuration
      <elrond>
        <wasm/>
        <node/>
        <bigIntHeap> .BigIntHeap </bigIntHeap>
      </elrond>

    syntax BigIntHeap ::= List{Int, ":"}
```

The (incorrect) default implementation of a host call is to just return zero values of the correct type.

```k
    rule <instrs> hostCall("env", "asyncCall", [ DOM ] -> [ CODOM ]) => . ... </instrs>
         <valstack> VS => #zero(CODOM) ++ #drop(lengthValTypes(DOM), VS) </valstack>

endmodule

module MANDOS
    imports ELROND
    imports WASM-AUXIL

    configuration
      <mandos>
        <k> $PGM:Steps </k>
        <newAddresses> .Map </newAddresses>
        <elrond/>
        <exit-code exit=""> 1 </exit-code>
      </mandos>
```

If the program halts without any remaining steps to take, we report a successful exit.

```k
    rule <k> . </k>
         <commands> . </commands>
         <instrs> . </instrs>
         <exit-code> 1 => 0 </exit-code>


    syntax AddressNonce ::= tuple( Address , Int )
 // ----------------------------------------------

    syntax Steps ::= List{Step, ""} [klabel(mandosSteps), symbol]
 // -------------------------------------------------------------
    rule <k> .Steps => . </k>
    rule <k> S:Step SS:Steps => S ~> SS ... </k>

    syntax Step ::= "noop"
 // ----------------------
    rule <k> noop => . ... </k>

    syntax Step ::= ModuleDecl
 // --------------------------
    rule <k> M:ModuleDecl => . ... </k>
         <wasm>
           <instrs> .K => sequenceStmts(text2abstract(M .Stmts)) </instrs>
           ...
         </wasm>

    syntax Step ::= "register" String [klabel(register), symbol]
 // ------------------------------------------------------------
    rule <k> register NAME => . ... </k>
         <moduleRegistry> REG => REG [NAME <- IDX -Int 1] </moduleRegistry>
         <nextModuleIdx> IDX </nextModuleIdx>

    syntax Step ::= setAccount(Address, Int, Int, WasmString, Map) [klabel(setAccount), symbol]
 // -----------------------------------------------------------------------------------
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

    syntax Step ::= scDeploy( DeployTx, Expect ) [klabel(scDeploy), symbol]
 // ----------------------------------------------------------------------
    rule <k> scDeploy( TX, EXPECT ) => TX ~> EXPECT ... </k>

    syntax DeployTx ::= deployTx( Address, Int , ModuleDecl , Arguments , Int , Int ) [klabel(deployTx), symbol]
 // ------------------------------------------------------------------------------------------------------------

    syntax Step ::= scCall( CallTx, Expect ) [klabel(scCall), symbol]
 // ----------------------------------------------------------------
    rule <k> scCall( TX, EXPECT ) => TX ~> EXPECT ... </k>

    syntax CallTx ::= callTx(Address /*From*/, Address /*To*/, Int /*Value*/, WasmString /*Function*/, Arguments, Int /*gasLimit*/, Int /*gasPrice*/) [klabel(callTx), symbol]
 // ---------------------------------------------------------------------------------------------------------------------------------------------

    syntax Expect ::= ".Expect" [klabel(.Expect), symbol]
 // -------------------------------------------------------

    syntax Arguments ::= List{WasmString, ""} [klabel(arguments), symbol]
 // ------------------------------------------------------------------

    syntax Step ::= checkState() [klabel(checkState), symbol]
 // ---------------------------------------------------------

endmodule
```
