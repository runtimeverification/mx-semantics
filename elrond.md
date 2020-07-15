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


endmodule

module ELROND
    imports WASM-TEST
    imports AUTO-ALLOCATE

endmodule
```
