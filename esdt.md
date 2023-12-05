# ESDT Transfer

TODO ESDT transfer should be a builtin function
TODO check token settings: frozen, paused, limited transfer...

```k
require "elrond-node.md"

module ESDT
    imports ELROND-NODE
    imports LIST-BYTES-EXTENSIONS

    syntax InternalCmd ::= transferESDT  ( Bytes , Bytes , ESDTTransfer )
                         | transferESDTs ( Bytes , Bytes , List )

    rule <commands> transferESDTs(_, _, .List) => #transferSuccess ... </commands>
    rule <commands> transferESDTs(FROM, TO, ListItem(T:ESDTTransfer) Ls) 
                 => transferESDT(FROM, TO, T) 
                 ~> transferESDTs(FROM, TO, Ls)
                    ... 
         </commands>

    rule <commands> transferESDT(FROM, TO, esdtTransfer(TOKEN, VALUE, _)) 
                 => checkAccountExists(FROM)
                 ~> checkAccountExists(TO)
                 ~> checkESDTBalance(FROM, TOKEN, VALUE)
                 ~> addToESDTBalance(FROM, TOKEN, 0 -Int VALUE)
                 ~> addToESDTBalance(TO,   TOKEN, VALUE)
                    ... 
         </commands>
```

## ESDT transfer sub-commands

- Check account balance: assumes the account exists.

```k
    syntax InternalCmd ::= checkESDTBalance(account: Bytes, token: Bytes, value: Int)
 // ------------------------------------------------------
    rule [checkESDTBalance]:
        <commands> checkESDTBalance(ACCT, TOKEN, VALUE) => . ... </commands>
        <account>
          <address> ACCT </address>
          <esdtData>
            <esdtId> TOKEN </esdtId>
            <esdtBalance> ORIGFROM </esdtBalance>
            ...
          </esdtData>
          ...
        </account>
      requires VALUE <=Int ORIGFROM
      [priority(60)]

    // VALUE > ORIGFROM or TOKEN does not exist
    rule [checkESDTBalance-oof]:
        <commands> checkESDTBalance(_, _, _) => #exception(OutOfFunds, b"") ... </commands>
      [priority(61)]

```

- Update ESDT balance: assumes the account exists and it has enough balance.

```k
    syntax InternalCmd ::= addToESDTBalance(account: Bytes, token: Bytes, delta: Int)
 // ------------------------------------------------------
    rule [addToESDTBalance]:
        <commands> addToESDTBalance(ACCT, TOKEN, DELTA) => . ... </commands>
        <account>
          <address> ACCT </address>
          <esdtData>
            <esdtId> TOKEN </esdtId>
            <esdtBalance> ORIGFROM => ORIGFROM +Int DELTA </esdtBalance>
            ...
          </esdtData>
          ...
        </account>
      [priority(60)]

    rule [addToESDTBalance-new-esdtData]:
        <commands> addToESDTBalance(ACCT, TOKEN, DELTA) => . ... </commands>
        <account>
          <address> ACCT </address>
          (.Bag => <esdtData>
            <esdtId> TOKEN </esdtId>
            <esdtBalance> DELTA </esdtBalance>
            ...
          </esdtData>)
          ...
        </account>
      [priority(61)]

```

## ESDT Builtin Functions

### Local Mint

```k
    rule isBuiltinFunction(F) => true requires F ==K #token("\"ESDTLocalMint\"", "WasmStringToken")

    rule [ESDTLocalMint]:
        <commands> processBuiltinFunc("\"ESDTLocalMint\"", SND, DST, <vmInput> 
                                                                    <callValue> VALUE </callValue>
                                                                    <callArgs> ARGS </callArgs>
                                                                    _ 
                                                                  </vmInput>)
                => checkBool(VALUE ==Int 0, "built in function called with tx value is not allowed")
                ~> checkBool(size(ARGS) >=Int 2, "invalid arguments to process built-in function")
                ~> checkBool(SND ==K DST, "invalid receiver address")
                ~> checkAccountExists(SND)
                ~> checkAllowedToExecute(SND, ARGS {{ 0 }} orDefault b"", ESDTRoleLocalMint)
                ~> checkBool( lengthBytes(ARGS {{ 1 }} orDefault b"") <=Int 100
                            , "invalid arguments to process built-in function")
                ~> esdtLocalMint( SND
                                , ARGS {{ 0 }} orDefault b""
                                , Bytes2Int(ARGS {{ 1 }} orDefault b"", BE, Unsigned)
                                )
                   ...
        </commands>

    syntax InternalCmd ::= esdtLocalMint(account: Bytes, token: Bytes, value: Int)
        [klabel(esdtLocalMint), symbol]
 // ------------------------------------------------------------------------------
    rule [esdtLocalMint-cmd]:
        <commands> esdtLocalMint(ADDR, TOK, VAL)
                => addToESDTBalance(ADDR, TOK, VAL) ...
        </commands>
        <vmOutput> _ => VMOutput(OK, b"", .ListBytes, .List)</vmOutput>
```

### ESDT Transfer

```k
    rule isBuiltinFunction(F) => true requires F ==K #token("\"ESDTTransfer\"", "WasmStringToken")

    rule [ESDTTransfer]:
        <commands> processBuiltinFunc("\"ESDTTransfer\"", SND, DST, 
                                      <vmInput> 
                                        <callValue> VALUE </callValue>
                                        <callArgs> ARGS </callArgs>
                                        _ 
                                      </vmInput> #as VMINPUT)
                => checkBool(VALUE ==Int 0, "built in function called with tx value is not allowed")
                ~> checkBool(size(ARGS) >=Int 2, "invalid arguments to process built-in function")
                // TODO ~> check transfer to meta
                // TODO ~> checkIfTransferCanHappenWithLimitedTransfer()
                ~> checkBool(ESDTTransfer.value(ARGS) >Int 0, "negative value")
                ~> transferESDT( SND, DST
                               , esdtTransfer(
                                   ESDTTransfer.token(ARGS),
                                   ESDTTransfer.value(ARGS), 
                                   0)
                               )
                ~> determineIsSCCallAfter(SND, DST, VMINPUT)
                   ...
        </commands>

    syntax Bytes ::= "ESDTTransfer.token"  "(" ListBytes ")"   [function, total]
    syntax Int   ::= "ESDTTransfer.value" "(" ListBytes ")"    [function, total]
 // -----------------------------------------------------------------------------
    rule ESDTTransfer.token(ARGS) => ARGS {{ 0 }} orDefault b""
    rule ESDTTransfer.value(ARGS) => Bytes2Int(ARGS {{ 1 }} orDefault b"", BE, Unsigned)

    syntax ListBytes ::= "ESDTTransfer.callArgs" "(" ListBytes ")"    [function, total]
 // -----------------------------------------------------------------------------------
    //                         token       amount      function
    rule ESDTTransfer.callArgs(ListItem(_) ListItem(_) ListItem(_) ARGS) => ARGS
    rule ESDTTransfer.callArgs(_) => .ListBytes                        [owise]


    syntax InternalCmd ::= determineIsSCCallAfter(Bytes, Bytes, VmInputCell)
        [klabel(determineIsSCCallAfter), symbol]
 // ----------------------------------------------
    rule [determineIsSCCallAfter-call]:
        <commands> determineIsSCCallAfter(SND, DST, <vmInput> 
                                                      <callArgs> ARGS </callArgs>
                                                      _ 
                                                    </vmInput> #as VMINPUT)
                => newWasmInstance(DST, CODE)
                ~> mkCall( DST
                         , #unparseWasmString("\"" +String Bytes2String(ARGS {{ 2 }} orDefault b"") +String "\"")
                         , mkVmInputEsdtExec(SND, VMINPUT)
                         )
                   ...
        </commands>
        <account>
          <address> DST </address>
          <code> CODE:ModuleDecl </code>
          ...
        </account>
      requires size(ARGS) >Int 2     // extra arguments for SC call after

    rule [determineIsSCCallAfter-nocall]:
        <commands> determineIsSCCallAfter(_SND, _DST, _VMINPUT)
                => . ...
        </commands>
        <vmOutput> _ => VMOutput(OK, b"", .ListBytes, .List)</vmOutput> // TODO add log entry
      [owise]

    syntax VmInputCell ::= mkVmInputEsdtExec(Bytes, VmInputCell)    [function, total]
 // -----------------------------------------------------------------------------------
    rule mkVmInputEsdtExec(FROM, <vmInput>
                                  <callArgs> ARGS </callArgs>
                                  <gasProvided> GAS </gasProvided>
                                  <gasPrice> GAS_PRICE </gasPrice>
                                  <esdtTransfers> ESDT </esdtTransfers>
                                  _
                                </vmInput>)
      => <vmInput>
            <caller> FROM </caller>
            <callArgs> ESDTTransfer.callArgs(ARGS) </callArgs>
            <callValue> 0 </callValue>
            <esdtTransfers> ESDT </esdtTransfers>
            // gas
            <gasProvided> GAS </gasProvided>
            <gasPrice> GAS_PRICE </gasPrice>
          </vmInput>
```

## Misc

```k
    syntax ESDTLocalRole ::= "ESDTRoleLocalMint"            [klabel(ESDTRoleLocalMint), symbol]
                           | "ESDTRoleLocalBurn"            [klabel(ESDTRoleLocalBurn), symbol]
                           | "ESDTRoleNFTCreate"            [klabel(ESDTRoleNFTCreate), symbol]
                           | "ESDTRoleNFTAddQuantity"       [klabel(ESDTRoleNFTAddQuantity), symbol]
                           | "ESDTRoleNFTBurn"              [klabel(ESDTRoleNFTBurn), symbol]
                           | "ESDTRoleNFTAddURI"            [klabel(ESDTRoleNFTAddURI), symbol]
                           | "ESDTRoleNFTUpdateAttributes"  [klabel(ESDTRoleNFTUpdateAttributes), symbol]
                           | "ESDTTransferRole"             [klabel(ESDTTransferRole), symbol]
                           | "None"                         [klabel(ESDTRoleNone), symbol]

    syntax InternalCmd ::= checkAllowedToExecute(account: Bytes, token: Bytes, role: ESDTLocalRole)
        [klabel(checkAllowedToExecute), symbol]
 // ----------------------------------------------------------------------------------------
    rule [checkAllowedToExecute-pass]:
        <commands> checkAllowedToExecute(ADDR, TOK, ROLE) => . ... </commands>
        <account>
          <address> ADDR </address>
          <esdtData>
            <esdtId>    TOK   </esdtId>
            <esdtRoles> ROLES </esdtRoles>
            ...
          </esdtData>
          ...
        </account>
      requires ROLE in ROLES
      [priority(60)]

    rule [checkAllowedToExecute-fail]:
        <commands> checkAllowedToExecute(_ADDR, _TOK, _ROLE) 
                => #exception(UserError, b"action is not allowed") ...
        </commands>
      [priority(61)]

```

```k
endmodule
```