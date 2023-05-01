EEI Helpers
===========

Go implementation: [mx-chain-vm-go/vmhost/vmhooks/eei_helpers.go](https://github.com/multiversx/mx-chain-vm-go/blob/ea3d78d34c35f7ef9c1a9ea4fce8288608763229/vmhost/vmhooks/eei_helpers.go)

```k
module EEI-HELPERS
  imports BOOL
  imports INT
  imports BYTES
  imports STRING

  syntax Int ::= "#tickerMinLen"                 [macro]
               | "#tickerMaxLen"                 [macro]
               | "#randomCharsLen"               [macro]
               | "#idMinLen"                     [macro]
               | "#idMaxLen"                     [macro]

  rule #tickerMinLen    => 3
  rule #tickerMaxLen    => 10
  rule #randomCharsLen  => 6
  rule #idMinLen        => #tickerMinLen +Int #randomCharsLen +Int 1
  rule #idMaxLen        => #tickerMaxLen +Int #randomCharsLen +Int 1

  syntax Bool ::= #validateToken( Bytes )                [function, total]
 // -----------------------------------------------------------------
  rule #validateToken(Bs) => false requires lengthBytes(Bs) <Int #idMinLen
                                     orBool lengthBytes(Bs) >Int #idMaxLen
  rule #validateToken(Bs) => #isTickerValid( #getTicker(Bs) ) 
                     andBool #randomCharsAreValid( #getRandomChars(Bs) )
                     andBool Bs[(lengthBytes(Bs) -Int #randomCharsLen) -Int 1 ] ==Int ordChar("-")
                              requires lengthBytes(Bs) >=Int #idMinLen
                               andBool lengthBytes(Bs) <=Int #idMaxLen

  syntax Bytes ::= #getTicker(Bytes)                    [function, total]
                 | #getRandomChars(Bytes)               [function, total]
 // ------------------------------------------------------------------------------------
  rule #getTicker(Bs) => substrBytes(Bs, 0, lengthBytes(Bs) -Int #randomCharsLen -Int 1) 
    requires lengthBytes(Bs) >=Int #randomCharsLen
  rule #getRandomChars(Bs) => substrBytes(Bs, lengthBytes(Bs) -Int #randomCharsLen, lengthBytes(Bs))
    requires lengthBytes(Bs) >=Int #randomCharsLen
  // make the functions total
  rule #getTicker(Bs) => .Bytes
    requires lengthBytes(Bs) <Int #randomCharsLen
  rule #getRandomChars(Bs) => .Bytes
    requires lengthBytes(Bs) <Int #randomCharsLen


  syntax Bool ::= #isTickerValid( Bytes )                [function, total]
 // ----------------------------------------------------------------------
  rule #isTickerValid(Ticker) => false
    requires lengthBytes(Ticker) <Int #tickerMinLen
      orBool lengthBytes(Ticker) >Int #tickerMaxLen
  rule #isTickerValid(Ticker) => #allReadable(Ticker, 0)
    requires lengthBytes(Ticker) >=Int #tickerMinLen
      orBool lengthBytes(Ticker) <=Int #tickerMaxLen
  
  syntax Bool ::= #allReadable(Bytes, Int)       [function, total]
                | #readableChar(Int)             [function, total]
 // ---------------------------------------------------------
  rule #allReadable(Bs, Ix) => #readableChar(Bs[Ix]) andBool #allReadable(Bs, Ix +Int 1)   
                                            requires Ix <Int lengthBytes(Bs) andBool Ix >=Int 0
  rule #allReadable(Bs, Ix) => true         requires Ix >=Int lengthBytes(Bs)
  rule #allReadable(_Bs, Ix => 0)           requires Ix <Int 0

  rule #readableChar(X) => ( X >=Int ordChar("A") andBool X <=Int ordChar("Z") )
                    orBool ( X >=Int ordChar("0") andBool X <=Int ordChar("9") )


  syntax Bool ::= #randomCharsAreValid(Bytes)     [function, total]
 // ---------------------------------------------------------------
  rule #randomCharsAreValid(Bs) => false                      requires lengthBytes(Bs) =/=Int #randomCharsLen
  rule #randomCharsAreValid(Bs) => #allValidRandom(Bs, 0)     requires lengthBytes(Bs) ==Int #randomCharsLen
  
  syntax Bool ::= #allValidRandom(Bytes, Int)       [function, total]
                | #validRandom(Int)                 [function, total]
 // ---------------------------------------------------------
  rule #allValidRandom(Bs, Ix) => #validRandom(Bs[Ix]) andBool #allValidRandom(Bs, Ix +Int 1)   
                                               requires Ix <Int lengthBytes(Bs) andBool Ix >=Int 0
  rule #allValidRandom(Bs, Ix) => true         requires Ix >=Int lengthBytes(Bs)
  rule #allValidRandom(_Bs, Ix => 0)           requires Ix <Int 0

  rule #validRandom(X) => ( X >=Int ordChar("a") andBool X <=Int ordChar("f") )
                   orBool ( X >=Int ordChar("0") andBool X <=Int ordChar("9") )

endmodule
```