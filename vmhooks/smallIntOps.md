Small Integers
============

Go implementation: [mx-chain-vm-go/vmhost/vmhooks/smallIntOps.go](https://github.com/multiversx/mx-chain-vm-go/blob/ea3d78d34c35f7ef9c1a9ea4fce8288608763229/vmhost/vmhooks/smallIntOps.go)

```k
require "../elrond-config.md"

module SMALLINTOPS
    imports BASEOPS
    imports ELROND-CONFIG

    // extern long long smallIntGetUnsignedArgument(void *context, int32_t id);
    rule <instrs> hostCall("env", "smallIntGetUnsignedArgument", [ i32 .ValTypes ] -> [ i64 .ValTypes ])
               => #returnIfUInt64(Bytes2Int(unwrap(ARGS[ARG_IDX]), BE, Unsigned), "argument out of range") ... </instrs>
         <locals> 0 |-> <i32> ARG_IDX </locals>
         <callArgs> ARGS </callArgs>
      requires #validArgIdx(ARG_IDX, ARGS)

    // extern long long smallIntGetSignedArgument(void *context, int32_t id);
    rule <instrs> hostCall("env", "smallIntGetSignedArgument", [ i32 .ValTypes ] -> [ i64 .ValTypes ])
               => #returnIfSInt64(Bytes2Int(unwrap(ARGS[ARG_IDX]), BE, Signed), "argument out of range") ... </instrs>
         <locals> 0 |-> <i32> ARG_IDX </locals>
         <callArgs> ARGS </callArgs>
      requires ARG_IDX <Int size(ARGS)

    // extern void smallIntFinishUnsigned(void* context, long long value);
    rule <instrs> hostCall("env", "smallIntFinishUnsigned", [ i64 .ValTypes ] -> [ .ValTypes ])
               => #appendToOut(Int2Bytes(#unsigned(i64, VALUE), BE, Unsigned))
                  ...
         </instrs>
         <locals> 0 |-> <i64> VALUE </locals>

    // extern void smallIntFinishSigned(void* context, long long value);
    rule <instrs> hostCall("env", "smallIntFinishSigned", [ i64 .ValTypes ] -> [ .ValTypes ])
               => #appendToOut(Int2Bytes(#signed(i64, VALUE), BE, Signed))
                  ...
         </instrs>
         <locals> 0 |-> <i64> VALUE </locals>

    // extern int32_t smallIntStorageStoreUnsigned(void *context, int32_t keyOffset, int32_t keyLength, long long value);
    rule <instrs> hostCall("env", "smallIntStorageStoreUnsigned", [ i32 i32 i64 .ValTypes ] -> [ i32 .ValTypes ])
               => #memLoad(KEYOFFSET, KEYLEN)
               ~> #pushBytes(Int2Bytes(VALUE, BE, Unsigned))
               ~> #storageStore
                  ...
         </instrs>
         <locals>
           0 |-> <i32> KEYOFFSET
           1 |-> <i32> KEYLEN
           2 |-> <i64> VALUE
         </locals>

    // extern int32_t smallIntStorageStoreSigned(void *context, int32_t keyOffset, int32_t keyLength, long long value);
    rule <instrs> hostCall("env", "smallIntStorageStoreSigned", [ i32 i32 i64 .ValTypes ] -> [ i32 .ValTypes ])
               => #memLoad(KEYOFFSET, KEYLEN)
               ~> #pushBytes(Int2Bytes(VALUE, BE, Signed))
               ~> #storageStore
                  ...
         </instrs>
         <locals>
           0 |-> <i32> KEYOFFSET
           1 |-> <i32> KEYLEN
           2 |-> <i64> VALUE
         </locals>

    // extern long long smallIntStorageLoadUnsigned(void *context, int32_t keyOffset, int32_t keyLength);
    rule <instrs> hostCall("env", "smallIntStorageLoadUnsigned", [ i32 i32 .ValTypes ] -> [ i64 .ValTypes ])
               => #memLoad(KEYOFFSET, KEYLENGTH)
               ~> #storageLoad
               ~> #loadBytesAsUInt64("storage value out of range")
                  ...
         </instrs>
         <locals>
           0 |-> <i32> KEYOFFSET
           1 |-> <i32> KEYLENGTH
         </locals>

    // extern long long smallIntStorageLoadSigned(void *context, int32_t keyOffset, int32_t keyLength);
    rule <instrs> hostCall("env", "smallIntStorageLoadSigned", [ i32 i32 .ValTypes ] -> [ i64 .ValTypes ])
               => #memLoad(KEYOFFSET, KEYLENGTH)
               ~> #storageLoad
               ~> #loadBytesAsSInt64("storage value out of range")
                  ...
         </instrs>
         <locals>
           0 |-> <i32> KEYOFFSET
           1 |-> <i32> KEYLENGTH
         </locals>

endmodule
```