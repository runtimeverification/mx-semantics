```k
require "test.md"
require "wasm-text.md"

module ELROND-SYNTAX
    imports ELROND
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
         <accounts>
            <account multiplicity="*" type="Map">
               <address> 0 </address>
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
         <k> $PGM:Stmts </k>
         <wasm/>
         <node/>
         <bigIntHeap> .BigIntHeap </bigIntHeap>
      </elrond>

    syntax BigIntHeap ::= List{Int, ":"}

    rule <k> PGM => . </k>
         <wasm>
           <instrs> .K => sequenceStmts(text2abstract(PGM)) </instrs>
           ...
         </wasm>
```

The (incorrect) default implementation of a host call is to just return zero values of the correct type.

```k
    rule <instrs> hostCall("env", "asyncCall", [ DOM ] -> [ CODOM ]) => . ... </instrs>
         <valstack> VS => #zero(CODOM) ++ #drop(lengthValTypes(DOM), VS) </valstack>

    syntax Stmt ::= "#clearConfig"
 // ------------------------------

endmodule

```
