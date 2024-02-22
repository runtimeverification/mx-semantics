# Kasmer Semantics

```k
requires "mandos.md"

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
          0 |-> <i32> ADDR_HANDLE
          1 |-> <i64> NONCE
          2 |-> <i32> BALANCE_HANDLE
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
          0 |-> <i32> OWNER_HANDLE
          1 |-> <i64> NONCE
          2 |-> <i32> ADDR_HANDLE
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
          0 |-> <i32> OWNER_HANDLE
          1 |-> <i64> GAS_LIMIT
          2 |-> <i32> VALUE_HANDLE
          3 |-> <i32> CODE_PATH_HANDLE
          4 |-> <i32> ARGS_HANDLE
          5 |-> <i32> RESULT_ADDR_HANDLE
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
          0 |-> <i32> OWNER_HANDLE
          1 |-> <i32> KEY_HANDLE
          2 |-> <i32> DEST_HANDLE
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
          0 |-> <i32> ADDR_HANDLE
          1 |-> <i32> KEY_HANDLE
          2 |-> <i32> VAL_HANDLE
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
          0 |-> <i32> ADDR_HANDLE
          1 |-> <i32> VAL_HANDLE
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

- `setESDTExternalBalance`

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
          0 |-> <i32> ADDR_HANDLE
          1 |-> <i32> TOK_ID_HANDLE
          2 |-> <i32> VAL_HANDLE
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

- `setESDTRole`
- `checkESDTRole`

```k
    rule [testapi-setESDTRole]:
        <instrs> hostCall ("env", "setESDTRole", [i32 i32 i32 i32 .ValTypes] -> [.ValTypes])
              => #getBuffer(TOK_ID_HANDLE)
              ~> #getBuffer(ADDR_HANDLE)
              ~> #setESDTRole(Int2ESDTRole(ROLE), P =/=Int 0)
              ~> #dropBytes
              ~> #dropBytes
                 ...
        </instrs>
        <locals>
          0 |-> <i32> ADDR_HANDLE
          1 |-> <i32> TOK_ID_HANDLE
          2 |-> <i32> ROLE
          3 |-> <i32> P
        </locals>

    syntax InternalInstr ::= #setESDTRole(ESDTLocalRole, Bool)
 // -------------------------------------------------------------
    // account and ESDT exist
    rule [setESDTRole-set-existing]:
        <instrs> #setESDTRole(ROLE, P) => . ... </instrs>
        <bytesStack> ADDR : TOK_ID : _ </bytesStack>
        <account>
          <address> ADDR </address>
          <esdtData>
            <esdtId> TOK_ID </esdtId>
            <esdtRoles> ROLES => updateSet(ROLES, ROLE, P) </esdtRoles>
            ...
          </esdtData>
          ...
        </account>

    // ESDT doesn't exist, P = true => add
    rule [setESDTRole-add-new]:
        <instrs> #setESDTRole(ROLE, true) => . ... </instrs>
        <bytesStack> ADDR : TOK_ID : _ </bytesStack>
        <account>
          <address> ADDR </address>
          (.Bag => <esdtData>
            <esdtId> TOK_ID </esdtId>
            <esdtRoles> SetItem(ROLE) </esdtRoles>
            ...
          </esdtData>)
          ...
        </account>
      [priority(60)]

    // ESDT doesn't exist, P = false => skip
    rule [setESDTRole-remove-skip]:
        <instrs> #setESDTRole(_ROLE, false) => . ... </instrs>
        <bytesStack> ADDR : _TOK_ID : _ </bytesStack>
        <account>
          <address> ADDR </address>
          ...
        </account>
      [priority(61)]

    // account not found
    rule [setESDTRole-not-found]:
        <instrs> #setESDTRole(_, _)
              => #throwExceptionBs(ExecutionFailed, b"account not found: " +Bytes ADDR) ... 
        </instrs>
        <bytesStack> ADDR : _TOK_ID : _ </bytesStack>
      [priority(62)]

    syntax Set ::= updateSet(Set, KItem, Bool)      [function, total]
 // -----------------------------------------------------------------
    rule updateSet(S, I, true) => S |Set SetItem(I)
    rule updateSet(S, I, false) => S -Set SetItem(I)

    syntax ESDTLocalRole ::= Int2ESDTRole(Int)   [function, total]
 // -------------------------------------------------------
    rule Int2ESDTRole(1) => ESDTRoleLocalMint
    rule Int2ESDTRole(2) => ESDTRoleLocalBurn
    rule Int2ESDTRole(3) => ESDTRoleNFTCreate
    rule Int2ESDTRole(4) => ESDTRoleNFTAddQuantity
    rule Int2ESDTRole(5) => ESDTRoleNFTBurn
    rule Int2ESDTRole(6) => ESDTRoleNFTAddURI
    rule Int2ESDTRole(7) => ESDTRoleNFTUpdateAttributes
    rule Int2ESDTRole(8) => ESDTTransferRole
    rule Int2ESDTRole(_) => None      [owise]

    rule [testapi-checkESDTRole]:
        <instrs> hostCall ("env", "checkESDTRole", [i32 i32 i32 .ValTypes] -> [i32 .ValTypes])
              => #getBuffer(TOK_ID_HANDLE)
              ~> #getBuffer(ADDR_HANDLE)
              ~> #checkESDTRole(Int2ESDTRole(ROLE))
              ~> #dropBytes
              ~> #dropBytes
                 ...
        </instrs>
        <locals>
          0 |-> <i32> ADDR_HANDLE
          1 |-> <i32> TOK_ID_HANDLE
          2 |-> <i32> ROLE
        </locals>

    syntax InternalInstr ::= #checkESDTRole(ESDTLocalRole)
 // -------------------------------------------------------------
    rule [checkESDTRole-exists]:
        <instrs> #checkESDTRole(ROLE) => i32.const #bool(ROLE in ROLES) ... </instrs>
        <bytesStack> ADDR : TOK_ID : _ </bytesStack>
        <account>
          <address> ADDR </address>
          <esdtData>
            <esdtId> TOK_ID </esdtId>
            <esdtRoles> ROLES </esdtRoles>
            ...
          </esdtData>
          ...
        </account>

    rule [checkESDTRole-none]:
        <instrs> #checkESDTRole(_ROLE) => i32.const 0 ... </instrs>
        <bytesStack> ADDR : _ : _ </bytesStack>
        <account>
          <address> ADDR </address>
          ...
        </account>
      [priority(60)]

    rule [checkESDTRole-not-found]:
        <instrs> #checkESDTRole(_ROLE)
              => #throwExceptionBs(ExecutionFailed, b"account not found: " +Bytes ADDR) ... 
        </instrs>
        <bytesStack> ADDR : _TOK_ID : _ </bytesStack>
      [priority(61)]

```

### Set current block info

```k
    rule [testapi-setBlockTimestamp]:
        <instrs> hostCall("env", "setBlockTimestamp", [i64 .ValTypes ] -> [.ValTypes ]) 
              => . ...
        </instrs>
        <locals>
          0 |-> <i64> TIMESTAMP
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
          0 |-> <i32> P
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
          0 |-> <i32> P
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
          0 |-> <i32> ADDR_HANDLE
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
        <locals> .Map </locals>
        <callee> _ => #foundryRunner </callee>
        <prank> true => false </prank>

    rule [testapi-stopPrank-err]:
        <instrs> hostCall ( "env" , "stopPrank" , [ .ValTypes ] -> [ .ValTypes ] )
              => #throwException(ExecutionFailed, "Cannot stop prank while not in a prank") ...
        </instrs>
        <locals> .Map </locals>
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
