Mandos Testing Framework
========================

```k
requires "wasm-semantics/wasm-text.md"
requires "elrond.md"

module MANDOS-SYNTAX
    imports MANDOS
    imports WASM-TEXT-SYNTAX
endmodule
```

Mandos Configuration
--------------------

```k
module MANDOS
    imports COLLECTIONS
    imports ELROND

    configuration
      <mandos>
        <k> $PGM:Steps </k>
        <newAddresses> .Map </newAddresses>
        <checkedAccounts> .Set </checkedAccounts>
        <elrond/>
        <txCount> 0 </txCount>
        <exit-code exit=""> 0 </exit-code>
      </mandos>
    
    // Creates 32-byte a dummy transaction hash from transaction count.
    // The official Mandos (Scenario) implementation uses the "id" field as transaction hash. 
    syntax Bytes ::= mkTxHash(Int)    [function, total]
 // ---------------------------------------------------
    rule mkTxHash(TX_CNT) => Int2Bytes(32, TX_CNT, BE)

```

Mandos Steps
------------

### Wasm and Elrond Interaction

Only take the next step once both the Elrond node and Wasm are done executing.

```k
    syntax Step ::= "#wait"
 // -----------------------
    rule <k> #wait => .K ... </k>
         <commands> .K </commands>
         <instrs> .K </instrs>

    syntax Steps ::= List{Step, ""} [symbol(mandosSteps)]
 // -------------------------------------------------------------
    rule [steps-empty]:
        <k> .Steps => .K </k>
        <commands> .K </commands>
        <instrs> .K </instrs>
      [priority(60)]

    rule [steps-seq]:
        <k> S:Step SS:Steps => S ~> SS ... </k>
        <commands> .K </commands>
        <instrs> .K </instrs>
      [priority(60)]

    syntax Step ::= "setExitCode" Int     [symbol(setExitCode)]
 // -------------------------------------------------------------------
    rule <k> setExitCode I => .K ... </k>
         <commands> .K </commands>
         <instrs> .K </instrs>
         <exit-code> _ => I </exit-code>
      [priority(60)]

    syntax Step ::= ModuleDecl
 // --------------------------
    rule <k> (module _:OptionalId _:Defns):ModuleDecl #as M => #wait ... </k>
         <instrs> .K => sequenceStmts(text2abstract(M .Stmts)) </instrs>
         <commands> .K </commands>

    rule <k> M:ModuleDecl => #wait ... </k>
         <instrs> .K => M </instrs>
         <commands> .K </commands>
      [owise]

    syntax Step ::= "register" String [symbol(register)]
 // ------------------------------------------------------------
    rule <k> register NAME => .K ... </k>
         <moduleRegistry> REG => REG [NAME <- IDX -Int 1] </moduleRegistry>
         <nextModuleIdx> IDX </nextModuleIdx>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]

    syntax Step ::= checkFailed(Step)     [symbol(checkFailed)]

```

### Helper Functions

```k
    syntax Map  ::= #removeEmptyBytes ( Map ) [function]
 // ----------------------------------------------------------------------------------------
    rule #removeEmptyBytes(.Map)
        => .Map
    rule #removeEmptyBytes(Key |-> Value M)
        =>  #if Value ==K .Bytes
            #then #removeEmptyBytes(M)
            #else Key |-> Value #removeEmptyBytes(M)
            #fi
        requires notBool Key in_keys(M)
    rule #removeEmptyBytes(Key |-> Value M)
        =>  #if Value ==K .Bytes
            #then #removeEmptyBytes(M)
            #else Key |-> Value #removeEmptyBytes(M)
            #fi
        requires notBool Key in_keys(M)
        [simplification]

    syntax Map  ::= #removeReservedKeys ( Map ) [function]
 // ----------------------------------------------------------------------------------------
    rule #removeReservedKeys(.Map)
        => .Map
    rule #removeReservedKeys(Key |-> Value M)
        =>  #if #hasPrefix(Bytes2String(Key), "ELROND")
            #then #removeReservedKeys(M)
            #else Key |-> Value #removeReservedKeys(M)
            #fi
        requires notBool Key in_keys(M)
    rule #removeReservedKeys(Key |-> Value M)
        =>  #if #hasPrefix(Bytes2String(Key), "ELROND")
            #then #removeReservedKeys(M)
            #else Key |-> Value #removeReservedKeys(M)
            #fi
        requires notBool Key in_keys(M)
        [simplification]
```

### Step type: setState

```k
    syntax Step ::= setAccount    (
                        address: Address, nonce: Int, balance: Int, code: Code,
                        owner: Address, storage: Map )  [symbol(setAccount)]
                  | setAccountAux (
                        address: Bytes, nonce: Int, balance: Int, code: Code,
                        owner: Bytes, storage: Map )      [symbol(setAccountAux)]
                  | createAndSetAccountWithEmptyCode       ( Bytes, Int, Int, Map )
                  | createAndSetAccountAfterInitCodeModule ( Bytes, Int, Int, Map )
 // -------------------------------------------------------------------------------
    rule <k> setAccount(ADDRESS, NONCE, BALANCE, CODE, OWNER, STORAGE)
          => setAccountAux(#address2Bytes(ADDRESS), NONCE, BALANCE, CODE, #address2Bytes(OWNER), STORAGE) ... </k>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]

    rule <k> setAccountAux(ADDRESS, NONCE, BALANCE, CODE, OWNER, STORAGE) => #wait ... </k>
         <commands> .K 
                 => createAccount(ADDRESS)
                 ~> setAccountFields(ADDRESS, NONCE, BALANCE, CODE, OWNER, STORAGE) 
         </commands>
         <instrs> .K </instrs>
      [priority(60)]

    syntax Step ::= setEsdtBalance   ( Bytes , Bytes, Int, ESDTMetadata, Int )     [symbol(setEsdtBalance)]
                  | setEsdtBalanceAux( Bytes , Bytes,      ESDTMetadata, Int )     [symbol(setEsdtBalanceAux)]
 // ------------------------------------------------
    rule <k> setEsdtBalance( ADDR , TokId , Nonce, Metadata, Value )
          => setEsdtBalanceAux(ADDR, keyWithNonce(TokId, Nonce), Metadata, Value) ...
        </k>
         <commands> .K </commands>
         <instrs> .K </instrs>

    rule [setEsdtBalanceAux]:
        <k> setEsdtBalanceAux( ADDR , TokId , Metadata, Value ) => .K ... </k>
        <account>
          <address> ADDR </address>
          <esdtData>
            <esdtId> TokId </esdtId>
            <esdtBalance> _ => Value </esdtBalance>
            <esdtMetadata> _ => Metadata </esdtMetadata>
            ...
           </esdtData>
          ...
        </account>
        <commands> .K </commands>
        <instrs> .K </instrs>
      [priority(60)]

    rule [setEsdtBalanceAux-new]:
        <k> setEsdtBalanceAux( ADDR , TokId , Metadata , Value ) => .K ... </k>
        <account>
          <address> ADDR </address>
          <esdtDatas>
            (.Bag => <esdtData>
              <esdtId> TokId </esdtId>
              <esdtBalance> Value </esdtBalance>
            <esdtMetadata> Metadata </esdtMetadata>
              ...
            </esdtData>)
            ...
          </esdtDatas>
          ...
        </account>
        <commands> .K </commands>
        <instrs> .K </instrs>
      [priority(61)]


    syntax Step ::= setEsdtLastNonce ( Bytes , Bytes, Int )     [symbol(setEsdtLastNonce)]
 // ----------------------------------------------------------------------------
    rule [setEsdtLastNonce-existing]:
        <k> setEsdtLastNonce(ADDR, TOK, NONCE) => .K ... </k>
        <account>
          <address> ADDR </address>
          <esdtData>
            <esdtId> TOK </esdtId>
            <esdtLastNonce> _ => NONCE </esdtLastNonce>
            ...
           </esdtData>
          ...
        </account>
        <commands> .K </commands>
        <instrs> .K </instrs>
      [priority(60)]

    rule [setEsdtLastNonce-new]:
        <k> setEsdtLastNonce(ADDR, TOK, NONCE) => .K ... </k>
        <account>
          <address> ADDR </address>
          <esdtDatas>
            (.Bag => <esdtData>
              <esdtId> TOK </esdtId>
              <esdtLastNonce> NONCE </esdtLastNonce>
              ...
            </esdtData>)
            ...
          </esdtDatas>
          ...
        </account>
        <commands> .K </commands>
        <instrs> .K </instrs>
      [priority(61)]

    syntax Step ::= setEsdtRoles( Bytes , Bytes , Set )
        [symbol(setEsdtRoles)]
 // ----------------------------------------------------------------------------
    rule [setEsdtRoles-existing]:
        <k> setEsdtRoles(ADDR, TOK, ROLES) => .K ... </k>
        <account>
          <address> ADDR </address>
          <esdtData>
            <esdtId> TOK </esdtId>
            <esdtRoles> _ => ROLES </esdtRoles>
            ...
           </esdtData>
          ...
        </account>
        <commands> .K </commands>
        <instrs> .K </instrs>
      [priority(60)]

    rule [setEsdtRoles-new]:
        <k> setEsdtRoles(ADDR, TOK, ROLES) => .K ... </k>
        <account>
          <address> ADDR </address>
          <esdtDatas>
            (.Bag => <esdtData>
              <esdtId> TOK </esdtId>
              <esdtRoles> ROLES </esdtRoles>
              ...
            </esdtData>)
            ...
          </esdtDatas>
          ...
        </account>
        <commands> .K </commands>
        <instrs> .K </instrs>
      [priority(61)]

    syntax Step ::= checkEsdtRoles( Bytes , Bytes , Set )
        [symbol(checkEsdtRoles)]
 // ----------------------------------------------------------------------------
    rule [checkEsdtRoles]:
        <k> checkEsdtRoles(ADDR, TOK, ROLES) => .K ... </k>
        <account>
          <address> ADDR </address>
          <esdtData>
            <esdtId> TOK </esdtId>
            <esdtRoles> ROLES </esdtRoles>
            ...
           </esdtData>
          ...
        </account>
        <commands> .K </commands>
        <instrs> .K </instrs>
      [priority(60)]

    syntax Step ::= newAddress    ( Address, Int, Address ) [symbol(newAddress)]
                  | newAddressAux ( Bytes, Int, Bytes )     [symbol(newAddressAux)]
 // ---------------------------------------------------------------------------------------
    rule <k> newAddress(CREATOR, NONCE, NEW)
          => newAddressAux(#address2Bytes(CREATOR), NONCE, #address2Bytes(NEW)) ... </k>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]

    rule <k> newAddressAux(CREATOR, NONCE, NEW) => .K ... </k>
         <newAddresses> NEWADDRESSES => NEWADDRESSES [tuple(CREATOR, NONCE) <- NEW] </newAddresses>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]

    syntax AddressNonce ::= tuple( Bytes , Int )
 // ----------------------------------------------

    syntax Step      ::= setCurBlockInfo  ( BlockInfo ) [symbol(setCurBlockInfo)]
                       | setPrevBlockInfo ( BlockInfo ) [symbol(setPrevBlockInfo)]
    syntax BlockInfo ::= blockTimestamp  ( Int )   [symbol(blockTimestamp)]
                       | blockNonce      ( Int )   [symbol(blockNonce)]
                       | blockRound      ( Int )   [symbol(blockRound)]
                       | blockEpoch      ( Int )   [symbol(blockEpoch)]
                       | blockRandomSeed ( Bytes ) [symbol(blockRandomSeed)]
 // --------------------------------------------------------------------------------
    rule <k> setCurBlockInfo(blockTimestamp(TIMESTAMP)) => .K ... </k>
         <curBlockTimestamp> _ => TIMESTAMP </curBlockTimestamp>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]

    rule <k> setCurBlockInfo(blockNonce(NONCE)) => .K ... </k>
         <curBlockNonce> _ => NONCE </curBlockNonce>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]

    rule <k> setCurBlockInfo(blockRound(ROUND)) => .K ... </k>
         <curBlockRound> _ => ROUND </curBlockRound>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]

    rule <k> setCurBlockInfo(blockEpoch(EPOCH)) => .K ... </k>
         <curBlockEpoch> _ => EPOCH </curBlockEpoch>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]

    rule <k> setCurBlockInfo(blockRandomSeed(SEED)) => .K ... </k>
         <curBlockRandomSeed> _ => SEED </curBlockRandomSeed>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]

    rule <k> setPrevBlockInfo(blockTimestamp(TIMESTAMP)) => .K ... </k>
         <prevBlockTimestamp> _ => TIMESTAMP </prevBlockTimestamp>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]

    rule <k> setPrevBlockInfo(blockNonce(NONCE)) => .K ... </k>
         <prevBlockNonce> _ => NONCE </prevBlockNonce>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]

    rule <k> setPrevBlockInfo(blockRound(ROUND)) => .K ... </k>
         <prevBlockRound> _ => ROUND </prevBlockRound>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]

    rule <k> setPrevBlockInfo(blockEpoch(EPOCH)) => .K ... </k>
         <prevBlockEpoch> _ => EPOCH </prevBlockEpoch>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]

    rule <k> setPrevBlockInfo(blockRandomSeed(SEED)) => .K ... </k>
         <prevBlockRandomSeed> _ => SEED </prevBlockRandomSeed>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]
```

### Step type: checkState

```k
    syntax Step ::= checkAccountNonce    ( Address, Int ) [symbol(checkAccountNonce)]
                  | checkAccountNonceAux ( Bytes, Int )   [symbol(checkAccountNonceAux)]
 // --------------------------------------------------------------------------------------------
    rule <k> checkAccountNonce(ADDRESS, NONCE)
             => checkAccountNonceAux(#address2Bytes(ADDRESS), NONCE) ... </k>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]

    rule <k> checkAccountNonceAux(ADDR, NONCE) => .K ... </k>
         <account>
           <address> ADDR </address>
           <nonce> NONCE </nonce>
           ...
         </account>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]

    syntax Step ::= checkAccountBalance    ( Address, Int ) [symbol(checkAccountBalance)]
                  | checkAccountBalanceAux ( Bytes, Int )   [symbol(checkAccountBalanceAux)]
 // ------------------------------------------------------------------------------------------------
    rule <k> checkAccountBalance(ADDRESS, BALANCE)
             => checkAccountBalanceAux(#address2Bytes(ADDRESS), BALANCE) ... </k>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]

    rule <k> checkAccountBalanceAux(ADDR, BALANCE) => .K ... </k>
         <account>
           <address> ADDR </address>
           <balance> BALANCE </balance>
           ...
         </account>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]

    syntax Step ::= checkAccountESDTBalance    ( Bytes, Bytes, Int, Int ) [symbol(checkAccountESDTBalance)]
                  | checkAccountESDTBalanceAux ( Bytes, Bytes, Int )      [symbol(checkAccountESDTBalanceAux)]
 // ------------------------------------------------------------------------------------------------
    rule <k> checkAccountESDTBalance(ADDRESS, TOKEN, NONCE, BALANCE)
          => checkAccountESDTBalanceAux(ADDRESS, keyWithNonce(TOKEN, NONCE), BALANCE) ... </k>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]

    rule <k> checkAccountESDTBalanceAux(ADDR, TOKEN, BALANCE) #as C
          => #if BALANCE ==Int BALANCE2
             #then .K
             #else checkFailed(C)
             #fi ... </k>
         <account>
           <address> ADDR </address>
           <esdtData>
             <esdtId> TOKEN </esdtId>
             <esdtBalance> BALANCE2 </esdtBalance>
             ...
           </esdtData>
           ...
         </account>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]

    rule <k> checkAccountESDTBalanceAux(ADDR, _TOKEN, 0) => .K ... </k>
         <account>
           <address> ADDR </address>
           ...
         </account>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(61)]

    syntax Step ::= checkAccountStorage    ( Address, Map ) [symbol(checkAccountStorage)]
                  | checkAccountStorageAux ( Bytes, Map )   [symbol(checkAccountStorageAux)]
 // ------------------------------------------------------------------------------------------------
    rule <k> checkAccountStorage(ADDRESS, STORAGE)
             => checkAccountStorageAux(#address2Bytes(ADDRESS), STORAGE) ... </k>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]

    rule <k> checkAccountStorageAux(ADDR, STORAGE) => .K ... </k>
         <account>
           <address> ADDR </address>
           <storage> ACCTSTORAGE </storage>
           ...
         </account>
         <commands> .K </commands>
         <instrs> .K </instrs>
        requires #removeReservedKeys(ACCTSTORAGE) ==K #removeEmptyBytes(STORAGE)
      [priority(60)]

    syntax Step ::= checkAccountCode    ( Address, String ) [symbol(checkAccountCode)]
                  | checkAccountCodeAux ( Bytes, String )   [symbol(checkAccountCodeAux)]
 // ---------------------------------------------------------------------------------------------
    rule <k> checkAccountCode(ADDRESS, CODEPATH)
             => checkAccountCodeAux(#address2Bytes(ADDRESS), CODEPATH) ... </k>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]

    syntax OptionalString ::= #getModuleCodePath(ModuleDecl)    [function, total]
 // ----------------------------------------------------------------------
    rule #getModuleCodePath(#module (... metadata: #meta (... filename: PATH ) ) ) => PATH
    rule #getModuleCodePath((module OID:OptionalId DS:Defns) => structureModule(DS, OID))
    rule #getModuleCodePath(_) => .String                                                   [owise]

    rule [checkAccountCodeAux-no-code]:
         <k> checkAccountCodeAux(ADDR, "") => .K ... </k>
         <account>
           <address> ADDR </address>
           <code> .Code </code>
           ...
         </account>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]
      
    rule [checkAccountCodeAux-code]:
         <k> checkAccountCodeAux(ADDR, CODEPATH) => .K ... </k>
         <account>
           <address> ADDR </address>
           <code> CODE:ModuleDecl </code>
           ...
         </account>
         <commands> .K </commands>
         <instrs> .K </instrs>
      requires CODEPATH ==K #getModuleCodePath(CODE)
      [priority(60)]

    syntax Step ::= checkedAccount    ( Address ) [symbol(checkedAccount)]
                  | checkedAccountAux ( Bytes )   [symbol(checkedAccountAux)]
 // ---------------------------------------------------------------------------------
    rule <k> checkedAccount(ADDRESS)
             => checkedAccountAux(#address2Bytes(ADDRESS)) ... </k>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]

    rule <k> checkedAccountAux(ADDR) => .K ... </k>
         <checkedAccounts> ... (.Set => SetItem(ADDR)) ... </checkedAccounts>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]

    syntax Step ::= checkNoAdditionalAccounts( Set ) [symbol(checkNoAdditionalAccounts)]
 // ---------------------------------------------------------------------------------------
    rule <k> checkNoAdditionalAccounts(EXPECTED) => .K ... </k>
         <checkedAccounts> CHECKEDACCTS </checkedAccounts>
         <commands> .K </commands>
         <instrs> .K </instrs>
      requires EXPECTED ==K CHECKEDACCTS
      [priority(60)]

    syntax Step ::= "clearCheckedAccounts" [symbol(clearCheckedAccounts)]
 // -----------------------------------------------------------------------------
    rule <k> clearCheckedAccounts => .K ... </k>
         <checkedAccounts> _ => .Set </checkedAccounts>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]
```

### Step type: scCall

```k
    syntax Step ::= callTx    (from: Address, to: Address, value: Int, esdtValue: List, func: WasmString, args: ListBytes, gasLimit: Int, gasPrice: Int) [symbol(callTx)]
                  | callTxAux (from: Bytes,   to: Bytes,   value: Int, esdtValue: List, func: WasmString, args: ListBytes, gasLimit: Int, gasPrice: Int) [symbol(callTxAux)]
 // ----------------------------------------------------------------------------------------------------------------------------------------------------------
    rule [callTx]:
        <k> callTx(FROM, TO, VALUE, ESDT, FUNCTION, ARGS, GASLIMIT, GASPRICE)
         => callTxAux(#address2Bytes(FROM), #address2Bytes(TO), VALUE, ESDT, FUNCTION, ARGS, GASLIMIT, GASPRICE) ... 
        </k>
        <commands> .K </commands>
        <instrs> .K </instrs>
      [priority(60)]

    rule [callTxAux]:
        <k> callTxAux(FROM, TO, VALUE, ESDT, FUNCTION, ARGS, GASLIMIT, GASPRICE) => #wait ... </k>
        <commands> .K => callContract(
                            TO, FUNCTION, 
                            mkVmInputSCCall(FROM, ARGS, VALUE, ESDT, GASLIMIT, GASPRICE, mkTxHash(CNT))
                          ) 
        </commands>
        <instrs> .K </instrs>
        <account>
          <address> FROM </address>
          <nonce> NONCE => NONCE +Int 1 </nonce>
          <balance> BALANCE => BALANCE -Int GASLIMIT *Int GASPRICE </balance>
          ...
        </account>
        <txCount> CNT => CNT +Int 1 </txCount>
      [priority(60), preserves-definedness]
      // Preserving definedness:
      //   - callContract is a constructor
      //   - mkVmInputSCCall is total
      //   - Map updates (account) preserve definedness
      //   - +String, +Int, -Int and *Int are total
      //   - #parseWasmString is total.

    syntax VmInputCell ::= mkVmInputSCCall(Bytes, ListBytes, Int, List, Int, Int, Bytes)    [function, total]
 // -----------------------------------------------------------------------------------
    rule mkVmInputSCCall(FROM, ARGS, VALUE, ESDT, GAS, GAS_PRICE, HASH)
      => <vmInput>
            <caller> FROM </caller>
            <callArgs> ARGS </callArgs>
            <callValue> VALUE </callValue>
            <callType> DirectCall </callType>
            <esdtTransfers> ESDT </esdtTransfers>
            // gas
            <gasProvided> GAS </gasProvided>
            <gasPrice> GAS_PRICE </gasPrice>
            <txHash> HASH </txHash>
          </vmInput>

    syntax Step ::= checkExpectOut ( ListBytes ) [symbol(checkExpectOut)]
 // --------------------------------------------------------------------------
    rule <k> checkExpectOut(OUT) => .K ... </k>
         <vmOutput> VMOutput(... out: OUT) </vmOutput>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]

    syntax Step ::= checkExpectStatus ( ReturnCode ) [symbol(checkExpectStatus)]
 // ------------------------------------------------------------------------------------
    rule <k> checkExpectStatus(RETURNCODE) => .K ... </k>
         <vmOutput> VMOutput(... returnCode: RETURNCODE) </vmOutput>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]

    syntax Step ::= checkExpectMessage ( Bytes ) [symbol(checkExpectMessage)]
 // ---------------------------------------------------------------------------------
    rule <k> checkExpectMessage(MSG) => .K ... </k>
         <vmOutput> VMOutput(... returnMessage: MSG) </vmOutput>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]

    syntax Step ::= checkExpectLogs ( List ) [symbol(checkExpectLogs)]
 // --------------------------------------------------------------------------
    rule <k> checkExpectLogs(LOGS) => .K ... </k>
         <vmOutput> VMOutput(... logs: LOGS) </vmOutput>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]
    // TODO implement event logs (some host functions like ESDT transfer should emit event logs. see crowdfunding-claim-successful.json)
    rule <k> checkExpectLogs(_LOGS) => .K ... </k>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(61)]

```

## Step type: scQuery

TODO make sure that none of the state changes are persisted -- [Doc](https://docs.multiversx.com/developers/scenario-reference/structure#step-type-scquery)

```k
    syntax Step ::= queryTx    (to: Address, func: WasmString, args: ListBytes) [symbol(queryTx)]
                  | queryTxAux (to: Bytes,   func: WasmString, args: ListBytes) [symbol(queryTxAux)]
 // ---------------------------------------------------------------------------------------------------
    rule <k> queryTx(TO, FUNCTION, ARGS) => queryTxAux(#address2Bytes(TO), FUNCTION, ARGS) ... </k>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]

    rule <k> queryTxAux(TO, FUNCTION, ARGS) => #wait ... </k>
         <commands> .K => callContract(TO, FUNCTION, mkVmInputQuery(TO, ARGS, mkTxHash(CNT))) </commands>
         <instrs> .K </instrs>
         <txCount> CNT => CNT +Int 1 </txCount>
      [priority(60)]

    syntax VmInputCell ::= mkVmInputQuery(Bytes, ListBytes, Bytes)    [function, total]
 // -----------------------------------------------------------------------------------
    rule mkVmInputQuery(TO, ARGS, HASH)
      => <vmInput>
            <caller> TO </caller>
            <callArgs> ARGS </callArgs>
            <callValue> 0 </callValue>
            <callType> DirectCall </callType>
            <esdtTransfers> .List </esdtTransfers>
            // gas
            <gasProvided> maxUInt64 </gasProvided>
            <gasPrice> 0 </gasPrice>
            <txHash> HASH </txHash>
          </vmInput>
```

### Step type: scDeploy

```k
    syntax Step ::= deployTx    ( Address, Int, ModuleDecl, ListBytes, Int, Int ) [symbol(deployTx)]
                  | deployTxAux (   Bytes, Int, ModuleDecl, ListBytes, Int, Int )   [symbol(deployTxAux)]
 // ------------------------------------------------------------------------------------------------------
    rule <k> deployTx(FROM, VALUE, MODULE, ARGS, GASLIMIT, GASPRICE)
          => deployTxAux(#address2Bytes(FROM), VALUE, MODULE, ARGS, GASLIMIT, GASPRICE) ... 
         </k>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]

    rule [deployTxAux]:
        <k> deployTxAux(FROM, VALUE, MODULE, ARGS, GASLIMIT, GASPRICE) => #wait ... </k>
        <commands> .K 
                => createAccount(NEWADDR)
                ~> setAccountOwner(NEWADDR, FROM)
                ~> setAccountCode(NEWADDR, MODULE)
                ~> callContract(NEWADDR, "init", mkVmInputDeploy(FROM, VALUE, ARGS, GASLIMIT, GASPRICE, mkTxHash(CNT)))
        </commands>
        <instrs> .K </instrs>
        <account>
           <address> FROM </address>
           <nonce> NONCE => NONCE +Int 1 </nonce>
           <balance> BALANCE => BALANCE -Int GASLIMIT *Int GASPRICE </balance>
           ...
        </account>
        <newAddresses> ... tuple(FROM, NONCE) |-> NEWADDR:Bytes ... </newAddresses>
        <txCount> CNT => CNT +Int 1 </txCount>
      [priority(60)]

    syntax VmInputCell ::= mkVmInputDeploy(Bytes, Int, ListBytes, Int, Int, Bytes)    [function, total]
 // -----------------------------------------------------------------------------------
    rule mkVmInputDeploy(FROM, VALUE, ARGS, GASLIMIT, GASPRICE, HASH)
      => <vmInput>
            <caller> FROM </caller>
            <callArgs> ARGS </callArgs>
            <callValue> VALUE </callValue>
            <callType> DirectCall </callType>
            <esdtTransfers> .List </esdtTransfers>
            // gas
            <gasProvided> GASLIMIT </gasProvided>
            <gasPrice> GASPRICE </gasPrice>
            <txHash> HASH </txHash>
          </vmInput>
```

### Step type: transfer

```k
    syntax Step ::= transfer(TransferTx) [symbol(transfer)]
 // -----------------------------------------------------
    rule <k> transfer(TX) => TX ... </k>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]

    syntax TransferTx ::= transferTx    ( from: Address, to: Bytes, value: Int ) [symbol(transferTx)]
                        | transferTxAux ( from: Bytes, to: Bytes, value: Int )   [symbol(transferTxAux)]
 // ------------------------------------------------------------------------------------------------------------
    rule <k> transferTx(FROM, TO, VAL) 
          => transferTxAux(#address2Bytes(FROM), #address2Bytes(TO), VAL) ...
         </k>
         <commands> .K </commands>
         <instrs> .K </instrs>
    [priority(60)]

    rule <k> transferTxAux(FROM, TO, VAL) => #wait ... </k>
         <commands> .K => transferFunds(FROM, TO, VAL) </commands>
         <instrs> .K </instrs>
         <account>
          <address> FROM </address>
          <nonce> NONCE => NONCE +Int 1 </nonce>
          ...
        </account>
      [priority(60)]
```

### Step type: validatorReward

```k
    syntax Step ::= validatorReward(ValidatorRewardTx) [symbol(validatorReward)]
 // ------------------------------------------------------------------------------------
    rule <k> validatorReward(TX) => TX ... </k>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]

    syntax ValidatorRewardTx ::= validatorRewardTx    ( to: Address, value: Int) [symbol(validatorRewardTx)]
                               | validatorRewardTxAux ( to: Bytes, value: Int )  [symbol(validatorRewardTxAux)]
 // -------------------------------------------------------------------------------------------------------------------
    rule <k> validatorRewardTx(TO, VAL) => validatorRewardTxAux(#address2Bytes(TO), VAL) ... </k>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]

    rule <k> validatorRewardTxAux(TO, VAL) => .K ... </k>
         <account>
           <address> TO </address>
            <storage> STOR
                   => STOR[String2Bytes("ELRONDreward")
                           <- #incBytes(#lookupStorage(STOR, String2Bytes("ELRONDreward")), VAL)]
            </storage>
            <balance> TO_BAL => TO_BAL +Int VAL </balance>
            ...
         </account>
         <commands> .K </commands>
         <instrs> .K </instrs>
      [priority(60)]

    syntax Bytes ::= #incBytes(val : Bytes, inc : Int) [function]
 // -------------------------------------------------------------
    rule #incBytes(VAL, INC) => Int2Bytes(Bytes2Int(VAL, BE, Signed) +Int INC, BE, Signed)
```

```k
endmodule
```
