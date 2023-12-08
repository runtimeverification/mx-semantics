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
    syntax BuiltinFunction ::= "#ESDTLocalMint"        [klabel(#ESDTLocalMint), symbol]
    rule toBuiltinFunction(F) => #ESDTLocalMint requires F ==K #token("\"ESDTLocalMint\"", "WasmStringToken")

    rule [ESDTLocalMint]:
        <commands> processBuiltinFunction(#ESDTLocalMint, SND, DST, <vmInput> 
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
    syntax BuiltinFunction ::= "#ESDTTransfer"        [klabel(#ESDTTransfer), symbol]
    rule toBuiltinFunction(F) => #ESDTTransfer requires F ==K #token("\"ESDTTransfer\"", "WasmStringToken")

    rule [ESDTTransfer]:
        <commands> processBuiltinFunction(#ESDTTransfer, SND, DST, 
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
                ~> transferESDTs( SND, DST, parseESDTTransfers(#ESDTTransfer, ARGS))
                ~> determineIsSCCallAfter(SND, DST, #ESDTTransfer, VMINPUT)
                   ...
        </commands>

    syntax Bytes ::= "ESDTTransfer.token"  "(" ListBytes ")"   [function, total]
    syntax Int   ::= "ESDTTransfer.value" "(" ListBytes ")"    [function, total]
 // -----------------------------------------------------------------------------
    rule ESDTTransfer.token(ARGS) => ARGS {{ 0 }} orDefault b""
    rule ESDTTransfer.value(ARGS) => Bytes2Int(ARGS {{ 1 }} orDefault b"", BE, Unsigned)

    syntax InternalCmd ::= determineIsSCCallAfter(Bytes, Bytes, BuiltinFunction, VmInputCell)
        [klabel(determineIsSCCallAfter), symbol]
 // ----------------------------------------------
    rule [determineIsSCCallAfter-call]:
        <commands> determineIsSCCallAfter(SND, DST, FUNC, <vmInput> 
                                                            <callArgs> ARGS </callArgs>
                                                            <gasProvided> GAS </gasProvided>
                                                            <gasPrice> GAS_PRICE </gasPrice>
                                                            _ 
                                                          </vmInput> #as VMINPUT)
                => newWasmInstance(DST, CODE)
                ~> mkCall( DST
                         , #unparseWasmString("\"" +String Bytes2String(getCallFunc(FUNC, ARGS)) +String "\"")
                         , mkVmInputEsdtExec(SND, FUNC, ARGS, GAS, GAS_PRICE)
                         )
                   ...
        </commands>
        <account>
          <address> DST </address>
          <code> CODE:ModuleDecl </code>
          ...
        </account>
      requires getCallFunc(FUNC, ARGS) =/=K b""

    rule [determineIsSCCallAfter-nocall]:
        <commands> determineIsSCCallAfter(_SND, _DST, _FUNC, _VMINPUT)
                => . ...
        </commands>
        <vmOutput> _ => VMOutput(OK, b"", .ListBytes, .List)</vmOutput> // TODO add log entry
      [owise]

    syntax VmInputCell ::= mkVmInputEsdtExec(Bytes, BuiltinFunction, ListBytes, Int, Int)
        [function, total]
 // -----------------------------------------------------------------------------------
    rule mkVmInputEsdtExec(FROM, BIFUNC, ARGS, GAS, GAS_PRICE)
      => <vmInput>
            <caller> FROM </caller>
            <callArgs> getCallArgs(BIFUNC, ARGS) </callArgs>
            <callValue> 0 </callValue>
            <esdtTransfers>
              parseESDTTransfers(BIFUNC, ARGS)
            </esdtTransfers>
            <gasProvided> GAS </gasProvided>
            <gasPrice> GAS_PRICE </gasPrice>
          </vmInput>
```


### Multi ESDT Transfer

```k
    syntax BuiltinFunction ::= "#MultiESDTNFTTransfer"        [klabel(#MultiESDTNFTTransfer), symbol]
    rule toBuiltinFunction(F) => #MultiESDTNFTTransfer
      requires F ==K #token("\"MultiESDTNFTTransfer\"", "WasmStringToken")

    rule [MultiESDTNFTTransfer]:
        <commands> processBuiltinFunction(#MultiESDTNFTTransfer, SND, DST, 
                                      <vmInput> 
                                        <callValue> VALUE </callValue>
                                        <callArgs> ARGS </callArgs>
                                        _ 
                                      </vmInput> #as VMINPUT)
                => checkBool(VALUE ==Int 0, "built in function called with tx value is not allowed")
                ~> checkBool(size(ARGS) >=Int 4, "invalid arguments to process built-in function")
                ~> checkBool(SND ==K DST, "invalid receiver address")
                // TODO ~> check transfer to meta
                // TODO ~> checkIfTransferCanHappenWithLimitedTransfer()
                ~> checkBool(MultiESDTNFTTransfer.num(ARGS) >Int 0,
                      "invalid arguments to process built-in function, 0 tokens to transfer")
                ~> checkBool(size(ARGS) >=Int MultiESDTNFTTransfer.num(ARGS) *Int 3 +Int 2,
                      "invalid arguments to process built-in function, invalid number of arguments")
                ~> transferESDTs( SND, MultiESDTNFTTransfer.dest(ARGS),
                      parseESDTTransfers(#MultiESDTNFTTransfer, ARGS))
                ~> determineIsSCCallAfter(SND, MultiESDTNFTTransfer.dest(ARGS), #MultiESDTNFTTransfer, VMINPUT)
                   ...
        </commands>


    syntax Bytes ::= "MultiESDTNFTTransfer.dest" "(" ListBytes ")"    [function, total]
    syntax Int   ::= "MultiESDTNFTTransfer.num"  "(" ListBytes ")"    [function, total]
 // -----------------------------------------------------------------------------------
    rule MultiESDTNFTTransfer.dest(ARGS) => ARGS {{ 0 }} orDefault b""
    rule MultiESDTNFTTransfer.num(ARGS)  => Bytes2Int(ARGS {{ 1 }} orDefault b"", BE, Unsigned)

    syntax List ::= parseESDTTransfers  (BuiltinFunction, ListBytes)  [function, total]
                  | parseESDTTransfersH (Int, ListBytes)              [function, total]
 // ------------------------------------------------------------------------------------
    rule parseESDTTransfers(#ESDTTransfer, ARGS)
      => ListItem(esdtTransfer( ESDTTransfer.token(ARGS), ESDTTransfer.value(ARGS), 0))

    rule parseESDTTransfers(#MultiESDTNFTTransfer, ARGS)
      => parseESDTTransfersH(MultiESDTNFTTransfer.num(ARGS), rangeTotal(ARGS, 2, 0))
      requires size(ARGS) >=Int 2

    rule parseESDTTransfers(_, _) => .List
      [owise]

    rule parseESDTTransfersH(N, ListItem(wrap(TOK)) ListItem(wrap(NONCE)) ListItem(wrap(AMT)) REST) 
      => ListItem( esdtTransfer( 
            TOK, Bytes2Int(NONCE, BE, Unsigned), Bytes2Int(AMT, BE, Unsigned)
          ))
         parseESDTTransfersH(N -Int 1, REST)
      requires 0 <Int N

    // end of list or invalid args
    rule parseESDTTransfersH(_, _) => .List [owise]
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

    syntax ListBytes ::= getCallArgs(BuiltinFunction, ListBytes)  [function, total]
 // -------------------------------------------------------------------------------
    rule getCallArgs(#ESDTTransfer, ARGS) => rangeTotal(ARGS, 3, 0) // drop token, amount, func
    rule getCallArgs(#MultiESDTNFTTransfer, ARGS)
      => rangeTotal(ARGS, MultiESDTNFTTransfer.num(ARGS) *Int 3 +Int 3, 0) // drop dest, num, num*3, func
    rule getCallArgs(_, _) => .ListBytes  [owise]

    syntax Bytes ::= getCallFunc(BuiltinFunction, ListBytes)  [function, total]
 // --------------------------------------------------------------------------
    rule getCallFunc(#ESDTTransfer, ARGS) => ARGS {{ 2 }} orDefault b"" // token&amount&func&...
    rule getCallFunc(#MultiESDTNFTTransfer, ARGS)
      => ARGS {{ MultiESDTNFTTransfer.num(ARGS) *Int 3 +Int 2 }} orDefault b""
    rule getCallFunc(_, _) => b""   [owise]
```

```k
endmodule
```