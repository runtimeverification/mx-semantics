Small Integers
============

Go implementation: [mx-chain-vm-go/vmhost/vmhooks/smallIntOps.go](https://github.com/multiversx/mx-chain-vm-go/blob/ea3d78d34c35f7ef9c1a9ea4fce8288608763229/vmhost/vmhooks/smallIntOps.go)

```k
requires "../elrond-config.md"

module SMALLINTOPS
    imports BASEOPS
    imports ELROND-CONFIG
    imports private LIST-BYTES-EXTENSIONS

    // extern long long smallIntGetUnsignedArgument(void *context, int32_t id);
    rule [smallIntGetUnsignedArgument]:
        <instrs> hostCall("env", "smallIntGetUnsignedArgument", [ i32 .ValTypes ] -> [ i64 .ValTypes ])
              => #returnIfUInt64(Bytes2Int(ARGS {{ ARG_IDX }} orDefault b"", BE, Unsigned), "argument out of range")
                 ...
        </instrs>
        <locals> ListItem(<i32> ARG_IDX) </locals>
        <callArgs> ARGS </callArgs>
      requires #validArgIdx(ARG_IDX, ARGS)

    rule [smallIntGetUnsignedArgument-ioor]:
        <instrs> hostCall("env", "smallIntGetUnsignedArgument", [ i32 .ValTypes ] -> [ i64 .ValTypes ])
              => #throwException(ExecutionFailed, "argument index out of range")
                 ...
        </instrs>
        <locals> ListItem(<i32> ARG_IDX) </locals>
        <callArgs> ARGS </callArgs>
      requires notBool #validArgIdx(ARG_IDX, ARGS)


    // extern long long smallIntGetSignedArgument(void *context, int32_t id);
    rule [smallIntGetSignedArgument]:
        <instrs> hostCall("env", "smallIntGetSignedArgument", [ i32 .ValTypes ] -> [ i64 .ValTypes ])
              => #returnIfSInt64(Bytes2Int(ARGS {{ ARG_IDX }} orDefault b"", BE, Signed), "argument out of range")
                 ...
        </instrs>
        <locals> ListItem(<i32> ARG_IDX) </locals>
        <callArgs> ARGS </callArgs>
      requires #validArgIdx(ARG_IDX, ARGS)

    rule [smallIntGetSignedArgument-ioor]:
        <instrs> hostCall("env", "smallIntGetSignedArgument", [ i32 .ValTypes ] -> [ i64 .ValTypes ])
              => #throwException(ExecutionFailed, "argument index out of range")
                 ...
        </instrs>
        <locals> ListItem(<i32> ARG_IDX) </locals>
        <callArgs> ARGS </callArgs>
      requires notBool #validArgIdx(ARG_IDX, ARGS)


    // extern void smallIntFinishUnsigned(void* context, long long value);
    rule <instrs> hostCall("env", "smallIntFinishUnsigned", [ i64 .ValTypes ] -> [ .ValTypes ])
               => #appendToOut(Int2Bytes(#unsigned(i64, VALUE), BE, Unsigned))
                  ...
         </instrs>
         <locals> ListItem(<i64> VALUE) </locals>
      requires definedUnsigned(i64, VALUE)
      [preserves-definedness]
      // Preserving definedness: definedUnsigned(_) ensures #unsigned(_) is defined

    // extern void smallIntFinishSigned(void* context, long long value);
    rule <instrs> hostCall("env", "smallIntFinishSigned", [ i64 .ValTypes ] -> [ .ValTypes ])
               => #appendToOut(Int2Bytes(#signed(i64, VALUE), BE, Signed))
                  ...
         </instrs>
         <locals> ListItem(<i64> VALUE) </locals>
      requires definedSigned(i64, VALUE)
      [preserves-definedness]
      // Preserving definedness: definedSigned(_) ensures #signed(_) is defined


    // extern int32_t smallIntStorageStoreUnsigned(void *context, int32_t keyOffset, int32_t keyLength, long long value);
    rule <instrs> hostCall("env", "smallIntStorageStoreUnsigned", [ i32 i32 i64 .ValTypes ] -> [ i32 .ValTypes ])
               => #memLoad(KEYOFFSET, KEYLEN)
               ~> #pushBytes(Int2Bytes(VALUE, BE, Unsigned))
               ~> #storageStore
                  ...
         </instrs>
         <locals>
           ListItem(<i32> KEYOFFSET)
           ListItem(<i32> KEYLEN)
           ListItem(<i64> VALUE)
         </locals>

    // extern int32_t smallIntStorageStoreSigned(void *context, int32_t keyOffset, int32_t keyLength, long long value);
    rule <instrs> hostCall("env", "smallIntStorageStoreSigned", [ i32 i32 i64 .ValTypes ] -> [ i32 .ValTypes ])
               => #memLoad(KEYOFFSET, KEYLEN)
               ~> #pushBytes(Int2Bytes(VALUE, BE, Signed))
               ~> #storageStore
                  ...
         </instrs>
         <locals>
           ListItem(<i32> KEYOFFSET)
           ListItem(<i32> KEYLEN)
           ListItem(<i64> VALUE)
         </locals>

    // extern long long smallIntStorageLoadUnsigned(void *context, int32_t keyOffset, int32_t keyLength);
    rule <instrs> hostCall("env", "smallIntStorageLoadUnsigned", [ i32 i32 .ValTypes ] -> [ i64 .ValTypes ])
               => #memLoad(KEYOFFSET, KEYLENGTH)
               ~> #storageLoad
               ~> #loadBytesAsUInt64("storage value out of range")
                  ...
         </instrs>
         <locals>
           ListItem(<i32> KEYOFFSET)
           ListItem(<i32> KEYLENGTH)
         </locals>

    // extern long long smallIntStorageLoadSigned(void *context, int32_t keyOffset, int32_t keyLength);
    rule <instrs> hostCall("env", "smallIntStorageLoadSigned", [ i32 i32 .ValTypes ] -> [ i64 .ValTypes ])
               => #memLoad(KEYOFFSET, KEYLENGTH)
               ~> #storageLoad
               ~> #loadBytesAsSInt64("storage value out of range")
                  ...
         </instrs>
         <locals>
           ListItem(<i32> KEYOFFSET)
           ListItem(<i32> KEYLENGTH)
         </locals>

endmodule
```
