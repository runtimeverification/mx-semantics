Elrond API
==========

Here, host calls are implemented, by defining the semantics when `hostCall(MODULE_NAME, EXPORT_NAME, TYPE)` is left on top of the `instrs` cell.

```k
require "../elrond-config.md"
require "bigIntOps.md"
require "cryptoei.md"
require "elrondei.md"
require "managedei.md"
require "manBufOps.md"
require "smallIntOps.md"

module ELRONDAPI
    imports ELROND-CONFIG
    imports BIGINTOPS
    imports CRYPTOEI
    imports ELRONDEI
    imports MANAGEDEI
    imports MANBUFOPS
    imports SMALLINTOPS
endmodule
```