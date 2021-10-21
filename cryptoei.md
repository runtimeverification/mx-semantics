Cryptoei API Module
===================

```k
require "auto-allocate.md"
require "elrond-config.md"

module CRYPTOEI
    imports ELROND-CONFIG
    imports WASM-AUTO-ALLOCATE

    // extern int32_t sha256(void* context, int32_t dataOffset, int32_t length, int32_t resultOffset);
    rule <instrs> hostCall("env", "sha256", [ i32 i32 i32 .ValTypes ] -> [ i32 .ValTypes ])
               => #hashMemory(DATAOFFSET, LENGTH, RESULTOFFSET, #sha256FromBytesStack)
                  ...
         </instrs>
         <locals>
           0 |-> <i32> DATAOFFSET
           1 |-> <i32> LENGTH
           2 |-> <i32> RESULTOFFSET
         </locals>

    // extern int32_t keccak256(void *context, int32_t dataOffset, int32_t length, int32_t resultOffset);
    rule <instrs> hostCall("env", "keccak256", [ i32 i32 i32 .ValTypes ] -> [ i32 .ValTypes ])
               => #hashMemory(DATAOFFSET, LENGTH, RESULTOFFSET, #keccakFromBytesStack)
                  ...
         </instrs>
         <locals>
           0 |-> <i32> DATAOFFSET
           1 |-> <i32> LENGTH
           2 |-> <i32> RESULTOFFSET
         </locals>

endmodule
```
