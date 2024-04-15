
```k
requires "../elrond-config.md"
requires "manBufOps.md"
requires "managedConversions.md"

module ASYNC-HELPERS
    imports ASYNC-CALL
    imports ELROND-NODE

    syntax InternalCmd ::= "#asyncExecute"                    [symbol(asyncExecute)]
                         | #registerAsyncCall(AsyncCall)      [symbol(registerAsyncCall)]

    syntax Bool ::= isCallAsync(CallType)   [function, total]
 // ---------------------------------------------
    rule isCallAsync(AsynchronousCall)     => true
    rule isCallAsync(AsynchronousCallBack) => true    
    rule isCallAsync(DirectCall)           => false
  
endmodule

module ASYNC
    imports MANAGEDCONVERSIONS
    imports ASYNC-HELPERS

    rule [registerAsyncCall]:
        <commands> #registerAsyncCall(#asyncCall(... successCallback: CB1, errorCallback: CB2 ) #as CALL)
                // TODO calculate GasLocked
                => checkBool( CB1 =/=K b"init", "invalid function (invalid name)")
                ~> checkBool( notBool(isBuiltin(CB1))
                            , "cannot use built-in function as callback")
                ~> checkBool( CB2 =/=K b"init", "invalid function (invalid name)")
                ~> checkBool( notBool(isBuiltin(CB2))
                            , "cannot use built-in function as callback")
                ~> checkBool( FUNC =/=K b"init" andBool FUNC =/=K b"upgradeContract"
                            , "async call is not allowed at this location")
                ~> checkBool( notBool isMultilevelAsync(CALLTYPE, CALLSTACK)
                            , "multi-level async calls are not allowed yet")
                ~> #addAsyncCall(CALL)
                   ...
        </commands>
        <function> FUNC </function>
        <callType> CALLTYPE </callType>
        <callStack> CALLSTACK </callStack>

    syntax InternalCmd ::= #addAsyncCall(AsyncCall)    [symbol(addAsyncCall)]
 // -----------------------------------------------------------------------------------
    rule [addAsyncCall]:
        <commands> #addAsyncCall(#asyncCall(... dest: TO, func: FUNC) #as CALL) => .K ... </commands>
        <asyncCalls> L => L ListItem(CALL) </asyncCalls>
        <logging>
          S => S +String " -- addAsyncCall " +String Bytes2String(TO) +String " " +String FUNC
        </logging>


    syntax Bool ::= isMultilevelAsync(CallType, List)   [function, total]
 // ---------------------------------------------
    rule isMultilevelAsync(C, _) => true                  requires         isCallAsync(C)
    rule isMultilevelAsync(C, L) => isCallAsyncOnStack(L) requires notBool isCallAsync(C)
    
    syntax Bool ::= isCallAsyncOnStack(List)            [function, total]
 // ---------------------------------------------
    rule isCallAsyncOnStack(.List) => false
    rule isCallAsyncOnStack(ListItem(CALLSTATE) _) => true
      requires         isCallStateAsync(CALLSTATE)
    rule isCallAsyncOnStack(ListItem(CALLSTATE) L) => isCallAsyncOnStack(L)
      requires notBool isCallStateAsync(CALLSTATE)
    // stack item is not a CallStateCell. This should never happen
    rule isCallAsyncOnStack(ListItem(_) _) => false   [owise]

    syntax Bool ::= isCallStateAsync(CallStateCell)   [function, total]
 // ---------------------------------------------
    rule isCallStateAsync(<callState>
                            <vmInput>
                              <callType> T </callType>
                              _
                            </vmInput>
                            _
                          </callState>) => isCallAsync(T)


    rule [asyncExecute]:
        <commands> #asyncExecute
                => #executeAsyncLocalCalls
                  // TODO implement cross-shard calls
                   ...
        </commands>

    syntax InternalCmd ::= "#executeAsyncLocalCalls" [symbol(executeAsyncLocalCalls)]
 // -------------------------------------------------------------------------------
    rule [executeAsyncLocalCalls]:
        <commands> #executeAsyncLocalCalls
                => #executeAsyncLocalCall
                ~> #executeAsyncLocalCallback
                ~> #dropAsyncLocalCall
                ~> #executeAsyncLocalCalls
                   ...
        </commands>
        <asyncCalls> ListItem(_) ... </asyncCalls>
        <instrs> .K </instrs>

    rule [executeAsyncLocalCalls-empty]:
        <commands> #executeAsyncLocalCalls => .K ... </commands>
        <instrs> .K </instrs>
      [owise]


    syntax InternalCmd ::= "#dropAsyncLocalCall" [symbol(dropAsyncLocalCall)]
 // ---------------------------------------------------------------------------------------------
    rule [dropAsyncLocalCall]:
        <commands> #dropAsyncLocalCall => .K ... </commands>
        <asyncCalls> (ListItem(_) => .ListAsyncCall) ... </asyncCalls>

    syntax InternalCmd ::= "#executeAsyncLocalCall" [symbol(executeAsyncLocalCall)]
 // ---------------------------------------------------------------------------------------------
    rule [executeAsyncLocalCall]:
        <commands> #executeAsyncLocalCall
                => callContract(CHILD, FUNC,
                                <vmInput>
                                  <caller> PARENT </caller>
                                  <callArgs> ARGS </callArgs>
                                  <callValue> Bytes2Int(VALUE, BE, Unsigned) </callValue>
                                  <callType> AsynchronousCall </callType>
                                  <esdtTransfers> .List </esdtTransfers>
                                  <gasProvided> GAS </gasProvided>
                                  <gasPrice> GAS_PRICE </gasPrice>
                                </vmInput>)
                ~> #mergeOutputs
                    ...
        </commands>
        <callee> PARENT </callee>
        <gasPrice> GAS_PRICE </gasPrice>
        <asyncCalls> 
          ListItem(
            #asyncCall( ...
              dest: CHILD, func: FUNC, args: ARGS, valueBytes: VALUE, gas: GAS
            )
          )
          ...
        </asyncCalls>

    syntax InternalCmd ::= "#executeAsyncLocalCallback"        [symbol(executeAsyncLocalCallback)]
 // ---------------------------------------------------------------------------------------------
    rule [executeAsyncLocalCallback]:
        <commands> #executeAsyncLocalCallback
                => callContractCb(PARENT, chooseCallback(RC, CALL),
                                <vmInput>
                                  <caller> CHILD </caller>
                                  <callArgs> argsForCallback(RC, MSG, OUT) </callArgs>
                                  <callValue> extractLastValue(PARENT, VMOUTPUT) </callValue>
                                  <callType> AsynchronousCallBack </callType>
                                  <esdtTransfers> extractLastEsdt(PARENT, VMOUTPUT) </esdtTransfers>
                                  <gasProvided> GAS </gasProvided>
                                  <gasPrice> GAS_PRICE </gasPrice>
                                </vmInput>)
                ~> #mergeOutputs
                    ...
        </commands>
        <vmOutput>
          VMOutput( ... returnCode: RC, returnMessage: MSG , out: OUT ) #as VMOUTPUT
        </vmOutput>
        <callee> PARENT </callee>
        <gasPrice> GAS_PRICE </gasPrice>
        <asyncCalls> 
          ListItem(
            #asyncCall( ... 
              dest: CHILD,
              gas: GAS
            ) #as CALL
          )
          ...
        </asyncCalls>
      requires chooseCallback(RC, CALL) =/=String ""


    rule [executeAsyncLocalCallback-no-callback]:
        <commands> #executeAsyncLocalCallback => .K ... </commands>
        <vmOutput> VMOutput( ... returnCode: RC ) </vmOutput>
        <asyncCalls> ListItem(CALL) ... </asyncCalls>
      requires chooseCallback(RC, CALL) ==String ""

    syntax InternalCmd ::= callContractCb(Bytes, String, VmInputCell)
 // ---------------------------------------------------------------
    rule [callContractCb]:
        <commands> callContractCb(TO, FUNC, VMINPUT)
                => pushWorldState
                ~> pushCallState
                ~> resetCallstate
                ~> newWasmInstance(TO, CODE)
                ~> mkCall(TO, #quoteUnparseWasmString(FUNC), VMINPUT)
                ~> #endWasm
                   ...
        </commands>
        <account>
          <address> TO </address>
          <code> CODE </code>
          ...
        </account>
        <vmOutput> _ => .VMOutput </vmOutput>
        <logging> S => S +String " -- callContractCb " +String FUNC </logging>
      [priority(60)]


    syntax InternalCmd ::= "#mergeOutputs"
 // --------------------------------------
    rule [mergeOutputs]:
        <commands> #mergeOutputs => .K ... </commands>
        <vmOutput>
          VMOutput( ... returnCode: OK , out: OUTPUT, logs: LOGS, outputAccounts: OA2 )
        </vmOutput>
        <out> ... (.ListBytes => OUTPUT) </out>
        <logs> ... (.List => LOGS) </logs>
        <outputAccounts> OA => updateMap(OA, OA2) </outputAccounts> // TODO concat common items

    rule [mergeOutputs-err]:
        <commands> #mergeOutputs => .K ... </commands>
        <vmOutput>
          VMOutput( ... returnCode: _:ExceptionCode )
        </vmOutput>

    syntax String ::= chooseCallback(ReturnCode, AsyncCall)    [function, total]
 // -------------------------------------------------------------------------------
    rule chooseCallback(OK,              #asyncCall(... successCallback: F)) => F
    rule chooseCallback(_:ExceptionCode, #asyncCall(... errorCallback: F)) => F

    syntax ListBytes ::= argsForCallback(ReturnCode, Bytes, ListBytes)    [function, total]
 // -------------------------------------------------------------------
    rule argsForCallback(OK, _, OUT) 
      => ListItem(wrap(Int2Bytes(0, BE, Unsigned))) OUT
    rule argsForCallback(EC:ExceptionCode, MSG, _) 
      => ListItem(wrap(Int2Bytes(ReturnCode2Int(EC), BE, Unsigned))) ListItem(wrap(MSG))

    syntax Int ::= extractLastValue   (Bytes, VMOutput)       [function, total]
                 | extractLastValueAux(TransferValue)         [function, total]
 // --------------------------------------------------------------------------
    rule extractLastValue(PARENT, VMOutput(... out: .ListBytes, outputAccounts: OAs))
      => extractLastValueAux(lastTransfer(PARENT, OAs))
    rule extractLastValue(_, _) => 0                             [owise]    

    rule extractLastValueAux(I:Int) => I
    rule extractLastValueAux(_)     => 0                         [owise]
    
    syntax List ::= extractLastEsdt   (Bytes, VMOutput)       [function, total]
                  | extractLastEsdtAux(TransferValue)         [function, total]
 // --------------------------------------------------------------------------
    rule extractLastEsdt(PARENT, VMOutput(... out: .ListBytes, outputAccounts: OAs))
      => extractLastEsdtAux(lastTransfer(PARENT, OAs))
    rule extractLastEsdt(_, _) => .List                     [owise]    

    rule extractLastEsdtAux(E:ESDTTransfer) => ListItem(E)
    rule extractLastEsdtAux(_) => .List                     [owise]    


    syntax TransferValue ::= lastTransfer(Bytes, Map)      [function, total]
 // -----------------------------------------------------------------------------
    rule lastTransfer(PARENT, PARENT |-> OutputAccount(_, _ ListItem(T))) => T
    rule lastTransfer(_, _) => 0
      [owise] 

endmodule
```