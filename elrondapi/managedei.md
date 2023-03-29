Managed EI
==========

```k
require "../elrond-config.md"
require "manBufOps.md"

module MANAGEDEI
     imports ELROND-CONFIG
     imports MANBUFOPS

    // extern void managedOwnerAddress(void* context, int32_t destinationHandle);
    rule <instrs> hostCall ( "env" , "managedOwnerAddress" , [ i32  .ValTypes ] -> [ .ValTypes ] )
               => #setBuffer( DEST_IDX , OWNER )
                  ...
         </instrs>
         <locals> 0 |-> DEST_IDX </locals>
         <callee> CALLEE </callee>
         <account>
            <address> CALLEE </address>
            <ownerAddress> OWNER </ownerAddress>
            ...
         </account>

    // TODO implement managedWriteLog
    // extern void      managedWriteLog(void* context, int32_t topicsHandle, int32_t dataHandle);
    rule <instrs> hostCall ( "env" , "managedWriteLog" , [ i32  i32  .ValTypes ] -> [ .ValTypes ] )
               => .
                  ...
         </instrs>

 // extern void      managedSignalError(void* context, int32_t errHandle);
    rule <instrs> hostCall ( "env" , "managedSignalError" , [ i32  .ValTypes ] -> [ .ValTypes ] )
               => #getBuffer(ERR_IDX)
               ~> #signalError
                  ...
         </instrs>
         <locals>  0 |-> <i32> ERR_IDX  </locals>

endmodule
```