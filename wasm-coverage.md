Wasm Code Coverage
==================

```k
require "wasm.md"

module WASM-COVERAGE
    imports WASM
    imports SET
    imports MAP

    configuration
      <wasmCoverage>
          <coveredFuncs> .Set </coveredFuncs>
          <notCoveredFuncs> .Set </notCoveredFuncs>
          <coveredBlock> .Map </coveredBlock>
          <lastVisitedBlock> .Int </lastVisitedBlock>
      </wasmCoverage>
```

Function Coverage
-----------------

```k
    syntax FuncCoverageDescription ::= fcd ( mod: OptionalString, fidx: Int ) [klabel(fcd), symbol]
 // ----------------------------------------------------------------------------------------------------

    rule [coverage-invoke]:
        <instrs> ( invoke ADDR ):Instr ... </instrs>
        <funcDef> 
          <fAddr> ADDR </fAddr>
          <fModInst> MODIDX </fModInst>
          ...
        </funcDef>
        <moduleInst>
          <modIdx> MODIDX </modIdx>
          <moduleFileName> FILENAME </moduleFileName>
          <funcAddrs> ... FIDX |-> ADDR ... </funcAddrs>
          ...
        </moduleInst>
        <coveredFuncs>    COV  => COV  |Set SetItem( fcd(FILENAME, FIDX) ) </coveredFuncs>
        <notCoveredFuncs> NCOV => NCOV -Set SetItem( fcd(FILENAME, FIDX) ) </notCoveredFuncs>
      requires fcd(FILENAME, FIDX) in(NCOV)
      [priority(10)]

    rule [coverage-allocfunc]:
        <instrs> allocfunc(MOD, ADDR, _, _, _, _) ... </instrs>
        <moduleInst>
          <modIdx> MOD </modIdx>
          <moduleFileName> FILENAME </moduleFileName>
          <funcAddrs> ... FIDX |-> ADDR ... </funcAddrs>
          ...
        </moduleInst>
        <notCoveredFuncs> NCOV => NCOV |Set SetItem( fcd(FILENAME, FIDX) ) </notCoveredFuncs>
      requires notBool fcd(FILENAME, FIDX) in(NCOV)
      [priority(10)]
```

Block Coverage
--------------

```k
    syntax BlockUID ::= blockUid ( mod: OptionalString, blockId: Int ) [klabel(blockUid), symbol]
 // ----------------------------------------------------------------------------------

    syntax BlockCoverage ::= blockCov ( mod: OptionalString, blockId: Int )                                [klabel(blockCov), symbol]
                           | ifCov    ( mod: OptionalString, blockId: Int , truebr: Bool , falsebr: Bool ) [klabel(ifCov), symbol]
                           | loopCov  ( mod: OptionalString, blockId: Int , times: Int )                   [klabel(loopCov), symbol]
 // ---------------------------------------------------------------------------------------------------------------------
    rule [coverage-block]:
        <instrs> #block(_, _, BLOCKID:Int) ... </instrs>
        <curModIdx> MODIDX </curModIdx>
        <moduleInst>
          <modIdx> MODIDX </modIdx>
          <moduleFileName> FILENAME </moduleFileName>
          ...
        </moduleInst>
        <coveredBlock> BLOCKCOV 
                    => BLOCKCOV [ blockUid(FILENAME, BLOCKID) <- blockCov(FILENAME, BLOCKID) ] 
        </coveredBlock>
        <lastVisitedBlock>  _ => BLOCKID </lastVisitedBlock>
      requires notBool blockUid(FILENAME, BLOCKID) in_keys(BLOCKCOV)
      [priority(10)]

    rule [coverage-if-true]:
        <instrs> #if(_, _, _, BLOCKID:Int) ... </instrs>
        <valstack> < i32 > VAL : _ </valstack>
        <curModIdx> MODIDX </curModIdx>
        <moduleInst>
          <modIdx> MODIDX </modIdx>
          <moduleFileName> FILENAME </moduleFileName>
          ...
        </moduleInst>
        <coveredBlock> BLOCKCOV 
                    => BLOCKCOV [ blockUid(FILENAME, BLOCKID) <- ifCov(FILENAME, BLOCKID, true, false) ]
        </coveredBlock>
        <lastVisitedBlock>  _ => BLOCKID </lastVisitedBlock>
      requires notBool blockUid(FILENAME, BLOCKID) in_keys(BLOCKCOV)
       andBool VAL =/=Int 0
      [priority(10)]

    rule [coverage-if-false]:
        <instrs> #if(_, _, _, BLOCKID:Int) ... </instrs>
        <valstack> < i32 > VAL : _ </valstack>
        <curModIdx> MODIDX </curModIdx>
        <moduleInst>
          <modIdx> MODIDX </modIdx>
          <moduleFileName> FILENAME </moduleFileName>
          ...
        </moduleInst>
        <coveredBlock> BLOCKCOV
                    => BLOCKCOV [ blockUid(FILENAME, BLOCKID) <- ifCov(FILENAME, BLOCKID, false, true) ]
        </coveredBlock>
        <lastVisitedBlock>  _ => BLOCKID </lastVisitedBlock>
      requires notBool blockUid(FILENAME, BLOCKID) in_keys(BLOCKCOV)
       andBool VAL ==Int 0
      [priority(10)]

    rule [coverage-if-true-2]:
        <instrs> #if(_, _, _, BLOCKID:Int) ... </instrs>
        <valstack> < i32 > VAL : _ </valstack>
        <curModIdx> MODIDX </curModIdx>
        <moduleInst>
          <modIdx> MODIDX </modIdx>
          <moduleFileName> FILENAME </moduleFileName>
          ...
        </moduleInst>
        <coveredBlock> 
          ...
          blockUid(FILENAME, BLOCKID) |-> ifCov(FILENAME, BLOCKID, false => true, _)
          ...
        </coveredBlock>
        <lastVisitedBlock>  _ => BLOCKID </lastVisitedBlock>
      requires VAL =/=Int 0
      [priority(10)]

    rule [coverage-if-false-2]:
        <instrs> #if(_, _, _, BLOCKID:Int) ... </instrs>
        <valstack> < i32 > VAL : _ </valstack>
        <curModIdx> MODIDX </curModIdx>
        <moduleInst>
          <modIdx> MODIDX </modIdx>
          <moduleFileName> FILENAME </moduleFileName>
          ...
        </moduleInst>
        <coveredBlock>
          ...
          blockUid(FILENAME, BLOCKID) |-> ifCov(FILENAME, BLOCKID, _, false => true)
          ...
        </coveredBlock>
        <lastVisitedBlock>  _ => BLOCKID </lastVisitedBlock>
      requires VAL ==Int 0
      [priority(10)]

    rule [coverage-loop]:
        <instrs> #loop(_, _, BLOCKID:Int) ... </instrs>
        <curModIdx> MODIDX </curModIdx>
        <moduleInst>
          <modIdx> MODIDX </modIdx>
          <moduleFileName> FILENAME </moduleFileName>
          ...
        </moduleInst>
        <coveredBlock> BLOCKCOV
                    => BLOCKCOV [ blockUid(FILENAME, BLOCKID) <- loopCov(FILENAME, BLOCKID, 1) ]
        </coveredBlock>
        <lastVisitedBlock> _ => BLOCKID </lastVisitedBlock>
      requires notBool blockUid(FILENAME, BLOCKID) in_keys(BLOCKCOV)
      [priority(10)]

    rule [coverage-loop-2]:
        <instrs> #loop(_, _, BLOCKID:Int) ... </instrs>
        <curModIdx> MODIDX </curModIdx>
        <moduleInst>
          <modIdx> MODIDX </modIdx>
          <moduleFileName> FILENAME </moduleFileName>
          ...
        </moduleInst>
        <coveredBlock>
          ...
          blockUid(FILENAME, BLOCKID) |-> loopCov(FILENAME, BLOCKID, T => T +Int 1)
          ...
        </coveredBlock>
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

    rule <instrs> #call(_) ... </instrs>
         <lastVisitedBlock> LB => .Int </lastVisitedBlock>
      requires LB =/=K .Int
      [priority(10)]

    rule <instrs> #call_indirect(_) ... </instrs>
         <lastVisitedBlock> LB => .Int </lastVisitedBlock>
      requires LB =/=K .Int
      [priority(10)]
```

```k
endmodule
```
