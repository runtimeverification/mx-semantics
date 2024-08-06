# ESDT Transfer

TODO ESDT transfer should be a builtin function
TODO check token settings: frozen, paused, limited transfer...

```k
requires "elrond-node.md"
requires "switch.md"

module ESDT
    imports ELROND-NODE
    imports SWITCH-SYNTAX
    imports LIST-BYTES-EXTENSIONS

    syntax Bytes ::= "#esdtSCAddress"   [macro]
 // -------------------------------------------
    rule #esdtSCAddress => b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xff\xff"

    syntax Bytes ::= keyWithNonce(Bytes, Int)   [function, total]
 // -------------------------------------------------------------
    rule keyWithNonce(TOK, NONCE) => TOK +Bytes Int2Bytes(NONCE, BE, Unsigned)


    syntax K ::= transferESDTs(Bytes, Bytes, List)       [function, total]
               | transferESDTsAux(Bytes, Bytes, List)    [function, total]
 // -------------------------------------------------------------------
    rule transferESDTs(FROM, TO, L)
      => transferESDTsAux(FROM, TO, L)
      ~> appendToOutAccount(TO, OutputTransfer(FROM, L))

    rule transferESDTsAux(FROM:Bytes, TO:Bytes, ListItem(T:ESDTTransfer) Ts)
      => transferESDT(FROM, TO, T)
      ~> transferESDTsAux(FROM, TO, Ts)

    rule transferESDTsAux(_FROM, _TO, .List)         => .K
    rule transferESDTsAux(_FROM, _TO, ListItem(X) _) => .K    requires notBool isESDTTransfer(X)

    syntax K ::= transferESDT ( Bytes , Bytes , ESDTTransfer )    [function, total]
 // ---------------------------------------------------------------------
    rule transferESDT(FROM, TO, esdtTransfer(TOKEN, VALUE, 0))
      => checkAccountExists(FROM)
      ~> checkAccountExists(TO)
      ~> checkESDTBalance(FROM, TOKEN, VALUE)
      ~> addToESDTBalance(FROM, TOKEN, 0 -Int VALUE, false)
      ~> addToESDTBalance(TO,   TOKEN, VALUE, true)

    rule transferESDT(FROM, TO, esdtTransfer(TOKEN, VALUE, NONCE))
      => checkAccountExists(FROM)
      ~> checkAccountExists(TO)
      ~> checkESDTBalance(FROM, keyWithNonce(TOKEN, NONCE), VALUE)
      ~> moveNFTToDestination(FROM, TO, keyWithNonce(TOKEN, NONCE), VALUE)
      ~> removeEmptyNft(FROM, keyWithNonce(TOKEN, NONCE))
      requires NONCE =/=Int 0

    syntax InternalCmd ::= removeEmptyNft(Bytes, Bytes)
 // ---------------------------------------------------
    rule [removeEmptyNft]:
        <commands> removeEmptyNft(ACCT, TOKEN) => .K ... </commands>
        <account>
          <address> ACCT </address>
          (<esdtData>
            <esdtId> TOKEN </esdtId>
            <esdtBalance> 0 </esdtBalance>
            ...
          </esdtData> => .Bag)
          ...
        </account>
        <instrs> (#waitCommands ~> _) #Or .K </instrs>
      [priority(60)]

    rule [removeEmptyNft-skip-instrs-empty]:
        <commands> removeEmptyNft(_, _) => .K ... </commands>
        <instrs> .K </instrs>
      [priority(61)]

    rule [removeEmptyNft-skip-instrs-wait]:
        <commands> removeEmptyNft(_, _) => .K ... </commands>
        <instrs> #waitCommands ... </instrs>
      [priority(61)]

```

## ESDT transfer sub-commands

- Check account balance: assumes the account exists.

```k
    syntax InternalCmd ::= checkESDTBalance(account: Bytes, token: Bytes, value: Int)
 // ------------------------------------------------------
    rule [checkESDTBalance]:
        <commands> checkESDTBalance(ACCT, TOKEN, VALUE) => .K ... </commands>
        <account>
          <address> ACCT </address>
          <esdtData>
            <esdtId> TOKEN </esdtId>
            <esdtBalance> ORIGFROM </esdtBalance>
            ...
          </esdtData>
          ...
        </account>
        <instrs> (#waitCommands ~> _) #Or .K </instrs>
      requires VALUE <=Int ORIGFROM
      [priority(60)]

    // VALUE > ORIGFROM or TOKEN does not exist
    rule [checkESDTBalance-oof-instrs-empty]:
        <commands> checkESDTBalance(_, _, _) => #exception(OutOfFunds, b"") ... </commands>
        <instrs> .K </instrs>
      [priority(61)]
    rule [checkESDTBalance-oof-instrs-wait]:
        <commands> checkESDTBalance(_, _, _) => #exception(OutOfFunds, b"") ... </commands>
        <instrs> #waitCommands ... </instrs>
      [priority(61)]

```

- Update ESDT balance: assumes the account exists and it has enough balance.

```k
    syntax InternalCmd ::= addToESDTBalance(account: Bytes, token: Bytes, delta: Int, allowNew: Bool)
 // ------------------------------------------------------
    rule [addToESDTBalance]:
        <commands> addToESDTBalance(ACCT, TOKEN, DELTA, _) => .K ... </commands>
        <account>
          <address> ACCT </address>
          <esdtData>
            <esdtId> TOKEN </esdtId>
            <esdtBalance> ORIGFROM => ORIGFROM +Int DELTA </esdtBalance>
            ...
          </esdtData>
          ...
        </account>
        <instrs> (#waitCommands ~> _) #Or .K </instrs>
      [priority(60)]

    rule [addToESDTBalance-new-esdtData]:
        <commands> addToESDTBalance(ACCT, TOKEN, DELTA, true) => .K ... </commands>
        <account>
          <address> ACCT </address>
          (.Bag => <esdtData>
            <esdtId> TOKEN </esdtId>
            <esdtBalance> DELTA </esdtBalance>
            ...
          </esdtData>)
          ...
        </account>
        <instrs> (#waitCommands ~> _) #Or .K </instrs>
      [priority(61), preserves-definedness]
      // preserves-definedness:
      //  - ACCT exists prior so the account map is defined
      //  - TOKEN does not exist prior in esdtData, otherwise the rule above with higher priority would apply.

    rule [addToESDTBalance-new-err-instrs-empty]:
        <commands> addToESDTBalance(_ACCT, _TOKEN, _DELTA, false)
                => #exception(ExecutionFailed, b"new NFT data on sender")
                   ...
        </commands>
        <instrs> .K </instrs>
      [priority(61)]
    rule [addToESDTBalance-new-err-instrs-wait]:
        <commands> addToESDTBalance(_ACCT, _TOKEN, _DELTA, false)
                => #exception(ExecutionFailed, b"new NFT data on sender")
                   ...
        </commands>
        <instrs> #waitCommands ... </instrs>
      [priority(61)]

```

- Add NFT to an account

```k
    syntax InternalCmd ::= moveNFTToDestination(Bytes, Bytes, Bytes, Int)
 // --------------------------------------------------------------------
    rule [moveNFTToDestination-existing]:
        <commands> moveNFTToDestination(FROM, TO, TOKEN, DELTA) => .K ... </commands>
        <account>
          <address> FROM </address>
          <esdtData>
            <esdtId> TOKEN </esdtId>
            <esdtBalance> ORIGFROM => ORIGFROM -Int DELTA </esdtBalance>
            ...
          </esdtData>
          ...
        </account>
        <account>
          <address> TO </address>
          <esdtData>
            <esdtId> TOKEN </esdtId>
            <esdtBalance> ORIGTO => ORIGTO +Int DELTA </esdtBalance>
            ...
          </esdtData>
          ...
        </account>
        <instrs> (#waitCommands ~> _) #Or .K </instrs>
      [priority(60)]

    rule [moveNFTToDestination-self]:
        <commands> moveNFTToDestination(FROM, FROM, TOKEN, _DELTA) => .K ... </commands>
        <account>
          <address> FROM </address>
          <esdtData>
            <esdtId> TOKEN </esdtId>
            ...
          </esdtData>
          ...
        </account>
        <instrs> (#waitCommands ~> _) #Or .K </instrs>
      [priority(60)]

    rule [moveNFTToDestination-new]:
        <commands> moveNFTToDestination(FROM, TO, TOKEN, DELTA) => .K ... </commands>
        <account>
          <address> FROM </address>
          <esdtData>
            <esdtId> TOKEN </esdtId>
            <esdtBalance> ORIGFROM => ORIGFROM -Int DELTA </esdtBalance>
            <esdtMetadata> META </esdtMetadata>
            ...
          </esdtData>
          ...
        </account>
        <account>
          <address> TO </address>
          (.Bag => <esdtData>
            <esdtId> TOKEN </esdtId>
            <esdtBalance> DELTA </esdtBalance>
            <esdtMetadata> META </esdtMetadata>
            ...
          </esdtData>)
          ...
        </account>
        <instrs> (#waitCommands ~> _) #Or .K </instrs>
      [priority(61)]
```

## ESDT Builtin Functions

### Local Mint

```k
    syntax BuiltinFunction ::= "#ESDTLocalMint"        [symbol(#ESDTLocalMint)]

    rule toBuiltinFunction(F) => #ESDTLocalMint requires F ==String "\"ESDTLocalMint\""

    rule BuiltinFunction2Bytes(#ESDTLocalMint) => b"ESDTLocalMint"

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
                ~> checkAllowedToExecute(SND, getArg(ARGS, 0), ESDTRoleLocalMint)
                ~> checkBool( lengthBytes(getArg(ARGS, 1)) <=Int 100
                            , "invalid arguments to process built-in function")
                ~> addToESDTBalance(SND, getArg(ARGS, 0), getArgUInt(ARGS, 1), true)
                   ...
        </commands>
        <instrs> .K </instrs>

```

### Local Burn

```k
    syntax BuiltinFunction ::= "#ESDTLocalBurn"        [symbol(#ESDTLocalBurn)]

    rule toBuiltinFunction(F) => #ESDTLocalBurn requires F ==String "\"ESDTLocalBurn\""

    rule BuiltinFunction2Bytes(#ESDTLocalBurn) => b"ESDTLocalBurn"

    rule [ESDTLocalBurn]:
        <commands> processBuiltinFunction(#ESDTLocalBurn, SND, DST, <vmInput>
                                                                    <callValue> VALUE </callValue>
                                                                    <callArgs> ARGS </callArgs>
                                                                    _
                                                                  </vmInput>)
                => checkBool(VALUE ==Int 0, "built in function called with tx value is not allowed")
                ~> checkBool(size(ARGS) >=Int 2, "invalid arguments to process built-in function")
                ~> checkBool(SND ==K DST, "invalid receiver address")
                ~> checkAccountExists(SND)
                // TODO If the token has the 'BurnRoleForAll' global property, skip 'checkAllowedToExecute'
                ~> checkAllowedToExecute(SND, getArg(ARGS, 0), ESDTRoleLocalBurn)
                ~> checkBool( lengthBytes(getArg(ARGS, 1)) <=Int 100
                            , "invalid arguments to process built-in function")
                ~> checkESDTBalance(SND, getArg(ARGS, 0),        getArgUInt(ARGS, 1))
                ~> addToESDTBalance(SND, getArg(ARGS, 0), 0 -Int getArgUInt(ARGS, 1), false)
                   ...
        </commands>
        <instrs> .K </instrs>

```

### NFT Burn

```k
    syntax BuiltinFunction ::= "#ESDTNFTBurn"        [symbol(#ESDTNFTBurn)]

    rule toBuiltinFunction(F) => #ESDTNFTBurn requires F ==String "\"ESDTNFTBurn\""

    rule BuiltinFunction2Bytes(#ESDTNFTBurn) => b"ESDTNFTBurn"

    rule [ESDTNFTBurn]:
        <commands> processBuiltinFunction(#ESDTNFTBurn, SND, DST, <vmInput>
                                                                    <callValue> VALUE </callValue>
                                                                    <callArgs> ARGS </callArgs>
                                                                    _
                                                                  </vmInput>)
                => checkBool(VALUE ==Int 0, "built in function called with tx value is not allowed")
                ~> checkBool(size(ARGS) >=Int 2, "invalid arguments to process built-in function")
                ~> checkBool(SND ==K DST, "invalid receiver address")
                ~> checkAccountExists(SND)
                ~> esdtNftBurn( SND,
                                           getArg(ARGS, 0),
                                getArgUInt(ARGS, 1),
                                getArgUInt(ARGS, 2)
                              )
                   ...
        </commands>
        <instrs> .K </instrs>

    syntax InternalCmd ::= esdtNftBurn(Bytes, Bytes, Int, Int)
 // ----------------------------------------------------------
    rule [esdtNftBurn]:
        <commands> esdtNftBurn(ADDR, TOKEN, NONCE, VALUE)
                => checkAllowedToExecute(ADDR, TOKEN, ESDTRoleNFTBurn)
                ~> checkESDTBalance(ADDR, keyWithNonce(TOKEN, NONCE), VALUE)
                ~> addToESDTBalance(ADDR, keyWithNonce(TOKEN, NONCE), 0 -Int VALUE, false)
                ~> removeEmptyNft(ADDR, keyWithNonce(TOKEN, NONCE))
                   ...
        </commands>
        <instrs> .K </instrs>

```

### ESDT Transfer

```k
    syntax BuiltinFunction ::= "#ESDTTransfer"        [symbol(#ESDTTransfer)]

    rule toBuiltinFunction(F) => #ESDTTransfer requires F ==String "\"ESDTTransfer\""

    rule BuiltinFunction2Bytes(#ESDTTransfer) => b"ESDTTransfer"

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
        <instrs> .K </instrs>

    syntax Bytes ::= "ESDTTransfer.token"  "(" ListBytes ")"   [function, total]
    syntax Int   ::= "ESDTTransfer.value" "(" ListBytes ")"    [function, total]
 // -----------------------------------------------------------------------------
    rule ESDTTransfer.token(ARGS) => getArg(ARGS, 0)
    rule ESDTTransfer.value(ARGS) => getArgUInt(ARGS, 1)

    syntax InternalCmd ::= determineIsSCCallAfter(Bytes, Bytes, BuiltinFunction, VmInputCell)
        [symbol(determineIsSCCallAfter)]
 // ----------------------------------------------
    rule [determineIsSCCallAfter-call]:
        <commands> determineIsSCCallAfter(SND, DST, FUNC, <vmInput>
                                                            <callArgs> ARGS </callArgs>
                                                            <gasProvided> GAS </gasProvided>
                                                            <gasPrice> GAS_PRICE </gasPrice>
                                                            _
                                                          </vmInput>)
                => newWasmInstance(DST, CODE)
                ~> mkCall( DST
                         , #quoteUnparseWasmString(Bytes2String(getCallFunc(FUNC, ARGS)))
                         , mkVmInputEsdtExec(SND, FUNC, ARGS, GAS, GAS_PRICE, HASH)
                         )
                   ...
        </commands>
        <txHash> HASH </txHash>
        <account>
          <address> DST </address>
          <code> CODE:ModuleDecl </code>
          ...
        </account>
        <instrs> .K </instrs>
      requires getCallFunc(FUNC, ARGS) =/=K b""

    rule [determineIsSCCallAfter-nocall]:
        <commands> determineIsSCCallAfter(_SND, _DST, _FUNC, _VMINPUT)
                => .K ...
        </commands>
        <instrs> .K </instrs>
      [owise]

    syntax VmInputCell ::= mkVmInputEsdtExec(Bytes, BuiltinFunction, ListBytes, Int, Int, Bytes)
        [function, total]
 // -----------------------------------------------------------------------------------
    rule mkVmInputEsdtExec(FROM, BIFUNC, ARGS, GAS, GAS_PRICE, HASH)
      => <vmInput>
            <caller> FROM </caller>
            <callArgs> getCallArgs(BIFUNC, ARGS) </callArgs>
            <callValue> 0 </callValue>
            <callType> DirectCall </callType>
            <esdtTransfers>
              parseESDTTransfers(BIFUNC, ARGS)
            </esdtTransfers>
            <gasProvided> GAS </gasProvided>
            <gasPrice> GAS_PRICE </gasPrice>
            <txHash> HASH </txHash>
          </vmInput>
```


### Multi ESDT Transfer

```k
    syntax BuiltinFunction ::= "#MultiESDTNFTTransfer"        [symbol(#MultiESDTNFTTransfer)]

    rule toBuiltinFunction(F) => #MultiESDTNFTTransfer requires F ==String "\"MultiESDTNFTTransfer\""

    rule BuiltinFunction2Bytes(#MultiESDTNFTTransfer) => b"MultiESDTNFTTransfer"

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
        <instrs> .K </instrs>


    syntax Bytes ::= "MultiESDTNFTTransfer.dest" "(" ListBytes ")"    [function, total]
    syntax Int   ::= "MultiESDTNFTTransfer.num"  "(" ListBytes ")"    [function, total]
 // -----------------------------------------------------------------------------------
    rule MultiESDTNFTTransfer.dest(ARGS) => getArg(ARGS, 0)
    rule MultiESDTNFTTransfer.num(ARGS)  => getArgUInt(ARGS, 1)

    syntax List ::= parseESDTTransfers  (BuiltinFunction, ListBytes)  [function, total]
                  | parseESDTTransfersH (Int, ListBytes)              [function, total]
 // ------------------------------------------------------------------------------------
    rule parseESDTTransfers(#ESDTTransfer, ARGS)
      => ListItem(esdtTransfer( ESDTTransfer.token(ARGS), ESDTTransfer.value(ARGS), 0))

    rule parseESDTTransfers(#MultiESDTNFTTransfer, ARGS)
      => parseESDTTransfersH(MultiESDTNFTTransfer.num(ARGS), rangeTotal(ARGS, 2, 0))
      requires size(ARGS) >=Int 2

    rule parseESDTTransfers(#ESDTNFTTransfer, ARGS)
      => ListItem(esdtTransfer(
                        getArg(ARGS, 0),
                        getArgUInt(ARGS, 2),
                        getArgUInt(ARGS, 1)
                  ))

    rule parseESDTTransfers(_, _) => .List
      [owise]

    rule parseESDTTransfersH(N, ListItem(wrap(TOK)) ListItem(wrap(NONCE)) ListItem(wrap(AMT)) REST)
      => ListItem( esdtTransfer(
            TOK, Bytes2Int(AMT, BE, Unsigned), Bytes2Int(NONCE, BE, Unsigned)
          ))
         parseESDTTransfersH(N -Int 1, REST)
      requires 0 <Int N

    // end of list or invalid args
    rule parseESDTTransfersH(_, _) => .List [owise]
```

### NFT Create

```k
    syntax BuiltinFunction ::= "#ESDTNFTCreate"        [symbol(#ESDTNFTCreate)]

    rule toBuiltinFunction(F) => #ESDTNFTCreate requires F ==String "\"ESDTNFTCreate\""

    rule BuiltinFunction2Bytes(#ESDTNFTCreate) => b"ESDTNFTCreate"

    rule [ESDTNFTCreate]:
        <commands> processBuiltinFunction(#ESDTNFTCreate, SND, DST,
                                      <vmInput>
                                        <callValue> VALUE </callValue>
                                        <callArgs> ARGS </callArgs>
                                        _
                                      </vmInput>)
                => checkBool(VALUE ==Int 0, "built in function called with tx value is not allowed")
                ~> checkBool(size(ARGS) >=Int 7, "invalid arguments to process built-in function")
                ~> checkBool(SND ==K DST, "invalid receiver address")
                ~> checkBool(lengthBytes(getArg(ARGS, 1)) <=Int 32,
                      "invalid arguments to process built-in function, max length for quantity in nft create is 32")
                ~> esdtNftCreate(SND, ESDTNFTCreate.token(ARGS), ESDTNFTCreate.qtty(ARGS), ESDTNFTCreate.meta(SND, ARGS))
                   ...
        </commands>
        <instrs> .K </instrs>

    syntax InternalCmd ::= esdtNftCreate(Bytes, Bytes, Int, ESDTMetadata)      [symbol(esdtNftCreate)]
 // ---------------------------------------------------------------------------------------------------------
    rule [esdtNftCreate]:
        <commands> esdtNftCreate(SND, TOKEN, QTTY, esdtMetadata (... nonce: NONCE, royalties: ROYALTIES) #as META)
                => checkAllowedToExecute(SND, TOKEN, ESDTRoleNFTCreate)
                ~> checkBool(ROYALTIES <=Int 10000,
                      "invalid arguments to process built-in function, invalid max royality value")
                ~> checkBool(QTTY >Int 0,
                      "invalid arguments to process built-in function, invalid quantity")
                ~> #if QTTY >Int 1
                   #then checkAllowedToExecute(SND, TOKEN, ESDTRoleNFTAddQuantity)
                   #else .K
                   #fi
                ~> saveNFT(SND, TOKEN, QTTY, META)
                ~> saveLatestNonce(SND, TOKEN, NONCE)
                   ...
        </commands>
        <instrs> .K </instrs>

    syntax Bytes ::= "ESDTNFTCreate.token" "(" ListBytes ")"   [function, total]
    syntax Int   ::= "ESDTNFTCreate.qtty"  "(" ListBytes ")"   [function, total]
 // -------------------------------------------------------------------------------------
    rule ESDTNFTCreate.token(ARGS)  =>           getArg(ARGS, 0)
    rule ESDTNFTCreate.qtty(ARGS)   => getArgUInt(ARGS, 1)

    syntax ESDTMetadata ::= "ESDTNFTCreate.meta" "("  Bytes ","  ListBytes ")"   [function, total]
 // --------------------------------------------------------------------------------------------
    rule ESDTNFTCreate.meta(SND, ARGS)
      => esdtMetadata( ...
            name: getArg(ARGS, 2),
            nonce: getLatestNonce(SND, ESDTNFTCreate.token(ARGS)) +Int 1,
            creator: SND,
            royalties: getArgUInt(ARGS, 3),
            hash: getArg(ARGS, 4),
            uris: rangeTotal(ARGS, 6, 0),
            attributes: getArg(ARGS, 5)
          )

    syntax Int ::= getLatestNonce(Bytes, Bytes)   [function, total]
 // ---------------------------------------------------------------
    rule [[ getLatestNonce(ADDR, TOK) => NONCE ]]
        <account>
          <address> ADDR </address>
          <esdtData>
            <esdtId> TOK </esdtId>
            <esdtLastNonce> NONCE </esdtLastNonce>
            ...
          </esdtData>
          ...
        </account>

    rule getLatestNonce(_, _) => 0      [owise]

    syntax InternalCmd ::= saveNFT(Bytes, Bytes, Int, ESDTMetadata)       [symbol(saveNFT)]
 // -----------------------------------------------------------------------------------------------
    rule [saveNFT]:
        <commands> saveNFT(ADDR, TOK_KEY, QTTY, esdtMetadata(... nonce: NONCE) #as META) => .K ... </commands>
        <account>
          <address> ADDR </address>
          (.Bag => <esdtData>
            <esdtId> keyWithNonce(TOK_KEY, NONCE) </esdtId>
            <esdtBalance> QTTY </esdtBalance>
            <esdtRoles>  .Set   </esdtRoles>
            <esdtProperties> .Bytes </esdtProperties>
            <esdtMetadata> META </esdtMetadata>
            <esdtLastNonce> 0 </esdtLastNonce>
          </esdtData>)
          ...
        </account>
        <out> ... (.ListBytes => ListItem(wrap(Int2Bytes(NONCE, BE, Unsigned)))) </out>
        <instrs> .K </instrs>

    syntax InternalCmd ::= saveLatestNonce(Bytes, Bytes, Int)   [symbol(saveLatestNonce)]
 // ---------------------------------------------------------------------------------------------
    rule [saveLatestNonce]:
        <commands> saveLatestNonce(ADDR, TOKEN, NONCE) => .K ... </commands>
        <account>
          <address> ADDR </address>
          <esdtData>
            <esdtId> TOKEN </esdtId>
            <esdtLastNonce> _ => NONCE </esdtLastNonce>
            ...
          </esdtData>
          ...
        </account>
        <instrs> .K </instrs>
```

### NFT Add Quantity

```k
    syntax BuiltinFunction ::= "#ESDTNFTAddQuantity"        [symbol(#ESDTNFTAddQuantity)]

    rule toBuiltinFunction(F) => #ESDTNFTAddQuantity requires F ==String "\"ESDTNFTAddQuantity\""

    rule BuiltinFunction2Bytes(#ESDTNFTAddQuantity) => b"ESDTNFTAddQuantity"

    rule [ESDTNFTAddQuantity]:
        <commands> processBuiltinFunction(#ESDTNFTAddQuantity, SND, DST,
                                      <vmInput>
                                        <callValue> VALUE </callValue>
                                        <callArgs> ARGS </callArgs>
                                        _
                                      </vmInput>)

                => checkBool(VALUE ==Int 0, "built in function called with tx value is not allowed")
                ~> checkBool(size(ARGS) >=Int 3, "invalid arguments to process built-in function")
                ~> checkBool(SND ==K DST, "invalid receiver address")
                ~> checkBool(lengthBytes(getArg(ARGS, 2)) <=Int 32,
                      "invalid arguments to process built-in function, max length for quantity in add nft quantity is 32")

                ~> esdtNftAddQuantity( SND,
                                                 getArg(ARGS, 0),
                                       getArgUInt(ARGS, 1),
                                       getArgUInt(ARGS, 2)
                                      )
                   ...
        </commands>
        <instrs> .K </instrs>

    syntax InternalCmd ::= esdtNftAddQuantity(Bytes, Bytes, Int, Int)
 // -----------------------------------------------------------------
    rule [esdtNftAddQuantity]:
        <commands> esdtNftAddQuantity(SND, TOKEN, NONCE, VALUE)
                => checkAllowedToExecute(SND, TOKEN, ESDTRoleNFTAddQuantity)
                ~> checkBool(NONCE =/=Int 0, "NFT does not have metadata")
                ~> addToESDTBalance(
                      SND,
                      keyWithNonce(TOKEN, NONCE),
                      VALUE,
                      false
                   )
                   ...
        </commands>
        <instrs> .K </instrs>

```

### NFT Transfer

```k
    syntax BuiltinFunction ::= "#ESDTNFTTransfer"        [symbol(#ESDTNFTTransfer)]

    rule toBuiltinFunction(F) => #ESDTNFTTransfer requires F ==String "\"ESDTNFTTransfer\""

    rule BuiltinFunction2Bytes(#ESDTNFTTransfer) => b"ESDTNFTTransfer"

    rule [ESDTNFTTransfer]:
        <commands> processBuiltinFunction(#ESDTNFTTransfer, SND, DST,
                                      <vmInput>
                                        <callValue> VALUE </callValue>
                                        <callArgs> ARGS </callArgs>
                                        _
                                      </vmInput> #as VMINPUT)

                => checkBool(VALUE ==Int 0, "built in function called with tx value is not allowed")
                ~> checkBool(size(ARGS) >=Int 4, "invalid arguments to process built-in function")
                ~> checkBool(SND ==K DST, "invalid receiver address")
                ~> transferESDTs( SND, getArg(ARGS, 3),
                      parseESDTTransfers(#ESDTNFTTransfer, ARGS))
                ~> determineIsSCCallAfter(SND, getArg(ARGS, 3), #ESDTNFTTransfer, VMINPUT)
                   ...
        </commands>
        <instrs> .K </instrs>

```

### NFT Add URI

```k
    syntax BuiltinFunction ::= "#ESDTNFTAddURI"        [symbol(#ESDTNFTAddURI)]

    rule toBuiltinFunction(F) => #ESDTNFTAddURI requires F ==String "\"ESDTNFTAddURI\""

    rule BuiltinFunction2Bytes(#ESDTNFTAddURI) => b"ESDTNFTAddURI"

    // ESDTNFTAddURI & TOKEN & NONCE & URI1 & URI2 ...
    rule [ESDTNFTAddURI]:
        <commands> processBuiltinFunction(#ESDTNFTAddURI, SND, DST,
                                      <vmInput>
                                        <callValue> VALUE </callValue>
                                        <callArgs> ARGS </callArgs>
                                        _
                                      </vmInput>)

                => checkBool(VALUE ==Int 0, "built in function called with tx value is not allowed")
                ~> checkBool(size(ARGS) >=Int 3, "invalid arguments to process built-in function")
                ~> checkBool(SND ==K DST, "invalid receiver address")
                ~> checkAllowedToExecute(SND, getArg(ARGS, 0), ESDTRoleNFTAddURI)
                ~> esdtNftAddUri(
                      SND,
                      keyWithNonce(getArg(ARGS, 0), getArgUInt(ARGS, 1)),
                      rangeTotal(ARGS, 2, 0)
                   )
                   ...
        </commands>
        <instrs> .K </instrs>
      [priority(60)]

    syntax InternalCmd ::= esdtNftAddUri(Bytes, Bytes, ListBytes)
 // -----------------------------------------------------------------
    rule [esdtNftAddUri]:
        <commands> esdtNftAddUri(SND, TOKEN, NEW_URIS)
                => .K ...
        </commands>
        <account>
          <address> SND </address>
          <esdtData>
            <esdtId> TOKEN </esdtId>
            <esdtMetadata> esdtMetadata ( ... uris: URIS => URIS NEW_URIS ) </esdtMetadata>
            ...
          </esdtData>
          ...
        </account>
        <instrs> .K </instrs>
      [priority(60)]

    rule [esdtNftAddUri-not-found]:
        <commands> esdtNftAddUri(_SND, _TOKEN, _NEW_URIS)
                => #exception(UserError, b"new NFT data on sender") ...
        </commands>
        <instrs> .K </instrs>
      [priority(61)]

```

## Misc

```k
    syntax ESDTLocalRole ::= "ESDTRoleLocalMint"            [symbol(ESDTRoleLocalMint)]
                           | "ESDTRoleLocalBurn"            [symbol(ESDTRoleLocalBurn)]
                           | "ESDTRoleNFTCreate"            [symbol(ESDTRoleNFTCreate)]
                           | "ESDTRoleNFTAddQuantity"       [symbol(ESDTRoleNFTAddQuantity)]
                           | "ESDTRoleNFTBurn"              [symbol(ESDTRoleNFTBurn)]
                           | "ESDTRoleNFTAddURI"            [symbol(ESDTRoleNFTAddURI)]
                           | "ESDTRoleNFTUpdateAttributes"  [symbol(ESDTRoleNFTUpdateAttributes)]
                           | "ESDTTransferRole"             [symbol(ESDTTransferRole)]
                           | "None"                         [symbol(ESDTRoleNone)]

    syntax InternalCmd ::= checkAllowedToExecute(account: Bytes, token: Bytes, role: ESDTLocalRole)
        [symbol(checkAllowedToExecute)]
 // ----------------------------------------------------------------------------------------
    rule [checkAllowedToExecute-system]:
        <commands> checkAllowedToExecute(#esdtSCAddress, _, _) => .K ... </commands>
        <instrs> .K </instrs>

    rule [checkAllowedToExecute-pass]:
        <commands> checkAllowedToExecute(ADDR, TOK, ROLE) => .K ... </commands>
        <account>
          <address> ADDR </address>
          <esdtData>
            <esdtId>    TOK   </esdtId>
            <esdtRoles> ROLES </esdtRoles>
            ...
          </esdtData>
          ...
        </account>
        <instrs> .K </instrs>
      requires ROLE in ROLES
      [priority(60)]

    rule [checkAllowedToExecute-fail]:
        <commands> checkAllowedToExecute(_ADDR, _TOK, _ROLE)
                => #exception(UserError, b"action is not allowed") ...
        </commands>
        <instrs> .K </instrs>
      [priority(61)]

    syntax ListBytes ::= getCallArgs(BuiltinFunction, ListBytes)  [function, total]
 // -------------------------------------------------------------------------------
    rule getCallArgs(#ESDTTransfer, ARGS)    => rangeTotal(ARGS, 3, 0) // drop token, amount, func
    rule getCallArgs(#ESDTNFTTransfer, ARGS) => rangeTotal(ARGS, 5, 0) // drop token, nonce, amount, dest, func
    rule getCallArgs(#MultiESDTNFTTransfer, ARGS)
      => rangeTotal(ARGS, MultiESDTNFTTransfer.num(ARGS) *Int 3 +Int 3, 0) // drop dest, num, num*3, func
    rule getCallArgs(_, _) => .ListBytes  [owise]

    syntax Bytes ::= getCallFunc(BuiltinFunction, ListBytes)  [function, total]
 // --------------------------------------------------------------------------
    rule getCallFunc(#ESDTTransfer,    ARGS) => getArg(ARGS, 2) // token&amount&func&...
    rule getCallFunc(#ESDTNFTTransfer, ARGS) => getArg(ARGS, 4) // token&nonce&amount&dest&func&...
    rule getCallFunc(#MultiESDTNFTTransfer, ARGS)
      => getArg(ARGS, MultiESDTNFTTransfer.num(ARGS) *Int 3 +Int 2)
    rule getCallFunc(_, _) => b""   [owise]


    syntax Bytes ::= getArg    (ListBytes, Int)    [function, total]
    syntax Int   ::= getArgUInt(ListBytes, Int)    [function, total]
 // ---------------------------------------------------------------
    rule getArg    (ARGS, I) => ARGS {{ I }} orDefault b""
    rule getArgUInt(ARGS, I) => Bytes2Int(getArg(ARGS, I), BE, Unsigned)

```

```k
endmodule
```
