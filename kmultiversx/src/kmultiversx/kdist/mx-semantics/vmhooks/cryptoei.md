Crypto API
==========

Go implementation: [mx-chain-vm-go/vmhost/vmhooks/cryptoei.go](https://github.com/multiversx/mx-chain-vm-go/blob/ea3d78d34c35f7ef9c1a9ea4fce8288608763229/vmhost/vmhooks/cryptoei.go)

```k
requires "../elrond-config.md"
requires "manBufOps.md"
```

## Helpers

```k
module CRYPTOEI-HELPERS
    imports ELROND-CONFIG
    imports MANBUFOPS

    syntax HashBytesStackInstr ::= "#sha256FromBytesStack"
 // ------------------------------------------------------
    rule <instrs> #sha256FromBytesStack => .K ... </instrs>
         <bytesStack> (DATA => #parseHexBytes(Sha256(DATA))) : _STACK </bytesStack>

    syntax HashBytesStackInstr ::= "#keccakFromBytesStack"
 // ------------------------------------------------------
    rule <instrs> #keccakFromBytesStack => .K ... </instrs>
         <bytesStack> (DATA => #parseHexBytes(Keccak256(DATA))) : _STACK </bytesStack>

    syntax InternalInstr ::= #hashMemory ( Int , Int , Int ,  HashBytesStackInstr )
 // -------------------------------------------------------------------------------
    rule <instrs> #hashMemory(DATAOFFSET, LENGTH, RESULTOFFSET, HASHINSTR)
               => #memLoad(DATAOFFSET, LENGTH)
               ~> HASHINSTR
               ~> #memStoreFromBytesStack(RESULTOFFSET)
               ~> #dropBytes
               ~> i32.const 0
               ...
          </instrs>

    syntax InternalInstr ::= #hashManBuffer ( Int , Int , HashBytesStackInstr )
 // -------------------------------------------------------------------------------
    rule [hashManBuffer]:
        <instrs> #hashManBuffer(DATA_HANDLE, DEST_HANDLE, HASHINSTR)
              => #getBuffer(DATA_HANDLE)
              ~> HASHINSTR
              ~> #setBufferFromBytesStack(DEST_HANDLE)
              ~> #dropBytes
              ~> i32.const 0
                ...
        </instrs>

endmodule
```

## Host functions

```k
module CRYPTOEI
    imports CRYPTOEI-HELPERS

    // extern int32_t sha256(void* context, int32_t dataOffset, int32_t length, int32_t resultOffset);
    rule <instrs> hostCall("env", "sha256", [ i32 i32 i32 .ValTypes ] -> [ i32 .ValTypes ])
               => #hashMemory(DATAOFFSET, LENGTH, RESULTOFFSET, #sha256FromBytesStack)
                  ...
         </instrs>
         <locals>
           ListItem(<i32> DATAOFFSET)
           ListItem(<i32> LENGTH)
           ListItem(<i32> RESULTOFFSET)
         </locals>

    // extern int32_t managedSha256(void* context, int32_t inputHandle, int32_t outputHandle);
    rule [managedSha256]:
        <instrs> hostCall("env", "managedSha256", [ i32 i32  .ValTypes ] -> [ i32  .ValTypes ] )
              => #hashManBuffer(DATA, DEST, #sha256FromBytesStack)
                 ...
        </instrs>
        <locals> ListItem(<i32> DATA) ListItem(<i32> DEST) </locals>


    // extern int32_t keccak256(void *context, int32_t dataOffset, int32_t length, int32_t resultOffset);
    rule <instrs> hostCall("env", "keccak256", [ i32 i32 i32 .ValTypes ] -> [ i32 .ValTypes ])
               => #hashMemory(DATAOFFSET, LENGTH, RESULTOFFSET, #keccakFromBytesStack)
                  ...
         </instrs>
         <locals>
           ListItem(<i32> DATAOFFSET)
           ListItem(<i32> LENGTH)
           ListItem(<i32> RESULTOFFSET)
         </locals>

    // extern int32_t managedKeccak256(void* context, int32_t inputHandle, int32_t outputHandle);
    rule [managedKeccak256]:
        <instrs> hostCall("env", "managedKeccak256", [ i32 i32 .ValTypes ] -> [ i32 .ValTypes ])
              => #hashManBuffer(DATA, DEST, #keccakFromBytesStack)
                 ...
        </instrs>
        <locals> ListItem(<i32> DATA) ListItem(<i32> DEST) </locals>

endmodule
```
