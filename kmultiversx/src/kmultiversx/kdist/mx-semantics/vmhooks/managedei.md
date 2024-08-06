Managed EI
==========

Go implementation: [mx-chain-vm-go/vmhost/vmhooks/managedei.go](https://github.com/multiversx/mx-chain-vm-go/blob/ea3d78d34c35f7ef9c1a9ea4fce8288608763229/vmhost/vmhooks/managedei.go)

```k
requires "../elrond-config.md"
requires "manBufOps.md"
requires "managedConversions.md"

module MANAGEDEI
    imports ELROND-CONFIG
    imports MANBUFOPS
    imports MANAGEDCONVERSIONS

    // extern void managedOwnerAddress(void* context, int32_t destinationHandle);
    rule <instrs> hostCall ( "env" , "managedOwnerAddress" , [ i32  .ValTypes ] -> [ .ValTypes ] )
               => #setBuffer( DEST_IDX , OWNER )
                  ...
         </instrs>
         <locals> ListItem(<i32> DEST_IDX) </locals>
         <callee> CALLEE </callee>
         <account>
            <address> CALLEE </address>
            <ownerAddress> OWNER </ownerAddress>
            ...
         </account>

    // TODO implement managedWriteLog
    // extern void      managedWriteLog(void* context, int32_t topicsHandle, int32_t dataHandle);
    rule <instrs> hostCall ( "env" , "managedWriteLog" , [ i32  i32  .ValTypes ] -> [ .ValTypes ] )
               => .K
                  ...
         </instrs>

 // extern void      managedGetOriginalTxHash(void* context, int32_t resultHandle);
    rule <instrs> hostCall ( "env" , "managedGetOriginalTxHash" , [ i32  .ValTypes ] -> [ .ValTypes ] )
               => #setBuffer(RES_IDX, HASH) ...
         </instrs>
         <txHash> HASH </txHash>
         <locals>  ListItem(<i32> RES_IDX)  </locals>

 // extern void      managedSignalError(void* context, int32_t errHandle);
    rule <instrs> hostCall ( "env" , "managedSignalError" , [ i32  .ValTypes ] -> [ .ValTypes ] )
               => #getBuffer(ERR_IDX)
               ~> #signalError
                  ...
         </instrs>
         <locals>  ListItem(<i32> ERR_IDX)  </locals>

 // extern void      managedGetMultiESDTCallValue(void* context, int32_t multiCallValueHandle);
    rule <instrs> hostCall ( "env" , "managedGetMultiESDTCallValue" , [ i32  .ValTypes ] -> [ .ValTypes ] )
               => #writeEsdtsToBytes(ESDTS)
               ~> #setBufferFromBytesStack(DEST_IDX)
               ~> #dropBytes
                  ...
         </instrs>
         <locals>  ListItem(<i32> DEST_IDX)  </locals>
         <esdtTransfers> ESDTS </esdtTransfers>
  
 // extern int32_t   managedMultiTransferESDTNFTExecute(void* context, int32_t dstHandle, int32_t tokenTransfersHandle, long long gasLimit, int32_t functionHandle, int32_t argumentsHandle);
    rule [managedMultiTransferESDTNFTExecute]:
        <instrs> hostCall("env", "managedMultiTransferESDTNFTExecute", [ i32 i32 i64 i32 i32 .ValTypes ] -> [ i32 .ValTypes ] )
              => #transferESDTNFTExecuteWithTypedArgs(
                  getBuffer(DEST_IDX), 
                  readESDTTransfers(TRANSFERS_IDX), 
                  GAS_LIMIT, 
                  getBuffer(FUNC_IDX), 
                  readManagedVecOfManagedBuffers(ARGS_IDX)
                 )
                 ...
        </instrs>
        <locals>
          ListItem(<i32> DEST_IDX)
          ListItem(<i32> TRANSFERS_IDX)
          ListItem(<i64> GAS_LIMIT)
          ListItem(<i32> FUNC_IDX)
          ListItem(<i32> ARGS_IDX)
        </locals>
        
 // extern void      managedSCAddress(void* context, int32_t destinationHandle);
    rule <instrs> hostCall ( "env" , "managedSCAddress" , [ i32  .ValTypes ] -> [ .ValTypes ] )
               => #setBuffer( DEST_IDX , CALLEE )
                  ...
         </instrs>
         <locals> ListItem(<i32> DEST_IDX) </locals>
         <callee> CALLEE </callee>

 // extern int32_t managedTransferValueExecute(void* context, int32_t dstHandle, int32_t valueHandle, long long gasLimit, int32_t functionHandle, int32_t argumentsHandle);
    rule <instrs> hostCall ( "env" , "managedTransferValueExecute" , [ i32  i32  i64  i32  i32  .ValTypes ] -> [ i32  .ValTypes ] )
               => #transferValueExecuteWithTypedArgs(
                    getBuffer(DEST_IDX), 
                    getBigInt(VALUE_IDX), 
                    GAS_LIMIT, 
                    getBuffer(FUNC_IDX), 
                    readManagedVecOfManagedBuffers(ARGS_IDX)
                  )
                  ...
         </instrs>
         <locals>
           ListItem(<i32> DEST_IDX)
           ListItem(<i32> VALUE_IDX)
           ListItem(<i64> GAS_LIMIT)
           ListItem(<i32> FUNC_IDX)
           ListItem(<i32> ARGS_IDX)
         </locals>

 // extern int32_t managedExecuteOnDestContext(void* context, long long gas, int32_t addressHandle, int32_t valueHandle, int32_t functionHandle, int32_t argumentsHandle, int32_t resultHandle);
    rule [managedExecuteOnDestContext]:
        <instrs> hostCall ( "env" , "managedExecuteOnDestContext" , [i64 i32 i32 i32 i32 i32 .ValTypes ] -> [ i32  .ValTypes ] )
              => #executeOnDestContextWithTypedArgs(
                  getBuffer(DEST_IDX), 
                  getBigInt(VALUE_IDX),
                  .List,
                  GAS_LIMIT, 
                  getBuffer(FUNC_IDX), 
                  readManagedVecOfManagedBuffers(ARGS_IDX)
                 )
              ~> #setReturnDataIfExists(size(OUT), RES_IDX)
                 ...
        </instrs>
        <locals>
          ListItem(<i64> GAS_LIMIT)
          ListItem(<i32> DEST_IDX)
          ListItem(<i32> VALUE_IDX)
          ListItem(<i32> FUNC_IDX)
          ListItem(<i32> ARGS_IDX)
          ListItem(<i32> RES_IDX)
        </locals>
        <out> OUT </out>

    syntax InternalInstr ::= #setReturnDataIfExists(Int, Int)
 // ------------------------------------------------------
    rule [setReturnDataIfExists]:
        <instrs> #setReturnDataIfExists(OldLen, Dest)
              => #writeManagedVecOfManagedBuffers(rangeTotal(OUT, OldLen, 0), Dest)
                 ...
        </instrs>
        <out> OUT </out>
      requires OldLen <Int size(OUT)

    rule [setReturnDataIfExists-noData]:
        <instrs> #setReturnDataIfExists(OldLen, Dest)
              => #setBuffer(Dest, .Bytes)
                 ...
        </instrs>
        <out> OUT </out>
      requires OldLen >=Int size(OUT)

 // extern int32 managedCreateAsyncCall(void* context, int32_t destHandle, int32_t valueHandle, int32_t functionHandle,
 //                                     int32_t argumentsHandle, int32_t successOffset, int32_t successLength,
 //                                     int32_t errorOffset, int32_t errorLength, long long gas, long long extraGasForCallback,
 //                                     int32_t callbackClosureHandle);
    rule [managedCreateAsyncCall]:
        <instrs> hostCall ( "env" , "managedCreateAsyncCall" , [i32 i32 i32 i32 i32 i32 i32 i32 i64 i64 i32 .ValTypes ] -> [ i32  .ValTypes ] )
              => #memLoad(SUCC_OFF, SUCC_LEN)
              ~> #memLoad(ERR_OFF, ERR_LEN)
              ~> #createAsyncCallWithTypedArgs(
                  getBuffer(DEST_IDX), 
                  getBigInt(VALUE_IDX),
                  getBuffer(FUNC_IDX), 
                  readManagedVecOfManagedBuffers(ARGS_IDX),
                  GAS,
                  CB_GAS,
                  getBuffer(CB_CLOSURE_IDX)
                 )
                 ...
        </instrs>
        <locals>
          ListItem(<i32> DEST_IDX)
          ListItem(<i32> VALUE_IDX)
          ListItem(<i32> FUNC_IDX)
          ListItem(<i32> ARGS_IDX)
          ListItem(<i32> SUCC_OFF)
          ListItem(<i32> SUCC_LEN)
          ListItem(<i32> ERR_OFF)
          ListItem(<i32> ERR_LEN)
          ListItem(<i64> GAS)
          ListItem(<i64> CB_GAS)
          ListItem(<i32> CB_CLOSURE_IDX)
        </locals>

 // extern void managedAsyncCall(void* context, int32_t destHandle, int32_t valueHandle, int32_t functionHandle, int32_t argumentsHandle);
    rule [managedAsyncCall]:
        <instrs> hostCall("env", "managedAsyncCall", [i32 i32 i32 i32 .ValTypes] -> [ .ValTypes ] )
              ~> _
              => #pushBytes(b"callBack")
              ~> #pushBytes(b"callBack")
              ~> #createAsyncCallWithTypedArgs(
                  getBuffer(DEST_IDX), 
                  getBigInt(VALUE_IDX),
                  getBuffer(FUNC_IDX), 
                  readManagedVecOfManagedBuffers(ARGS_IDX),
                  GAS,
                  0,
                  b""
                 )
                 
        </instrs>
        <locals>
          ListItem(<i32> DEST_IDX)
          ListItem(<i32> VALUE_IDX)
          ListItem(<i32> FUNC_IDX)
          ListItem(<i32> ARGS_IDX)
        </locals>
        <gasProvided> GAS </gasProvided>

  // extern void managedGetCallbackClosure(void* context, int32_t destHandle);
  // Ideally, every call should have a call ID and parent call ID, and this should consider the parent call ID to locate the parent call.
  // Since we only handle local async calls for now, the parent async call is always the first one in the list.
    rule [managedGetCallbackClosure]:
        <instrs> hostCall ( "env" , "managedGetCallbackClosure" , [ i32 .ValTypes ] -> [ .ValTypes ] )
              => #setBuffer(DEST_IDX, CLOSURE)
                 ...
        </instrs>
        <locals>
          ListItem(<i32> DEST_IDX)
        </locals>
        <callType> AsynchronousCallBack </callType>
        <callStack>
          ListItem(
            <callState>
              <asyncCalls> ListItem( #asyncCall( ... closure: CLOSURE )) ... </asyncCalls>
              ...
            </callState>
          ) ...
        </callStack>

    rule [managedGetCallbackClosure-err]:
        <instrs> hostCall ( "env" , "managedGetCallbackClosure" , [ i32 .ValTypes ] -> [ .ValTypes ] )
              => #throwException(ExecutionFailed, "no callback for closure, cannot call callback directly")
                 ...
        </instrs>
        <locals>
          ListItem(<i32> _DEST_IDX)
        </locals>
      [owise]

 // extern void managedGetBlockRandomSeed(void *context, int32_t resultHandle);
    rule <instrs> hostCall("env", "managedGetBlockRandomSeed", [i32  .ValTypes] -> [ .ValTypes ] )
               => #setBuffer(BUF_IDX, SEED)
                  ...
         </instrs>
         <locals> ListItem(<i32> BUF_IDX) </locals>
         <curBlockRandomSeed> SEED </curBlockRandomSeed>

 // extern void managedGetPrevBlockRandomSeed(void* context, int32_t resultHandle);
    rule [managedGetPrevBlockRandomSeed]:
        <instrs> hostCall("env", "managedGetPrevBlockRandomSeed", [i32 .ValTypes] -> [ .ValTypes ] )
              => #setBuffer(BUF_IDX, SEED)
                 ...
        </instrs>
        <locals> ListItem(<i32> BUF_IDX) </locals>
        <prevBlockRandomSeed> SEED </prevBlockRandomSeed>




 // extern void managedGetESDTTokenData(void* context, int32_t addressHandle, int32_t tokenIDHandle, long long nonce,
 //                                                    int32_t valueHandle, int32_t propertiesHandle, int32_t hashHandle,
 //                                                    int32_t nameHandle, int32_t attributesHandle, int32_t creatorHandle,
 //                                                    int32_t royaltiesHandle, int32_t urisHandle);
    rule [managedGetESDTTokenData]:
        <instrs> hostCall("env", "managedGetESDTTokenData", [i32 i32 i64 i32 i32 i32 i32 i32 i32 i32 i32 .ValTypes] -> [ .ValTypes ] )
              => #getBuffer(ADDR_IDX)
              ~> #pushBytes(Int2Bytes(NONCE, BE, Unsigned))
              ~> #getBuffer(TOK_IDX)
              ~> #appendBytes
              ~> #getESDTTokenData
                 ...
        </instrs>
        <locals>
          ListItem(<i32> ADDR_IDX)
          ListItem(<i32> TOK_IDX)
          ListItem(<i64> NONCE)
          ...
        </locals>

    syntax InternalInstr ::= "#getESDTTokenData"
 // --------------------------------------------
    rule [getESDTTokenData-nft]:
        <instrs> #getESDTTokenData
              => #setBigIntValue(VAL_IDX, VALUE)
              ~> #setBuffer(PROPS_IDX, PROPS)
              ~> #setBuffer(HASH_IDX, HASH)
              ~> #setBuffer(NAME_IDX, NAME)
              ~> #setBuffer(ATTRS_IDX, ATTRS)
              ~> #setBuffer(HASH_IDX, HASH)
              ~> #setBuffer(CREATOR_IDX, CREATOR)
              ~> #setBigIntValue(ROYL_IDX, ROYL)
              ~> #writeManagedVecOfManagedBuffers(URIS, URIS_IDX)
                 ...
        </instrs>
        <bytesStack> TOKEN : ADDR : REST => REST </bytesStack>
        <locals>
          ListItem(_)
          ListItem(_)
          ListItem(_)
          ListItem(<i32> VAL_IDX)
          ListItem(<i32> PROPS_IDX)
          ListItem(<i32> HASH_IDX)
          ListItem(<i32> NAME_IDX)
          ListItem(<i32> ATTRS_IDX)
          ListItem(<i32> CREATOR_IDX)
          ListItem(<i32> ROYL_IDX)
          ListItem(<i32> URIS_IDX)
          ...
        </locals>
        <account>
          <address> ADDR </address>
          <esdtData>
            <esdtId> TOKEN </esdtId>
            <esdtBalance> VALUE </esdtBalance>
            <esdtMetadata>
              esdtMetadata( ...
                name: NAME,
                creator: CREATOR,
                royalties: ROYL,
                hash: HASH,
                uris: URIS,
                attributes: ATTRS
              )
            </esdtMetadata>
            <esdtProperties> PROPS </esdtProperties>
            ...
          </esdtData>
          ...
        </account>

    rule [getESDTTokenData-ft]:
        <instrs> #getESDTTokenData
              => #setBigIntValue(VAL_IDX, VALUE)
              ~> #setBuffer(PROPS_IDX, PROPS)
                 ...
        </instrs>
        <bytesStack> TOKEN : ADDR : REST => REST </bytesStack>
        <locals>
          ListItem(_)
          ListItem(_)
          ListItem(_)
          ListItem(<i32> VAL_IDX)
          ListItem(<i32> PROPS_IDX)
          ...
        </locals>
        <account>
          <address> ADDR </address>
          <esdtData>
            <esdtId> TOKEN </esdtId>
            <esdtBalance> VALUE </esdtBalance>
            <esdtMetadata> .esdtMetadata </esdtMetadata>
            <esdtProperties> PROPS </esdtProperties>
            ...
          </esdtData>
          ...
        </account>

    // extern long long getESDTLocalRoles(void* context, int32_t tokenIdHandle);
    rule [getESDTLocalRoles]:
        <instrs> hostCall("env", "getESDTLocalRoles", [ i32 .ValTypes ] -> [ i64 .ValTypes ])
              => #getBuffer(TOKEN_IDX)
              ~> #getESDTLocalRoles
              ~> #dropBytes
                 ...
        </instrs>
        <locals> ListItem(<i32> TOKEN_IDX) </locals>

    syntax InternalInstr ::= "#getESDTLocalRoles"     [symbol(getESDTLocalRoles)]
 // ---------------------------------------------
    rule [getESDTLocalRoles-aux]:
        <instrs> #getESDTLocalRoles
              => i64.const rolesToInt(ROLES)
                 ...
        </instrs>
        <bytesStack> TOKEN : _ </bytesStack>
        <callee> ADDR </callee>
        <account>
          <address> ADDR </address>
          <esdtData>
            <esdtId> TOKEN </esdtId>
            <esdtRoles> ROLES </esdtRoles>
            ...
          </esdtData>
          ...
        </account>

    rule [getESDTLocalRoles-aux-nil]:
        <instrs> #getESDTLocalRoles => i64.const 0 ... </instrs>
        <bytesStack> _TOKEN : _ </bytesStack>
      [owise]

    syntax Int ::= rolesToInt(Set)   [function, total]
 // ---------------------------------------------------
    rule rolesToInt(S) => #if ESDTRoleLocalMint      in S #then 1 #else 0 #fi 
                     +Int #if ESDTRoleLocalBurn      in S #then 2 #else 0 #fi
                     +Int #if ESDTRoleNFTCreate      in S #then 4 #else 0 #fi
                     +Int #if ESDTRoleNFTAddQuantity in S #then 8 #else 0 #fi
                     +Int #if ESDTRoleNFTBurn        in S #then 16 #else 0 #fi

endmodule
```
