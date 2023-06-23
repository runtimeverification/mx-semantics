# ESDT Transfer

TODO ESDT transfer should be a builtin function
TODO check token settings: frozen, paused, limited transfer...

```k
require "elrond-node.md"

module ESDT
    imports ELROND-NODE

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


```k
endmodule
```