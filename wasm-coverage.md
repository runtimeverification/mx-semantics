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
    syntax FuncCoverageDescription ::= fcd ( mod: Int, fidx: Int, id: OptionalId ) [klabel(fcd), symbol]
 // ----------------------------------------------------------------------------------------------------

    rule <instrs> ( invoke I ):Instr ... </instrs>
         <coveredFuncs> COV => COV SetItem(NCOV[I]) </coveredFuncs>
         <notCoveredFuncs> NCOV => NCOV [I <- undef] </notCoveredFuncs>
      requires I in_keys(NCOV)
      [priority(10)]

    rule <instrs> allocfunc(MOD, ADDR, _, _, _, #meta(... id: OID)) ... </instrs>
         <moduleInst>
           <modIdx> MOD </modIdx>
           <funcAddrs> ... FIDX |-> ADDR ... </funcAddrs>
           ...
         </moduleInst>
         <notCoveredFuncs> NCOV => NCOV [ ADDR <- fcd(MOD, FIDX, OID)] </notCoveredFuncs>
      requires notBool ADDR in_keys(NCOV)
      [priority(10)]
```

Block Coverage
--------------

```k
    syntax BlockUID ::= blockUid ( mod: Int, blockId: Int ) [klabel(blockUid), symbol]
 // ----------------------------------------------------------------------------------

    syntax BlockCoverage ::= blockCov ( mod: Int, blockId: Int )                                [klabel(blockCov), symbol]
                           | ifCov    ( mod: Int, blockId: Int , truebr: Bool , falsebr: Bool ) [klabel(ifCov), symbol]
                           | loopCov  ( mod: Int, blockId: Int , times: Int )                   [klabel(loopCov), symbol]
 // ---------------------------------------------------------------------------------------------------------------------
    rule <instrs> #block(_, _, BLOCKID:Int) ... </instrs>
         <curModIdx> MODIDX </curModIdx>
         <coveredBlock> BLOCKCOV => BLOCKCOV [ blockUid(MODIDX, BLOCKID) <- blockCov(MODIDX, BLOCKID) ] </coveredBlock>
         <lastVisitedBlock>  _ => BLOCKID </lastVisitedBlock>
      requires notBool blockUid(MODIDX, BLOCKID) in_keys(BLOCKCOV)
      [priority(10)]

    rule <instrs> #if(_, _, _, BLOCKID:Int) ... </instrs>
         <valstack> < i32 > VAL : _ </valstack>
         <curModIdx> MODIDX </curModIdx>
         <coveredBlock> BLOCKCOV => BLOCKCOV [ blockUid(MODIDX, BLOCKID) <- ifCov(MODIDX, BLOCKID, true, false) ] </coveredBlock>
         <lastVisitedBlock>  _ => BLOCKID </lastVisitedBlock>
      requires (notBool blockUid(MODIDX, BLOCKID) in_keys(BLOCKCOV)) andBool VAL =/=Int 0
      [priority(10)]

    rule <instrs> #if(_, _, _, BLOCKID:Int) ... </instrs>
         <valstack> < i32 > VAL : _ </valstack>
         <curModIdx> MODIDX </curModIdx>
         <coveredBlock> BLOCKCOV => BLOCKCOV [ blockUid(MODIDX, BLOCKID) <- ifCov(MODIDX, BLOCKID, false, true) ] </coveredBlock>
         <lastVisitedBlock>  _ => BLOCKID </lastVisitedBlock>
      requires (notBool blockUid(MODIDX, BLOCKID) in_keys(BLOCKCOV)) andBool VAL ==Int 0
      [priority(10)]

    rule <instrs> #if(_, _, _, BLOCKID:Int) ... </instrs>
         <valstack> < i32 > VAL : _ </valstack>
         <curModIdx> MODIDX </curModIdx>
         <coveredBlock> ... blockUid(MODIDX, BLOCKID) |-> ifCov(MODIDX, BLOCKID, false => true, _) ... </coveredBlock>
         <lastVisitedBlock>  _ => BLOCKID </lastVisitedBlock>
      requires VAL =/=Int 0
      [priority(10)]

    rule <instrs> #if(_, _, _, BLOCKID:Int) ... </instrs>
         <valstack> < i32 > VAL : _ </valstack>
         <curModIdx> MODIDX </curModIdx>
         <coveredBlock> ... blockUid(MODIDX, BLOCKID) |-> ifCov(MODIDX, BLOCKID, _, false => true) ... </coveredBlock>
         <lastVisitedBlock>  _ => BLOCKID </lastVisitedBlock>
      requires VAL ==Int 0
      [priority(10)]

    rule <instrs> #loop(_, _, BLOCKID:Int) ... </instrs>
         <curModIdx> MODIDX </curModIdx>
         <coveredBlock> BLOCKCOV => BLOCKCOV [ blockUid(MODIDX, BLOCKID) <- loopCov(MODIDX, BLOCKID, 1) ] </coveredBlock>
         <lastVisitedBlock> _ => BLOCKID </lastVisitedBlock>
      requires notBool blockUid(MODIDX, BLOCKID) in_keys(BLOCKCOV)
      [priority(10)]

    rule <instrs> #loop(_, _, BLOCKID:Int) ... </instrs>
         <curModIdx> MODIDX </curModIdx>
         <coveredBlock> ... blockUid(MODIDX, BLOCKID) |-> loopCov(MODIDX, BLOCKID, T => T +Int 1) </coveredBlock>
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
