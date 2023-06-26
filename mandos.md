Mandos Testing Framework
========================

```k
require "wasm-text.md"
require "elrond.md"

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
        <exit-code exit=""> 0 </exit-code>
      </mandos>
```

Mandos Steps
------------

### Wasm and Elrond Interaction

Only take the next step once both the Elrond node and Wasm are done executing.

```k
    syntax Step ::= "#wait"
 // -----------------------
    rule <k> #wait => . ... </k>
         <commands> . </commands>
         <instrs> . </instrs>

    syntax Steps ::= List{Step, ""} [klabel(mandosSteps), symbol]
 // -------------------------------------------------------------
    rule <k> .Steps => . </k> [priority(60)]
    rule <k> S:Step SS:Steps => S ~> SS ... </k> [priority(60)]

    syntax Step ::= "setExitCode" Int
 // ---------------------------------
    rule <k> setExitCode I => . ... </k>
         <commands> . </commands>
         <instrs> . </instrs>
         <exit-code> _ => I </exit-code>
      [priority(60)]

    syntax Step ::= ModuleDecl
 // --------------------------
    rule <k> (module _:OptionalId _:Defns):ModuleDecl #as M => #wait ... </k>
         <instrs> . => sequenceStmts(text2abstract(M .Stmts)) </instrs>

    rule <k> M:ModuleDecl => #wait ... </k>
         <instrs> . => M </instrs>
      [owise]

    syntax Step ::= "register" String [klabel(register), symbol]
 // ------------------------------------------------------------
    rule <k> register NAME => . ... </k>
         <moduleRegistry> REG => REG [NAME <- IDX -Int 1] </moduleRegistry>
         <nextModuleIdx> IDX </nextModuleIdx>
      [priority(60)]
```

### Helper Functions

```k
    syntax MapBytesToBytes  ::= #removeEmptyBytes ( MapBytesToBytes ) [function]
 // ----------------------------------------------------------------------------------------
    rule #removeEmptyBytes(.MapBytesToBytes)
        => .MapBytesToBytes
    rule #removeEmptyBytes(Key Bytes2Bytes|-> Value M)
        =>  #if Value ==K .Bytes
            #then #removeEmptyBytes(M)
            #else Key Bytes2Bytes|-> Value #removeEmptyBytes(M)
            #fi
    rule #removeEmptyBytes(Key Bytes2Bytes|-> Value M)
        =>  #if Value ==K .Bytes
            #then #removeEmptyBytes(M)
            #else Key Bytes2Bytes|-> Value #removeEmptyBytes(M)
            #fi
        [simplification]

```

### Step type: setState

```k
    syntax Step ::= setAccount    (
                        address: Address, nonce: Int, balance: Int, code: Code,
                        owner: Address, storage: MapBytesToBytes )  [klabel(setAccount), symbol]
                  | setAccountAux (
                        address: Bytes, nonce: Int, balance: Int, code: Code,
                        owner: Bytes, storage: MapBytesToBytes )      [klabel(setAccountAux), symbol]
                  | createAndSetAccountWithEmptyCode       ( Bytes, Int, Int, Map )
                  | createAndSetAccountAfterInitCodeModule ( Bytes, Int, Int, Map )
 // -------------------------------------------------------------------------------
    rule <k> setAccount(ADDRESS, NONCE, BALANCE, CODE, OWNER, STORAGE)
          => setAccountAux(#address2Bytes(ADDRESS), NONCE, BALANCE, CODE, #address2Bytes(OWNER), STORAGE) ... </k>
      [priority(60)]

    rule <k> setAccountAux(ADDRESS, NONCE, BALANCE, CODE, OWNER, STORAGE) => #wait ... </k>
         <commands> . 
                 => createAccount(ADDRESS)
                 ~> setAccountFields(ADDRESS, NONCE, BALANCE, CODE, OWNER, STORAGE) 
         </commands>
      [priority(60)]

    syntax Step ::= setEsdtBalance( Bytes , Bytes, Int )     [klabel(setEsdtBalance), symbol]
 // ------------------------------------------------
    rule <k> setEsdtBalance( ADDR , TokId , Value ) => . ... </k>
        <account>
          <address> ADDR </address>
          <esdtData>
            <esdtId> TokId </esdtId>
            <esdtBalance> _ => Value </esdtBalance>
            ...
           </esdtData>
          ...
        </account>
      [priority(60)]
    
    rule <k> setEsdtBalance( ADDR , TokId , Value ) => . ... </k>
        <account>
          <address> ADDR </address>
          <esdtDatas>
            (.Bag => <esdtData>
              <esdtId> TokId </esdtId>
              <esdtBalance> Value </esdtBalance>
              <frozen> false </frozen>
            </esdtData>)
            ...
          </esdtDatas>
          ...
        </account>
      [priority(61)]
    
    syntax Step ::= newAddress    ( Address, Int, Address ) [klabel(newAddress), symbol]
                  | newAddressAux ( Bytes, Int, Bytes )     [klabel(newAddressAux), symbol]
 // ---------------------------------------------------------------------------------------
    rule <k> newAddress(CREATOR, NONCE, NEW)
          => newAddressAux(#address2Bytes(CREATOR), NONCE, #address2Bytes(NEW)) ... </k>
      [priority(60)]

    rule <k> newAddressAux(CREATOR, NONCE, NEW) => . ... </k>
         <newAddresses> NEWADDRESSES => NEWADDRESSES [tuple(CREATOR, NONCE) <- NEW] </newAddresses>
      [priority(60)]

    syntax AddressNonce ::= tuple( Bytes , Int )
 // ----------------------------------------------

    syntax Step      ::= setCurBlockInfo  ( BlockInfo ) [klabel(setCurBlockInfo), symbol]
                       | setPrevBlockInfo ( BlockInfo ) [klabel(setPrevBlockInfo), symbol]
    syntax BlockInfo ::= blockTimestamp  ( Int )   [klabel(blockTimestamp), symbol]
                       | blockNonce      ( Int )   [klabel(blockNonce), symbol]
                       | blockRound      ( Int )   [klabel(blockRound), symbol]
                       | blockEpoch      ( Int )   [klabel(blockEpoch), symbol]
                       | blockRandomSeed ( Bytes ) [klabel(blockRandomSeed), symbol]
 // --------------------------------------------------------------------------------
    rule <k> setCurBlockInfo(blockTimestamp(TIMESTAMP)) => . ... </k>
         <curBlockTimestamp> _ => TIMESTAMP </curBlockTimestamp>
      [priority(60)]

    rule <k> setCurBlockInfo(blockNonce(NONCE)) => . ... </k>
         <curBlockNonce> _ => NONCE </curBlockNonce>
      [priority(60)]

    rule <k> setCurBlockInfo(blockRound(ROUND)) => . ... </k>
         <curBlockRound> _ => ROUND </curBlockRound>
      [priority(60)]

    rule <k> setCurBlockInfo(blockEpoch(EPOCH)) => . ... </k>
         <curBlockEpoch> _ => EPOCH </curBlockEpoch>
      [priority(60)]

    rule <k> setCurBlockInfo(blockRandomSeed(SEED)) => . ... </k>
         <curBlockRandomSeed> _ => SEED </curBlockRandomSeed>
      [priority(60)]

    rule <k> setPrevBlockInfo(blockTimestamp(TIMESTAMP)) => . ... </k>
         <prevBlockTimestamp> _ => TIMESTAMP </prevBlockTimestamp>
      [priority(60)]

    rule <k> setPrevBlockInfo(blockNonce(NONCE)) => . ... </k>
         <prevBlockNonce> _ => NONCE </prevBlockNonce>
      [priority(60)]

    rule <k> setPrevBlockInfo(blockRound(ROUND)) => . ... </k>
         <prevBlockRound> _ => ROUND </prevBlockRound>
      [priority(60)]

    rule <k> setPrevBlockInfo(blockEpoch(EPOCH)) => . ... </k>
         <prevBlockEpoch> _ => EPOCH </prevBlockEpoch>
      [priority(60)]

    rule <k> setPrevBlockInfo(blockRandomSeed(SEED)) => . ... </k>
         <prevBlockRandomSeed> _ => SEED </prevBlockRandomSeed>
      [priority(60)]
```

### Step type: checkState

```k
    syntax Step ::= checkAccountNonce    ( Address, Int ) [klabel(checkAccountNonce), symbol]
                  | checkAccountNonceAux ( Bytes, Int )   [klabel(checkAccountNonceAux), symbol]
 // --------------------------------------------------------------------------------------------
    rule <k> checkAccountNonce(ADDRESS, NONCE)
             => checkAccountNonceAux(#address2Bytes(ADDRESS), NONCE) ... </k>
      [priority(60)]

    rule <k> checkAccountNonceAux(ADDR, NONCE) => . ... </k>
         <account>
           <address> ADDR </address>
           <nonce> NONCE </nonce>
           ...
         </account>
      [priority(60)]

    syntax Step ::= checkAccountBalance    ( Address, Int ) [klabel(checkAccountBalance), symbol]
                  | checkAccountBalanceAux ( Bytes, Int )   [klabel(checkAccountBalanceAux), symbol]
 // ------------------------------------------------------------------------------------------------
    rule <k> checkAccountBalance(ADDRESS, BALANCE)
             => checkAccountBalanceAux(#address2Bytes(ADDRESS), BALANCE) ... </k>
      [priority(60)]

    rule <k> checkAccountBalanceAux(ADDR, BALANCE) => . ... </k>
         <account>
           <address> ADDR </address>
           <balance> BALANCE </balance>
           ...
         </account>
      [priority(60)]

    syntax Step ::= checkAccountStorage    ( Address, MapBytesToBytes ) [klabel(checkAccountStorage), symbol]
                  | checkAccountStorageAux ( Bytes, MapBytesToBytes )   [klabel(checkAccountStorageAux), symbol]
 // ------------------------------------------------------------------------------------------------
    rule <k> checkAccountStorage(ADDRESS, STORAGE)
             => checkAccountStorageAux(#address2Bytes(ADDRESS), STORAGE) ... </k>
      [priority(60)]

    rule <k> checkAccountStorageAux(ADDR, STORAGE) => . ... </k>
         <account>
           <address> ADDR </address>
           <storage> ACCTSTORAGE </storage>
           ...
         </account>
        requires ACCTSTORAGE ==K #removeEmptyBytes(STORAGE)
      [priority(60)]

    syntax Step ::= checkAccountCode    ( Address, String ) [klabel(checkAccountCode), symbol]
                  | checkAccountCodeAux ( Bytes, String )   [klabel(checkAccountCodeAux), symbol]
 // ---------------------------------------------------------------------------------------------
    rule <k> checkAccountCode(ADDRESS, CODEPATH)
             => checkAccountCodeAux(#address2Bytes(ADDRESS), CODEPATH) ... </k>
      [priority(60)]

    syntax OptionalString ::= #getModuleCodePath(ModuleDecl)    [function, total]
 // ----------------------------------------------------------------------
    rule #getModuleCodePath(#module (... metadata: #meta (... filename: PATH ) ) ) => PATH
    rule #getModuleCodePath((module OID:OptionalId DS:Defns) => structureModule(DS, OID))
    rule #getModuleCodePath(_) => .String                                                   [owise]

    rule <k> checkAccountCodeAux(ADDR, "") => . ... </k>
         <account>
           <address> ADDR </address>
           <code> .Code </code>
           ...
         </account>
      [priority(60)]
      
    rule <k> checkAccountCodeAux(ADDR, CODEPATH) => . ... </k>
         <account>
           <address> ADDR </address>
           <code> CODE:ModuleDecl </code>
           ...
         </account>
      requires CODEPATH ==K #getModuleCodePath(CODE)
      [priority(60)]

    syntax Step ::= checkedAccount    ( Address ) [klabel(checkedAccount), symbol]
                  | checkedAccountAux ( Bytes )   [klabel(checkedAccountAux), symbol]
 // ---------------------------------------------------------------------------------
    rule <k> checkedAccount(ADDRESS)
             => checkedAccountAux(#address2Bytes(ADDRESS)) ... </k>
      [priority(60)]

    rule <k> checkedAccountAux(ADDR) => . ... </k>
         <checkedAccounts> ... (.Set => SetItem(ADDR)) ... </checkedAccounts>
      [priority(60)]

    syntax Step ::= "checkNoAdditionalAccounts" [klabel(checkNoAdditionalAccounts), symbol]
 // ---------------------------------------------------------------------------------------
    rule <k> checkNoAdditionalAccounts => . ... </k>
         <checkedAccounts> CHECKEDACCTS </checkedAccounts>
         <activeAccounts> CHECKEDACCTS </activeAccounts>
      [priority(60)]

    syntax Step ::= "clearCheckedAccounts" [klabel(clearCheckedAccounts), symbol]
 // -----------------------------------------------------------------------------
    rule <k> clearCheckedAccounts => . ... </k>
         <checkedAccounts> _ => .Set </checkedAccounts>
      [priority(60)]
```

### Step type: scCall

```k
    syntax Step ::= callTx    (from: Address, to: Address, value: Int, esdtValue: List, func: WasmString, args: ListBytes, gasLimit: Int, gasPrice: Int) [klabel(callTx), symbol]
                  | callTxAux (from: Bytes,   to: Bytes,   value: Int, esdtValue: List, func: WasmString, args: ListBytes, gasLimit: Int, gasPrice: Int) [klabel(callTxAux), symbol]
 // ----------------------------------------------------------------------------------------------------------------------------------------------------------
    rule [callTx]:
        <k> callTx(FROM, TO, VALUE, ESDT, FUNCTION, ARGS, GASLIMIT, GASPRICE)
         => callTxAux(#address2Bytes(FROM), #address2Bytes(TO), VALUE, ESDT, FUNCTION, ARGS, GASLIMIT, GASPRICE) ... 
        </k>
      [priority(60)]

    rule [callTxAux]:
        <k> callTxAux(FROM, TO, VALUE, ESDT, FUNCTION, ARGS, GASLIMIT, GASPRICE) => #wait ... </k>
        <commands> . => callContract(TO, FUNCTION, mkVmInputSCCall(FROM, ARGS, VALUE, ESDT, GASLIMIT, GASPRICE)) </commands>
        <account>
          <address> FROM </address>
          <nonce> NONCE => NONCE +Int 1 </nonce>
          <balance> BALANCE => BALANCE -Int GASLIMIT *Int GASPRICE </balance>
          ...
        </account>
        <logging> S => S +String " -- call contract: " +String #parseWasmString(FUNCTION) </logging>
      [priority(60)]

    syntax VmInputCell ::= mkVmInputSCCall(Bytes, ListBytes, Int, List, Int, Int)    [function, total]
 // -----------------------------------------------------------------------------------
    rule mkVmInputSCCall(FROM, ARGS, VALUE, ESDT, GAS, GAS_PRICE)
      => <vmInput>
            <caller> FROM </caller>
            <callArgs> ARGS </callArgs>
            <callValue> VALUE </callValue>
            <esdtTransfers> ESDT </esdtTransfers>
            // gas
            <gasProvided> GAS </gasProvided>
            <gasPrice> GAS_PRICE </gasPrice>
          </vmInput>

    syntax Step ::= checkExpectOut ( ListBytes ) [klabel(checkExpectOut), symbol]
 // --------------------------------------------------------------------------
    rule <k> checkExpectOut(OUT) => . ... </k>
         <vmOutput> VMOutput(... out: OUT) </vmOutput>
      [priority(60)]

    syntax Step ::= checkExpectStatus ( ReturnCode ) [klabel(checkExpectStatus), symbol]
 // ------------------------------------------------------------------------------------
    rule <k> checkExpectStatus(RETURNCODE) => . ... </k>
         <vmOutput> VMOutput(... returnCode: RETURNCODE) </vmOutput>
      [priority(60)]

    syntax Step ::= checkExpectMessage ( Bytes ) [klabel(checkExpectMessage), symbol]
 // ---------------------------------------------------------------------------------
    rule <k> checkExpectMessage(MSG) => . ... </k>
         <vmOutput> VMOutput(... returnMessage: MSG) </vmOutput>
      [priority(60)]

    syntax Step ::= checkExpectLogs ( List ) [klabel(checkExpectLogs), symbol]
 // --------------------------------------------------------------------------
    rule <k> checkExpectLogs(LOGS) => . ... </k>
         <vmOutput> VMOutput(... logs: LOGS) </vmOutput>
      [priority(60)]
    // TODO implement event logs (some host functions like ESDT transfer should emit event logs. see crowdfunding-claim-successful.json)
    rule <k> checkExpectLogs(_LOGS) => . ... </k>
      [priority(61)]

```

## Step type: scQuery

TODO make sure that none of the state changes are persisted -- [Doc](https://docs.multiversx.com/developers/scenario-reference/structure#step-type-scquery)

```k
    syntax Step ::= queryTx    (to: Address, func: WasmString, args: ListBytes) [klabel(queryTx), symbol]
                  | queryTxAux (to: Bytes,   func: WasmString, args: ListBytes) [klabel(queryTxAux), symbol]
 // ---------------------------------------------------------------------------------------------------
    rule <k> queryTx(TO, FUNCTION, ARGS) => queryTxAux(#address2Bytes(TO), FUNCTION, ARGS) ... </k>
      [priority(60)]

    rule <k> queryTxAux(TO, FUNCTION, ARGS) => #wait ... </k>
         <commands> . => callContract(TO, FUNCTION, mkVmInputQuery(TO, ARGS)) </commands>
         <logging> S => S +String " -- query contract: " +String #parseWasmString(FUNCTION) </logging>
      [priority(60)]

    syntax VmInputCell ::= mkVmInputQuery(Bytes, ListBytes)    [function, total]
 // -----------------------------------------------------------------------------------
    rule mkVmInputQuery(TO, ARGS)
      => <vmInput>
            <caller> TO </caller>
            <callArgs> ARGS </callArgs>
            <callValue> 0 </callValue>
            <esdtTransfers> .List </esdtTransfers>
            // gas
            <gasProvided> maxUInt64 </gasProvided>
            <gasPrice> 0 </gasPrice>
          </vmInput>
```

### Step type: scDeploy

```k
    syntax Step ::= deployTx    ( Address, Int, ModuleDecl, ListBytes, Int, Int ) [klabel(deployTx), symbol]
                  | deployTxAux (   Bytes, Int, ModuleDecl, ListBytes, Int, Int )   [klabel(deployTxAux), symbol]
 // ------------------------------------------------------------------------------------------------------
    rule <k> deployTx(FROM, VALUE, MODULE, ARGS, GASLIMIT, GASPRICE)
          => deployTxAux(#address2Bytes(FROM), VALUE, MODULE, ARGS, GASLIMIT, GASPRICE) ... 
         </k>
      [priority(60)]

    rule [deployTxAux]:
        <k> deployTxAux(FROM, VALUE, MODULE, ARGS, GASLIMIT, GASPRICE) => #wait ... </k>
        <commands> . 
                => createAccount(NEWADDR)
                ~> setAccountOwner(NEWADDR, FROM)
                ~> setAccountCode(NEWADDR, MODULE)
                ~> callContract(NEWADDR, "init", mkVmInputDeploy(FROM, VALUE, ARGS, GASLIMIT, GASPRICE))
        </commands>
        <account>
           <address> FROM </address>
           <nonce> NONCE => NONCE +Int 1 </nonce>
           <balance> BALANCE => BALANCE -Int GASLIMIT *Int GASPRICE </balance>
           ...
        </account>
        <newAddresses> ... tuple(FROM, NONCE) |-> NEWADDR:Bytes ... </newAddresses>
      [priority(60)]

    syntax VmInputCell ::= mkVmInputDeploy(Bytes, Int, ListBytes, Int, Int)    [function, total]
 // -----------------------------------------------------------------------------------
    rule mkVmInputDeploy(FROM, VALUE, ARGS, GASLIMIT, GASPRICE)
      => <vmInput>
            <caller> FROM </caller>
            <callArgs> ARGS </callArgs>
            <callValue> VALUE </callValue>
            <esdtTransfers> .List </esdtTransfers>
            // gas
            <gasProvided> GASLIMIT </gasProvided>
            <gasPrice> GASPRICE </gasPrice>
          </vmInput>
```

### Step type: transfer

```k
    syntax Step ::= transfer(TransferTx) [klabel(transfer), symbol]
 // -----------------------------------------------------
    rule <k> transfer(TX) => TX ... </k> [priority(60)]

    syntax TransferTx ::= transferTx    ( from: Address, to: Bytes, value: Int ) [klabel(transferTx), symbol]
                        | transferTxAux ( from: Bytes, to: Bytes, value: Int )   [klabel(transferTxAux), symbol]
 // ------------------------------------------------------------------------------------------------------------
    rule <k> transferTx(FROM, TO, VAL) => transferTxAux(#address2Bytes(FROM), #address2Bytes(TO), VAL) ... </k> [priority(60)]

    rule <k> transferTxAux(FROM, TO, VAL) => #wait ... </k>
         <commands> . => transferFunds(FROM, TO, VAL) </commands>
      [priority(60)]
```

### Step type: validatorReward

```k
    syntax Step ::= validatorReward(ValidatorRewardTx) [klabel(validatorReward), symbol]
 // ------------------------------------------------------------------------------------
    rule <k> validatorReward(TX) => TX ... </k> [priority(60)]

    syntax ValidatorRewardTx ::= validatorRewardTx    ( to: Address, value: Int) [klabel(validatorRewardTx), symbol]
                               | validatorRewardTxAux ( to: Bytes, value: Int )  [klabel(validatorRewardTxAux), symbol]
 // -------------------------------------------------------------------------------------------------------------------
    rule <k> validatorRewardTx(TO, VAL) => validatorRewardTxAux(#address2Bytes(TO), VAL) ... </k> [priority(60)]

    rule <k> validatorRewardTxAux(TO, VAL) => . ... </k>
         <account>
           <address> TO </address>
            <storage> STOR
                   => STOR{{String2Bytes("ELRONDreward") 
                           <- #incBytes(#lookupStorage(STOR, String2Bytes("ELRONDreward")), VAL)}}
            </storage>
            <balance> TO_BAL => TO_BAL +Int VAL </balance>
            ...
         </account>
      [priority(60)]

    syntax Bytes ::= #incBytes(val : Bytes, inc : Int) [function]
 // -------------------------------------------------------------
    rule #incBytes(VAL, INC) => Int2Bytes(Bytes2Int(VAL, BE, Signed) +Int INC, BE, Signed)
```

```k
endmodule
```
