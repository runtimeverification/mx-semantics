Elrond VM Hooks
==========

Here, host calls are implemented, by defining the semantics when `hostCall(MODULE_NAME, EXPORT_NAME, TYPE)` is left on top of the `instrs` cell.

```k
requires "../elrond-config.md"
requires "bigIntOps.md"
requires "cryptoei.md"
requires "baseOps.md"
requires "managedei.md"
requires "manBufOps.md"
requires "smallIntOps.md"

module VMHOOKS
    imports ELROND-CONFIG
    imports BIGINTOPS
    imports CRYPTOEI
    imports BASEOPS
    imports MANAGEDEI
    imports MANBUFOPS
    imports SMALLINTOPS
endmodule
```
