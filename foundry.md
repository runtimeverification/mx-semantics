# Foundry for Elrond

```k
require "mandos.md"

module FOUNDRY-SYNTAX
    imports FOUNDRY
endmodule

module FOUNDRY
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

## Foundry Mandos Commands

### Fetch Wasm Code 

```k
    syntax Step ::= fetchWasmSource(Bytes, ModuleDecl)    [klabel(fetchWasmSource), symbol]
 // ---------------------------------------------------------------------------------------
    rule [fetchWasmSource]:
        <k> fetchWasmSource(PATH, MOD) => . ... </k>
        <wasmStore> ST => ST [PATH <- MOD] </wasmStore>
      [priority(60)]

```

## Foundry Host Functions

Only the `#foundryRunner` account can execute these commands/host functions.

### Create account

```k
    rule [hostCall-createAccount]:
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
    rule [instr-createAccount]:
        <instrs> foundryCreateAccount(ADDR:Bytes, NONCE, BALANCE:Int)
              => #waitCommands
                 ...
        </instrs>
        <commands> (. => createAccount(ADDR)
                      ~> setAccountFields(ADDR, NONCE, BALANCE, .Code, .Bytes, .MapBytesToBytes )
                    ) ... 
        </commands>

```

### Register new address

```k
    rule [hostCall-registerNewAddress]:
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
    rule [instr-registerNewAddress]:
        <instrs> foundryRegisterNewAddress(CREATOR:Bytes, NONCE, NEW:Bytes)
              => . ...
        </instrs>
        <newAddresses> NEWADDRESSES => NEWADDRESSES [tuple(CREATOR, NONCE) <- NEW] </newAddresses>

```

### Deploy contract

```k
    rule [hostCall-deployContract]:
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
    rule [instr-deployContract]:
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

```

### Get/set storage

```k
    rule [hostCall-getStorage]:
        <instrs> hostCall ( "env" , "getStorage" , [ i32  i32  i32  .ValTypes ] -> [ .ValTypes ] )
              => foundryGetStorage( getBuffer(OWNER_HANDLE), getBuffer(KEY_HANDLE), DEST_HANDLE)
                 ...
        </instrs>
        <locals>
          0 |-> <i32> OWNER_HANDLE
          1 |-> <i32> KEY_HANDLE
          2 |-> <i32> DEST_HANDLE
        </locals>
        <callee> #foundryRunner </callee>

    syntax InternalInstr ::= foundryGetStorage(BytesResult, BytesResult, Int)
 // -------------------------------------------------------------------------
    rule [testapi-getStorage]:
        <instrs> foundryGetStorage(OWNER:Bytes, KEY:Bytes, DEST_HANDLE)
              => #setBuffer(DEST_HANDLE, VAL)
                 ...
        </instrs>
        <account>
          <address> OWNER </address>
          <storage> ...  wrap(KEY) Bytes2Bytes|-> wrap(VAL) ... </storage>
          ...
        </account>

```

### Assertions/assumptions

```k
    rule [hostCall-assertBool]:
        <instrs> hostCall ( "env" , "assertBool" , [ i32 .ValTypes ] -> [ .ValTypes ] )
              => #if P =/=Int 0
                 #then .K
                 #else #throwException(ExecutionFailed, "assertion failed")
                 #fi
                 ...
        </instrs>
        <locals>
          0 |-> <i32> P
        </locals>


    rule [hostCall-assumeBool]:
        <instrs> hostCall ( "env" , "assumeBool" , [ i32 .ValTypes ] -> [ .ValTypes ] )
              => #assume(P) ...
        </instrs>
        <locals>
          0 |-> <i32> P
        </locals>

    syntax IternalInstr ::= #assume(Int)
 // ------------------------------------
    rule [assume]:
        <instrs> #assume(P) => . ... </instrs>
      ensures P =/=Int 0

```

### Prank

```k
    rule [hostCall-startPrank]:
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

    rule [hostCall-stopPrank]:
        <instrs> hostCall ( "env" , "stopPrank" , [ .ValTypes ] -> [ .ValTypes ] )
              => . ...
        </instrs>
        <locals> .Map </locals>
        <callee> _ => #foundryRunner </callee>
        <prank> true => false </prank>

```

## Misc

 ```k
    syntax InternalInstr ::= "#waitCommands"
 // ---------------------------------------
    rule [waitCommands]:
        <instrs> #waitCommands => . ... </instrs>
        <commands> #endWasm ... </commands>
      [priority(200)]   // TODO is this good?

    rule <commands> #transferSuccess => . ... </commands>
         <instrs> #waitCommands ... </instrs>

endmodule
```