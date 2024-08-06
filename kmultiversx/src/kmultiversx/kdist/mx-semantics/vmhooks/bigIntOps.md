Big Integers
============

Go implementation: [mx-chain-vm-go/vmhost/vmhooks/bigIntOps.go](https://github.com/multiversx/mx-chain-vm-go/blob/ea3d78d34c35f7ef9c1a9ea4fce8288608763229/vmhost/vmhooks/bigIntOps.go)

```k
requires "../elrond-config.md"
requires "baseOps.md"

module BIGINT-HELPERS
    imports ELROND-CONFIG
    imports BASEOPS
    imports LIST-BYTES-EXTENSIONS

    syntax IntResult ::= getBigInt(Int)      [function, total]
 // -------------------------------------------------------
    rule [[ getBigInt(IDX) => I ]]
      <bigIntHeap> ... IDX |-> I ... </bigIntHeap>
    rule getBigInt(_) => Err("no bigInt under the given handle") [owise]

    syntax InternalInstr ::= #getBigInt ( idx : Int ,  Signedness )
 // ---------------------------------------------------------------
    rule <instrs> #getBigInt(BIGINT_IDX, SIGN) => .K ... </instrs>
         <bytesStack> STACK => Int2Bytes({HEAP [ BIGINT_IDX ] orDefault 0}:>Int, BE, SIGN) : STACK </bytesStack>
         <bigIntHeap> HEAP </bigIntHeap>
      requires BIGINT_IDX in_keys( HEAP )
        andBool isInt(HEAP [ BIGINT_IDX ] orDefault 0)
      [preserves-definedness]
      // Preserving definedness:
      //  - Int2Bytes is total
      //  - in_keys is total
      //  - '_{{_}} orDefault' is total

    rule <instrs> #getBigInt(BIGINT_IDX, _SIGN) => #throwException(ExecutionFailed, "no bigInt under the given handle") ... </instrs>
         <bigIntHeap> HEAP </bigIntHeap>
      requires notBool( BIGINT_IDX in_keys( HEAP ) )
        orBool notBool isInt(HEAP [ BIGINT_IDX ] orDefault 0)

    syntax InternalInstr ::= #getBigIntOrCreate ( idx : Int ,  Signedness )
 // ---------------------------------------------------------------
    rule [getBigIntOrCreate-get]:
        <instrs> #getBigIntOrCreate(BIGINT_IDX, SIGN) => .K ... </instrs>
        <bytesStack> STACK => Int2Bytes({HEAP [ BIGINT_IDX ] orDefault 0}:>Int, BE, SIGN) : STACK </bytesStack>
        <bigIntHeap> HEAP </bigIntHeap>
      requires BIGINT_IDX in_keys( HEAP )
        andBool isInt(HEAP [ BIGINT_IDX ] orDefault 0)
      [preserves-definedness]
      // Preserving definedness:
      //  - Int2Bytes is total
      //  - in_keys is total
      //  - '_{{_}} orDefault' is total

    rule [getBigIntOrCreate-create]:
        <instrs> #getBigIntOrCreate(BIGINT_IDX, SIGN) => #setBigIntValue(BIGINT_IDX, 0) ... </instrs>
        <bytesStack> STACK => Int2Bytes(0, BE, SIGN) : STACK </bytesStack>
        <bigIntHeap> HEAP </bigIntHeap>
      requires notBool( BIGINT_IDX in_keys( HEAP ) )
        orBool notBool isInt(HEAP [ BIGINT_IDX ] orDefault 0)

    syntax InternalInstr ::= #setBigIntFromBytesStack ( idx: Int , Signedness )
                           | #setBigInt ( idx: Int , value: Bytes , Signedness )
                           | #setBigIntValue ( Int , Int )
 // ----------------------------------------------------------------------------
    rule <instrs> #setBigIntFromBytesStack(BIGINT_IDX, SIGN) => #setBigInt(BIGINT_IDX, BS, SIGN) ... </instrs>
         <bytesStack> BS : _ </bytesStack>

    rule <instrs> #setBigInt(BIGINT_IDX, BS, SIGN) => .K ... </instrs>
         <bigIntHeap> HEAP => HEAP [ BIGINT_IDX <- Bytes2Int(BS, BE, SIGN) ] </bigIntHeap>

    rule <instrs> #setBigIntValue(BIGINT_IDX, VALUE) => .K ... </instrs>
         <bigIntHeap> HEAP => HEAP [ BIGINT_IDX <- VALUE ] </bigIntHeap>

    syntax Int ::= #newKey(Map)                    [function, total]
                 | #newKeyAux(Int, Map)            [function, total]
 // -------------------------------------------------------
    rule #newKey(M:Map)       => #newKeyAux(size(M), M)
    rule #newKeyAux(I, M:Map) => I                        requires notBool(I in_keys(M))
    rule #newKeyAux(I, M:Map) => #newKeyAux(I +Int 1, M)  requires         I in_keys(M)

 // sqrtInt(X) = ⌊√X⌋   if X is non-negative
 // sqrtInt(X) = -1     if X is negative
    syntax Int ::= sqrtInt(Int)           [function, total]
 // ------------------------------------------------
    rule sqrtInt(X) => -1                           requires X <Int 0
    rule sqrtInt(0) => 0
    rule sqrtInt(X) => #let P = 2 ^Int (log2Int(X) /Int 2) // the largest power of 2 less than or eq. to X
                       #in sqrtBS(X, P, P *Int 2)   requires X >Int 0

 // sqrtBS(X,L,R) tries to find ⌊√X⌋ between L and R using binary search
 // sqrtBS(X,L,R) = Y
 //   * Y is defined when L <= R
 //   * L <= ⌊√X⌋ <= R should hold for a correct result
    syntax Int ::= sqrtBS(Int, Int, Int)      [function]
 // ------------------------------------------------------------
    rule sqrtBS(_, L, R) => L                                      requires L ==Int R
    rule sqrtBS(X, L, R) => sqrtBS(X, L, bsMid(L,R) -Int 1)        requires L <Int R
                                                                    andBool squareInt(bsMid(L,R)) >Int X
    rule sqrtBS(X, L, R) => sqrtBS(X, bsMid(L,R), R)               requires L <Int R
                                                                    andBool squareInt(bsMid(L,R)) <=Int X

    // L and R gets closer at each iteration, eventuallly L == R holds
    rule #Ceil(sqrtBS(@X:Int, @L:Int, @R:Int)) => #Ceil(@X) #And #Ceil(@L) #And #Ceil(@R)
                                             #And {(@L <=Int @R) #Equals true}   [simplification]

    // value in the middle for binary search
    syntax Int ::= bsMid(Int, Int)         [function, total]
    rule bsMid(X,Y) => (X +Int Y +Int 1) /Int 2

    syntax Int ::= squareInt(Int)           [function, total]
    rule squareInt(I) => I *Int I

endmodule

module BIGINTOPS
     imports BIGINT-HELPERS

    // extern int32_t bigIntNew(void* context, long long smallValue);
    rule <instrs> hostCall("env", "bigIntNew", [ i64 .ValTypes ] -> [ i32 .ValTypes ])
               => i32.const #newKey(HEAP)
                  ...
         </instrs>
         <locals> ListItem(<i64> INITIAL) </locals>
         <bigIntHeap> HEAP => HEAP [ #newKey(HEAP) <- #signed(i64, INITIAL) ] </bigIntHeap>
      requires definedSigned(i64, INITIAL)
      [preserves-definedness]
      // Preserving definedness:
      //  - #newKey is total
      //  - Map[Int <- Int] is total
      //  - we check that #signed(i64, INITIAL) is defined.

    // extern int32_t bigIntUnsignedByteLength(void* context, int32_t reference);
    rule <instrs> hostCall("env", "bigIntUnsignedByteLength", [ i32 .ValTypes ] -> [ i32 .ValTypes ])
               => #getBigInt(IDX, Unsigned)
               ~> #returnLength
               ~> #dropBytes
                  ...
         </instrs>
         <locals> ListItem(<i32> IDX) </locals>

    // extern int32_t bigIntSignedByteLength(void* context, int32_t reference);
    rule <instrs> hostCall("env", "bigIntSignedByteLength", [ i32 .ValTypes ] -> [ i32 .ValTypes ])
               => #getBigInt(IDX, Unsigned)
               ~> #returnLength
               ~> #dropBytes
                  ...
         </instrs>
         <locals> ListItem(<i32> IDX) </locals>

 // extern long long bigIntGetInt64(void* context, int32_t destinationHandle);
    rule [bigIntGetInt64]:
        <instrs> hostCall ("env", "bigIntGetInt64", [i32 .ValTypes ] -> [i64  .ValTypes ] )
              => i64 . const V
                 ...
        </instrs>
        <locals> ListItem(<i32> IDX) </locals>
        <bigIntHeap> ... IDX |-> V ... </bigIntHeap>
      requires V <=Int maxSInt64
       andBool minSInt64 <=Int V

    rule [bigIntGetInt64-not-int64]:
        <instrs> hostCall ("env", "bigIntGetInt64", [i32 .ValTypes ] -> [i64  .ValTypes ] )
              => #throwException(ExecutionFailed, "big int cannot be represented as int64") ...
        </instrs>
        <locals> ListItem(<i32> IDX) </locals>
        <bigIntHeap> ... IDX |-> V ... </bigIntHeap>
      requires V >Int maxSInt64
        orBool minSInt64 >Int V

    rule [bigIntGetInt64-invalid-handle]:
        <instrs> hostCall ("env", "bigIntGetInt64", [i32 .ValTypes ] -> [i64  .ValTypes ] )
              => #setBigIntValue(IDX, 0)
              ~> i64 . const 0
                 ...
        </instrs>
        <locals> ListItem(<i32> IDX) </locals>
        <bigIntHeap> HEAP </bigIntHeap>
      requires notBool(IDX in_keys(HEAP))

    // extern int32_t bigIntGetUnsignedBytes(void* context, int32_t reference, int32_t byteOffset);
    rule <instrs> hostCall("env", "bigIntGetUnsignedBytes", [ i32 i32 .ValTypes ] -> [ i32 .ValTypes ])
               => #getBigInt(IDX, Unsigned)
               ~> #memStoreFromBytesStack(OFFSET)
               ~> #returnLength
               ~> #dropBytes
                  ...
         </instrs>
         <locals> ListItem(<i32> IDX)  ListItem(<i32> OFFSET) </locals>

    // extern int32_t bigIntGetSignedBytes(void* context, int32_t reference, int32_t byteOffset);
    rule <instrs> hostCall("env", "bigIntGetSignedBytes", [ i32 i32 .ValTypes ] -> [ i32 .ValTypes ])
               => #getBigInt(IDX, Signed)
               ~> #memStoreFromBytesStack(OFFSET)
               ~> #returnLength
               ~> #dropBytes
                  ...
         </instrs>
         <locals> ListItem(<i32> IDX)  ListItem(<i32> OFFSET) </locals>

    // extern void bigIntSetUnsignedBytes(void* context, int32_t destination, int32_t byteOffset, int32_t byteLength);
    rule <instrs> hostCall("env", "bigIntSetUnsignedBytes", [ i32 i32 i32 .ValTypes ] -> [ .ValTypes ])
               => #memLoad(OFFSET, LENGTH)
               ~> #setBigIntFromBytesStack(IDX, Unsigned)
               ~> #dropBytes
                  ...
         </instrs>
         <locals> ListItem(<i32> IDX) ListItem(<i32> OFFSET) ListItem(<i32> LENGTH) </locals>

    // extern void bigIntSetSignedBytes(void* context, int32_t destination, int32_t byteOffset, int32_t byteLength);
    rule <instrs> hostCall("env", "bigIntSetSignedBytes", [ i32 i32 i32 .ValTypes ] -> [ .ValTypes ])
               => #memLoad(OFFSET, LENGTH)
               ~> #setBigIntFromBytesStack(IDX, Signed)
               ~> #dropBytes
                  ...
         </instrs>
         <locals> ListItem(<i32> IDX) ListItem(<i32> OFFSET) ListItem(<i32> LENGTH) </locals>

 // extern void      bigIntSetInt64(void* context, int32_t destinationHandle, long long value);
    rule <instrs> hostCall ( "env" , "bigIntSetInt64" , [ i32  i64  .ValTypes ] -> [ .ValTypes ] )
               => #setBigIntValue(DEST_IDX, #signed(i64, VALUE))
                  ...
         </instrs>
         <locals> ListItem(<i32> DEST_IDX) ListItem(<i64> VALUE) </locals>
      requires definedSigned(i64, VALUE)
      [preserves-definedness]
      // Preserving definedness:
      //  - only constructors on the RHS except for #signed, and we
      //    check for its definedness separately.

    // extern void bigIntAdd(void* context, int32_t destination, int32_t op1, int32_t op2);
    rule <instrs> hostCall("env", "bigIntAdd", [ i32 i32 i32 .ValTypes ] -> [ .ValTypes ]) => .K ... </instrs>
         <locals> ListItem(<i32> DST)  ListItem(<i32> OP1_IDX)  ListItem(<i32> OP2_IDX) </locals>
         <bigIntHeap> HEAP
                   => HEAP [ DST <- ({HEAP[OP1_IDX] orDefault 0}:>Int) +Int ({HEAP[OP2_IDX] orDefault 0}:>Int) ]
         </bigIntHeap>
      requires OP1_IDX in_keys(HEAP)
       andBool OP2_IDX in_keys(HEAP)
       andBool isInt(HEAP[OP1_IDX] orDefault 0)
       andBool isInt(HEAP[OP2_IDX] orDefault 0)
      [preserves-definedness]
      // Preserving definedness:
      //  - +Int is total
      //  - in_keys is total
      //  - _{{_ <- _}} is total
      //  - _{{_}} orDefault _ is total

   // TODO a lot of code duplication in the error cases.
   // use sth like #getBigInt that checks existence
    rule <instrs> hostCall("env", "bigIntAdd", [ i32 i32 i32 .ValTypes ] -> [ .ValTypes ])
               => #throwException(ExecutionFailed, "no bigInt under the given handle") ...
         </instrs>
         <locals> ListItem(<i32> _DST)  ListItem(<i32> OP1_IDX)  ListItem(<i32> OP2_IDX) </locals>
         <bigIntHeap> HEAP </bigIntHeap>
      requires notBool (OP1_IDX in_keys(HEAP))
        orBool notBool (OP2_IDX in_keys(HEAP))
        orBool notBool isInt(HEAP[OP1_IDX] orDefault 0)
        orBool notBool isInt(HEAP[OP2_IDX] orDefault 0)

    // extern void bigIntSub(void* context, int32_t destination, int32_t op1, int32_t op2);
    rule <instrs> hostCall("env", "bigIntSub", [ i32 i32 i32 .ValTypes ] -> [ .ValTypes ]) => .K ... </instrs>
         <locals> ListItem(<i32> DST)  ListItem(<i32> OP1_IDX)  ListItem(<i32> OP2_IDX) </locals>
         <bigIntHeap> HEAP
                   => HEAP [ DST <- ({HEAP[OP1_IDX] orDefault 0}:>Int) -Int ({HEAP[OP2_IDX] orDefault 0}:>Int) ]
         </bigIntHeap>
      requires OP1_IDX in_keys(HEAP)
       andBool OP2_IDX in_keys(HEAP)
       andBool isInt(HEAP[OP1_IDX] orDefault 0)
       andBool isInt(HEAP[OP2_IDX] orDefault 0)
      [preserves-definedness]
      // Preserving definedness:
      //  - -Int is total
      //  - in_keys is total
      //  - _{{_ <- _}} is total
      //  - _{{_}} orDefault _ is total

    rule <instrs> hostCall("env", "bigIntSub", [ i32 i32 i32 .ValTypes ] -> [ .ValTypes ])
               => #throwException(ExecutionFailed, "no bigInt under the given handle") ...
         </instrs>
         <locals> ListItem(<i32> _DST)  ListItem(<i32> OP1_IDX)  ListItem(<i32> OP2_IDX) </locals>
         <bigIntHeap> HEAP </bigIntHeap>
      requires notBool (OP1_IDX in_keys(HEAP))
        orBool notBool (OP2_IDX in_keys(HEAP))
        orBool notBool isInt(HEAP[OP1_IDX] orDefault 0)
        orBool notBool isInt(HEAP[OP2_IDX] orDefault 0)

    // extern void bigIntMul(void* context, int32_t destination, int32_t op1, int32_t op2);
    rule <instrs> hostCall("env", "bigIntMul", [ i32 i32 i32 .ValTypes ] -> [ .ValTypes ]) => .K ... </instrs>
         <locals> ListItem(<i32> DST)  ListItem(<i32> OP1_IDX)  ListItem(<i32> OP2_IDX) </locals>
         <bigIntHeap> HEAP
                   => HEAP [ DST <- ({HEAP[OP1_IDX] orDefault 0}:>Int) *Int ({HEAP[OP2_IDX] orDefault 0}:>Int) ]
         </bigIntHeap>
      requires OP1_IDX in_keys(HEAP)
       andBool OP2_IDX in_keys(HEAP)
       andBool isInt(HEAP[OP1_IDX] orDefault 0)
       andBool isInt(HEAP[OP2_IDX] orDefault 0)
      [preserves-definedness]
      // Preserving definedness:
      //  - *Int is total
      //  - in_keys is total
      //  - _{{_ <- _}} is total
      //  - _{{_}} orDefault _ is total

    rule <instrs> hostCall("env", "bigIntMul", [ i32 i32 i32 .ValTypes ] -> [ .ValTypes ])
               => #throwException(ExecutionFailed, "no bigInt under the given handle") ...
         </instrs>
         <locals> ListItem(<i32> _DST)  ListItem(<i32> OP1_IDX)  ListItem(<i32> OP2_IDX) </locals>
         <bigIntHeap> HEAP </bigIntHeap>
      requires notBool (OP1_IDX in_keys(HEAP))
        orBool notBool (OP2_IDX in_keys(HEAP))
        orBool notBool isInt(HEAP[OP1_IDX] orDefault 0)
        orBool notBool isInt(HEAP[OP2_IDX] orDefault 0)

    // extern void bigIntTDiv(void* context, int32_t destination, int32_t op1, int32_t op2);
    rule <instrs> hostCall("env", "bigIntTDiv", [ i32 i32 i32 .ValTypes ] -> [ .ValTypes ]) => .K ... </instrs>
         <locals> ListItem(<i32> DST)  ListItem(<i32> OP1_IDX)  ListItem(<i32> OP2_IDX) </locals>
         <bigIntHeap> HEAP
                   => HEAP [ DST <- ({HEAP[OP1_IDX] orDefault 0}:>Int) /Int ({HEAP[OP2_IDX] orDefault 0}:>Int) ]
         </bigIntHeap>
      requires OP1_IDX in_keys(HEAP)
       andBool OP2_IDX in_keys(HEAP)
       andBool isInt(HEAP[OP1_IDX] orDefault 0)
       andBool isInt(HEAP[OP2_IDX] orDefault 0)
       andBool (HEAP[OP2_IDX] orDefault 0) =/=K 0
      [preserves-definedness]
      // Preserving definedness:
      //  - we checked that /Int is defined
      //  - _{{_ <- _}} is total
      //  - _{{_}} orDefault _ is total

    rule <instrs> hostCall("env", "bigIntTDiv", [ i32 i32 i32 .ValTypes ] -> [ .ValTypes ])
               => #throwException(ExecutionFailed, "no bigInt under the given handle") ...
         </instrs>
         <locals> ListItem(<i32> _DST)  ListItem(<i32> OP1_IDX)  ListItem(<i32> OP2_IDX) </locals>
         <bigIntHeap> HEAP </bigIntHeap>
      requires notBool (OP1_IDX in_keys(HEAP))
        orBool notBool (OP2_IDX in_keys(HEAP))
        orBool notBool isInt(HEAP[OP1_IDX] orDefault 0)
        orBool notBool isInt(HEAP[OP2_IDX] orDefault 0)

    rule <instrs> hostCall("env", "bigIntTDiv", [ i32 i32 i32 .ValTypes ] -> [ .ValTypes ])
               => #throwException(ExecutionFailed, "division by 0") ...
         </instrs>
         <locals> ListItem(<i32> _DST)  ListItem(<i32> OP1_IDX)  ListItem(<i32> OP2_IDX) </locals>
         <bigIntHeap> HEAP </bigIntHeap>
      requires OP1_IDX in_keys(HEAP)
       andBool OP2_IDX in_keys(HEAP)
       andBool isInt(HEAP[OP1_IDX] orDefault 0)
       andBool (HEAP[OP2_IDX] orDefault 0) ==K 0

    // extern int32_t bigIntSign(void* context, int32_t op);
    rule <instrs> hostCall("env", "bigIntSign", [ i32 .ValTypes ] -> [ i32 .ValTypes ])
               => i32.const #bigIntSign({HEAP[IDX] orDefault 0}:>Int)
                  ...
         </instrs>
         <locals> ListItem(<i32> IDX) </locals>
         <bigIntHeap> HEAP </bigIntHeap>
      requires IDX in_keys(HEAP)
        andBool isInt(HEAP[IDX] orDefault 0)
      [preserves-definedness]
      // Preserving definedness:
      //  - #bigIntSign is total
      //  - in_keys is total
      //  - _[_] orDefault _ is total
      //  - {HEAP[IDX] orDefault 0}:>Int is defined (checked isInt)

    rule <instrs> hostCall("env", "bigIntSign", [ i32 .ValTypes ] -> [ i32 .ValTypes ])
               => #throwException(ExecutionFailed, "no bigInt under the given handle")
                  ...
         </instrs>
         <locals> ListItem(<i32> IDX) </locals>
         <bigIntHeap> HEAP </bigIntHeap>
      requires notBool (IDX in_keys(HEAP))
        orBool notBool isInt(HEAP[IDX] orDefault 0)

    // extern int32_t bigIntCmp(void* context, int32_t op1, int32_t op2);
    rule <instrs> hostCall("env", "bigIntCmp", [ i32 i32 .ValTypes ] -> [ i32 .ValTypes ])
               => i32.const #cmpInt({HEAP [OP1_IDX] orDefault 0}:>Int, {HEAP [OP2_IDX] orDefault 0}:>Int)
                  ...
         </instrs>
         <locals> ListItem(<i32> OP1_IDX)  ListItem(<i32> OP2_IDX) </locals>
         <bigIntHeap> HEAP </bigIntHeap>
      requires OP1_IDX in_keys(HEAP)
       andBool OP2_IDX in_keys(HEAP)
       andBool isInt(HEAP [OP1_IDX] orDefault 0)
       andBool isInt(HEAP [OP2_IDX] orDefault 0)
      [preserves-definedness]
      // Preserving definedness:
      //  - #cmpInt is total
      //  - in_keys is total
      //  - _{{_ <- _}} is total
      //  - _{{_}} orDefault _ is total

    rule <instrs> hostCall("env", "bigIntCmp", [ i32 i32 .ValTypes ] -> [ i32 .ValTypes ])
               => #throwException(ExecutionFailed, "no bigInt under the given handle")
                  ...
         </instrs>
         <locals> ListItem(<i32> OP1_IDX)  ListItem(<i32> OP2_IDX) </locals>
         <bigIntHeap> HEAP </bigIntHeap>
      requires notBool (OP1_IDX in_keys(HEAP))
        orBool notBool (OP2_IDX in_keys(HEAP))
        orBool notBool isInt(HEAP[OP1_IDX] orDefault 0)
        orBool notBool isInt(HEAP[OP2_IDX] orDefault 0)

    // extern void bigIntFinishUnsigned(void* context, int32_t reference);
    rule <instrs> hostCall("env", "bigIntFinishUnsigned", [ i32 .ValTypes ] -> [ .ValTypes ])
               => #getBigInt(IDX, Unsigned)
               ~> #appendToOutFromBytesStack
                  ...
         </instrs>
         <locals> ListItem(<i32> IDX) </locals>

    // extern void bigIntFinishSigned(void* context, int32_t reference);
    rule <instrs> hostCall("env", "bigIntFinishSigned", [ i32 .ValTypes ] -> [ .ValTypes ])
               => #getBigInt(IDX, Signed)
               ~> #appendToOutFromBytesStack
                  ...
         </instrs>
         <locals> ListItem(<i32> IDX) </locals>

    // extern int32_t bigIntStorageStoreUnsigned(void *context, int32_t keyOffset, int32_t keyLength, int32_t source);
    rule <instrs> hostCall("env", "bigIntStorageStoreUnsigned", [ i32 i32 i32 .ValTypes ] -> [ i32 .ValTypes ])
               => #memLoad(KEYOFFSET, KEYLENGTH)
               ~> #getBigIntOrCreate(BIGINTIDX, Unsigned)
               ~> #storageStore
                  ...
         </instrs>
         <locals>
           ListItem(<i32> KEYOFFSET)
           ListItem(<i32> KEYLENGTH)
           ListItem(<i32> BIGINTIDX)
         </locals>

    // extern int32_t bigIntStorageLoadUnsigned(void *context, int32_t keyOffset, int32_t keyLength, int32_t destination);
    rule <instrs> hostCall("env", "bigIntStorageLoadUnsigned", [ i32 i32 i32 .ValTypes ] -> [ i32 .ValTypes ])
               => #memLoad(KEYOFFSET, KEYLENGTH)
               ~> #storageLoad
               ~> #setBigIntFromBytesStack(DEST, Unsigned)
               ~> #returnLength
               ~> #dropBytes
                  ...
         </instrs>
         <locals>
           ListItem(<i32> KEYOFFSET)
           ListItem(<i32> KEYLENGTH)
           ListItem(<i32> DEST)
         </locals>

    // extern void bigIntGetUnsignedArgument(void *context, int32_t id, int32_t destination);
    rule <instrs> hostCall("env", "bigIntGetUnsignedArgument", [ i32 i32 .ValTypes ] -> [ .ValTypes ]) =>  .K ... </instrs>
         <locals> ListItem(<i32> ARG_IDX)  ListItem(<i32> BIG_IDX) </locals>
         <callArgs> ARGS </callArgs>
         <bigIntHeap> HEAP => HEAP [ BIG_IDX <- Bytes2Int(ARGS {{ ARG_IDX }}, BE, Unsigned) ] </bigIntHeap>
      requires #validArgIdx(ARG_IDX, ARGS)
      [preserves-definedness]
      // Preserving definedness:
      //  - ARGS {{ ARG_IDX }} is defined because #validArgIdx(ARG_IDX, ARGS)
      //  - #cmpInt is total
      //  - Bytes2Int is total
      //  - _{{_ <- _}} is total

    // If ARG_IDX is invalid (out of bounds) just ignore
    // https://github.com/multiversx/mx-chain-vm-go/blob/ea3d78d34c35f7ef9c1a9ea4fce8288608763229/vmhost/vmhooks/bigIntOps.go#L68
    rule <instrs> hostCall("env", "bigIntGetUnsignedArgument", [ i32 i32 .ValTypes ] -> [ .ValTypes ]) =>  .K ... </instrs>
         <locals> ListItem(<i32> ARG_IDX)  ListItem(<i32> _BIG_IDX) </locals>
         <callArgs> ARGS </callArgs>
      requires notBool #validArgIdx(ARG_IDX, ARGS)

    // extern void bigIntGetSignedArgument(void *context, int32_t id, int32_t destination);
    rule <instrs> hostCall("env", "bigIntGetSignedArgument", [ i32 i32 .ValTypes ] -> [ .ValTypes ]) =>  .K ... </instrs>
         <locals> ListItem(<i32> ARG_IDX)  ListItem(<i32> BIG_IDX) </locals>
         <callArgs> ARGS </callArgs>
         <bigIntHeap> HEAP => HEAP [ BIG_IDX <- Bytes2Int(ARGS {{ ARG_IDX }}, BE, Signed) ] </bigIntHeap>
      requires #validArgIdx(ARG_IDX, ARGS)
      [preserves-definedness]
      // Preserving definedness:
      //  - ARGS {{ ARG_IDX }} is defined because #validArgIdx(ARG_IDX, ARGS)
      //  - Bytes2Int is total
      //  - _{{_ <- _}} is total

    rule <instrs> hostCall("env", "bigIntGetSignedArgument", [ i32 i32 .ValTypes ] -> [ .ValTypes ]) =>  .K ... </instrs>
         <locals> ListItem(<i32> ARG_IDX)  ListItem(<i32> _BIG_IDX) </locals>
         <callArgs> ARGS </callArgs>
      requires notBool #validArgIdx(ARG_IDX, ARGS)

    // extern void bigIntGetCallValue(void *context, int32_t destination);
    rule <instrs> hostCall("env", "bigIntGetCallValue", [ i32 .ValTypes ] -> [ .ValTypes ]) => .K ... </instrs>
         <locals> ListItem(<i32> IDX) </locals>
         <bigIntHeap> HEAP => HEAP [ IDX <- VALUE ] </bigIntHeap>
         <callValue> VALUE </callValue>

    // extern void bigIntGetExternalBalance(void *context, int32_t addressOffset, int32_t result);
    rule <instrs> hostCall("env", "bigIntGetExternalBalance", [ i32 i32 .ValTypes ] -> [ .ValTypes ])
               => #memLoad(ADDROFFSET, 32)
               ~> #getExternalBalance
               ~> #setBigIntFromBytesStack(RESULT, Unsigned)
               ~> #dropBytes
                  ...
         </instrs>
         <locals>
           ListItem(<i32> ADDROFFSET)
           ListItem(<i32> RESULT)
         </locals>

    // extern void bigIntGetESDTExternalBalance(void* context, int32_t addressOffset, int32_t tokenIDOffset, int32_t tokenIDLen, long long nonce, int32_t resultHandle);
    rule <instrs> hostCall ( "env" , "bigIntGetESDTExternalBalance" , [ i32  i32  i32  i64  i32  .ValTypes ] -> [ .ValTypes ] )
               => #memLoad(ADDR_OFFSET, 32)
               ~> #pushBytes(Int2Bytes(NONCE, BE, Unsigned))
               ~> #memLoad(TOK_ID_OFFSET, TOK_ID_LEN)
               ~> #appendBytes
               ~> #bigIntGetESDTExternalBalance(RES_HANDLE)
               ~> #dropBytes
               ~> #dropBytes
                  ...
         </instrs>
         <locals>
           ListItem(<i32> ADDR_OFFSET)
           ListItem(<i32> TOK_ID_OFFSET)
           ListItem(<i32> TOK_ID_LEN)
           ListItem(<i64> NONCE)
           ListItem(<i32> RES_HANDLE)
         </locals>

    syntax InternalInstr ::= #bigIntGetESDTExternalBalance(Int)
 // -----------------------------------------------------------
    rule <instrs> #bigIntGetESDTExternalBalance(RES_HANDLE)
               => #setBigIntValue( RES_HANDLE , BALANCE )
                  ...
         </instrs>
         <bytesStack> TOK_ID : ADDR : _ </bytesStack>
         <account>
           <address> ADDR </address>
           <esdtData>
             <esdtId> TOK_ID </esdtId>
             <esdtBalance> BALANCE </esdtBalance>
             ...
           </esdtData>
           ...
         </account>
      [priority(60)]

    rule <instrs> #bigIntGetESDTExternalBalance(RES_HANDLE)
               => #setBigIntValue( RES_HANDLE , 0 )
                  ...
         </instrs>
         <bytesStack> _TOK_ID : ADDR : _ </bytesStack>
         <account>
           <address> ADDR </address>
           ...
         </account>
      [priority(61)]

 // extern int32_t   bigIntIsInt64(void* context, int32_t destinationHandle);
    rule [bigIntIsInt64-invalid-handle]:
        <instrs> hostCall ( "env" , "bigIntIsInt64" , [ i32  .ValTypes ] -> [ i32  .ValTypes ] )
              => #throwException(ExecutionFailed, "no bigInt under the given handle") ...
        </instrs>
        <locals> ListItem(<i32> IDX) </locals>
        <bigIntHeap> HEAP </bigIntHeap>
      requires notBool (IDX in_keys( HEAP ))

    rule [bigIntIsInt64]:
        <instrs> hostCall ( "env" , "bigIntIsInt64" , [ i32  .ValTypes ] -> [ i32  .ValTypes ] )
              => i32.const #bool( minSInt64 <=Int V andBool V <=Int maxSInt64 )
                 ...
        </instrs>
        <locals> ListItem(<i32> IDX) </locals>
        <bigIntHeap> ... IDX |-> V ... </bigIntHeap>

 // extern void      bigIntSqrt(void* context, int32_t destinationHandle, int32_t opHandle);
    rule [bigIntSqrt-invalid-handle]:
        <instrs> hostCall ( "env" , "bigIntSqrt" , [ i32  i32  .ValTypes ] -> [ .ValTypes ] )
              => #throwException(ExecutionFailed, "no bigInt under the given handle") ...
        </instrs>
        <locals> ListItem(<i32> _DEST)  ListItem(<i32> IDX) </locals>
        <bigIntHeap> HEAP </bigIntHeap>
      requires notBool (IDX in_keys( HEAP ))

    rule [bigIntSqrt-neg]:
        <instrs> hostCall ( "env" , "bigIntSqrt" , [ i32  i32  .ValTypes ] -> [ .ValTypes ] )
              => #throwException(ExecutionFailed, "bad bounds (lower)")
                 ...
        </instrs>
        <locals> ListItem(<i32> _DEST)  ListItem(<i32> IDX) </locals>
        <bigIntHeap> ... IDX |-> V ... </bigIntHeap>
      requires V <Int 0

    rule [bigIntSqrt]:
        <instrs> hostCall ( "env" , "bigIntSqrt" , [ i32  i32  .ValTypes ] -> [ .ValTypes ] )
              => #setBigIntValue(DEST, sqrtInt(V))
                 ...
        </instrs>
        <locals> ListItem(<i32> DEST)  ListItem(<i32> IDX) </locals>
        <bigIntHeap> ... IDX |-> V ... </bigIntHeap>
      requires 0 <=Int V

 // extern void bigIntAbs(void* context, int32_t destinationHandle, int32_t opHandle);
    rule [bigIntAbs-invalid-handle]:
        <instrs> hostCall ( "env" , "bigIntAbs" , [ i32  i32  .ValTypes ] -> [ .ValTypes ] )
              => #throwException(ExecutionFailed, "no bigInt under the given handle") ...
        </instrs>
        <locals> ListItem(<i32> _DEST)  ListItem(<i32> IDX) </locals>
        <bigIntHeap> HEAP </bigIntHeap>
      requires notBool (IDX in_keys( HEAP ))

    rule [bigIntAbs]:
        <instrs> hostCall ( "env" , "bigIntAbs" , [ i32  i32  .ValTypes ] -> [ .ValTypes ] )
              => #setBigIntValue(DEST, absInt(V))
                 ...
        </instrs>
        <locals> ListItem(<i32> DEST)  ListItem(<i32> IDX) </locals>
        <bigIntHeap> ... IDX |-> V ... </bigIntHeap>


 // extern void bigIntNeg(void* context, int32_t destinationHandle, int32_t opHandle);
    rule [bigIntNeg-invalid-handle]:
        <instrs> hostCall ( "env" , "bigIntNeg" , [ i32  i32  .ValTypes ] -> [ .ValTypes ] )
              => #throwException(ExecutionFailed, "no bigInt under the given handle") ...
        </instrs>
        <locals> ListItem(<i32> _DEST)  ListItem(<i32> IDX) </locals>
        <bigIntHeap> HEAP </bigIntHeap>
      requires notBool (IDX in_keys( HEAP ))

    rule [bigIntNeg]:
        <instrs> hostCall ( "env" , "bigIntNeg" , [ i32  i32  .ValTypes ] -> [ .ValTypes ] )
              => #setBigIntValue(DEST, 0 -Int V)
                 ...
        </instrs>
        <locals> ListItem(<i32> DEST)  ListItem(<i32> IDX) </locals>
        <bigIntHeap> ... IDX |-> V ... </bigIntHeap>


endmodule
```
