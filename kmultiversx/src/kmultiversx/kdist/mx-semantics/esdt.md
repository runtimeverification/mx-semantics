# ESDT Transfer

TODO ESDT transfer should be a builtin function
TODO check token settings: frozen, paused, limited transfer...

```k
requires "elrond-node.md"

module ESDT
    imports ELROND-NODE
    imports LIST-BYTES-EXTENSIONS
    imports MAP-BYTES-TO-BYTES-PRIMITIVE

    syntax Bytes ::= "#esdtSCAddress"   [macro]
 // -------------------------------------------
    rule #esdtSCAddress => b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\xff\xff"

    syntax Bytes ::= keyWithNonce(Bytes, Int)   [function, total]
 // -------------------------------------------------------------
    rule keyWithNonce(TOK, NONCE) => TOK +Bytes Int2Bytes(NONCE, BE, Unsigned)

    syntax InternalCmd ::= transferESDT  ( Bytes , Bytes , ESDTTransfer )
                         | transferESDTs ( Bytes , Bytes , List )

    rule <commands> transferESDTs(_, _, .List) => .K ... </commands>
    rule <commands> transferESDTs(FROM, TO, ListItem(T:ESDTTransfer) Ls) 
                 => transferESDT(FROM, TO, T) 
                 ~> transferESDTs(FROM, TO, Ls)
                    ... 
         </commands>

    rule <commands> transferESDT(FROM, TO, esdtTransfer(TOKEN, VALUE, 0) #as T) 
                 => checkAccountExists(FROM)
                 ~> checkAccountExists(TO)
                 ~> checkESDTBalance(FROM, TOKEN, VALUE)
                 ~> addToESDTBalance(FROM, TOKEN, 0 -Int VALUE, false)
                 ~> addToESDTBalance(TO,   TOKEN, VALUE, true)
                 ~> appendToOutAccount(TO, OutputTransfer(FROM, T))
                    ... 
         </commands>

    rule <commands> transferESDT(FROM, TO, esdtTransfer(TOKEN, VALUE, NONCE) #as T) 
                 => checkAccountExists(FROM)
                 ~> checkAccountExists(TO)
                 ~> checkESDTBalance(FROM, keyWithNonce(TOKEN, NONCE), VALUE)
                 ~> addNFTToDestination(FROM, TO, keyWithNonce(TOKEN, NONCE), VALUE)
                 ~> removeEmptyNft(FROM, keyWithNonce(TOKEN, NONCE))
                 ~> appendToOutAccount(TO, OutputTransfer(FROM, T))
                    ... 
         </commands>
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
      [priority(60)]

    rule [removeEmptyNft-skip]:
        <commands> removeEmptyNft(_, _) => .K ... </commands>
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
      requires VALUE <=Int ORIGFROM
      [priority(60)]

    // VALUE > ORIGFROM or TOKEN does not exist
    rule [checkESDTBalance-oof]:
        <commands> checkESDTBalance(_, _, _) => #throwExceptionBs(OutOfFunds, b"") ... </commands>
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
      [priority(61)]

    rule [addToESDTBalance-new-err]:
        <commands> addToESDTBalance(_ACCT, _TOKEN, _DELTA, false)
                => #throwExceptionBs(ExecutionFailed, b"new NFT data on sender") 
                   ...
        </commands>
      [priority(61)]

```

- Add NFT to an account

```k
    syntax InternalCmd ::= addNFTToDestination(Bytes, Bytes, Bytes, Int)
 // --------------------------------------------------------------------
    rule [addNFTToDestination-existing]:
        <commands> addNFTToDestination(FROM, TO, TOKEN, DELTA) => .K ... </commands>
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
            <esdtBalance> ORIGFROM => ORIGFROM +Int DELTA </esdtBalance>
            ...
          </esdtData>
          ...
        </account>
      [priority(60)]

    rule [addNFTToDestination-new]:
        <commands> addNFTToDestination(FROM, TO, TOKEN, DELTA) => .K ... </commands>
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
      [priority(60)]
```

## ESDT Builtin Functions

### Local Mint

```k
    syntax BuiltinFunction ::= "#ESDTLocalMint"        [klabel(#ESDTLocalMint), symbol]

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
                => addToESDTBalance(ADDR, TOK, VAL, true) ...
        </commands>
```

### Local Burn

```k
    syntax BuiltinFunction ::= "#ESDTLocalBurn"        [klabel(#ESDTLocalBurn), symbol]

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
                ~> checkAllowedToExecute(SND, ARGS {{ 0 }} orDefault b"", ESDTRoleLocalBurn) 
                ~> checkBool( lengthBytes(ARGS {{ 1 }} orDefault b"") <=Int 100
                            , "invalid arguments to process built-in function")
                ~> esdtLocalBurn( SND
                                , ARGS {{ 0 }} orDefault b""
                                , Bytes2Int(ARGS {{ 1 }} orDefault b"", BE, Unsigned)
                                )
                   ...
        </commands>

    syntax InternalCmd ::= esdtLocalBurn(account: Bytes, token: Bytes, value: Int)
        [klabel(esdtLocalBurn), symbol]
 // ------------------------------------------------------------------------------
    rule [esdtLocalBurn-cmd]:
        <commands> esdtLocalBurn(ADDR, TOK, VAL)
                => checkESDTBalance(ADDR, TOK, VAL)
                ~> addToESDTBalance(ADDR, TOK, 0 -Int VAL, false)
                   ...
        </commands>

```

### NFT Burn

```k
    syntax BuiltinFunction ::= "#ESDTNFTBurn"        [klabel(#ESDTNFTBurn), symbol]

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
                                           ARGS {{ 0 }} orDefault b"",
                                Bytes2Int( ARGS {{ 1 }} orDefault b"", BE, Unsigned),
                                Bytes2Int( ARGS {{ 2 }} orDefault b"", BE, Unsigned)
                              )
                   ...
        </commands>

    syntax InternalCmd ::= esdtNftBurn(Bytes, Bytes, Int, Int)
 // ----------------------------------------------------------
    rule [esdtNftBurn]:
        <commands> esdtNftBurn(ADDR, TOKEN, NONCE, VALUE)
                => checkAllowedToExecute(ADDR, TOKEN, ESDTRoleNFTBurn)
                ~> checkESDTBalance(ADDR, keyWithNonce(TOKEN, NONCE), VALUE)
                ~> addToESDTBalance(ADDR, keyWithNonce(TOKEN, NONCE), 0 -Int VALUE, false)
                   ...
        </commands>

```

### ESDT Transfer

```k
    syntax BuiltinFunction ::= "#ESDTTransfer"        [klabel(#ESDTTransfer), symbol]

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
      requires getCallFunc(FUNC, ARGS) =/=K b""

    rule [determineIsSCCallAfter-nocall]:
        <commands> determineIsSCCallAfter(_SND, _DST, _FUNC, _VMINPUT)
                => .K ...
        </commands>
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
    syntax BuiltinFunction ::= "#MultiESDTNFTTransfer"        [klabel(#MultiESDTNFTTransfer), symbol]

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
            TOK, Bytes2Int(AMT, BE, Unsigned), Bytes2Int(NONCE, BE, Unsigned)
          ))
         parseESDTTransfersH(N -Int 1, REST)
      requires 0 <Int N

    // end of list or invalid args
    rule parseESDTTransfersH(_, _) => .List [owise]
```

### NFT Create

```k
    syntax BuiltinFunction ::= "#ESDTNFTCreate"        [klabel(#ESDTNFTCreate), symbol]

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
                ~> checkBool(lengthBytes(ARGS {{ 1 }} orDefault b"") <=Int 32,
                      "invalid arguments to process built-in function, max length for quantity in nft create is 32")
                ~> esdtNftCreate(SND, ESDTNFTCreate.token(ARGS), ESDTNFTCreate.qtty(ARGS), ESDTNFTCreate.meta(SND, ARGS))
                   ...
        </commands>

    syntax InternalCmd ::= esdtNftCreate(Bytes, Bytes, Int, ESDTMetadata)      [klabel(esdtNftCreate), symbol]
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

    syntax Bytes ::= "ESDTNFTCreate.token" "(" ListBytes ")"   [function, total]
    syntax Int   ::= "ESDTNFTCreate.qtty"  "(" ListBytes ")"   [function, total]
 // -------------------------------------------------------------------------------------
    rule ESDTNFTCreate.token(ARGS)  =>           ARGS {{ 0 }} orDefault b""
    rule ESDTNFTCreate.qtty(ARGS)   => Bytes2Int(ARGS {{ 1 }} orDefault b"", BE, Unsigned)
    
    syntax ESDTMetadata ::= "ESDTNFTCreate.meta" "("  Bytes ","  ListBytes ")"   [function, total]
 // --------------------------------------------------------------------------------------------
    rule ESDTNFTCreate.meta(SND, ARGS)
      => esdtMetadata( ...
            name: ARGS {{ 2 }} orDefault b"", 
            nonce: getLatestNonce(SND, ESDTNFTCreate.token(ARGS)) +Int 1,
            creator: SND,
            royalties: Bytes2Int(ARGS {{ 3 }} orDefault b"", BE, Unsigned),
            hash: ARGS {{ 4 }} orDefault b"",
            uris: rangeTotal(ARGS, 6, 0),
            attributes: ARGS {{ 5 }} orDefault b""
          )

    syntax Int ::= getLatestNonce(Bytes, Bytes)   [function, total]
 // ---------------------------------------------------------------
    rule [[ getLatestNonce(ADDR, TOK) => Bytes2Int( STORAGE {{ getNonceKey(TOK)}} orDefault b"", BE, Unsigned )]]
        <account>
          <address> ADDR </address>
          <storage> STORAGE </storage>
          ...
        </account>

    rule getLatestNonce(_, _) => 0      [owise]

    syntax Bytes ::= getNonceKey(Bytes)   [function, total]
 // -------------------------------------------------------
    rule getNonceKey(TOK) => b"ELRONDnonce" +Bytes TOK


    syntax InternalCmd ::= saveNFT(Bytes, Bytes, Int, ESDTMetadata)       [klabel(saveNFT), symbol]
 // -----------------------------------------------------------------------------------------------
    rule [saveNFT]:
        <commands> saveNFT(ADDR, TOK_KEY, QTTY, esdtMetadata(... nonce: NONCE) #as META) => .K ... </commands>
        <account>
          <address> ADDR </address>
          (.Bag => <esdtData>
            <esdtId> keyWithNonce(TOK_KEY, NONCE) </esdtId>
            <esdtBalance> QTTY </esdtBalance>
            <esdtRoles> .Set </esdtRoles>
            <esdtMetadata> META </esdtMetadata>
            <esdtProperties> .Bytes </esdtProperties>
          </esdtData>)
          ...
        </account>
        <out> ... (.ListBytes => ListItem(wrap(Int2Bytes(NONCE, BE, Unsigned)))) </out>

    syntax InternalCmd ::= saveLatestNonce(Bytes, Bytes, Int)   [klabel(saveLatestNonce), symbol]
 // ---------------------------------------------------------------------------------------------
    rule [saveLatestNonce]:
        <commands> saveLatestNonce(ADDR, TOKEN, NONCE) => .K ... </commands>
        <account>
          <address> ADDR </address>
          <storage> STORAGE => STORAGE{{ getNonceKey(TOKEN) <- Int2Bytes(NONCE, BE, Unsigned) }} </storage>
          ...
        </account>
```

### NFT Add Quantity

```k
    syntax BuiltinFunction ::= "#ESDTNFTAddQuantity"        [klabel(#ESDTNFTAddQuantity), symbol]

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
                ~> checkBool(lengthBytes(ARGS {{ 2 }} orDefault b"") <=Int 32,
                      "invalid arguments to process built-in function, max length for quantity in add nft quantity is 32")

                ~> esdtNftAddQuantity( SND,
                                                 ARGS {{ 0 }} orDefault b"",
                                       Bytes2Int(ARGS {{ 1 }} orDefault b"", BE, Unsigned),
                                       Bytes2Int(ARGS {{ 2 }} orDefault b"", BE, Unsigned)
                                      )
                   ...
        </commands>

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
    rule [checkAllowedToExecute-system]:
        <commands> checkAllowedToExecute(#esdtSCAddress, _, _) => .K ... </commands>

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
      requires ROLE in ROLES
      [priority(60)]

    rule [checkAllowedToExecute-fail]:
        <commands> checkAllowedToExecute(_ADDR, _TOK, _ROLE) 
                => #throwExceptionBs(UserError, b"action is not allowed") ...
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
