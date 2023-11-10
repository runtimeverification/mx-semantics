# Kasmer Semantics

```k
require "mandos.md"

module KASMER-SYNTAX
    imports KASMER
endmodule

module KASMER
    imports MANDOS
```

## Configuration

```k
    configuration
      <foundry>
        <mandos/>
        <wasmStore> .Map </wasmStore> // file path -> wasm module AST
        <prank> false </prank>
      </foundry>

    syntax Bytes ::= "#foundryRunner"      [macro]
 // --------------------------------------------------------
    rule #foundryRunner 
      => b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00k-test________________"
```

## Foundry Host Functions

Only the `#foundryRunner` account can execute these commands/host functions.

### Create account

```k
    rule [testapi-createAccount]:
        <instrs> hostCall ( "env" , "createAccount" , [ i32  i64  i32  .ValTypes ] -> [ .ValTypes ] )
              => foundryCreateAccount( getBuffer(ADDR_HANDLE), NONCE, getBigInt(BALANCE_HANDLE))
                 ...
        </instrs>
        <locals>
          wrap(0) Int2Val|-> <i32> ADDR_HANDLE
          wrap(1) Int2Val|-> <i64> NONCE
          wrap(2) Int2Val|-> <i32> BALANCE_HANDLE
        </locals>
        <callee> #foundryRunner </callee>

    syntax InternalInstr ::= foundryCreateAccount(BytesResult, Int, IntResult)
 // ----------------------------------------------------------------------------
    rule [foundryCreateAccount]:
        <instrs> foundryCreateAccount(ADDR:Bytes, NONCE, BALANCE:Int)
              => #waitCommands
                 ...
        </instrs>
        <commands> (. => createAccount(ADDR)
                      ~> setAccountFields(ADDR, NONCE, BALANCE, .Code, .Bytes, .MapBytesToBytes )
                    ) ... 
        </commands>

    rule [foundryCreateAccount-err]:
        <instrs> foundryCreateAccount(_, _, _)
              => #throwException(ExecutionFailed, "Could not create account")
                 ...
        </instrs>
      [owise]

```

### Register new address

```k
    rule [testapi-registerNewAddress]:
        <instrs> hostCall ( "env" , "registerNewAddress" , [ i32  i64  i32  .ValTypes ] -> [ .ValTypes ] )
              => foundryRegisterNewAddress( getBuffer(OWNER_HANDLE), NONCE, getBuffer(ADDR_HANDLE))
                 ...
        </instrs>
        <locals>
          wrap(0) Int2Val|-> <i32> OWNER_HANDLE
          wrap(1) Int2Val|-> <i64> NONCE
          wrap(2) Int2Val|-> <i32> ADDR_HANDLE
        </locals>
        <callee> #foundryRunner </callee>

    syntax InternalInstr ::= foundryRegisterNewAddress(BytesResult, Int, BytesResult)
 // ----------------------------------------------------------------------------
    rule [foundryRegisterNewAddress]:
        <instrs> foundryRegisterNewAddress(CREATOR:Bytes, NONCE, NEW:Bytes)
              => . ...
        </instrs>
        <newAddresses> NEWADDRESSES => NEWADDRESSES [tuple(CREATOR, NONCE) <- NEW] </newAddresses>

    rule [foundryRegisterNewAddress-err]:
        <instrs> foundryRegisterNewAddress(_, _, _)
              => #throwException(ExecutionFailed, "Could not register address") ...
        </instrs>
      [owise]

```

### Deploy contract

```k
    rule [testapi-deployContract]:
        <instrs> hostCall("env", "deployContract", [i32 i64 i32 i32 i32 i32 .ValTypes] -> [.ValTypes])
              => foundryDeployContract(
                    getBuffer(OWNER_HANDLE), 
                    GAS_LIMIT,
                    getBigInt(VALUE_HANDLE),
                    getBuffer(CODE_PATH_HANDLE),
                    readManagedVecOfManagedBuffers(ARGS_HANDLE),
                    RESULT_ADDR_HANDLE
                    )
                 ...
        </instrs>
        <locals>
          wrap(0) Int2Val|-> <i32> OWNER_HANDLE
          wrap(1) Int2Val|-> <i64> GAS_LIMIT
          wrap(2) Int2Val|-> <i32> VALUE_HANDLE
          wrap(3) Int2Val|-> <i32> CODE_PATH_HANDLE
          wrap(4) Int2Val|-> <i32> ARGS_HANDLE
          wrap(5) Int2Val|-> <i32> RESULT_ADDR_HANDLE
        </locals>
        <callee> #foundryRunner </callee>

    syntax InternalInstr ::= foundryDeployContract(BytesResult, Int, IntResult, BytesResult, ListBytesResult, Int)
 // ----------------------------------------------------------------------------
    rule [foundryDeployContract]:
        <instrs> foundryDeployContract(OWNER:Bytes, GAS, VALUE:Int, PATH:Bytes, ARGS:ListBytes, RESULT_ADDR_HANDLE)
              => #waitCommands
              ~> #setBuffer(RESULT_ADDR_HANDLE, NEWADDR)
                 ...
        </instrs>
        <commands> (. 
                => createAccount(NEWADDR)
                ~> setAccountOwner(NEWADDR, OWNER)
                ~> setAccountCode(NEWADDR, MODULE)
                ~> callContract(NEWADDR, "init", mkVmInputDeploy(OWNER, VALUE, ARGS, GAS, 0))
                ) ...
        </commands>
        <account>
           <address> OWNER </address>
           <nonce> NONCE </nonce>
           ...
        </account>
        <newAddresses> ... tuple(OWNER, NONCE) |-> NEWADDR:Bytes ... </newAddresses>
        <wasmStore> ... PATH |-> MODULE </wasmStore>

    rule [foundryDeployContract-err]:
        <instrs> foundryDeployContract(_, _, _, _, _, _)
              => #throwException(ExecutionFailed, "Could not deploy contract")
                 ...
        </instrs>
      [owise]

```

### Get/set storage

```k
    rule [testapi-getStorage]:
        <instrs> hostCall ( "env" , "getStorage" , [ i32  i32  i32  .ValTypes ] -> [ .ValTypes ] )
              => #getBuffer(KEY_HANDLE)
              ~> #getBuffer(OWNER_HANDLE)
              ~> #storageLoadFromAddress
              ~> #setBufferFromBytesStack(DEST_HANDLE)
              ~> #dropBytes
                 ...
        </instrs>
        <locals>
          wrap(0) Int2Val|-> <i32> OWNER_HANDLE
          wrap(1) Int2Val|-> <i32> KEY_HANDLE
          wrap(2) Int2Val|-> <i32> DEST_HANDLE
        </locals>
        <callee> #foundryRunner </callee>

    rule [testapi-setStorage]:
        <instrs> hostCall ( "env" , "setStorage" , [ i32  i32  i32  .ValTypes ] -> [ .ValTypes ] )
              => #getBuffer(VAL_HANDLE)
              ~> #getBuffer(KEY_HANDLE)
              ~> #getBuffer(ADDR_HANDLE)
              ~> foundryWriteToStorage
              ~> #dropBytes
              ~> #dropBytes
              ~> #dropBytes
                 ...
        </instrs>
        <locals>
          wrap(0) Int2Val|-> <i32> ADDR_HANDLE
          wrap(1) Int2Val|-> <i32> KEY_HANDLE
          wrap(2) Int2Val|-> <i32> VAL_HANDLE
        </locals>
        <callee> #foundryRunner </callee>

    syntax InternalInstr ::= "foundryWriteToStorage"
 // -------------------------------------------------
    rule [foundryWriteToStorage-empty]:
        <instrs> foundryWriteToStorage => . ... </instrs>
        <bytesStack> ADDR : KEY : VALUE : _ </bytesStack>
         <account>
           <address> ADDR </address>
           <storage> STORAGE => STORAGE{{KEY <- undef}} </storage>
           ...
         </account>
         requires VALUE ==K .Bytes

    rule [foundryWriteToStorage]:
        <instrs> foundryWriteToStorage => . ... </instrs>
        <bytesStack> ADDR : KEY : VALUE : _ </bytesStack>
         <account>
           <address> ADDR </address>
           <storage> STORAGE => STORAGE{{KEY <- VALUE}} </storage>
           ...
         </account>
         requires VALUE =/=K .Bytes

```

### Set balance

#### EGLD

```k
    rule [testapi-setExternalBalance]:
        <instrs> hostCall ("env", "setExternalBalance", [i32 i32 .ValTypes] -> [.ValTypes])
              => #setBalance(getBuffer(ADDR_HANDLE), getBigInt(VAL_HANDLE)) ...
        </instrs>
        <locals>
          wrap(0) Int2Val|-> <i32> ADDR_HANDLE
          wrap(1) Int2Val|-> <i32> VAL_HANDLE
        </locals>
        <callee> #foundryRunner </callee>

    syntax InternalInstr ::= #setBalance(BytesResult, IntResult)
 // ------------------------------------------------------------
    rule [setBalance]:
        <instrs> #setBalance(ADDR:Bytes, VALUE:Int) => . ... </instrs>
        <account>
          <address> ADDR </address>
          <balance> _ => VALUE </balance>
          ...
        </account>
      requires 0 <=Int VALUE

    rule [setBalance-neg]:
        <instrs> #setBalance(_:Bytes, VALUE:Int)
              => #throwException(UserError, "Cannot set negative balance") ...
        </instrs>
      requires VALUE <Int 0

    // VALUE is valid but account not found
    rule [setBalance-acct-not-found]:
        <instrs> #setBalance(ADDR:Bytes, VALUE:Int)
              => #throwExceptionBs(ExecutionFailed, b"account not found: " +Bytes ADDR)
                 ...
        </instrs>
      requires 0 <=Int VALUE
      [owise]

    rule [setBalance-invalid-buffer]:
        <instrs> #setBalance(Err(MSG), _)
              => #throwException(ExecutionFailed, MSG) ...
        </instrs>

    rule [setBalance-invalid-big-int]:
        <instrs> #setBalance(_:Bytes, Err(MSG))
              => #throwException(ExecutionFailed, MSG) ...
        </instrs>
    
```

#### ESDT

```k

    rule [testapi-setESDTExternalBalance]:
        <instrs> hostCall ("env", "setESDTExternalBalance", [i32 i32 i32 .ValTypes] -> [.ValTypes])
              => #getBuffer(TOK_ID_HANDLE)
              ~> #getBuffer(ADDR_HANDLE)
              ~> #setESDTBalance(getBigInt(VAL_HANDLE))
              ~> #dropBytes
              ~> #dropBytes
                 ...
        </instrs>
        <locals>
          wrap(0) Int2Val|-> <i32> ADDR_HANDLE
          wrap(1) Int2Val|-> <i32> TOK_ID_HANDLE
          wrap(2) Int2Val|-> <i32> VAL_HANDLE
        </locals>
        <callee> #foundryRunner </callee>


    syntax InternalInstr ::= #setESDTBalance(IntResult)
 // ---------------------------------------------------
    // ERROR: invalid value handle
    rule [setESDTBalance-invalid-big-int]:
        <instrs> #setESDTBalance(Err(MSG))
              => #throwException(ExecutionFailed, MSG) ...
        </instrs>
    
    // ERROR: value is negative
    rule [setESDTBalance-neg]:
        <instrs> #setESDTBalance(VALUE:Int)
              => #throwException(UserError, "Cannot set negative balance") ...
        </instrs>
      requires 0 >Int VALUE
    
    
    // change an existing ESDT balance
    rule [setESDTBalance]:
        <instrs> #setESDTBalance(VALUE:Int) => . ... </instrs>
        <bytesStack> ADDR : TOK_ID : _ </bytesStack>
        <account>
          <address> ADDR </address>
          <esdtData>
            <esdtId> TOK_ID </esdtId>
            <esdtBalance> _ => VALUE </esdtBalance>
            ...
          </esdtData>
          ...
        </account>
      requires 0 <=Int VALUE

    // add new ESDT data
    rule [setESDTBalance-new-token]:
        <instrs> #setESDTBalance(VALUE:Int) => . ... </instrs>
        <bytesStack> ADDR : TOK_ID : _ </bytesStack>
        <account>
          <address> ADDR </address>
          (.Bag => <esdtData>
            <esdtId> TOK_ID </esdtId>
            <esdtBalance> VALUE </esdtBalance>
            ...
          </esdtData>)
          ...
        </account>
      requires 0 <=Int VALUE
      [priority(60)]
    
    // ERROR: account not found
    rule [setESDTBalance-acct-not-found]:
        <instrs> #setESDTBalance(VALUE:Int) 
              => #throwExceptionBs(ExecutionFailed, b"account not found: " +Bytes ADDR)
                 ... 
        </instrs>
        <bytesStack> ADDR : _ : _ </bytesStack>
      requires 0 <=Int VALUE
      [priority(61)]

```

### Set current block info

```k
    rule [testapi-setBlockTimestamp]:
        <instrs> hostCall("env", "setBlockTimestamp", [i64 .ValTypes ] -> [.ValTypes ]) 
              => . ...
        </instrs>
        <locals>
          wrap(0) Int2Val|-> <i64> TIMESTAMP
        </locals>
        <curBlockTimestamp> _ => TIMESTAMP </curBlockTimestamp>
        <callee> #foundryRunner </callee>

```

### Assertions and assumptions

```k
    rule [testapi-assertBool]:
        <instrs> hostCall ( "env" , "assertBool" , [ i32 .ValTypes ] -> [ .ValTypes ] )
              => #assert( P ) ...
        </instrs>
        <locals>
          wrap(0) Int2Val|-> <i32> P
        </locals>

    syntax InternalInstr ::= #assert(Int)     [symbol, klabel(foundryAssert)]
 // -------------------------------------------------------------------------
    rule [foundryAssert-true]:
        <instrs> #assert( I ) => . ... </instrs>    
      requires I =/=Int 0

    rule [foundryAssert-false]:
        <instrs> #assert( I ) 
             => #throwException(ExecutionFailed, "assertion failed") ... 
        </instrs>
      requires I ==Int 0


    rule [testapi-assumeBool]:
        <instrs> hostCall ( "env" , "assumeBool" , [ i32 .ValTypes ] -> [ .ValTypes ] )
              => #assume(P) ...
        </instrs>
        <locals>
          wrap(0) Int2Val|-> <i32> P
        </locals>

    syntax IternalInstr ::= #assume(Int)     [symbol, klabel(foundryAssume)]
 // ------------------------------------------------------------------------
    rule [foundryAssume-true]:
        <instrs> #assume(P) => . ... </instrs>
      requires P =/=Int 0

    rule [foundryAssume-false]:
        <instrs> #assume(P) => #endFoundryImmediately ... </instrs>
      requires P ==Int 0

    syntax InternalInstr ::= "#endFoundryImmediately"
        [symbol, klabel(endFoundryImmediately)]
 // ------------------------------------------------------
    rule [endFoundryImmediately]:
        (<callState>
          <instrs> #endFoundryImmediately ... </instrs>
          ...
        </callState> 
          => 
        <callState> 
          <instrs> . </instrs>
          ...
        </callState>)
        <callStack> _ => .List </callStack>
        <interimStates> _ => .List </interimStates>
        <k> _ => . </k>
        <commands> _ => . </commands>
        <checkedAccounts> _ => .Set </checkedAccounts>
        <prank> _ => false </prank>
        <exit-code> _ => 0 </exit-code>

```

### Prank

```k
    rule [testapi-startPrank]:
        <instrs> hostCall ( "env" , "startPrank" , [ i32  .ValTypes ] -> [ .ValTypes ] )
              => #startPrank(getBuffer(ADDR_HANDLE)) ...
        </instrs>
        <locals>
          wrap(0) Int2Val|-> <i32> ADDR_HANDLE
        </locals>
        <callee> #foundryRunner </callee>

    syntax InternalInstr ::= #startPrank(BytesResult)
 // -------------------------------------------------
    rule [startPrank]:
        <instrs> #startPrank(ADDR:Bytes) => . ... </instrs>
        <callee> #foundryRunner => ADDR </callee>
        <prank> false => true </prank>

    rule [startPrank-not-allowed]:
        <instrs> #startPrank(_:Bytes)
              => #throwException(ExecutionFailed, "Only the test contract can start a prank and the test contract can't start a prank while already pranking") 
                 ...
        </instrs>
        <callee> ADDR </callee>
        <prank> PRANK </prank>
      requires ADDR =/=K #foundryRunner
        orBool PRANK

    rule [startPrank-err]:
        <instrs> #startPrank(Err(MSG))
              => #throwException(ExecutionFailed, MSG) 
                 ...
        </instrs>

    rule [testapi-stopPrank]:
        <instrs> hostCall ( "env" , "stopPrank" , [ .ValTypes ] -> [ .ValTypes ] )
              => . ...
        </instrs>
        <locals> .MapIntToVal </locals>
        <callee> _ => #foundryRunner </callee>
        <prank> true => false </prank>

    rule [testapi-stopPrank-err]:
        <instrs> hostCall ( "env" , "stopPrank" , [ .ValTypes ] -> [ .ValTypes ] )
              => #throwException(ExecutionFailed, "Cannot stop prank while not in a prank") ...
        </instrs>
        <locals> .MapIntToVal </locals>
        <prank> false </prank>
      [owise]

```

## Misc

 ```k
    syntax InternalInstr ::= "#waitCommands"
 // ---------------------------------------
    rule [waitCommands]:
        <instrs> #waitCommands => . ... </instrs>
        <commands> #endWasm ... </commands>
      [priority(200)]

    rule <commands> #transferSuccess => . ... </commands>
         <instrs> #waitCommands ... </instrs>

endmodule
```