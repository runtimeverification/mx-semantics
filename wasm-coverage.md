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
          <coveredBlock> .Map </coveredBlock>
          <lastVisitedBlock> .Int </lastVisitedBlock>
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
```

Block Coverage
--------------

```k
    syntax BlockCoverage ::= blockCoverage ( blockId: Int )
                           | ifCoverage    ( blockId: Int , truebr: Bool , falsebr: Bool )
                           | loopCoverage  ( blockId: Int , times: Int )
 // --------------------------------------------------------------------
    rule <instrs> #block(_, _, BLOCKID:Int) ... </instrs>
         <coveredBlock> BLOCKCOV => BLOCKCOV [ BLOCKID <- blockCoverage(BLOCKID) ] </coveredBlock>
         <lastVisitedBlock>  _ => BLOCKID </lastVisitedBlock>
      requires notBool BLOCKID in_keys(BLOCKCOV)
      [priority(10)]

    rule <instrs> #if(_, _, _, BLOCKID:Int) ... </instrs>
         <valstack> < i32 > VAL : _ </valstack>
         <coveredBlock> BLOCKCOV => BLOCKCOV [ BLOCKID <- ifCoverage(BLOCKID, true, false) ] </coveredBlock>
         <lastVisitedBlock>  _ => BLOCKID </lastVisitedBlock>
      requires (notBool BLOCKID in_keys(BLOCKCOV)) andBool VAL =/=Int 0
      [priority(10)]

    rule <instrs> #if(_, _, _, BLOCKID:Int) ... </instrs>
         <valstack> < i32 > VAL : _ </valstack>
         <coveredBlock> BLOCKCOV => BLOCKCOV [ BLOCKID <- ifCoverage(BLOCKID, false, true) ] </coveredBlock>
         <lastVisitedBlock>  _ => BLOCKID </lastVisitedBlock>
      requires (notBool BLOCKID in_keys(BLOCKCOV)) andBool VAL ==Int 0
      [priority(10)]

    rule <instrs> #if(_, _, _, BLOCKID:Int) ... </instrs>
         <valstack> < i32 > VAL : _ </valstack>
         <coveredBlock> ... BLOCKID |-> ifCoverage(BLOCKID, false => true, _) ... </coveredBlock>
         <lastVisitedBlock>  _ => BLOCKID </lastVisitedBlock>
      requires VAL =/=Int 0
      [priority(10)]

    rule <instrs> #if(_, _, _, BLOCKID:Int) ... </instrs>
         <valstack> < i32 > VAL : _ </valstack>
         <coveredBlock> ... BLOCKID |-> ifCoverage(BLOCKID, _, false => true) ... </coveredBlock>
         <lastVisitedBlock>  _ => BLOCKID </lastVisitedBlock>
      requires VAL ==Int 0
      [priority(10)]

    rule <instrs> #loop(_, _, BLOCKID:Int) ... </instrs>
         <coveredBlock> BLOCKCOV => BLOCKCOV [ BLOCKID <- loopCoverage(BLOCKID, 1) ] </coveredBlock>
         <lastVisitedBlock> _ => BLOCKID </lastVisitedBlock>
      requires notBool BLOCKID in_keys(BLOCKCOV)
      [priority(10)]

    rule <instrs> #loop(_, _, BLOCKID:Int) ... </instrs>
         <coveredBlock> ... BLOCKID |-> loopCoverage(BLOCKID, T => T +Int 1) </coveredBlock>
         <lastVisitedBlock> LB => BLOCKID </lastVisitedBlock>
      requires LB =/=K BLOCKID
      [priority(10)]

    rule <instrs> #br(0) ~> _L:Label ... </instrs>
         <lastVisitedBlock> LB => .Int </lastVisitedBlock>
      requires LB =/=K .Int
      [priority(10)]

    rule <instrs> _L:Label ... </instrs>
         <lastVisitedBlock> LB => .Int </lastVisitedBlock>
      requires LB =/=K .Int
      [priority(10)]
```

```k
endmodule
```
