Wasm Code Coverage
==================

```k
require "wasm.md"

module WASM-COVERAGE
    imports WASM

    configuration
      <wasmCoverage>
          <coveredFuncs> .Set </coveredFuncs>
          <notCoveredFuncs> .Map </notCoveredFuncs>
          <wasm/>
      </wasmCoverage>
```

Function Coverage
-----------------

```k
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
