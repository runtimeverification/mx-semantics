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
      <kasmer>
        <mandos/>
        <wasmStore> .Map </wasmStore> // file path -> wasm module AST
        <prank> false </prank>
      </kasmer>

    syntax Bytes ::= "#kasmerRunner"      [macro]
 // --------------------------------------------------------
    rule #kasmerRunner
      => b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00k-test________________"
```

## Kasmer Host Functions

Only the `#kasmerRunner` account can execute these commands/host functions.

### Create account

```k
    rule [testapi-createAccount]:
        <instrs> hostCall ( "env" , "createAccount" , [ i32  i64  i32  .ValTypes ] -> [ .ValTypes ] )
              => kasmerCreateAccount( getBuffer(ADDR_HANDLE), NONCE, getBigInt(BALANCE_HANDLE))
                 ...
        </instrs>
        <locals>
          ListItem(<i32> ADDR_HANDLE)
          ListItem(<i64> NONCE)
          ListItem(<i32> BALANCE_HANDLE)
        </locals>
        <callee> #kasmerRunner </callee>

    syntax InternalInstr ::= kasmerCreateAccount(BytesResult, Int, IntResult)
 // ----------------------------------------------------------------------------
    rule [kasmerCreateAccount]:
        <instrs> kasmerCreateAccount(ADDR:Bytes, NONCE, BALANCE:Int)
              => #waitCommands
                 ...
        </instrs>
        <commands> (.K => createAccount(ADDR)
                      ~> setAccountFields(ADDR, NONCE, BALANCE, .Code, .Bytes, .Map )
                    ) ...
        </commands>

    rule [kasmerCreateAccount-err]:
        <instrs> kasmerCreateAccount(_, _, _)
              => #throwException(ExecutionFailed, "Could not create account")
                 ...
        </instrs>
      [owise]

```

### Register new address

```k
    rule [testapi-registerNewAddress]:
        <instrs> hostCall ( "env" , "registerNewAddress" , [ i32  i64  i32  .ValTypes ] -> [ .ValTypes ] )
              => kasmerRegisterNewAddress( getBuffer(OWNER_HANDLE), NONCE, getBuffer(ADDR_HANDLE))
                 ...
        </instrs>
        <locals>
          ListItem(<i32> OWNER_HANDLE)
          ListItem(<i64> NONCE)
          ListItem(<i32> ADDR_HANDLE)
        </locals>
        <callee> #kasmerRunner </callee>

    syntax InternalInstr ::= kasmerRegisterNewAddress(BytesResult, Int, BytesResult)
 // ----------------------------------------------------------------------------
    rule [kasmerRegisterNewAddress]:
        <instrs> kasmerRegisterNewAddress(CREATOR:Bytes, NONCE, NEW:Bytes)
              => .K ...
        </instrs>
        <newAddresses> NEWADDRESSES => NEWADDRESSES [tuple(CREATOR, NONCE) <- NEW] </newAddresses>

    rule [kasmerRegisterNewAddress-err]:
        <instrs> kasmerRegisterNewAddress(_, _, _)
              => #throwException(ExecutionFailed, "Could not register address") ...
        </instrs>
      [owise]

```

### Deploy contract

```k
    rule [testapi-deployContract]:
        <instrs> hostCall("env", "deployContract", [i32 i64 i32 i32 i32 i32 .ValTypes] -> [.ValTypes])
              => kasmerDeployContract(
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
          ListItem(<i32> OWNER_HANDLE)
          ListItem(<i64> GAS_LIMIT)
          ListItem(<i32> VALUE_HANDLE)
          ListItem(<i32> CODE_PATH_HANDLE)
          ListItem(<i32> ARGS_HANDLE)
          ListItem(<i32> RESULT_ADDR_HANDLE)
        </locals>
        <callee> #kasmerRunner </callee>

    syntax InternalInstr ::= kasmerDeployContract(BytesResult, Int, IntResult, BytesResult, ListBytesResult, Int)
 // ----------------------------------------------------------------------------
    rule [kasmerDeployContract]:
        <instrs> kasmerDeployContract(OWNER:Bytes, GAS, VALUE:Int, PATH:Bytes, ARGS:ListBytes, RESULT_ADDR_HANDLE)
              => #waitCommands
              ~> #setBuffer(RESULT_ADDR_HANDLE, NEWADDR)
                 ...
        </instrs>
        <commands> (.K
                => createAccount(NEWADDR)
                ~> setAccountOwner(NEWADDR, OWNER)
                ~> setAccountCode(NEWADDR, MODULE)
                ~> callContract(NEWADDR, "init", mkVmInputDeploy(OWNER, VALUE, ARGS, GAS, 0, HASH))
                ) ...
        </commands>
        <txHash> HASH </txHash>
        <account>
           <address> OWNER </address>
           <nonce> NONCE </nonce>
           ...
        </account>
        <newAddresses> ... tuple(OWNER, NONCE) |-> NEWADDR:Bytes ... </newAddresses>
        <wasmStore> ... PATH |-> MODULE </wasmStore>

    rule [kasmerDeployContract-err]:
        <instrs> kasmerDeployContract(_, _, _, _, _, _)
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
          ListItem(<i32> OWNER_HANDLE)
          ListItem(<i32> KEY_HANDLE)
          ListItem(<i32> DEST_HANDLE)
        </locals>
        <callee> #kasmerRunner </callee>

    rule [testapi-setStorage]:
        <instrs> hostCall ( "env" , "setStorage" , [ i32  i32  i32  .ValTypes ] -> [ .ValTypes ] )
              => #getBuffer(VAL_HANDLE)
              ~> #getBuffer(KEY_HANDLE)
              ~> #getBuffer(ADDR_HANDLE)
              ~> kasmerWriteToStorage
              ~> #dropBytes
              ~> #dropBytes
              ~> #dropBytes
                 ...
        </instrs>
        <locals>
          ListItem(<i32> ADDR_HANDLE)
          ListItem(<i32> KEY_HANDLE)
          ListItem(<i32> VAL_HANDLE)
        </locals>
        <callee> #kasmerRunner </callee>

    syntax InternalInstr ::= "kasmerWriteToStorage"
 // -------------------------------------------------
    rule [kasmerWriteToStorage-empty]:
        <instrs> kasmerWriteToStorage => .K ... </instrs>
        <bytesStack> ADDR : KEY : VALUE : _ </bytesStack>
         <account>
           <address> ADDR </address>
           <storage> STORAGE => STORAGE[KEY <- undef] </storage>
           ...
         </account>
         requires VALUE ==K .Bytes
         [preserves-definedness] // ADDR exists prior in account map

    rule [kasmerWriteToStorage]:
        <instrs> kasmerWriteToStorage => .K ... </instrs>
        <bytesStack> ADDR : KEY : VALUE : _ </bytesStack>
         <account>
           <address> ADDR </address>
           <storage> STORAGE => STORAGE[KEY <- VALUE] </storage>
           ...
         </account>
         requires VALUE =/=K .Bytes
         [preserves-definedness] // ADDR exists prior in account map
```

### Set balance

#### EGLD

```k
    rule [testapi-setExternalBalance]:
        <instrs> hostCall ("env", "setExternalBalance", [i32 i32 .ValTypes] -> [.ValTypes])
              => #setBalance(getBuffer(ADDR_HANDLE), getBigInt(VAL_HANDLE)) ...
        </instrs>
        <locals>
          ListItem(<i32> ADDR_HANDLE)
          ListItem(<i32> VAL_HANDLE)
        </locals>
        <callee> #kasmerRunner </callee>

    syntax InternalInstr ::= #setBalance(BytesResult, IntResult)
 // ------------------------------------------------------------
    rule [setBalance]:
        <instrs> #setBalance(ADDR:Bytes, VALUE:Int) => .K ... </instrs>
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
          ListItem(<i32> ADDR_HANDLE)
          ListItem(<i32> TOK_ID_HANDLE)
          ListItem(<i32> VAL_HANDLE)
        </locals>
        <callee> #kasmerRunner </callee>


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
        <instrs> #setESDTBalance(VALUE:Int) => .K ... </instrs>
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
        <logging> S
               => S +String " -- setESDTBalance "
                    +String Bytes2String(ADDR) +String " "
                    +String Bytes2String(TOK_ID)
        </logging>
      requires 0 <=Int VALUE

    // add new ESDT data
    rule [setESDTBalance-new-token]:
        <instrs> #setESDTBalance(VALUE:Int) => .K ... </instrs>
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
        <logging> S
               => S +String " -- setESDTBalance "
                    +String Bytes2String(ADDR) +String " "
                    +String Bytes2String(TOK_ID)
        </logging>
      requires 0 <=Int VALUE
      [priority(60), preserves-definedness]
      // - ADDR exists prior so the account map is well-defined
      // - TOK_ID does not exist prior in esdtData because otherwise the rule above with higher priority would apply.

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
          ListItem(<i32> ADDR_HANDLE)
          ListItem(<i32> TOK_ID_HANDLE)
          ListItem(<i32> ROLE)
          ListItem(<i32> P)
        </locals>

    syntax InternalInstr ::= #setESDTRole(ESDTLocalRole, Bool)
 // -------------------------------------------------------------
    // account and ESDT exist
    rule [setESDTRole-set-existing]:
        <instrs> #setESDTRole(ROLE, P) => .K ... </instrs>
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
        <instrs> #setESDTRole(ROLE, true) => .K ... </instrs>
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
        <instrs> #setESDTRole(_ROLE, false) => .K ... </instrs>
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
          ListItem(<i32> ADDR_HANDLE)
          ListItem(<i32> TOK_ID_HANDLE)
          ListItem(<i32> ROLE)
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
              => .K ...
        </instrs>
        <locals>
          ListItem(<i64> TIMESTAMP)
        </locals>
        <curBlockTimestamp> _ => TIMESTAMP </curBlockTimestamp>
        <logging> S
               => S +String " -- setBlockTimestamp "
                    +String Int2String(TIMESTAMP)
        </logging>
        <callee> #kasmerRunner </callee>

```

### Assertions and assumptions

```k
    rule [testapi-assertBool]:
        <instrs> hostCall ( "env" , "assertBool" , [ i32 .ValTypes ] -> [ .ValTypes ] )
              => #assert( P ) ...
        </instrs>
        <locals>
          ListItem(<i32> P)
        </locals>

    syntax InternalInstr ::= #assert(Int)     [symbol(kasmerAssert)]
 // -------------------------------------------------------------------------
    rule [kasmerAssert-true]:
        <instrs> #assert( I ) => .K ... </instrs>
      requires I =/=Int 0

    rule [kasmerAssert-false]:
        <instrs> #assert( I )
             => #throwException(ExecutionFailed, "assertion failed") ...
        </instrs>
      requires I ==Int 0


    rule [testapi-assumeBool]:
        <instrs> hostCall ( "env" , "assumeBool" , [ i32 .ValTypes ] -> [ .ValTypes ] )
              => #assume(P) ...
        </instrs>
        <locals>
          ListItem(<i32> P)
        </locals>

    syntax IternalInstr ::= #assume(Int)     [symbol(kasmerAssume)]
 // ------------------------------------------------------------------------
    rule [kasmerAssume-true]:
        <instrs> #assume(P) => .K ... </instrs>
      requires P =/=Int 0

    rule [kasmerAssume-false]:
        <instrs> #assume(P) => #endFoundryImmediately ... </instrs>
      requires P ==Int 0

    syntax InternalInstr ::= "#endFoundryImmediately"
        [symbol(endFoundryImmediately)]
 // ------------------------------------------------------
    rule [endFoundryImmediately]:
        (<callState>
          <instrs> #endFoundryImmediately ... </instrs>
          ...
        </callState>
          =>
        <callState>
          <instrs> .K </instrs>
          ...
        </callState>)
        <callStack> _ => .List </callStack>
        <interimStates> _ => .List </interimStates>
        <k> _ => .K </k>
        <commands> _ => .K </commands>
        <checkedAccounts> _ => .Set </checkedAccounts>
        <prank> _ => false </prank>
        <exit-code> _ => 0 </exit-code>
    [preserves-definedness] // all initial configuration fields assumed defined
```

### Prank

```k
    rule [testapi-startPrank]:
        <instrs> hostCall ( "env" , "startPrank" , [ i32  .ValTypes ] -> [ .ValTypes ] )
              => #getBuffer(ADDR_HANDLE)
              ~> #startPrank ...
        </instrs>
        <locals>
          ListItem(<i32> ADDR_HANDLE)
        </locals>
        <callee> #kasmerRunner </callee>

    syntax InternalInstr ::= "#startPrank"
 // -------------------------------------------------
    rule [startPrank]:
        <instrs> #startPrank => .K ... </instrs>
        <bytesStack> ADDR:Bytes : S => S </bytesStack>
        <callee> #kasmerRunner => ADDR </callee>
        <prank> false => true </prank>

    rule [startPrank-not-allowed]:
        <instrs> #startPrank
              => #throwException(ExecutionFailed, "Only the test contract can start a prank and the test contract can't start a prank while already pranking")
                 ...
        </instrs>
        <bytesStack> _:Bytes : S => S </bytesStack>
        <callee> ADDR </callee>
        <prank> PRANK </prank>
      requires ADDR =/=K #kasmerRunner
        orBool PRANK

    rule [testapi-stopPrank]:
        <instrs> hostCall ( "env" , "stopPrank" , [ .ValTypes ] -> [ .ValTypes ] )
              => .K ...
        </instrs>
        <locals> .List </locals>
        <callee> _ => #kasmerRunner </callee>
        <prank> true => false </prank>

    rule [testapi-stopPrank-err]:
        <instrs> hostCall ( "env" , "stopPrank" , [ .ValTypes ] -> [ .ValTypes ] )
              => #throwException(ExecutionFailed, "Cannot stop prank while not in a prank") ...
        </instrs>
        <locals> .List </locals>
        <prank> false </prank>
      [owise]

endmodule
```
