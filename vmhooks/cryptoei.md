Crypto API
==========

Go implementation: [mx-chain-vm-go/vmhost/vmhooks/cryptoei.go](https://github.com/multiversx/mx-chain-vm-go/blob/ea3d78d34c35f7ef9c1a9ea4fce8288608763229/vmhost/vmhooks/cryptoei.go)

```k
require "../elrond-config.md"

module CRYPTOEI
     imports ELROND-CONFIG

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