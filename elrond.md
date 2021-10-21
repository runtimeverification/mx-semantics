Elrond Semantics
================

```k
require "auto-allocate.md"
require "bigIntOps.md"
require "cryptoei.md"
require "elrond-config.md"
require "elrondei.md"
require "smallIntOps.md"

module ELROND
    imports BIGINTOPS
    imports CRYPTOEI
    imports ELROND-CONFIG
    imports ELRONDEI
    imports SMALLINTOPS
    imports WASM-AUTO-ALLOCATE
```

### Other Host Calls

The (incorrect) default implementation of a host call is to just return zero values of the correct type.

```k
    rule <instrs> hostCall("env", "asyncCall", [ DOM ] -> [ CODOM ]) => . ... </instrs>
         <valstack> VS => #zero(CODOM) ++ #drop(lengthValTypes(DOM), VS) </valstack>

endmodule
```
