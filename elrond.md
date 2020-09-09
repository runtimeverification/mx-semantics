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

    configuration
      <node>
        <commands> .K </commands>
        <accounts>
          <account multiplicity="*" type="Map">
             <address> "" </address>
             <nonce> 0 </nonce>
             <balance> 0 </balance>
```

If the code is "", it means the account is not a contract.
If the code is "file:<some_path>", then it is a contract, and the corresponding Wasm module is stored in the module registry, with the account's name as key.

```k
             <code> "" </code>
```
Storage maps byte arrays to byte arrays.

```k
             <storage> .Map </storage>

           </account>
         </accounts>
       </node>

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
    imports K-IO

    configuration
      <mandos>
        <k> $PGM:Steps </k>
        <elrond/>
        <exit-code exit=""> 1 </exit-code>
      </mandos>

    syntax Steps ::= List{Step, ""} [klabel(mandosSteps), symbol]
 // -------------------------------------------------------------
    rule <k> .Steps => . </k>
    rule <k> S:Step SS:Steps => S ~> SS ... </k>

    rule <k> . </k>
         <commands> . </commands>
         <instrs> . </instrs>
         <exit-code> 1 => 0 </exit-code>

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

    syntax Step ::= "setAccount" String Int Int String Map [klabel(setAccount), symbol]
 // -----------------------------------------------------------------------------------
    rule <k> setAccount ADDRESS NONCE BALANCE CODE STORAGE => . ... </k>
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

endmodule
```
