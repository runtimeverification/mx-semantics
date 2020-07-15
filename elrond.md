```k
require "test.md"
require "wasm-text.md"

module ELROND-SYNTAX
    imports ELROND
    imports WASM-TEST-SYNTAX
endmodule

module AUTO-ALLOCATE
    imports WASM-TEST

    syntax Stmts ::=  autoAllocModules( ModuleDecl, Map ) [function]
                   | #autoAllocModules( Defns     , Map ) [function]
 // -----------------------------------------------------
    rule  autoAllocModules(#module(... importDefns: IS), MR) => #autoAllocModules(IS, MR)

    rule #autoAllocModules(.Defns, _) => .Stmts
    rule #autoAllocModules(((import MOD _ _) DS) => DS, MR) requires MOD in_keys(MR)
    rule #autoAllocModules(((import MOD _ _) DS), MR)
      => #emptyModule()
         (register(MOD))
         #autoAllocModules(DS, MR)
      requires notBool MOD in_keys(MR)

    rule <instrs> MD:ModuleDecl
               => sequenceStmts(autoAllocModules(MD, MR))
               ~> MD
              ...
         </instrs>
         <moduleRegistry> MR </moduleRegistry>
      requires autoAllocModules(MD, MR) =/=K .Stmts

    syntax Instr ::= hostCall(String, String)
 // -----------------------------------------
    rule <instrs> (import MOD NAME #funcDesc(... type: TIDX) #as FDESC) => allocfunc(HOSTMOD, NEXTADDR, TYPE, [ .ValTypes ], hostCall(#parseWasmString(MOD), #parseWasmString(NAME)) .Instrs, #meta(... id: , localIds: .Map )) ~> (import MOD NAME FDESC) ... </instrs>
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
          <nextFuncIdx> NEXTFUNC => NEXTFUNC +Int 1 </nextFuncIdx>
          <nextTypeIdx> NEXTTYPE => NEXTTYPE +Int 1 </nextTypeIdx>
          <types> TYPES => TYPES [ NEXTTYPE <- TYPE ] </types>
          ...
        </moduleInst>
      requires notBool NAME in_keys(EXPORTS)


endmodule

module ELROND
    imports WASM-TEST
    imports AUTO-ALLOCATE

endmodule
```
